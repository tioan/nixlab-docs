# Inputs und ihre Pins

Nur `nixpkgs` und `nixpkgs-unstable` laufen im nächtlichen Auto-Upgrade mit (`services.nixCache.prebuild.updateInputs` in `modules/deploy.nix`, aktualisiert von ursalia für alle Hosts). Alles, was bei einem kaputten Release das ganze Lab aussperren würde, ist separat gepinnt und wird von Hand gebumpt.

| Input | Branch / Tag | Wer nutzt es | Nachts mit? |
| --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | alle NixOS-Hosts | ja |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x), zorlock (mactop) | ja |
| `sops-nix` | main | alle | nein – von Hand, Diff gelesen (läuft als root mit allen Secrets) |
| `nixpkgs-netbird` | nixos-unstable | NetBird-Server und alle Clients | nein – Server zuerst, dann Clients |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id-Paket) | nein |
| `disko` | main | ursalia, tummi (alle Mounts) | nein |
| `lanzaboote` | v1.2.0 | ursalia, tummi (Secure Boot) | nein |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | nein (kein Auto-Upgrade) |
| `home-manager` | release-26.05 | gusto (Dotfiles) | nein – zusammen mit `nix-darwin` |
| `nix-homebrew` | main | Macs mit Homebrew (gusto): das Modul, das Homebrew installiert | nein – `just mac-upgrade` |
| `brew-src` | Tag `7.0.11` (`flake = false`) | Macs mit Homebrew: Homebrew selbst, statt des eigenen Pins von nix-homebrew | nein – Tag in `flake.nix` ändern |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs mit Homebrew: die festgeschriebenen Taps | nein – `just mac-upgrade` |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird-App (Cask `netbird-ui`) | nein – `just mac-upgrade` |
| `stablyai-orca-tap` | main (`flake = false`) | gusto: Orca (Cask `orca`), gepinnt von `apps` | nein – `just mac-upgrade` |

Die Homebrew-Inputs sind der Grund, warum ein Cask eine feste Version hat: Mit `mutableTaps = false` kann Homebrew seine Taps nicht selbst aktualisieren, siehe [macOS-Hosts](../explanation/macos-hosts.md).

`nix flake check` prüft zusätzlich, dass `hosts/grammi/dashboards/topology.json` zu dem passt, was `topology.nix` gerade erzeugt – ein neuer Exporter ohne `just topology` lässt den Check fehlschlagen.
