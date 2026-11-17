# just recipes

| Recipe | Purpose |
| --- | --- |
| `just try <host>` | Deploy the current topic branch to a host and hold it there until the branch is merged ([Test a branch before merging](../how-to/try-branch.md)) |
| `just try-confirm <host> [minutes] [via]` | Like `try`, but rolls itself back unless the host is reached and confirmed within the deadline ([with automatic rollback](../how-to/try-branch.md#confirm)) |
| `just release <host>` / `holds` | Drop a hold without merging / list every hold |
| `just test-restic-verified` | Forced backup failures in a throwaway VM on ursalia ([When a backup counts as successful](../explanation/monitoring.md#backup-verified)) |
| `just test-gw-remote-private-users` | gw-remote in a user namespace in a throwaway VM on ursalia: OpenVPN, nftables, WireGuard inside, then the switch back without one |
| `just test-forwarding` | The forward filter in throwaway VMs on ursalia: nothing from a neighbour into the overlay or onto a container bridge ([Exit nodes](../explanation/secrets-network-access.md)) |
| `just forward-probe <host>` | Live check on a routing host: a namespace neighbour must not reach the mesh; runtime only, cleans up |
| `just restore-test <host> [isolation]` | Restore grammi or zummi from restic into a throwaway VM on ursalia without network and measure the RTO ([Test a restore](../how-to/restore-test.md)) |
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
| `just wifi-qr [ssid]` | A WLAN of gruffi: SSID, PSK, encryption and a QR code to join it, from `openwrt/gruffi/uci.nix` and its `secrets.yaml` (prints the PSK); without an SSID the list of WLANs |
| `just known-hosts` | Write `~/.ssh/known_hosts.nixlab` from the inventory – for a workstation outside this repo; gusto gets the keys system-wide |
| `just netbird-plan` / `netbird-apply` | Change the NetBird account; apply also rewrites `expected-peers.json` (commit it, deploy grammi) and `admin-peers.json` (commit it, deploy aldrin and ursalia) |
| `just netbird-proxy-certs` | Get proxy services without a certificate one and bring the dashboard up to date (NetBird #7118); runs at the end of `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | New random PIN for Paperless share links from outside (then `netbird-apply`), or show the current one |
| `just netbird-key <host>` | New setup key for a host, 24 h to deploy |
| `just netbird-key-techo5` | Setup key for a TECHO5 device (Echo Show 8) onto the Mac's clipboard, never printed; valid 24 h, steps in `terraform/netbird/techo5.tf` |
| `just netbird-import` | Rebuild the Tofu state from the account – only needed when git does not have it either ([Tofu state](../explanation/nixos-opentofu.md#state)) |
| `just netbird-renew-token` | Renew the service user token (valid 90 days; alert NetbirdTokenExpiring three weeks before) |
| `just tf-state-passphrase` | Once: the passphrase for the Tofu states into `terraform/secrets.yaml` (never overwrites) |
| `just tf-state-rekey` | New random state passphrase, every state rewritten with it and committed together with `terraform/secrets.yaml`; in the main checkout on main, then push. The old ciphertexts stay in git history |
| `just telemetry-credentials [user]` | Passwords for grammi's metrics/log ingest (vmauth, one user per sender in `hosts/grammi/telemetry-ingest.json`): adds the missing ones, or a new one for `user`; written into `hosts/grammi/telemetry-ingest.yaml` and the sender's `telemetry.yaml`, never printed |
| `just github-key <host>` | New GitHub deploy key for a host (key via sops, registration via Tofu) |
| `just github-plan` / `github-apply` | Change the repositories and deploy keys on GitHub |
| `just garage-plan` / `garage-apply` | Change the buckets, keys and permissions in Garage on aldrin (`terraform/garage`) |
| `just aldrin-backup-secrets` | Copy the Garage key of the bucket `aldrin-backups` from Tofu state and a new repository password into `hosts/aldrin/backup.yaml` – once, after `garage-apply` |
| `just data-backup-secrets <host>` | The same for the bucket `<host>-data-backups` into `hosts/<host>/backup-data.yaml` (`modules/restic-data.nix`) – once per host, after `garage-apply` |
| `just garage-admin-token` | Copy Garage's admin token from aldrin into `terraform/secrets.yaml` over SSH – once per workstation key, and again after rotating it |
| `just desec-key <host>` / `desec-verify` | Rotate a deSEC token, or check the scopes from every host |
| `just desec-names` | Rewrite `terraform/desec-tokens/acme-names.json` from the flake (the names each token may write); then `desec-apply` |
| `just nanokvm-mcp-key` | Store the NanoKVM Go+ MCP API key encrypted for ursalia (then commit, deploy ursalia) |
| `just nanokvm-cert` | Fetch the NanoKVM Go+'s self-signed certificate as ursalia sees it and pin it after comparing (then commit, deploy ursalia) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude Code bridge to the NanoKVM Go+ on ursalia: set up once, start, stop, state, log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (default gusto, or zorlock over SSH): show what a switch would change (nvd, Homebrew removals/installs), or switch with a summary – see [macOS hosts](../explanation/macos-hosts.md) |
| `just apps [term] [--host h]` / `just apps install\|uninstall <name>…` / `apps-list [host]` / `apps-rm <name> [host]` | Software of a Mac (`hosts/<host>/apps.json`): a round of searching nixpkgs, Homebrew and the App Store, adding (after a pin check) and removing, then one switch and one commit; install or uninstall exact names like brew; list; remove one entry – on gusto also as `apps`, `apps-list`, `apps-rm` from any directory, see [Software on the Macs](../how-to/software.md) |
| `just mac-upgrade` | On gusto: update the Homebrew pins, switch, `brew upgrade`, NetBird version next to the mesh pin; commit `flake.lock` |
| `just container-bump <host> <name> [tag]` | Pin a container image to the newest release tag's digest (or the given tag's) in `hosts/<host>/container-images.json`; then commit and deploy ([Update a container image](../how-to/container-images.md)) |
| `just gc <host>` | Run the nightly garbage collection now (keeps the last 10 generations) |
| `just docs` | Build this documentation: private PDFs (de/en) and the anonymised public version (README, PDFs, site sources, modules) in `public-docs/` (gitignored clone of `nixlab-docs`), committed and pushed there; GitHub builds the site from it |
| `just docs-serve` | Build the private site with real values locally and serve it at `http://127.0.0.1:8000` |

Recipes that need sops get the workstation's age key from 1Password through `SOPS_AGE_KEY_CMD`. On gusto home-manager sets it and `op` unlocks through the 1Password app (Touch ID); sops, tofu and age come from the devShell (direnv in the checkout). Without that setup:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```
