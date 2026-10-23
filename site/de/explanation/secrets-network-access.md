# Secrets, Netzwerk & Zugriff

## Secrets (sops-nix, age)

Jede Host-Datei ist für genau zwei Empfänger verschlüsselt: den age-Key aus dem SSH-Host-Key des Hosts und den Offline-Recovery-Key `admin`. Das MacBook kann Host-Secrets also nicht lesen – `just secrets <host>` editiert sie auf dem Host und holt das Ergebnis zurück. Verschlüsseln für einen Host geht dagegen überall (nur der öffentliche Key ist nötig); genau das nutzen `netbird-key` und `desec-key`.

| Datei | Empfänger | Inhalt |
| --- | --- | --- |
| `hosts/<host>/secrets.yaml` | Host + admin | Deploy-Key, App-Passwörter, OIDC-Clients, restic |
| `hosts/<host>/netbird.yaml` | Host + admin | NetBird-Setup-Key (von Tofu) |
| `hosts/<host>/desec.yaml` | Host + admin | deSEC-Token (von Tofu) |
| `hosts/<host>/github.yaml` | Host + admin | GitHub-Deploy-Key (von `just github-key`) |
| `terraform/*/secrets.yaml` | workstation + admin | API-Tokens für die Provider |

Der Workstation-Key liegt in 1Password und wird über `SOPS_AGE_KEY_CMD` gelesen, nie als Datei. `env.sh` in jedem Tofu-Modul entschlüsselt die Tokens nur in die Shell des jeweiligen Rezepts.

## Netzwerk

- **NetBird-Mesh** (`192.0.2.0/24`, Peer-Namen unter `peer.homelab.example`): Control Plane auf grammi, Login über Pocket ID. Private Range (RFC 1918) statt CGNAT, weil tailscaled Pakete aus 100.64/10 verwirft, solange beide Clients parallel laufen.
- **Gruppen:** `servers` (alle Hosts außer cuckoosegg), `subraum-devices`, `admin-workstations` (MacBook), dazu Personengruppen aus Pocket ID.
- **Heim-LAN** (`198.51.100.0/24`): Route über ursalia (Metrik 100), die beiden Apple TVs als Rückfall (Gruppe `home-routers`, Metrik 200, eigener Setup-Key per `just netbird-router-key`, keiner Person zugeordnet, in keiner Policy); für Gruppe `home-lan`, nicht für Geräte, die schon zu Hause sind (Posture-Check `not-at-home`). Die Apple TVs sollten in der App „Quantum-Resistance“ eingeschaltet haben; seit 2026-10-21 läuft Rosenpass im Mesh permissiv, ohne ginge es auch, nur nicht quantenresistent.
- **Anbindung von ursalia:** WLAN ins Hauptnetz des Heim-LANs (Intel BE200, `hosts/ursalia/wifi.nix`): wpa_supplicant, WPA3 mit WPA2-Rückfall, Land DE, alle Bänder, Passwort per sops. Am endgültigen Platz gibt es kein Kabel; eno1 behält DHCP als Rückfall mit schlechterer Routen-Metrik, damit das WLAN die Hauptverbindung bleibt, wenn beide aktiv sind.
- **Anbindung von zorlock:** ebenfalls WLAN (`en1`, Broadcom); `hosts/zorlock/wifi.nix` stellt sicher, dass `homelab` als bevorzugtes Netz eingetragen ist (`networksetup`, fügt nur hinzu, Passwort per sops in `hosts/zorlock/wifi.yaml`). nix-darwin hat kein WLAN-Modul; die Bandwahl bleibt bei macOS.
- **Subraum:** Route über cuckoosegg für `subraum-access`. cuckoosegg selbst darf nur grammis Ingest (TCP 8428/9428) erreichen und nur vom MacBook per SSH erreicht werden.
- **Tailscale** läuft während der Migration noch parallel und dient als Break-Glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

## Zugriff

Öffentlich offen sind nur 22/80/443. root-SSH lässt `modules/ssh.nix` nur von Mesh- oder Tailscale-Adressen zu; jeder Host hat ein eigenes Login-Keypair. Das Mesh ist derzeit nur IPv4, Dual-Stack ist als offener Punkt notiert.

### Apps auf grammi: nur über Traefik `:8090`

Mealie, Grist, logchef und Grafana lauschen auf grammi nur auf `127.0.0.1`. Der Reverse Proxy erreicht sie über den Traefik-Entrypoint `apps` (Port 8090), der vor jede App Wartungsschalter und Fehlerseiten setzt ([Wartungsmodus](../how-to/maintenance.md)). VictoriaMetrics (8428) und VictoriaLogs (9428) lauschen weiter auf allen Adressen, weil die anderen Hosts ihre Metriken und Logs über das Mesh dorthin schicken.

**Bewusste Lücke:** `:8090` selbst ist für jeden Mesh-Peer offen (`nb-mesh` ist vertrauenswürdig), ohne die SSO des Proxys. Wer im Mesh ist, erreicht mit dem passenden `Host`-Header jede App direkt, VictoriaMetrics/-Logs sogar ohne Login, weil sie keinen eigenen haben. Das ist so gewollt (2026-10-23): Wer grammi erreicht, entscheiden die NetBird-Policies, und Mealie, Grist, logchef und Grafana verlangen ihren eigenen Login. Neu bewerten, wenn ins Mesh Peers kommen, denen man weniger traut, oder sobald der Proxy per `direct_upstream` auf Loopback zugreifen kann ([offener Punkt](../project/open-items.md)).

### Private Doku: Admin-Geräte, Heimnetz, Login

Die private Fassung dieser Doku (`doku.homelab.example`, auf aldrin und ursalia) enthält jede interne Adresse und beschreibt, wie das Lab betrieben wird. Das ist mehr, als jedes Gerät im Mesh sehen muss. Deshalb liefert nginx sie nur an die Mesh-Adressen der Admin-Geräte aus; alle anderen bekommen 403 – mit einer eigenen Seite, die sagt, warum, von welcher Adresse die Anfrage kam und wie man ein Gerät freischaltet (ohne Navigation, damit die Seitentitel nicht sichtbar werden). Der Name selbst löst für alle Peers auf.

**Von außen** führt derselbe Name auf die öffentliche, anonymisierte Doku (GitHub Pages): Öffentlich ist `doku` ein CNAME auf den Reverse Proxy, dessen Dienst `doku` ohne Login an einen Listener auf aldrin (Port 8091, nur Mesh) weiterreicht, der nur eine Weiterleitung kennt. Wer im Mesh ist, kommt über die NetBird-Zone direkt zu aldrin und ursalia.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Extern oder NetBird aus | Reverse Proxy (grammi) → aldrin:8091 | 301 auf die öffentliche Doku |
| Im Mesh, Gerät in `admin-workstations` | direkt aldrin/ursalia | private Doku |
| Im Mesh, anderes Gerät | direkt aldrin/ursalia | 403-Seite |
| Extern, `doku.homelab.example/login` | aldrin:8091 → 302 auf `doku-login.homelab.example` → Reverse Proxy mit SSO (`docs-readers`) → aldrin:8094 | private Doku |
| Heimnetz, über den eigenen Eintrag des Routers | direkt ursalias LAN-Adresse | private Doku, außer Geräten auf der Deny-Liste |

**Login aus dem Internet** (entschieden 2026-10-23): für ein Gerät ohne NetBird, etwa einen Firmenlaptop. `doku.homelab.example/login` führt auf `doku-login.homelab.example`, einen eigenen Dienst im Reverse Proxy mit SSO für die Pocket-ID-Gruppe `docs-readers` – ein eigener Name, weil der Proxy die Anmeldung je Dienst kennt, nicht je Pfad, und SSO auf `doku` selbst die öffentliche Doku dahinter stellen würde. Sein Ziel ist ein Listener auf aldrin (Port 8094), der die private Seite ausliefert. Weil die Geräte aller Personen diesen Port über das Mesh ebenfalls erreichen (`to-servers`), schickt der Proxy einen geheimen Header (`X-Nixlab-Docs-Key`) mit, und aldrin liefert nur an Anfragen, die ihn tragen; neuer Schlüssel: `just docs-login-key`. Dieser Weg hängt an grammi und zummi – er ist eine Ergänzung, wenn das Mesh nicht zur Hand ist, kein Ersatz dafür.

**Heimnetz** (entschieden 2026-10-23): Der Router zu Hause beantwortet `doku.homelab.example` mit ursalias LAN-Adresse (ein eigener Eintrag, wie bei `mqtt.homelab.example`), und ursalia liefert die private Doku an das ganze Hauptnetz – außer an die Adressen auf einer bewussten Deny-Liste (`services.docsSite.lan` in `hosts/ursalia/configuration.nix`, Inventar-Geräte mit fester Adresse). Eine Deny-Liste nach Adresse erwischt nur Geräte mit reservierter Adresse; Gäste und alles mit wechselnder Adresse kommen hinein. Die Apple TVs gehören darauf, sobald sie eine Reservierung haben: Als NetBird-Ausweichrouter ins LAN maskieren sie Mesh-Peers auf ihre eigene Adresse. Mesh-Geräte betrifft das nicht – für sie löst der Name weiter auf die Mesh-Adressen auf.

**Warum über den Proxy:** So steht `doku` mit den anderen öffentlichen Namen im NetBird-Dashboard, statt als eigener öffentlicher vHost auf aldrin. Der Proxy selbst kann nicht umleiten, nur weiterreichen – daher der Weiterleitungs-Listener. Er hat einen eigenen Port, statt dass der Doku-vHost den Proxy an seiner Adresse erkennt: Der Proxy ist ein eigener Peer, dessen Mesh-Adresse Tofu nicht kennt. Die Verknüpfung von `homelab.example` mit der öffentlichen Doku ist dabei bewusst in Kauf genommen; die echten Adressen bleiben dort weiter ersetzt.

**Wer als Admin-Gerät zählt:** die Geräte der Gruppe `admin-workstations` (`terraform/netbird/subraum.tf`), heute das MacBook – dasselbe Gerät, das auch per SSH an die Subraum-Geräte darf. Bewusst nicht die Personengruppe `homelab_admins`: die füllt sich aus Pocket ID mit *allen* Geräten eines Admin-Users. Heute wären das keine (Calla hat keine eigenen Geräte), und ein Telefon, das sich unter einem Admin-User anmeldet, wäre sofort drin. Admin ist hier ein Gerät, das in Tofu mit Namen steht, nicht eine Anmeldung. Ein weiteres Gerät in `admin-workstations` bekommt damit auch SSH auf die Subraum-Geräte – dasselbe Vertrauen. Tofu liest die Mitglieder bei jedem `just netbird-apply` und schreibt Name → Adresse nach `terraform/netbird/admin-peers.json`; `flake.nix` übergibt die Adressen an `services.docsSite.allow`. Ein neues Admin-Gerät kommt also nach `just netbird-apply`, Commit und Deploy von aldrin und ursalia hinein.

**Warum in nginx und nicht in einer NetBird-Policy:** `to-servers` erlaubt den Geräten aller Personen (`homelab` und `homelab_admins`) alle Ports auf allen Servern. NetBird-Policies können nur erlauben, nicht verbieten – eine engere Regel für die Doku änderte nichts, solange `to-servers` so bleibt. `to-servers` auf eine Port-Liste je Dienst einzuschränken, ginge, berührt aber jeden Dienst auf jedem Server für eine statische Seite. Die Doku über einen eigenen Port abzutrennen, scheitert am selben Punkt. Die Policy entscheidet also weiter, welche Hosts ein Gerät erreicht, und nginx, wer die Doku bekommt.

**Warum keine Anmeldung im Mesh (Pocket ID):** Die Doku liest man, wenn etwas kaputt ist. Ein Login hinge sie an zummi (Pocket ID) und, über den Reverse Proxy, an grammi – genau die Hosts, von denen sie unabhängig sein soll. Eine Adressliste braucht zur Laufzeit nichts außer nginx auf dem Host selbst. Der Login aus dem Internet oben ändert daran nichts: Mesh und Heimnetz funktionieren ohne ihn weiter.

**Was das bewusst in Kauf nimmt:**

- Die Liste ist so aktuell wie das letzte `just netbird-apply` mit anschließendem Deploy. Ein neues Admin-Gerät sieht bis dahin 403, ein entferntes Gerät kommt bis dahin noch hinein.
- Die Adresse steht für das Gerät, nicht für die Person: Wer ein Admin-Gerät benutzt, liest die Doku.
- Leer darf die Liste nicht werden – `just netbird-admin-peers` verweigert eine leere Ausgabe, und das Modul bricht den Build mit einer Assertion ab, statt still allen 403 zu geben.
- Nur IPv4, wie das Mesh. Mit dem IPv6-Overlay kommen die v6-Adressen in dieselbe Liste.

### Paperless: von außen Freigabelinks (PIN) und App (SSO)

Im Mesh löst `dokumente.homelab.example` über die NetBird-Zone direkt zu ursalia auf (volle App, Login per Pocket ID).

**Von außen** ist `dokumente` ein CNAME auf den Reverse Proxy. Dessen Dienst `dokumente` bietet zwei Anmeldungen und reicht beide an einen Listener auf ursalia weiter (Port 8092, nur Mesh, HTTP durch den Tunnel):

- **PIN**, für Dritte mit einem Freigabelink: nur `share/<slug>` (Dokumente und Bündel, beides `SharedLinkView` in Paperless), sonst 404. Ein abgelaufener oder unbekannter Link führt in Paperless auf die Login-Seite; der Listener beantwortet das mit einem kurzen Hinweistext.
- **SSO** über Pocket ID (Gruppen `paperless-users`/`paperless-admins`): die volle App samt paperless-gpt wie im Mesh. Danach folgt noch der Pocket-ID-Login von Paperless selbst, meist ohne Eingabe.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Extern mit PIN | Reverse Proxy (grammi) → ursalia:8092 | nur `/share/<slug>`, sonst 404 |
| Extern mit SSO | Reverse Proxy (grammi) → ursalia:8092 | volle App |
| Im Mesh | direkt ursalia:443 | volle App, Freigabelinks ohne PIN |

**Woran der Listener SSO erkennt:** am Header `X-NetBird-User`. Der Proxy löscht bei jeder Anfrage, was der Client unter diesem Namen schickt, und setzt ihn nur bei SSO-Sitzungen auf die E-Mail-Adresse (`stampNetBirdIdentity` in NetBird, geprüft mit 0.81.0 – bei NetBird-Updates erneut prüfen). Der Header wählt nur die Pfade, er meldet niemanden an: Paperless verlangt weiter seinen eigenen Login. Ein Mesh-Peer, der den Header direkt an Port 8092 schickt, bekommt nichts, was er über 443 nicht ohnehin bekäme.

**Warum derselbe Name:** Paperless baut den Freigabelink aus dem Origin der Oberfläche. Ein Link `https://dokumente.homelab.example/share/<slug>` funktioniert so für Dritte ohne Umschreiben – egal ob im Mesh oder per SSO erzeugt. Ein eigener Name für eine der beiden Anmeldungen hieße, Links von Hand anzupassen.

**Warum der Listener filtert und nicht die PIN:** Die PIN ist eine zweite Hürde vor dem nicht ratbaren Slug, kein Ersatz. Dass PIN-Besucher die App nicht sehen, hängt allein an nginx auf ursalia. Der Proxy-Dienst hat keinen Pfadfilter (Ziel-`path`), sonst käme die Weiterleitung auf `/accounts/login/` bei abgelaufenen Links nicht mehr beim Listener an.

**PIN:** genau 6 Ziffern (mehr nimmt die NetBird-API nicht an), eine für alle Freigaben. Neu: `just dokumente-share-pin` (zufällig, nach `terraform/netbird/secrets.yaml`), dann `just netbird-apply`; anzeigen: `just dokumente-share-pin-show`. Der Proxy sperrt eine Client-Adresse nach 5 falschen PINs in 5 Minuten für 15 Minuten.

**Was das bewusst in Kauf nimmt:**

- Eine noch gültige PIN-Sitzung (Cookie des Proxys) überspringt die Anmeldeseite. Wer dann per SSO in die App will, landet auf einer Hinweisseite und muss erst die Website-Daten löschen oder ein privates Fenster nehmen.
- Wer die PIN kennt, kommt an jeden Link, dessen Slug er kennt – nicht an andere. Freigaben in Paperless deshalb mit Ablaufdatum anlegen.
- Die Unterscheidung PIN/SSO hängt an einem Verhalten des Proxys, nicht an einer dokumentierten Schnittstelle.
- CrowdSec sieht weder PIN-Versuche noch Anfragen an die App (TCP-Passthrough, kein HTTP-Log auf grammi), wie bei allen Proxy-Namen; es bleiben die Sperre des Proxys und der Login von Paperless.
- ursalias nginx loggt als Absender die Mesh-Adresse des Proxys, nicht die des Besuchers (kein `realip`: es würde die Adresse vor `allow`/`deny` umschreiben).

### Grafana: öffentliche Dashboards über `dash`

Seit 2026-10-23 lassen sich Dashboards nach außen teilen („Share externally“, in Grafana „öffentliche Dashboards“). Das Recht dazu hat nur die Grafana-Rolle Admin. Die vergibt der SSO-Login an die Pocket-ID-Gruppe `grafana_admins` (eigens dafür, `terraform/netbird/people.tf`; Mitglieder in Pocket ID pflegen, wirksam beim nächsten Grafana-Login), alle anderen bleiben Editor.

**Der Weg:** `dash.homelab.example` ist ein eigener Dienst im Reverse Proxy, **ohne Login**. Sein Ziel ist derselbe Entrypoint `apps` von Traefik auf grammi wie bei `metrics`, aber für diesen Namen lässt Traefik nur `/public-dashboards/`, `/api/public/` und `/public/` (Assets) zu Grafana durch. Alles andere beantwortet Traefik mit 404. Dieser Router hält die App von anonymen Besuchern fern, nicht der Proxy.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Jeder mit Link | Reverse Proxy → Traefik `apps` (Host `dash`) → Grafana | nur das freigegebene Dashboard, lesend |
| SSO | `metrics.homelab.example` | volle App |

**Link weitergeben:** Grafana baut den Link aus `root_url`, er lautet also `https://metrics.homelab.example/public-dashboards/<token>` – unter `metrics` landet ein Gast beim SSO-Login. Den Link für Gäste zeigt das Dashboard „Homelab / Shared dashboards“: ein Timer auf grammi fragt alle 10 Sekunden die Grafana-API ab und schreibt jede Freigabe mit ihrer `dash`-Adresse und den genutzten Template-Variablen als Metrik `grafana_public_dashboard_info` (`hosts/grammi/grafana-shares.nix`). Jedes Dashboard verlinkt oben rechts dorthin („Nach außen teilen“). Die Spalte „Verwalten“ öffnet den Freigabe-Dialog des jeweiligen Dashboards zum Pausieren und Widerrufen – ein Schalter direkt in der Tabelle geht nicht, weil Grafana Panel-Actions seine eigene API nur per POST/PUT aufrufen lässt und das Pausieren PATCH braucht. Die Tokens liegen damit in VictoriaMetrics, sichtbar für alle, die Grafana öffnen können.

**Was das bewusst in Kauf nimmt:**

- Der Token im Link ist das einzige Geheimnis, keine PIN davor. Ein öffentliches Dashboard ist nur lesbar, und in Grafana lässt es sich jederzeit pausieren oder löschen.
- Dashboards mit Template-Variablen teilt Grafana zwar, aber Panels, die eine Variable nutzen (etwa `$job` in Hosts Overview), bleiben für Gäste leer; dafür braucht es eine Kopie ohne Variablen. Die Spalte „Variablen“ in „Homelab / Shared dashboards“ zeigt, welche Freigabe das betrifft. Außerdem braucht jedes Panel die UID seiner Datenquelle; die UIDs sind deshalb in der Provisionierung festgelegt und in allen Dashboards eingetragen (`hosts/grammi/configuration.nix`).
- Wie bei allen Proxy-Namen sieht CrowdSec auf grammi nur, was Traefik im Entrypoint `apps` loggt, nicht den TLS-Teil davor.

### MQTT von außen: TLS-Passthrough zu Home Assistant

`mqtt.homelab.example:8883` ist das Mosquitto-Add-on auf Home Assistant, für MQTT-Geräte, die auch außerhalb der Wohnung laufen (AWTRIX NG auf einem Ulanzi TC002). Überall derselbe Name, derselbe Port und dasselbe Zertifikat, ein Gerät wird also einmal eingerichtet:

| Wo | Weg |
| --- | --- |
| Zu Hause | die OPNsense beantwortet `mqtt.homelab.example` mit HAs LAN-Adresse (lokaler DNS-Eintrag) → HA:8883 direkt, auch ohne Internet |
| Außen | öffentlicher CNAME auf den Reverse Proxy → `netbird-proxy` auf grammi, Port 8883 → durchs Mesh zu HA:8883 |

**HA ist ein NetBird-Peer** (NetBird-Add-on, `terraform/netbird/home-assistant.tf`), in einer eigenen Gruppe `home-assistant` – nicht in `servers`, es erreicht also genau zwei Dinge, und außer dem Proxy erreicht nichts HA. Die DNS-Verwaltung durch NetBird ist für die Gruppe aus: HA löst weiter über die OPNsense auf, auch wenn das Internet weg ist.

**TLS endet in Mosquitto, nicht am Proxy.** Der Service `mqtt` (`terraform/netbird/reverse-proxy.tf`) läuft im L4-Modus `tls` mit dem Peer HA als Ziel: Der Proxy liest nur die SNI und reicht die Verbindung unverändert durch. Für einen L4-Service mit eigenem Port bindet der Proxy diesen Port selbst auf allen Adressen (einen PROXY-Header muss dort nur 127.0.0.1 schicken); grammis Firewall öffnet 8883 in `hosts/grammi/netbird-proxy.nix`.

**Das Zertifikat** gilt für `homeassistant.homelab.example` und `mqtt.homelab.example`. HAs Let's-Encrypt-Add-on holt es per DNS-01 – aber ohne eigenen deSEC-Token (der ließe sich an keine Adresse binden, die Heimadresse wechselt). Es fragt stattdessen dns01proxy auf grammi (`hosts/grammi/dns01proxy.nix`, Provider `dns-httpreq`), unter `https://acme.homelab.example:8446`:

- Der Port ist nur im Mesh offen, und die Policy `home-assistant-acme` lässt nur HA hin. HA löst den Namen über die OPNsense auf (lokaler Eintrag auf grammis Mesh-Adresse, `tofu output acme_proxy_address`), alle anderen Peers über die NetBird-Zone.
- Der Proxy schreibt die TXT-Records mit grammis an die Adresse gebundenem Token. HAs Account (Passwort im Add-on, bcrypt-Hash in `hosts/grammi/dns01proxy.yaml`, `just dns01proxy-key-homeassistant`) darf nur Challenges für die beiden Namen oben beantworten.
- dns01proxy spricht selbst HTTPS und holt sein eigenes Zertifikat für `acme.homelab.example` auf demselben Weg.

**Die beiden lokalen DNS-Einträge** sind Host-Overrides in Unbound auf der OPNsense (Services → Unbound DNS → Overrides), von Hand gesetzt – der API-Schlüssel `inventory-ro` darf nur lesen:

| Name | Adresse | Wozu |
| --- | --- | --- |
| `mqtt.homelab.example` | 198.51.100.168 (HAs LAN-Adresse) | MQTT bleibt im Heimnetz und läuft auch ohne Internet |
| `acme.homelab.example` | 192.0.2.122 (grammis Mesh-Adresse, `tofu output acme_proxy_address`) | HA erreicht dns01proxy; NetBird verwaltet HAs DNS nicht |

Ändert sich HAs Adresse oder grammis Mesh-Adresse (neue Lease, NetBird-Neuregistrierung), muss der Override von Hand nachgezogen werden.

Das Add-on erneuert nicht von selbst: Eine HA-Automation startet es täglich und startet Mosquitto wöchentlich neu, damit das erneuerte Zertifikat geladen wird.

**Was das bewusst in Kauf nimmt:**

- Kein Login am Proxy – L4 hat keinen. Einzige Hürde sind die Benutzer von Mosquitto, und dazu gehört jeder Login, den das Add-on annimmt (seine eigene Liste und die Home-Assistant-Benutzer).
- Mosquitto sieht für jede Verbindung von außen die Mesh-Adresse des Proxys als Absender (das Add-on kann keinen PROXY-Header annehmen) – weder HA noch CrowdSec können also einzelne Clients per Adresse sperren. Der Proxy kann nach Land oder Adressbereich filtern (`access_restrictions`), vorerst nicht gesetzt.
- Die Erneuerung des Zertifikats braucht grammi und das Mesh – mit 30 Tagen Puffer vor Ablauf.
- Ein Gerät, das bei ausgefallenem Internet neu startet, braucht die Uhrzeit von woanders als aus dem Internet, um das Zertifikat zu prüfen.
