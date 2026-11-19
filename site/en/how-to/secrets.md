# Add secrets

App passwords, OIDC clients and the like live in `hosts/<host>/secrets.yaml`, encrypted for the host and the recovery key `admin`. The MacBook cannot decrypt these files – that is why they are edited on the host (background: [Secrets, network & access](../explanation/secrets-network-access.md)).

## Steps

1. `just sync <host>` – otherwise the host has an outdated `secrets.yaml`, and `pull-secrets` brings it back into the repo.
2. `just secrets <host>` – opens sops on the host (with its host key, no 1Password sign-in) and afterwards fetches the result into the repo via `pull-secrets`.
3. Always quote values: `key: "value"`, single quotes if the value contains `"` or `\`. An unquoted value may be read by YAML as a number or bool; sops-nix then aborts `setupSecrets` and **no** secret of that generation gets installed.
4. Add the NixOS side (`sops.secrets."<name>"`) in the host module, commit, deploy: `just ship <host> "<message>"`.

## What is not edited by hand

| File | Written by |
| --- | --- |
| `hosts/<host>/netbird.yaml` | `just netbird-key <host>` |
| `hosts/<host>/desec.yaml` | `just desec-key <host>` |
| `hosts/<host>/github.yaml` | `just github-key <host>` |
| `terraform/*/secrets.yaml` | sops on the MacBook with the workstation key from 1Password |

Everything that needs sops on the MacBook runs with the sign-in in front – see [just recipes](../reference/recipes.md).

## Writing a recipe that handles a secret

A process's command line is visible to everyone on the machine (`ps`), its environment to the same user. So a secret never goes into a child's arguments or into an environment variable set for it: into `jq` through a pipe (`printf '%s' "$v" | jq -Rs …`, or `--rawfile k <(printf '%s' "$v")` – `printf` is a shell builtin, no process of its own), into `curl` as a header file (`-H @<(printf 'Authorization: Token %s' "$t")`) and a body file (`--data-binary @<(…)`), into `sops` with `set --value-stdin` or `scripts/sops-write.sh`, into a remote host on stdin (nixlab#395, nixlab#401).
