# Test a branch on a host before merging

A topic is deployed from its worktree to a host and merged into main only once it works there. Without precautions that lasts until 04:00: the nightly upgrade builds `/etc/nixos` – that is, main – and quietly switches the host back. A `just deploy` from another topic does the same. `just try` therefore sets a **hold** on the host that every way back to main honours ([`modules/deploy-hold.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy-hold.nix)).

## Flow { #flow }

From the topic's worktree, in a real terminal – the recipes need SSH and do not work via `!` in the Claude app:

```bash
cd .worktrees/<topic>
git rebase origin/main
just try ursalia
```

`just try <host>`:

1. refuses with uncommitted changes (the hold names a commit), on main, or when the branch is not based on the current `origin/main` – otherwise the test would roll back what others merged meanwhile;
2. refuses when **another** branch already holds the host (the same branch may deploy again);
3. builds on ursalia and switches like `just deploy-push`;
4. writes `/etc/nixos-hold` on the host: branch, commit, time, from where.

If it works, merge and deploy:

```bash
git switch main && git merge --ff-only <topic> && git push
just deploy ursalia
```

`just deploy` (`rebuild`, to be exact) sees that the held commit is now in `/etc/nixos`, lifts the hold and builds as usual.

If it does not: back to main with

```bash
just release ursalia
just deploy ursalia
```

## With automatic rollback: `just try-confirm` { #confirm }

For changes that can cut the host off – network, NetBird, SSH, firewall – there is a variant with a dead-man switch:

```bash
just try-confirm ursalia        # 5 minutes to confirm
just try-confirm ursalia 10     # 10 minutes
```

1. Same checks and build as `just try`, but nothing is switched by nixos-rebuild.
2. On the host, a timer is armed first: after the deadline it switches back to the generation that is running now.
3. Then the branch is activated with `switch-to-configuration test`, as a unit of its own on the host – the activation survives a dropped SSH session. `test` leaves the boot default alone: a reboot or a hang also ends up in the old generation.
4. The workstation waits until it reaches the host over the mesh again and the activation has finished, and asks **Keep it? [y/N]**.
5. Only `y` stops the timer, sets the system profile and boot entry and writes the hold as `just try` does. Anything else – `n`, no answer, no connection – and the host rolls itself back at the deadline (`n` does it right away).

When the host answers under a different name afterwards (a rename), `via` names the address to deploy to; the confirmation always goes to `<host>.peer.homelab.example`:

```bash
just try-confirm ursalia 10 root@ursalia-next.peer.homelab.example
```

The question needs a real terminal; without one the answer is "no".

The pattern – apply, check from outside, keep only when confirmed within a deadline, revert otherwise – comes from snowball (BBBSnowball): [`firewall-update.sh`](https://github.com/BBBSnowball/nixcfg/blob/35264a74189686e8ce0231b4752f85225d0c9e00/hosts/sonline0/firewall-update.sh) does it for iptables rules; `try-confirm` does it for a whole NixOS generation.

## What honours the hold { #honoured }

| Path | With a hold |
| --- | --- |
| nightly `nixos-upgrade` | skipped (`ExecCondition`, not a failure): no flake update, no switch, no reboot. If the held commit has reached `/etc/nixos` meanwhile, it lifts the hold and runs. |
| `just rebuild`/`deploy`/`ship`/`deploy-all` | refused, unless the held commit is in the freshly pulled `/etc/nixos` – then the hold goes and the deploy runs |
| `just deploy-push <host>` | the same rule against the local checkout's `HEAD` |
| ursalia's nightly push to cuckoosegg | skipped, unless the held commit is in ursalia's `/etc/nixos` |

The rule is the same everywhere: a hold blocks as long as what is about to be deployed does not contain the held commit. A **rebase merge** rewrites the commit – then nothing recognises the merge, and the hold has to go with `just release <host>`.

## cuckoosegg { #cuckoosegg }

`just try cuckoosegg` works the same way, the hold lives on cuckoosegg. After the merge there is no `just deploy cuckoosegg`: either ursalia's push at 06:30 takes over once ursalia's checkout has the merge (`just deploy ursalia` or `just sync ursalia`), or right away from main with `just deploy-push cuckoosegg`.

## Seeing who holds what { #status }

- `just holds` – every NixOS host at once
- login shell on the host – a warning line, after 48 h with a pointer to `just release`
- Grafana "Homelab / Hosts Overview", panel **Deploy holds (just try)** – metric `nixlab_deploy_hold_since_seconds{branch,commit}`, orange while a hold exists, red after 48 h. The lab has no real alerting; the panel is the reminder.

## Limits { #limits }

- **Tofu** (`netbird-apply`, `desec-apply`, `pocketid-apply`) has one state and is applied from main only. A topic that changes Tofu cannot be tested ahead this way.
- **Macs** (gusto, zorlock) are not covered – they have no nightly upgrade that would roll back.
- **Two topics on one host** at the same time do not work: the second `just try` refuses until the first is merged or released.
- A host from before `modules/deploy-hold.nix` knows no hold; the first `just try` on it brings the module along.
- **`try-confirm` and the nightly upgrade:** there is no hold until the confirmation. If the deadline spans 04:00, `nixos-upgrade` builds main. If the branch changes the hostname, it even builds main for the *new* name – at ursalia's cut-over (2026-10-27) the NUC booted the M720q's configuration that way. Set `nixos-hold set` first, or don't test into the night.
