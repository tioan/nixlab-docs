# Site gateway: Remote

The remote site (a club whose Omada network is looked after from here) is connected to the lab through **gw-remote**: a NixOS container on aldrin that is the OpenVPN server for the site's router and, in the mesh, the routing peer into its four VLANs. Only the admin device reaches the devices there, nothing behind the router reaches the lab. Click a box to jump to its section.

## Architecture { #architecture }

<figure class="nx-diagram">
<svg viewBox="0 0 680 490" role="img" aria-labelledby="gw-remote-title gw-remote-desc" xmlns="http://www.w3.org/2000/svg">
<title id="gw-remote-title">The remote site through gw-remote</title>
<desc id="gw-remote-desc">gusto reaches the container gw-remote on aldrin over NetBird. The ER7206 at the remote site opens two OpenVPN tunnels to it, one per uplink. Other peers have no access, from the site only replies come back.</desc>
<style>
.nx-t { font-size: 14px; font-weight: 500; fill: #1f1e1d; }
.nx-s { font-size: 12px; fill: #6b6965; }
.nx-line { stroke: #b4b2a9; stroke-width: 0.75; fill: none; }
.nx-frame { fill: none; stroke: #b4b2a9; stroke-width: 0.75; stroke-dasharray: 4 4; }
.nx-box { fill: #fbfaf7; stroke: #b4b2a9; stroke-width: 0.75; }
.nx-gray rect { fill: #f1efe8; stroke: #5f5e5a; stroke-width: 0.75; }
.nx-gray .nx-t { fill: #444441; } .nx-gray .nx-s { fill: #5f5e5a; }
.nx-purple rect { fill: #eeedfe; stroke: #534ab7; stroke-width: 0.75; }
.nx-purple .nx-t { fill: #3c3489; } .nx-purple .nx-s { fill: #534ab7; }
.nx-coral rect { fill: #faece7; stroke: #993c1d; stroke-width: 0.75; }
.nx-coral .nx-t { fill: #712b13; } .nx-coral .nx-s { fill: #993c1d; }
</style>
<g class="nx-gray"><rect x="40" y="60" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="83" text-anchor="middle">grammi</text><text class="nx-s" x="100" y="102" text-anchor="middle">NetBird mgmt</text></g>
<a href="#access"><g class="nx-purple"><rect x="40" y="158" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="181" text-anchor="middle">gusto</text><text class="nx-s" x="100" y="200" text-anchor="middle">MacBook, mesh</text></g></a>
<a href="#access"><g class="nx-gray"><rect x="40" y="290" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="313" text-anchor="middle">Other peers</text><text class="nx-s" x="100" y="332" text-anchor="middle">no policy</text></g></a>
<rect class="nx-frame" x="190" y="60" width="260" height="380" rx="16"/>
<text class="nx-t" x="210" y="88">aldrin</text><text class="nx-s" x="210" y="106">Realtox DUS, static IPv4</text>
<rect class="nx-box" x="210" y="120" width="220" height="300" rx="12"/>
<text class="nx-t" x="225" y="144">gw-remote (container)</text>
<a href="#access"><g class="nx-purple"><rect x="230" y="158" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="181" text-anchor="middle">NetBird router</text><text class="nx-s" x="320" y="200" text-anchor="middle">policy: gusto only</text></g></a>
<a href="#isolation"><g class="nx-gray"><rect x="230" y="224" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="247" text-anchor="middle">nftables</text><text class="nx-s" x="320" y="266" text-anchor="middle">from the site: replies only</text></g></a>
<a href="#failover"><g class="nx-coral"><rect x="230" y="290" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="313" text-anchor="middle">tun-remote-uplink1</text><text class="nx-s" x="320" y="332" text-anchor="middle">udp/1194</text></g></a>
<a href="#failover"><g class="nx-coral"><rect x="230" y="356" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="379" text-anchor="middle">tun-remote-uplink2</text><text class="nx-s" x="320" y="398" text-anchor="middle">udp/1195</text></g></a>
<rect class="nx-frame" x="475" y="60" width="165" height="360" rx="16"/>
<text class="nx-t" x="490" y="88">Remote site</text>
<g class="nx-coral"><rect x="485" y="100" width="145" height="56" rx="8"/><text class="nx-t" x="557" y="123" text-anchor="middle">LAN</text><text class="nx-s" x="557" y="142" text-anchor="middle">VLANs 1, 79, 80, 81</text></g>
<line class="nx-line" x1="557" y1="156" x2="557" y2="176"/>
<a href="#profiles"><g class="nx-coral"><rect x="485" y="176" width="145" height="56" rx="8"/><text class="nx-t" x="557" y="199" text-anchor="middle">ER7206</text><text class="nx-s" x="557" y="218" text-anchor="middle">OpenVPN client 2.3.8</text></g></a>
<g class="nx-coral"><rect x="485" y="296" width="122" height="44" rx="8"/><text class="nx-t" x="546" y="323" text-anchor="middle">SFP WAN</text></g>
<g class="nx-coral"><rect x="485" y="362" width="122" height="44" rx="8"/><text class="nx-t" x="546" y="389" text-anchor="middle">WAN (CGNAT)</text></g>
<path class="nx-line" d="M622 232 L622 384 L609 384"/>
<path class="nx-line" d="M622 318 L609 318"/>
<line x1="160" y1="186" x2="227" y2="186" stroke="#7F77DD" stroke-width="1.5"/><path d="M222 182 L228 186 L222 190" stroke="#7F77DD" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="485" y1="318" x2="413" y2="318" stroke="#D85A30" stroke-width="1.5"/><path d="M418 314 L412 318 L418 322" stroke="#D85A30" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="485" y1="384" x2="413" y2="384" stroke="#D85A30" stroke-width="1.5" stroke-dasharray="5 4"/><path d="M418 380 L412 384 L418 388" stroke="#D85A30" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="40" y1="462" x2="80" y2="462" stroke="#D85A30" stroke-width="1.5"/>
<text class="nx-s" x="90" y="466">tunnel up, metric 100</text>
<line x1="270" y1="462" x2="310" y2="462" stroke="#D85A30" stroke-width="1.5" stroke-dasharray="5 4"/>
<text class="nx-s" x="320" y="466">standby, metric 200</text>
<text class="nx-s" x="40" y="486">arrow = who opens the connection</text>
</svg>
</figure>

## Who gets in { #access }

Only the admin device: the four NetBird policies `remote-*` (`terraform/netbird/remote.tf`, one per VLAN) have `admin-workstations` as their source, that is gusto, and no person group. Every other peer does not even get the route. When gusto is at the site itself, the route goes away (posture check `not-at-remote`) and traffic goes direct.

gw-remote itself is in the group `remote-devices`, not `servers`: it ends tunnels from a network others run, so it reaches only what it is explicitly allowed, grammi's metrics and log ingest (`remote-devices-telemetry`, TCP 8428/9428), like cuckoosegg.

## Isolation { #isolation }

Nothing from the site gets into the lab. Three layers see to that:

- **A container with a network namespace of its own** on aldrin: `tun-remote-*` and a second `nb-mesh` never meet aldrin's trusted mesh interface. No kernel of its own - the deliberate trade-off against a VM (2026-10-22).
- **nftables in the container** (`hosts/gw-remote/container.nix`): the tunnels are not trusted. New connections into a tunnel only from the admin devices' mesh addresses (`admin-peers.json`), out of a tunnel only replies (`established,related`), nothing at all to the container itself. Masquerade per tunnel: the site only sees gw-remote's tunnel address and needs no route back.
- **nftables on aldrin** (`hosts/aldrin/gw-remote.nix`): the OpenVPN ports are forwarded to the container only from the two uplinks' addresses; the container reaches the internet only, neither aldrin nor its mesh.

No CrowdSec on these ports: its bouncer only hooks input, the ports are forwarded, and community blocklists list CGNAT addresses. The protection is the source filter and `tls-auth`.

Tested 2026-11-02: gusto reaches the devices, ursalia and aldrin do not; from the ER7206, gw-remote, aldrin's end of the container link and mesh addresses get no answer.

## Tunnels and failover { #failover }

One OpenVPN server per uplink, not one for both clients: with one server both clients would announce the same networks via `iroute`, and OpenVPN rather than the kernel would pick which one gets the traffic - with no clean way back when the active one drops. Two servers are two tun interfaces, and the kernel picks by route metric.

| Uplink | Line at the ER7206 | Port | Interface | Metric |
| --- | --- | --- | --- | --- |
| uplink1 | SFP WAN, Vodafone, static IPv4 | udp/1194 | `tun-remote-uplink1` | 100 |
| uplink2 | WAN, CGNAT | udp/1195 | `tun-remote-uplink2` | 200 |

`client-connect` sets the routes to the VLANs once an uplink's client is connected, `client-disconnect` removes them. OpenVPN runs without root for that, with `CAP_NET_ADMIN` only. The VLANs come from the inventory (networks with `site: "remote"`), ports, transfer nets and metrics from `hosts/gw-remote/site.json`.

`keepalive 2 10`: when an uplink fails, gw-remote notices after 20 s. In the test with the previous `keepalive 10 60` the site was unreachable for exactly 120 s, failing back cost 3 s. Connections opened while uplink2 carried the traffic keep its masquerade address after failback and may break.

## Profiles on the ER7206 { #profiles }

The ER7206 (firmware 1.4.3) ships **OpenVPN 2.3.8**. Hence:

- no `tls-crypt`: it silently drops a profile with it - no packet, no log, no session. Hence `tls-auth`.
- no cipher negotiation: the server offers GCM first and falls back to `AES-256-CBC` with `auth SHA256` for it.
- the controller takes only an IP as the server, no name. `just gw-remote-ovpn` writes aldrin's address into the profile.
- the controller's VPN status page stays empty for these clients even while the tunnel is up. gw-remote's metrics show the state.

New profile (needs the workstation key):

```bash
just gw-remote-ovpn uplink1 ~/Downloads/remote-uplink1.ovpn
```

Create it in the controller as a VPN client of type OpenVPN (name `remote_uplink1`, it takes no dashes), mode Certificate, interface SFP WAN (uplink1) or WAN (uplink2), all four VLANs as local networks. Delete the file afterwards. `just gw-remote-pki` creates the CA, the server and the two client certificates; the CA key is thrown away, a new client means a new CA and new profiles.

## Monitoring { #monitoring }

gw-remote ships metrics and logs to grammi like every host. On top, per uplink, `nixlab_remote_uplink_connected`, `…_connected_since_seconds` and the bytes of the current session (`hosts/gw-remote/uplink-metrics.nix`, from OpenVPN's status file). Alerts: **RemoteUplinkDown** (one uplink disconnected for 30 min - also what an address that left the source filter looks like) and **RemoteSiteUnreachable** (none for 10 min). Dashboard: the "Site tunnels" row in Homelab / NetBird.

## Operations { #operations }

- **Commands in the container:** `ssh root@aldrin.peer.homelab.example systemd-run -M gw-remote --wait --pipe -q -E PATH=/run/current-system/sw/bin /run/current-system/sw/bin/bash -c '…' </dev/null`. Not `nixos-container run` without a terminal: it stays stopped and keeps the container's init alive (2026-11-02).
- **First deploy:** the NetBird login in the container is deliberately no boot job (`Type=exec`). aldrin brings up its end of the container link only once the container reports it has booted - a waiting login had deadlocked that.
- **uplink2's address changed:** RemoteUplinkDown fires, the new address is in OpenVPN's log or `tcpdump` on aldrin; then adjust `sources.uplink2` in `hosts/aldrin/gw-remote.nix`. Whether the extra single address is still needed gets checked against the logs at the end of November 2026.
