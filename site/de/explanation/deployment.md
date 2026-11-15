# Deployment & Betrieb

Die Pull-Hosts (zummi, aldrin, grammi, ursalia) halten `/etc/nixos` als Checkout des privaten GitHub-Repos und bauen sich selbst. cuckoosegg wird gepusht, zorlock und gusto werden auf dem Mac selbst per `darwin-rebuild` umgestellt ([macOS-Hosts](macos-hosts.md)).

| Host | Manueller Deploy | Automatisch |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<Nachricht>"` = commit, push, `git pull` + `nixos-rebuild switch` auf dem Host | nächtliches Auto-Upgrade, Reboot-Fenster 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (gebaut auf ursalia, kopiert zum Ziel) | ursalia pusht täglich um 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` mit sudo, mit Zusammenfassung) | keins |
| gusto | `just mac-switch` auf gusto, aus der Arbeitskopie | keins – `just mac-upgrade` für die Homebrew-Pins |

## Nächtliches Upgrade

Seit 2026-10-31 aktualisiert nur noch ursalia die Inputs: `nix-cache-prebuild` (`modules/nix-cache.nix`) zieht um 02:30 `main`, aktualisiert `nixpkgs`, `nixpkgs-unstable` und `sops-nix`, baut jeden Host, lädt alles, was nicht auf cache.nixos.org liegt, signiert in den Nix-Cache (Bucket `nix-cache` in Garage auf aldrin) und pusht erst dann die neue `flake.lock` mit seinem Deploy-Key. Baut ein Host nicht, bleibt das Lock für alle liegen. `modules/auto-upgrade-git.nix` setzt auf jedem Host ab 04:00 die `flake.lock` auf HEAD zurück, zieht `main` per Fast-Forward, baut und schaltet um – mit dem Cache als zweitem Substituter nach cache.nixos.org, sodass auch kleine Hosts wie zummi nichts mehr selbst bauen. Ein abgebrochener Lauf hinterlässt keine geänderte `flake.lock` mehr (Reset am Start und in `ExecStopPost`, `just sync` verwirft sie ebenfalls). Der GitHub-Host-Key ist gepinnt, weil niemand zusieht. Ein Konfigurationsfehler, der erst beim Kaltstart auffällt, legt den Host also um 04:00 lahm – bei den VMs gibt es dafür die Konsole des Anbieters.

Hält `just try` einen Host auf einem Themen-Branch, überspringt das Upgrade ihn, bis der Branch gemergt ist ([Branch vor dem Merge testen](../how-to/try-branch.md)).
