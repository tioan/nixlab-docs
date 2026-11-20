# Web Application Firewall

CrowdSec liest auf jedem Host die Access-Logs von nginx und Traefik und sperrt Adressen, die auffallen (`modules/crowdsec.nix`, dasselbe Modul wie auf den öffentlichen VMs; seine `secrets.yaml` braucht `crowdsec_enroll_token` und `crowdsec_bouncer_api_key`). Das geschieht im Nachhinein: Der eine Request, der eine Lücke ausnutzt, ist dann schon beim Dienst angekommen. Die WAF (`modules/waf.nix`, seit 2026-10-25) prüft jeden Request, bevor der Proxy ihn weiterreicht – mit CrowdSecs AppSec-Komponente, also derselben Engine, denselben Alerts und denselben Bans. Seit #4 (2026-11-16) läuft sie auf allen drei Front Doors.

## Aufbau

| Teil | Was es tut |
| --- | --- |
| AppSec (Teil von CrowdSec) | wertet die Regeln auf `127.0.0.1:7422` aus, erzeugt Alerts |
| nginx: OpenResty + Lua-Bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | zummi, aldrin: schickt in der Access-Phase jeden Request der gelisteten vhosts an AppSec und setzt die Antwort um; OpenResty ersetzt nginx (dasselbe NixOS-Modul, Lua eingebaut) |
| Traefik: CrowdSec-Plugin (`pkgs/crowdsec-traefik-plugin.nix`) | grammi: Middleware `waf` an den Routern, die sie nennen, als lokales Plugin geladen |
| Firewall-Bouncer | setzt Bans wie bisher in nftables um, auf allen Ports |

`modules/waf.nix` enthält keine Lab-Werte; der Host sagt, welche Namen hindurchgehen und wie. `modules/waf-lab.nix` ergänzt den Lab-Teil: den Bouncer-Schlüssel aus `hosts/<host>/waf.yaml` (sops) und die Metrik „AppSec antwortet“.

## Regeln

| Regeln | Phase | Folge (Block) |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – rund 200 Regeln für bekannte CVEs | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Methoden-Allowlist pro Name (`allowedMethods`) | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | kein Block; Ban, wenn der Bucket überläuft (Kapazität 5, alle 30 s leert sich ein Token) |

Die IP wird gesperrt, sobald zwei *verschiedene* In-Band-Regeln innerhalb von 60 s anschlagen (`crowdsecurity/appsec-vpatch`). Die beiden eigenen Regeln sind das grobe Netz unter den CVE-Regeln: Kein öffentlicher Dienst hier läuft mit PHP, ASP, JSP oder CGI.

## Modi, pro Name

`services.waf.mode` ist der Standard, `services.waf.hosts."<name>".mode` überschreibt ihn:

- **`block`**: In-Band-Treffer bekommen eine 403, Treffer füttern die Ban-Szenarien.
- **`detect`**: In-Band-Treffer werden mit „allow“ beantwortet und ihre Events verworfen – nichts wird blockiert, kein Ban-Szenario sieht sie; die Alerts bleiben (`cscli alerts list`). Jeder neue Name beginnt hier für eine Woche.

Die log-basierten HTTP-Szenarien aus `modules/crowdsec.nix` hängen nicht vom Modus ab.

## Ausnahmen

Alle pro Name, unter `services.waf.hosts."<name>"`:

- `exclusions = [ { rules = [ … ]; crsIds = [ … ]; paths/pathPrefixes/methods = [ … ]; } ]` – In-Band-Regeln (per Name) oder CRS-Regeln (per ID) nur für die passenden Requests abschalten.
- `allowedMethods = [ … ]` – jede andere Methode zählt wie ein Regeltreffer.
- `skipInspection = [ { pathPrefixes = [ … ]; methods = [ … ]; } ]` – nur nginx: Der Request geht gar nicht an AppSec (große Upload-Bodies; der Bouncer würde sie sonst ganz puffern). Bans gelten weiter.

| Name / Pfad | Behandlung | Grund |
| --- | --- | --- |
| `auth.homelab.example` (Pocket ID) | Block; CRS 931100 aus auf `/authorize` und `/api/oidc/token`; Methoden-Allowlist | native OIDC-Clients melden sich mit `redirect_uri=http://127.0.0.1:<port>` an; drei Wochen ohne Treffer auf einen echten Client |
| `mesh.homelab.example` Dashboard und `/oauth2/` (NetBird) | ab 2026-11-16 eine Woche Detect, dann Block | eine falsche Sperre trennt alle hinter dieser Adresse vom Mesh |
| NetBird API, gRPC, Relay | nie hinter der WAF | authentifizierter Maschinenverkehr |
| `s3.aldrin.homelab.example` (S3, `/nix-cache/`), `s3-admin`, `doku` | nicht hinter der WAF | signierte oder binäre Bodies bzw. nur im Mesh; Bucket-Whitelist aus #307 |
| `cloud.homelab.example` (OpenCloud) | eine Woche Detect, dann Block; `no-server-side-scripts` aus auf `/remote.php`, `/status.php`, `/ocs/`; CRS 911100 aus für WebDAV-Methoden; PUT/PATCH-Bodies auf `/remote.php/dav/`, `/remote.php/webdav/`, `/dav/`, `/data/` ungeprüft | die Sync-Clients nutzen ownClouds Pfade und WebDAV; Uploads mit `proxy_request_buffering off` |
| `tabs.homelab.example` (floccus) | eine Woche Detect, dann Block; CRS 911100 aus für WebDAV-Methoden | WebDAV-Client |
| `short.homelab.example`, `fotos.homelab.example`, `dash.homelab.example` | Block | öffentlich, ohne Login, in den Detect-Daten nur Scanner |
| ACME, MQTT 8883, Home-Assistant-App | nichts zu tun | DNS-01 / tls-alpn, reines TCP, und HA läuft über den NetBird-Proxy, nicht über diese Front Doors |

## Heimanschluss

Der Heimanschluss hat eine dynamische Adresse und wurde schon gesperrt: `http-crawl-non_statics` und `http-probing` erwischten eine Workstation bei `tofu apply` und den ersten nächtlichen Prebuild. Seit #444 (sobald ausgerollt) verwirft CrowdSec die Sperre für diese Szenarien (und `homelab/http-malformed-request`), wenn die Quelle die aufgelöste IPv4-Adresse ist oder im aufgelösten IPv6-Präfix liegt:

- gruffi hält einen dyndns-Namen auf den Adressen des Anschlusses (`uplinks.home.dyndnsName` in `inventory.json`; A die IPv4, AAAA gruffis eigene Adresse im delegierten Präfix). Der Name liegt in einer eigenen Zone `dyn.homelab.example`, delegiert per DNSControl: deSECs Mindest-TTL gilt pro Zone, 900 s für `homelab.example`, die dyndns-Zone bekommt eine niedrigere. Das Skript `openwrt/gruffi/ddns-home.sh` läuft, wenn die Leitung hochkommt, und alle 15 Minuten; sein deSEC-Token darf nur diese beiden Records schreiben (`terraform/desec-tokens`).
- Auf den öffentlichen Hosts löst eine Postoverflow-Whitelist (`modules/crowdsec-dynamic-allow.nix`) den Namen auf, wenn ein Szenario auslöst, und verwirft die Sperre, wenn die Quelle die A-Adresse ist oder im Präfix des AAAA liegt (`ipv6PrefixLength` aus dem Inventar). Scheitert der Lookup, gibt es keine Ausnahme.
- Die WAF weist schädliche Requests von zu Hause weiter mit 403 ab; nur die Sperre entfällt. Brute-Force-, CVE- und WAF-Szenarien sperren den Heimanschluss weiterhin, ein kompromittiertes Gerät zu Hause fällt also trotzdem auf. Keine LAPI-Allowlist: Die prüft in CrowdSec 1.7.8 auch AppSec und würde die Adresse dann gar nicht mehr in-band blocken.
- Nicht abgedeckt: die Community-Blocklist und von Hand gesetzte Sperren.

Metriken: `cs_node_wl_hits_ok_total{name="homelab/home-line"}` (verworfene Sperren), `nixlab_crowdsec_dynamic_allow_addresses{family}` pro Host, `gruffi_ddns_in_sync` und Verwandte von gruffi. Alarme `CrowdsecHomeExemptionUnresolved`, `CrowdsecHomeExemptionStale`, `GruffiDyndnsOutOfSync`, `GruffiDyndnsNotRunning`. Dashboard: Web & Security, Zeile „Home line exemption“.

## Ausfall

`services.waf.failOpen = true` (Standard): Ist AppSec nicht erreichbar oder antwortet nicht rechtzeitig, gehen Requests ungeprüft durch – Pocket ID, der NetBird-Login und die Sync-Clients sollen nicht mit CrowdSec ausfallen. Keiner der beiden Bouncer kann das pro Name entscheiden. Das Traefik-Plugin würde von sich aus blockieren, wenn AppSec oder die LAPI nicht erreichbar sind, und bis zum ersten Abruf der Sperren; das Modul schaltet all das ab.

Wie lange „rechtzeitig“ ist: `services.waf.appsecTimeout` (500 ms, das `APPSEC_PROCESS_TIMEOUT` des Bouncers) beim nginx-Bouncer; das Traefik-Plugin wartet `httpTimeoutSeconds` (10 s). Den teilt es mit dem vollen Abruf der Sperrliste, der mit 2 s auf grammi jede Minute scheiterte (2026-11-19); er bleibt deshalb beim Plugin-Standard, ein crowdsec-Neustart antwortet ohnehin sofort mit `connection refused`. Traefik hat keinen Zähler pro Request; es loggt `appsecQuery:unreachable` (ohne Router) für jeden Request, den es ungeprüft durchließ, und eine VictoriaLogs-Regel zählt das. Ein Request, zu dem AppSec kein Urteil abgab, zählt auf nginx als `result="unchecked"` (#413): Das Modul umhüllt den AppSec-Aufruf des Bouncers und wertet dessen Fehler-Rückgabe aus. Das deckt Zeitüberschreitung, nicht lauschendes AppSec (`connection refused`) und ein AppSec ab, das bei zu großem Body die Verbindung schließt. Eine 401 oder 5xx von AppSec liefert keinen Fehler und sieht bei fail open aus wie eine 200; die deckt die Probe ab. Mit `failOpen = false` werden dieselben Requests abgewiesen und zählen trotzdem als unchecked. Gemessen 2026-11-05..19: fast alle kamen, während crowdsec neu startete (nächtliches Hub-Index-Update um 00:01, Deploys) – meist `connection refused`, ein längerer Timeout hätte also nicht geholfen; AppSecs eigene Verarbeitung blieb auf jedem Host bei p99,9 unter 25 ms.

## Metriken und Alarme

| Metrik | Quelle |
| --- | --- |
| `nixlab_waf_requests_total{vhost, result="refused"\|"unchecked"\|"passed"}` | nginx, pro vhost, in der Log-Phase gezählt (`127.0.0.1:9932/metrics`, von vmagent abgeholt) |
| `nixlab_waf_appsec_duration_seconds` (Histogramm) | nginx, pro Host: wie lange der Bouncer auf AppSec wartete, Request-Body eingeschlossen; eine Zeitüberschreitung zählt mit ihrer vollen Wartezeit |
| `traefik_router_requests_total{code="403"}` auf `dash`, `mesh-oauth2`, `mesh-dashboard` | Traefik auf grammi |
| `nixlab_waf_appsec_up` | Textfile-Writer `waf-appsec-up`, einmal pro Minute: AppSec antwortet auf seinem Port |
| `nixlab_waf_appsec_probe_ok` | derselbe Writer: eine harmlose Anfrage mit dem Bouncer-Key bekam eine 200 |
| `cs_appsec_reqs_total`, `cs_appsec_block_total`, `cs_appsec_rule_hits` | CrowdSec selbst |

Die Probe (`services.waf.probe.package`) schickt ihre Anfrage von `127.0.0.2` (`services.waf.probe.address`) mit dem Bouncer-Key des Hosts, den der Writer als systemd-Credential bekommt. CrowdSec versieht seine AppSec-Zähler mit der Absenderadresse der Verbindung (`source`), bei allem, was ein Bouncer weiterreicht, also `127.0.0.1`; vmagent verwirft die Serien mit der Adresse der Probe (`services.waf.probe.metricRelabelConfigs`), die Zähler zeigen also nur Bouncer-Traffic. Die Laufzeit-Histogramme tragen `source` ebenfalls und werden genauso gefiltert. Ohne Key (ein Host vor `just waf-key` oder eine nicht lesbare Key-Datei) öffnet die Probe nur eine TCP-Verbindung; `nixlab_waf_appsec_up` heißt dann „der Port nimmt Verbindungen an“, nicht „AppSec antwortet per HTTP“. Bei nicht lesbarem Key ist `nixlab_waf_appsec_probe_ok` 0. Bis #452 fragte die Probe ohne Key, und CrowdSec loggte einmal pro Minute „missing API key“ als Fehler.

Alarme (`hosts/grammi/alerting/security.nix`): `WafAppsecDown` (5 Minuten keine Antwort), `WafAppsecProbeFailed` (antwortet, aber die Anfrage mit Key scheitert 10 Minuten lang: Key gesperrt oder Regeln kaputt), `WafBlocksHigh` (mehr als 100 abgewiesene Requests pro Stunde auf einem Namen), `WafUncheckedHigh` (mehr als 10 ungeprüfte Requests in 15 Minuten auf einem Namen, 30 Minuten lang – ein Neustart-Schub löst ihn nicht aus; für Traefik pro Host aus dem Journal, `hosts/grammi/alerting/journal.nix`). Dashboard: Web & Security, Zeile „AppSec WAF“.

## Hosts

| Host | Namen | Modus |
| --- | --- | --- |
| zummi | `auth.homelab.example` | Block (seit 2026-11-08) |
| aldrin | `short.homelab.example`, `fotos.homelab.example` | Block (#4) |
| ursalia | `inv.homelab.example` (Proxy-Listener von OpenInvento, vor den öffentlichen Fundseiten-Pfaden) | Block (#503) |
| aldrin | `cloud.homelab.example`, `tabs.homelab.example` | Detect, dann Block |
| grammi | `dash.homelab.example` | Block (#4) |
| grammi | `mesh.homelab.example` (Dashboard, `/oauth2/`) | Detect, dann Block |

ursalia hat seit #503 eine eigene CrowdSec-Engine (`modules/crowdsec.nix`), nur für NetBird-Proxy-Listener mit öffentlichen Pfaden. Diese Listener nutzen `lab.vhosts.<name>.realip`; WAF und Anwendung sehen so den Besucher und nicht die Mesh-Adresse des Proxys.

Ein Traefik-Plugin auf grammi schützt die Dienste anderer Hosts nicht: Traefik reicht diese Namen als TCP an den NetBird-Proxy durch, der seine Ziele direkt erreicht.

## Einen Host oder Namen hinzufügen

1. `services.waf.enable = true;` und `./modules/waf-lab.nix` in die Module des Hosts in `flake.nix` (die öffentlichen VMs haben es über das Profil `public-vm`); `waf` in die Zeile des Hosts in `.sops.yaml`. nginx: `lab.vhosts."<name>".waf = true;` (oder `services.waf.nginx.vhosts`). Traefik: Der Router nennt `config.services.waf.traefik.middleware`.
2. Neue Namen in `detect`: `services.waf.hosts."<name>".mode = "detect";`.
3. Deployen. Die AppSec-Engine läuft dann; noch fragt sie kein Proxy.
4. `just waf-key <host>` – registriert `nginx-appsec` bzw. `traefik-appsec` bei der LAPI des Hosts und schreibt den Schlüssel nach `hosts/<host>/waf.yaml`. Committen, deployen.
5. Prüfen: `cscli bouncers list` zeigt den Bouncer mit frischem Abruf; `curl -I https://<name>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` löst einen Test-Alert aus.
6. Nach einer Woche ohne Fehlalarme: `mode = "detect"` entfernen.

Test: `just test-vm waf` (`tests/waf.nix`) – bösartiger Request über nginx und Traefik blockiert, Ausnahmen gehen durch, Detect alarmiert nur, bei gestopptem CrowdSec fail open, und ein AppSec, das nie antwortet: Der Request wartet `appsecTimeout`, geht durch und zählt als unchecked.

Quellen: Die nginx-Anbindung folgt CrowdSecs [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) aus cs-nginx-bouncer v1.2.3 (MIT); die Lua-Bibliothek ist CrowdSecs [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633) (MIT); das Traefik-Plugin ist maxlerebourgs [crowdsec-bouncer-traefik-plugin v1.8.1](https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin/tree/f9c85b1472d618e9188a025c9b2308d0b27e5321) (Apache-2.0).
