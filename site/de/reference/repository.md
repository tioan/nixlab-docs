# Repository-Struktur

Ein Flake, `nixosConfigurations` für fünf Hosts plus `darwinConfigurations` für die beiden Macs (zorlock, gusto) und zwei `devShells`: eine zum Arbeiten am Repo, eine mit dnscontrol für das DNSControl-Repo. Jeder Host bekommt eine explizite Modulliste in `flake.nix`; was fehlt, fehlt mit Begründung im Kommentar daneben.

| Pfad | Inhalt |
| --- | --- |
| `flake.nix` / `flake.lock` | Inputs, Host-Definitionen, Pakete, `lib.topology`, `lib.inventory`, `checks` |
| `modules/` | 17 geteilte Module: base, nix, ssh, firewall, networking (ifstate), acme, crowdsec, tailscale, netbird, metrics/metrics-shipping, logging/log-shipping, qemu-guest, deploy, auto-upgrade-git, docs-site |
| `modules/darwin/` | Für die Macs: `homebrew.nix` (eine Homebrew-Richtlinie für jeden darwin-Host) und `rebuild.sh` (die Mechanik hinter den `mac-*`-Rezepten) |
| `hosts/gusto/` | Die Workstation: `configuration.nix` (System, Casks, macOS-Einstellungen), `home.nix` und `ssh.nix` (home-manager), `ssh/*.pub` (öffentliche Hälften der 1Password-SSH-Schlüssel) |
| `.envrc` | direnv: lädt die devShell des Flakes (sops, age, tofu, …) im Checkout |
| `hosts/<host>/` | `configuration.nix`, Hardware, Dienst-Module, sops-Dateien (`secrets.yaml`, `netbird.yaml`, `desec.yaml`) |
| `pkgs/` | Eigene Pakete: garage-ui, logchef, paperless-gpt, prometheus-paperless-exporter, ollama-metrics-proxy |
| `terraform/netbird/` | OpenTofu: NetBird-Account, Policies, DNS-Zonen, Reverse-Proxy-Dienste, Personen/Gruppen (inkl. Pocket ID) |
| `terraform/desec-tokens/` | OpenTofu: eng gescopte deSEC-Tokens pro Host für DNS-01 |
| `terraform/github/` | OpenTofu: die Repos `nixlab` (privat) und `nixlab-docs` (öffentlich), Deploy-Keys pro Host |
| `topology.nix` | Generiert das Topologie-Dashboard für Grafana aus den Host-Configs |
| `inventory.json` / `inventory.nix` | Lab-Inventar (jede Maschine: Art, Site, Uplink, Beziehungen, Entsperren) und seine Prüfung, siehe [Inventar](inventory.md) |
| `inventory.schema.json` | JSON-Schema zum Bearbeiten von `inventory.json`, generiert |
| `tests/` | Tests, die `nix flake check` auswertet (`inventory.nix`) |
| `justfile` | Alle Bedienabläufe: deploy, secrets, netbird-\*, desec-\* |
| `docs/` | Diese Projektdokumentation: Seiten unter `site/{de,en}/`, Zensical-Konfiguration, Build (`build.sh`, `site-src.sh`, `assemble.py`, `gen-reference.py`), Paket der privaten Site (`package.nix`) und was sie sonst von Dritten laden würde – Schriften, glightbox (`assets.nix`), Installationsanleitungen (ursalia, cuckoosegg, gusto), Upstream-Issue-Entwürfe |
| `dnsconfig.js` | Symlink ins separate DNSControl-Repo – öffentliche DNS-Records leben dort |
| `.sops.yaml` | age-Empfänger pro Host, `admin` (Offline-Recovery) und `workstation` (1Password) |
