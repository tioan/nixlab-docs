# Services

Dienste sind nach Funktion benannt, nicht nach Produkt. Es gibt drei Arten der Erreichbarkeit: direkt öffentlich, öffentlich hinter dem NetBird-Reverse-Proxy mit SSO, oder nur im Mesh.

| Name (`.homelab.example`) | App | Host | Erreichbar |
| --- | --- | --- | --- |
| `auth` | Pocket ID | zummi | öffentlich (nginx) |
| `mesh` | NetBird Management/Dashboard | grammi | öffentlich (Traefik terminiert TLS) |
| `s3.aldrin` | Garage S3-API | aldrin | öffentlich (nginx) |
| `rezepte` | Mealie | grammi | Reverse Proxy + SSO |
| `grist` | Grist | grammi | Reverse Proxy + SSO |
| `logs` | logchef | grammi | Reverse Proxy + SSO |
| `metrics` | Grafana | grammi | Reverse Proxy + SSO |
| `dash` | Grafana, nur öffentliche Dashboards | grammi | Reverse Proxy ohne Login, Traefik lässt nur die Pfade öffentlicher Dashboards durch ([warum](../explanation/secrets-network-access.md#grafana-offentliche-dashboards-uber-dash)) |
| `vm` / `vl` | VictoriaMetrics / VictoriaLogs UI | grammi | Reverse Proxy + SSO |
| `s3-admin` | garage-ui | aldrin | nur Mesh |
| `dokumente` | Paperless + paperless-gpt (`/paperless-gpt/`) | ursalia | im Mesh direkt; von außen über den Reverse Proxy Freigabelinks per PIN und die App per SSO ([warum](../explanation/secrets-network-access.md#paperless-von-auen-freigabelinks-pin-und-app-sso)) |
| `llm` | Ollama (hinter Caddy) | zorlock | nur Mesh |
| `mqtt` | Mosquitto (Home-Assistant-Add-on) | Home Assistant (Heim-LAN, NetBird-Peer) | Port 8883, MQTT über TLS: zu Hause direkt zu HA (der Heimrouter (OPNsense) beantwortet den Namen lokal), von außen über den Reverse Proxy als TLS-Passthrough zum Peer, ohne SSO ([warum](../explanation/secrets-network-access.md#mqtt-von-auen-tls-passthrough-zu-home-assistant)) |
| `acme` | dns01proxy (DNS-01 für Home Assistant) | grammi | nur Mesh, Port 8446; HA löst ihn über den Heimrouter (OPNsense) auf ([warum](../explanation/secrets-network-access.md#mqtt-von-auen-tls-passthrough-zu-home-assistant)) |
| `doku` | Diese Dokumentation (private Fassung) | aldrin + ursalia | im Mesh nur Admin-Geräte ([warum](../explanation/secrets-network-access.md#private-doku-nur-admin-gerate)), ein A-Record je Host; von außen über den Reverse Proxy eine Weiterleitung auf die öffentliche Doku |

**Reverse Proxy:** Traefik auf grammi besitzt Port 443. `mesh.homelab.example` terminiert es selbst, alles andere reicht es per TCP-Passthrough mit PROXY-Protokoll v2 an `netbird-proxy` weiter, das TLS und ACME (tls-alpn-01) selbst macht. Login am Proxy ist SSO gegen Pocket ID, begrenzt auf die NetBird-Gruppen der jeweiligen App; `dokumente` zusätzlich mit PIN (nur Freigabelinks). Die Dienste auf grammi erreicht der Proxy alle über den Traefik-Entrypoint `apps` (Port 8090), der Wartungsschalter und Fehlerseiten davorsetzt ([Wartungsmodus](../how-to/maintenance.md)).

**Mesh-only-Namen:** Jeder Name ist eine eigene NetBird-DNS-Zone mit einem A-Record auf die Mesh-Adresse (192.0.2.x). Öffentliches DNS kennt sie nicht; das Zertifikat kommt per DNS-01 über deSEC.

**Querschnitt auf allen Linux-Hosts:** vmagent schickt Metriken, Vector schickt journald- und nginx-Logs an grammi. CrowdSec liest die nginx/Traefik-Logs auf den öffentlichen Hosts. restic-Backups gehen in Garage-Buckets auf aldrin, für Paperless zusätzlich append-only zu BorgBase.
