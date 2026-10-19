# Module

Die 17 Module unter `modules/` tragen die gemeinsame Konfiguration aller Hosts; jede Datei erklärt im Kopfkommentar, warum sie so ist. Die öffentliche Fassung enthält sie anonymisiert unter `modules/` – als Referenz, nicht direkt importierbar: einige lesen `hosts/<host>/*.yaml` und setzen sops-nix voraus. Vier haben eigene Optionen.

| Modul | Zweck | Optionen / Besonderheiten |
| --- | --- | --- |
| [auto-upgrade-git.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git.nix) | Nächtliches `nixos-rebuild switch`, committet und pusht die neue `flake.lock` zurück ins Repo | `services.autoUpgradeGit`: `enable`, `flakeDir`, `flakeAttr`, `updateInputs`, `dates`, `allowReboot`, `rebootWindow`, `deployKeySecret`, `gitAuthorEmail` |
| [log-shipping.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/log-shipping.nix) | journald- und nginx-Logs per Vector an VictoriaLogs | `services.logShipping`: `enable`, `victoriaLogsUrl` |
| [metrics-shipping.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics-shipping.nix) | vmagent scrapt die lokalen Exporter und schreibt per remote_write an VictoriaMetrics | `services.metricsShipping`: `enable`, `remoteWriteUrl`, `exporterPorts` |
| [deploy.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy.nix) | Die Lab-Policy für auto-upgrade-git: GitHub-Deploy-Key, gepinnter Hostkey, Reboot-Fenster 04:00–06:00 | getrennt vom Mechanismus, damit der wiederverwendbar bleibt |
| [acme.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/acme.nix) | ACME-Defaults für jeden TLS-Host: DNS-01 gegen deSEC | Token aus `hosts/<host>/desec.yaml` (von Tofu) |
| [netbird.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird.nix) | NetBird-Client im Mesh, Registrierung per Setup-Key, lokale Metriken | Setup-Key aus `hosts/<host>/netbird.yaml` (von Tofu) |
| [tailscale.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/tailscale.nix) | Gemeinsamer Tailscale-Agent | `tailscale serve` bleibt in der Host-Config |
| [ssh.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/ssh.nix) | Wer sich von wo anmelden darf: root nur über Mesh oder Tailscale | Schlüssel bleiben pro Host |
| [firewall.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/firewall.nix) | Öffentlich nur 22/80/443, Tailnet als vertrauenswürdiges Interface | |
| [crowdsec.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec.nix) | CrowdSec-Engine und Firewall-Bouncer, Whitelist für die Lab-Hosts | Umgehungen für Fehler in den nixpkgs-Modulen, im Kopf dokumentiert |
| [networking.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/networking.nix) | ifstate-Gerüst, systemd-resolved mit DNS-over-TLS, keine Fallback-Resolver | Adressen und Routen bleiben in der Host-Config |
| [metrics.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics.nix) | Prometheus-Exporter pro Host | Schutz über die Firewall statt über Bind-Adressen |
| [logging.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/logging.nix) | Begrenzt journald, das sonst bis 4 GB wächst | |
| [qemu-guest.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/qemu-guest.nix) | QEMU Guest Agent mit gesperrter RPC-Liste: Snapshots ja, Shell und Dateizugriff über den Kanal nein | |
| [nix.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/nix.nix) | Nix-Daemon, Garbage Collection, Store-Optimierung | |
| [docs-site.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/docs-site.nix) | Die private Doku-Site (Flake-Paket `docs-site`) unter `doku` im Mesh | `services.docsSite`: `enable`, `package`, `fqdn`, `allow` (Standard: das ganze Mesh; im Lab nur die Admin-Geräte aus `admin-peers.json`); auf aldrin und ursalia |
| [base.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/base.nix) | Locale, Konsole, Zeit und Werkzeuge zum Debuggen | |
