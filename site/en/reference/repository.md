# Repository layout

One flake, `nixosConfigurations` for five hosts plus `darwinConfigurations` for the two Macs (zorlock, gusto) and two `devShells`: one for working on the repo, one with dnscontrol for the DNSControl repo. Every host is built by `mkHost` or `mkDarwin` (`lib/hosts.nix`) from its profiles (`profiles/*.nix`) and the modules only it has; a profile it does not import is missing with the reason in a comment next to it.

| Path | Contents |
| --- | --- |
| `flake.nix` / `flake.lock` | Inputs, host definitions, packages, `lib.topology`, `lib.inventory`, `checks` |
| `lib/hosts.nix` | `mkHost` and `mkDarwin`: profiles + own modules + `hosts/<host>/configuration.nix`, module arguments `inputs` and `inventory` |
| `profiles/` | Module lists several hosts share: `common`, `pulled`, `public-vm`, `services`, `home-nuc`, `docs-site`, `darwin` |
| `modules/` | 18 shared modules: base, nix, hotfixes, ssh, firewall, networking (ifstate), acme, crowdsec, netbird, metrics/metrics-shipping, logging/log-shipping, qemu-guest, deploy, auto-upgrade-git, docs-site, maintenance |
| `modules/darwin/` | For the Macs: `homebrew.nix` (one Homebrew policy for every darwin host) and `rebuild.sh` (the engine behind the `mac-*` recipes) |
| `hosts/gusto/` | The workstation: `configuration.nix` (system, casks, macOS settings), `home.nix` and `ssh.nix` (home-manager), `ssh/*.pub` (public halves of the 1Password SSH keys) |
| `.envrc` | direnv: loads the flake's devShell (sops, age, tofu, …) in the checkout |
| `hosts/<host>/` | `configuration.nix`, hardware, service modules, sops files (`secrets.yaml`, `netbird.yaml`, `desec.yaml`) |
| `pkgs/` | Own packages, listed once in `pkgs/default.nix`: on every host as `pkgs.nixlab.<name>` (the flake's `overlays.default`), on the workstation as `nix build .#<name>`. Hosts never call a package file themselves (`checks.own-packages`) |
| `terraform/netbird/` | OpenTofu: NetBird account, policies, DNS zones, reverse proxy services, people/groups (incl. Pocket ID) |
| `terraform/desec-tokens/` | OpenTofu: narrowly scoped deSEC tokens per host for DNS-01 |
| `terraform/github/` | OpenTofu: the repositories `nixlab` (private) and `nixlab-docs` (public), deploy keys per host |
| `terraform/garage/` | OpenTofu: buckets, keys and permissions in Garage on aldrin (lifecycle rules by hand) |
| `topology.nix` | Generates the Grafana topology dashboard from the host configs |
| `inventory.json` / `inventory.nix` | Lab inventory (every machine: kind, site, uplink, relations, unlock) and its validation, see [Inventory](inventory.md) |
| `inventory.schema.json` | JSON Schema for editing `inventory.json`, generated |
| `tests/` | Tests evaluated by `nix flake check` (`inventory.nix`) |
| `justfile` / `just/` | All operational workflows (`just --list`): the `justfile` holds the shared settings (`hosts`, `mesh`) and imports `just/<area>.just` – deploy, mac, inventory, docs, tests, tofu (desec-\*, …), netbird-\*, secrets; longer shell lives in `scripts/` |
| `docs/` | This project documentation: pages under `site/{de,en}/`, Zensical config, build (`build.sh`, `site-src.sh`, `assemble.py`, `gen-reference.py`, `gen-llms.py`), the private site's package (`package.nix`) and what it would otherwise load from third parties – fonts, glightbox (`assets.nix`), install guides (ursalia, cuckoosegg, gusto), drafts of upstream issues |
| `dnsconfig.js` | Symlink into the separate DNSControl repo – public DNS records live there |
| `.sops.yaml` | age recipients per host, `admin` (offline recovery) and `workstation` (1Password) |
