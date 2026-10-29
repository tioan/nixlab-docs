# Web Application Firewall

CrowdSec liest auf jedem Host die Access-Logs von nginx und Traefik und sperrt Adressen, die auffallen (`modules/crowdsec.nix`). Das geschieht im Nachhinein: Der eine Request, der eine Lücke ausnutzt, ist dann schon beim Dienst angekommen. Die WAF (`modules/waf.nix`, seit 2026-10-25) prüft jeden Request, bevor nginx ihn weiterreicht – mit CrowdSecs AppSec-Komponente, also derselben Engine, denselben Alerts und denselben Bans.

## Aufbau

| Teil | Was es tut |
| --- | --- |
| OpenResty | ersetzt nginx (dasselbe NixOS-Modul, Lua eingebaut) |
| Lua-Bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | schickt in der Access-Phase jeden Request der gelisteten vhosts an AppSec auf `127.0.0.1:7422` und setzt dessen Antwort um |
| AppSec (Teil von CrowdSec) | wertet die Regeln aus, erzeugt Alerts |
| Firewall-Bouncer | setzt Bans wie bisher in nftables um, auf allen Ports |

Ist CrowdSec nicht erreichbar, lässt nginx die Requests ungeprüft durch (`APPSEC_FAILURE_ACTION=passthrough`) – Pocket ID soll nicht mit CrowdSec ausfallen.

## Regeln

| Regeln | Phase | Folge |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – rund 200 Regeln für bekannte CVEs (PHP-CGI, Spring4Shell, Grafana File Read, …) | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Methoden-Allowlist pro Name (`services.waf.allowedMethods`) – auf `auth.homelab.example` nur GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | kein Block; mehr als 5 Treffer in 30 s bannen die IP |

Jeder In-band-Treffer bekommt 403. Gebannt wird die IP, sobald zwei *verschiedene* In-band-Regeln innerhalb von 60 s treffen (`crowdsecurity/appsec-vpatch`: capacity 1 mit `distinct: rule_name`) – dieselbe Regel wiederholt füllt den Bucket nicht. Wer Scanner sucht, trifft in der Regel schnell mehrere.

Die beiden eigenen Regeln sind das grobe Netz unter den CVE-Regeln: Kein öffentlicher Dienst hier führt PHP, ASP, JSP oder CGI aus, also ist jede Anfrage danach ein Scan oder ein Exploit – auch für eine Lücke, für die es noch keine eigene Regel gibt. Die CRS läuft nur out-of-band, weil sie breit ist und einzelne Fehlalarme kein Grund sein sollen, einen legitimen Nutzer auszusperren.

Ausnahmen pro Name: `services.waf.ruleExclusions."<fqdn>" = [ "<regel>" ];`. OpenCloud (aldrin) braucht das für `homelab/no-server-side-scripts`, weil es ownClouds `/remote.php`, `/status.php` und `/ocs/v*.php` für die Desktop-Clients beibehält.

## Modi

- **`detect`** (Standard für jeden neuen Host): In-band-Treffer bekommen „allow“, die Ban-Szenarien der WAF laufen in der Simulation. Alerts erscheinen in `cscli alerts list` und in der Console mit „(simul)“, gesperrt wird durch die WAF nichts.
- **`block`**: In-band-Treffer bekommen 403, die IP wird gebannt.

Die log-basierten HTTP-Szenarien aus `modules/crowdsec.nix` hängen nicht am Modus und bannen wie bisher.

## Hosts

| Host | vhosts | Modus |
| --- | --- | --- |
| zummi | `auth.homelab.example` (Pocket ID) | detect (Pilot seit 2026-10-25) |

Geplant: grammi (Traefik-Plugin, nur Dashboard, `/oauth2/` und die öffentlichen Grafana-Pfade), aldrin (garage-ui, OpenCloud). Nie durch die WAF: Garages S3-API und NetBirds gRPC/Relay/API – signierte oder binäre Bodies, nichts für die Regeln zu finden, viel falsch zu lesen.

## Einen Host anschließen

1. `services.waf = { enable = true; nginx.vhosts = [ "<vhost>" ]; };` in der Host-Konfiguration, `./modules/waf.nix` in der Modulliste des Hosts in `flake.nix`, `waf` in die Zeile des Hosts in `.sops.yaml`.
2. Deployen. Die AppSec-Engine läuft dann schon; nginx fragt sie noch nicht (Warnung beim Evaluieren).
3. `just waf-key <host>` – registriert den Bouncer `nginx-appsec` beim LAPI des Hosts und schreibt den Schlüssel nach `hosts/<host>/waf.yaml`. Committen, deployen.
4. Prüfen: `cscli bouncers list` zeigt `nginx-appsec` mit frischem „Last API pull“; `curl -I https://<vhost>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` erzeugt einen Test-Alert (`cscli alerts list`).
5. Nach ein, zwei Wochen ohne Fehlalarme: `mode = "block";`.

Quellen: Die nginx-Einbindung folgt CrowdSecs [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) aus cs-nginx-bouncer v1.2.3; die Lua-Bibliothek ist CrowdSecs [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633).
