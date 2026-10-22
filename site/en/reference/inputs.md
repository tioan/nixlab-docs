# Inputs and their pins

Only `nixpkgs`, `nixpkgs-unstable` and `sops-nix` move with the nightly auto-upgrade (`updateInputs` in `modules/deploy.nix`). Anything that would lock the whole lab out on a broken release is pinned separately and bumped by hand.

| Input | Branch / tag | Used by | Nightly? |
| --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | all NixOS hosts | yes |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x), zorlock (mactop) | yes |
| `sops-nix` | main | all | yes |
| `nixpkgs-netbird` | nixos-unstable | NetBird server and all clients | no – server first, then clients |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id package) | no |
| `disko` | main | ursalia (all mounts) | no |
| `lanzaboote` | v1.1.0 | ursalia (Secure Boot) | no |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | no (no auto-upgrade) |
| `home-manager` | release-26.05 | gusto (dotfiles) | no – together with `nix-darwin` |
| `nix-homebrew` | main | Macs with Homebrew (gusto): Homebrew itself | no – `just mac-upgrade` |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs with Homebrew: the pinned taps | no – `just mac-upgrade` |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird app (cask `netbird-ui`) | no – `just mac-upgrade` |

The Homebrew inputs are the reason a cask has a fixed version: with `mutableTaps = false` Homebrew cannot update its taps itself, see [macOS hosts](../explanation/macos-hosts.md).

`nix flake check` additionally verifies that `hosts/grammi/dashboards/topology.json` matches what `topology.nix` currently generates – a new exporter without `just topology` fails the check.
