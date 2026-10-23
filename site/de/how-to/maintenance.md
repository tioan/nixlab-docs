# Wartungsmodus

Ein Dienst lässt sich für eine Wartung abschalten, ohne ihn anzuhalten: Wer ihn aufruft, bekommt eine Seite mit Status 503, dem Grund und `Retry-After`; der Dienst selbst läuft weiter und ist für Tests erreichbar. Dieselbe Seite erscheint mit 502 oder 504, wenn der Dienst gerade nicht antwortet – etwa während eines `switch`. Modul: `modules/maintenance.nix`.

## Wie es funktioniert { #how-it-works }

Jeder HTTP-Weg zu einem Dienst endet an nginx oder Traefik auf dem Host, auf dem der Dienst läuft – auch der Weg über den NetBird-Reverse-Proxy, der nur weiterreicht. Dort sitzen Wartungsschalter und Fehlerseiten; die Software davor ist ein Detail pro Host.

<figure class="nx-diagram">
<svg viewBox="0 0 680 530" role="img" aria-label="Wege zu den Diensten: jeder HTTP-Weg endet an nginx oder Traefik auf dem Ziel-Host, dort sitzen Wartungsschalter und Fehlerseiten" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}</style>
<text class="nx-s" x="62" y="30" text-anchor="middle">Quelle</text>
<text class="nx-s" x="172" y="30" text-anchor="middle">Eingang grammi</text>
<text class="nx-s" x="298" y="30" text-anchor="middle">Proxy</text>
<text class="nx-s" x="432" y="30" text-anchor="middle">Front am Ziel</text>
<text class="nx-s" x="584" y="30" text-anchor="middle">Dienste</text>
<g class="nx-gray"><rect x="20" y="48" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="78" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 73 H368"/><path class="nx-line" d="M362 69 L368 73 L362 77"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="48" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="70" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="87" text-anchor="middle">aldrin, zummi</text></a>
<path class="nx-line" d="M494 73 H506"/><path class="nx-line" d="M500 69 L506 73 L500 77"/>
<g class="nx-gray"><rect x="508" y="48" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="69" text-anchor="middle">s3.aldrin, cloud,</text><text class="nx-s" x="584" y="85" text-anchor="middle">auth</text></g>
<g class="nx-gray"><rect x="20" y="110" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="140" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 135 H116"/><path class="nx-line" d="M110 131 L116 135 L110 139"/>
<g class="nx-gray"><rect x="118" y="110" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="140" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 135 H238"/><path class="nx-line" d="M232 131 L238 135 L232 139"/>
<g class="nx-gray"><rect x="240" y="110" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="140" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 135 H368"/><path class="nx-line" d="M362 131 L368 135 L362 139"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="110" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="132" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="149" text-anchor="middle">ursalia :8092</text></a>
<path class="nx-line" d="M494 135 H506"/><path class="nx-line" d="M500 131 L506 135 L500 139"/>
<g class="nx-gray"><rect x="508" y="110" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="140" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="172" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="202" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 197 H116"/><path class="nx-line" d="M110 193 L116 197 L110 201"/>
<g class="nx-gray"><rect x="118" y="172" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="202" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 197 H238"/><path class="nx-line" d="M232 193 L238 197 L232 201"/>
<g class="nx-gray"><rect x="240" y="172" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="202" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 197 H368"/><path class="nx-line" d="M362 193 L368 197 L362 201"/>
<a data-target="traefik" tabindex="0" role="link" class="nx-teal"><rect x="370" y="172" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="194" text-anchor="middle">Traefik :8090</text><text class="nx-s" x="432" y="211" text-anchor="middle">alle grammi-Apps</text></a>
<path class="nx-line" d="M494 197 H506"/><path class="nx-line" d="M500 193 L506 197 L500 201"/>
<g class="nx-gray"><rect x="508" y="172" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="193" text-anchor="middle">vm, vl, rezepte,</text><text class="nx-s" x="584" y="209" text-anchor="middle">grist, logs, metrics</text></g>
<g class="nx-gray"><rect x="20" y="234" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="264" text-anchor="middle">Mesh</text></g>
<path class="nx-line" d="M104 259 H368"/><path class="nx-line" d="M362 255 L368 259 L362 263"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="234" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="256" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="273" text-anchor="middle">ursalia :443</text></a>
<path class="nx-line" d="M494 259 H506"/><path class="nx-line" d="M500 255 L506 259 L500 263"/>
<g class="nx-gray"><rect x="508" y="234" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="264" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="296" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="326" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 321 H238"/><path class="nx-line" d="M232 317 L238 321 L232 325"/>
<g class="nx-gray"><rect x="240" y="296" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="318" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="335" text-anchor="middle">:8883, nur TCP</text></g>
<path class="nx-line" d="M356 321 H368"/><path class="nx-line" d="M362 317 L368 321 L362 325"/>
<g class="nx-gray"><rect x="370" y="296" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="326" text-anchor="middle">keine</text></g>
<path class="nx-line" d="M494 321 H506"/><path class="nx-line" d="M500 317 L506 321 L500 325"/>
<g class="nx-gray"><rect x="508" y="296" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="326" text-anchor="middle">mqtt (Home Assistant)</text></g>
<g class="nx-gray"><rect x="20" y="358" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="388" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 383 H116"/><path class="nx-line" d="M110 379 L116 383 L110 387"/>
<g class="nx-gray"><rect x="118" y="358" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="388" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 383 H238"/><path class="nx-line" d="M232 379 L238 383 L232 387"/>
<g class="nx-gray"><rect x="240" y="358" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="380" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="397" text-anchor="middle">Ziel umgestellt</text></g>
<path class="nx-line" d="M356 383 H368" stroke-dasharray="5 4"/><path class="nx-line" d="M362 379 L368 383 L362 387"/>
<a data-target="proxy-maintenance" tabindex="0" role="link" class="nx-teal"><rect x="370" y="358" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="380" text-anchor="middle">Wartungsseite</text><text class="nx-s" x="432" y="397" text-anchor="middle">grammi :8090</text></a>
<g class="nx-gray"><rect x="508" y="358" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="379" text-anchor="middle">wenn der Ziel-Host</text><text class="nx-s" x="584" y="395" text-anchor="middle">ganz aus ist</text></g>
<a data-target="switching" tabindex="0" role="link" class="nx-teal"><rect x="20" y="430" width="640" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="453" text-anchor="middle">Gemeinsam auf jedem Host mit Front</text><text class="nx-s" x="340" y="472" text-anchor="middle">Flag in /var/lib/maintenance · Seite 503/502/504 · Bypass-Cookie</text></a>
<g class="nx-teal"><rect x="20" y="504" width="14" height="14" rx="3" stroke-width="1"/></g><text class="nx-s" x="42" y="515">Wartungs-Check und Fehlerseiten</text>
<g class="nx-gray"><rect x="340" y="504" width="14" height="14" rx="3" stroke-width="1" stroke-dasharray="3 2"/></g><text class="nx-s" x="362" y="515">gestrichelt: Proxy-Wartung, nur bei Bedarf</text>
</svg>
</figure>

- **Flag**: `/var/lib/maintenance/<fqdn>` (oder `all` für den ganzen Host). Der Inhalt der Datei ist der Grund auf der Seite. Die Flags überstehen einen Neustart – eine Wartung bleibt zu, bis sie jemand beendet.
- **Seite**: ein kleines Programm auf jedem Host (`maintenance-responder`, nur 127.0.0.1:8089, startet bei Bedarf über systemd). Es entscheidet für nginx und Traefik gleich zwischen Wartung (503) und Störung (502/504).
- **Bypass**: ein Cookie für alle Namen unter `homelab.example`, mit dem der Dienst trotz Wartung im Browser erreichbar bleibt.

## Ein- und ausschalten { #switching }

Vom Arbeitsrechner; der Host wird über `inventory.json` gefunden:

```bash
just maintenance dokumente on "Paperless-Upgrade, bis ca. 22 Uhr"
```

```bash
just maintenance dokumente off
```

```bash
just maintenance-list
```

Ein Name ohne Punkt bekommt `.homelab.example` angehängt. Ein ganzer Host (alle Namen mit Wartungsschalter dort):

```bash
just maintenance all on "Umzug auf neue Hardware" aldrin
```

```bash
just maintenance all off "" aldrin
```

Auf dem Host selbst geht dasselbe mit `maintenance on|off|status`. Ein Neuladen von nginx oder Traefik ist nicht nötig; nginx prüft das Flag bei jeder Anfrage, Traefik übernimmt die Änderung nach zwei bis vier Sekunden.

Welche Namen einen Wartungsschalter haben:

| Host | Namen | Front |
| --- | --- | --- |
| aldrin | `s3.aldrin`, `cloud` | nginx |
| zummi | `auth` | nginx |
| ursalia | `dokumente` (443 und der Proxy-Listener 8092) | nginx |
| grammi | alle Namen aus `hosts/grammi/proxy-services.json` | Traefik `:8090` |

Nebenwirkungen: `s3.aldrin` in Wartung heißt, dass die nächtlichen restic-Backups aller Hosts scheitern; `auth` in Wartung heißt, dass sich niemand neu per Pocket ID anmelden kann. `s3-admin` (garage-ui) hat nur die Fehlerseiten: Sein 443 ist öffentlich offen, und die Wartungsprüfung liefe vor dessen Mesh-Sperre (`allow`/`deny`).

## Dienst trotzdem sehen { #bypass }

1. Token in die Zwischenablage holen (wird nie angezeigt):

    ```bash
    just maintenance-key
    ```

2. `https://<name>/_maintenance/bypass` öffnen, z. B. `https://dokumente.homelab.example/_maintenance/bypass`, Token einfügen.

Das Cookie gilt 12 Stunden für alle Namen unter `homelab.example`, auch für den Rückweg nach dem Login bei Pocket ID. Löschen: `https://<name>/_maintenance/clear`. Der Bypass ist Komfort, keine Sicherheitsgrenze – Login, SSO am Proxy und Mesh-Sperren gelten weiter. Das Token liegt per sops in `hosts/<host>/maintenance.yaml` (gleiches Token auf allen vier Hosts); neu erzeugen: alle vier Dateien löschen, `just maintenance-token`, committen, die vier Hosts deployen.

Der Schlüssel wird per Formular geschickt, nicht als `?key=` in der Adresse: Adressen stehen in den Zugriffsprotokollen, und die landen in VictoriaLogs.

## Hinter der Wartung testen mit ssh -L { #testing-behind }

Für Prüfungen ohne Browser – Healthcheck, API, Versionsabfrage – reicht ein Tunnel direkt zum Dienst, an nginx und Traefik vorbei:

```bash
ssh -L 8000:127.0.0.1:8000 root@ursalia.peer.homelab.example
```

```bash
curl -sI http://localhost:8000/api/
```

Weitere Beispiele: Grafana `ssh -L 3000:127.0.0.1:3000 root@grammi.peer.homelab.example`, Garage-S3 `ssh -L 3900:127.0.0.1:3900 root@aldrin.peer.homelab.example` (dann ein S3-Client gegen `http://localhost:3900`).

Für einen Test im Browser taugt das meist nicht: Dienste, die ihre eigene Adresse prüfen, lehnen `localhost` ab. paperless vergleicht beim Login den `Origin` mit `PAPERLESS_URL` (CSRF), OpenCloud und alles mit OIDC leiten nach der Anmeldung auf ihre echte Adresse zurück – die gerade in Wartung ist. Für den Browser ist der [Bypass](#bypass) da.

## Wenn der Host ganz aus ist { #proxy-maintenance }

Ist der Ziel-Host selbst aus (Neustart, Umzug), fehlt auch seine Wartungsseite, und der NetBird-Proxy zeigt seinen eigenen Fehler. Für die Dienste außerhalb von grammi (`dokumente`, `doku`) lässt sich das Proxy-Ziel deshalb auf grammi umstellen, wo Traefik jeden Namen, den es nicht selbst bedient, mit der Wartungsseite beantwortet:

```bash
just proxy-maintenance dokumente on "ursalia wird neu installiert"
```

```bash
just proxy-maintenance dokumente off
```

Das schreibt `terraform/netbird/proxy-maintenance.json`, ruft `just netbird-apply` auf und setzt bzw. löscht das Flag auf grammi. Danach `proxy-maintenance.json` und `expected-peers.json` committen (solange umgestellt ist, fällt der Host aus den Zielen des Proxys). Der Login (SSO, PIN) bleibt davor; aus dem Mesh direkt bleibt der Host natürlich unerreichbar.

## Fehlerseiten bei 502 und 504 { #error-pages }

Ohne Schalter: Antwortet der Dienst nicht (502) oder zu langsam (504), zeigt die Front dieselbe Seite mit „Gerade nicht erreichbar“ und dem echten Statuscode.

### nginx { #nginx }

nginx ersetzt nur seine eigenen Fehler (`error_page`). Fehlerantworten des Dienstes selbst kommen unverändert durch – `proxy_intercept_errors` bleibt aus, damit S3-Clients ihr XML und OIDC-Clients ihr JSON bekommen.

### Traefik { #traefik }

Traefik ersetzt mit der `errors`-Middleware auch Antworten des Dienstes, deshalb nur 502 und 504, nicht 503. Die Wartungs-Router erzeugt `maintenance-traefik-sync` aus den Flags in `/run/traefik-dynamic/`, das Traefik beobachtet. Der Kontroll-Endpunkt `mesh.homelab.example` bekommt nie einen Wartungsschalter.

## Neuen Dienst aufnehmen { #new-service }

- **nginx**: den vHost (Attributname) in `services.maintenance.nginx.vhosts` des Hosts eintragen, oder in `nginx.errorPagesOnly` für nur die Fehlerseiten. Nicht für vHosts mit `allow`/`deny`, deren Port auch Abgewiesene erreichen – die Wartungsprüfung läuft vor `allow`/`deny`.
- **grammi**: jeder Eintrag in `hosts/grammi/proxy-services.json` ist automatisch dabei.
- **Neuer Host**: `./modules/maintenance.nix` in `flake.nix` importieren, `services.maintenance.enable = true`, den Host in `.sops.yaml` (`maintenance`) und in `just maintenance-token` aufnehmen und das Token neu erzeugen.
