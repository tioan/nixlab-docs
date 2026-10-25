# Open items

- [ ] NetBird provider: replace the build from PR #215 (IPv6 overlay) with the registry version again once it is released ([exit nodes & IPv6](../explanation/secrets-network-access.md#netbird-provider-pr215))
- [ ] Home Assistant: check whether `trusted_proxies`/`trusted_networks` know only `192.0.2.0/24` and add `2001:db8:203:0::/64` (not in the repo)
- [ ] Upstream PRs to the NetBird provider (#247 `direct_upstream`/cluster targets, #248 `crowdsec_mode`); then switch the proxy targets on grammi to `localhost`
- [ ] Remove Tailscale from the servers once nothing depends on it any more
- [ ] Grafana alerting (contact point still missing) for SMART, fwupd, Paperless, NetBird expected ≠ known, ursalia's WLAN (not associated, stuck on 2.4 GHz, weak signal)
- [ ] Update notifications for the inputs pinned by hand (NetBird, Pocket ID)
- [ ] Declarative root passwords via sops
- [ ] Keep the host list in one place instead of `flake.nix`, the Tofu modules and `justfile`
- [ ] gusto: after the first switch check whether the NetBird app updates itself (or follows the dashboard's auto-update) and switch that off, so the version comes from `netbirdio-tap` only
- [ ] gusto: default git address `admin@homelab.example` instead of `mail@admin.org`, together with a new layout of `~/Projects`
- [ ] Inventory: a field for a device's DNS name (arkkvm answers as `arkkvm01`, today only in its note), and public addresses for the managed hosts – then `hosts/gusto/ssh.nix` derives its fallback names from them
- [ ] Docs site: `<link rel="alternate" type="text/markdown">` in every HTML page, pointing to its Markdown version (`docs/gen-llms.py`) – needs a theme override, so only once Zensical is at 1.0
