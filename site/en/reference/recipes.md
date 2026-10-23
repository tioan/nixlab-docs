# just recipes

| Recipe | Purpose |
| --- | --- |
| `just try <host>` | Deploy the current topic branch to a host and hold it there until the branch is merged ([Test a branch before merging](../how-to/try-branch.md)) |
| `just release <host>` / `holds` | Drop a hold without merging / list every hold |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Edit host secrets on the host and fetch them back |
| `just topology` | Regenerate the topology dashboard (otherwise `nix flake check` fails) |
| `just inventory` | Show the validated inventory with everything derived ([Inventory](inventory.md)) |
| `just inventory-test` | Check `inventory.json`, run the validator tests, check the schema is fresh |
| `just inventory-schema` | Regenerate `inventory.schema.json` after a format change |
| `just inventory-diagram` | Regenerate the diagram of all fields on [Inventory schema](inventory-schema.md) after a format change |
| `just inventory-collect [--force] [host …]` | Fetch SSH host keys, interfaces (MAC, medium, link-local) and hardware (vendor, model, product id, serial) from the devices into `inventory.json` – fills gaps and reports differences; `--force` takes the device values |
| `just services [--json]` | What the inventory's services run, from the host configurations: version, license, language ([Software view](inventory.md#software)) |
| `just sbom [host …]` | SBOM (CycloneDX, SPDX, CSV) of the running system of each host into `sbom/` ([Software view](inventory.md#software)) |
| `just known-hosts` | Write `~/.ssh/known_hosts.nixlab` from the inventory – for a workstation outside this repo; gusto gets the keys system-wide |
| `just netbird-plan` / `netbird-apply` | Change the NetBird account; apply also rewrites `expected-peers.json` (commit it, deploy grammi) and `admin-peers.json` (commit it, deploy aldrin and ursalia) |
| `just netbird-proxy-certs` | Get proxy services without a certificate one and bring the dashboard up to date (NetBird #7118); runs at the end of `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | New random PIN for Paperless share links from outside (then `netbird-apply`), or show the current one |
| `just netbird-key <host>` | New setup key for a host, 24 h to deploy |
| `just netbird-import` | Restore lost Tofu state from the account |
| `just netbird-renew-token` | Yearly renewal of the service user token |
| `just github-key <host>` | New GitHub deploy key for a host (key via sops, registration via Tofu) |
| `just github-plan` / `github-apply` | Change the repositories and deploy keys on GitHub |
| `just desec-key <host>` / `desec-verify` | Rotate a deSEC token, or check the scopes from every host |
| `just nanokvm-mcp-key` | Store the NanoKVM Go+ MCP API key encrypted for ursalia (then commit, deploy ursalia) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude Code bridge to the NanoKVM Go+ on ursalia: set up once, start, stop, state, log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (default gusto, or zorlock over SSH): show what a switch would change (nvd, Homebrew removals/installs), or switch with a summary – see [macOS hosts](../explanation/macos-hosts.md) |
| `just apps [term] [--host h]` / `apps-list [host]` / `apps-rm <name> [host]` | Software of a Mac (`hosts/<host>/apps.json`): a round of searching nixpkgs, Homebrew and the App Store, adding (after a pin check) and removing, then one switch and one commit; list; remove one entry – on gusto also as `apps`, `apps-list`, `apps-rm` from any directory, see [Software on the Macs](../how-to/software.md) |
| `just mac-upgrade` | On gusto: update the Homebrew pins, switch, `brew upgrade`, NetBird version next to the mesh pin; commit `flake.lock` |
| `just gc <host>` | Delete store generations older than 7 days |
| `just docs` | Build this documentation: private PDFs (de/en) and the anonymised public version (README, PDFs, site sources, modules) in `public-docs/` (gitignored clone of `nixlab-docs`), committed and pushed there; GitHub builds the site from it |
| `just docs-serve` | Build the private site with real values locally and serve it at `http://127.0.0.1:8000` |

Recipes that need sops get the workstation's age key from 1Password through `SOPS_AGE_KEY_CMD`. On gusto home-manager sets it and `op` unlocks through the 1Password app (Touch ID); sops, tofu and age come from the devShell (direnv in the checkout). Without that setup:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```
