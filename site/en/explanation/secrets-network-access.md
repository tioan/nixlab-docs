# Secrets, network & access

## Secrets (sops-nix, age)

Every host file is encrypted for exactly two recipients: the age key derived from the host's SSH host key and the offline recovery key `admin`. So the MacBook cannot read host secrets – `just secrets <host>` edits them on the host and fetches the result back. Encrypting for a host, on the other hand, works anywhere (only the public key is needed); that is exactly what `netbird-key` and `desec-key` use.

| File | Recipients | Contents |
| --- | --- | --- |
| `hosts/<host>/secrets.yaml` | host + admin | Deploy key, app passwords, OIDC clients, restic |
| `hosts/<host>/netbird.yaml` | host + admin | NetBird setup key (from Tofu) |
| `hosts/<host>/desec.yaml` | host + admin | deSEC token (from Tofu) |
| `hosts/<host>/github.yaml` | host + admin | GitHub deploy key (from `just github-key`) |
| `terraform/*/secrets.yaml` | workstation + admin | API tokens for the providers |

The workstation key lives in 1Password and is read via `SOPS_AGE_KEY_CMD`, never as a file. `env.sh` in each Tofu module decrypts the tokens only into the shell of the respective recipe.

## Network

- **NetBird mesh** (`192.0.2.0/24` and `2001:db8:203:0::/64`, peer names under `peer.homelab.example`): control plane on grammi, login via Pocket ID. Private range (RFC 1918) instead of CGNAT, because tailscaled drops packets from 100.64/10 while both clients run in parallel.
- **Groups:** `servers` (all hosts except cuckoosegg), `subraum-devices`, `admin-workstations` (MacBook), plus person groups from Pocket ID.
- **Home LAN** (`198.51.100.0/24`): routed through ursalia (metric 100), with the two Apple TVs as fallback (group `home-routers`, metric 200, own setup key via `just netbird-router-key`, owned by nobody, in no policy); for group `home-lan`, not for devices that are already at home (posture check `not-at-home`). Rosenpass is off mesh-wide since 2026-10-24 (until 2026-10-31, see [macOS hosts](macos-hosts.md#netbird-on-the-two-macs)); "Quantum-Resistance" in the Apple TVs' app belongs off for that time as well.
- **ursalia's uplink:** WLAN into the home LAN's main network (Intel BE200, `hosts/ursalia/wifi.nix`): wpa_supplicant, WPA3 with WPA2 fallback, country DE, all bands, passphrase via sops. Its final spot has no cable; eno1 keeps DHCP as a fallback with a worse route metric, so the WLAN stays the primary link when both are up.
- **zorlock's uplink:** WLAN as well (`en1`, Broadcom); `hosts/zorlock/wifi.nix` makes sure `homelab` is a preferred network (`networksetup`, only ever adds it, passphrase via sops in `hosts/zorlock/wifi.yaml`). nix-darwin has no Wi-Fi module; band choice stays with macOS.
- **Exit nodes and IPv6:** aldrin and zummi as exit nodes for the group `exit-nodes`; the mesh is dual stack (`2001:db8:203:0::/64`) – see [Exit nodes & IPv6](#exit-nodes).
- **Subraum:** routed through cuckoosegg for `subraum-access`. cuckoosegg itself may only reach grammi's ingest (TCP 8428/9428) and may only be reached from the MacBook via SSH.
- **Tailscale** still runs in parallel during the migration and serves as break-glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

### Exit nodes & IPv6 { #exit-nodes }

aldrin and zummi are exit nodes: a client can send all its traffic, IPv4 and IPv6, through one of them and then appears on the internet with that host's public address. The two sit with different providers (realtox in Düsseldorf, IONOS in Berlin), hence two separate routes instead of one HA route – the client picks its way out. Configuration: `terraform/netbird/exit-nodes.tf` (routes, policy) and `modules/netbird-exit-node.nix` (hosts).

<figure class="nx-diagram">
<svg viewBox="0 0 680 420" role="img" aria-label="A client in the group exit-nodes sends all its IPv4 and IPv6 traffic through the NetBird tunnel to either aldrin or zummi; the exit node masquerades it to its public addresses at realtox or IONOS" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}.nx-blue rect{fill:#e6f1fb;stroke:#185fa5}.nx-blue .nx-t{fill:#042c53}.nx-blue .nx-s{fill:#185fa5}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}</style>
<text class="nx-t" x="16" y="24">Exit nodes: one client, two ways out</text>
<text class="nx-s" x="16" y="42">The client picks one of the two, v4 and v6 always together</text>
<text class="nx-s" x="86" y="72" text-anchor="middle">Client</text>
<text class="nx-s" x="266" y="72" text-anchor="middle">NetBird mesh</text>
<text class="nx-s" x="446" y="72" text-anchor="middle">Exit node</text>
<text class="nx-s" x="596" y="72" text-anchor="middle">Internet as</text>
<path class="nx-line" d="M156 180 H176"/><path class="nx-line" d="M170 176 L176 180 L170 184"/>
<path class="nx-line" d="M356 180 H366 V120 H376"/><path class="nx-line" d="M370 116 L376 120 L370 124"/>
<path class="nx-line" d="M366 180 V240 H376"/><path class="nx-line" d="M370 236 L376 240 L370 244"/>
<path class="nx-line" d="M516 120 H528"/><path class="nx-line" d="M522 116 L528 120 L522 124"/>
<path class="nx-line" d="M516 240 H528"/><path class="nx-line" d="M522 236 L528 240 L522 244"/>
<a data-target="exit-nodes-use" tabindex="0" role="link" class="nx-teal"><rect x="16" y="145" width="140" height="70" rx="8" stroke-width="1"/><text class="nx-t" x="86" y="168" text-anchor="middle">Client</text><text class="nx-s" x="86" y="185" text-anchor="middle">group exit-nodes</text><text class="nx-s" x="86" y="202" text-anchor="middle">app or CLI</text></a>
<a data-target="mesh-ipv6" tabindex="0" role="link" class="nx-gray"><rect x="176" y="135" width="180" height="90" rx="8" stroke-width="1"/><text class="nx-t" x="266" y="159.5" text-anchor="middle">WireGuard tunnel</text><text class="nx-s" x="266" y="176.5" text-anchor="middle">192.0.2.0/24</text><text class="nx-s" x="266" y="193.5" text-anchor="middle">2001:db8:203:0::/64</text><text class="nx-s" x="266" y="210.5" text-anchor="middle">0.0.0.0/0 + ::/0</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-blue"><rect x="376" y="90" width="140" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="446" y="108" text-anchor="middle">aldrin</text><text class="nx-s" x="446" y="125" text-anchor="middle">exit-aldrin</text><text class="nx-s" x="446" y="142" text-anchor="middle">NAT44 + NAT66</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-blue"><rect x="376" y="210" width="140" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="446" y="228" text-anchor="middle">zummi</text><text class="nx-s" x="446" y="245" text-anchor="middle">exit-zummi</text><text class="nx-s" x="446" y="262" text-anchor="middle">NAT44 + NAT66</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-coral"><rect x="528" y="90" width="136" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="596" y="108" text-anchor="middle">realtox</text><text class="nx-s" x="596" y="125" text-anchor="middle">203.0.113.11</text><text class="nx-s" x="596" y="142" text-anchor="middle">2001:db8:11::2</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-coral"><rect x="528" y="210" width="136" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="596" y="228" text-anchor="middle">IONOS</text><text class="nx-s" x="596" y="245" text-anchor="middle">203.0.113.10</text><text class="nx-s" x="596" y="262" text-anchor="middle">2001:db8:10::1</text></a>
<a data-target="exit-nodes-who" tabindex="0" role="link" class="nx-gray"><rect x="16" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="118" y="318" text-anchor="middle">Who may</text><text class="nx-s" x="118" y="335" text-anchor="middle">Pocket ID group exit-nodes</text><text class="nx-s" x="118" y="352" text-anchor="middle">policy → exit-node-access</text></a>
<a data-target="exit-nodes-use" tabindex="0" role="link" class="nx-gray"><rect x="238" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="318" text-anchor="middle">Choice in the client</text><text class="nx-s" x="340" y="335" text-anchor="middle">skip_auto_apply: off until picked</text><text class="nx-s" x="340" y="352" text-anchor="middle">one toggle for v4 and v6</text></a>
<a data-target="exit-nodes-monitoring" tabindex="0" role="link" class="nx-gray"><rect x="460" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="562" y="318" text-anchor="middle">Counters → Grafana</text><text class="nx-s" x="562" y="335" text-anchor="middle">nftables, postrouting</text><text class="nx-s" x="562" y="352" text-anchor="middle">Homelab / NetBird</text></a>
<text class="nx-s" x="16" y="390">Without a choice nothing changes: the client reaches the internet through its own uplink as before.</text>
<text class="nx-s" x="16" y="406">The overlay is ULA; the public addresses only come in through masquerade on the exit node.</text>
</svg>
</figure>

#### Who may { #exit-nodes-who }

The Pocket ID group `exit-nodes`. Someone joins by being added to the group in Pocket ID (auth.homelab.example), followed by `just netbird-apply`; that carries the membership over to the NetBird group of the same name and so to all of the person's devices. The policy `exit-nodes` lets only this group into the routes' access group `exit-node-access`. Deliberately not everyone: whoever uses an exit node shows up with the server's address.

#### Using them { #exit-nodes-use }

The routes are present on every device of the group but off (`skip_auto_apply`) until one is picked – in the NetBird app under "Exit Node" or "Networks", or on the CLI:

```bash
netbird networks select exit-aldrin
```

```bash
netbird networks deselect exit-aldrin
```

Each exit node has two routes, `exit-aldrin` (`0.0.0.0/0`) and `exit-aldrin-v6` (`::/0`). A client from 0.81 on pairs them by name and shows them as one entry "0.0.0.0/0, ::/0": one toggle moves v4 and v6, no IPv6 leaks past the exit node through the client's own uplink. Check with `curl -4 ifconfig.co` and `curl -6 ifconfig.co`.

#### On the hosts { #exit-nodes-hosts }

Routing and NAT are set up by the NetBird client itself: masquerade for v4 (NAT44) and v6 (NAT66) to the host's public addresses, the policy's ACL in its own nftables table. `modules/netbird-exit-node.nix` additionally turns on forwarding for both families, so it does not depend on the client. Reverse-path filtering stays "strict", the NixOS firewall does not filter forwarding (`filterForward` off, as everywhere).

Why NAT66 rather than public addresses for the clients: a client's overlay address holds mesh-wide, whatever the exit node – a GUA out of aldrin's network would leave through zummi with a foreign source address. Besides, neither host has a routed prefix: aldrin's /64 is on-link, zummi has a /128.

#### Dual stack in the mesh { #mesh-ipv6 }

Since 2026-10-25 the whole mesh is dual stack. Next to its address out of `192.0.2.0/24`, every peer gets one out of the ULA `2001:db8:203:0::/64` (`ipv6_enabled_groups` = All, `terraform/netbird/main.tf`). Peer names under `peer.homelab.example` and the service names (`s3-admin`, `dokumente`, `doku`, `llm`, `acme`, `terraform/netbird/mesh-services.tf`) have AAAA next to A; NetBird serves AAAA only to peers that have v6 themselves. The Apple TVs (client 0.66) stay on v4.

The range sits next to `192.0.2.0/24` everywhere: root SSH (`modules/ssh.nix`), CrowdSec's whitelist, the docs site, garage-ui on aldrin, Paperless and Samba on ursalia, Traefik's `trustedIPs` on grammi, Caddy on zorlock. `admin-peers.json` lists v4 and v6 per device. A new allow list for the mesh gets both ranges.

When the groups in `ipv6_enabled_groups` change, NetBird hands out new v6 addresses. Tofu reads the services' AAAA records at plan time, so after such a change, or for a newly registered peer, it takes a second `just netbird-apply`.

#### Monitoring { #exit-nodes-monitoring }

Each exit node counts the forwarded traffic per family and direction in an nftables table of its own and hands it to node_exporter as `netbird_exit_node_bytes_total` / `netbird_exit_node_packets_total`. In the dashboard "Homelab / NetBird", the section "Exit nodes" shows throughput and volume. The counters hang off `postrouting`, not `forward`: the NetBird client puts `iifname nb-mesh accept` at the top of every foreign forward chain, so counters behind it would never be reached.

#### Provider from PR #215 { #netbird-provider-pr215 }

The released NetBird provider (v0.0.10) knows neither `ipv6_enabled_groups` nor `network_range_v6` and resets them on every apply of the account settings ([#243](https://github.com/netbirdio/terraform-provider-netbird/issues/243)). Until [PR #215](https://github.com/netbirdio/terraform-provider-netbird/pull/215) is released, `pkgs/terraform-provider-netbird.nix` builds the provider from that PR and `terraform/netbird/env.sh` swaps it in through `dev_overrides`; Tofu warns about it on every run. To undo: remove the package, its flake output and the block in `env.sh`, then `tofu init -upgrade` ([open item](../project/open-items.md)).

## Access

Only 22/80/443 are open to the public. `modules/ssh.nix` allows root SSH only from mesh or Tailscale addresses; every host has its own login keypair. Mesh means both ranges, `192.0.2.0/24` and `2001:db8:203:0::/64` ([dual stack](#mesh-ipv6)).

### Apps on grammi: only through Traefik `:8090`

Mealie, Grist, logchef and Grafana listen on `127.0.0.1` only on grammi. The reverse proxy reaches them through Traefik's `apps` entrypoint (port 8090), which puts the maintenance switch and error pages in front of every app ([maintenance mode](../how-to/maintenance.md)). VictoriaMetrics (8428) and VictoriaLogs (9428) still listen on all addresses, because the other hosts push their metrics and logs into them over the mesh.

**Deliberate gap:** `:8090` itself is open to every mesh peer (`nb-mesh` is trusted), without the proxy's SSO. Anyone in the mesh reaches every app directly with the matching `Host` header, VictoriaMetrics/-Logs even without a login, since they have none of their own. This is intended (2026-10-23): the NetBird policies decide who reaches grammi, and Mealie, Grist, logchef and Grafana ask for their own login. Revisit when peers that deserve less trust join the mesh, or once the proxy can reach loopback via `direct_upstream` ([open item](../project/open-items.md)).

### Private docs: admin devices, home LAN, login

The private version of this documentation (`doku.homelab.example`, on aldrin and ursalia) contains every internal address and describes how the lab is run. That is more than every device in the mesh needs to see. So nginx serves it only to the mesh addresses of the admins' devices; everyone else gets 403 – with a page of its own that says why, which address the request came from and how a device gets in (without the navigation, so the page titles stay hidden). The name itself resolves for all peers.

**From outside** the same name leads to the public, anonymised docs (GitHub Pages): publicly `doku` is a CNAME to the reverse proxy, whose service `doku` hands it on without a login to a listener on aldrin (port 8091, mesh only) that knows nothing but a redirect. Whoever is in the mesh gets to aldrin and ursalia directly through the NetBird zone.

| Who | Path | Result |
| --- | --- | --- |
| Outside, or NetBird off | reverse proxy (grammi) → aldrin:8091 | 301 to the public docs |
| In the mesh, device in `admin-workstations` | straight to aldrin/ursalia | private docs |
| In the mesh, any other device | straight to aldrin/ursalia | 403 page |
| Outside, `doku.homelab.example/login` | aldrin:8091 → 302 to `doku-login.homelab.example` → reverse proxy with SSO (`docs-readers`) → aldrin:8094 | private docs |
| Home LAN, through the router's own record | straight to ursalia's LAN address | private docs, except devices on the deny list |

**Login from the internet** (decided 2026-10-23): for a device without NetBird, e.g. a work laptop. `doku.homelab.example/login` leads to `doku-login.homelab.example`, a reverse proxy service of its own with SSO for the Pocket ID group `docs-readers` – a name of its own because the proxy's login is per service, not per path, and SSO on `doku` itself would put the public docs behind it. Its target is a listener on aldrin (port 8094) that serves the private site. Because every person's devices reach that port over the mesh as well (`to-servers`), the proxy sends a secret header (`X-Nixlab-Docs-Key`) and aldrin serves only requests that carry it; new key: `just docs-login-key`. This way depends on grammi and zummi – it is an addition for when the mesh is not at hand, not a replacement for it.

**Home LAN** (decided 2026-10-23): the home router answers `doku.homelab.example` with ursalia's LAN address (a record of its own, like `mqtt.homelab.example`), and ursalia serves the private docs to the whole main home network – except the addresses on a deliberate deny list (`services.docsSite.lan` in `hosts/ursalia/configuration.nix`, inventory devices with a fixed address). A deny list by address catches only devices with a reserved address; guests and anything with a changing address get in. The Apple TVs belong on it once they have a reservation: as NetBird fallback routers into the LAN they masquerade mesh peers to their own address. Mesh devices are not affected – for them the name keeps resolving to the mesh addresses.

**Why through the proxy:** this way `doku` is listed with the other public names in the NetBird dashboard instead of being a public vhost of its own on aldrin. The proxy cannot redirect by itself, only forward – hence the redirect listener. It has a port of its own rather than the docs vhost recognising the proxy by its address: the proxy is a peer of its own whose mesh address Tofu does not know. Linking `homelab.example` to the public docs is accepted on purpose; the real addresses stay replaced there.

**What counts as an admin device:** the devices in the group `admin-workstations` (`terraform/netbird/subraum.tf`), today the MacBook – the same device that may also SSH to the Subraum devices. Deliberately not the person group `homelab_admins`: that one is filled from Pocket ID with *all* devices of an admin user. Today that would be none (Calla has no devices of its own), and a phone signing in under an admin user would be in at once. An admin here is a device named in Tofu, not a login. A further device in `admin-workstations` therefore also gets SSH to the Subraum devices – the same trust. Tofu reads the members on every `just netbird-apply` and writes name → address to `terraform/netbird/admin-peers.json`; `flake.nix` hands the addresses to `services.docsSite.allow`. A new admin device therefore gets in after `just netbird-apply`, a commit and a deploy of aldrin and ursalia.

**Why nginx and not a NetBird policy:** `to-servers` lets the devices of all persons (`homelab` and `homelab_admins`) reach all ports on all servers. NetBird policies can only allow, never deny – a narrower rule for the docs would change nothing as long as `to-servers` stays as it is. Narrowing `to-servers` to a port list per service would work, but touches every service on every server for one static site. Moving the docs to a port of their own fails at the same point. So the policy still decides which hosts a device reaches, and nginx decides who gets the docs.

**Why no login in the mesh (Pocket ID):** you read the docs when something is broken. A login would tie them to zummi (Pocket ID) and, through the reverse proxy, to grammi – exactly the hosts they are meant to be independent of. An address list needs nothing at runtime but nginx on the host itself. The login from the internet above does not change that: the mesh and LAN ways keep working without it.

**What this deliberately accepts:**

- The list is as current as the last `just netbird-apply` followed by a deploy. Until then a new admin device sees 403, and a removed device still gets in.
- The address stands for the device, not the person: whoever uses an admin device reads the docs.
- The list must never be empty – `just netbird-admin-peers` refuses an empty output, and the module fails the build with an assertion instead of quietly giving everyone 403.
- IPv4 only, like the mesh. With the IPv6 overlay the v6 addresses go into the same list.

### Paperless: from outside, share links (PIN) and the app (SSO)

In the mesh `dokumente.homelab.example` resolves straight to ursalia through the NetBird zone (full app, Pocket ID login).

**From outside** `dokumente` is a CNAME to the reverse proxy. Its service `dokumente` offers two logins and hands both on to a listener on ursalia (port 8092, mesh only, HTTP through the tunnel):

- **PIN**, for third parties with a share link: `share/<slug>` only (documents and bundles, both paperless' `SharedLinkView`), 404 otherwise. An expired or unknown link makes paperless redirect to its login page; the listener answers that with a short note.
- **SSO** via Pocket ID (groups `paperless-users`/`paperless-admins`): the full app including paperless-gpt, as in the mesh. Paperless' own Pocket ID login still follows, usually without a prompt.

| Who | Path | Result |
| --- | --- | --- |
| Outside with PIN | reverse proxy (grammi) → ursalia:8092 | `/share/<slug>` only, 404 otherwise |
| Outside with SSO | reverse proxy (grammi) → ursalia:8092 | full app |
| In the mesh | straight to ursalia:443 | full app, share links without PIN |

**How the listener recognises SSO:** by the header `X-NetBird-User`. The proxy deletes whatever the client sends under that name on every request and sets it to the email address for SSO sessions only (`stampNetBirdIdentity` in NetBird, checked with 0.81.0 – check again on NetBird updates). The header only picks the paths, it logs nobody in: paperless still asks for its own login. A mesh peer sending the header straight to port 8092 gets nothing it would not get on 443 anyway.

**Why the same name:** paperless builds a share link from the origin of the UI. A link `https://dokumente.homelab.example/share/<slug>` therefore works for third parties without rewriting – whether created in the mesh or via SSO. A name of its own for either login would mean editing links by hand.

**Why the listener filters, not the PIN:** the PIN is a second hurdle in front of the unguessable slug, not a replacement for it. That PIN visitors do not see the app rests on nginx on ursalia alone. The proxy service has no path filter (target `path`), otherwise the redirect to `/accounts/login/` for expired links would no longer reach the listener.

**PIN:** exactly 6 digits (the NetBird API accepts nothing else), one for all shares. New one: `just dokumente-share-pin` (random, into `terraform/netbird/secrets.yaml`), then `just netbird-apply`; show it: `just dokumente-share-pin-show`. The proxy blocks a client address for 15 minutes after 5 wrong PINs within 5 minutes.

**What this deliberately accepts:**

- A still-valid PIN session (the proxy's cookie) skips the login page. Whoever then wants the app via SSO lands on a note page and has to clear the site data or use a private window first.
- Whoever knows the PIN gets every link whose slug they know – no others. So create shares in paperless with an expiry date.
- Telling PIN from SSO rests on a behaviour of the proxy, not on a documented interface.
- CrowdSec sees neither PIN attempts nor requests to the app (TCP passthrough, no HTTP log on grammi), as with every proxy name; the proxy's own block and paperless' login remain.
- ursalia's nginx logs the proxy's mesh address as the client, not the visitor's (no `realip`: it would rewrite the address before `allow`/`deny`).

### Grafana: public dashboards through `dash`

Since 2026-10-23 dashboards can be shared outside ("Share externally", "public dashboards" in Grafana). Only the Grafana role Admin may do that; the SSO login grants it to the Pocket ID group `grafana_admins` (a group just for this, `terraform/netbird/people.tf`; members are kept in Pocket ID and count from the next Grafana login), everyone else stays Editor.

**The path:** `dash.homelab.example` is a reverse proxy service of its own **without a login**. It targets the same Traefik entrypoint `apps` on grammi as `metrics`, but for this name Traefik lets only `/public-dashboards/`, `/api/public/` and `/public/` (assets) through to Grafana; everything else gets a 404 from Traefik. That router is what keeps the app from anonymous visitors, not the proxy.

| Who | Path | Result |
| --- | --- | --- |
| Anyone with the link | reverse proxy → Traefik `apps` (host `dash`) → Grafana | the shared dashboard only, read-only |
| SSO | `metrics.homelab.example` | full app |

**Passing a link on:** Grafana builds it from `root_url`, so it reads `https://metrics.homelab.example/public-dashboards/<token>` – under `metrics` a guest lands at the SSO login. The link for guests is on the dashboard "Homelab / Shared dashboards": a timer on grammi asks Grafana's API every 10 seconds and writes each share with its `dash` address and the template variables it uses as the metric `grafana_public_dashboard_info` (`hosts/grammi/grafana-shares.nix`). Every dashboard links there at the top right ("Nach außen teilen"). The column "Verwalten" opens the dashboard's share dialog for pausing and revoking – a switch right in the table is not possible, since Grafana lets panel actions call its own API only with POST/PUT and pausing needs PATCH. The tokens thereby sit in VictoriaMetrics, visible to everyone who can open Grafana.

**Accepted on purpose:**

- The token in the link is the only secret, no PIN in front. A public dashboard is read-only and can be paused or deleted in Grafana at any time.
- Grafana does share dashboards with template variables, but panels using one (e.g. `$job` in Hosts Overview) stay empty for guests; those need a copy without variables. The column "Variablen" in "Homelab / Shared dashboards" shows which share is affected. Every panel also needs its datasource's uid, which is why the uids are pinned in provisioning and named in every dashboard (`hosts/grammi/configuration.nix`).
- As with every proxy name, CrowdSec on grammi only sees what Traefik logs on the `apps` entrypoint, not the TLS part in front of it.

### MQTT from outside: TLS passthrough to Home Assistant

`mqtt.homelab.example:8883` is the Mosquitto add-on on Home Assistant, for MQTT devices that are also used away from home (AWTRIX NG on an Ulanzi TC002). Same name, port and certificate everywhere, so a device is configured once:

| Where | Path |
| --- | --- |
| At home | the home router (OPNsense) answers `mqtt.homelab.example` with HA's LAN address (local DNS entry) → HA:8883 directly, also without internet |
| Outside | public CNAME to the reverse proxy → `netbird-proxy` on grammi, port 8883 → through the mesh to HA:8883 |

**HA is a NetBird peer** (NetBird add-on, `terraform/netbird/home-assistant.tf`), in a group of its own `home-assistant` – not in `servers`, so it reaches exactly two things and nothing reaches it but the proxy. NetBird's DNS management is off for that group: HA keeps resolving through the home router (OPNsense), also when the internet is gone.

**TLS ends in Mosquitto, not at the proxy.** The service `mqtt` (`terraform/netbird/reverse-proxy.tf`) runs in L4 mode `tls` with the peer HA as its target: the proxy reads only the SNI and passes the connection through untouched. For an L4 service with a port of its own the proxy binds that port itself on all addresses (only 127.0.0.1 has to send a PROXY header there); grammi's firewall opens 8883 in `hosts/grammi/netbird-proxy.nix`.

**The certificate** covers `homeassistant.homelab.example` and `mqtt.homelab.example`. HA's Let's Encrypt add-on gets it via DNS-01 – but without a deSEC token of its own (it could not be pinned to an address, the home address changes). It asks dns01proxy on grammi instead (`hosts/grammi/dns01proxy.nix`, provider `dns-httpreq`), at `https://acme.homelab.example:8446`:

- The port is open only on the mesh, and the policy `home-assistant-acme` lets only HA reach it. HA resolves the name through the home router (OPNsense) (local entry to grammi's mesh address, `tofu output acme_proxy_address`), every other peer through the NetBird zone.
- The proxy writes the TXT records with grammi's address-pinned token. HA's account (password in the add-on, bcrypt hash in `hosts/grammi/dns01proxy.yaml`, `just dns01proxy-key-homeassistant`) may only answer challenges for the two names above.
- dns01proxy serves HTTPS itself and fetches its own certificate for `acme.homelab.example` the same way.

**The two local DNS entries** are host overrides in Unbound on the OPNsense (Services → Unbound DNS → Overrides), set by hand – the API key `inventory-ro` is read-only:

| Name | Address | Why |
| --- | --- | --- |
| `mqtt.homelab.example` | 198.51.100.168 (HA's LAN address) | MQTT stays in the home network and works without internet |
| `acme.homelab.example` | 192.0.2.122 (grammi's mesh address, `tofu output acme_proxy_address`) | HA reaches dns01proxy; NetBird does not manage HA's DNS |

If HA's address or grammi's mesh address changes (new lease, NetBird re-registration), the override has to follow by hand.

The add-on does not renew by itself: an HA automation starts it daily and restarts Mosquitto weekly, so the renewed certificate gets loaded.

**What this deliberately accepts:**

- No login at the proxy – L4 has none. Mosquitto's own users are the only gate, and that includes every login the add-on accepts (its own list and Home Assistant users).
- Mosquitto sees the proxy's mesh address as the sender of every outside connection (the add-on cannot take a PROXY header), so neither HA nor CrowdSec can block a single client by address. The proxy can filter by country or address range (`access_restrictions`), not set for now.
- Certificate renewal needs grammi and the mesh – with 30 days of slack before expiry.
- A device that restarts while the internet is down needs the time from somewhere other than the internet to check the certificate.
