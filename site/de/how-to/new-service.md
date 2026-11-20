# Neuen Dienst veröffentlichen

Dienste heißen nach ihrer Funktion (`rezepte`, nicht `mealie`); neue Webdienste auf grammi nutzen PostgreSQL. Zuerst entscheiden, wie der Dienst erreichbar sein soll – davon hängt ab, welche Dateien sich ändern.

| Erreichbarkeit | Für | Beispiele |
| --- | --- | --- |
| Nur im Mesh | Admin-Oberflächen, Dienste für die eigenen Geräte | `s3-admin`, `ollama` |
| Öffentlich hinter dem Reverse Proxy mit SSO | Web-Apps, die auch von unterwegs ohne NetBird-App erreichbar sein sollen | `rezepte`, `grist`, `metrics`, `dokumente` |
| Direkt öffentlich | Dienste mit eigenem Login für Maschinen oder alle | `auth`, `s3.aldrin` |

## Nur im Mesh

1. In `terraform/netbird/mesh-services.tf` eine Zeile unter `local.mesh_services`: Name → Host(s). Daraus entsteht eine eigene NetBird-DNS-Zone mit A-Record(s) auf die Mesh-Adresse(n); öffentliches DNS kennt den Namen nicht.
2. `just netbird-apply` – neue Zonen kommen seit NetBird 0.81 ohne Neustart bei den Clients an.
3. Auf dem Host einen vHost mit `lab.vhosts.<name> = { port = …; meshOnly = true; }` – Zertifikat über DNS-01 (deSEC), Allow-Liste nur fürs Mesh, Security-Header und Wartungsschalter kommen mit ([Web-Grundlage](../explanation/web-baseline.md#der-vhost-helfer)).
4. Braucht der Dienst ein Zertifikat per DNS-01: `just desec-names` und `just desec-apply` – jeder deSEC-Token darf nur die `_acme-challenge`-Records der Namen seines Hosts schreiben (`terraform/desec-tokens/acme-names.json`, abgeleitet aus `security.acme.certs`). `nix flake check` schlägt fehl, solange die Datei fehlt.
5. Host deployen, `just topology` (neuer vHost).

## Öffentlich hinter dem Reverse Proxy

Für Dienste auf grammi:

1. Eintrag in `hosts/grammi/proxy-services.json`: Name → App, Port, Pocket-ID-Gruppen, optional `start` (wohin `/` weiterleitet). Tofu (`reverse-proxy.tf`), Traefik und `topology.nix` lesen dieselbe Datei; der Proxy erreicht jede App über Traefik `:8090`.
2. Der Dienst lauscht nur auf `127.0.0.1` – Traefik verbindet sich über Loopback, mehr braucht es nicht ([Apps auf grammi](../explanation/secrets-network-access.md#apps-auf-grammi-nur-uber-traefik-8090)).
3. In DNSControl einen CNAME `<name>` → `proxy.homelab.example` pushen – einige Minuten vor dem Apply, sonst cacht der Resolver NXDOMAIN.
4. Erst grammi deployen, dann `just netbird-apply`. Das ruft am Ende `just netbird-proxy-certs` auf: Es fragt jeden neuen Namen einmal von außen ab, damit der Proxy sein Zertifikat holt, und startet `netbird-proxy` danach einmal neu – sonst hängt das Dashboard bei „Issuing certificate…“ (NetBird-Diskussion #7118).

Dienste auf anderen Hosts bekommen eine eigene Ressource in `terraform/netbird/reverse-proxy.tf` mit dem Host als Peer-Ziel (Beispiele: `dokumente` auf ursalia – SSO für die App, Freigabelinks unter `/share/` ohne Anmeldung –, `doku` auf aldrin). Auch hier: CNAME vorher pushen, `just netbird-apply` erledigt die Zertifikate.

## Direkt öffentlich

nginx-vHost auf dem Host (ACME per DNS-01), A/AAAA-Records in DNSControl, CrowdSec liest die nginx-Logs mit. Nur für Dienste, die ohnehin eine eigene Anmeldung haben.

## Danach

- Doku: [Services](../reference/services.md), bei neuem Host-Verzeichnis-Inhalt auch [Inhalt von hosts/&lt;host&gt;/](../reference/host-directory.md).
- Dual-Stack, wo es geht (A und AAAA).
- Wartungsschalter und Fehlerseiten: [Wartungsmodus](maintenance.md#new-service) – auf grammi automatisch, auf anderen Hosts ein Eintrag im Host.
