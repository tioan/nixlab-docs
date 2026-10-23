# Modules

The 19 modules under `modules/` carry the configuration shared by all hosts; every file explains in its header comment why it is the way it is. The public version contains them anonymised under `modules/` – as a reference, not directly importable: some read `hosts/<host>/*.yaml` and assume sops-nix. Five have options of their own.

| Module | Purpose | Options / notes |
| --- | --- | --- |
| [auto-upgrade-git.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git.nix) | Nightly `nixos-rebuild switch`, commits and pushes the new `flake.lock` back to the repo | `services.autoUpgradeGit`: `enable`, `flakeDir`, `flakeAttr`, `updateInputs`, `dates`, `allowReboot`, `rebootWindow`, `deployKeySecret`, `gitAuthorEmail` |
| [log-shipping.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/log-shipping.nix) | journald and nginx logs to VictoriaLogs via Vector | `services.logShipping`: `enable`, `victoriaLogsUrl` |
| [metrics-shipping.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics-shipping.nix) | vmagent scrapes the local exporters and remote-writes to VictoriaMetrics | `services.metricsShipping`: `enable`, `remoteWriteUrl`, `exporterPorts` |
| [deploy.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy.nix) | The lab's policy for auto-upgrade-git: GitHub deploy key, pinned host key, reboot window 04:00–06:00 | kept apart from the mechanism so that stays reusable |
| [acme.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/acme.nix) | ACME defaults for every TLS host: DNS-01 against deSEC | token from `hosts/<host>/desec.yaml` (from Tofu) |
| [netbird.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird.nix) | NetBird client in the mesh, registration via setup key, local metrics | setup key from `hosts/<host>/netbird.yaml` (from Tofu) |
| [tailscale.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/tailscale.nix) | Shared Tailscale agent | `tailscale serve` stays in the host config |
| [ssh.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/ssh.nix) | Who may log in from where: root only via mesh or Tailscale | keys stay per host |
| [firewall.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/firewall.nix) | Only 22/80/443 public, tailnet as trusted interface | |
| [crowdsec.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec.nix) | CrowdSec engine and firewall bouncer, whitelist for the lab hosts | workarounds for bugs in the nixpkgs modules, documented in the header |
| [networking.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/networking.nix) | ifstate skeleton, systemd-resolved with DNS over TLS, no fallback resolvers | addresses and routes stay in the host config |
| [metrics.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics.nix) | Prometheus exporters per host | protected by the firewall instead of bind addresses |
| [logging.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/logging.nix) | Bounds journald, which otherwise grows up to 4 GB | |
| [qemu-guest.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/qemu-guest.nix) | QEMU guest agent with an RPC deny list: snapshots yes, shell and file access over the channel no | |
| [nix.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/nix.nix) | Nix daemon, garbage collection, store optimisation | |
| [docs-site.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/docs-site.nix) | The private docs site (flake package `docs-site`) under `doku` on the mesh | `services.docsSite`: `enable`, `package`, `fqdn`, `allow` (default: the whole mesh; in the lab only the admin devices from `admin-peers.json`); on aldrin and ursalia |
| [maintenance.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/maintenance.nix) | Maintenance mode for nginx and Traefik: a flag file switches a name to a 503 page, the same page on 502/504 | `services.maintenance`, see [Maintenance mode](../how-to/maintenance.md) |
| [hotfixes.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/hotfixes.nix) | Package hotfixes that switch themselves off and warn once nixpkgs has the fix | module argument `hotfix`, overlays from `modules/hotfixes/`, see [Hotfix a package](../how-to/hotfix.md) |
| [base.nix](https://github.com/tioan/nixlab-docs/blob/main/modules/base.nix) | Locale, console, time and tools for debugging | |
