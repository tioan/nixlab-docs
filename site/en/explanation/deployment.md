# Deployment & operations

The pull hosts (zummi, aldrin, grammi, ursalia) keep `/etc/nixos` as a checkout of the private GitHub repo and build themselves. cuckoosegg is pushed to, zorlock and gusto are switched on the Mac itself with `darwin-rebuild` ([macOS hosts](macos-hosts.md)).

| Host | Manual deploy | Automatic |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<message>"` = commit, push, `git pull` + `nixos-rebuild switch` on the host | nightly auto-upgrade, reboot window 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (built on ursalia, copied to the target) | ursalia pushes daily at 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` with sudo, with a summary) | none |
| gusto | `just mac-switch` on gusto, from the working copy | none – `just mac-upgrade` for the Homebrew pins |

## Nightly upgrade

Since 2026-10-31 only ursalia updates the inputs: `nix-cache-prebuild` (`modules/nix-cache.nix`) pulls `main` at 02:30, updates `nixpkgs` and `nixpkgs-unstable`, builds every host, uploads everything not on cache.nixos.org, signed, to the nix cache (bucket `nix-cache` in Garage on aldrin) and only then pushes the new `flake.lock` with its deploy key, in a commit signed with its own key. `sops-nix` is bumped by hand with the diff read: its activation code runs as root with every secret. If one host does not build, the lock is held back for all. From 04:00 `modules/auto-upgrade-git.nix` on every host resets `flake.lock` to HEAD, fast-forwards `main` if its tip is signed (see below), builds and switches – with the cache as a second substituter after cache.nixos.org, so even small hosts like zummi no longer build anything themselves. An aborted run no longer leaves a modified `flake.lock` behind (reset at the start and in `ExecStopPost`; `just sync` discards it too). The GitHub host key is pinned because nobody is watching. A configuration error that only shows up on a cold boot therefore takes the host down at 04:00 – for the VMs there is the provider's console for that.

While `just try` holds a host on a topic branch, the upgrade skips it until the branch is merged ([Test a branch before merging](../how-to/try-branch.md)).

## Signed main

Every pull of `/etc/nixos` – the nightly upgrade, ursalia's prebuild, `just sync`/`deploy`/`check` – goes through `auto-upgrade-git-pull` (`modules/auto-upgrade-git-pull.nix`): it fetches, checks the SSH signature of the tip of `main` against `/etc/auto-upgrade-git/allowed-signers` from the running system, and fast-forwards only to that checked commit. Who may sign is in `git-signers.nix`:

- **trusted** – the workstation key ("nixlab commit signing" in 1Password, through `op-ssh-sign`; gusto signs every commit). A commit signed by it vouches for everything below it.
- **lock-only** – ursalia's prebuild key. Accepted only for a commit with one parent that changes `flake.lock` and nothing else, on top of an accepted commit; so it cannot carry anything else onto `main`.

Anything else – unsigned, unknown key, a lock-only commit that changes more – fails the run before it builds; the host keeps running what it has, and `NixosUpgradeStale` reports it after a while. The deploy keys of all hosts except ursalia are read-only (`terraform/github/main.tf`), so a compromised host cannot push either.

GitHub's own merge commits are unsigned. PRs are therefore merged with `just merge <branch>` (signed merge commit, push; GitHub marks the PR merged). If an unsigned commit ends up as the tip anyway, `just seal` shows the last commits and puts a signed empty commit on top. A host can always be updated by hand: `ssh root@<host>`, then `cd /etc/nixos && git pull --ff-only && nixos-rebuild switch --flake .#<host>`.
