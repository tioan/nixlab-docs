# Add a new host

A host appears in several places in the repo, because NixOS and OpenTofu deliberately share no host list (see [What is deliberately not wired](../explanation/nixos-opentofu.md#what-is-deliberately-not-wired)). This guide walks through them in order.

## 1. Provide the machine

Rented VMs are created by hand at the provider; bare metal and the Subraum VM follow the installation guides in `docs/install-*.md`. The result is a NixOS install with an SSH host key – the host's age key is derived from it next.

## 2. Create the configuration

- Create `hosts/<host>/configuration.nix` and `hardware-configuration.nix`.
- Add it to `nixosConfigurations` in `flake.nix` with an explicit module list. Whatever is left out on purpose gets a comment saying why.

## 3. Add it wherever hosts are listed

| File | Entry |
| --- | --- |
| `flake.nix` | `nixosConfigurations.<host>` |
| `inventory.json` | `hosts.<host>` with `"managed": true` – kind, site, owner, unlock (see [Inventory](../reference/inventory.md)) |
| `justfile` | `hosts := "…"` (pull hosts only, for `ship-all`) |
| `terraform/netbird/main.tf` | `local.hosts`: host → setup key group (`servers` or similar) |
| `terraform/desec-tokens/main.tf` | `local.hosts`: allowed source addresses, `acme_names` |
| `terraform/github/main.tf` | `local.hosts`: deploy key read-only or with write access |

## 4. sops recipient

Derive the age key from the new host's SSH host key (`ssh-to-age` on `/etc/ssh/ssh_host_ed25519_key.pub`) and add it to `.sops.yaml`: an anchor under `keys` and a `creation_rule` for `hosts/<host>/(secrets|netbird|desec|github)\.yaml$` with the host and `admin` as recipients. The public host key itself goes into `inventory.json` (`sshHostKeys`, or later via `just inventory-collect`); `checks.inventory-sops` compares the two.

## 5. Mint keys and tokens

| Recipe | Result | Note |
| --- | --- | --- |
| `just netbird-key <host>` | `hosts/<host>/netbird.yaml` | one-off setup key, **valid for 24 h** – deploy right after |
| `just desec-key <host>` | `hosts/<host>/desec.yaml` | only for hosts with their own certificates |
| `just github-key <host>` | `hosts/<host>/github.yaml` + `github-deploy.pub` | pull hosts only |

Recipes that need sops on the MacBook run with the 1Password sign-in in front (see [just recipes](../reference/recipes.md)).

## 6. Deploy and check

- First deploy within 24 h of `netbird-key`. The host registers itself in the mesh at startup; Tofu finds it by name through `data "netbird_peer"`.
- Run `just topology` and commit the result – otherwise `nix flake check` fails.
- `just inventory-collect` (host key, interfaces), set `network`/`ipv4` by hand, then `just inventory-test`; `just known-hosts` on the MacBook.
- Add app secrets once the host is running: [Add secrets](secrets.md).
- Update the docs: [Hosts & roles](../reference/hosts.md), [Services](../reference/services.md).
