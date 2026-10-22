# just-Rezepte

| Rezept | Zweck |
| --- | --- |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Host-Secrets auf dem Host editieren und zurückholen |
| `just topology` | Topologie-Dashboard neu erzeugen (sonst schlägt `nix flake check` fehl) |
| `just inventory` | Das geprüfte Inventar mit allem Abgeleiteten anzeigen ([Inventar](inventory.md)) |
| `just inventory-test` | `inventory.json` prüfen, die Tests der Validierung laufen lassen, Schema auf Aktualität prüfen |
| `just inventory-schema` | `inventory.schema.json` nach einer Formatänderung neu erzeugen |
| `just inventory-collect [--force] [host …]` | SSH-Host-Keys, Interfaces (MAC, Medium, Link-Local) und Hardware (Hersteller, Modell, Produkt-ID, Seriennummer) von den Geräten in `inventory.json` holen – füllt Lücken und meldet Abweichungen; `--force` übernimmt die Werte des Geräts |
| `just known-hosts` | `~/.ssh/known_hosts.nixlab` aus dem Inventar schreiben – für eine Workstation außerhalb dieses Repos; gusto bekommt die Schlüssel systemweit |
| `just netbird-plan` / `netbird-apply` | NetBird-Account ändern; apply schreibt auch `expected-peers.json` (committen, grammi deployen) und `admin-peers.json` (committen, aldrin und ursalia deployen) neu |
| `just netbird-proxy-certs` | Proxy-Diensten ohne Zertifikat eins holen und das Dashboard nachziehen (NetBird #7118); läuft am Ende von `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | Neue zufällige PIN für Paperless-Freigabelinks von außen (danach `netbird-apply`) bzw. aktuelle anzeigen |
| `just netbird-key <host>` | Neuer Setup-Key für einen Host, 24 h Zeit zum Deployen |
| `just netbird-import` | Verlorenen Tofu-State aus dem Account wiederherstellen |
| `just netbird-renew-token` | Jährliche Erneuerung des Service-User-Tokens |
| `just github-key <host>` | Neuer GitHub-Deploy-Key für einen Host (Schlüssel per sops, Registrierung per Tofu) |
| `just github-plan` / `github-apply` | Repos und Deploy-Keys auf GitHub ändern |
| `just desec-key <host>` / `desec-verify` | deSEC-Token tauschen bzw. Scopes von jedem Host aus prüfen |
| `just nanokvm-mcp-key` | MCP-API-Key des NanoKVM Go+ verschlüsselt für ursalia ablegen (danach committen, ursalia deployen) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude-Code-Brücke zum NanoKVM Go+ auf ursalia: einmal einrichten, starten, stoppen, Zustand, Log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (Standard gusto, oder zorlock per SSH): zeigen, was ein Switch ändern würde (nvd, Homebrew entfernt/installiert), oder schalten mit Zusammenfassung – siehe [macOS-Hosts](../explanation/macos-hosts.md) |
| `just mac-upgrade` | Auf gusto: Homebrew-Pins aktualisieren, schalten, `brew upgrade`, NetBird-Version neben dem Mesh-Pin; `flake.lock` committen |
| `just gc <host>` | Store-Generationen älter als 7 Tage löschen |
| `just docs` | Diese Doku bauen: private PDFs (de/en) und die anonymisierte öffentliche Fassung (README, PDFs, Site-Quellen, Module) in `public-docs/` (Clone von `nixlab-docs`, gitignored), dort committet und gepusht; GitHub baut daraus die Site |
| `just docs-serve` | Private Site mit echten Werten lokal bauen und unter `http://127.0.0.1:8000` zeigen |

Rezepte, die sops brauchen, bekommen den age-Key der Workstation über `SOPS_AGE_KEY_CMD` aus 1Password. Auf gusto setzt home-manager die Variable, und `op` entsperrt über die 1Password-App (Touch ID); sops, tofu und age kommen aus der devShell (direnv im Checkout). Ohne diese Einrichtung:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```
