# Deployment & Betrieb

Die Pull-Hosts (zummi, aldrin, grammi, ursalia) halten `/etc/nixos` als Checkout des privaten GitHub-Repos und bauen sich selbst. cuckoosegg wird gepusht, zorlock und gusto werden auf dem Mac selbst per `darwin-rebuild` umgestellt ([macOS-Hosts](macos-hosts.md)).

| Host | Manueller Deploy | Automatisch |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<Nachricht>"` = commit, push, `git pull` + `nixos-rebuild switch` auf dem Host | nächtliches Auto-Upgrade, Reboot-Fenster 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (gebaut auf ursalia, kopiert zum Ziel) | ursalia pusht täglich um 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` mit sudo, mit Zusammenfassung) | keins |
| gusto | `just mac-switch` auf gusto, aus der Arbeitskopie | keins – `just mac-upgrade` für die Homebrew-Pins |

## Nächtliches Upgrade

Seit 2026-10-31 aktualisiert nur noch ursalia die Inputs: `nix-cache-prebuild` (`modules/nix-cache.nix`) zieht um 02:30 `main`, aktualisiert `nixpkgs` und `nixpkgs-unstable`, baut jeden Host, lädt alles, was nicht auf cache.nixos.org liegt, signiert in den Nix-Cache (Bucket `nix-cache` in Garage auf aldrin) und pusht erst dann die neue `flake.lock` mit seinem Deploy-Key, in einem Commit mit eigenem Signaturschlüssel. `sops-nix` wird von Hand mit gelesenem Diff angehoben: sein Aktivierungscode läuft als root mit allen Secrets. Baut ein Host nicht, bleibt das Lock für alle liegen. `modules/auto-upgrade-git.nix` setzt auf jedem Host ab 04:00 die `flake.lock` auf HEAD zurück, zieht `main` per Fast-Forward, wenn dessen Spitze signiert ist (siehe unten), baut und schaltet um – mit dem Cache als zweitem Substituter nach cache.nixos.org, sodass auch kleine Hosts wie zummi nichts mehr selbst bauen. Ein abgebrochener Lauf hinterlässt keine geänderte `flake.lock` mehr (Reset am Start und in `ExecStopPost`, `just sync` verwirft sie ebenfalls). Der GitHub-Host-Key ist gepinnt, weil niemand zusieht. Ein Konfigurationsfehler, der erst beim Kaltstart auffällt, legt den Host also um 04:00 lahm – bei den VMs gibt es dafür die Konsole des Anbieters.

Hält `just try` einen Host auf einem Themen-Branch, überspringt das Upgrade ihn, bis der Branch gemergt ist ([Branch vor dem Merge testen](../how-to/try-branch.md)).

## Signiertes main

Jedes Ziehen von `/etc/nixos` – das nächtliche Upgrade, ursalias Prebuild, `just sync`/`deploy`/`check` – läuft über `auto-upgrade-git-pull` (`modules/auto-upgrade-git-pull.nix`): Es holt, prüft die SSH-Signatur der Spitze von `main` gegen `/etc/auto-upgrade-git/allowed-signers` aus dem laufenden System und spult nur auf genau diesen geprüften Commit vor. Wer signieren darf, steht in `git-signers.nix`:

- **trusted** – der Workstation-Schlüssel („nixlab commit signing“ in 1Password, über `op-ssh-sign`; gusto signiert jeden Commit). Ein damit signierter Commit bürgt für alles darunter.
- **lock-only** – ursalias Prebuild-Schlüssel. Gilt nur für einen Commit mit einem Vorgänger, der allein `flake.lock` ändert und auf einem angenommenen Commit sitzt; so kann er nichts anderes nach `main` tragen.

Alles andere – unsigniert, unbekannter Schlüssel, ein Lock-only-Commit, der mehr ändert – lässt den Lauf vor dem Bauen scheitern; der Host behält, was er hat, und `NixosUpgradeStale` meldet es nach einer Weile. Die Deploy-Keys aller Hosts außer ursalia sind read-only (`terraform/github/main.tf`), ein übernommener Host kann also auch nicht pushen.

GitHubs eigene Merge-Commits sind unsigniert. PRs werden deshalb mit `just merge <branch>` gemergt (signierter Merge-Commit, Push; GitHub markiert den PR als gemergt). Landet trotzdem ein unsignierter Commit an der Spitze, zeigt `just seal` die letzten Commits und setzt einen signierten leeren Commit darauf. Von Hand lässt sich ein Host immer aktualisieren: `ssh root@<host>`, dann `cd /etc/nixos && git pull --ff-only && nixos-rebuild switch --flake .#<host>`.
