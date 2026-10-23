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

- **NetBird mesh** (`192.0.2.0/24`, peer names under `peer.homelab.example`): control plane on grammi, login via Pocket ID. Private range (RFC 1918) instead of CGNAT, because tailscaled drops packets from 100.64/10 while both clients run in parallel.
- **Groups:** `servers` (all hosts except cuckoosegg), `subraum-devices`, `admin-workstations` (MacBook), plus person groups from Pocket ID.
- **Home LAN** (`198.51.100.0/24`): routed through ursalia (metric 100), with the two Apple TVs as fallback (group `home-routers`, metric 200, own setup key via `just netbird-router-key`, owned by nobody, in no policy); for group `home-lan`, not for devices that are already at home (posture check `not-at-home`). The Apple TVs should have "Quantum-Resistance" on in the app; since 2026-10-21 the mesh runs Rosenpass permissive, so it works without, just not quantum-resistant.
- **ursalia's uplink:** WLAN into the home LAN's main network (Intel BE200, `hosts/ursalia/wifi.nix`): wpa_supplicant, WPA3 with WPA2 fallback, country DE, all bands, passphrase via sops. Its final spot has no cable; eno1 keeps DHCP as a fallback with a worse route metric, so the WLAN stays the primary link when both are up.
- **zorlock's uplink:** WLAN as well (`en1`, Broadcom); `hosts/zorlock/wifi.nix` makes sure `homelab` is a preferred network (`networksetup`, only ever adds it, passphrase via sops in `hosts/zorlock/wifi.yaml`). nix-darwin has no Wi-Fi module; band choice stays with macOS.
- **Subraum:** routed through cuckoosegg for `subraum-access`. cuckoosegg itself may only reach grammi's ingest (TCP 8428/9428) and may only be reached from the MacBook via SSH.
- **Tailscale** still runs in parallel during the migration and serves as break-glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

## Access

Only 22/80/443 are open to the public. `modules/ssh.nix` allows root SSH only from mesh or Tailscale addresses; every host has its own login keypair. The mesh is IPv4 only for now; dual stack is listed as an open item.

### Apps on grammi: only through Traefik `:8090`

Mealie, Grist, logchef and Grafana listen on `127.0.0.1` only on grammi. The reverse proxy reaches them through Traefik's `apps` entrypoint (port 8090), which puts the maintenance switch and error pages in front of every app ([maintenance mode](../how-to/maintenance.md)). VictoriaMetrics (8428) and VictoriaLogs (9428) still listen on all addresses, because the other hosts push their metrics and logs into them over the mesh.

**Deliberate gap:** `:8090` itself is open to every mesh peer (`nb-mesh` is trusted), without the proxy's SSO. Anyone in the mesh reaches every app directly with the matching `Host` header, VictoriaMetrics/-Logs even without a login, since they have none of their own. This is intended (2026-10-23): the NetBird policies decide who reaches grammi, and Mealie, Grist, logchef and Grafana ask for their own login. Revisit when peers that deserve less trust join the mesh, or once the proxy can reach loopback via `direct_upstream` ([open item](../project/open-items.md)).

### Private docs: admin devices only

The private version of this documentation (`doku.homelab.example`, on aldrin and ursalia) contains every internal address and describes how the lab is run. That is more than every device in the mesh needs to see. So nginx serves it only to the mesh addresses of the admins' devices; everyone else gets 403 – with a page of its own that says why, which address the request came from and how a device gets in (without the navigation, so the page titles stay hidden). The name itself resolves for all peers.

**From outside** the same name leads to the public, anonymised docs (GitHub Pages): publicly `doku` is a CNAME to the reverse proxy, whose service `doku` hands it on without a login to a listener on aldrin (port 8091, mesh only) that knows nothing but a redirect. Whoever is in the mesh gets to aldrin and ursalia directly through the NetBird zone.

| Who | Path | Result |
| --- | --- | --- |
| Outside, or NetBird off | reverse proxy (grammi) → aldrin:8091 | 301 to the public docs |
| In the mesh, device in `admin-workstations` | straight to aldrin/ursalia | private docs |
| In the mesh, any other device | straight to aldrin/ursalia | 403 page |

**Why through the proxy:** this way `doku` is listed with the other public names in the NetBird dashboard instead of being a public vhost of its own on aldrin. The proxy cannot redirect by itself, only forward – hence the redirect listener. It has a port of its own rather than the docs vhost recognising the proxy by its address: the proxy is a peer of its own whose mesh address Tofu does not know. Linking `homelab.example` to the public docs is accepted on purpose; the real addresses stay replaced there.

**What counts as an admin device:** the devices in the group `admin-workstations` (`terraform/netbird/subraum.tf`), today the MacBook – the same device that may also SSH to the Subraum devices. Deliberately not the person group `homelab_admins`: that one is filled from Pocket ID with *all* devices of an admin user. Today that would be none (Calla has no devices of its own), and a phone signing in under an admin user would be in at once. An admin here is a device named in Tofu, not a login. A further device in `admin-workstations` therefore also gets SSH to the Subraum devices – the same trust. Tofu reads the members on every `just netbird-apply` and writes name → address to `terraform/netbird/admin-peers.json`; `flake.nix` hands the addresses to `services.docsSite.allow`. A new admin device therefore gets in after `just netbird-apply`, a commit and a deploy of aldrin and ursalia.

**Why nginx and not a NetBird policy:** `to-servers` lets the devices of all persons (`homelab` and `homelab_admins`) reach all ports on all servers. NetBird policies can only allow, never deny – a narrower rule for the docs would change nothing as long as `to-servers` stays as it is. Narrowing `to-servers` to a port list per service would work, but touches every service on every server for one static site. Moving the docs to a port of their own fails at the same point. So the policy still decides which hosts a device reaches, and nginx decides who gets the docs.

**Why no login (Pocket ID):** you read the docs when something is broken. A login would tie them to zummi (Pocket ID) and, through the reverse proxy, to grammi – exactly the hosts they are meant to be independent of. An address list needs nothing at runtime but nginx on the host itself.

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
