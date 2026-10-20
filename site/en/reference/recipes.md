# just recipes

| Recipe | Purpose |
| --- | --- |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Edit host secrets on the host and fetch them back |
| `just topology` | Regenerate the topology dashboard (otherwise `nix flake check` fails) |
| `just inventory` | Show the validated inventory with everything derived ([Inventory](inventory.md)) |
| `just inventory-test` | Check `inventory.json`, run the validator tests, check the schema is fresh |
| `just inventory-schema` | Regenerate `inventory.schema.json` after a format change |
| `just inventory-collect [--force] [host …]` | Fetch SSH host keys, interfaces (MAC, medium, link-local) and hardware (vendor, model, product id, serial) from the devices into `inventory.json` – fills gaps and reports differences; `--force` takes the device values |
| `just known-hosts` | Write `~/.ssh/known_hosts.nixlab` on the MacBook from the inventory |
| `just netbird-plan` / `netbird-apply` | Change the NetBird account; apply also rewrites `expected-peers.json` (commit it, deploy grammi) and `admin-peers.json` (commit it, deploy aldrin and ursalia) |
| `just netbird-proxy-certs` | Get proxy services without a certificate one and bring the dashboard up to date (NetBird #7118); runs at the end of `netbird-apply` |
| `just netbird-key <host>` | New setup key for a host, 24 h to deploy |
| `just netbird-import` | Restore lost Tofu state from the account |
| `just netbird-renew-token` | Yearly renewal of the service user token |
| `just github-key <host>` | New GitHub deploy key for a host (key via sops, registration via Tofu) |
| `just github-plan` / `github-apply` | Change the repositories and deploy keys on GitHub |
| `just desec-key <host>` / `desec-verify` | Rotate a deSEC token, or check the scopes from every host |
| `just gc <host>` | Delete store generations older than 7 days |
| `just docs` | Build this documentation: private PDFs (de/en) and the anonymised public version (README, PDFs, site sources, modules) in `public-docs/` (gitignored clone of `nixlab-docs`), committed and pushed there; GitHub builds the site from it |
| `just docs-serve` | Build the private site with real values locally and serve it at `http://127.0.0.1:8000` |

Recipes that need sops on the MacBook run with a 1Password sign-in in front, which provides the age key via `SOPS_AGE_KEY_CMD`:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```
