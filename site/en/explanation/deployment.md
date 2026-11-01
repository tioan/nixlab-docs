# Deployment & operations

The pull hosts (zummi, aldrin, grammi, ursalia) keep `/etc/nixos` as a checkout of the private GitHub repo and build themselves. cuckoosegg is pushed to, zorlock and gusto are switched on the Mac itself with `darwin-rebuild` ([macOS hosts](macos-hosts.md)).

| Host | Manual deploy | Automatic |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<message>"` = commit, push, `git pull` + `nixos-rebuild switch` on the host | nightly auto-upgrade, reboot window 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (built on ursalia, copied to the target) | ursalia pushes daily at 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` with sudo, with a summary) | none |
| gusto | `just mac-switch` on gusto, from the working copy | none – `just mac-upgrade` for the Homebrew pins |

## Nightly upgrade

Since 2026-10-31 only ursalia updates the inputs: `nix-cache-prebuild` (`modules/nix-cache.nix`) pulls `main` at 02:30, updates `nixpkgs`, `nixpkgs-unstable` and `sops-nix`, builds every host, uploads everything not on cache.nixos.org, signed, to the nix cache (bucket `nix-cache` in Garage on aldrin) and only then pushes the new `flake.lock` with its deploy key. If one host does not build, the lock is held back for all. From 04:00 `modules/auto-upgrade-git.nix` on every host resets `flake.lock` to HEAD, fast-forwards `main`, builds and switches – with the cache as a second substituter after cache.nixos.org, so even small hosts like zummi no longer build anything themselves. An aborted run no longer leaves a modified `flake.lock` behind (reset at the start and in `ExecStopPost`; `just sync` discards it too). The GitHub host key is pinned because nobody is watching. A configuration error that only shows up on a cold boot therefore takes the host down at 04:00 – for the VMs there is the provider's console for that.

While `just try` holds a host on a topic branch, the upgrade skips it until the branch is merged ([Test a branch before merging](../how-to/try-branch.md)).
