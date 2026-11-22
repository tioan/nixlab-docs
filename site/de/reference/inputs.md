# Inputs und ihre Pins

Nur `nixpkgs` und `nixpkgs-unstable` laufen im nächtlichen Auto-Upgrade mit (`services.nixCache.prebuild.updateInputs` in `modules/deploy.nix`, aktualisiert von ursalia für alle Hosts). Alles, was bei einem kaputten Release das ganze Lab aussperren würde, ist separat gepinnt und wird von Hand gebumpt.

| Input | Branch / Tag | Wer nutzt es | Nachts mit? | Ablauf |
| --- | --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | alle NixOS-Hosts | ja | – |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x, claude-code), aldrin (Immich Public Proxy), zorlock (mactop), docs-site (Zensical) | ja | pro Paket mit dem Release-Wechsel, der es liefert (erwartet: 26.11) |
| `sops-nix` | main | alle | nein – von Hand, Diff gelesen (läuft als root mit allen Secrets) | – |
| `nixpkgs-netbird` | nixos-unstable | NetBird-Server und die Clients der NixOS-Hosts und von zorlock (gusto: `netbirdio-tap`) | nein – Server zuerst, dann Clients | sobald Stable `netbird-server` und das Dashboard jeweils mindestens in der laufenden Version liefert (beim Wechsel auf 26.11 prüfen); dann Server und diese Clients zusammen |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id-Paket) | nein | keiner – der IdP bleibt absichtlich aus dem nächtlichen Update |
| `nixpkgs-opencloud` | nixos-unstable | aldrin (OpenCloud-Paket) | nein – OpenCloud lässt sich nicht downgraden | sobald Stable die laufende Version erreicht (der aldrin-Build warnt) |
| `nixpkgs-mealie` | nixos-unstable | grammi (Mealie-Paket) | nein – Migrationen gehen nur vorwärts, Release-Notes lesen | sobald Stable mindestens die laufende Version liefert (erwartet: 26.11) |
| `nixpkgs-immich` | nixos-unstable | ursalia (Immich-Modul und -Paket) | nein – Migrationen gehen nur vorwärts, Release-Notes lesen | sobald Stable Immich 3.x mindestens in der laufenden Version liefert (erwartet: 26.11) |
| `nixpkgs-karakeep` | nixos-unstable | ursalia (Karakeep-Paket) | nein – SQLite-Migrationen gehen nur vorwärts, Release-Notes lesen | sobald Stable mindestens die laufende Version liefert (erwartet: 26.11) |
| `nixpkgs-readeck` | nixos-unstable | ursalia (Readeck-Paket; Alarm `PinnedPackageNewerRelease` eine Woche nach einem neueren Upstream-Release) | nein – SQLite-Migrationen gehen nur vorwärts, Changelog lesen | sobald Stable mindestens die laufende Version liefert (erwartet: 26.11) |
| `disko` | main | ursalia, tummi (alle Mounts) | nein | – |
| `lanzaboote` | v1.2.0 | ursalia, tummi (Secure Boot) | nein | – |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | nein (kein Auto-Upgrade) | – |
| `home-manager` | release-26.05 | gusto (Dotfiles) | nein – zusammen mit `nix-darwin` | – |
| `nix-homebrew` | main | Macs mit Homebrew (gusto): das Modul, das Homebrew installiert | nein – `just mac-upgrade` | – |
| `brew-src` | Tag `7.0.11` (`flake = false`) | Macs mit Homebrew: Homebrew selbst, statt des eigenen Pins von nix-homebrew | nein – Tag in `flake.nix` ändern | – |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs mit Homebrew: die festgeschriebenen Taps | nein – `just mac-upgrade` | – |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird-App (Cask `netbird-ui`) | nein – `just mac-upgrade` | – |
| `stablyai-orca-tap` | main (`flake = false`) | gusto: Orca (Cask `orca`), gepinnt von `apps` | nein – `just mac-upgrade` | – |

Die absichtlich von Hand gebumpten unstable-Pins (`nixpkgs-netbird`, `-opencloud`, `-mealie`, `-immich`) bewegen sich jeweils an ihrem eigenen Tag; ein Bump landet, wo die gewünschte Version dort vorhanden ist, auf einer Revision, die ein anderer von ihnen schon hat – eine Revision weniger auszuwerten, eine Kopie jeder Bibliothek weniger in den Closures. Hosts und Module lesen einen Pin als `inputs.<pin>.legacyPackages.${system}` ([#17](https://github.com/admin/nixlab/issues/17), [#315](https://github.com/admin/nixlab/issues/315)).

Die Homebrew-Inputs sind der Grund, warum ein Cask eine feste Version hat: Mit `mutableTaps = false` kann Homebrew seine Taps nicht selbst aktualisieren, siehe [macOS-Hosts](../explanation/macos-hosts.md).

`nix flake check` prüft zusätzlich, dass `hosts/grammi/dashboards/topology.json` zu dem passt, was `topology.nix` gerade erzeugt – ein neuer Exporter ohne `just topology` lässt den Check fehlschlagen.
