# Inputs and their pins

Only `nixpkgs` and `nixpkgs-unstable` move with the nightly auto-upgrade (`services.nixCache.prebuild.updateInputs` in `modules/deploy.nix`, updated by ursalia for every host). Anything that would lock the whole lab out on a broken release is pinned separately and bumped by hand.

| Input | Branch / tag | Used by | Nightly? | Expiry |
| --- | --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | all NixOS hosts | yes | – |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x, claude-code), aldrin (Immich Public Proxy), zorlock (mactop), docs-site (Zensical) | yes | per package, with the release bump that ships it (expected: 26.11) |
| `sops-nix` | main | all | no – by hand, diff read (runs as root with every secret) | – |
| `nixpkgs-netbird` | nixos-unstable | NetBird server and the clients of the NixOS hosts and zorlock (gusto: `netbirdio-tap`) | no – server first, then clients | once stable ships `netbird-server` and the dashboard, each at least at the running version (check at 26.11); then server and these clients together |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id package) | no | none – the IdP stays off the nightly update on purpose |
| `nixpkgs-opencloud` | nixos-unstable | aldrin (OpenCloud package) | no – OpenCloud cannot be downgraded | once stable reaches the running version (the aldrin build warns) |
| `nixpkgs-mealie` | nixos-unstable | grammi (Mealie package) | no – migrations only go forward, read the release notes | once stable ships at least the running version (expected: 26.11) |
| `nixpkgs-immich` | nixos-unstable | ursalia (Immich module and package) | no – migrations only go forward, read the release notes | once stable ships Immich 3.x at least at the running version (expected: 26.11) |
| `nixpkgs-karakeep` | nixos-unstable | ursalia (Karakeep package) | no – SQLite migrations only go forward, read the release notes | once stable ships at least the running version (expected: 26.11) |
| `nixpkgs-readeck` | nixos-unstable | ursalia (Readeck package; alert `PinnedPackageNewerRelease` a week after a newer upstream release) | no – SQLite migrations only go forward, read the changelog | once stable ships at least the running version (expected: 26.11) |
| `disko` | main | ursalia, tummi (all mounts) | no | – |
| `lanzaboote` | v1.2.0 | ursalia, tummi (Secure Boot) | no | – |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | no (no auto-upgrade) | – |
| `home-manager` | release-26.05 | gusto (dotfiles) | no – together with `nix-darwin` | – |
| `nix-homebrew` | main | Macs with Homebrew (gusto): the module that installs Homebrew | no – `just mac-upgrade` | – |
| `brew-src` | tag `7.0.11` (`flake = false`) | Macs with Homebrew: Homebrew itself, instead of nix-homebrew's own pin | no – edit the tag in `flake.nix` | – |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs with Homebrew: the pinned taps | no – `just mac-upgrade` | – |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird app (cask `netbird-ui`) | no – `just mac-upgrade` | – |
| `stablyai-orca-tap` | main (`flake = false`) | gusto: Orca (cask `orca`), pinned by `apps` | no – `just mac-upgrade` | – |

The deliberately bumped unstable pins (`nixpkgs-netbird`, `-opencloud`, `-mealie`, `-immich`) move on their own days; a bump lands on a revision another of them already has where the wanted version is there – one revision fewer to evaluate, one copy less of every library in the closures. Hosts and modules read a pin as `inputs.<pin>.legacyPackages.${system}` ([#17](https://github.com/admin/nixlab/issues/17), [#315](https://github.com/admin/nixlab/issues/315)).

The Homebrew inputs are the reason a cask has a fixed version: with `mutableTaps = false` Homebrew cannot update its taps itself, see [macOS hosts](../explanation/macos-hosts.md).

`nix flake check` additionally verifies that `hosts/grammi/dashboards/topology.json` matches what `topology.nix` currently generates – a new exporter without `just topology` fails the check.
