# nixlab – Project documentation

As of: 2026-10-19 · [Deutsch](README.de.md) · [PDF](nixlab-documentation.en.pdf) · [Website](https://tioan.github.io/nixlab-docs/)

> This documentation describes a private repo. The domain and internal addresses are replaced with example values: the domain with `homelab.example` ([RFC 2606](https://www.rfc-editor.org/rfc/rfc2606)), IPv4 per [RFC 5737](https://www.rfc-editor.org/rfc/rfc5737) (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), IPv6 per [RFC 3849](https://www.rfc-editor.org/rfc/rfc3849) (`2001:db8::/32`), the tailnet name with `example-tailnet.ts.net`. The real mesh range is a /22 out of RFC 1918. Modules, documentation and build tooling were written together with Claude (Anthropic). License: [MIT](LICENSE).


## Overview

nixlab is the flake monorepo for the **homelab.example** homelab: five NixOS hosts, a Mac mini running nix-darwin and the admin workstation gusto (a MacBook, nix-darwin + home-manager), plus three OpenTofu modules for the NetBird account, the deSEC API tokens and the GitHub repositories with their deploy keys. Everything is operated through a `justfile` from gusto; the hosts pull their own configuration from the private GitHub repo and update themselves overnight.

Short answer to the question *"Did you wire NixOS and OpenTofu together somehow?"*: **Yes, but deliberately loosely – through files in the repo, not through a shared tool.** OpenTofu writes sops-encrypted files into `hosts/<host>/` that the NixOS modules read at build time, and both sides read the same service list `hosts/grammi/proxy-services.json`. No terranix, no Tofu run from within Nix. Details in [NixOS & OpenTofu](#nixos--opentofu).

Audience: people who can read NixOS flakes, sops-nix and Terraform/OpenTofu.

## NixOS & OpenTofu

Yes, the two are wired together – with the repo as the shared interface. OpenTofu manages what exists outside the machines behind an API (NetBird account, deSEC tokens, Pocket ID groups); NixOS manages the machines. The two never talk to each other directly: Tofu only runs on the MacBook through `just`, Nix never evaluates Tofu state.

<figure class="nx-diagram">
<svg viewBox="0 0 680 452" role="img" aria-label="Tofu and NixOS only share files in the repo: OpenTofu talks to the APIs, its results land as files in the repo, and the Nix flake reads those files" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-ts{font-size:12px}.nx-tx{font-size:11px}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}.nx-blue rect{fill:#e6f1fb;stroke:#185fa5}.nx-blue .nx-t{fill:#042c53}.nx-blue .nx-s{fill:#185fa5}</style>
<text class="nx-t" x="16" y="24">Tofu and NixOS only share files in the repo</text>
<text class="nx-s" x="16" y="42">Arrows show where data flows</text>
<text class="nx-s" x="76" y="78" text-anchor="middle">API (over the network)</text>
<text class="nx-s" x="224" y="78" text-anchor="middle">OpenTofu on the MacBook</text>
<text class="nx-s" x="387" y="78" text-anchor="middle">Repo files</text>
<text class="nx-s" x="571" y="78" text-anchor="middle">Nix flake</text>
<path class="nx-line" d="M152 114.0 H136"/><path class="nx-line" d="M142 110.0 L136 114.0 L142 118.0"/><path class="nx-line" d="M146 110.0 L152 114.0 L146 118.0"/>
<path class="nx-line" d="M152 174.0 H136"/><path class="nx-line" d="M142 170.0 L136 174.0 L142 178.0"/><path class="nx-line" d="M146 170.0 L152 174.0 L146 178.0"/>
<path class="nx-line" d="M152 234.0 H136"/><path class="nx-line" d="M142 230.0 L136 234.0 L142 238.0"/><path class="nx-line" d="M146 230.0 L152 234.0 L146 238.0"/>
<path class="nx-line" d="M296 114.0 H312"/><path class="nx-line" d="M306 110.0 L312 114.0 L306 118.0"/>
<path class="nx-line" d="M312 174.0 H296"/><path class="nx-line" d="M302 170.0 L296 174.0 L302 178.0"/>
<path class="nx-line" d="M296 234.0 H312"/><path class="nx-line" d="M306 230.0 L312 234.0 L306 238.0"/>
<path class="nx-line" d="M462 114.0 H478"/><path class="nx-line" d="M472 110.0 L478 114.0 L472 118.0"/>
<path class="nx-line" d="M462 174.0 H478"/><path class="nx-line" d="M472 170.0 L478 174.0 L472 178.0"/>
<path class="nx-line" d="M462 234.0 H478"/><path class="nx-line" d="M472 230.0 L478 234.0 L472 238.0"/>
<path class="nx-line" d="M462 294.0 H478"/><path class="nx-line" d="M472 290.0 L478 294.0 L472 298.0"/>
<path class="nx-line" d="M296 186 H304 V294.0 H312"/><path class="nx-line" d="M306 290.0 L312 294.0 L306 298.0"/>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="16" y="90" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="112" text-anchor="middle">NetBird API</text><text class="nx-s" x="76" y="129" text-anchor="middle">mesh.homelab.example</text></a>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="16" y="150" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="172" text-anchor="middle">Pocket ID API</text><text class="nx-s" x="76" y="189" text-anchor="middle">auth.homelab.example</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="16" y="210" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="232" text-anchor="middle">deSEC API</text><text class="nx-s" x="76" y="249" text-anchor="middle">token management</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="152" y="90" width="144" height="108" rx="8" stroke-width="1"/><text class="nx-t" x="224" y="142" text-anchor="middle">netbird</text><text class="nx-s" x="224" y="159" text-anchor="middle">terraform/netbird</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="152" y="210" width="144" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="224" y="232" text-anchor="middle">desec-tokens</text><text class="nx-s" x="224" y="249" text-anchor="middle">terraform/desec-tokens</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="312" y="90" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="387" y="112" text-anchor="middle">netbird.yaml</text><text class="nx-s" x="387" y="129" text-anchor="middle">hosts/host/, sops</text></a>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-blue"><rect x="312" y="150" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="387" y="172" text-anchor="middle">proxy-services.json</text><text class="nx-s" x="387" y="189" text-anchor="middle">hosts/grammi/, plain text</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="312" y="210" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="387" y="232" text-anchor="middle">desec.yaml</text><text class="nx-s" x="387" y="249" text-anchor="middle">hosts/host/, sops</text></a>
<a data-target="peers" tabindex="0" role="link" class="nx-gray"><rect x="312" y="270" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="387" y="292" text-anchor="middle">expected-peers.json</text><text class="nx-s" x="387" y="309" text-anchor="middle">terraform/netbird/</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="478" y="90" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="112" text-anchor="middle">netbird.nix</text><text class="nx-s" x="571" y="129" text-anchor="middle">modules/, setup key</text></a>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-gray"><rect x="478" y="150" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="172" text-anchor="middle">topology.nix</text><text class="nx-s" x="571" y="189" text-anchor="middle">Grafana topology</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="478" y="210" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="232" text-anchor="middle">acme.nix</text><text class="nx-s" x="571" y="249" text-anchor="middle">modules/, DNS-01 token</text></a>
<a data-target="peers" tabindex="0" role="link" class="nx-gray"><rect x="478" y="270" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-tx" x="571" y="292" text-anchor="middle">netbird-expected-peers.nix</text><text class="nx-s" x="571" y="309" text-anchor="middle">hosts/grammi/, metric</text></a>
<text class="nx-s" x="16" y="346">tofu apply creates account, policies and tokens and gets setup keys and tokens back;</text>
<text class="nx-s" x="16" y="363">just netbird-key and desec-key encrypt them with sops for the target host into the repo.</text>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-blue"><rect x="16" y="382" width="316" height="52" rx="8" stroke-width="1"/><text class="nx-t" x="174" y="406" text-anchor="middle">Both sides read proxy-services.json</text><text class="nx-s" x="174" y="423" text-anchor="middle">maintained by hand, plain text in the repo</text></a>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="348" y="382" width="316" height="52" rx="8" stroke-width="1"/><text class="nx-t" x="506" y="406" text-anchor="middle">Runs on NixOS itself (grammi, zummi)</text><text class="nx-s" x="506" y="423" text-anchor="middle">Reverse direction: no tofu apply without these hosts</text></a>
</svg>
</figure>

Tofu never writes to a host directly: every result ends up as a file in the repo and reaches the host only with the next deploy.

### The touch points

#### NetBird setup key

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/netbird.yaml` | `just netbird-key <host>` (`tofu output setup_keys` → `sops encrypt`) | `modules/netbird.nix` (`sopsFile`) | One-time setup key, valid for 24 h |

The flow for a new host: Tofu creates the setup key, `just netbird-key` writes it encrypted for exactly that host (age key derived from its SSH host key) to `hosts/<host>/netbird.yaml`, commit, deploy within 24 h. The host registers itself on start; Tofu does not manage peers, it looks them up by name via `data "netbird_peer"`.

#### deSEC token

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/desec.yaml` | `just desec-key <host>` (`tofu output acme_tokens` → `sops encrypt`) | `modules/acme.nix` (`sopsFile`) | deSEC token for TXT records only, VMs pinned to their IP |

#### Expected and admin peers

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `terraform/netbird/expected-peers.json` | `just netbird-apply` (`tofu output expected_peers`, computed from the policies in `expected-peers.tf`) | `hosts/grammi/netbird-expected-peers.nix` (`builtins.readFile`) | Expected NetBird peers per host as metric `netbird_expected_peers`, next to the real network map in the NetBird dashboard (e.g. aldrin 6, grammi 8) |
| Tofu → NixOS | `terraform/netbird/admin-peers.json` | `just netbird-apply` (`tofu output admin_peers`, from the group `admin-workstations`, `admin-peers.tf`) | `flake.nix` (`builtins.readFile`, option `services.docsSite.allow`) | Mesh addresses of the admins' devices (v4 and v6 per device) – who may read the private docs |

#### proxy-services.json

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| shared | `hosts/grammi/proxy-services.json` | by hand | `terraform/netbird/reverse-proxy.tf` (`jsondecode(file(...))`) and `topology.nix` | Name → app, port, groups of the reverse proxy services |

#### GitHub deploy key

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| repo → both | `hosts/<host>/github.yaml` + `github-deploy.pub` | `just github-key <host>` (`ssh-keygen` → `sops encrypt`) | private half: `modules/deploy.nix` (`sopsFile`); public half: `terraform/github` (`file(...)`) | Deploy key for `/etc/nixos`; Tofu only ever sees the public half |

#### NixOS → Tofu

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| NixOS → Tofu | NetBird server on grammi | `hosts/grammi/netbird.nix` | provider via `https://mesh.homelab.example` | The API Tofu runs against in the first place |
| NixOS → Tofu | Bootstrap tokens | `just netbird-setup-owner`, `netbird-proxy-token` (SSH to grammi, server API) | `terraform/netbird/secrets.yaml` and `hosts/grammi/netbird-proxy.yaml` | Owner PAT, proxy token |
| NixOS → Tofu | Garage admin token | `hosts/aldrin/secrets.yaml` (`garage_admin_token`), copied by `just garage-admin-token` (SSH to aldrin) | `terraform/secrets.yaml`, `terraform/lib.sh` (`garage_env`) for `terraform/garage` and `just healthlog-offhost` | Full admin API at `http://aldrin.peer.homelab.example:3903` (admin devices in the mesh only, `admin-peers.json`); after a rotation run the recipe again |

### Tofu state

Every module has exactly one state file in the main checkout (`terraform/<module>/<name>.tfstate`), also when a recipe runs from a worktree. It holds setup keys and tokens and is therefore encrypted with OpenTofu's state encryption (AES-GCM, key via PBKDF2) and **committed**. The passphrase is `tf_state_passphrase` in `terraform/secrets.yaml`, sops-encrypted for the workstation and the admin key, one for all modules. `terraform/lib.sh` builds `TF_ENCRYPTION` from it; the passphrase never sits in a file. Recipes whose tofu call changed the state commit exactly that file right afterwards (other staged changes stay untouched); pushing stays manual. A plaintext state is never committed – `tf_init` and the commit refuse it.

**Restoring** after a lost workstation: clone the repo, set up the sops key (see [Recipes](#just-recipes)), done – the recipes read the state from the checkout. Without the workstation key, the admin recovery key decrypts `terraform/secrets.yaml`. `just netbird-import` is only needed when git does not have the state either. Since 2026-10-24; before that the state was gitignored and lived on the workstation only (on 2026-10-22 only in the old MacBook's Time Machine backup).

### What is deliberately not wired

- **No shared host list.** Hosts are listed three times: `nixosConfigurations` in `flake.nix`, `local.hosts` in the Tofu modules and `hosts :=` in the `justfile`. A new host has to be added in all three places.
- **No terranix / no Tofu in the Nix build.** Tofu runs on the workstation only; the state is in the repo, encrypted ([Tofu state](#tofu-state)), and Nix never evaluates it.
- **No provisioning of the machines.** The VMs are created by hand at the provider, ursalia/cuckoosegg following `docs/install-*.md`.
- **Public DNS** lives in DNSControl (its own repo, only linked in via symlink), not in Tofu.

So the line is: whatever Nix can build deterministically from the repo, Nix does. Whatever is created once through an API and returns a secret, Tofu does – and hands it over encrypted as a file.

## Secrets, network & access

### Secrets (sops-nix, age)

Every host file is encrypted for exactly two recipients: the age key derived from the host's SSH host key and the offline recovery key `admin`. So the MacBook cannot read host secrets – `just secrets <host>` edits them on the host and fetches the result back. Encrypting for a host, on the other hand, works anywhere (only the public key is needed); that is exactly what `netbird-key` and `desec-key` use.

| File | Recipients | Contents |
| --- | --- | --- |
| `hosts/<host>/secrets.yaml` | host + admin | Deploy key, app passwords, OIDC clients, restic |
| `hosts/<host>/netbird.yaml` | host + admin | NetBird setup key (from Tofu) |
| `hosts/<host>/desec.yaml` | host + admin | deSEC token (from Tofu) |
| `hosts/<host>/github.yaml` | host + admin | GitHub deploy key (from `just github-key`) |
| `hosts/<host>/waf.yaml` | host + admin | the WAF bouncer's key (from `just waf-key`, see [WAF](#web-application-firewall)) |
| `terraform/*/secrets.yaml` | workstation + admin | API tokens for the providers |

The workstation key lives in 1Password and is read via `SOPS_AGE_KEY_CMD`, never as a file. `env.sh` in each Tofu module decrypts the tokens only into the shell of the respective recipe.

### Network

- **NetBird mesh** (`192.0.2.0/24` and `2001:db8:203:0::/64`, peer names under `peer.homelab.example`): control plane on grammi, login via Pocket ID. Private range (RFC 1918) instead of CGNAT, because tailscaled drops packets from 100.64/10 while both clients run in parallel.
- **Groups:** `servers` (all hosts except cuckoosegg), `subraum-devices`, `remote-devices` (gw-remote, [site gateway](#site-gateway-remote)), `admin-workstations` (MacBook), plus person groups from Pocket ID.
- **Home LAN** (`198.51.100.0/24`): routed through ursalia (metric 100), with the two Apple TVs as fallback (group `home-routers`, metric 200, own setup key via `just netbird-router-key`, owned by nobody, in no policy); for group `home-lan`, not for devices that are already at home (posture check `not-at-home`). Rosenpass is off mesh-wide since 2026-10-24 (until 2026-10-31, see [macOS hosts](#netbird-on-the-two-macs)); "Quantum-Resistance" in the Apple TVs' app belongs off for that time as well.
- **Travel router** (Mudi 7, GL.iNet GL-E5800): peer `mudi7`, group `travel-routers`, own setup key via `just netbird-key-mudi7`, owned by nobody and in no policy for now. The OpenWrt package only ships NetBird 0.24.3; the binary is swapped by hand for the `linux_arm64` release at the mesh's version (`terraform/netbird/travel-router.tf`).
- **ursalia's uplink:** since 2026-11-02 a 2.5G cable (`enp46s0`, `hosts/ursalia/lan.nix`) into the home LAN's main network, DHCP without a reservation. The WLAN (Intel AX211, `modules/home-wifi.nix`) is off: on the Flint 4 the association failed because the 5 GHz network advertises SAE H2E, and wpa_supplicant needs the passphrase in its own configuration for that, which `ext_password` keeps out of it ("SAE: Could not find PT for group 19"). WLAN as a standby next to the cable is left out on purpose: both links up at once is what NetBird handled badly on the M720q.
- **zorlock's uplink:** WLAN as well (`en1`, Broadcom); `hosts/zorlock/wifi.nix` makes sure `homelab` is a preferred network (`networksetup`, only ever adds it, passphrase via sops in `hosts/zorlock/wifi.yaml`). nix-darwin has no Wi-Fi module; band choice stays with macOS.
- **Exit nodes and IPv6:** aldrin and zummi as exit nodes for the group `exit-nodes`; the mesh is dual stack (`2001:db8:203:0::/64`) – see [Exit nodes & IPv6](#exit-nodes--ipv6).
- **Subraum:** routed through cuckoosegg for `subraum-access`. cuckoosegg itself may only reach grammi's ingest (TCP 8428/9428) and may only be reached from the MacBook via SSH.
- **Tailscale** still runs in parallel during the migration and serves as break-glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

#### Exit nodes & IPv6

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

##### Who may

The Pocket ID group `exit-nodes`. Someone joins by being added to the group in Pocket ID (auth.homelab.example); within a minute the [group sync](#pocket-id--netbird-group-sync) carries the membership over to the NetBird group of the same name and so to all of the person's devices. The policy `exit-nodes` lets only this group into the routes' access group `exit-node-access`. Deliberately not everyone: whoever uses an exit node shows up with the server's address.

##### Using them

The routes are present on every device of the group but off (`skip_auto_apply`) until one is picked – in the NetBird app under "Exit Node" or "Networks", or on the CLI:

```bash
netbird networks select exit-aldrin
```

```bash
netbird networks deselect exit-aldrin
```

Each exit node has two routes, `exit-aldrin` (`0.0.0.0/0`) and `exit-aldrin-v6` (`::/0`). A client from 0.81 on pairs them by name and shows them as one entry "0.0.0.0/0, ::/0": one toggle moves v4 and v6, no IPv6 leaks past the exit node through the client's own uplink. Check with `curl -4 ifconfig.co` and `curl -6 ifconfig.co`.

##### On the hosts

Routing and NAT are set up by the NetBird client itself: masquerade for v4 (NAT44) and v6 (NAT66) to the host's public addresses, the policy's ACL in its own nftables table. `modules/netbird-exit-node.nix` additionally turns on forwarding for both families, so it does not depend on the client. Reverse-path filtering stays "strict", the NixOS firewall does not filter forwarding (`filterForward` off, as everywhere).

Why NAT66 rather than public addresses for the clients: a client's overlay address holds mesh-wide, whatever the exit node – a GUA out of aldrin's network would leave through zummi with a foreign source address. Besides, neither host has a routed prefix: aldrin's /64 is on-link, zummi has a /128.

##### Dual stack in the mesh

Since 2026-10-25 the whole mesh is dual stack. Next to its address out of `192.0.2.0/24`, every peer gets one out of the ULA `2001:db8:203:0::/64` (`ipv6_enabled_groups` = All, `terraform/netbird/main.tf`). Peer names under `peer.homelab.example` and the service names (`s3-admin`, `dokumente`, `doku`, `llm`, `acme`, `terraform/netbird/mesh-services.tf`) have AAAA next to A; NetBird serves AAAA only to peers that have v6 themselves. The Apple TVs (client 0.66) stay on v4.

The range sits next to `192.0.2.0/24` everywhere: root SSH (`modules/ssh.nix`), CrowdSec's whitelist, the docs site, garage-ui on aldrin, Paperless and Samba on ursalia, Traefik's `trustedIPs` on grammi, Caddy on zorlock. `admin-peers.json` lists v4 and v6 per device. A new allow list for the mesh gets both ranges.

When the groups in `ipv6_enabled_groups` change, NetBird hands out new v6 addresses. Tofu reads the services' AAAA records at plan time, so after such a change, or for a newly registered peer, it takes a second `just netbird-apply`.

##### Monitoring

Each exit node counts the forwarded traffic per family and direction in an nftables table of its own and hands it to node_exporter as `netbird_exit_node_bytes_total` / `netbird_exit_node_packets_total`. In the dashboard "Homelab / NetBird", the section "Exit nodes" shows throughput and volume. The counters hang off `postrouting`, not `forward`: the NetBird client puts `iifname nb-mesh accept` at the top of every foreign forward chain, so counters behind it would never be reached.

##### Provider from PR #215

The released NetBird provider (v0.0.10) knows neither `ipv6_enabled_groups` nor `network_range_v6` and resets them on every apply of the account settings ([#243](https://github.com/netbirdio/terraform-provider-netbird/issues/243)). Until [PR #215](https://github.com/netbirdio/terraform-provider-netbird/pull/215) is released, `pkgs/terraform-provider-netbird.nix` builds the provider from that PR and `terraform/netbird/env.sh` swaps it in through `dev_overrides`; Tofu warns about it on every run. To undo: remove the package, its flake output and the block in `env.sh`, then `tofu init -upgrade` ([open item](#open-items)).

#### DNS with AdGuard Home

AdGuard Home on ursalia (`hosts/ursalia/adguardhome.nix`, since 2026-11-01) filters DNS for the home LAN and for every person's device in the mesh. Upstream is the same DoT connection to Freifunk München as on every host. Chosen over Pi-hole (no DoT to the upstream without an extra service) and Technitium (configuration only through UI/API, kept in `/var/lib` instead of the flake).

| Who | How | Protocol |
| --- | --- | --- |
| Home LAN | The Flint 4 hands out ursalia as DNS server via DHCP | DNS on 53 (redirected to 5354 by nftables), DoT/DoQ on 853 (`dns.homelab.example`), DoH through nginx (`https://dns.homelab.example/dns-query`) |
| People's devices in the mesh (`homelab`, `homelab_admins`) | NetBird nameserver group `adguard`, primary (`terraform/netbird/nameservers.tf`) | DNS on 5354 over the mesh address (policies `to-dns-udp`/`to-dns-tcp`, ursalia only); the hop runs inside WireGuard |
| Servers, Apple TVs, cuckoosegg, Home Assistant | not at all – their own resolver policy or the router | – |

- **Port 5354 instead of 53:** resolved's stub holds `127.0.0.53:53`, and AdGuard cannot open TCP on `0.0.0.0:53` next to it. Turning the stub off is no option (NixOS points `/etc/resolv.conf` at it), fixed addresses would need the mesh IP in the repo and `ip_nonlocal_bind` for the whole host. Hence: AdGuard on 5354, in the LAN nftables redirects 53 there, the NetBird group uses 5354 directly. On ursalia itself test with `dig @127.0.0.1 -p 5354`.
- **Mesh names** (`peer.homelab.example`, the zones from `mesh-services.tf`) are answered by the NetBird client itself and never reach AdGuard.
- **The router's names:** AdGuard forwards `doku.homelab.example`, `mqtt.homelab.example` and `.lan` to the Flint 4, for the LAN only – see [below](#the-routers-names-conditional-forwarding).
- **ursalia itself** does not resolve through AdGuard but through the router directly (DHCP DNS ignored): an AdGuard failure must not take ursalia's NetBird and the route into the home LAN with it.
- **Configuration from Nix only** (`mutableSettings = false`): changes in the UI are gone after a restart. The UI is for the query log (7 days), statistics and a quick unblock.
- **Admin UI** at `adguard.homelab.example`: reverse proxy with SSO for `homelab_admins`, then AdGuard's own login (user `admin`). Both: besides the proxy, the admin workstations reach the listener on ursalia (port 8096, every port), and AdGuard should not depend on the policies staying this narrow – without its own login it would be open to anyone talking to that port directly.
- **Password:** plaintext only in 1Password; ursalia gets only the bcrypt hash (`hosts/ursalia/adguardhome.yaml`), which AdGuard puts into its configuration on start. New password: `just adguardhome-password`, store it in 1Password, commit, deploy ursalia.
- **Break-glass** without Pocket ID and the proxy: `ssh -L 3020:127.0.0.1:3020 root@ursalia.peer.homelab.example`, then `http://127.0.0.1:3020` with the password from 1Password.
- **ursalia down, in the mesh:** NetBird keeps trying AdGuard for about a minute, then falls back to the device's own DNS and returns by itself once AdGuard answers again (tested 2026-11-01 with the iPhone: AdGuard stopped for 2 min, pages kept loading, back on AdGuard some 20 s after the restart). An outage costs the filtering, not name resolution. The LAN has no such fallback as long as the Flint 4 hands out ursalia only.
- **On the Flint 4, by hand:** DHCP DNS option set to ursalia's LAN address; check IPv6 DNS (RA/DHCPv6) – as long as the router announces itself there, dual-stack devices partly ask past AdGuard. For IPv6, ursalia has a fixed address in the home network's ULA, `<ULA /64>::53` on the cable (derived from `sites.home.ipv6Ula` and `ipv6SubnetId`, `hosts/ursalia/adguardhome.nix`); gruffi's OpenWrt image (`openwrt/gruffi/`) is to announce exactly that one. ursalia itself takes no announced DNS server, neither via DHCPv4 nor via RA/DHCPv6. Home Assistant keeps the router as its DNS.

##### The router's names: conditional forwarding

Some names are answered by the router itself with a LAN address (a local entry), so they work directly at home and without internet – e.g. `mqtt.homelab.example` → Home Assistant. Since AdGuard is the LAN's DNS server, no device asks the router directly any more. AdGuard therefore passes these names on to the router (*conditional forwarding*) instead of knowing the addresses itself:

```nix
upstream_dns = [
  "tls://dot.ffmuc.net"                                   # everything else
  "[/doku.homelab.example/mqtt.homelab.example/lan/]198.51.100.1"  # these names: the router
];
```

- **Syntax:** `[/name1/name2/]server` applies to the names listed *and all names below them*; the most specific match wins. `[/sub.name/]#` takes a subname out again (back to the normal upstream).
- **Order of a query:** AdGuard's rewrites (here only `dns.homelab.example`) → blocklists → cache → matching upstream. What goes to the router is filtered too.
- **Why forwarding rather than rewrites:** the entries stay in *one* place, the router. No IP duplicated in the repo, changes on the router take effect at once – except for the cache: AdGuard keeps the answer for its TTL; if impatient: UI → Settings → DNS settings → Clear cache.
- **LAN only:** for the mesh ranges (`192.0.2.0/24`, `2001:db8:203:0::/64`) AdGuard has a persistent client "NetBird mesh" with upstreams of its own – ffmuc only. A client's own upstreams *replace* the global list entirely, so the forwarding line is absent there. A phone on the road gets the public answer for `mqtt.homelab.example` (reverse proxy) instead of 198.51.100.168, which it cannot reach from there.
- **Reverse lookups** (PTR for private addresses) also go to the router via `local_ptr_upstreams`, which knows the DHCP names; private PTR queries never leave the house.

**Adding a new local name:**

1. Create the entry on the router (Flint 4).
2. Add the name to the forwarding line in `hosts/ursalia/adguardhome.nix`, deploy ursalia. AdGuard does not know by itself which names the router overrides – without this step the LAN gets the public answer.
3. Check, in the LAN and in the mesh:

```bash
dig +short mqtt.homelab.example @ursalia.peer.homelab.example -p 5354
```

NetBird's counterpart are nameserver groups with `domains` (match domains): the same idea one level up, per peer group instead of per client address.

### Access

Only 22/80/443 are open to the public. `modules/ssh.nix` allows root SSH only from mesh or Tailscale addresses; every host has its own login keypair. Mesh means both ranges, `192.0.2.0/24` and `2001:db8:203:0::/64` ([dual stack](#dual-stack-in-the-mesh)).

#### Who reaches the servers

`nb-mesh` is a trusted interface on every host; what may reach a server over the mesh is decided by the NetBird policies alone (`terraform/netbird/main.tf`). Since 2026-11-01 (risk register R9) they are split by origin – policies can only allow, so split rather than subtract:

| Policy | from | to | allows |
|---|---|---|---|
| `to-servers` | people's devices (`homelab`, `homelab_admins`) | all servers | TCP 80, 443 |
| `to-smb` | people's devices | ursalia (group `smb-servers`) | TCP 445 |
| `to-servers-icmp` | people's devices | all servers | ICMP |
| `admin-to-servers` | `admin-workstations` (gusto) | all servers | everything |
| `servers-to-servers` | `servers` | all servers | everything |

People's devices thus reach only the web front doors (nginx, Traefik, Caddy with their own rules) and the Samba share – no longer SSH, exporters, Garage's admin API, VictoriaMetrics/-Logs or Traefik's `apps` entrypoint. `homelab_admins` gets no more than `homelab`: admin is a device named in `admin-workstations`, not a login. All of ICMP rather than just ping, because a NetBird rule cannot filter by ICMP type.

The reverse proxy needs none of these policies: NetBird allows its peers to each service target's port by itself (`management/server/types/legacynmap/proxy_policies.go`, 0.81.0). cuckoosegg (only 8428/9428 on grammi), Home Assistant and the exit nodes keep policies of their own. Narrowing `servers-to-servers` to the ports in use is parked ([open item](#open-items)).

To check from a device that is only in `homelab` (MacBook Pro, iPhone): `nc -zv grammi.peer.homelab.example 443` connects, `nc -zv grammi.peer.homelab.example 8090` and `… 8428` time out.

#### Apps on grammi: only through Traefik `:8090`

Mealie, Grist, logchef and Grafana listen on `127.0.0.1` only on grammi. The reverse proxy reaches them through Traefik's `apps` entrypoint (port 8090), which puts the maintenance switch and error pages in front of every app ([maintenance mode](#maintenance-mode)). VictoriaMetrics (8428) and VictoriaLogs (9428) still listen on all addresses, because the other hosts push their metrics and logs into them over the mesh.

**Remaining gap:** `:8090` itself has no SSO. From 2026-10-23 to 2026-11-01 it was open to every mesh peer, every person's devices included; since [`to-servers`](#who-reaches-the-servers) was narrowed to 80/443, only the proxy, the admin devices and the other servers reach the port. It closes completely once the proxy can reach loopback via `direct_upstream` ([open item](#open-items)).

#### Private docs: admin devices, home LAN, login

The private version of this documentation (`doku.homelab.example`, on aldrin and ursalia) contains every internal address and describes how the lab is run. That is more than every device in the mesh needs to see. So nginx serves it only to the mesh addresses of the admins' devices; everyone else gets 403 – with a page of its own that says why, which address the request came from and how a device gets in (without the navigation, so the page titles stay hidden). The name itself resolves for all peers.

**From outside** the same name leads to the public, anonymised docs (GitHub Pages): publicly `doku` is a CNAME to the reverse proxy, whose service `doku` hands it on without a login to a listener on aldrin (port 8091, mesh only) that knows nothing but a redirect. Whoever is in the mesh gets to aldrin and ursalia directly through the NetBird zone.

| Who | Path | Result |
| --- | --- | --- |
| Outside, or NetBird off | reverse proxy (grammi) → aldrin:8091 | 301 to the public docs |
| In the mesh, device in `admin-workstations` | straight to aldrin/ursalia | private docs |
| In the mesh, any other device | straight to aldrin/ursalia | 403 page |
| Outside, `doku.homelab.example/login` | aldrin:8091 → 302 to `doku-login.homelab.example` → reverse proxy with SSO (`docs-readers`) → aldrin:8094 | private docs |
| Home LAN, through the router's own record | straight to ursalia's LAN address | private docs, except devices on the deny list |

**Login from the internet** (decided 2026-10-23): for a device without NetBird, e.g. a work laptop. `doku.homelab.example/login` leads to `doku-login.homelab.example`, a reverse proxy service of its own with SSO for the Pocket ID group `docs-readers` – a name of its own because the proxy's login is per service, not per path, and SSO on `doku` itself would put the public docs behind it. Its target is a listener on aldrin (port 8094) that serves the private site. Because the admin devices and the other servers reach that port over the mesh as well (until 2026-11-01 every person's devices too, see [`to-servers`](#who-reaches-the-servers)), the proxy sends a secret header (`X-Nixlab-Docs-Key`) and aldrin serves only requests that carry it; new key: `just docs-login-key`. This way depends on grammi and zummi – it is an addition for when the mesh is not at hand, not a replacement for it.

**Home LAN** (decided 2026-10-23): the home router answers `doku.homelab.example` with ursalia's LAN address (a record of its own, like `mqtt.homelab.example`), and ursalia serves the private docs to the whole main home network – except the addresses on a deliberate deny list (`services.docsSite.lan` in `hosts/ursalia/configuration.nix`, inventory devices with a fixed address). A deny list by address catches only devices with a reserved address; guests and anything with a changing address get in. The Apple TVs belong on it once they have a reservation: as NetBird fallback routers into the LAN they masquerade mesh peers to their own address. Mesh devices are not affected – for them the name keeps resolving to the mesh addresses.

**Why through the proxy:** this way `doku` is listed with the other public names in the NetBird dashboard instead of being a public vhost of its own on aldrin. The proxy cannot redirect by itself, only forward – hence the redirect listener. It has a port of its own rather than the docs vhost recognising the proxy by its address: the proxy is a peer of its own whose mesh address Tofu does not know. Linking `homelab.example` to the public docs is accepted on purpose; the real addresses stay replaced there.

**What counts as an admin device:** the devices in the group `admin-workstations` (`terraform/netbird/subraum.tf`), today the MacBook – the same device that may also SSH to the Subraum devices. Deliberately not the person group `homelab_admins`: that one is filled from Pocket ID with *all* devices of an admin user. Today that would be none (Calla has no devices of its own), and a phone signing in under an admin user would be in at once. An admin here is a device named in Tofu, not a login. A further device in `admin-workstations` therefore also gets SSH to the Subraum devices – the same trust. Tofu reads the members on every `just netbird-apply` and writes name → address to `terraform/netbird/admin-peers.json`; `flake.nix` hands the addresses to `services.docsSite.allow`. A new admin device therefore gets in after `just netbird-apply`, a commit and a deploy of aldrin and ursalia.

**Why nginx and not a NetBird policy:** [`to-servers`](#who-reaches-the-servers) lets the devices of all persons (`homelab` and `homelab_admins`) reach port 443 on all servers, and the docs share 443 with everything else nginx serves there. A policy works per port, not per vhost. So the policy decides which ports a device reaches, and nginx decides who gets the docs.

**Why no login in the mesh (Pocket ID):** you read the docs when something is broken. A login would tie them to zummi (Pocket ID) and, through the reverse proxy, to grammi – exactly the hosts they are meant to be independent of. An address list needs nothing at runtime but nginx on the host itself. The login from the internet above does not change that: the mesh and LAN ways keep working without it.

**What this deliberately accepts:**

- The list is as current as the last `just netbird-apply` followed by a deploy. Until then a new admin device sees 403, and a removed device still gets in.
- The address stands for the device, not the person: whoever uses an admin device reads the docs.
- The list must never be empty – `just netbird-admin-peers` refuses an empty output, and the module fails the build with an assertion instead of quietly giving everyone 403.
- v4 and v6 per device, like the mesh ([dual stack](#dual-stack-in-the-mesh)). NetBird hands out a new v6 address when the groups in `ipv6_enabled_groups` change – then `just netbird-apply` and a deploy of aldrin and ursalia, or the device sees 403 over v6.

#### Pocket ID: admin pages only from admin devices

Since 2026-10-25 nginx on zummi answers Pocket ID's admin paths with 403 unless the request comes from an address in `admin-peers.json` – the same list as for the private docs. Closed is everything an admin session or an admin API key can do: `/settings/admin`, users, groups, OIDC clients, APIs, API keys, settings, audit log, signup tokens, SCIM (list: `$pocketid_admin_path` in `hosts/zummi/configuration.nix`, by the permissions of Pocket ID 2.19.1's routes – re-check on every minor bump). Login, account pages (`/api/users/me…`), the OIDC endpoints and logos stay public. The one other exception: the [group sync](#pocket-id--netbird-group-sync)'s reads from grammi.

So that admin devices arrive with their mesh address, a NetBird DNS zone points `auth.homelab.example` at zummi's mesh addresses for `admin-workstations` only (`terraform/netbird/pocket-id-admin.tf`); the vhost listens on the wildcard for it. Every other peer, NetBird's server on grammi included, keeps the public record.

- Without NetBird on the device the public record applies: login works, the admin pages answer 403. A browser with its own DNS-over-HTTPS bypasses NetBird's DNS the same way.
- `just pocketid-plan`/`-apply` therefore need NetBird on the MacBook.
- A new admin device: into `admin-workstations`, `just netbird-apply`, then deploy zummi (and aldrin and ursalia, as for the docs).

#### Pocket ID → NetBird: group sync

Who is in which person group lives in Pocket ID only (`terraform/netbird/people.tf`). Until 2026-11-01 a change reached NetBird – and with it the reverse proxy's SSO group checks – only with the next `just netbird-apply`. Since then a timer on grammi reconciles every minute (`hosts/grammi/netbird-group-sync.nix`): for every person in `local.people` it sets `auto_groups` and `is_blocked` exactly as `netbird_user.person` computes them (person groups in Tofu's order, disabled in Pocket ID = blocked in NetBird), so the next plan shows no drift for them. Other groups in `auto_groups` stay untouched. Someone in neither `homelab` nor `homelab_admins` in Pocket ID is left alone and the run fails (the same check as Tofu's precondition). Every change is a line in the journal (`naddi: +home-lan`); right now instead of within a minute: `just netbird-group-sync`.

Decided 2026-11-01 (1b) over an unattended `tofu apply` (applies everything, the state lives on the workstation) and over drift detection alone. NetBird's own JWT group sync stays off (reasons in the header of `people.tf`). A SCIM receiver that Pocket ID pushes changes to right away is noted for later.

**Credentials**, each in a sops file of its own so either can be renewed alone:

- **NetBird:** token of the service user `group-sync` (`terraform/netbird/group-sync.tf`), role admin – NetBird 0.81 allows nothing narrower for updating users (`network_admin` may only read them). Whoever owns grammi owns NetBird's database anyway. Store: `just netbird-group-sync-token`, renew yearly: `just netbird-group-sync-token renew`.
- **Pocket ID:** API key of the dedicated admin user `netbird-group-sync` (no passkey, only for this key; shows up separately in the audit log, disabling the user locks the key at once). Pocket ID 2.19.1 cannot scope API keys: the key can do anything an admin can. It is fenced in on zummi: from grammi's mesh addresses nginx lets through only `GET` on the user list, single users and the key's own key list (`$pocketid_sync_allowed`), from the internet every admin path is 403. Fully usable, the key would only be from the admin devices. That is why the sync reaches Pocket ID at zummi's mesh name (TLS still for `auth.homelab.example`). Creating the key: log in as `netbird-group-sync` with a login code from the admin UI, create the API key "netbird-group-sync" valid for a year, delete that user's old keys, then `just netbird-group-sync-pocketid-key`.

Then commit and deploy grammi each time. **Alerts** (`hosts/grammi/alerting.nix`): NetbirdGroupSyncStale (an hour without a clean run), SyncCredentialExpiring (token or key expire in less than 30 days), PersonNotManaged (someone is in `homelab`/`homelab_admins` in Pocket ID but not in `people.tf`); every failed run also trips UnitFailed.

- A new person: after `just netbird-apply` commit the new `terraform/netbird/group-sync.json` and deploy grammi.
- `group-sync.json` also holds grammi's mesh addresses; when they change (new v6 address), deploy zummi.

#### Paperless: from outside, share links (PIN) and the app (SSO)

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

#### Grafana: public dashboards through `dash`

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

#### MQTT from outside: TLS passthrough to Home Assistant

`mqtt.homelab.example:8883` is the Mosquitto add-on on Home Assistant, for MQTT devices that are also used away from home (AWTRIX NG on an Ulanzi TC002). Same name, port and certificate everywhere, so a device is configured once:

| Where | Path |
| --- | --- |
| At home | the home router (Flint 4) answers `mqtt.homelab.example` with HA's LAN address (local DNS entry) → HA:8883 directly, also without internet |
| Outside | public CNAME to the reverse proxy → `netbird-proxy` on grammi, port 8883 → through the mesh to HA:8883 |

**HA is a NetBird peer** (NetBird add-on, `terraform/netbird/home-assistant.tf`), in a group of its own `home-assistant` – not in `servers`, so it reaches exactly two things and nothing reaches it but the proxy. NetBird's DNS management is off for that group: HA keeps resolving through the home router (Flint 4), also when the internet is gone.

**TLS ends in Mosquitto, not at the proxy.** The service `mqtt` (`terraform/netbird/reverse-proxy.tf`) runs in L4 mode `tls` with the peer HA as its target: the proxy reads only the SNI and passes the connection through untouched. For an L4 service with a port of its own the proxy binds that port itself on all addresses (only 127.0.0.1 has to send a PROXY header there); grammi's firewall opens 8883 in `hosts/grammi/netbird-proxy.nix`.

**The certificate** covers `homeassistant.homelab.example` and `mqtt.homelab.example`. HA's Let's Encrypt add-on gets it via DNS-01 – but without a deSEC token of its own (it could not be pinned to an address, the home address changes). It asks dns01proxy on grammi instead (`hosts/grammi/dns01proxy.nix`, provider `dns-httpreq`), at `https://acme.homelab.example:8446`:

- The port is open only on the mesh, and the policy `home-assistant-acme` lets only HA reach it. HA resolves the name through the home router (Flint 4) (local entry to grammi's mesh address, `tofu output acme_proxy_address`), every other peer through the NetBird zone.
- The proxy writes the TXT records with grammi's address-pinned token. HA's account (password in the add-on, bcrypt hash in `hosts/grammi/dns01proxy.yaml`, `just dns01proxy-key-homeassistant`) may only answer challenges for the two names above.
- dns01proxy serves HTTPS itself and fetches its own certificate for `acme.homelab.example` the same way.

**The two local DNS entries** are `domain` entries in dnsmasq on gruffi, set by hand over SSH (`uci add dhcp domain`, then `name` and `ip`, `uci commit dhcp`, restart dnsmasq). The "Hostnames" page is missing from GL.iNet's LuCI (404 on `view/network/hosts.js`):

| Name | Address | Why |
| --- | --- | --- |
| `mqtt.homelab.example` | 198.51.100.168 (HA's LAN address) | MQTT stays in the home network and works without internet |
| `acme.homelab.example` | 192.0.2.122 (grammi's mesh address, `tofu output acme_proxy_address`) | HA reaches dns01proxy; NetBird does not manage HA's DNS |

If HA's address or grammi's mesh address changes (new lease, NetBird re-registration), the entry has to follow by hand.

The add-on does not renew by itself: an HA automation starts it daily and restarts Mosquitto weekly, so the renewed certificate gets loaded.

**What this deliberately accepts:**

- No login at the proxy – L4 has none. Mosquitto's own users are the only gate, and that includes every login the add-on accepts (its own list and Home Assistant users).
- Mosquitto sees the proxy's mesh address as the sender of every outside connection (the add-on cannot take a PROXY header), so neither HA nor CrowdSec can block a single client by address. The proxy can filter by country or address range (`access_restrictions`), not set for now.
- Certificate renewal needs grammi and the mesh – with 30 days of slack before expiry.
- A device that restarts while the internet is down needs the time from somewhere other than the internet to check the certificate.

#### floccus: tabs and bookmarks through `tabs`

floccus syncs bookmarks and open tabs between browsers, including profiles on devices outside the mesh. The target is a WebDAV server of its own on aldrin (`hosts/aldrin/floccus.nix`): `rclone serve webdav` on loopback, nginx in front as `tabs.homelab.example`, public.

- **Not OpenCloud:** floccus only does basic auth. OpenCloud would need an app token for that, and it would reach every file in the account – in a browser on a device somebody else administers. The password here reaches one directory of tab lists.
- **Not nginx DAV:** floccus asks for the file size with PROPFIND, which nginx only speaks with the `dav_ext` module, and that means building nginx from source on every update. rclone comes from the cache and handles everything floccus sends: GET, PUT, DELETE, MOVE, PROPFIND.
- **Account:** one (`floccus`). `just floccus-password` puts a random password on the clipboard and its bcrypt hash into `hosts/aldrin/floccus.yaml`; without that file the module does nothing. The old password works until the next deploy of aldrin.
- **Content:** floccus has a passphrase set, the server only sees the encrypted file.
- **Backup:** `/data/floccus` is a btrfs subvolume of its own and gets the same btrbk snapshots as OpenCloud – local, on the same volume.

**In floccus:** a profile with sync method WebDAV, URL `https://tabs.homelab.example/`, user `floccus`, the password from the recipe, the same passphrase on every device. For tabs a profile of type "Tabs", for bookmarks a separate one with another file name – two profiles must never share a file. On devices with separate browser profiles (work/private) set floccus up in the private profile only.

## Site gateway: Remote

The remote site (a club whose Omada network is looked after from here) is connected to the lab through **gw-remote**: a NixOS container on aldrin that is the OpenVPN server for the site's router and, in the mesh, the routing peer into its four VLANs. Only the admin device reaches the devices there, nothing behind the router reaches the lab. Click a box to jump to its section.

### Architecture

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

### Who gets in

Only the admin device: the four NetBird policies `remote-*` (`terraform/netbird/remote.tf`, one per VLAN) have `admin-workstations` as their source, that is gusto, and no person group. Every other peer does not even get the route. When gusto is at the site itself, the route goes away (posture check `not-at-remote`) and traffic goes direct.

gw-remote itself is in the group `remote-devices`, not `servers`: it ends tunnels from a network others run, so it reaches only what it is explicitly allowed, grammi's metrics and log ingest (`remote-devices-telemetry`, TCP 8428/9428), like cuckoosegg.

### Isolation

Nothing from the site gets into the lab. Three layers see to that:

- **A container with a network namespace of its own** on aldrin: `tun-remote-*` and a second `nb-mesh` never meet aldrin's trusted mesh interface. No kernel of its own - the deliberate trade-off against a VM (2026-10-22).
- **nftables in the container** (`hosts/gw-remote/container.nix`): the tunnels are not trusted. New connections into a tunnel only from the admin devices' mesh addresses (`admin-peers.json`), out of a tunnel only replies (`established,related`), nothing at all to the container itself. Masquerade per tunnel: the site only sees gw-remote's tunnel address and needs no route back.
- **nftables on aldrin** (`hosts/aldrin/gw-remote.nix`): the OpenVPN ports are forwarded to the container only from the two uplinks' addresses; the container reaches the internet only, neither aldrin nor its mesh.

No CrowdSec on these ports: its bouncer only hooks input, the ports are forwarded, and community blocklists list CGNAT addresses. The protection is the source filter and `tls-auth`.

Tested 2026-11-02: gusto reaches the devices, ursalia and aldrin do not; from the ER7206, gw-remote, aldrin's end of the container link and mesh addresses get no answer.

### Tunnels and failover

One OpenVPN server per uplink, not one for both clients: with one server both clients would announce the same networks via `iroute`, and OpenVPN rather than the kernel would pick which one gets the traffic - with no clean way back when the active one drops. Two servers are two tun interfaces, and the kernel picks by route metric.

| Uplink | Line at the ER7206 | Port | Interface | Metric |
| --- | --- | --- | --- | --- |
| uplink1 | SFP WAN, Vodafone, static IPv4 | udp/1194 | `tun-remote-uplink1` | 100 |
| uplink2 | WAN, CGNAT | udp/1195 | `tun-remote-uplink2` | 200 |

`client-connect` sets the routes to the VLANs once an uplink's client is connected, `client-disconnect` removes them. OpenVPN runs without root for that, with `CAP_NET_ADMIN` only. The VLANs come from the inventory (networks with `site: "remote"`), ports, transfer nets and metrics from `hosts/gw-remote/site.json`.

`keepalive 2 10`: when an uplink fails, gw-remote notices after 20 s. In the test with the previous `keepalive 10 60` the site was unreachable for exactly 120 s, failing back cost 3 s. Connections opened while uplink2 carried the traffic keep its masquerade address after failback and may break.

### Profiles on the ER7206

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

### Monitoring

gw-remote ships metrics and logs to grammi like every host. On top, per uplink, `nixlab_remote_uplink_connected`, `…_connected_since_seconds` and the bytes of the current session (`hosts/gw-remote/uplink-metrics.nix`, from OpenVPN's status file). Alerts: **RemoteUplinkDown** (one uplink disconnected for 30 min - also what an address that left the source filter looks like) and **RemoteSiteUnreachable** (none for 10 min). Dashboard: the "Site tunnels" row in Homelab / NetBird.

### Operations

- **Commands in the container:** `ssh root@aldrin.peer.homelab.example systemd-run -M gw-remote --wait --pipe -q -E PATH=/run/current-system/sw/bin /run/current-system/sw/bin/bash -c '…' </dev/null`. Not `nixos-container run` without a terminal: it stays stopped and keeps the container's init alive (2026-11-02).
- **First deploy:** the NetBird login in the container is deliberately no boot job (`Type=exec`). aldrin brings up its end of the container link only once the container reports it has booted - a waiting login had deadlocked that.
- **uplink2's address changed:** RemoteUplinkDown fires, the new address is in OpenVPN's log or `tcpdump` on aldrin; then adjust `sources.uplink2` in `hosts/aldrin/gw-remote.nix`. Whether the extra single address is still needed gets checked against the logs at the end of November 2026.

## Deployment & operations

The pull hosts (zummi, aldrin, grammi, ursalia) keep `/etc/nixos` as a checkout of the private GitHub repo and build themselves. cuckoosegg is pushed to, zorlock and gusto are switched on the Mac itself with `darwin-rebuild` ([macOS hosts](#macos-hosts)).

| Host | Manual deploy | Automatic |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<message>"` = commit, push, `git pull` + `nixos-rebuild switch` on the host | nightly auto-upgrade, reboot window 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (built on ursalia, copied to the target) | ursalia pushes daily at 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` with sudo, with a summary) | none |
| gusto | `just mac-switch` on gusto, from the working copy | none – `just mac-upgrade` for the Homebrew pins |

### Nightly upgrade

Since 2026-10-31 only ursalia updates the inputs: `nix-cache-prebuild` (`modules/nix-cache.nix`) pulls `main` at 02:30, updates `nixpkgs`, `nixpkgs-unstable` and `sops-nix`, builds every host, uploads everything not on cache.nixos.org, signed, to the nix cache (bucket `nix-cache` in Garage on aldrin) and only then pushes the new `flake.lock` with its deploy key. If one host does not build, the lock is held back for all. From 04:00 `modules/auto-upgrade-git.nix` on every host resets `flake.lock` to HEAD, fast-forwards `main`, builds and switches – with the cache as a second substituter after cache.nixos.org, so even small hosts like zummi no longer build anything themselves. An aborted run no longer leaves a modified `flake.lock` behind (reset at the start and in `ExecStopPost`; `just sync` discards it too). The GitHub host key is pinned because nobody is watching. A configuration error that only shows up on a cold boot therefore takes the host down at 04:00 – for the VMs there is the provider's console for that.

While `just try` holds a host on a topic branch, the upgrade skips it until the branch is merged ([Test a branch before merging](#test-a-branch-on-a-host-before-merging)).

## Monitoring

Everything ends up on grammi: **vmagent** on every host sends metrics to VictoriaMetrics (`:8428`), **Vector** sends journald and nginx logs to VictoriaLogs (`:9428`), both over the mesh. Grafana (`metrics`) and logchef (`logs`) sit behind the reverse proxy with SSO. Exporters per host come from `modules/metrics.nix`; whatever has no endpoint of its own goes through node_exporter's textfile collector (`/var/lib/prometheus-node-exporter-text-files`), written by small timers or services:

| Textfile metric | Host | Source |
| --- | --- | --- |
| `tailscale_*` | hosts with Tailscale | `tailscale metrics write`, every 30 s |
| `fwupd_updates_*` | ursalia | `fwupdmgr get-updates` after each metadata refresh |
| `smart_selftest_*` | ursalia | self-test log of every disk in `services.diskHealth.devices` (`smartctl -l selftest`), hourly (`modules/disk-health.nix`) |
| `wifi_link_*` | tummi | `iw dev wlo1 link` (PHY mode, width, MCS, NSS), every 30 s |
| `node_wifi_*`, `wifi_link_*` | zorlock | `system_profiler SPAirPortDataType -json` every 60 s, same names as on tummi (no receive rate, retries or separate receive PHY mode on macOS; macOS redacts SSID/BSSID without Location Services even for root, shown as "n/a" in the dashboard), plus `wifi_link_noise_dbm` |
| `unit_cgroup_*` | all Linux hosts | CPU time and memory per systemd service from its cgroup, every 15 s (`unit-metrics` in `modules/metrics.nix`); counts every process of the unit, containers with `--cgroups=split` included |
| `esphome_builder_data_bytes` | ursalia | Size of `/var/lib/esphome-builder` (toolchain cache), hourly |
| `grafana_public_dashboard_info` | grammi | public dashboards from Grafana's API with their `dash` link and the template variables they use, every 10 s |
| `netbird_expected_peers` | grammi | `terraform/netbird/expected-peers.json`, baked into the system at build time; label `netbird_host` (the host it is about), since `host` is the sending host on every series as of 2026-11-02 |
| `nixlab_remote_uplink_*` | gw-remote | OpenVPN's status file per uplink: connected, since when, bytes of the current session, every 30 s ([site gateway](#monitoring-1)) |
| `nixlab_netbird_group_sync_*` | grammi | Pocket ID → NetBird group sync (`hosts/grammi/netbird-group-sync.nix`): last clean run, token and key expiry, Pocket ID users outside `people.tf` |
| `nixlab_nixos_upgrade_last_success_seconds` | hosts with the nightly upgrade | time of the last successful `nixos-upgrade` (`modules/auto-upgrade-git.nix`), for the NixosUpgradeStale alert |

The dashboards are JSON in `hosts/grammi/dashboards/`, provisioned from the repo (changes only via commit + deploy of grammi). `topology.json` is generated by `just topology`. "Export as image" is rendered by the Grafana image renderer on grammi (headless Chromium, loopback only `127.0.0.1:8082`); sharing outside see [access](#grafana-public-dashboards-through-dash).

| Dashboard | Shows |
| --- | --- |
| Hosts Overview | Scrape targets, CPU/memory/disk/network per host, failed units, certificates, backups (btrbk, restic), pending firmware, WLAN band/signal |
| Topology | Hosts, exporters and data flows as a Graphviz diagram |
| NetBird | Control plane reachable per host; peers per host as expected (Tofu) / known (network map) / connected P2P / connected relay, plus deviations; connection history, P2P latency, sync and setup times; netbird-server (signal, relay, gRPC, API); throughput and volume of the exit nodes aldrin/zummi per IP family ([exit nodes](#monitoring)) |
| WLAN | ursalia's and zorlock's band (2.4 / 5 / 6 GHz) over time, channel, signal, PHY mode, link rate, traffic, MCS, retries, time associated |
| Disk Health | SMART of ursalia's NVMe and SATA SSD: status, critical warnings, wear, spare, temperature, data written, ATA error counters, outcome and age of the last self-tests |
| Paperless | Health (Celery, Redis, DB, index, classifier), documents, inbox, failed tasks, storage, log warnings |
| paperless-gpt | OCR and suggestion backlog, OCR time per page, LLM requests, durations, tokens, errors; zorlock's GPU and memory |
| ESPHome builds | The build server on ursalia: health, ESPHome version, builds and success rate, duration per build and device, CPU and memory next to Paperless, toolchain cache size, warnings. Builds and durations come from the log lines "Starting job …" / "Job … completed/failed" via LogsQL; device-builder has no metrics endpoint |
| Shared dashboards | Every public dashboard with the link for guests (`dash.homelab.example`) whether it is paused and which variables it uses (those panels stay empty for guests); every dashboard links here at the top right |
| Web & Security | nginx and Traefik requests, status codes, durations; CrowdSec bans, alerts, parser hits |
| Garage (S3 storage) | aldrin's Garage: cluster health, disk, S3 requests/errors/duration, resync and GC queues |
| VictoriaMetrics & VictoriaLogs | Ingest rate, disk usage, query duration, active series |
| zorlock (Mac mini) | mactop: thermal state, CPU/GPU, power, temperatures, memory, fan; Ollama requests, speed, model load times |

**Expected vs. known peers (NetBird):** "expected" is computed by OpenTofu from the policies with the group membership at the last `just netbird-apply` (example: aldrin 6, grammi 8, cuckoosegg 4). "known" is what the management server really distributes. A device that joins later raises known at once, expected only after the next apply + deploy of grammi – on purpose, so a new peer is visible. The model ignores posture checks; see the header of `expected-peers.tf`.

**Log level:** Vector turns journald's `PRIORITY` into the `level` field. Python services log to stderr, so journald files every line as an error. Lines in the format `<date> <time> INFO|WARNING|ERROR …` therefore take their level from the text, minus the colour codes (`modules/log-shipping.nix`).

**Grafana pitfall:** state timelines with `mergeValues` and colour mode "thresholds" turn numbers into threshold buckets ("1+", "< 1") before value mappings are applied. Use colour mode "fixed" and put text and colour into the mappings.

### Alerting

**vmalert** on grammi evaluates rules, one instance against VictoriaMetrics, one against VictoriaLogs. **Alertmanager** groups, mutes and repeats. **Home Assistant** turns each group into a push notification on the iPhone and a notification in HA's web UI. Both disappear again once the alert resolves. Everything listens on `127.0.0.1` only. The single way out is the webhook to HA over the mesh (policy `alerting-home-assistant`, grammi → HA:8123 only). Alertmanager's web UI (alerts, silences) is at `alertmanager.homelab.example` or `alerts.homelab.example`, behind the reverse proxy with SSO, `homelab_admins` only. Code: `hosts/grammi/alerting.nix`.

| Alert | Based on | Fires when |
| --- | --- | --- |
| UnitFailed | journal: systemd's "unit failed" (`MESSAGE_ID d9b373ed…`) per host and unit in 30 min (failures in the mute window: 3 h), plus `node_systemd_unit_state{state="failed"}` for 10 min | one failure is enough, the message gives the count |
| NixosUpgradeStale | `nixlab_nixos_upgrade_last_success_seconds` | no success for 26 h, except under a deploy hold |
| ResticBackupStale, ResticCheckFailed | `restic_backup_timestamp`, `restic_check_success` | newest snapshot older than 26 h, check failed |
| BtrbkSnapshotStale | `btrbk_last_snapshot_timestamp_seconds` | older than 26 h |
| CertExpiring | `ssl_certificate_expiry_seconds`, only `/var/lib/acme/<domain>/cert.pem` | less than 21 days |
| DiskFull | `node_filesystem_*` | above 85 % for 15 min |
| HostGone, TargetDown | `up` | host sent within the last 24 h, but not now; exporter down for 15 min |
| NetbirdGroupSyncStale | `nixlab_netbird_group_sync_last_success_seconds` | no clean run for 1 h |
| SyncCredentialExpiring | `nixlab_netbird_group_sync_credential_expiry_seconds` | the group sync's token or key expires in less than 30 days |
| PersonNotManaged | `nixlab_netbird_group_sync_unmanaged_person` | Pocket ID user in `homelab`/`homelab_admins` who is not in `people.tf`, for 1 h |
| RemoteUplinkDown, RemoteSiteUnreachable | `nixlab_remote_uplink_connected` | one uplink of the remote site disconnected for 30 min; none for 10 min |
| LinkSpeedDropped | `node_network_speed_bytes` | an Ethernet link negotiates less than within the last 7 days, for 30 min |
| VersionCheckCriticalUpdate | journal: the "critical update" lines of the version check on zorlock (`hosts/zorlock/version-check.nix`) | a core service (`criticality: core` in `inventory.json`) has an upstream release no report has covered yet; held back until 07:00, stays up for 12 h; the assessment is in that night's `claude.md` (`just version-check-fetch`) |
| Watchdog | `vector(1)` | always, as heartbeat |

**Link speed:** LinkSpeedDropped compares a link with its own past, not with `speed` in `inventory.json`: that is what one end can do, a link gets the slower of both ends (tummi's 2.5G port behind the Beryl's 1G). After a deliberate move to a slower port, silence it; it resolves once the faster week has passed. Wi-Fi and unplugged ports report no speed. Only ports with a `speed` in the inventory count: veths, taps and bridges report made-up speeds, and a bridge follows its ports. Negotiated and inventory capability side by side: table "Links: negotiated vs. capability" in the Hosts Overview, fed by `nixlab_inventory_link_speed_bytes` (vmalert group `nixlab-inventory`, one constant series per interface with a `speed`).

**Why the journal:** the next switch clears a unit's failed state. `systemctl --failed` and any single query show nothing afterwards. The crash loops of paperless-secret-key (October 2026, ~33 000 failed starts) and grist-core (~22 000 a day) never showed up as "failed", but every start left systemd's message in the journal.

**Quiet:** between 04:00 and 06:00 (nightly upgrade and reboot window) everything but the Watchdog is muted. Whatever still fires at 06:00 is sent then. Hence a 3 h window for failures between 04:00 and 06:00, 30 min otherwise, so that a fixed unit clears its notification soon. Grouped by alert and host, repeated every 12 h. HostGone suppresses the other alerts of the same host.

**Dead man's switch:** the Watchdog reaches HA every 5 min and restarts the timer `timer.nixlab_alerting_heartbeat` (20 min) there. If it runs out, the HA automation "nixlab Alerting stumm" reports that grammi, vmalert, Alertmanager or the path to HA is down. Without internet at home nothing arrives. Alertmanager keeps retrying, and an alert that still fires then arrives afterwards.

**In HA:** automation "nixlab Alertmanager" (webhook, one run per group; tag `nixlab-<alert>-<host>`, so that the resolve removes the push and the web UI notification again), "nixlab Alerting stumm" and the timer. The push goes through the legacy service `notify.mobile_app_…`, because `notify.send_message` takes no `data.tag`. The webhook ID is the only secret: `just alerting-webhook-key` puts a new one on the clipboard (for the automation's trigger) and the URL into `hosts/grammi/alerting.yaml`. Deploy grammi afterwards.

**Testing:** send a synthetic alert straight to Alertmanager: `ssh root@grammi.peer.homelab.example amtool --alertmanager.url=http://127.0.0.1:9093 alert add alertname=Test host=test --annotation=summary=Test`. It goes away by itself after 5 min. End to end: `systemd-run --unit=alerting-selftest false` on a host, UnitFailed arrives within about 5 min; the resolve follows once the failure drops out of the 30 min window.

## Web application firewall

On every host CrowdSec reads the nginx and Traefik access logs and bans addresses that stand out (`modules/crowdsec.nix`). That happens after the fact: the one request carrying an exploit has already reached the service. The WAF (`modules/waf.nix`, since 2026-10-25) checks each request before nginx passes it on – with CrowdSec's AppSec component, so the same engine, the same alerts and the same bans.

### Layout

| Part | What it does |
| --- | --- |
| OpenResty | replaces nginx (same NixOS module, Lua built in) |
| Lua bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | in the access phase, sends each request of the listed vhosts to AppSec on `127.0.0.1:7422` and acts on the answer |
| AppSec (part of CrowdSec) | evaluates the rules, raises alerts |
| Firewall bouncer | enforces bans in nftables as before, on every port |

If CrowdSec cannot be reached, nginx lets requests through unchecked (`APPSEC_FAILURE_ACTION=passthrough`) – Pocket ID should not go down with CrowdSec.

### Rules

| Rules | Phase | Effect |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – about 200 rules for known CVEs (PHP-CGI, Spring4Shell, Grafana file read, …) | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Method allowlist per name (`services.waf.allowedMethods`) – on `auth.homelab.example` only GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | no block; more than 5 hits in 30 s ban the IP |

Every in-band match gets a 403. The IP is banned once two *different* in-band rules hit within 60 s (`crowdsecurity/appsec-vpatch`: capacity 1 with `distinct: rule_name`) – the same rule repeated does not fill the bucket. Scanners usually hit several quickly.

The two own rules are the coarse net under the CVE rules: no public service here runs PHP, ASP, JSP or CGI, so any request for one is a scan or an exploit – including for a hole that has no rule of its own yet. The CRS runs out of band only, because it is broad and a single false positive should not lock out a legitimate user.

Exceptions per name: `services.waf.ruleExclusions."<fqdn>" = [ "<rule>" ];`. OpenCloud (aldrin) needs this for `homelab/no-server-side-scripts`, since it keeps ownCloud's `/remote.php`, `/status.php` and `/ocs/v*.php` for the desktop clients.

### Modes

- **`detect`** (default for every new host): in-band matches are answered with "allow", the WAF's ban scenarios run in simulation. Alerts show up in `cscli alerts list` and in the console marked "(simul)"; the WAF blocks nothing.
- **`block`**: in-band matches get a 403 and the IP is banned.

The log-based HTTP scenarios from `modules/crowdsec.nix` do not depend on the mode and ban as before.

### Hosts

| Host | vhosts | Mode |
| --- | --- | --- |
| zummi | `auth.homelab.example` (Pocket ID) | detect (pilot since 2026-10-25) |

Planned: grammi (Traefik plugin, only the dashboard, `/oauth2/` and the public Grafana paths), aldrin (garage-ui, OpenCloud). Never behind the WAF: Garage's S3 API and NetBird's gRPC/relay/API – signed or binary bodies, nothing for the rules to find and plenty to misread.

### Adding a host

1. `services.waf = { enable = true; nginx.vhosts = [ "<vhost>" ]; };` in the host's configuration, `./modules/waf.nix` in the host's module list in `flake.nix`, `waf` in the host's line in `.sops.yaml`.
2. Deploy. The AppSec engine is running then; nginx does not ask it yet (warning at evaluation).
3. `just waf-key <host>` – registers the bouncer `nginx-appsec` with the host's LAPI and writes its key to `hosts/<host>/waf.yaml`. Commit, deploy.
4. Check: `cscli bouncers list` shows `nginx-appsec` with a recent "Last API pull"; `curl -I https://<vhost>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` raises a test alert (`cscli alerts list`).
5. After a week or two without false positives: `mode = "block";`.

Sources: the nginx wiring follows CrowdSec's [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) from cs-nginx-bouncer v1.2.3; the Lua library is CrowdSec's [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633).

## macOS hosts

Two machines in this repo run macOS with nix-darwin instead of NixOS: **zorlock**, the Mac mini serving Ollama, and **gusto**, the MacBook that is the admin workstation. Both are `darwinConfigurations` in the same flake and use the same darwin-tested nixpkgs (`nixpkgs-darwin`). Apart from that they are opposites – one is a server nobody sits at, the other a laptop that is only ever used by a person – and several things are therefore solved differently on purpose. This page explains what the two share, where they differ, and why.

| | zorlock | gusto |
| --- | --- | --- |
| Role | LLM server (Ollama for paperless-gpt) | Admin workstation: deploys, secrets, Tofu, docs |
| Configuration | `hosts/zorlock/` | `hosts/gusto/` (system) + `home.nix`, `ssh.nix` (home-manager) |
| Built and switched | on zorlock, from `/etc/nixos` (`just mac-switch zorlock`) | on gusto, from the working copy (`just mac-switch`) |
| Homebrew | off | on – the apps are casks |
| Software list | in `configuration.nix` | `hosts/gusto/apps.json` – `apps`, `apps-rm` |
| home-manager | no | yes, for admin's dotfiles |
| NetBird client | nix-darwin `services.netbird`, client from `nixpkgs-netbird` | Homebrew cask `netbird-ui` from NetBird's tap |
| NetBird login | setup key from sops, unattended | SSO (Pocket ID) in the app |
| SSH into it | yes, as admin, keys only | no – Remote Login stays off |
| sops secrets | yes (deploy key, deSEC token, NetBird key, Wi-Fi) | none |
| Monitoring, logs | vmagent, Vector → grammi | none – not in the topology |
| Availability | always on (`criticality: service`) | intermittent (`kind: laptop`) |

None of `modules/*.nix` applies to either Mac – those modules are written for NixOS (systemd, ifstate, nginx). What does carry over is restated in each host's `configuration.nix` in nix-darwin's terms. The one module the two share is `modules/darwin/homebrew.nix`.

### Homebrew: one policy for both Macs

Some macOS software exists only as a Homebrew cask, or should come signed by its vendor: 1Password, Vivaldi, Arq, Ghostty, the NetBird app. `modules/darwin/homebrew.nix` is imported by every `darwinConfiguration` and sets one policy (decided on 2026-10-21). It only takes effect where a host sets `homebrew.enable = true` – today that is gusto; on zorlock the module changes nothing, its system closure is identical with and without it.

**Homebrew and its taps are pinned in `flake.lock`.** Homebrew itself is not installed with the `curl | bash` script but by the `nix-homebrew` input. `homebrew-core`, `homebrew-cask` and every third-party tap are flake inputs (`flake = false`), with `mutableTaps = false`. There is no git checkout for `brew update` to move: which version of a cask a switch installs depends on `flake.lock` alone – the same logic as for nixpkgs. A host adds a tap with one line,

```nix
nix-homebrew.taps."netbirdio/homebrew-tap" = inputs.netbirdio-tap;
```

and `homebrew.taps` (the list nix-darwin writes into the Brewfile) is derived from that set automatically.

**Homebrew's own version is pinned by tag.** nix-homebrew brings a Homebrew pin of its own (7.0.4 as of 2026-10-28), which lags behind the casks: since [Homebrew/brew#24369](https://github.com/Homebrew/brew/pull/24369) (2026-10-27) homebrew-cask writes `zap :not_required`, which only Homebrew 7.0.11 and later understand ([Homebrew/brew#24315](https://github.com/Homebrew/brew/pull/24315)) – with 7.0.4 `brew bundle` stopped at `android-platform-tools`. So `flake.nix` has its own input `brew-src` on a release tag and points nix-homebrew at it (`nix-homebrew.inputs.brew-src.follows`); `modules/darwin/homebrew.nix` names the package after that tag, so the switch diff shows the real version (`brew --version` cannot tell: it says `>=4.3.0 (shallow or no git repository)` with any pin). `just mac-upgrade` does not move a tag – updating Homebrew is an edit of that line. Once nix-homebrew pins 7.0.11 or later itself, the input and the `follows` go away.

**A switch does what the configuration says – and nothing else.**

- `onActivation.autoUpdate = false`: no `brew update` during a switch.
- `onActivation.upgrade = false`: no `brew upgrade` during a switch either; an installed cask stays at its version until it is upgraded on purpose.
- `onActivation.cleanup = "zap"`: whatever is installed but not declared is removed, casks including their application data (`brew uninstall --zap`). Deleting a cask from the configuration (`apps.json`) therefore really uninstalls the app with its settings. This applies to Mac App Store apps as well (Homebrew used to leave them alone). `just mac-diff` shows this before it happens, and `just mac-switch` stops before it: if the switch would remove anything, it lists it and asks `[y/N]`; without a terminal it aborts. `MAC_SWITCH_ALLOW_REMOVALS=1 just mac-switch` goes ahead without asking. Usually the fix is to declare what is missing in `apps.json` (decided on 2026-10-23, after a switch would have removed three App Store apps installed by hand).
- `global.autoUpdate = false` and `global.brewfile = true`: the same for `brew` typed by hand, and `HOMEBREW_BUNDLE_FILE` points at the generated Brewfile, so a plain `brew bundle check` compares against the configuration.

Apps with their own updater, and Mac App Store apps, keep updating themselves; the policy only concerns what Homebrew does.

**No `brew shellenv`.** Neither nix-darwin's nor nix-homebrew's shell integration is used – both would run `brew shellenv` in every new shell and put Homebrew *in front of* Nix in `PATH`. Instead `/opt/homebrew/bin` and `sbin` are added to the system `PATH` directly, after the Nix profiles and before macOS' own directories:

```text
~/.nix-profile/bin : /etc/profiles/per-user/$USER/bin : /run/current-system/sw/bin : /nix/var/nix/profiles/default/bin : /opt/homebrew/bin : /opt/homebrew/sbin : /usr/local/bin : /usr/bin : …
```

A tool from Nix always wins over the same tool from Homebrew, Homebrew wins over Apple's stubs, and opening a shell starts no `brew` at all.

#### The mac-* recipes

| Recipe | What it does |
| --- | --- |
| `just mac-diff [host]` | Builds the configuration and shows what a switch would change: the Nix closure (`nvd diff`), the casks and formulae that would be **removed** (`brew bundle cleanup --zap` without `--force`) and those that would be **installed**. Changes nothing. |
| `just mac-switch [host]` | Builds, stops if Homebrew would remove anything (see above), switches, and ends with a compact summary: Nix packages added/removed/updated (nvd) and Homebrew `- removed` / `+ new`. |
| `just mac-upgrade` | Updates only the Homebrew pins (`nix-homebrew` and every input from a `github:<owner>/homebrew-<name>` repository – `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap`, found in `flake.lock`), switches, runs `brew upgrade` and prints `old -> new` per upgraded item, plus the NetBird client version on gusto next to the mesh's pin. The result is a `flake.lock` change to commit. |

The host defaults to `gusto`, which is built from the working copy (uncommitted changes included – but nix only sees files git knows, so `git add` new files first). `zorlock` is reached over SSH: `git pull` in `/etc/nixos`, then the same script under sudo. `deploy-zorlock` and `check-zorlock` are now short forms of `mac-switch zorlock` and `mac-diff zorlock`. The work itself is done by `modules/darwin/rebuild.sh` on the Mac.

`mac-upgrade` exists only for gusto: it changes `flake.lock`, which is committed on the workstation; zorlock has no Homebrew.

#### Software as data: apps.json

What a Mac runs – casks, Homebrew formulae, Mac App Store apps and nixpkgs packages – is not written into its `configuration.nix` but listed in `hosts/<host>/apps.json` (decided 2026-10-22; gusto today, zorlock does not opt in). `modules/darwin/apps.nix` turns the file into `homebrew.casks`, `homebrew.brews`, `homebrew.masApps`, `environment.systemPackages`, the user's `home.packages` and `fonts.packages`. Each entry is keyed by its name in its source and carries a `note` (why it is there) and the day it was `added`; nixpkgs entries also a `scope` (`system`, `user`, `font`). Taps stay Nix, in the host's configuration – they are flake inputs; `apps` can add one (below).

The file is data on purpose: a tool can add and remove entries without parsing Nix, and the configuration checks it on every evaluation – unknown sources or fields, a nixpkgs attribute that does not exist, an entry from a tap the host does not pin – and lists every problem at once (`checks.darwin-apps`). `modules/darwin/apps.schema.json` gives the editor completion and hover help.

`apps` is that tool (`pkgs/nixlab-apps`): one round of searching, adding and removing, then one switch and one commit. It searches nixpkgs, Homebrew and the Mac App Store online, groups the hits that are the same software and marks the recommended source – for a GUI app cask before App Store before nixpkgs (signed, in `/Applications`, updates itself), for a command line tool nixpkgs before a formula. The pick is then checked against the **pin**, because a switch installs what `flake.lock` says, not what the search showed: a nixpkgs package must evaluate in `nixpkgs-darwin` (available, not unfree), a cask or formula must be in the pinned tap. A missing cask or formula can bump `homebrew-cask` / `homebrew-core` in a commit of its own – harmless, `upgrade = false` leaves installed casks alone. `nixpkgs-darwin` is never bumped there: it is the whole system of both Macs. The pinned third-party taps are searched too, offline from their pin; a cask from a tap that is not pinned yet is found by its full name (`apps stablyai/orca/orca`), and picking it pins the tap – flake input, `nix-homebrew.taps` line, `nix flake lock`, a commit of its own – after showing who publishes it and asking. That question is the trust decision: every pinned tap is trusted (decided 2026-10-23, with Orca as the first such tap). Steps: [Software on the Macs](#software-on-the-macs).

### NetBird on the two Macs

Both Macs are peers in the NetBird mesh, but they get their client in two different ways. This is deliberate.

#### zorlock: nix-darwin module, client from the mesh pin

`hosts/zorlock/netbird.nix` turns on nix-darwin's `services.netbird`. That module runs only the daemon – `netbird service run` as a launchd daemon, as root, state in `/var/lib/netbird` – and leaves login and settings to the user. The rest is done by a second launchd job, `netbird-login`, the same pattern as on the Linux hosts:

- The **client binary** comes from the `nixpkgs-netbird` input, the pin the NetBird server on grammi and every NixOS client use. The whole mesh moves together with `nix flake update nixpkgs-netbird` – server first, then the clients.
- **Login** is unattended: `netbird-login` registers once with a single-use setup key from `hosts/zorlock/netbird.yaml` (sops, `just netbird-key zorlock`). After that the key is spent and the peer's identity lives in `/var/lib/netbird/config.json`.
- **Rosenpass** is turned off by the same job (off mesh-wide since 2026-10-24, until 2026-10-31, see below), the client's local Prometheus endpoint (`127.0.0.1:9191`, scraped by vmagent) on – nix-darwin's module has no `config.d` like the NixOS one.
- After a reboot zorlock joins the mesh only once FileVault has been unlocked (over SSH from the home LAN), because the daemon lives on the data volume.

That is what a server needs: no GUI session (zorlock should stay logged out, Ollama counts free RAM), coming back by itself, the same client version as the rest of the mesh, and metrics.

#### gusto: the official app as Homebrew cask

gusto installs `netbirdio/homebrew-tap/netbird-ui`, the cask from NetBird's own tap, pinned as the flake input `netbirdio-tap` (decided on 2026-10-21). The cask is the signed menu-bar app; it depends on the formula `netbird` from the same tap (the CLI and daemon), and its installer registers the daemon as `/Library/LaunchDaemons/netbird.plist`. That is the same software the official `.pkg` installer puts on a Mac, only installed and removed through the configuration. The formula is also listed on its own (`homebrew.brews`), so `cleanup = "zap"` can never treat the daemon as an orphan and remove it from under the app.

- **Login** is interactive: in the app, with SSO through Pocket ID – the peer then belongs to the admin's user and its groups, the way a person's device should. There is no setup key and no sops file for gusto.
- **Rosenpass** is set once in the app's settings (Quantum-Resistance); the daemon keeps it in its own config. Since 2026-10-21 it is **off** on the workstation – a test against tunnels that stayed "Connected" without a WireGuard handshake after the Rosenpass key expired (upstream #3107, #3121); gusto starts the same way, off. The dead tunnels came back anyway, between two peers that both ran Rosenpass (ursalia↔zorlock, 2026-10-23: key expired without renewal, the two sides ended up with different pre-shared keys, no handshake any more – and Rosenpass itself runs through that tunnel). So since 2026-10-24 Rosenpass is **off mesh-wide** for a week, until 2026-10-31; the apps (iPhone, Apple TVs, Home Assistant) by hand. Then it is decided: no more dead tunnels – it stays off until upstream fixes the re-keying; dead tunnels anyway – Rosenpass was not the cause and comes back, permissive.
- **Version**: whatever the pinned tap holds. It changes only with `just mac-upgrade`, which prints gusto's client version next to `nixpkgs-netbird`'s so the two do not drift far apart. The usual rule still applies: the server (grammi) is updated first, clients follow.
- **Updates from elsewhere**: the app's own update notice and NetBird's dashboard-driven auto-update must not move the version behind the configuration's back; this is checked on the first switch and switched off if the app offers it.
- No metrics endpoint and no log shipping – gusto is not monitored.

#### Why not the same on both?

| Question | Answer |
| --- | --- |
| Why does gusto not use the nix-darwin module like zorlock? | That module has no menu-bar app; everything would be CLI. On a laptop that changes networks all the time, the app is how one sees at a glance whether the mesh is up, switches profiles and signs in again. Login on gusto is SSO anyway, which needs a browser and a person – the unattended setup-key job that makes zorlock's variant worthwhile does not apply. |
| Why does zorlock not use the cask? | A server must come back on its own after a reboot, without anybody signing in, with the same client version as the mesh and with metrics. The cask's app needs a GUI session, and its version follows the tap, not the mesh pin. |
| Why not `netbird-ui` from nixpkgs on gusto? | nixpkgs packages the UI for Linux first; whether it builds and runs properly on macOS (signing, the menu-bar integration) is not verified, and it would not be the signed binary NetBird ships. |
| Mac App Store? | NetBird offers no Mac App Store version (only iOS). |
| What is the price? | gusto's client version is pinned separately from the mesh's (`netbirdio-tap` instead of `nixpkgs-netbird`). `just mac-upgrade` makes the gap visible; it is closed by hand. |

#### The peer in Tofu

`terraform/netbird/subraum.tf` looks up the admin workstation by peer name (`data "netbird_peer"`) for the group `admin-workstations` – the group that may reach the Subraum devices and the docs site. Changing the workstation (old MacBook → gusto) is done with both peers in the group for a short while: add a second data source `gusto`, `just netbird-apply`, deploy aldrin and ursalia (docs site allow-list), test, and only then remove the old peer.

### gusto in detail

The reasons behind gusto's setup; the complete list of what is on it, every setting and the day-to-day tasks are on [gusto – the admin workstation](#gusto--the-admin-workstation).

#### Starting from scratch

gusto was set up deliberately bare (2026-10-21): no app list taken over from the old installation, only a small base. Everything else is added the moment it is needed – `apps` (into `hosts/gusto/apps.json`, switch, commit), and, if there is data, it comes back from the backup.

| Where | What |
| --- | --- |
| Casks | 1Password + `1password-cli`, Vivaldi, Arq, Claude, Ghostty, NetBird |
| System (`environment.systemPackages`) | git, gh, just, jq, neovim (`EDITOR`), curl, wget, rsync |
| admin (home-manager) | zsh, atuin, fzf, zoxide, direnv + nix-direnv, bat, eza, ripgrep, fd, tree, lazygit, btop, yazi, tmux, nvd, nix-output-monitor, uv, typst |
| Font | Maple Mono NF (Nerd Font) for Ghostty and the TUIs |
| Repo tools | sops, age, ssh-to-age, opentofu, nvd – from the flake's devShell; dnscontrol from a separate one for the DNSControl repo, see below |

`op` comes as a cask and not from nixpkgs because the CLI unlocks through the 1Password app with Touch ID, which only works with the vendor's signed binary.

#### XDG and home-manager

Project rule: configuration lives under `~/.config/<tool>` wherever the tool supports it – zsh (`ZDOTDIR=~/.config/zsh`), git (`~/.config/git/config`), Ghostty, tmux, direnv. A tool without XDG support keeps its real file in the classic place and gets a link `~/.config/<tool>` pointing at it, e.g. `~/.config/ssh → ~/.ssh`. Data goes to `~/.local/share`, state (zsh history) to `~/.local/state`.

`PATH` gets exactly one personal directory, `~/.local/bin`: `GOBIN` points there, `CARGO_INSTALL_ROOT` is `~/.local`, and `uv tool install` uses it by default. `GOPATH` and `CARGO_HOME` live under `~/.local/share`. No `~/go/bin`, `~/.cargo/bin` or pnpm path any more.

git: name `admin`, default address `mail@admin.org`; for everything below `~/Projects/homelab/` an `includeIf gitdir:` switches to `admin@homelab.example`.

#### SSH: 1Password only

The private keys exist only in 1Password; its agent offers them. Two links make the agent reachable under a path without spaces: `~/.1password/agent.sock` (home-manager) and `SSH_AUTH_SOCK` – in every shell (home-manager) and for GUI apps through `launchd.user.envVariables`.

`~/.ssh/config` is generated by home-manager (`hosts/gusto/ssh.nix`):

- **Global lines first**, before any `Host` block (`extraOptionOverrides`): `IdentityAgent`, `IdentitiesOnly`, `Compression`, `SendEnv`. The first value ssh finds wins, so no later block – and no included file – can point the agent elsewhere. Exactly that had broken the old config: an included file's `Host *` sent IdentityAgent to another user's agent.
- **One key per target**: `IdentityFile` names the *public* half (`hosts/gusto/ssh/*.pub`, linked to `~/.ssh/pub/`). That tells the agent which key to offer; the private half never touches the disk.
- **Lab hosts are generated** from `inventory.json` – every managed host except gusto: `<host>` / `<host>.peer.homelab.example` over the mesh as root (zorlock as admin); `<host>.example-tailnet.ts.net` while Tailscale still runs; and for hosts with a public address (aldrin, grammi, zummi) `<host>.homelab.example` as admin – root is refused on public addresses (`modules/ssh.nix`), so this fallback works when the mesh is down. The alternative names use `HostKeyAlias <host>.peer.homelab.example`, so all of them are checked against the one host key from the inventory.
- **Host keys** come from the inventory (`/etc/ssh/ssh_known_hosts`, like on every host); GitHub's key is pinned in `configuration.nix`. `just known-hosts` is not needed on gusto.
- By hand: `zorlock-lan` (FileVault unlock), `gruffi`, `arkkvm`/`arkkvm01`, the Subraum router as jump host (with its port forwards), vogon, amnesia, unifi, git.c3pb.de, edi, a block for old switches that only *adds* legacy algorithms (`+…`), and GitHub (with a 60 s ControlMaster).

#### devShell and direnv

The repo's own tools are not installed globally. `flake.nix` has `devShells.aarch64-darwin.default` with sops, age, ssh-to-age, opentofu and nvd from the flake's pins; `.envrc` (`use flake`) makes direnv load it whenever a shell enters the checkout – once per checkout `direnv allow`. nix-direnv caches the shell and protects it from garbage collection. The docs tools are not in it: `just docs` and `just docs-serve` fetch their own through `nix shell`.

sops on gusto takes the workstation's age key straight from 1Password: home-manager sets `SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"'`, `op` unlocks with Touch ID through the app – no `op signin`, no key file.

#### DNSControl

The public DNS records live in the repo next door, `~/Projects/homelab/DNSControl` (local, no remote; linked in here as the `dnsconfig.js` symlink). dnscontrol comes from a second, slim devShell `devShells.aarch64-darwin.dns` that holds nothing but dnscontrol and sops; the `.envrc` there loads it with `use flake ../nixlab#dns`. DNSControl gets no `flake.nix` of its own – that keeps dnscontrol on this flake's pins, with no second `flake.lock`.

The providers' credentials (deSEC, OVH, hosting.de) live sops-encrypted in `creds.sops.json` in the repo, never in plaintext on disk. The `.sops.yaml` there names the same recipients as the Tofu modules: the workstation key and the `admin` recovery key – so they stay readable without 1Password. A wrapper does the rest:

- `bin/dnscontrol` sits in front of the real binary through the `.envrc` (`PATH_add bin`), which stores the real one's path in `DNSCONTROL_BIN`.
- For the commands that talk to providers – `preview`, `push`, `ppreview`, `ppush`, `check-creds`, `get-zones`, `get-certs` – it adds `--creds '!sops -d …/creds.sops.json --output-type json'`, unless `--creds` is on the line already. Everything else it passes through unchanged. `--output-type` comes last on purpose: dnscontrol takes a `--creds` value ending in `.json` for a file name, even after the `!`.
- sops decrypts with the workstation key (`SOPS_AGE_KEY_CMD`, Touch ID), dnscontrol reads the JSON from its output. None of it touches the disk.

The commands stay `dnscontrol preview` and `dnscontrol push`. Changing a token means `sops creds.sops.json` and a commit. The repo's `.gitignore` blocks a `creds.json`, so plaintext never gets in again. An executable `creds.json` instead of the wrapper does not work: dnscontrol does not check the executable bit for names ending in `.json`.

## Add a new host

A host appears in several places in the repo, because NixOS and OpenTofu deliberately share no host list (see [What is deliberately not wired](#what-is-deliberately-not-wired)). This guide walks through them in order.

### 1. Provide the machine

Rented VMs are created by hand at the provider; bare metal and the Subraum VM follow the installation guides in `docs/install-*.md`. The result is a NixOS install with an SSH host key – the host's age key is derived from it next.

### 2. Create the configuration

- Create `hosts/<host>/configuration.nix` and `hardware-configuration.nix`.
- Add it to `nixosConfigurations` in `flake.nix` with an explicit module list. Whatever is left out on purpose gets a comment saying why.

### 3. Add it wherever hosts are listed

| File | Entry |
| --- | --- |
| `flake.nix` | `nixosConfigurations.<host>` |
| `inventory.json` | `hosts.<host>` with `"managed": true` – kind, site, owner, unlock (see [Inventory](#inventory)) |
| `justfile` | `hosts := "…"` (pull hosts only, for `ship-all`) |
| `terraform/netbird/main.tf` | `local.hosts`: host → setup key group (`servers` or similar) |
| `terraform/desec-tokens/main.tf` | `local.hosts`: allowed source addresses, `acme_names` |
| `terraform/github/main.tf` | `local.hosts`: deploy key read-only or with write access |

### 4. sops recipient

Derive the age key from the new host's SSH host key (`ssh-to-age` on `/etc/ssh/ssh_host_ed25519_key.pub`) and add it to `.sops.yaml`: an anchor under `keys` and a `creation_rule` for `hosts/<host>/(secrets|netbird|desec|github)\.yaml$` with the host and `admin` as recipients. The public host key itself goes into `inventory.json` (`sshHostKeys`, or later via `just inventory-collect`); `checks.inventory-sops` compares the two.

### 5. Mint keys and tokens

| Recipe | Result | Note |
| --- | --- | --- |
| `just netbird-key <host>` | `hosts/<host>/netbird.yaml` | one-off setup key, **valid for 24 h** – deploy right after |
| `just desec-key <host>` | `hosts/<host>/desec.yaml` | only for hosts with their own certificates |
| `just github-key <host>` | `hosts/<host>/github.yaml` + `github-deploy.pub` | pull hosts only |

Recipes that need sops take the workstation key from 1Password (on gusto set up by home-manager, see [just recipes](#just-recipes)).

### 6. Deploy and check

- First deploy within 24 h of `netbird-key`. The host registers itself in the mesh at startup; Tofu finds it by name through `data "netbird_peer"`.
- Run `just topology` and commit the result – otherwise `nix flake check` fails.
- `just inventory-collect` (host key, interfaces), set `network`/`ipv4` by hand, then `just inventory-test`; `just mac-switch` on gusto (its known_hosts comes from the inventory) – a new managed host also gets its SSH block there automatically, with `hosts/gusto/ssh/<host>.homelab.example.pub`.
- Add app secrets once the host is running: [Add secrets](#add-secrets).
- Update the docs: [Hosts & roles](#hosts--roles), [Services](#services-2).

## Publish a new service

Services are named by function (`rezepte`, not `mealie`); new web services on grammi use PostgreSQL. First decide how the service should be reachable – that decides which files change.

| Reachability | For | Examples |
| --- | --- | --- |
| Mesh only | admin UIs, services for your own devices | `s3-admin`, `llm` |
| Public behind the reverse proxy with SSO | web apps that should work on the road without the NetBird app | `rezepte`, `grist`, `metrics`, `dokumente` |
| Directly public | services with their own login, for machines or everyone | `auth`, `s3.aldrin` |

### Mesh only

1. One line under `local.mesh_services` in `terraform/netbird/mesh-services.tf`: name → host(s). This creates a NetBird DNS zone of its own with A record(s) on the mesh address(es); public DNS does not know the name.
2. `just netbird-apply` – since NetBird 0.81 new zones reach the clients without a restart.
3. On the host an nginx vhost with `enableACME`, `acmeRoot = null` (DNS-01 via deSEC) and `allow 192.0.2.0/24; deny all;`.
4. If the service runs on ursalia or zorlock: add the name to the host's `acme_names` in `terraform/desec-tokens/main.tf` and run `just desec-apply` – their tokens may only write exactly those TXT records.
5. Deploy the host, `just topology` (new vhost).

### Public behind the reverse proxy

For services on grammi:

1. An entry in `hosts/grammi/proxy-services.json`: name → app, port, Pocket ID groups, optionally `start` (where `/` redirects to). Tofu (`reverse-proxy.tf`), Traefik and `topology.nix` read the same file; the proxy reaches every app through Traefik `:8090`.
2. The service listens on `127.0.0.1` only – Traefik connects over loopback, nothing more is needed ([apps on grammi](#apps-on-grammi-only-through-traefik-8090)).
3. Push a CNAME `<name>` → `proxy.homelab.example` in DNSControl – a few minutes before the apply, otherwise the resolver caches NXDOMAIN.
4. Deploy grammi first, then `just netbird-apply`. At the end it runs `just netbird-proxy-certs`: it requests every new name once from outside so the proxy fetches its certificate, then restarts `netbird-proxy` once – otherwise the dashboard hangs at "Issuing certificate…" (NetBird discussion #7118).

Services on other hosts get a resource of their own in `terraform/netbird/reverse-proxy.tf` with the host as peer target (examples: `dokumente` on ursalia – SSO for the app, a PIN for share links only –, `doku` on aldrin). Here too: push the CNAME first, `just netbird-apply` takes care of the certificates.

### Directly public

nginx vhost on the host (ACME via DNS-01), A/AAAA records in DNSControl, CrowdSec reads the nginx logs. Only for services that have a login of their own anyway.

### Afterwards

- Docs: [Services](#services-2), and [Contents of hosts/&lt;host&gt;/](#contents-of-hostshost) if new files appear there.
- Dual stack wherever possible (A and AAAA).
- Maintenance switch and error pages: [maintenance mode](#adding-a-service) – automatic on grammi, one entry in the host elsewhere.

## Maintenance mode

A service can be closed for maintenance without stopping it: whoever opens it gets a page with status 503, the reason and `Retry-After`; the service itself keeps running and stays reachable for tests. The same page appears with 502 or 504 when the service does not answer – during a `switch`, say. Module: `modules/maintenance.nix`.

### How it works

Every HTTP path to a service ends at nginx or Traefik on the host the service runs on – the path through the NetBird reverse proxy too, which only passes requests on. That is where the maintenance switch and the error pages sit; which software it is, is a detail per host.

<figure class="nx-diagram">
<svg viewBox="0 0 680 530" role="img" aria-label="Paths to the services: every HTTP path ends at nginx or Traefik on the target host, where the maintenance switch and the error pages sit" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}</style>
<text class="nx-s" x="62" y="30" text-anchor="middle">Source</text>
<text class="nx-s" x="172" y="30" text-anchor="middle">grammi entry</text>
<text class="nx-s" x="298" y="30" text-anchor="middle">Proxy</text>
<text class="nx-s" x="432" y="30" text-anchor="middle">Front at target</text>
<text class="nx-s" x="584" y="30" text-anchor="middle">Services</text>
<g class="nx-gray"><rect x="20" y="48" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="78" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 73 H368"/><path class="nx-line" d="M362 69 L368 73 L362 77"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="48" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="70" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="87" text-anchor="middle">aldrin, zummi</text></a>
<path class="nx-line" d="M494 73 H506"/><path class="nx-line" d="M500 69 L506 73 L500 77"/>
<g class="nx-gray"><rect x="508" y="48" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="69" text-anchor="middle">s3.aldrin, cloud,</text><text class="nx-s" x="584" y="85" text-anchor="middle">auth</text></g>
<g class="nx-gray"><rect x="20" y="110" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="140" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 135 H116"/><path class="nx-line" d="M110 131 L116 135 L110 139"/>
<g class="nx-gray"><rect x="118" y="110" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="140" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 135 H238"/><path class="nx-line" d="M232 131 L238 135 L232 139"/>
<g class="nx-gray"><rect x="240" y="110" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="140" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 135 H368"/><path class="nx-line" d="M362 131 L368 135 L362 139"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="110" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="132" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="149" text-anchor="middle">ursalia :8092</text></a>
<path class="nx-line" d="M494 135 H506"/><path class="nx-line" d="M500 131 L506 135 L500 139"/>
<g class="nx-gray"><rect x="508" y="110" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="140" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="172" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="202" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 197 H116"/><path class="nx-line" d="M110 193 L116 197 L110 201"/>
<g class="nx-gray"><rect x="118" y="172" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="202" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 197 H238"/><path class="nx-line" d="M232 193 L238 197 L232 201"/>
<g class="nx-gray"><rect x="240" y="172" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="202" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 197 H368"/><path class="nx-line" d="M362 193 L368 197 L362 201"/>
<a data-target="traefik" tabindex="0" role="link" class="nx-teal"><rect x="370" y="172" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="194" text-anchor="middle">Traefik :8090</text><text class="nx-s" x="432" y="211" text-anchor="middle">all grammi apps</text></a>
<path class="nx-line" d="M494 197 H506"/><path class="nx-line" d="M500 193 L506 197 L500 201"/>
<g class="nx-gray"><rect x="508" y="172" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="193" text-anchor="middle">vm, vl, rezepte,</text><text class="nx-s" x="584" y="209" text-anchor="middle">grist, logs, metrics</text></g>
<g class="nx-gray"><rect x="20" y="234" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="264" text-anchor="middle">Mesh</text></g>
<path class="nx-line" d="M104 259 H368"/><path class="nx-line" d="M362 255 L368 259 L362 263"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="234" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="256" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="273" text-anchor="middle">ursalia :443</text></a>
<path class="nx-line" d="M494 259 H506"/><path class="nx-line" d="M500 255 L506 259 L500 263"/>
<g class="nx-gray"><rect x="508" y="234" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="264" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="296" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="326" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 321 H238"/><path class="nx-line" d="M232 317 L238 321 L232 325"/>
<g class="nx-gray"><rect x="240" y="296" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="318" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="335" text-anchor="middle">:8883, TCP only</text></g>
<path class="nx-line" d="M356 321 H368"/><path class="nx-line" d="M362 317 L368 321 L362 325"/>
<g class="nx-gray"><rect x="370" y="296" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="326" text-anchor="middle">none</text></g>
<path class="nx-line" d="M494 321 H506"/><path class="nx-line" d="M500 317 L506 321 L500 325"/>
<g class="nx-gray"><rect x="508" y="296" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="326" text-anchor="middle">mqtt (Home Assistant)</text></g>
<g class="nx-gray"><rect x="20" y="358" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="388" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 383 H116"/><path class="nx-line" d="M110 379 L116 383 L110 387"/>
<g class="nx-gray"><rect x="118" y="358" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="388" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 383 H238"/><path class="nx-line" d="M232 379 L238 383 L232 387"/>
<g class="nx-gray"><rect x="240" y="358" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="380" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="397" text-anchor="middle">target switched</text></g>
<path class="nx-line" d="M356 383 H368" stroke-dasharray="5 4"/><path class="nx-line" d="M362 379 L368 383 L362 387"/>
<a data-target="proxy-maintenance" tabindex="0" role="link" class="nx-teal"><rect x="370" y="358" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="380" text-anchor="middle">Maintenance page</text><text class="nx-s" x="432" y="397" text-anchor="middle">grammi :8090</text></a>
<g class="nx-gray"><rect x="508" y="358" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="379" text-anchor="middle">when the target host</text><text class="nx-s" x="584" y="395" text-anchor="middle">is down entirely</text></g>
<a data-target="switching" tabindex="0" role="link" class="nx-teal"><rect x="20" y="430" width="640" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="453" text-anchor="middle">Shared on every host with a front</text><text class="nx-s" x="340" y="472" text-anchor="middle">Flag in /var/lib/maintenance · page 503/502/504 · bypass cookie</text></a>
<g class="nx-teal"><rect x="20" y="504" width="14" height="14" rx="3" stroke-width="1"/></g><text class="nx-s" x="42" y="515">maintenance check and error pages</text>
<g class="nx-gray"><rect x="340" y="504" width="14" height="14" rx="3" stroke-width="1" stroke-dasharray="3 2"/></g><text class="nx-s" x="362" y="515">dashed: proxy maintenance, only when needed</text>
</svg>
</figure>

- **Flag**: `/var/lib/maintenance/<fqdn>` (or `all` for the whole host). The file's content is the reason on the page. Flags survive a reboot – maintenance stays on until someone ends it.
- **Page**: a small program on every host (`maintenance-responder`, 127.0.0.1:8089 only, started on demand by systemd). It decides between maintenance (503) and failure (502/504) the same way for nginx and Traefik.
- **Bypass**: one cookie for every name under `homelab.example` that keeps the service reachable in the browser despite maintenance.

### Switching on and off

From the workstation; the host is looked up in `inventory.json`:

```bash
just maintenance dokumente on "Paperless upgrade, until about 10 pm"
```

```bash
just maintenance dokumente off
```

```bash
just maintenance-list
```

A name without a dot gets `.homelab.example` appended. A whole host (every name with a maintenance switch there):

```bash
just maintenance all on "Moving to new hardware" aldrin
```

```bash
just maintenance all off "" aldrin
```

On the host itself the same works with `maintenance on|off|status`. Neither nginx nor Traefik needs a reload; nginx checks the flag on every request, Traefik picks the change up after two to four seconds.

Which names have a maintenance switch:

| Host | Names | Front |
| --- | --- | --- |
| aldrin | `s3.aldrin`, `cloud` | nginx |
| zummi | `auth` | nginx |
| ursalia | `dokumente` (443 and the proxy listener 8092) | nginx |
| grammi | every name in `hosts/grammi/proxy-services.json` | Traefik `:8090` |

Side effects: `s3.aldrin` in maintenance means every host's nightly restic backup fails; `auth` in maintenance means nobody can log in anew through Pocket ID. `s3-admin` (garage-ui) only has the error pages: its 443 is open publicly, and the maintenance check would run before its mesh-only `allow`/`deny`.

### Seeing the service anyway

1. Copy the token to the clipboard (it is never shown):

    ```bash
    just maintenance-key
    ```

2. Open `https://<name>/_maintenance/bypass`, e.g. `https://dokumente.homelab.example/_maintenance/bypass`, and paste the token.

The cookie holds for 12 hours for every name under `homelab.example`, including the way back after logging in at Pocket ID. To remove it: `https://<name>/_maintenance/clear`. The bypass is a convenience, not a security boundary – login, the proxy's SSO and mesh-only restrictions still apply. The token is in `hosts/<host>/maintenance.yaml` (sops, the same token on all four hosts); to rotate it: delete all four files, run `just maintenance-token`, commit, deploy the four hosts.

The key is sent through a form, not as `?key=` in the address: addresses end up in the access logs, and those are shipped to VictoriaLogs.

### Testing behind maintenance with ssh -L

For checks without a browser – health check, API, version – a tunnel straight to the service, past nginx and Traefik, is enough:

```bash
ssh -L 8000:127.0.0.1:8000 root@ursalia.peer.homelab.example
```

```bash
curl -sI http://localhost:8000/api/
```

More examples: Grafana `ssh -L 3000:127.0.0.1:3000 root@grammi.peer.homelab.example`, Garage S3 `ssh -L 3900:127.0.0.1:3900 root@aldrin.peer.homelab.example` (then an S3 client against `http://localhost:3900`).

For a test in the browser this rarely works: services that check their own address refuse `localhost`. paperless compares the `Origin` with `PAPERLESS_URL` on login (CSRF), OpenCloud and everything with OIDC send you back to their real address after the login – which is in maintenance. The [bypass](#seeing-the-service-anyway) is what the browser needs.

### When the host is down entirely

When the target host itself is down (reboot, migration), its maintenance page is gone with it and the NetBird proxy shows its own error. For the services outside grammi (`dokumente`, `doku`) the proxy's target can therefore be switched to grammi, where Traefik answers every name it does not serve itself with the maintenance page:

```bash
just proxy-maintenance dokumente on "ursalia is being reinstalled"
```

```bash
just proxy-maintenance dokumente off
```

This writes `terraform/netbird/proxy-maintenance.json`, runs `just netbird-apply` and sets or removes the flag on grammi. Commit `proxy-maintenance.json` and `expected-peers.json` afterwards (while switched over, the host drops out of the proxy's targets). The login (SSO, PIN) stays in front; straight from the mesh the host is of course still unreachable.

### Error pages for 502 and 504

No switch involved: when the service does not answer (502) or too slowly (504), the front shows the same page with "currently unreachable" and the real status code.

#### nginx

nginx replaces only its own errors (`error_page`). The service's own error responses pass unchanged – `proxy_intercept_errors` stays off, so S3 clients get their XML and OIDC clients their JSON.

#### Traefik

Traefik also replaces the service's responses with its `errors` middleware, hence 502 and 504 only, not 503. The maintenance routers are written by `maintenance-traefik-sync` from the flags into `/run/traefik-dynamic/`, which Traefik watches. The control plane `mesh.homelab.example` never gets a maintenance switch.

### Adding a service

- **nginx**: add the vhost (attribute name) to the host's `services.maintenance.nginx.vhosts`, or to `nginx.errorPagesOnly` for the error pages only. Not for vhosts with `allow`/`deny` whose port refused clients can reach too – the maintenance check runs before `allow`/`deny`.
- **grammi**: every entry in `hosts/grammi/proxy-services.json` is in automatically.
- **New host**: import `./modules/maintenance.nix` in `flake.nix`, set `services.maintenance.enable = true`, add the host to `.sops.yaml` (`maintenance`) and to `just maintenance-token`, and create the token anew.

## Add secrets

App passwords, OIDC clients and the like live in `hosts/<host>/secrets.yaml`, encrypted for the host and the recovery key `admin`. The MacBook cannot decrypt these files – that is why they are edited on the host (background: [Secrets, network & access](#secrets-network--access)).

### Steps

1. `just sync <host>` – otherwise the host has an outdated `secrets.yaml`, and `pull-secrets` brings it back into the repo.
2. `just secrets <host>` – opens sops on the host (with its host key, no 1Password sign-in) and afterwards fetches the result into the repo via `pull-secrets`.
3. Always quote values: `key: "value"`, single quotes if the value contains `"` or `\`. An unquoted value may be read by YAML as a number or bool; sops-nix then aborts `setupSecrets` and **no** secret of that generation gets installed.
4. Add the NixOS side (`sops.secrets."<name>"`) in the host module, commit, deploy: `just ship <host> "<message>"`.

### What is not edited by hand

| File | Written by |
| --- | --- |
| `hosts/<host>/netbird.yaml` | `just netbird-key <host>` |
| `hosts/<host>/desec.yaml` | `just desec-key <host>` |
| `hosts/<host>/github.yaml` | `just github-key <host>` |
| `terraform/*/secrets.yaml` | sops on the MacBook with the workstation key from 1Password |

Everything that needs sops on the MacBook runs with the sign-in in front – see [just recipes](#just-recipes).

## Rotate keys

What can be renewed how, and what to do afterwards. The recipes replace the old key at once – so commit and deploy right after.

| Key | Recipe | Afterwards | When |
| --- | --- | --- | --- |
| A host's NetBird setup key | `just netbird-key <host>` | deploy within 24 h | after a reinstall or lost client state |
| A host's deSEC token | `just desec-key <host>` | deploy at once, then `just desec-verify` | on suspicion, otherwise never |
| A host's GitHub deploy key | `just github-key <host>` | commit + deploy | on suspicion |
| Tofu token for NetBird (service user `terraform`) | `just netbird-renew-token` | – | yearly |
| App secrets | `just secrets <host>` (see [Add secrets](#add-secrets)) | deploy | on suspicion |

### SSH host key (= sops recipient)

A host's age key is derived from its SSH host key. A new host key therefore also means:

1. Derive the new age key with `ssh-to-age` and replace it in `.sops.yaml`.
2. Re-encrypt the host's files with `sops updatekeys` – this needs a key that can still read them (the old host key or `admin`).
3. Put the new public key into `inventory.json`: `just inventory-collect --force <host>`. `nix flake check` (`checks.inventory-sops`) fails until the inventory and `.sops.yaml` agree.
4. Commit and deploy before the old key is gone – every host's known_hosts comes from the inventory. On gusto: `just mac-switch`.

### After a rotation

- Delete old keys at the other end (GitHub, deSEC and NetBird are handled by the recipe through Tofu).
- `just docs` if names or procedures changed.

## Software on the Macs

Everything installed on gusto – casks, Homebrew formulae, Mac App Store apps, nixpkgs packages and fonts – is listed in `hosts/gusto/apps.json`. Three commands manage it – `apps`, `apps-list` and `apps-rm`, installed on gusto and usable from any directory; inside the checkout `just apps`, `just apps-list` and `just apps-rm` do the same. The background (why a data file, why the pin check) is in [macOS hosts](#software-as-data-appsjson).

### One round: add and remove

```bash
apps obsidian
```

The start term is optional (`apps` alone starts with an empty search). One round is any number of changes and ends with one switch and one commit:

```
╭──────────── search: obsidian  filter: export ─╮   ← both fields
│ filter> export                                 │   ← the active one
╰────────────────────────────────────────────────╯
  this round:  + ripgrep (nixpkgs, user)   − shottr (cask) ZAP
  enter: add / remove   tab: search ⇄ filter   ctrl-s: done   esc: cancel
  nixpkgs ✓ 12  Homebrew ✓ 2  App Store ✓ 10
   nixpkgs  obsidian-export   25.3.0   CLI  Rust library and CLI to export …
…
  [ Done · ctrl-s ]  [ Cancel · esc ]     shift-tab: buttons
```

- **Two fields, `tab` switches between them.** `search>` searches online; `filter>` (optional) narrows the results of that search in fzf, fuzzy, without searching again (`'word` for an exact match). A new search term empties the filter – it was for the old results. The border above shows both.
- **The search** runs as you type (from 2 characters, after a short pause) against nixpkgs (search.nixos.org, release of `nixpkgs-darwin`), Homebrew (formulae.brew.sh), the Mac App Store and the third-party taps gusto pins (offline, from their pin). A fully qualified term – `owner/tap/name`, as in `brew install --cask owner/tap/name` – also looks that one cask or formula up on GitHub when its tap is not pinned yet (see [A cask from a third-party tap](#a-cask-from-a-third-party-tap)). If search.nixos.org is down, `nix search` against the pin takes over – slower, but always there. The line above the list says what each source returned.
- **★** marks the recommended source where the same software exists more than once: for a GUI app cask before App Store before nixpkgs, for a command line tool nixpkgs before a Homebrew formula. The preview below shows description, version, licence, homepage – and for a declared entry its note.
- **Enter on a new hit adds it.** The list closes for the questions:
    1. The pin check –

        | Source | Check | If it fails |
        | --- | --- | --- |
        | nixpkgs | evaluates in the pinned `nixpkgs-darwin`, available on aarch64-darwin, not unfree | not added – it comes with the next system update; unfree: take the cask |
        | cask / formula | the `.rb` file is in the pinned tap | offers to bump `homebrew-cask` / `homebrew-core` (own commit) |
        | cask / formula from a tap that is not pinned | – (comes before the check) | shows who publishes the tap and what it downloads, then offers to pin **and trust** it (own commit) |
        | App Store | – (no pin, the store installs the current version) | – |

    2. for nixpkgs the scope: `user` (admin's `home.packages`, the default), `system` (root and every shell) or `font`;
    3. a note – why it is there, in English, like a comment in the configuration; Enter leaves it out.

    Then the list is back with the same search and filter, in the field you were in, ready for the next one. Ctrl-C during the questions skips that hit.
- **Enter on a declared entry (✓) marks it for removal** (red, struck through, `−`). Nothing is deleted yet.
- **Enter on something added or marked this round undoes it.**
- The header line lists the round: `+` green, `−` red, **ZAP** for a cask – removing a cask deletes the app *and its data* (settings, caches, containers) on the switch.

**Done** – `ctrl-s`, or `shift-tab` to the *Done* button and Enter (a click works too):

1. the round once more, then the configuration is evaluated; if that fails, the error is shown and you are back in the list;
2. casks to zap: `just mac-diff` shows them, then *Continue? [y/N]* – no takes you back to the list;
3. on gusto itself: switch? (default yes, no if something is zapped);
4. the commit follows a successful switch – or a declined one; a failed switch leaves everything uncommitted.

One commit per round, `apps.json` only: `gusto: add obsidian (cask), remove shottr (cask)`, with a list in the body; a longer round is counted in the subject (`gusto: add 3 and remove 1 apps`). A tap bump is a commit of its own before it (`flake.lock: bump homebrew-cask for …`), so is a new tap (`gusto: pin tap stablyai/homebrew-orca for orca`).

**Cancel** – `esc`, or the *Cancel* button: with changes in the round it asks *Discard N change(s)?*, then `apps.json` (and `flake.lock`, and for a new tap `flake.nix` and `configuration.nix`) are back as they were. If `apps.json` already has uncommitted changes when `apps` starts, it stops before changing anything; the same for the other files once a round would change them.

### A cask from a third-party tap

Some vendors publish their Mac app only in a tap of their own; their install line then reads `brew install --cask <owner>/<tap>/<name>`. Give `apps` exactly that name:

```bash
apps stablyai/orca/orca
```

- Once the tap is pinned, its casks and formulae show up in every search like the others; the search reads them from the pin, without the network. In `apps.json` they are `"<owner>/homebrew-<tap>/<name>"`, e.g. `stablyai/homebrew-orca/orca`.
- A tap that is not pinned yet is found only through the fully qualified name; the hit is marked *tap not pinned*. Enter on it shows who publishes the tap (GitHub owner, verified or not, age of the repository, last push) and the URLs the cask downloads from, and asks *Pin stablyai/homebrew-orca as flake input stablyai-orca-tap for gusto and trust it?*
- **Yes** adds the input to `flake.nix` (after the last tap input, with a generated comment – rewrite it if the reason deserves more), the line `nix-homebrew.taps."stablyai/homebrew-orca" = inputs.stablyai-orca-tap;` to `hosts/gusto/configuration.nix` and runs `nix flake lock`. Then the usual pin check and the note follow. Because the start term named exactly this cask, the round ends right there – no return to the list, no *Switch?* question: summary, evaluation, `just mac-switch`, then the tap as a commit of its own (`flake.nix`, `flake.lock`, `configuration.nix`) before the one of `apps.json`. The same holds for `apps owner/tap/name` whose tap is already pinned. A round with a removal still asks before the switch.
- **Every pinned tap is trusted** (`brew trust`, [macOS hosts](#homebrew-one-policy-for-both-macs)): a cask runs its install code as you. Check the publisher before saying yes.
- From then on `just mac-upgrade` bumps the new input with the others – it finds every tap input in `flake.lock` by itself.

Removing the last cask of a tap leaves the tap pinned and trusted; take it out by hand (input, `nix-homebrew.taps` line, `nix flake lock`).

### Remove one thing directly

```bash
apps-rm shottr
```

For a single removal without the search. A cask wants its name typed to confirm, then `just mac-diff`, switch (default no), commit. A **Mac App Store** app, too, is uninstalled on the switch when its entry goes. If a name is declared from two sources, choose with `--source`, e.g. `apps-rm obsidian --source nixpkgs`.

### List

```bash
apps-list
```

By source, with the date it came in and the note.

### By hand

`apps.json` can be edited directly (the editor completes fields through `modules/darwin/apps.schema.json`), then `just mac-diff` and `just mac-switch`. Mistakes show up on evaluation with the complete list of problems; `nix build .#checks.aarch64-darwin.darwin-apps` checks the file alone.

Not in `apps.json`:

- **A new third-party tap** – it is a flake input: `apps <owner>/<tap>/<name>` adds it (above); by hand, add the input in `flake.nix` and `nix-homebrew.taps."<owner>/homebrew-<tap>" = inputs.<input>;` in `hosts/gusto/configuration.nix`, then `nix flake lock`. Its casks and formulae are then `"<owner>/homebrew-<tap>/<name>"` in `apps.json`.
- **A tool with configuration** – `programs.<tool>` in `hosts/gusto/home.nix` (zsh, git, tmux, …).

### Which checkout, which Mac

The commands change the nixlab checkout (or worktree) the current directory is in; anywhere else the one in `NIXLAB_REPO` (`~/Projects/homelab/nixlab`, set in `home.nix`), or `--repo <path>`. They are the package `nixlab-apps` from this flake, installed through `home.nix` – a change to the tool itself arrives with the next `just mac-switch`; `just apps*` always runs the working copy's version.

The host defaults to gusto; `--host zorlock` works provided the host has `nixlab.apps.file` set – zorlock does not today. For a Mac other than the one you are on, the round commits without switching; then `just push` and `just mac-switch <host>`.

## Hotfix a package

When nixpkgs ships a version with a security hole or a bug and the fix is not in our pin yet, we pin the package ourselves – but through `hotfix` from [`modules/hotfixes.nix`](modules/hotfixes.nix), not with a bare `overrideAttrs`. `hotfix` applies the override only while nixpkgs still needs it, and warns once it no longer does.

Why: the nightly auto-upgrade moves `nixpkgs` and `nixpkgs-unstable` on its own. A hand-written pin goes stale unnoticed, and as soon as nixpkgs is past it, it pins an *older* version. That is what happened to the paperless 3.3.2 bump on ursalia: unstable had shipped 3.3.2 for a while before anyone noticed. The warning is our addition; the rest is snowball's work, see [Credits](#credits).

### When the hotfix switches itself off

`hotfix` returns the nixpkgs package unchanged and warns as soon as either holds:

- `pkg.version` ≥ `fixedVersion` – nixpkgs has updated, or
- one of `pkg.patches` has `fixPatch` in its file name – stable has backported the fix as a patch without raising the version (the usual case for CVEs on a stable release).

The override itself, src hash included, is no longer evaluated after that.

### Package from the host's nixpkgs: overlay in `modules/hotfixes/`

For packages from the normal `pkgs` of a NixOS host (sudo, openssh, nginx …). Every file in `modules/hotfixes/` is loaded as an overlay on **every** NixOS host – but not on the Macs, which do not get `modules/*.nix`.

```nix
# modules/hotfixes/sudo.nix
# CVE-2025-32463: chroot option lets local users run code as root.
hotfix: final: prev: {
  sudo = hotfix {
    name = "sudo CVE-2025-32463";
    pkg = prev.sudo;
    fixedVersion = "1.9.17p1";
    fixPatch = "CVE-2025-32463";
    override = pkg: pkg.overrideAttrs (old: rec {
      version = "1.9.17p1";
      src = final.fetchurl {
        url = "https://www.sudo.ws/dist/sudo-${version}.tar.gz";
        hash = "sha256-…";
      };
    });
  };
}
```

`fixPatch` is optional; it only makes sense where the nixpkgs patch will have a recognisable name (CVE number). Fill in the hash: first leave `lib.fakeHash`, then copy the right value from the build error.

### Package from a different nixpkgs: `hotfix` in the host module

Packages from `import nixpkgs-unstable { … }` (paperless, Grist, …) do not see the overlays. There, `hotfix` is used as a module argument:

```nix
{ pkgs, nixpkgs-unstable, hotfix, ... }:
let
  unstable = import nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  paperless = hotfix {
    name = "paperless-ngx GHSA-…";
    pkg = unstable.paperless-ngx;
    fixedVersion = "3.4.1";
    override = pkg: pkg.overrideAttrs (finalAttrs: prev: { version = "3.4.1"; src = …; });
  };
in
```

Changes that do *not* depend on a version – a patch for an open upstream issue, tests switched off – stay outside `hotfix` as a plain `overrideAttrs` on top of the result.

### Where the warning shows up

It is an evaluation warning:

```
evaluation warning: hotfix "sudo CVE-2025-32463" is no longer needed: nixpkgs' sudo has version 1.9.17p1 (fix in 1.9.17p1) - remove it
```

It appears with every `just ship`, `nixos-rebuild` and `nix eval` of the host – and on the pull hosts in the nightly upgrade's journal, where nobody reads it:

```bash
journalctl -u nixos-upgrade --since today | grep 'hotfix "'
```

Then delete the file in `modules/hotfixes/`, or remove the `hotfix { … }` from the host module, and deploy.

### Credits

The pattern – version comparison, detection of a backported CVE patch, one overlay per file that is loaded automatically – is by snowball ([BBBSnowball](https://github.com/BBBSnowball)), who offered it for reuse: [`hotfixes/` in BBBSnowball/nixcfg](https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes). Our version adds the warning and the `hotfix` module argument for packages from another nixpkgs.

## Test a branch on a host before merging

A topic is deployed from its worktree to a host and merged into main only once it works there. Without precautions that lasts until 04:00: the nightly upgrade builds `/etc/nixos` – that is, main – and quietly switches the host back. A `just deploy` from another topic does the same. `just try` therefore sets a **hold** on the host that every way back to main honours ([`modules/deploy-hold.nix`](modules/deploy-hold.nix)).

### Flow

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

### With automatic rollback: `just try-confirm`

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

When the host answers under a different name afterwards (a rename), `via` names the address to deploy to; the confirmation always goes to `<host>.peer.homelab.example`. That was the case at ursalia's cut-over (2026-10-29), when the NUC still answered as ursalia-next:

```bash
just try-confirm ursalia 10 root@ursalia-next.peer.homelab.example
```

The question needs a real terminal; without one the answer is "no".

The pattern – apply, check from outside, keep only when confirmed within a deadline, revert otherwise – comes from snowball (BBBSnowball): [`firewall-update.sh`](https://github.com/BBBSnowball/nixcfg/blob/35264a74189686e8ce0231b4752f85225d0c9e00/hosts/sonline0/firewall-update.sh) does it for iptables rules; `try-confirm` does it for a whole NixOS generation.

### What honours the hold

| Path | With a hold |
| --- | --- |
| nightly `nixos-upgrade` | skipped (`ExecCondition`, not a failure): no flake update, no switch, no reboot. If the held commit has reached `/etc/nixos` meanwhile, it lifts the hold and runs. |
| `just rebuild`/`deploy`/`ship`/`deploy-all` | refused, unless the held commit is in the freshly pulled `/etc/nixos` – then the hold goes and the deploy runs |
| `just deploy-push <host>` | the same rule against the local checkout's `HEAD` |
| ursalia's nightly push to cuckoosegg | skipped, unless the held commit is in ursalia's `/etc/nixos` |

The rule is the same everywhere: a hold blocks as long as what is about to be deployed does not contain the held commit. A **rebase merge** rewrites the commit – then nothing recognises the merge, and the hold has to go with `just release <host>`.

### cuckoosegg

`just try cuckoosegg` works the same way, the hold lives on cuckoosegg. After the merge there is no `just deploy cuckoosegg`: either ursalia's push at 06:30 takes over once ursalia's checkout has the merge (`just deploy ursalia` or `just sync ursalia`), or right away from main with `just deploy-push cuckoosegg`.

### Seeing who holds what

- `just holds` – every NixOS host at once
- login shell on the host – a warning line, after 48 h with a pointer to `just release`
- Grafana "Homelab / Hosts Overview", panel **Deploy holds (just try)** – metric `nixlab_deploy_hold_since_seconds{branch,commit}`, orange while a hold exists, red after 48 h. The lab has no real alerting; the panel is the reminder.

### Limits

- **Tofu** (`netbird-apply`, `desec-apply`, `pocketid-apply`) has one state and is applied from main only. A topic that changes Tofu cannot be tested ahead this way.
- **Macs** (gusto, zorlock) are not covered – they have no nightly upgrade that would roll back.
- **Two topics on one host** at the same time do not work: the second `just try` refuses until the first is merged or released.
- A host from before `modules/deploy-hold.nix` knows no hold; the first `just try` on it brings the module along.
- **`try-confirm` and the nightly upgrade:** there is no hold until the confirmation. If the deadline spans 04:00, `nixos-upgrade` builds main. If the branch changes the hostname, it even builds main for the *new* name – at ursalia's cut-over (2026-10-27) the NUC booted the M720q's configuration that way. Set `nixos-hold set` first, or don't test into the night.

## Test a restore

A backup is only as good as the last restore that worked. `just restore-test <host>` brings grammi or zummi back from its restic backup into a throwaway VM on ursalia and measures how long that takes – from an empty disk until the services answer. It needs nothing but this repository and the recovery key `admin`, the same as after losing the host for real.

### Run it

From a checkout, in a terminal where `op` is signed in (`op whoami`; otherwise `eval "$(op signin)"`):

```bash
just restore-test grammi isolation
just restore-test grammi
just restore-test zummi
```

- `isolation` is the rehearsal: the VM boots and has to prove it reaches nothing. No secret is involved. Run it first after changing [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix).
- Without a mode it is the restore. 1Password asks for the `admin` key right at the start (`op://<vault>/<item>/password`, other reference via `NIXLAB_ADMIN_AGE_KEY`).
- About two minutes per host. Repeat after changing a host's backup paths, its databases, or a service's data directory, and otherwise every few months.

### What happens

1. **Build:** `lib.restoreTest.<host>` – the host's own configuration plus [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix) – is built on ursalia as a QEMU VM.
2. **T0:** the VM starts with an empty disk. Its services come up empty or fail on missing secrets, like after a reinstall.
3. **While it boots**, on ursalia: the `admin` key decrypts `restic_password` and the S3 key from the repository's `hosts/<host>/secrets.yaml`; restic restores the newest snapshot. The `admin` key is deleted again right after.
4. **Isolation:** the VM must reach neither ursalia, the internet nor aldrin's S3, and NetBird, Tailscale and the restic timers must not run – checked before any secret goes into the VM. The check proves itself on the VM's own sshd.
5. **Secrets:** the restored SSH host key must match `inventory.json`; in the VM, sops-nix then decrypts every secret of the host with it.
6. **Data:** grammi – fresh Postgres cluster, `pg_dumpall` dump loaded, mealie, Grist, Grafana, logchef and NetBird state in place. zummi – the pocket-id database from the consistent `.backup` copy and the Let's Encrypt account.
7. **Checks:** every service has to answer over HTTP; pocket-id's JWKS must hold a key (proves the encryption key fits the database). Then counts (users, peers, documents, OIDC clients) in the VM next to the same counts on the live host – read-only there.
8. **Cleanup:** VM and tmpfs are deleted. Should the recipe die halfway, the VM stops itself after 2 h and a timer deletes the tmpfs after 3 h.

### Isolation

The VM runs the host's real configuration with real secrets. That is safe only because it cannot send a single packet: QEMU's user network with `restrict=on` (`virtualisation.restrictNetwork`). The only way in is SSH on ursalia's loopback, with a key that exists only for this run. Its disk, the restored host key and every decrypted secret live under `/run/restore-test/<host>` on ursalia, a tmpfs – they never touch a disk. The hostname stays the real one, because the modules pick the sops files by it; without a network it shows up nowhere.

### Result 2026-11-02

| | grammi | zummi |
| --- | --- | --- |
| Build (from the cache) | 17–24 s | 14–20 s |
| VM up | 12 s | 13 s |
| Backup fetched | 2 s (65.7 MiB) | 2 s (5.2 MiB) |
| Secrets decrypted | 22 s (29/29) | 19 s (13/13) |
| Data in place | 29 s | 48 s |
| **RTO: services answer** | **38 s** | **48 s** |
| Counts restored / live | NetBird peers 15/15, users 6/6; mealie users 3/3; Grafana users 3/3; Grist documents 6/6 | users 4/4, OIDC clients 13/13, ACME files 3/3 |

Not measured: renting a replacement machine, installing NixOS on it, pointing DNS to it. The RTO above is the part after that.

### What the test found

1. **zummi's backup held no pocket-id database** – in none of the 22 snapshots from 2026-08-10 to 2026-11-02. The unanchored `"*.db"` exclude also matched the `.backup` copy. Fixed the same day (anchored to the data directory).
2. **grist needs pocket-id to start** (OIDC discovery at `auth.homelab.example`): with grammi and zummi both gone, zummi comes back first.
3. **netbird-server needs `pkgs.netbird.io` to start** – it asks for the current GeoLite file every time, although the files are in the backup.
4. **Only numeric owners:** restic keeps uids, not names, and `/var/lib/nixos` (the uid map) is in no backup. A reinstalled host hands out uids anew, so a restore chowns each service's files by name (the test does).
5. **Where pocket-id's database goes** (`data/` in its working directory) is in no backup; the copy keeps its file name only.

## Repository layout

One flake, `nixosConfigurations` for five hosts plus `darwinConfigurations` for the two Macs (zorlock, gusto) and two `devShells`: one for working on the repo, one with dnscontrol for the DNSControl repo. Every host gets an explicit module list in `flake.nix`; whatever is missing is missing with the reason in a comment next to it.

| Path | Contents |
| --- | --- |
| `flake.nix` / `flake.lock` | Inputs, host definitions, packages, `lib.topology`, `lib.inventory`, `checks` |
| `modules/` | 19 shared modules: base, nix, hotfixes, ssh, firewall, networking (ifstate), acme, crowdsec, tailscale, netbird, metrics/metrics-shipping, logging/log-shipping, qemu-guest, deploy, auto-upgrade-git, docs-site, maintenance |
| `modules/darwin/` | For the Macs: `homebrew.nix` (one Homebrew policy for every darwin host) and `rebuild.sh` (the engine behind the `mac-*` recipes) |
| `hosts/gusto/` | The workstation: `configuration.nix` (system, casks, macOS settings), `home.nix` and `ssh.nix` (home-manager), `ssh/*.pub` (public halves of the 1Password SSH keys) |
| `.envrc` | direnv: loads the flake's devShell (sops, age, tofu, …) in the checkout |
| `hosts/<host>/` | `configuration.nix`, hardware, service modules, sops files (`secrets.yaml`, `netbird.yaml`, `desec.yaml`) |
| `pkgs/` | Own packages: garage-ui, logchef, paperless-gpt, prometheus-paperless-exporter, ollama-metrics-proxy |
| `terraform/netbird/` | OpenTofu: NetBird account, policies, DNS zones, reverse proxy services, people/groups (incl. Pocket ID) |
| `terraform/desec-tokens/` | OpenTofu: narrowly scoped deSEC tokens per host for DNS-01 |
| `terraform/github/` | OpenTofu: the repositories `nixlab` (private) and `nixlab-docs` (public), deploy keys per host |
| `terraform/garage/` | OpenTofu: buckets, keys and permissions in Garage on aldrin (lifecycle rules by hand) |
| `topology.nix` | Generates the Grafana topology dashboard from the host configs |
| `inventory.json` / `inventory.nix` | Lab inventory (every machine: kind, site, uplink, relations, unlock) and its validation, see [Inventory](#inventory) |
| `inventory.schema.json` | JSON Schema for editing `inventory.json`, generated |
| `tests/` | Tests evaluated by `nix flake check` (`inventory.nix`) |
| `justfile` | All operational workflows: deploy, secrets, netbird-\*, desec-\* |
| `docs/` | This project documentation: pages under `site/{de,en}/`, Zensical config, build (`build.sh`, `site-src.sh`, `assemble.py`, `gen-reference.py`, `gen-llms.py`), the private site's package (`package.nix`) and what it would otherwise load from third parties – fonts, glightbox (`assets.nix`), install guides (ursalia, cuckoosegg, gusto), drafts of upstream issues |
| `dnsconfig.js` | Symlink into the separate DNSControl repo – public DNS records live there |
| `.sops.yaml` | age recipients per host, `admin` (offline recovery) and `workstation` (1Password) |

## Where do I change what?

Which file is responsible for which change, how often that happens, and what to do afterwards.

| What | Where | How often | Afterwards |
| --- | --- | --- | --- |
| A service, package or option on one host | `hosts/<host>/*.nix` | often | `just ship <host> "…"` |
| Something for all hosts | `modules/*.nix` | now and then | `just ship-all "…"`; new module: public or in `docs/modules-private.txt`? |
| A name behind the reverse proxy (grammi) | `hosts/grammi/proxy-services.json` | rarely | CNAME in DNSControl, deploy grammi, `just netbird-apply` |
| A mesh-only name | `terraform/netbird/mesh-services.tf` | rarely | `just netbird-apply` |
| Who may read the private docs | group `admin-workstations` (`terraform/netbird/subraum.tf`, peer names) | rarely | `just netbird-apply`, commit `admin-peers.json`, deploy aldrin and ursalia |
| NetBird policies, groups, people, routes | `terraform/netbird/*.tf` | rarely | `just netbird-plan`, `just netbird-apply` |
| Who may use the exit nodes | Pocket ID group `exit-nodes` (auth.homelab.example) | rarely | `just netbird-apply` |
| Public DNS records | DNSControl repo (`dnsconfig.js`) | rarely | `dnscontrol preview`, `dnscontrol push` there, commit |
| What a deSEC token may do | `terraform/desec-tokens/main.tf` | rarely | `just desec-apply` |
| Repositories, deploy keys | `terraform/github/` | rarely | `just github-plan`, `just github-apply` |
| Version of an automatically updated input | `flake.lock` | nightly, automatic | – |
| Version of a separately pinned input | `flake.lock` (`nix flake update <input>`) | by hand | deploy the hosts that use it |
| A package version nixpkgs has not caught up with (security fix) | `modules/hotfixes/` or `hotfix` in the host module | when needed | deploy; remove once the build warns – [Hotfix a package](#hotfix-a-package) |
| Test a topic on a host before merging | the topic's worktree | when needed | `just try <host>`, after the merge `just deploy <host>` – [Test a branch before merging](#test-a-branch-on-a-host-before-merging) |
| Grafana dashboard | `hosts/grammi/dashboards/*.json` | now and then | deploy grammi |
| Topology (new host, exporter, vhost) | generated by `topology.nix` | when needed | `just topology`, commit |
| Machine data: kind, hardware, site, uplink, power, unlock, networks, interfaces, host keys | `inventory.json` | with every new device | `just inventory-collect`, `just inventory-test` ([Inventory](#inventory)) |
| An app or CLI tool on the workstation | `hosts/gusto/configuration.nix` (cask) or `hosts/gusto/home.nix` (CLI) | when needed | `just mac-diff`, `just mac-switch` |
| Homebrew policy of the Macs | `modules/darwin/homebrew.nix` | rarely | `just mac-switch` on every Mac with Homebrew |
| Versions of the casks | `flake.lock` (Homebrew inputs) | by hand | `just mac-upgrade`, commit |
| Inventory format (fields, kinds) | `spec` in `inventory.nix` | rarely | `just inventory-schema`, test case, docs |
| A host's secrets | `hosts/<host>/secrets.yaml` | rarely | [Add secrets](#add-secrets) |
| This documentation | `docs/site/{de,en}/` | with every change | `just docs` |

## Contents of hosts/&lt;host&gt;/

What a host directory contains and who writes it. Not every host has every file.

| File | Content | Written by |
| --- | --- | --- |
| `configuration.nix` | host configuration: network, services, vhosts | by hand |
| `hardware-configuration.nix` | hardware, file systems | `nixos-generate-config`, then by hand |
| `disk-config.nix` | partitioning (disko, ursalia only) | by hand |
| further `*.nix` | one service per file, e.g. `backup.nix`, `samba.nix`, `netbird.nix`, `traefik.nix` | by hand |
| `secrets.yaml` | app secrets, encrypted for host + admin | `just secrets <host>` |
| `netbird.yaml` | NetBird setup key | `just netbird-key <host>` (Tofu) |
| `desec.yaml` | deSEC token for DNS-01 | `just desec-key <host>` (Tofu) |
| `maintenance.yaml` | bypass token of the [maintenance mode](#seeing-the-service-anyway), the same on aldrin, zummi, grammi, ursalia | `just maintenance-token` |
| `github.yaml` | private half of the deploy key | `just github-key <host>` |
| `github-deploy.pub` | public half, read by `terraform/github` | `just github-key <host>` |
| further `*.yaml` | sops files of single services, e.g. `netbird-server.yaml`, `netbird-proxy.yaml` (grammi), `push-cuckoosegg.yaml` (ursalia) | their recipes, e.g. `just netbird-server-secrets`, `just netbird-proxy-token` |
| `push-key.pub` | public key for the push deploy (cuckoosegg only) | `just cuckoosegg-push-key` |
| `dashboards/*.json` | Grafana dashboards (grammi only) | by hand, `topology.json` via `just topology` |
| `proxy-services.json` | services behind the reverse proxy (grammi only) | by hand, read by Tofu and `topology.nix` |

## Inputs and their pins

Only `nixpkgs`, `nixpkgs-unstable` and `sops-nix` move with the nightly auto-upgrade (`services.nixCache.prebuild.updateInputs` in `modules/deploy.nix`, updated by ursalia for every host). Anything that would lock the whole lab out on a broken release is pinned separately and bumped by hand.

| Input | Branch / tag | Used by | Nightly? |
| --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | all NixOS hosts | yes |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x), zorlock (mactop) | yes |
| `sops-nix` | main | all | yes |
| `nixpkgs-netbird` | nixos-unstable | NetBird server and all clients | no – server first, then clients |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id package) | no |
| `disko` | main | ursalia (all mounts) | no |
| `lanzaboote` | v1.1.0 | ursalia (Secure Boot) | no |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | no (no auto-upgrade) |
| `home-manager` | release-26.05 | gusto (dotfiles) | no – together with `nix-darwin` |
| `nix-homebrew` | main | Macs with Homebrew (gusto): the module that installs Homebrew | no – `just mac-upgrade` |
| `brew-src` | tag `7.0.11` (`flake = false`) | Macs with Homebrew: Homebrew itself, instead of nix-homebrew's own pin | no – edit the tag in `flake.nix` |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs with Homebrew: the pinned taps | no – `just mac-upgrade` |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird app (cask `netbird-ui`) | no – `just mac-upgrade` |
| `stablyai-orca-tap` | main (`flake = false`) | gusto: Orca (cask `orca`), pinned by `apps` | no – `just mac-upgrade` |

The Homebrew inputs are the reason a cask has a fixed version: with `mutableTaps = false` Homebrew cannot update its taps itself, see [macOS hosts](#macos-hosts).

`nix flake check` additionally verifies that `hosts/grammi/dashboards/topology.json` matches what `topology.nix` currently generates – a new exporter without `just topology` fails the check.

## Hosts & roles

Three rented VMs carry the public services, ursalia, tummi and zorlock sit at home, cuckoosegg in the Subraum hackerspace; gusto is the admin workstation (a MacBook). All servers are reachable in the NetBird mesh as `<host>.peer.homelab.example`; root SSH exists only there. Kind, site, uplink and disk unlock of every machine – including the routers, KVM and appliances – are in the [inventory](#inventory), all of it at a glance on the [lab map](#lab-map).

| Host | Platform | Role | Notes |
| --- | --- | --- | --- |
| grammi | NixOS, rented VM | NetBird server (`mesh.homelab.example`) + reverse proxy, Traefik, monitoring (VictoriaMetrics/-Logs, Grafana, logchef), Mealie, Grist, PostgreSQL | Central sink for metrics and logs of all hosts |
| zummi | NixOS, rented VM | Pocket ID (`auth.homelab.example`) – login for all services and NetBird | pocket-id pinned separately |
| aldrin | NixOS, rented VM | Garage S3 (`s3.aldrin.homelab.example`), garage-ui (`s3-admin`), backup target for restic, docs site (`doku`) | Forked garage-ui package with subpath support |
| ursalia | NixOS, bare metal (ASRock NUC BOX-1260P) | Paperless-ngx 3 + paperless-gpt (`dokumente`), HealthLog (`health`), Bambuddy (`bambuddy`), AdGuard Home (`dns`, `adguard`), docs site (`doku`), Samba for the scanner, routing peer into the home LAN, build host for cuckoosegg, ESPHome build server for Home Assistant (home LAN only, port 6055), Claude Code bridge to the NanoKVM Go+ (on demand) | LUKS + btrfs via disko, TPM unlock, Secure Boot (lanzaboote), WLAN (Intel AX211, `home-wifi.nix`), no CrowdSec |
| tummi | NixOS, bare metal (ASRock NUC BOX-1260P) | Copying and sorting files: 8 TB on `/data`, SMB share "Daten" on the mesh | Built like ursalia (disko, TPM unlock, Secure Boot), WLAN with a wired fallback, nothing exposed |
| cuckoosegg | NixOS, VM on the Subraum Proxmox | NetBird routing peer into the Subraum networks | Group `subraum-devices` instead of `servers`, no repo/deploy key, deployed by push |
| zorlock | macOS + nix-darwin, Mac mini M4 | Ollama on the Apple GPU (`llm`), used by paperless-gpt | None of the `modules/*.nix`; FileVault unlock after reboot via LAN SSH |
| gusto | macOS + nix-darwin + home-manager, MacBook Pro | Admin workstation: deploys, secrets, Tofu, docs | Laptop, no sshd, no secrets, not monitored; apps as Homebrew casks, NetBird as the official app – see [gusto](#gusto--the-admin-workstation) and [macOS hosts](#macos-hosts) |

## gusto – the admin workstation

gusto is the MacBook Pro everything in this repo is run from: deploys, secrets, Tofu, the docs. It is the second nix-darwin host next to zorlock, and the only machine in the lab a person sits at. This page is the complete reference for it – what is on it, where each part is configured, how it is used day to day and what to check when something does not work. *Why* it is built this way (Homebrew policy, NetBird as an app, the differences to zorlock) is on [macOS hosts](#macos-hosts).

### At a glance

| | |
| --- | --- |
| Hardware | Apple MacBook Pro (Apple silicon), `kind: laptop`, `availability: intermittent` in the inventory |
| System | macOS (English, region Germany), FileVault on |
| Configuration | `darwinConfigurations.gusto` in `flake.nix`: nix-darwin + home-manager (user `admin`) |
| Built and switched | on gusto itself, from the working copy `~/Projects/homelab/nixlab` – `just mac-switch` |
| Apps | Homebrew casks, Homebrew and its taps pinned in `flake.lock` (`modules/darwin/homebrew.nix`); all software listed in `hosts/gusto/apps.json` |
| Repo tools | from the flake's devShell, loaded by direnv in the checkout |
| SSH | client only, keys only in 1Password; no Remote Login (no sshd) |
| Mesh | NetBird peer `gusto` (cask `netbird-ui`), group `admin-workstations` |
| Secrets | only `hosts/gusto/mcp.yaml` (the [Claude app's MCP servers](#the-claude-apps-mcp-servers)), encrypted for the workstation age key from 1Password; gusto has no host key of its own |
| Monitoring | none; not in the topology, nothing in the lab depends on it (`criticality: lab`) |
| Backup | Arq 7 to Garage on aldrin, plus Time Machine |

### Files

| File | Content |
| --- | --- |
| `hosts/gusto/configuration.nix` | System: host name, Nix settings, Touch ID for sudo, taps, SSH known hosts, `SSH_AUTH_SOCK` for GUI apps, macOS settings, home-manager wiring |
| `hosts/gusto/home.nix` | admin's home: environment, links, zsh and its helpers, CLI/TUI tools, Ghostty, git |
| `hosts/gusto/ssh.nix` | `~/.ssh/config` and `~/.ssh/pub/` |
| `hosts/gusto/mcp.nix`, `mcp.yaml` | The Claude app's MCP servers: `mcp-run` and their entries in Claude's config files; their credentials (sops) |
| `hosts/gusto/ssh/*.pub` | Public halves of the SSH keys (one per target), linked to `~/.ssh/pub/` |
| `hosts/gusto/apps.json` | All software: casks, formulae, Mac App Store, nixpkgs (system, user, font), each with a note – `apps-list` |
| `modules/darwin/apps.nix`, `apps.schema.json` | Turns `apps.json` into the options and checks it; editor schema |
| `pkgs/nixlab-apps/` | The tool behind `apps`, `apps-list`, `apps-rm` |
| `modules/darwin/homebrew.nix` | Homebrew policy shared with zorlock |
| `modules/darwin/rebuild.sh` | The engine of the `mac-*` recipes |
| `.envrc` | `use flake` – direnv loads the devShell in the checkout |
| `docs/install-gusto.md` | Setting gusto up from scratch (private docs only) |

Flake inputs used only by gusto: `home-manager`, `nix-homebrew`, `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap` – see [Flake inputs](#inputs-and-their-pins).

### What is installed

gusto was set up deliberately bare on 2026-10-21: no app list taken over from the previous installation, only the base below. Anything else is added when it is needed (see [Day to day](#day-to-day)). The tables describe it; the complete, current list is `hosts/gusto/apps.json` – `apps-list`.

#### Apps (Homebrew casks)

| Cask | What for |
| --- | --- |
| `1password`, `1password-cli` | Passwords, the SSH agent with all SSH keys, `op` for scripts (sops' age key). The CLI as a cask, not from nixpkgs: it unlocks through the app with Touch ID, which only works with the vendor's signed binary. |
| `vivaldi` | Browser |
| `arq` | Backup to Garage on aldrin |
| `claude` | Claude desktop app; its local MCP servers: [the Claude app's MCP servers](#the-claude-apps-mcp-servers) |
| `ghostty` | Terminal |
| `netbirdio/homebrew-tap/netbird-ui` (+ formula `netbird`) | NetBird menu-bar app and daemon – see [NetBird](#netbird) |
| `stablyai/homebrew-orca/orca` | Orca – IDE for running several AI coding agents side by side in terminals and worktrees; from Stably's own tap (input `stablyai-orca-tap`), updates itself. Removing it zaps `~/.orca` too |
| `shottr` | Screenshots |
| `telegram`, `whatsapp` | Messengers |
| `spotify` | Music |
| `visual-studio-code` | Editor (Microsoft's build, for Remote-SSH and Pylance); telemetry off, `settings.json` comes from home-manager and is read-only |

From the Mac App Store (`homebrew.masApps`, through `mas`; needs the App Store sign-in): **1Blocker**, **1Password for Safari**, **Ivory**, **TestFlight**. `zap` also removes App Store apps that are not declared; `just mac-switch` stops and asks first (see [macOS hosts](#macos-hosts)).

#### System-wide (nix-darwin)

`git`, `gh`, `just`, `jq`, `neovim` (`EDITOR`/`VISUAL`, kept across sudo), `curl`, `wget`, `rsync`; zsh as the system shell (`programs.zsh`); the font **Maple Mono NF** (Nerd Font) for Ghostty and the TUIs.

#### admin (home-manager)

| Tool | Notes |
| --- | --- |
| zsh | config in `~/.config/zsh`, autosuggestions, syntax highlighting, history in `~/.local/state/zsh/history` |
| atuin | shell history in SQLite, Ctrl-R / ↑ search; update check off |
| fzf | Ctrl-T (files), Alt-C (cd) |
| zoxide | `z <part of a path>` |
| direnv + nix-direnv | per-directory environments; caches flake shells and protects them from GC |
| bat, eza, ripgrep, fd, tree | `cat`/`ls`/`grep`/`find` replacements; eza brings `ls`, `ll`, `la`, `lt` |
| lazygit, btop, yazi, tmux | TUIs; yazi as `y` (changes into the last directory on exit), tmux with mouse, `tmux-256color` |
| nvd, nix-output-monitor | closure diffs, readable build output (`nom`) |
| uv | Python tools (`uv tool install` → `~/.local/bin`) |
| typst | documents (real-fast-document) |

#### Repo tools (devShell)

`sops`, `age`, `ssh-to-age`, `opentofu`, `nvd` – from `devShells.aarch64-darwin.default`, at the versions in `flake.lock`. They are there in every shell inside the checkout (direnv), not elsewhere. `dnscontrol` comes from `devShells.aarch64-darwin.dns` and is only there in the DNSControl folder, behind a wrapper that decrypts the credentials with sops – see [macOS hosts](#dnscontrol). The docs tools (pandoc, WeasyPrint, Zensical) are not in it; `just docs` and `just docs-serve` fetch their own.

### Environment

| Variable / path | Value | Why |
| --- | --- | --- |
| `PATH` | Nix profiles, then `/opt/homebrew/bin:sbin`, then macOS' directories; `~/.local/bin` in front for admin | Nix wins over Homebrew, Homebrew over Apple's stubs; no `brew shellenv` anywhere |
| `SSH_AUTH_SOCK` | `~/.1password/agent.sock` | every SSH client talks to 1Password – in shells (home-manager) and GUI apps (`launchd.user.envVariables`) |
| `SOPS_AGE_KEY_CMD` | `op read "op://<vault>/<item>/password"` | sops gets the workstation key from 1Password when it needs it; never on disk |
| `EDITOR`, `VISUAL` | `nvim` | |
| `GOPATH` / `GOBIN` | `~/.local/share/go` / `~/.local/bin` | XDG; binaries into the one personal PATH directory |
| `CARGO_HOME` / `CARGO_INSTALL_ROOT` | `~/.local/share/cargo` / `~/.local` | same; `cargo install` writes to `<root>/bin` |
| `ZDOTDIR` | `~/.config/zsh` | set by the stub `~/.zshenv` home-manager writes |

#### Files and links home-manager manages

| Path | |
| --- | --- |
| `~/.zshenv` → `~/.config/zsh/.zshenv`, `.zshrc` | zsh |
| `~/.config/git/config` | git |
| `~/.config/ghostty/config` | Ghostty |
| `~/.config/tmux/tmux.conf`, `~/.config/atuin/config.toml`, `~/.config/direnv/…`, `~/.config/lazygit/config.yml` | the tools |
| `~/.ssh/config`, `~/.ssh/pub/` | SSH |
| `~/.1password/agent.sock` → `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` | path without spaces for the agent; 1Password does not create it |
| `~/.config/ssh` → `~/.ssh` | XDG rule: tools without XDG support get a link under `~/.config` |

A file home-manager wants to write but finds already there (first switch on a fresh macOS) is renamed to `<name>.before-hm` instead of failing the switch.

### macOS settings

Decided one by one on 2026-10-21; everything not listed is macOS' default.

| Area | Setting | nix-darwin option |
| --- | --- | --- |
| Menu bar clock | 24 h, weekday, no date | `menuExtraClock.Show24Hour`, `ShowDayOfWeek`, `ShowDate = 2` |
| Dock | always visible, no magnification, icon size 66 | `dock.autohide`, `magnification`, `tilesize` |
| | no launch animation, no bouncing | `dock.launchanim`, `CustomUserPreferences."com.apple.dock"."no-bouncing"` |
| | minimise into the app icon, effect "scale", no recent apps | `minimize-to-application`, `mineffect`, `show-recents` |
| | hot corner bottom right: Quick Note | `dock.wvous-br-corner = 14` |
| | Dock content | not managed (yet) |
| Finder | path bar on, status bar off, icons on the desktop, list view, folders first (windows and desktop) | `finder.ShowPathbar`, `ShowStatusBar`, `CreateDesktop`, `FXPreferredViewStyle = "Nlsv"`, `_FXSortFoldersFirst`, `_FXSortFoldersFirstOnDesktop` |
| General | dark appearance, all file extensions, auto-capitalisation, period on double space | `NSGlobalDomain.AppleInterfaceStyle`, `AppleShowAllExtensions`, `NSAutomaticCapitalizationEnabled`, `NSAutomaticPeriodSubstitutionEnabled` |
| Trackpad | Force Click on, tracking speed 1 | `NSGlobalDomain."com.apple.trackpad.forceClick"`, `"com.apple.trackpad.scaling"` |
| Keyboard | German (main) and U.S. input sources | `CustomUserPreferences."com.apple.HIToolbox".AppleEnabledInputSources` – U.S. for KVM sessions (NanoKVM Go+, ArkKVM type PC scancodes); effective after logging out once |
| Network names | `gusto` as computer, local host and SMB NetBIOS name | `networking.*Name`, `smb.NetBIOSName` |
| Language, region | English, Germany | not in Nix – set during macOS setup |

After each switch `activateSettings -u` runs as admin, so most settings apply without logging out.

### Nix

Experimental features `nix-command flakes`; `admin` is a trusted user; no channels; `min-free` 5 GiB / `max-free` 20 GiB; store optimisation on; garbage collection Sundays 12:15, everything older than 30 days. No extra binary caches – every input follows nixpkgs, a community cache would have no hits.

### Security

- **FileVault** on (macOS setup).
- **sudo with Touch ID** (`/etc/pam.d/sudo_local`, which macOS updates leave alone), working inside tmux too (`pam_reattach`).
- **No Remote Login**: gusto runs no sshd and accepts no SSH connections. Nothing in the inventory or in `.sops.yaml` has a key for it, so no secret is ever encrypted to it.
- **Keys only in 1Password**: SSH keys (agent), the sops age key (`op read`), the Arq credentials. Nothing private under `~/.ssh`. The MCP servers' credentials are in sops (`hosts/gusto/mcp.yaml`), readable only with that age key.

### SSH

`~/.ssh/config` is generated (`hosts/gusto/ssh.nix`). At the very top, before any `Host` block: `IdentityAgent ~/.1password/agent.sock`, `IdentitiesOnly yes`, `Compression yes`, `SendEnv LANG LC_*` – first value wins in ssh_config, so nothing below can change them. Every `IdentityFile` names a **public** key in `~/.ssh/pub/`; that is how the agent knows which single key to offer.

Host keys: lab hosts from `inventory.json` (`/etc/ssh/ssh_known_hosts`), GitHub pinned; the rest goes to `~/.ssh/known_hosts` on first use.

| `ssh …` | Goes to | User | Key (`~/.ssh/pub/`) | Notes |
| --- | --- | --- | --- | --- |
| `aldrin`, `grammi`, `zummi`, `ursalia`, `cuckoosegg` (also `<host>.peer.homelab.example`) | `<host>.peer.homelab.example` (NetBird) | root | `<host>.homelab.example.pub` | generated from the inventory: every managed host except gusto |
| `zorlock` | `zorlock.peer.homelab.example` | admin | `zorlock.homelab.example.pub` | no root on macOS |
| `<host>.example-tailnet.ts.net` | Tailscale | as above | as above | break-glass while Tailscale still runs; not for cuckoosegg. Goes away with Tailscale. |
| `aldrin.homelab.example`, `grammi.homelab.example`, `zummi.homelab.example` | public address | admin | as above | fallback when the mesh is down – root is refused on public addresses (`modules/ssh.nix`) |
| `zorlock-lan` | 198.51.100.86 | admin | `zorlock.homelab.example.pub` | FileVault unlock after a reboot, from the home LAN |
| `gruffi` | 198.51.100.1 | root | `gruffi.homelab.example.pub` | home router (Flint 4, GL.iNet firmware, Dropbear) |
| `arkkvm`, `arkkvm01` | `arkkvm01` (DHCP name) | root | `arkkvm.pub` | |
| `subraum-router` | hackspace.c3pb.de | admin | `c3pb.de.pub` | jump host; forwards 8006 → Proxmox, 8080/8081 → Home Assistant |
| `vogon`, `amnesia`, `unifi` | `<name>.subraum.c3pb.de` via `subraum-router` | root | `<name>.subraum.c3pb.de.pub` | |
| `git.c3pb.de` | | git | `git.c3pb.de.pub` | |
| `edi` | | admin | – | `HostKeyAlgorithms +ssh-rsa` |
| `switch-*`, `172.31.64.*`, `172.31.65.*` | | bernd (switches) | – | old switches: *adds* SHA-1 KEX, `ssh-rsa`, CBC ciphers |
| `github.com` | | git | `github.com.pub` | ControlMaster, 60 s |
| `github-443` | ssh.github.com:443 | git | `github.com.pub` | for networks that block port 22 |

The alternative names (tailnet, public) carry `HostKeyAlias <host>.peer.homelab.example`, so all of them are checked against the one host key in the inventory. A new managed host appears here by itself after `just mac-switch` – only its public key file has to be added to `hosts/gusto/ssh/`.

### git

`~/.config/git/config`: name `admin`, address `mail@admin.org`; below `~/Projects/homelab/` (`includeIf gitdir:`) `admin@homelab.example`. `init.defaultBranch = main`, `pull.rebase = true`, alias `lg = log --oneline`. GitHub over SSH with the key `github.com SSH (admin)` from 1Password; `gh` for the API.

### NetBird

The official app from NetBird's tap (cask `netbird-ui`, formula `netbird` for the daemon), pinned as the input `netbirdio-tap`. Sign-in by SSO (Pocket ID) in the app, peer name `gusto`, group `admin-workstations` (Subraum devices, docs site). Rosenpass is **off** on the workstation (since 2026-10-21; mesh-wide since 2026-10-24, until 2026-10-31). The version follows the tap, not `nixpkgs-netbird`; `just mac-upgrade` prints both. Details and the comparison with zorlock: [macOS hosts](#netbird-on-the-two-macs).

### The Claude app's MCP servers

The desktop app and Claude Code start their local MCP servers as stdio processes through `mcp-run <server>` (`hosts/gusto/mcp.nix`, set up on 2026-10-23). On every start `mcp-run` decrypts only that server's section of `hosts/gusto/mcp.yaml` (`moneymoney` has none and starts without sops). The file is encrypted with sops for the keys `workstation` and `admin`; `op` may ask for Touch ID while doing so. Then `mcp-run` starts the server. No credential is in any of Claude's config files.

| Server | What | Start | Credentials in `mcp.yaml` | Desktop | Claude Code |
| --- | --- | --- | --- | --- | --- |
| `homeassistant` | [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) as an app (add-on) on the Raspberry Pi, port 9583 | `uvx fastmcp-remote <url>`, bridges HTTP to stdio | `homeassistant.url`: the app's secret URL, host `homeassistant.peer.homelab.example` | yes | yes |
| `feedbin` | [FeedbinMCP](https://github.com/admin/FeedbinMCP), admin's fork of [hypermoose/FeedbinMCP](https://github.com/hypermoose/FeedbinMCP) | `uv run --directory ~/Projects/personal/FeedbinMCP feedbin-mcp` | `feedbin.email`, `feedbin.password` | yes | no |
| `arkkvm` | [arkkvm-mcp](https://github.com/admin/arkkvm-mcp) | `uv run --directory ~/Projects/arkkvm/arkkvm-mcp arkkvm-mcp`, host `arkkvm01`, keyboard layout `de` | `arkkvm.password` | yes | yes |
| `moneymoney` | [moneymoney-mcp](https://github.com/pipamann/moneymoney-mcp) by Leon Heuser, read-only, through AppleScript to the running, unlocked app | `moneymoney-mcp`, built from tag [v0.4.0](https://github.com/pipamann/moneymoney-mcp/tree/3266505c450ff92ceaa79df3d59965f8ea28f22f) (`pkgs/moneymoney-mcp.nix`) | none | yes | no |

- **ha-mcp rather than the built-in "Model Context Protocol Server" integration:** the built-in one only sees what is exposed to Assist and has no device registry. ha-mcp can handle automations, dashboards, registries, history and more, with write access. That is deliberate: Claude asks before every tool call, and ha-mcp takes a backup before it changes anything. The app talks to HA through the Supervisor, so no long-lived token is needed. Its secret URL is in the app's log at start.
- **Reached over the mesh:** the same URL works at home and away. The NetBird policy `home-assistant-mcp` (`terraform/netbird/home-assistant.tf`) allows `admin-workstations` → HA, TCP 9583 only. Outside the LAN and the mesh the URL alone is of no use.
- **No Feedbin and no MoneyMoney in Claude Code:** feed articles and transaction texts are text from strangers (anyone sending money picks the reference), so a way in for prompt injection, and Claude Code has a shell and sops on gusto.
- **Configuration:** every switch merges the servers with `jq` into `mcpServers` of `~/Library/Application Support/Claude/claude_desktop_config.json` and `~/.claude.json`, by name. Servers added by hand stay; one removed here has to be deleted there by hand. The apps read the file at start, so restart them after a switch.
- **Changing credentials:** `cd ~/Projects/homelab/nixlab && sops hosts/gusto/mcp.yaml`. The change applies from the next server start, without a switch, because `mcp-run` reads the file in the working copy. The HA URL can be taken straight from the clipboard, with its host replaced by the mesh name:
  `cd ~/Projects/homelab/nixlab && sops set hosts/gusto/mcp.yaml '["homeassistant"]["url"]' "\"$(pbpaste | sed -E 's#^http://[^/]+#http://homeassistant.peer.homelab.example:9583#')\""`
- **MoneyMoney built from the tag, not `npx -y moneymoney-mcp`:** upstream's `npx` resolves the newest release and its dependency ranges from npm on every start; for a server that reads the bank accounts the build from `package-lock.json` is pinned and fetches nothing at start. An update means bumping version and hashes (see the package file). Read-only on purpose: without `--enable-transfers` the `create_bank_transfer` tool does not exist. At the first access macOS asks under Automation whether Claude may control MoneyMoney (System Settings → Privacy & Security → Automation). Error `DATABASE_LOCKED`: unlock MoneyMoney.

### Backup

- **Arq 7** backs up the whole disk to the Garage bucket on aldrin, with its own backup plan for gusto (the previous MacBook's plan is kept for restores only). Encryption password and Garage credentials are in 1Password.
- **Time Machine** in addition.
- Nothing on gusto needs a backup to be rebuilt: the system and the dotfiles are this repo, the keys are in 1Password. A backup is for data.

### Day to day

| Task | How |
| --- | --- |
| Add or remove apps and CLI tools | `apps [term]` (any directory; `just apps` in the checkout) – one round: search, pick, change the search, pick again …, then one switch and one commit ([how-to](#software-on-the-macs)); a tool with configuration: `programs.<tool>` in `hosts/gusto/home.nix` |
| Remove one thing directly | `apps-rm <name>`; casks go with their data (`zap`) – `mac-diff` comes first |
| See what is declared | `apps-list` |
| Update apps (Homebrew) | `just mac-upgrade` – bumps only the tap inputs, switches, `brew upgrade`, summary; then commit `flake.lock` |
| Update the system (Nix) | `nix flake update nixpkgs-darwin nix-darwin home-manager` → `just mac-switch` → also `just mac-switch zorlock` (same inputs) |
| Deploy a NixOS host | `just ship <host> "<message>"` or `just deploy <host>` – over the mesh as root |
| Edit secrets | `just secrets <host>` (Touch ID for `op`) |
| Docs | `just docs-serve` (preview), `just docs` (PDFs + public repo) |
| New checkout or worktree | `direnv allow` once inside it |

All `mac-*` recipes take the host as an optional parameter (default `gusto`; `zorlock` runs over SSH after a `git pull` there). New files must be known to git (`git add`) before a switch sees them.

### Troubleshooting

| Symptom | Check |
| --- | --- |
| `ssh-add -L`: "The agent has no identities" / "Could not open a connection" | 1Password running and unlocked, Settings → Developer → *Use the SSH agent*; `ls -l ~/.1password/agent.sock`; `echo $SSH_AUTH_SOCK` |
| ssh offers the wrong key / "Too many authentication failures" | `ssh -G <host> \| grep -E 'identityfile\|identityagent'` – exactly one `.pub` from `~/.ssh/pub/` |
| Host key mismatch for a lab host | host reinstalled or key rotated: inventory updated? Then `just mac-switch` (known hosts are part of the system) |
| `sops`, `tofu` not found | not in the checkout, or `direnv allow` missing |
| sops: "failed to get the data key" | `op read "op://<vault>/<item>/password" \| age-keygen -y` must print the workstation's `age1…` |
| `brew` installs nothing / tap missing | taps come only from `flake.lock` (`mutableTaps = false`); `brew tap` and `brew update` are not the way – add an input, `just mac-switch` |
| A setting did not apply | log out and in once (input sources, some Dock/Finder keys) |
| `.before-hm` files in the home directory | left by the first switch; compare and delete |
| An MCP server does not connect | run `mcp-run <server>` in a terminal: does it hang at Touch ID or sops, is a value missing in `mcp.yaml`, is the checkout missing? The desktop app logs to `~/Library/Logs/Claude/mcp-server-<name>.log` |
| `homeassistant` hangs | the URL's port must be 9583, the policy silently drops any other (timeout after 30 s): `sops decrypt --extract '["homeassistant"]["url"]' hosts/gusto/mcp.yaml \| cut -d/ -f3` shows only host and port; `nc -z homeassistant.peer.homelab.example 9583`; if `netbird status -d` shows HA as "Connected" but without a WireGuard handshake, Rosenpass in the NetBird app on HA is strict – turn on `rosenpass_permissive` there (until 2026-10-31 Rosenpass belongs off there entirely) |
| NetBird disconnected | menu-bar app → Connect; `netbird status -d`; daemon: `sudo launchctl print system/netbird` |

## gruffi – the home router

gruffi is the home network's router: a GL.iNet Flint 4 (GL-BE14000), running OpenWrt main instead of the GL firmware since 2026-11-02. It terminates the PPPoE line, routes and filters between the five home networks, hands out DHCP and router advertisements and is the switch for the servers. This page is its reference – what runs on it, where the image comes from, which port does what, what was measured and what is known to be broken. The network plan (zones, firewall matrix, WLANs, radio plan) is `docs/plan-heimnetze.md`; setting it up from scratch is in the private guide *Setting up gruffi*.

### Overview

| | |
| --- | --- |
| Hardware | GL.iNet Flint 4 (GL-BE14000): MT7988A (4 × Cortex-A73), 2 GiB RAM, 64 GB eMMC; MT7996/MT7990 Wi-Fi module on PCIe (Wi-Fi 7, 2.4/5/6 GHz) |
| System | OpenWrt main, built from PR [openwrt/openwrt#26215](https://github.com/openwrt/openwrt/pull/26215) (GL-BE14000 support, John Crispin) plus the netdev-name fix by Nilanka de Silva ([JiaY-shi/openwrt@89988effb0](https://github.com/JiaY-shi/openwrt/commit/89988effb028fce82ab943db5fd11b5a65a118a8)) and a kernel with `IPV6_ROUTER_PREF`/`IPV6_ROUTE_INFO` (Thread, `docs/thread-probe.md`) |
| Bootloader | GL's own U-Boot (the PR's "stock U-Boot" variant); its web recovery is the way back |
| Configuration | everything at first boot from `/etc/uci-defaults/90-gruffi`, generated from `inventory.json` by `openwrt/gruffi/uci.nix`; no hand-made configuration |
| Built | on ursalia in the container `openwrt-gruffi` (`openwrt/gruffi/build.sh`), checked with `openwrt/gruffi/dryrun.sh` |
| Installed | `sysupgrade -n` with the sysupgrade image (fresh, without the old configuration) |
| Access | OpenSSH, gusto's key only (`hosts/gusto/ssh/gruffi.homelab.example.pub`), from the mgmt network, from gusto in the private network and over the mesh |
| WLAN | currently from ap-og (EAP660 HD) – on sw-og-flur (lan6), directly on lan8 until the move (`docs/install-sw-og-flur.md`) – the built-in radios do not come up (see [Known issues](#known-issues)) |
| Display | stays dark: with the stock U-Boot the panel driver has no panel the bootloader switched on to take over |

### Files

| File | Content |
| --- | --- |
| `openwrt/gruffi/uci.nix` | Everything set at first boot: port roles, bridge and VLANs, networks, DHCP with all reservations, DNS, firewall zones and rules, PPPoE, SQM, WLANs, Thread sysctl, avahi; plus the expectations for the dry run (`dryrun`). Derives addresses, pools, prefixes and reservations from the inventory |
| `openwrt/gruffi/gen-files.sh` | Generates the image's `files/` from `uci.nix` and fills in the secrets (WLAN keys, root password hash from `secrets.yaml`, sops, workstation key from 1Password) |
| `openwrt/gruffi/secrets.yaml` | sops: WLAN keys, root password and its hash |
| `openwrt/gruffi/config.seed` | Package selection and options of the build |
| `openwrt/gruffi/inner.sh` | Runs in the build container: fetch the PR head, cherry-pick the fix, set kernel options, build, write `BUILDINFO` |
| `openwrt/gruffi/build.sh`, `Containerfile` | Starts the build on ursalia (Debian container, incremental, state in `/var/lib/openwrt-build/gruffi`) |
| `openwrt/gruffi/dryrun.sh` | Dry run with real clients (see [Changes](#changes)) |

### Ports and switches

Three paths lead into the SoC: the built-in 1G switch (MT7988, gmac0), the 2.5G switch YT9224 with the YT8824 quad PHY and the SFP+ cage (gmac1, fixed 10G USXGMII link, its own DSA tree) and the 10G copper port (RTL8261D, gmac2). The names follow the case labels.

| Port | Switch | Role (`uci.nix`) |
| --- | --- | --- |
| `wan` (WAN/LAN1, 10GBASE-T) | RTL8261D | mgmt untagged – the admin cable |
| `lan2` | YT9224/YT8824 | uplink: PPPoE on VLAN 7 (`lan2.7`) |
| `lan3` | YT9224/YT8824 | server untagged (ursalia) |
| `lan4` | YT9224/YT8824 | server untagged (zorlock, after its move to the Mac mini M6) |
| `lan5` | YT9224/YT8824 | trunk: private untagged, the others tagged (Flint 2) |
| `lan6` | MT7988 | trunk: mgmt untagged, the others tagged (sw-og-flur, PoE switch: ap-og, SLZB-MR3U) |
| `lan7` | MT7988 | server untagged (Home Assistant) |
| `lan8` | MT7988 | trunk: mgmt untagged, private/IoT/guest tagged: spare for ap-og (EAP660 HD), which hangs off sw-og-flur |
| `lan9` | MT7988 | IoT untagged (Hue Bridge) |
| `sfp` (SFP+) | YT9224 | trunk: all tagged |

All LAN ports are in one VLAN-filtering bridge `br-lan`; every network is a VLAN on it (`br-lan.<VLAN>`), VLAN IDs and prefixes come from the inventory. STP is on with gruffi as root bridge (priority 4096, forward delay 4 s): a freshly plugged port forwards after about 8 s.

### Networks and services

- **DHCP and RA** in all five networks (dnsmasq, odhcpd); `dhcpv4=server` has to be set – dnsmasq on main leaves DHCPv4 off otherwise. The reservations are all inventory interfaces with `ipv4.mode = "reserved"`.
- **DNS:** mgmt gets gruffi itself, the other networks AdGuard Home on ursalia (IPv4 and its ULA ::53). The firewall allows both addresses; gruffi's dnsmasq answers `.lan` and the services' LAN names, AdGuard forwards them to it.
- **Firewall** (fw4): zones = networks; forwardings and single rules are in `uci.nix` and follow the matrix in `docs/plan-heimnetze.md`. mgmt may reach the WAN (decision 5a on flash day).
- **PPPoE** on `lan2.7`, IPv6 by DHCPv6-PD (/56); SQM (cake) on `pppoe-wan`.
- **Offload:** software and hardware flow offloading on, `bridger` for bridge flows.

### Changes

Nothing on the device is changed by hand for good – changes go into `uci.nix` (or the inventory), then:

1. `nix develop -c openwrt/gruffi/build.sh` – build on ursalia (needs 1Password for sops).
2. `nix develop -c openwrt/gruffi/dryrun.sh` – runs the last build's `90-gruffi` in an OpenWrt x86 container with veth ports named like gruffi's and checks per network: DHCPv4 lease (pool, router, DNS), the first reservation, the RA (ULA prefix, DNS) with `rdisc6`, plus `fw4 check` and the number of DHCP ranges. With `--no-dhcpv4` it has to fail.
3. Image to gusto and gruffi, compare SHA-256, `sysupgrade -T`, then `sysupgrade -n`.

For changes on the running device (test rules, reservations until the next build): set uci, `uci commit`, then **only** `fw4 reload` or `/etc/init.d/dnsmasq restart`. **No `/etc/init.d/network reload`** on this image – after a few such reloads with changed bridge VLANs `lan2` stopped receiving until a reboot. Whatever changes the bridge or the ports needs a reboot.

### Measured performance

Measured on 2026-11-03 on the image from PR head `e3d333fa67` (xfr and iperf3, 8 s per run, 1/4/8 streams):

| Path | Link | Result |
| --- | --- | --- |
| lan4 → lan3, switched | 2.5G | 2.35 Gbit/s both ways, 0 retransmits |
| lan5 → lan3, routed | 2.5G | 2.31–2.34 Gbit/s |
| wan → lan3, routed | 10G | 2.34 Gbit/s (the 2.5G peer is the limit) |
| sfp → lan3 with Cisco SFP-H10GB-CU1M= or MikroTik S+RJ10 | 10G | 2.2–2.35 Gbit/s; the S+RJ10 gets 1.5 W and runs at 48–55 °C |
| iperf3 to gruffi itself via wan or sfp | 10G | 9.39 or 9.31 Gbit/s from gruffi, 4–4.6 Gbit/s to gruffi (its CPU as the receiver) |
| two 10G clients between wan and sfp, one VLAN (tagged on sfp) | 10G | ~2.8 Gbit/s – bridged in software (no flow in the PPE) |

So the ports are clean up to what the peers can do; details in nixlab#94 and in the [report in the PR](https://github.com/openwrt/openwrt/pull/26215#issuecomment-6609794789).

### Known issues

- **Wi-Fi radios missing** (nixlab#93): both PCIe controllers get no link at boot (`PCIe link down, current LTSSM state: detect.quiet`, probe -110), so there are no radios. The first three boots after the flash had Wi-Fi, none since – cold, warm and after `sysupgrade -n`. Whether the module or the image is to blame is settled by a check with the GL firmware. Until then ap-og on lan8 provides the WLAN.
- **No `network reload`** (nixlab#94, see [Changes](#changes)).
- **lan4/lan5** received nothing on older images – fixed in the PR by the MDI swap patch (`967-54`); from head `e3d333fa67` on, `ethtool -S lanN` also shows the YT9224 hardware counters (`967-55`).
- **First boot after a power cut:** PPPoE often needs one or two PADO timeouts (35 s each) because the old session still hangs at the ISP; after a warm reboot PPPoE is up at once.

### Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| SSH to gruffi: "Permission denied (publickey)" with "communication with agent failed" | The 1Password SSH agent wants the key `gruffi.homelab.example` approved (again) – confirm the dialog in 1Password |
| "Host key verification failed" after an upgrade | `sysupgrade -n` creates new host keys; compare the new fingerprint with the one from the upgrade check and put it into the inventory (`hosts.gruffi.sshHostKeys`) |
| "No route to host" to LAN addresses from the Claude app's terminal pane | The app lacks the macOS "Local Network" permission; Terminal.app works |
| From gusto on a cable into the server network "Connection refused" although the peer runs | `netbird down` removes the server network's route including the direct route over the cable; traffic then goes via gruffi, which rejects forwards within one zone. After `netbird down`, switch the network interface off and on once |
| A USB adapter only does ~300 Mbit/s | It is attached at USB 2.0 (`ioreg -r -c IOUSBHostDevice -l -w0`, `UsbLinkSpeed` = 480000000) – another cable or straight into the Mac |
| No DHCP in a network | `grep dhcp-range /var/etc/dnsmasq.conf.*` – missing ranges mean `dhcpv4=server` is missing |

## Inventory

`inventory.json` lists every machine of the lab, whether this flake configures it or not: what kind of device it is (vendor, model, serial), where it stands, how that place reaches the internet, what it runs on or is built into, where its power comes from, how its disk gets unlocked after a reboot, its networks, interfaces and addresses, and its SSH host keys. On top of the machines: the services they run and the ones bought from outside, what each service needs, where its data is backed up to, and the providers and contracts behind hosts, lines and services. These are the facts a NixOS config does not hold. Today the host keys are used: every host's known_hosts comes from here, and `nix flake check` ties them to the age keys in `.sops.yaml`. Later the rest is meant for grouping in the topology and for alert dependencies (an uplink is down, so don't page for every host behind it).

What it holds today is drawn on the [lab map](#lab-map): every host and every service by site, with clickable dependencies.

| File | Role |
| --- | --- |
| `inventory.json` | The data. JSON, so Nix (`builtins.fromJSON`) and OpenTofu (`jsondecode`) can both read it without help. |
| `inventory.nix` | Format (`spec`), validation, derived view, JSON Schema generator. Exposed as `lib.inventory` in `flake.nix`. |
| `inventory.schema.json` | JSON Schema for the editor (completion, hover help, inline errors). Generated, never edited. |
| `tests/inventory.nix` | Tests for the validator: a complete example inventory and one case per rule. |
| `software.nix` | What the services run, read from the host configurations (`lib.software`, `just services`). |
| `flake.nix` | `lib.inventory`, the checks, and `programs.ssh.knownHosts` for every host (NixOS and nix-darwin). |

Rule of thumb for what goes in: **only what cannot be derived from a config.** OS, architecture, CPU/RAM, mesh address and exporters stay out; `topology.nix` reads those from `nixosConfigurations`. A service's version, license and language are read from its package, not written down. What a service *needs* and where its data *should* go is intent, not config – that is in here (`dependsOn`, `backup`). Every relation is stored in **one direction only**; the reverse is derived, so the two cannot disagree.

### Structure

Eight sections, each an object of entries keyed by id. Ids are lower-case letters, digits and dashes (usable unchanged as Graphviz node or label values).

```
owners    ◄──────── hosts.owner
providers ◄──────── uplinks.provider, sites.provider, services.provider, contracts.provider
contracts ◄──────── hosts.contracts[], uplinks.contracts[], services.contracts[]
uplinks   ◄──────── sites.uplinks[]
sites     ◄──────── hosts.site, networks.site
networks  ◄──────── hosts.interfaces.<name>.network
hosts     ◄──────── hosts.runsOn / inside / power / manages[] / unlock.tang[], networks.dhcpServer, services.hosts[]
services  ◄──────── services.dependsOn[] / uses[] / endpoints[].via / backup[].to
```

A `"$schema": "./inventory.schema.json"` key at the top is allowed and ignored; it tells the editor where the schema is.

#### owners

Who administers a device: it decides whom to call and what may be changed.

All fields with type, default and meaning: [Inventory schema → owners](#owners-1).

#### uplinks

An internet line. Several sites may share one (rarely), one site may have several (primary and backup).

All fields with type, default and meaning: [Inventory schema → uplinks](#uplinks-1).

All fields are optional, so a line can be entered before its details are known.

#### sites

A place where devices stand.

All fields with type, default and meaning: [Inventory schema → sites](#sites-1).

#### hosts

Every device with an address that matters: servers, VMs, routers, APs, KVMs, PDUs, appliances.

All fields with type, default and meaning: [Inventory schema → hosts](#hosts-2).

##### Kinds

| Kind | For |
| --- | --- |
| `server` | Physical machine running services |
| `hypervisor` | Physical machine running VMs/containers for others |
| `vm`, `container` | Virtual; the only kinds that may have `runsOn` |
| `router`, `switch`, `ap` | Network (`ap` = WLAN access point) |
| `pdu`, `ups` | Power |
| `kvm` | IP-KVM, external or as a card inside its host; the only kind that may have `manages` |
| `nas`, `workstation`, `laptop` | As named |
| `phone`, `tablet`, `watch` | Mobile devices: iPhone, iPad, Apple Watch; usually with `availability: intermittent` |
| `appliance` | Anything else with an address: Apple TV, printer, … |

Whether a host is virtual follows from `kind` (`vm`, `container`) – not from `runsOn`. A rented VM is a `vm` without `runsOn`: the provider's hypervisor is not in the inventory.

#### networks

A layer-2 network with its IPv4 prefix: the home LAN, a VLAN in the hackerspace.

All fields with type, default and meaning: [Inventory schema → networks](#networks-1).

A network without any interface is allowed – it can be entered before its devices are.

#### providers

A company or club the lab depends on: an ISP, a hoster, a service bought from outside, the hackerspace.

All fields with type, default and meaning: [Inventory schema → providers](#providers-1).

#### contracts

What is paid to a provider. One provider may have several – two VMs and an extra IPv4 at one hoster are three contracts. Hosts, lines and services name their contracts (`contracts: [...]`); what a contract covers is derived.

All fields with type, default and meaning: [Inventory schema → contracts](#contracts-1). The cost is in whole cents per month, per year – with the month it is charged in – or once, in its own currency; totals are kept per currency and never converted.

Customer and contract numbers do **not** go into `inventory.json`: they are in `inventory.secrets.yaml` (sops, workstation and admin key), keyed by contract id. Nothing reads that file automatically.

```yaml
realtox-grammi:
  customer: "…"
  contract: "…"
```

#### services

What the hosts run, and what is bought from outside. Per-host plumbing (sshd, exporters, vmagent, Vector, CrowdSec, the mesh client) is not a service here – it is the same on every host and lives in the modules.

All fields with type, default and meaning: [Inventory schema → services](#services-1).

**Dependencies.** `dependsOn` and every `via` are the hard ones: together they must be free of cycles, and a service may not hard-depend on a less critical one (a `core` service on a `lab` one) – raise the other or move it to `uses`. `uses` is not part of the chain: when Pocket ID is gone, NetBird keeps its tunnels and only refuses new logins.

**Backups.** A copy counts as *off-host* when its target runs on none of the service's own hosts, or is a service from outside. A `stateful` service on hosts without an off-host copy is not an error but is listed in `gaps` – local snapshots on the same disk are no backup.

### Interfaces

`hosts.<id>.interfaces` maps interface names to their data. The name is what the OS calls it (`eno1`, `wlp2s0f0`, `en0`); for an appliance any label (`lan`, `wan`). A VLAN interface on a trunk (`eno1.20`) is an entry of its own; its VLAN id comes from its network.

```json
"interfaces": {
  "eno1":    { "mac": "52:54:00:12:34:56", "medium": "ethernet", "speed": 10000,
               "connector": "sfp-plus", "module": { "kind": "mm", "standard": "10gbase-sr" }, "linkLocal": "eui64",
               "network": "lan", "ipv4": { "mode": "reserved", "address": "192.0.2.10" } },
  "eno1.20": { "network": "iot", "linkLocal": "fe80::1234", "ipv4": { "mode": "dhcp" } }
}
```

All fields with type, default and meaning: [Inventory schema → hosts](#hosts-2).

**Link-local.** Only with EUI-64 does the address follow from the MAC (`fe80::` + MAC with the U/L bit flipped and `ff:fe` in the middle); the derived `ipv6LinkLocal` is computed then. Many systems use `stable-privacy` instead (RFC 7217: stable, but not computable), macOS and tvOS do not derive it from the MAC either. When the address is stable and known, enter it directly (`"fe80::…"`); `just inventory-collect` does exactly that when it does not match EUI-64. `eui64` needs a `mac`; with a *locally administered* Wi-Fi MAC (private Wi-Fi address) it is an error, because that MAC – and with it the address – is usually random. A locally administered Ethernet MAC is fine (QEMU's `52:54:00:…` is one).

**Link.** What an interface can do at most, not what it negotiates – that comes from the metrics (`node_network_speed_bytes`), see [Monitoring → Alerting](#alerting). Ethernet: `speed` in Mbit/s (`1000`, `2500`, `10000` …, only the usual steps), `connector` (`rj45`, `sfp`, `sfp-plus`, `sfp28`, `qsfp-plus`, `qsfp28`), and for a cage `module`: `kind` (`dac`/`aoc` a fixed cable, `sm`/`mm` a transceiver for singlemode/multimode fibre, `copper` an RJ45 transceiver) and optionally the `standard` printed on it (`10gbase-sr`, `1000base-lx` …). `speed` is what works with what is plugged in: at most what the connector and the standard carry. The standard fixes the kind (SR/SX/LRM multimode, LR/ER/BX singlemode, `-t` copper; 1000BASE-LX both, with a mode-conditioning cord over multimode); a DAC/AOC has none. Wi-Fi: `wifiStandard` (`wifi4` … `wifi7`, `wifi6e` on its own). All optional – filled in for our own servers and routers, not for VMs and appliances.

**IPv4 – `ipv4.mode`:**

| Mode | Meaning | Rules |
| --- | --- | --- |
| `reserved` | Fixed DHCP lease by MAC (reservation on `dhcpServer`) | `address` and `mac` required; the network needs a `dhcpServer`. MAC not looked up yet: the placeholder `aa:bb:cc:dd:ee:ff` - never passed on (`mac` null in the derived view, not in `reservations`), listed under `pending` |
| `static` | Configured on the device itself | `address` required; outside `dhcpPool` |
| `dhcp` | Dynamic | no `address` |

Every `address` lies inside the network's `ipv4` prefix, is neither network nor broadcast address (except /31, /32) and occurs once per network. A network without `ipv4` cannot take addresses.

**IPv6** is in here only as link-local and as a fixed prefix per network: DHCPv6 reservations hang on the DUID, not the MAC, and an ISP prefix (SLAAC) changes.

### SSH host keys

`sshHostKeys` holds a device's public host keys – for managed and unmanaged devices alike – as `"<type> <base64>"` without the comment: `ssh-ed25519`, `ecdsa-sha2-nistp256/384/521` or `ssh-rsa`. One ed25519 key is enough; others only when the device has no ed25519 (Dropbear, KVMs). Checked: the format, that the key data matches its type (the base64 starts with the encoded type name), and that no key occurs twice – a cloned VM that kept its host key would show up that way.

Where they go:

| Consumer | How |
| --- | --- |
| Every NixOS host and zorlock | `programs.ssh.knownHosts` from `lib.inventory.knownHosts` (in `flake.nix`, the module `inventoryKnownHosts` in every host's list). Deploys and ursalia's unattended push to cuckoosegg need no trust-on-first-use |
| gusto (workstation) | `programs.ssh.knownHosts` like every host – `/etc/ssh/ssh_known_hosts` after the next `just mac-switch` |
| A workstation outside this repo | `just known-hosts` writes `~/.ssh/known_hosts.nixlab`; ssh reads it with `UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts.nixlab` under `Host *` in `~/.ssh/config` |
| `.sops.yaml` | `checks.inventory-sops`: for every managed host, `ssh-to-age` of its ed25519 key must give the age recipient `&<host>` in `.sops.yaml`. Catches a host key that changed (reinstall, rotation) without `sops updatekeys`, and a mistyped key. Hosts without a key yet are skipped |

Names per key: the host's id, for managed hosts `<host>.peer.homelab.example` (the mesh name), and every fixed IPv4 address of its interfaces (`static`/`reserved`). One entry per key, named `<host>` or `<host>-<n>` with several keys.

### Collecting from the devices

`just inventory-collect` fetches what is tedious to type:

- **Managed hosts**, over the mesh (root, zorlock as `admin`):
    - host keys via `ssh-keyscan` (only the ed25519 one when there is one);
    - per interface name, MAC, `ethernet`/`wifi` and link-local – `eui64` when the address matches the MAC, otherwise the address itself. On Linux every interface with a device behind it (hardware or virtio; no `lo`, mesh, tunnels, bridges, veths), on macOS the hardware ports without Thunderbolt;
    - for hardware that is not virtual: `vendor`, `model`, `productId`, `serial`. On Linux from `/sys/class/dmi/id` (Lenovo: model from `product_version`, machine type from `product_name`; everybody else: model from `product_name`), on macOS from `system_profiler` (model as "Mac mini (M4, 16 GB)", the model identifier as `productId`). Placeholders like "To be filled by O.E.M." are dropped.
- **Unmanaged devices**: only host keys, at their first fixed IPv4 address – enter `network`/`ipv4` first.

| Call | Effect |
| --- | --- |
| `just inventory-collect` | All devices; **adds** only what is missing, a differing value is printed and kept |
| `just inventory-collect ursalia beryl` | Only these devices |
| `just inventory-collect --force ursalia` | Takes the device's value where it differs, and prints each value it overwrote |

A changed host key should be a decision, hence `--force` – best with the host named. Even `--force` never touches what the device does not report: `network`, `ipv4`, notes, and interfaces it no longer has (remove those by hand).

### Relations

| Field | Meaning | May point at | Derived reverse |
| --- | --- | --- | --- |
| `runsOn` | Virtualisation | `vm` → `hypervisor`; `container` → `hypervisor`, `server`, `nas`, `vm` | `guests` |
| `inside` | Physical installation (PCIe card, module) | any host | `contains` |
| `power` | Power supply | any host | `powers` |
| `manages` | Out-of-band access (on the KVM) | any host but itself | `managedBy` |
| `unlock.tang` | Tang server for NBDE | any host but itself | `tangClients` |
| `interfaces.*.network` | Network membership | a network at the host's site | `networks.<id>.interfaces` |
| `networks.dhcpServer` | DHCP for a network | a host with an interface in it | – |

`runsOn`, `inside` and `power` together form the dependency graph: what a host cannot work without. It must be free of cycles; the derived `upstream` of a host is its transitive closure. `runsOn` and `inside` exclude each other.

`inside` says nothing about power: whether a PCIe KVM card lives off its host's slot (standby power) or off PoE/USB is what `power` says. A card that only draws from the slot gets `"power"` set to its host. Then "host and KVM both gone" points at power or network, "host gone, KVM still there" at the OS – and the KVM is the way in.

### Disk unlock

```json
"unlock": { "methods": ["tpm", "nbde"], "threshold": 1, "tang": ["nas"], "fallback": "remote-ssh" }
```

All fields with type, default and meaning: [Inventory schema → hosts](#hosts-2).

| Case | `unlock` |
| --- | --- |
| Unencrypted | leave out |
| TPM, passphrase at the console as fallback | `{"methods": ["tpm"], "fallback": "console"}` |
| Only a human, over SSH (e.g. FileVault) | `{"methods": [], "fallback": "remote-ssh"}` |
| TPM **or** Tang | `{"methods": ["tpm", "nbde"], "tang": ["a"]}` |
| TPM **and** Tang (disk only unlocks in its own network) | `{"methods": ["tpm", "nbde"], "threshold": 2, "tang": ["a"]}` |
| Only Tang, two servers | `{"methods": ["nbde"], "tang": ["a", "b"], "fallback": "console"}` |

NBDE is a dependency of its own: a host that **needs** Tang (`nbde` without `tpm`, or `threshold` 2) only comes back once one of its Tang servers is up unattended itself. The validator follows these chains. Is there a host that would never come up without a human – two hosts that are each other's only Tang server, or a Tang server that itself waits at a passphrase prompt – that is an error. The derived `unattendedBoot` says per host whether it comes back after a reboot or power cut on its own.

Not checked: whether a Tang server actually runs Tang. That lives in its config, not here.

### Validation

`nix flake check` (or just the inventory part: `just inventory-test`) validates in three stages. Each stage only runs when the one before found nothing, so a typo does not turn into twenty follow-up errors. Every error names the path:

**1. Structure** – top level first, on its own, then every entry:

- only `$schema` and the eight sections at the top, all of them present
- valid ids and interface names, no unknown fields (catches typos), required fields present
- types, enums, minimums/maximums, formats (MAC, IPv4 address and prefix, IPv6 prefix, ULA /48, link-local, SSH key), no duplicates in lists
- references point at an existing entry of the right section

```
hosts.vps.critcality: unknown field (known: availability, contracts, criticality, inside, interfaces, kind, managed, manages, model, note, owner, power, productId, runsOn, serial, site, sshHostKeys, unlock, vendor)
hosts.nas.interfaces.eno1.mac: "52-54-00-12-34-56" is not a lower-case MAC address like aa:bb:cc:dd:ee:ff
hosts.app.runsOn: "pve2" is not in hosts
uplinks.fiber-home.asn: expected a whole number, got "AS64496"
```

**2. Rules between entries:**

- `runsOn` only for `vm`/`container` and only on an allowed kind; not together with `inside`
- `manages` only for `kvm`; nothing points at itself
- `runsOn`/`inside`/`power` without cycles
- `site` present or inheritable; an explicit `site` matches the inherited one
- every site has an uplink; no uplink, site or owner without use; IPv6 details of an uplink only with `ipv6`
- `unlock`: at least a method or a fallback; `threshold` ≤ number of methods; `tang` exactly when `nbde`
- `managed` agrees with `flake.nix`: every `nixosConfigurations`/`darwinConfigurations` entry is in here as managed, and every managed entry has a configuration
- hardware: `vendor`/`productId`/`serial` not on `vm`/`container`; no serial twice
- SSH keys: key data matches the type, no key on two devices
- interfaces: network at the host's site; `ipv4` needs a network, `address` according to the mode, inside the prefix, not network/broadcast, static outside the pool, unique per network; `reserved` needs `mac` and a `dhcpServer`; MAC unique and not multicast; `eui64` needs a MAC and no private Wi-Fi MAC; `speed`/`connector`/`module` only on ethernet, `wifiStandard` only on wifi; `speed` within connector and standard; `module` only in a cage, `kind` matching the standard, no standard on a DAC/AOC
- networks: prefix without host bits; pool inside the prefix, start ≤ end, only with `ipv4` and `dhcpServer`; `dhcpServer` at the site and with an interface in the network; VLAN id unique per site; `ipv6SubnetId` unique per site and inside the primary uplink's delegated prefix
- services: exactly one of `hosts`/`provider`; `package` only on managed hosts and not with `version`; no `core`/`service` service on an `intermittent` host; no reference to itself, nothing in both `dependsOn` and `uses`, no hard dependency on a less critical service; `dependsOn`/`via` without cycles; `via` with `proxy`, not with `loopback`; every `fqdn` once per port; `backup` only for `stateful`, `to` required with `restic`/`arq`, optional with `ha-backup`, not with the others, and at a `stateful` target; `contracts` only with `provider`
- contracts: `dueMonth` exactly with `year`; `renews` not before `since`; a contract named by a host, line or service is with that one's provider (a host: the provider of its site); no provider nothing refers to

```
hosts.app.runsOn: a vm cannot run on nas (kind nas; allowed: hypervisor)
hosts: runsOn/inside/power form a cycle through pve, ups1
hosts.laptop.managed: true, but flake.nix has no configuration of that name
hosts.router.interfaces.lan.ipv4.address: 192.0.2.150 is static but inside the DHCP pool of network lan
networks.lan.vlan: 20 is also used by networks.iot at site home
hosts.router.sshHostKeys[0]: same key as hosts.nas.sshHostKeys[0] - a cloned machine that kept its host key?
services.auth.dependsOn: docs is lab, less critical than this core service - raise it or move it to uses
services.proxy: a core service cannot run on laptop (availability intermittent) - make it lab or move it
services: dependsOn/via form a cycle through notes, proxy
hosts.vps.contracts: isp-fiber is with isp, the site dc with hoster
contracts.vps-plan.cost.dueMonth: required with period year - the month it is charged in
```

**3. Unlock chains** – see [Disk unlock](#disk-unlock):

```
hosts.nas.unlock: never unlocks unattended - none of its Tang servers (vps) comes up without a human
```

**Separately**, as its own check because it needs `ssh-to-age`: `checks.inventory-sops` (see [SSH host keys](#ssh-host-keys)).

```
hosts.cuckoosegg: host key gives age1z9rt…, .sops.yaml has age1z8uz… - host key changed without sops updatekeys, or a wrong key in inventory.json
```

The schema in `inventory.schema.json` only covers stage 1 (without references) and is there for the editor; the validation in `inventory.nix` is what counts.

### Derived view

`lib.inventory.inventory` (on the console: `just inventory`) is the validated inventory with everything derived. Every section gets its `id`; additionally:

| Section | Derived |
| --- | --- |
| `owners.<id>` | `hosts` – the hosts it administers |
| `uplinks.<id>` | `sites` – the sites on this line |
| `sites.<id>` | `hosts` – everything there, inherited sites included |
| `hosts.<id>` | `site` (effective, inherited along `runsOn`/`inside`), `virtual`, `uplinks` (of its site, primary first), `guests`, `contains`, `powers`, `managedBy`, `tangClients`, `upstream` (transitive, nearest first), `unattendedBoot`, `services` (running on it) |
| `hosts.<id>.interfaces.<name>` | `name`, `vlan` (from its network), `ipv6LinkLocal` (computed for `eui64`, as given for a fixed address, otherwise `null`) |
| `pending` | every placeholder MAC still to replace, every contract without `cost`; `just inventory-test` prints the list |
| `gaps` | allowed, but worth a look: `stateful` services without an off-host backup, contracts nothing refers to; printed by `just inventory-test` |
| `services.<id>` | `external` (has a `provider`), `sites` (of its hosts), `requires` (`dependsOn` + `via`), `upstream` (transitive over `requires`, nearest first), `upstreamHosts` (its hosts, those of its upstream, and what all of them run on / sit in / draw power from – the input for alert dependencies), `neededBy`, `usedBy`, `backup[].offsite`, `offsiteBackup` |
| `providers.<id>` | `services`, `contracts`, `sites`, `uplinks`, `affects` (what stops with it: services on hosts at a site it runs or behind lines that are all its, and everything that hard-depends on those or on its own services), `degrades` (services that only `use` them or what needs them), `monthly` (per currency) |
| `contracts.<id>` | `monthly` (a yearly amount divided by 12, rounded down to the cent; `null` for `once` or without cost), `covers` (`hosts`, `uplinks`, `services` naming it) |
| `costs` | `monthly` – the lab per month, per currency; `byMonth` – twelve entries, what is charged in each calendar month (monthly amounts every month, yearly ones in their `dueMonth`). One-off payments are left out |
| `networks.<id>` | `interfaces` – every interface in it (`host`, `interface`, `mac`, `address`, `mode`); `reservations` – what `dhcpServer` has to hand out by MAC (`host`, `interface`, `mac`, `address`), sorted by address; `ipv6SubnetHex` – `ipv6SubnetId` in hex (OpenWrt `ip6hint`); `ipv6Ula` – the network's `/64` in the site's `ipv6Ula` |

Besides `inventory`: `lib.inventory.knownHosts` (the `programs.ssh.knownHosts` value) and `lib.inventory.knownHostsFile` (the same as known_hosts text).

Optional fields are always present in the derived view: defaults filled in (`criticality`, `availability`, `unlock.threshold`), otherwise `null` or `[]`. A consumer never has to write `or`.

If the inventory is invalid, `inventory` throws with **all** errors at once; `lib.inventory.errors` is the list itself (empty when valid).

### Software view

`lib.software.services` (on the console: `just services`, everything with `just services --json`) follows every service's `package` path into the configurations of its hosts and reports what is there – nothing is written down, nothing is built:

| Field | Meaning |
| --- | --- |
| `name`, `version` | Of the package (the first host's; `perHost` has each host's) |
| `license` | SPDX ids from `meta.license` |
| `language` | Guessed from how it was built: `goModules` → Go, `cargoDeps` → Rust, the JS builders' caches → JavaScript, a `dist` output → Python, a C compiler in its stdenv → C/C++ (`languageGuessed` true), otherwise `null` (a static site) |
| `dependencies` | Direct dependencies as the package declares them (`name`, `version`): Python packages of a Python application, libraries of a C/C++ program. Go and Rust modules are fetched in one piece and do not show up – the SBOM per host has the full closure |
| `perHost` | The same per host, without dependencies – hosts on different pins differ here |

`checks.inventory-packages` fails when a `package` path leads to no package on one of the service's hosts (a renamed option, a host that lost the service). Unlike the other inventory checks it evaluates the hosts, so it is not part of `just inventory-test`.

**SBOM per host.** `just sbom [host …]` (without hosts: every managed host) writes the full runtime closure of what a host runs – `/run/current-system` – as CycloneDX (`sbom/<host>.cdx.json`), SPDX and CSV, made by sbomnix. It runs where the system is: on gusto itself, on the others over the mesh, pinned to the host's own nixpkgs (the first run fetches it there, about 180 MB, until the next GC); a Linux system cannot be read on the Mac. `sbom/` is ignored by git – the files change with every upgrade. Not in it: nixpkgs metadata such as licenses (sbomnix only has that for a flake reference, not for a running system – the services' licenses are in the software view) and the Go and Rust modules inside a package.

### Examples

The examples are the test inventory from `tests/inventory.nix`, written as JSON. It covers every field and relation.

**Rented VM** – virtual, the provider's hypervisor is not in the inventory:

```json
"vps": { "kind": "vm", "site": "dc", "owner": "lab", "managed": true, "criticality": "core" }
```

**VM on a hypervisor of others, which hangs on a UPS** – `site` is inherited from `pve`:

```json
"pve":  { "kind": "hypervisor", "site": "home", "owner": "club", "managed": false, "power": "ups1" },
"ups1": { "kind": "ups", "site": "home", "owner": "lab", "managed": false },
"app":  { "kind": "vm", "runsOn": "pve", "owner": "lab", "managed": true,
          "unlock": { "methods": ["nbde"], "tang": ["nas"] } }
```

Derived for `app`: `site` = `home`, `upstream` = `["pve", "ups1"]`, `unattendedBoot` = `true` (via the chain app → nas → vps).

**NAS with TPM and Tang required together, plus a PCIe KVM card inside it:**

```json
"nas": { "kind": "nas", "vendor": "Example Corp", "model": "Example NAS", "productId": "EX-1000",
         "serial": "NAS0001", "site": "home", "owner": "lab", "managed": true,
         "unlock": { "methods": ["tpm", "nbde"], "threshold": 2, "tang": ["vps"] } },
"kvmcard": { "kind": "kvm", "inside": "nas", "power": "nas", "manages": ["nas"],
             "owner": "lab", "managed": false }
```

Derived for `nas`: `contains`, `powers` and `managedBy` = `["kvmcard"]`, `tangClients` = `["app"]`.

**Laptop** – offline is normal, only a human unlocks it:

```json
"laptop": { "kind": "laptop", "site": "home", "owner": "lab", "managed": true,
            "availability": "intermittent", "unlock": { "methods": [], "fallback": "console" } }
```

**Networks, a reservation and a router** – the router hands out `nas`'s address by MAC; its own address is static, outside the pool:

```json
"networks": {
  "lan": { "name": "Home LAN", "site": "home", "ipv4": "192.0.2.0/24", "ipv6": "2001:db8:1::/64",
           "dhcpServer": "router", "dhcpPool": { "start": "192.0.2.100", "end": "192.0.2.199" } },
  "iot": { "name": "IoT", "site": "home", "vlan": 20, "ipv4": "198.51.100.0/24" }
},
"router": { "kind": "router", "site": "home", "owner": "lab", "managed": false,
            "sshHostKeys": ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI…"],
            "interfaces": { "lan": { "network": "lan", "ipv4": { "mode": "static", "address": "192.0.2.1" } } } }
```

Derived: `networks.lan.reservations` = `nas/eno1` (192.0.2.10) and `app/ens18` (192.0.2.11); `nas.interfaces.eno1.ipv6LinkLocal` = `fe80::5054:ff:fe12:3456`; known_hosts names for `nas` = `nas`, `nas.peer.example`, `192.0.2.10`.

**Site with primary line and LTE backup:**

```json
"uplinks": {
  "fiber-home": { "provider": "isp", "contracts": ["isp-fiber"], "asn": 64496, "medium": "fiber",
                  "bandwidth": { "down": 1000, "up": 500 }, "ipv4": "cgnat", "ipv6": true },
  "lte-backup": { "medium": "lte" }
},
"sites": {
  "home": { "city": "Exampletown", "kind": "residential", "uplinks": ["fiber-home", "lte-backup"] }
}
```

**A provider with two contracts on one VM, a yearly one charged in March:**

```json
"providers": { "hoster": { "name": "Example Hosting", "url": "https://hosting.example" } },
"contracts": {
  "vps-plan": { "provider": "hoster", "product": "VPS M", "since": "2025-03-01", "renews": "2027-03-01",
                "cost": { "amount": 12000, "currency": "EUR", "period": "year", "dueMonth": 3 } },
  "vps-ipv4": { "provider": "hoster", "cost": { "amount": 150, "currency": "EUR", "period": "month" } }
},
"vps": { "kind": "vm", "site": "dc", "contracts": ["vps-plan", "vps-ipv4"], … }
```

Derived: `contracts.vps-plan.monthly` = `1000`, `providers.hoster.monthly` = `{"EUR": 1150}`; in `costs.byMonth` March carries the 120.00.

**Services: a login, a reverse proxy, something behind it, a backup target and mail from outside:**

```json
"auth":    { "name": "Login", "hosts": ["vps"], "criticality": "core", "package": "services.auth.package",
             "endpoints": [{ "fqdn": "auth.example.org", "exposure": "public" }], "uses": ["mail"],
             "data": "stateful", "backup": [{ "method": "restic", "to": "storage" }] },
"proxy":   { "name": "Reverse proxy", "hosts": ["vps"], "criticality": "core", "data": "stateless", … },
"docs":    { "name": "Docs", "hosts": ["app", "nas"], "criticality": "lab", "uses": ["auth"], "data": "stateless",
             "endpoints": [{ "fqdn": "docs.example.org", "exposure": "proxy", "via": "proxy" }] },
"notes":   { "name": "Notes", "hosts": ["app"], "dependsOn": ["auth"], "data": "stateful",
             "backup": [{ "method": "pgdump" }, { "method": "restic", "to": "storage" }] },
"storage": { "name": "S3", "hosts": ["nas"], "version": "2.1", "data": "stateful", "backup": [{ "method": "btrbk" }] },
"mail":    { "name": "Mail", "provider": "mail", "contracts": ["mail-plan"], "data": "stateful" }
```

Derived: `docs.upstreamHosts` = `app, nas, pve, ups1, vps`; `auth.neededBy` = `notes`, `auth.usedBy` = `docs`; `providers.mail.degrades` = `auth`; `gaps` lists `storage` (only btrbk on its own disk).

**Reading it elsewhere.** In Nix (another flake output, a module via `specialArgs`):

```nix
self.lib.inventory.inventory.hosts.app.upstream   # [ "pve" "ups1" ]
```

In OpenTofu – the raw data, without derived values and without validation (that stays with `nix flake check`):

```hcl
locals {
  inventory = jsondecode(file("${path.module}/../../inventory.json"))
  servers   = [for id, h in local.inventory.hosts : id if h.managed]
}
```

### Tests

`tests/inventory.nix` holds a complete, fictional inventory (the examples above) and 98 cases. Each case changes exactly one thing and states the expected errors – exact wording and order – or, for valid variants, values of the derived view. A case also fails if a broken inventory does not make `.inventory` throw.

| Group | Covers |
| --- | --- |
| valid | Base inventory with all derived values; container on a VM; Tang loop broken by `threshold` 1; flake check switched off |
| uplinks | IPv6 prefix length out of range, IPv6 details without IPv6 |
| structure | Unknown/missing top-level key, typo in a field, enum, required field, type, minimum, dangling and wrong-section references, invalid id, duplicates |
| rules | `runsOn` on non-virtual and on a wrong kind, `runsOn` + `inside`, `manages` outside a KVM and on itself, self reference, cycle, missing/non-inheritable/contradicting `site`, site without uplink, unused entries, inventory ≠ flake |
| unlock | No way to unlock, `threshold` too high or without methods, `nbde` without `tang` and the reverse, own Tang server, Tang loop, Tang server waiting for a human |
| hardware | `vendor`/`serial` on a VM, `model` on a VM allowed, serial twice; derived hardware fields and defaults |
| SSH keys | Wrong format, with comment, key data of another type, same key on two hosts; derived known_hosts entries and file |
| interfaces | MAC format, interface name, link-local value, MAC twice, multicast MAC, `eui64` from a private Wi-Fi MAC and without MAC, network at another site, `ipv4` without network, address per mode, reserved without MAC or DHCP server, address outside/broadcast/in pool/without prefix/twice; derived link-local (EUI-64 of a QEMU MAC, fixed, random) and VLAN |
| networks | Prefix format, VLAN range and duplicate per site (same id at another site allowed), host bits, pool outside/backwards/without server, DHCP server without interface or at another site, subnet id beyond the delegated prefix and twice per site, ULA format; derived reservations, subnet hex and ULA `/64` |
| services | Neither/both of `hosts` and `provider`, empty `hosts`, `package` with `version`/without hosts/on an unmanaged host, critical service on an intermittent host (a `lab` one allowed), self references, `uses` doubling `dependsOn`, weaker hard dependency, cycles over `dependsOn` and `via`, endpoint rules and duplicate names, domain format, every backup rule; derived dependencies, upstream hosts, off-host backups, `gaps` |
| providers, contracts | Contract with the wrong provider on a host, line and service, on a line without provider, on a service on hosts; `dueMonth`, `renews` before `since`, amount not in whole cents, date format; unused and unknown provider; derived totals per currency and per month, `pending` for a missing cost |

```
just inventory-test
```

builds `checks.<system>.inventory` (the real file is valid), `inventory-tests` (all cases pass), `inventory-schema` (schema fresh), `inventory-diagram` (the [schema diagram](#all-fields-at-a-glance) fresh) and `inventory-sops` (host keys ↔ `.sops.yaml`). On failure the message lists each failing case with "want" and "got".

**A new rule** gets a case in the same commit: change one thing in `base` with `set`/`del`, paste the exact message. **Changed wording** of an error fails the tests – adjust case and this page together.

### Workflows

| What | Steps |
| --- | --- |
| New host / device | Add an entry to `inventory.json` (for a flake host `"managed": true` – otherwise `nix flake check` fails anyway), `just inventory-collect`, `network`/`ipv4` by hand, `just inventory-test` |
| Host key changed (reinstall) | `just inventory-collect --force <host>`, `.sops.yaml` + `sops updatekeys` (see [Rotate keys](#rotate-keys)), deploy, `just known-hosts` |
| New DHCP reservation | Interface with `mac`, `network`, `ipv4.mode: reserved` + `address`; the list for the router: `networks.<id>.reservations` in `just inventory` |
| Fill in a line's details | Fields in `uplinks.<id>`, nothing else to do |
| New service | Entry in `services` with `hosts` (and `package` on a managed host) or `provider`, `endpoints`, `dependsOn`/`uses`, `data`, `backup`; `just inventory-test` – a missing off-host backup shows up under "worth a look" |
| New contract | Entry in `contracts`, the id into `contracts` of the host, line or service it pays for; customer/contract number into `inventory.secrets.yaml` (`sops inventory.secrets.yaml`) |
| New field or kind | `spec` in `inventory.nix`, then `just inventory-schema` and `just inventory-diagram`, a test case in `tests/inventory.nix`, this page (de/en); `docs/inventory-example.json` if the [schema page](#inventory-schema)'s example should show it |
| Look at it | `just inventory` |

## Inventory schema

`inventory.json` follows a fixed format: eight sections, each an object of entries keyed by id, every field with a type, some of them references into another section. This page is the complete reference of that format – every field with its type, whether it is required, its default and its meaning, an example per section and a whole example inventory. *What* the inventory is for, how it is validated and what is derived from it is on [Inventory](#inventory).

The format is defined once, in `spec` in `inventory.nix`. Everything on this page that describes a field is generated from it, so it cannot drift from what the validator checks:

| Generated | From | Kept fresh by |
| --- | --- | --- |
| `inventory.schema.json` – JSON Schema for the editor | `spec` | `just inventory-schema`, `checks.inventory-schema` |
| The field tables below | `inventory.schema.json` | the docs build (`docs/gen-reference.py`) |
| The diagram of all fields | `spec` | `just inventory-diagram`, `checks.inventory-diagram` |
| The examples below | `docs/inventory-example.json` | the docs build; a test (`tests/inventory.nix`) keeps the file valid |

### Overview

The arrows point from the field that holds the reference to the section it names. A section's references into itself are noted in its box (↺). Each box leads to its section below.

<figure class="nx-diagram">
<svg viewBox="0 0 680 416" role="img" aria-label="The eight sections of inventory.json and the fields that refer from one to another" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-purple rect{fill:#eeedfe;stroke:#534ab7}.nx-purple .nx-t{fill:#26215c}.nx-purple .nx-s{fill:#534ab7}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}</style>
<path class="nx-line" d="M260 48 H180"/><path class="nx-line" d="M186 44 L180 48 L186 52"/>
<text class="nx-s" x="220" y="42" text-anchor="middle">owner</text>
<path class="nx-line" d="M500 40 H420"/><path class="nx-line" d="M426 36 L420 40 L426 44"/>
<text class="nx-s" x="460" y="34" text-anchor="middle">hosts[]</text>
<path class="nx-line" d="M420 66 H450 V198 H500"/><path class="nx-line" d="M494 194 L500 198 L494 202"/>
<text class="nx-s" x="456" y="130" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M340 76 V170"/><path class="nx-line" d="M336 164 L340 170 L344 164"/>
<text class="nx-s" x="346" y="128" text-anchor="start">site</text>
<path class="nx-line" d="M290 76 V130 H120 V170"/><path class="nx-line" d="M116 164 L120 170 L124 164"/>
<text class="nx-s" x="205" y="147" text-anchor="middle">interfaces.*.network</text>
<path class="nx-line" d="M80 170 V110 H275 V76"/><path class="nx-line" d="M271 82 L275 76 L279 82"/>
<text class="nx-s" x="178" y="104" text-anchor="middle">dhcpServer</text>
<path class="nx-line" d="M180 198 H260"/><path class="nx-line" d="M254 194 L260 198 L254 202"/>
<text class="nx-s" x="220" y="192" text-anchor="middle">site</text>
<path class="nx-line" d="M300 226 V270 H100 V320"/><path class="nx-line" d="M96 314 L100 320 L104 314"/>
<text class="nx-s" x="200" y="264" text-anchor="middle">uplinks[]</text>
<path class="nx-line" d="M340 226 V320"/><path class="nx-line" d="M336 314 L340 320 L344 314"/>
<text class="nx-s" x="346" y="290" text-anchor="start">provider</text>
<path class="nx-line" d="M180 348 H260"/><path class="nx-line" d="M254 344 L260 348 L254 352"/>
<text class="nx-s" x="220" y="342" text-anchor="middle">provider</text>
<path class="nx-line" d="M580 226 V348 H420"/><path class="nx-line" d="M426 344 L420 348 L426 352"/>
<text class="nx-s" x="574" y="290" text-anchor="end">provider</text>
<path class="nx-line" d="M560 76 V170"/><path class="nx-line" d="M556 164 L560 170 L564 164"/>
<text class="nx-s" x="566" y="128" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M660 48 H670 V364 H420"/><path class="nx-line" d="M426 360 L420 364 L426 368"/>
<text class="nx-s" x="540" y="380" text-anchor="middle">provider</text>
<path class="nx-line" d="M100 376 V400 H610 V226"/><path class="nx-line" d="M606 232 L610 226 L614 232"/>
<text class="nx-s" x="360" y="395" text-anchor="middle">contracts[]</text>
<a data-target="owners" tabindex="0" role="link" class="nx-gray"><rect x="20" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="44" text-anchor="middle">owners</text><text class="nx-s" x="100" y="62" text-anchor="middle">who administers</text></a>
<a data-target="hosts" tabindex="0" role="link" class="nx-gray"><rect x="260" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="44" text-anchor="middle">hosts</text><text class="nx-s" x="340" y="62" text-anchor="middle">↺ runsOn, power …</text></a>
<a data-target="services" tabindex="0" role="link" class="nx-purple"><rect x="500" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="44" text-anchor="middle">services</text><text class="nx-s" x="580" y="62" text-anchor="middle">↺ dependsOn, uses …</text></a>
<a data-target="networks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="194" text-anchor="middle">networks</text><text class="nx-s" x="100" y="212" text-anchor="middle">layer 2 + prefix</text></a>
<a data-target="sites" tabindex="0" role="link" class="nx-gray"><rect x="260" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="194" text-anchor="middle">sites</text><text class="nx-s" x="340" y="212" text-anchor="middle">where things stand</text></a>
<a data-target="contracts" tabindex="0" role="link" class="nx-coral"><rect x="500" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="194" text-anchor="middle">contracts</text><text class="nx-s" x="580" y="212" text-anchor="middle">what is paid</text></a>
<a data-target="uplinks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="344" text-anchor="middle">uplinks</text><text class="nx-s" x="100" y="362" text-anchor="middle">internet lines</text></a>
<a data-target="providers" tabindex="0" role="link" class="nx-coral"><rect x="260" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="344" text-anchor="middle">providers</text><text class="nx-s" x="340" y="362" text-anchor="middle">companies, clubs</text></a>
</svg>
</figure>

### All fields at a glance

Every section with all its fields – **bold** ones are required, nested objects are spelled out (`unlock.methods`, `endpoints[].fqdn`, `interfaces.<name>.mac`), and every reference field has its arrow (references inside a section only in the type column: `→ hosts`).

<figure class="nx-diagram nx-diagram-wide">
<svg
 viewBox="0.00 0.00 1389.00 1097.75" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 1093.75)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1243.75,-706 1110.75,-706 1110.75,-473.5 1243.75,-473.5 1243.75,-706"/>
<polygon fill="#f1efe8" stroke="none" points="1110.75,-473.5 1110.75,-706 1243.75,-706 1243.75,-473.5 1110.75,-473.5"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1110.75,-686.75 1110.75,-706 1243.75,-706 1243.75,-686.75 1110.75,-686.75"/>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-686.75 1110.75,-706 1243.75,-706 1243.75,-686.75 1110.75,-686.75"/>
<text text-anchor="start" x="1155.88" y="-693.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-667.5 1110.75,-686.75 1183.25,-686.75 1183.25,-667.5 1110.75,-667.5"/>
<text text-anchor="start" x="1114.75" y="-673.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-667.5 1183.25,-686.75 1243.75,-686.75 1243.75,-667.5 1183.25,-667.5"/>
<text text-anchor="start" x="1187.25" y="-673.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-648.25 1110.75,-667.5 1183.25,-667.5 1183.25,-648.25 1110.75,-648.25"/>
<text text-anchor="start" x="1114.75" y="-655" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-648.25 1183.25,-667.5 1243.75,-667.5 1243.75,-648.25 1183.25,-648.25"/>
<text text-anchor="start" x="1187.25" y="-654" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-629 1110.75,-648.25 1183.25,-648.25 1183.25,-629 1110.75,-629"/>
<text text-anchor="start" x="1114.75" y="-635.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-629 1183.25,-648.25 1243.75,-648.25 1243.75,-629 1183.25,-629"/>
<text text-anchor="start" x="1187.25" y="-634.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-609.75 1110.75,-629 1183.25,-629 1183.25,-609.75 1110.75,-609.75"/>
<text text-anchor="start" x="1114.75" y="-615.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-609.75 1183.25,-629 1243.75,-629 1243.75,-609.75 1183.25,-609.75"/>
<text text-anchor="start" x="1187.25" y="-615.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-590.5 1110.75,-609.75 1183.25,-609.75 1183.25,-590.5 1110.75,-590.5"/>
<text text-anchor="start" x="1114.75" y="-597.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-590.5 1183.25,-609.75 1243.75,-609.75 1243.75,-590.5 1183.25,-590.5"/>
<text text-anchor="start" x="1187.25" y="-596.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-571.25 1110.75,-590.5 1183.25,-590.5 1183.25,-571.25 1110.75,-571.25"/>
<text text-anchor="start" x="1114.75" y="-577" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-571.25 1183.25,-590.5 1243.75,-590.5 1243.75,-571.25 1183.25,-571.25"/>
<text text-anchor="start" x="1187.25" y="-577" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-552 1110.75,-571.25 1183.25,-571.25 1183.25,-552 1110.75,-552"/>
<text text-anchor="start" x="1114.75" y="-557.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-552 1183.25,-571.25 1243.75,-571.25 1243.75,-552 1183.25,-552"/>
<text text-anchor="start" x="1187.25" y="-557.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-532.75 1110.75,-552 1183.25,-552 1183.25,-532.75 1110.75,-532.75"/>
<text text-anchor="start" x="1114.75" y="-538.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-532.75 1183.25,-552 1243.75,-552 1243.75,-532.75 1183.25,-532.75"/>
<text text-anchor="start" x="1187.25" y="-538.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-512 1110.75,-532.75 1183.25,-532.75 1183.25,-512 1110.75,-512"/>
<text text-anchor="start" x="1114.75" y="-519.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-512 1183.25,-532.75 1243.75,-532.75 1243.75,-512 1183.25,-512"/>
<text text-anchor="start" x="1187.25" y="-519.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-492.75 1110.75,-512 1183.25,-512 1183.25,-492.75 1110.75,-492.75"/>
<text text-anchor="start" x="1114.75" y="-498.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-492.75 1183.25,-512 1243.75,-512 1243.75,-492.75 1183.25,-492.75"/>
<text text-anchor="start" x="1187.25" y="-498.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-473.5 1110.75,-492.75 1183.25,-492.75 1183.25,-473.5 1110.75,-473.5"/>
<text text-anchor="start" x="1114.75" y="-479.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-473.5 1183.25,-492.75 1243.75,-492.75 1243.75,-473.5 1183.25,-473.5"/>
<text text-anchor="start" x="1187.25" y="-479.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node5" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1381,-308.88 1308.75,-308.88 1308.75,-212.63 1381,-212.63 1381,-308.88"/>
<polygon fill="#f1efe8" stroke="none" points="1308.75,-212.63 1308.75,-308.88 1381,-308.88 1381,-212.63 1308.75,-212.63"/>
<g id="a_node5_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1308.75,-289.63 1308.75,-308.88 1381,-308.88 1381,-289.63 1308.75,-289.63"/>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-289.63 1308.75,-308.88 1381,-308.88 1381,-289.63 1308.75,-289.63"/>
<text text-anchor="start" x="1322.75" y="-296.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node5_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-270.38 1308.75,-289.63 1349,-289.63 1349,-270.38 1308.75,-270.38"/>
<text text-anchor="start" x="1312.75" y="-276.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-270.38 1349,-289.63 1381,-289.63 1381,-270.38 1349,-270.38"/>
<text text-anchor="start" x="1353" y="-276.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-251.13 1308.75,-270.38 1349,-270.38 1349,-251.13 1308.75,-251.13"/>
<text text-anchor="start" x="1312.75" y="-257.88" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-251.13 1349,-270.38 1381,-270.38 1381,-251.13 1349,-251.13"/>
<text text-anchor="start" x="1353" y="-256.88" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-231.88 1308.75,-251.13 1349,-251.13 1349,-231.88 1308.75,-231.88"/>
<text text-anchor="start" x="1312.75" y="-237.63" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-231.88 1349,-251.13 1381,-251.13 1381,-231.88 1349,-231.88"/>
<text text-anchor="start" x="1353" y="-237.63" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-212.63 1308.75,-231.88 1349,-231.88 1349,-212.63 1308.75,-212.63"/>
<text text-anchor="start" x="1312.75" y="-218.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node5_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-212.63 1349,-231.88 1381,-231.88 1381,-212.63 1349,-212.63"/>
<text text-anchor="start" x="1353" y="-218.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1243.75,-522.38C1344.42,-522.38 1212.49,-310.44 1301.35,-299.68"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.22,-301.79 1307.09,-299.35 1300.98,-297.59 1301.22,-301.79"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="474.25,-812.25 239.25,-812.25 239.25,-67.25 474.25,-67.25 474.25,-812.25"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-67.25 239.25,-812.25 474.25,-812.25 474.25,-67.25 239.25,-67.25"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-793 239.25,-812.25 474.25,-812.25 474.25,-793 239.25,-793"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-793 239.25,-812.25 474.25,-812.25 474.25,-793 239.25,-793"/>
<text text-anchor="start" x="344" y="-799.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-773.75 239.25,-793 404,-793 404,-773.75 239.25,-773.75"/>
<text text-anchor="start" x="243.25" y="-779.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-773.75 404,-793 474.25,-793 474.25,-773.75 404,-773.75"/>
<text text-anchor="start" x="408" y="-779.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-753 239.25,-773.75 404,-773.75 404,-753 239.25,-753"/>
<text text-anchor="start" x="243.25" y="-759.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-753 404,-773.75 474.25,-773.75 474.25,-753 404,-753"/>
<text text-anchor="start" x="408" y="-760.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-733.75 239.25,-753 404,-753 404,-733.75 239.25,-733.75"/>
<text text-anchor="start" x="243.25" y="-739.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-733.75 404,-753 474.25,-753 474.25,-733.75 404,-733.75"/>
<text text-anchor="start" x="408" y="-739.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-713 239.25,-733.75 404,-733.75 404,-713 239.25,-713"/>
<text text-anchor="start" x="243.25" y="-719.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-713 404,-733.75 474.25,-733.75 474.25,-713 404,-713"/>
<text text-anchor="start" x="408" y="-720.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-693.75 239.25,-713 404,-713 404,-693.75 239.25,-693.75"/>
<text text-anchor="start" x="243.25" y="-699.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-693.75 404,-713 474.25,-713 474.25,-693.75 404,-693.75"/>
<text text-anchor="start" x="408" y="-699.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-674.5 239.25,-693.75 404,-693.75 404,-674.5 239.25,-674.5"/>
<text text-anchor="start" x="243.25" y="-680.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.connector</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-674.5 404,-693.75 474.25,-693.75 474.25,-674.5 404,-674.5"/>
<text text-anchor="start" x="408" y="-680.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-655.25 239.25,-674.5 404,-674.5 404,-655.25 239.25,-655.25"/>
<text text-anchor="start" x="243.25" y="-661" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-655.25 404,-674.5 474.25,-674.5 474.25,-655.25 404,-655.25"/>
<text text-anchor="start" x="408" y="-661" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-636 239.25,-655.25 404,-655.25 404,-636 239.25,-636"/>
<text text-anchor="start" x="243.25" y="-641.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-636 404,-655.25 474.25,-655.25 474.25,-636 404,-636"/>
<text text-anchor="start" x="408" y="-641.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-616.75 239.25,-636 404,-636 404,-616.75 239.25,-616.75"/>
<text text-anchor="start" x="243.25" y="-623.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-616.75 404,-636 474.25,-636 474.25,-616.75 404,-616.75"/>
<text text-anchor="start" x="408" y="-622.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-597.5 239.25,-616.75 404,-616.75 404,-597.5 239.25,-597.5"/>
<text text-anchor="start" x="243.25" y="-603.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-597.5 404,-616.75 474.25,-616.75 474.25,-597.5 404,-597.5"/>
<text text-anchor="start" x="408" y="-603.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-578.25 239.25,-597.5 404,-597.5 404,-578.25 239.25,-578.25"/>
<text text-anchor="start" x="243.25" y="-584" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-578.25 404,-597.5 474.25,-597.5 474.25,-578.25 404,-578.25"/>
<text text-anchor="start" x="408" y="-584" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-559 239.25,-578.25 404,-578.25 404,-559 239.25,-559"/>
<text text-anchor="start" x="243.25" y="-564.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-559 404,-578.25 474.25,-578.25 474.25,-559 404,-559"/>
<text text-anchor="start" x="408" y="-564.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-539.75 239.25,-559 404,-559 404,-539.75 239.25,-539.75"/>
<text text-anchor="start" x="243.25" y="-545.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-539.75 404,-559 474.25,-559 474.25,-539.75 404,-539.75"/>
<text text-anchor="start" x="408" y="-545.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-520.5 239.25,-539.75 404,-539.75 404,-520.5 239.25,-520.5"/>
<text text-anchor="start" x="243.25" y="-527.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.kind</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-520.5 404,-539.75 474.25,-539.75 474.25,-520.5 404,-520.5"/>
<text text-anchor="start" x="408" y="-526.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-501.25 239.25,-520.5 404,-520.5 404,-501.25 239.25,-501.25"/>
<text text-anchor="start" x="243.25" y="-507" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.standard</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-501.25 404,-520.5 474.25,-520.5 474.25,-501.25 404,-501.25"/>
<text text-anchor="start" x="408" y="-507" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-480.5 239.25,-501.25 404,-501.25 404,-480.5 239.25,-480.5"/>
<text text-anchor="start" x="243.25" y="-487" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-480.5 404,-501.25 474.25,-501.25 474.25,-480.5 404,-480.5"/>
<text text-anchor="start" x="408" y="-487.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-461.25 239.25,-480.5 404,-480.5 404,-461.25 239.25,-461.25"/>
<text text-anchor="start" x="243.25" y="-467" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-461.25 404,-480.5 474.25,-480.5 474.25,-461.25 404,-461.25"/>
<text text-anchor="start" x="408" y="-467" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-442 239.25,-461.25 404,-461.25 404,-442 239.25,-442"/>
<text text-anchor="start" x="243.25" y="-447.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.speed</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-442 404,-461.25 474.25,-461.25 474.25,-442 404,-442"/>
<text text-anchor="start" x="408" y="-447.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-422.75 239.25,-442 404,-442 404,-422.75 239.25,-422.75"/>
<text text-anchor="start" x="243.25" y="-428.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.wifiStandard</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-422.75 404,-442 474.25,-442 474.25,-422.75 404,-422.75"/>
<text text-anchor="start" x="408" y="-428.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-403.5 239.25,-422.75 404,-422.75 404,-403.5 239.25,-403.5"/>
<text text-anchor="start" x="243.25" y="-410.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-403.5 404,-422.75 474.25,-422.75 474.25,-403.5 404,-403.5"/>
<text text-anchor="start" x="408" y="-409.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-384.25 239.25,-403.5 404,-403.5 404,-384.25 239.25,-384.25"/>
<text text-anchor="start" x="243.25" y="-391" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-384.25 404,-403.5 474.25,-403.5 474.25,-384.25 404,-384.25"/>
<text text-anchor="start" x="408" y="-390" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-363.5 239.25,-384.25 404,-384.25 404,-363.5 239.25,-363.5"/>
<text text-anchor="start" x="243.25" y="-370" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-363.5 404,-384.25 474.25,-384.25 474.25,-363.5 404,-363.5"/>
<text text-anchor="start" x="408" y="-370.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-344.25 239.25,-363.5 404,-363.5 404,-344.25 239.25,-344.25"/>
<text text-anchor="start" x="243.25" y="-350" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-344.25 404,-363.5 474.25,-363.5 474.25,-344.25 404,-344.25"/>
<text text-anchor="start" x="408" y="-350" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-325 239.25,-344.25 404,-344.25 404,-325 239.25,-325"/>
<text text-anchor="start" x="243.25" y="-330.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-325 404,-344.25 474.25,-344.25 474.25,-325 404,-325"/>
<text text-anchor="start" x="408" y="-330.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-304.25 239.25,-325 404,-325 404,-304.25 239.25,-304.25"/>
<text text-anchor="start" x="243.25" y="-311.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-304.25 404,-325 474.25,-325 474.25,-304.25 404,-304.25"/>
<text text-anchor="start" x="408" y="-311.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-283.5 239.25,-304.25 404,-304.25 404,-283.5 239.25,-283.5"/>
<text text-anchor="start" x="243.25" y="-290" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-283.5 404,-304.25 474.25,-304.25 474.25,-283.5 404,-283.5"/>
<text text-anchor="start" x="408" y="-290.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-264.25 239.25,-283.5 404,-283.5 404,-264.25 239.25,-264.25"/>
<text text-anchor="start" x="243.25" y="-270" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-264.25 404,-283.5 474.25,-283.5 474.25,-264.25 404,-264.25"/>
<text text-anchor="start" x="408" y="-270" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-243.5 239.25,-264.25 404,-264.25 404,-243.5 239.25,-243.5"/>
<text text-anchor="start" x="243.25" y="-250" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-243.5 404,-264.25 474.25,-264.25 474.25,-243.5 404,-243.5"/>
<text text-anchor="start" x="408" y="-250.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-224.25 239.25,-243.5 404,-243.5 404,-224.25 239.25,-224.25"/>
<text text-anchor="start" x="243.25" y="-230" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-224.25 404,-243.5 474.25,-243.5 474.25,-224.25 404,-224.25"/>
<text text-anchor="start" x="408" y="-230" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-203.5 239.25,-224.25 404,-224.25 404,-203.5 239.25,-203.5"/>
<text text-anchor="start" x="243.25" y="-210" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-203.5 404,-224.25 474.25,-224.25 474.25,-203.5 404,-203.5"/>
<text text-anchor="start" x="408" y="-210.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-184.25 239.25,-203.5 404,-203.5 404,-184.25 239.25,-184.25"/>
<text text-anchor="start" x="243.25" y="-190" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-184.25 404,-203.5 474.25,-203.5 474.25,-184.25 404,-184.25"/>
<text text-anchor="start" x="408" y="-190" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_95"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-165 239.25,-184.25 404,-184.25 404,-165 239.25,-165"/>
<text text-anchor="start" x="243.25" y="-170.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_96"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-165 404,-184.25 474.25,-184.25 474.25,-165 404,-165"/>
<text text-anchor="start" x="408" y="-170.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_97"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-145.75 239.25,-165 404,-165 404,-145.75 239.25,-145.75"/>
<text text-anchor="start" x="243.25" y="-151.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_98"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-145.75 404,-165 474.25,-165 474.25,-145.75 404,-145.75"/>
<text text-anchor="start" x="408" y="-151.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_99"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-126.5 239.25,-145.75 404,-145.75 404,-126.5 239.25,-126.5"/>
<text text-anchor="start" x="243.25" y="-133.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_100"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-126.5 404,-145.75 474.25,-145.75 474.25,-126.5 404,-126.5"/>
<text text-anchor="start" x="408" y="-132.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_101"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-105.75 239.25,-126.5 404,-126.5 404,-105.75 239.25,-105.75"/>
<text text-anchor="start" x="243.25" y="-112.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_102"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-105.75 404,-126.5 474.25,-126.5 474.25,-105.75 404,-105.75"/>
<text text-anchor="start" x="408" y="-113" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_103"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-86.5 239.25,-105.75 404,-105.75 404,-86.5 239.25,-86.5"/>
<text text-anchor="start" x="243.25" y="-92.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_104"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-86.5 404,-105.75 474.25,-105.75 474.25,-86.5 404,-86.5"/>
<text text-anchor="start" x="408" y="-92.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_105"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-67.25 239.25,-86.5 404,-86.5 404,-67.25 239.25,-67.25"/>
<text text-anchor="start" x="243.25" y="-73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_106"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-67.25 404,-86.5 474.25,-86.5 474.25,-67.25 404,-67.25"/>
<text text-anchor="start" x="408" y="-73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-763.38C756.2,-763.38 825.09,-697.55 1103.3,-696.39"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.09,-698.49 1109.09,-696.38 1103.08,-694.29 1103.09,-698.49"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="660.25,-669.75 539.25,-669.75 539.25,-435.75 660.25,-435.75 660.25,-669.75"/>
<polygon fill="#f1efe8" stroke="none" points="539.25,-435.75 539.25,-669.75 660.25,-669.75 660.25,-435.75 539.25,-435.75"/>
<g id="a_node3_107"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="539.25,-650.5 539.25,-669.75 660.25,-669.75 660.25,-650.5 539.25,-650.5"/>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-650.5 539.25,-669.75 660.25,-669.75 660.25,-650.5 539.25,-650.5"/>
<text text-anchor="start" x="578.75" y="-657.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_108"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-631.25 539.25,-650.5 615.5,-650.5 615.5,-631.25 539.25,-631.25"/>
<text text-anchor="start" x="543.25" y="-637" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_109"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-631.25 615.5,-650.5 660.25,-650.5 660.25,-631.25 615.5,-631.25"/>
<text text-anchor="start" x="619.5" y="-637" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_110"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-612 539.25,-631.25 615.5,-631.25 615.5,-612 539.25,-612"/>
<text text-anchor="start" x="543.25" y="-618.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_111"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-612 615.5,-631.25 660.25,-631.25 660.25,-612 615.5,-612"/>
<text text-anchor="start" x="619.5" y="-617.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_112"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-592.75 539.25,-612 615.5,-612 615.5,-592.75 539.25,-592.75"/>
<text text-anchor="start" x="543.25" y="-599.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_113"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-592.75 615.5,-612 660.25,-612 660.25,-592.75 615.5,-592.75"/>
<text text-anchor="start" x="619.5" y="-598.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-572 539.25,-592.75 615.5,-592.75 615.5,-572 539.25,-572"/>
<text text-anchor="start" x="543.25" y="-578.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-572 615.5,-592.75 660.25,-592.75 660.25,-572 615.5,-572"/>
<text text-anchor="start" x="619.5" y="-579.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_116"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-552.75 539.25,-572 615.5,-572 615.5,-552.75 539.25,-552.75"/>
<text text-anchor="start" x="543.25" y="-558.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_117"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-552.75 615.5,-572 660.25,-572 660.25,-552.75 615.5,-552.75"/>
<text text-anchor="start" x="619.5" y="-558.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_118"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-533.5 539.25,-552.75 615.5,-552.75 615.5,-533.5 539.25,-533.5"/>
<text text-anchor="start" x="543.25" y="-539.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_119"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-533.5 615.5,-552.75 660.25,-552.75 660.25,-533.5 615.5,-533.5"/>
<text text-anchor="start" x="619.5" y="-539.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_120"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-514.25 539.25,-533.5 615.5,-533.5 615.5,-514.25 539.25,-514.25"/>
<text text-anchor="start" x="543.25" y="-520" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6SubnetId</text>
</a>
</g>
<g id="a_node3_121"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-514.25 615.5,-533.5 660.25,-533.5 660.25,-514.25 615.5,-514.25"/>
<text text-anchor="start" x="619.5" y="-520" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node3_122"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-495 539.25,-514.25 615.5,-514.25 615.5,-495 539.25,-495"/>
<text text-anchor="start" x="543.25" y="-501.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_123"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-495 615.5,-514.25 660.25,-514.25 660.25,-495 615.5,-495"/>
<text text-anchor="start" x="619.5" y="-500.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_124"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-475.75 539.25,-495 615.5,-495 615.5,-475.75 539.25,-475.75"/>
<text text-anchor="start" x="543.25" y="-481.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_125"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-475.75 615.5,-495 660.25,-495 660.25,-475.75 615.5,-475.75"/>
<text text-anchor="start" x="619.5" y="-481.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_126"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-455 539.25,-475.75 615.5,-475.75 615.5,-455 539.25,-455"/>
<text text-anchor="start" x="543.25" y="-462.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_127"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-455 615.5,-475.75 660.25,-475.75 660.25,-455 615.5,-455"/>
<text text-anchor="start" x="619.5" y="-462.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_128"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-435.75 539.25,-455 615.5,-455 615.5,-435.75 539.25,-435.75"/>
<text text-anchor="start" x="543.25" y="-441.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_129"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-435.75 615.5,-455 660.25,-455 660.25,-435.75 615.5,-435.75"/>
<text text-anchor="start" x="619.5" y="-441.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-490.88C552.15,-490.88 464.86,-649.07 531.8,-659.58"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="531.45,-661.66 537.59,-660 531.76,-657.47 531.45,-661.66"/>
</g>
<g id="node4" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="635.88,-326.25 563.62,-326.25 563.62,-249.25 635.88,-249.25 635.88,-326.25"/>
<polygon fill="#f1efe8" stroke="none" points="563.62,-249.25 563.62,-326.25 635.88,-326.25 635.88,-249.25 563.62,-249.25"/>
<g id="a_node4_130"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="563.62,-307 563.62,-326.25 635.88,-326.25 635.88,-307 563.62,-307"/>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-307 563.62,-326.25 635.88,-326.25 635.88,-307 563.62,-307"/>
<text text-anchor="start" x="582.88" y="-313.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node4_131"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-287.75 563.62,-307 603.88,-307 603.88,-287.75 563.62,-287.75"/>
<text text-anchor="start" x="567.62" y="-293.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node4_132"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-287.75 603.88,-307 635.88,-307 635.88,-287.75 603.88,-287.75"/>
<text text-anchor="start" x="607.88" y="-293.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_133"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-268.5 563.62,-287.75 603.88,-287.75 603.88,-268.5 563.62,-268.5"/>
<text text-anchor="start" x="567.62" y="-275.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_134"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-268.5 603.88,-287.75 635.88,-287.75 635.88,-268.5 603.88,-268.5"/>
<text text-anchor="start" x="607.88" y="-274.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_135"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-249.25 563.62,-268.5 603.88,-268.5 603.88,-249.25 563.62,-249.25"/>
<text text-anchor="start" x="567.62" y="-255" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_136"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-249.25 603.88,-268.5 635.88,-268.5 635.88,-249.25 603.88,-249.25"/>
<text text-anchor="start" x="607.88" y="-255" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-314.63C510.93,-314.63 521.91,-316.37 555.17,-316.6"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="554.95,-318.7 560.96,-316.62 554.97,-314.5 554.95,-318.7"/>
</g>
<g id="node7" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="828.25,-475.63 725.25,-475.63 725.25,-337.88 828.25,-337.88 828.25,-475.63"/>
<polygon fill="#f1efe8" stroke="none" points="725.25,-337.88 725.25,-475.63 828.25,-475.63 828.25,-337.88 725.25,-337.88"/>
<g id="a_node7_137"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="725.25,-456.38 725.25,-475.63 828.25,-475.63 828.25,-456.38 725.25,-456.38"/>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-456.38 725.25,-475.63 828.25,-475.63 828.25,-456.38 725.25,-456.38"/>
<text text-anchor="start" x="765.88" y="-463.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node7_138"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-437.13 725.25,-456.38 767.75,-456.38 767.75,-437.13 725.25,-437.13"/>
<text text-anchor="start" x="729.25" y="-443.88" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node7_139"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-437.13 767.75,-456.38 828.25,-456.38 828.25,-437.13 767.75,-437.13"/>
<text text-anchor="start" x="771.75" y="-442.88" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_140"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-417.88 725.25,-437.13 767.75,-437.13 767.75,-417.88 725.25,-417.88"/>
<text text-anchor="start" x="729.25" y="-423.63" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Ula</text>
</a>
</g>
<g id="a_node7_141"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-417.88 767.75,-437.13 828.25,-437.13 828.25,-417.88 767.75,-417.88"/>
<text text-anchor="start" x="771.75" y="-423.63" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_142"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-398.63 725.25,-417.88 767.75,-417.88 767.75,-398.63 725.25,-398.63"/>
<text text-anchor="start" x="729.25" y="-405.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node7_143"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-398.63 767.75,-417.88 828.25,-417.88 828.25,-398.63 767.75,-398.63"/>
<text text-anchor="start" x="771.75" y="-404.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_144"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-379.38 725.25,-398.63 767.75,-398.63 767.75,-379.38 725.25,-379.38"/>
<text text-anchor="start" x="729.25" y="-385.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_145"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-379.38 767.75,-398.63 828.25,-398.63 828.25,-379.38 767.75,-379.38"/>
<text text-anchor="start" x="771.75" y="-385.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_146"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-358.63 725.25,-379.38 767.75,-379.38 767.75,-358.63 725.25,-358.63"/>
<text text-anchor="start" x="729.25" y="-365.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_147"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-358.63 767.75,-379.38 828.25,-379.38 828.25,-358.63 767.75,-358.63"/>
<text text-anchor="start" x="771.75" y="-365.88" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_148"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-337.88 725.25,-358.63 767.75,-358.63 767.75,-337.88 725.25,-337.88"/>
<text text-anchor="start" x="729.25" y="-345.38" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node7_149"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-337.88 767.75,-358.63 828.25,-358.63 828.25,-337.88 767.75,-337.88"/>
<text text-anchor="start" x="771.75" y="-345.13" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-213.88C557.65,-213.88 597.14,-184.22 660.25,-238.75 737.72,-305.69 626.14,-458.01 717.68,-465.7"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.51,-467.79 723.59,-465.94 717.68,-463.6 717.51,-467.79"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M661.25,-582.38C700.09,-582.38 681.24,-637.08 660.25,-669.75 628.12,-719.77 586.53,-690.71 539.25,-726.75 506.01,-752.09 517.1,-796.97 481.47,-802.14"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="481.76,-800.01 475.91,-802.51 482.04,-804.2 481.76,-800.01"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M660.25,-465.38C686.43,-465.38 694.82,-465.89 717.66,-465.99"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.58,-468.09 723.59,-466 717.59,-463.89 717.58,-468.09"/>
</g>
<g id="node6" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-1089.75 0,-1089.75 0,-501.75 174.25,-501.75 174.25,-1089.75"/>
<polygon fill="#f1efe8" stroke="none" points="0,-501.75 0,-1089.75 174.25,-1089.75 174.25,-501.75 0,-501.75"/>
<g id="a_node6_150"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-1070.5 0,-1089.75 174.25,-1089.75 174.25,-1070.5 0,-1070.5"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-1070.5 0,-1089.75 174.25,-1089.75 174.25,-1070.5 0,-1070.5"/>
<text text-anchor="start" x="68" y="-1077.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node6_151"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1051.25 0,-1070.5 107,-1070.5 107,-1051.25 0,-1051.25"/>
<text text-anchor="start" x="4" y="-1057" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node6_152"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1051.25 107,-1070.5 174.25,-1070.5 174.25,-1051.25 107,-1051.25"/>
<text text-anchor="start" x="111" y="-1057" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_153"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1032 0,-1051.25 107,-1051.25 107,-1032 0,-1032"/>
<text text-anchor="start" x="4" y="-1037.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node6_154"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1032 107,-1051.25 174.25,-1051.25 174.25,-1032 107,-1032"/>
<text text-anchor="start" x="111" y="-1037.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_155"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1012.75 0,-1032 107,-1032 107,-1012.75 0,-1012.75"/>
<text text-anchor="start" x="4" y="-1018.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node6_156"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1012.75 107,-1032 174.25,-1032 174.25,-1012.75 107,-1012.75"/>
<text text-anchor="start" x="111" y="-1018.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node6_157"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-993.5 0,-1012.75 107,-1012.75 107,-993.5 0,-993.5"/>
<text text-anchor="start" x="4" y="-999.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node6_158"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-993.5 107,-1012.75 174.25,-1012.75 174.25,-993.5 107,-993.5"/>
<text text-anchor="start" x="111" y="-999.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node6_159"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-974.25 0,-993.5 107,-993.5 107,-974.25 0,-974.25"/>
<text text-anchor="start" x="4" y="-980" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node6_160"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-974.25 107,-993.5 174.25,-993.5 174.25,-974.25 107,-974.25"/>
<text text-anchor="start" x="111" y="-980" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_161"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-955 0,-974.25 107,-974.25 107,-955 0,-955"/>
<text text-anchor="start" x="4" y="-960.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node6_162"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-955 107,-974.25 174.25,-974.25 174.25,-955 107,-955"/>
<text text-anchor="start" x="111" y="-960.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_163"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-935.75 0,-955 107,-955 107,-935.75 0,-935.75"/>
<text text-anchor="start" x="4" y="-941.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node6_164"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-935.75 107,-955 174.25,-955 174.25,-935.75 107,-935.75"/>
<text text-anchor="start" x="111" y="-941.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_165"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-916.5 0,-935.75 107,-935.75 107,-916.5 0,-916.5"/>
<text text-anchor="start" x="4" y="-922.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node6_166"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-916.5 107,-935.75 174.25,-935.75 174.25,-916.5 107,-916.5"/>
<text text-anchor="start" x="111" y="-922.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_167"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-897.25 0,-916.5 107,-916.5 107,-897.25 0,-897.25"/>
<text text-anchor="start" x="4" y="-904" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node6_168"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-897.25 107,-916.5 174.25,-916.5 174.25,-897.25 107,-897.25"/>
<text text-anchor="start" x="111" y="-903" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_169"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-878 0,-897.25 107,-897.25 107,-878 0,-878"/>
<text text-anchor="start" x="4" y="-883.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node6_170"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-878 107,-897.25 174.25,-897.25 174.25,-878 107,-878"/>
<text text-anchor="start" x="111" y="-883.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_171"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-857.25 0,-878 107,-878 107,-857.25 0,-857.25"/>
<text text-anchor="start" x="4" y="-863.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node6_172"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-857.25 107,-878 174.25,-878 174.25,-857.25 107,-857.25"/>
<text text-anchor="start" x="111" y="-864.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_173"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-836.5 0,-857.25 107,-857.25 107,-836.5 0,-836.5"/>
<text text-anchor="start" x="4" y="-843" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node6_174"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-836.5 107,-857.25 174.25,-857.25 174.25,-836.5 107,-836.5"/>
<text text-anchor="start" x="111" y="-843.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node6_175"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-817.25 0,-836.5 107,-836.5 107,-817.25 0,-817.25"/>
<text text-anchor="start" x="4" y="-823" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node6_176"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-817.25 107,-836.5 174.25,-836.5 174.25,-817.25 107,-817.25"/>
<text text-anchor="start" x="111" y="-823" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_177"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-798 0,-817.25 107,-817.25 107,-798 0,-798"/>
<text text-anchor="start" x="4" y="-804.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node6_178"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-798 107,-817.25 174.25,-817.25 174.25,-798 107,-798"/>
<text text-anchor="start" x="111" y="-803.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_179"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-777.25 0,-798 107,-798 107,-777.25 0,-777.25"/>
<text text-anchor="start" x="4" y="-783.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node6_180"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-777.25 107,-798 174.25,-798 174.25,-777.25 107,-777.25"/>
<text text-anchor="start" x="111" y="-784.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_181"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-758 0,-777.25 107,-777.25 107,-758 0,-758"/>
<text text-anchor="start" x="4" y="-763.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node6_182"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-758 107,-777.25 174.25,-777.25 174.25,-758 107,-758"/>
<text text-anchor="start" x="111" y="-763.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_183"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-738.75 0,-758 107,-758 107,-738.75 0,-738.75"/>
<text text-anchor="start" x="4" y="-745.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node6_184"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-738.75 107,-758 174.25,-758 174.25,-738.75 107,-738.75"/>
<text text-anchor="start" x="111" y="-744.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_185"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-719.5 0,-738.75 107,-738.75 107,-719.5 0,-719.5"/>
<text text-anchor="start" x="4" y="-726.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node6_186"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-719.5 107,-738.75 174.25,-738.75 174.25,-719.5 107,-719.5"/>
<text text-anchor="start" x="111" y="-725.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_187"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-700.25 0,-719.5 107,-719.5 107,-700.25 0,-700.25"/>
<text text-anchor="start" x="4" y="-706" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node6_188"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-700.25 107,-719.5 174.25,-719.5 174.25,-700.25 107,-700.25"/>
<text text-anchor="start" x="111" y="-706" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_189"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-681 0,-700.25 107,-700.25 107,-681 0,-681"/>
<text text-anchor="start" x="4" y="-686.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node6_190"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-681 107,-700.25 174.25,-700.25 174.25,-681 107,-681"/>
<text text-anchor="start" x="111" y="-686.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_191"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-660.25 0,-681 107,-681 107,-660.25 0,-660.25"/>
<text text-anchor="start" x="4" y="-666.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node6_192"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-660.25 107,-681 174.25,-681 174.25,-660.25 107,-660.25"/>
<text text-anchor="start" x="111" y="-667.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_193"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-639.5 0,-660.25 107,-660.25 107,-639.5 0,-639.5"/>
<text text-anchor="start" x="4" y="-646" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node6_194"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-639.5 107,-660.25 174.25,-660.25 174.25,-639.5 107,-639.5"/>
<text text-anchor="start" x="111" y="-646.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node6_195"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-620.25 0,-639.5 107,-639.5 107,-620.25 0,-620.25"/>
<text text-anchor="start" x="4" y="-627" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_196"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-620.25 107,-639.5 174.25,-639.5 174.25,-620.25 107,-620.25"/>
<text text-anchor="start" x="111" y="-626" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_197"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-601 0,-620.25 107,-620.25 107,-601 0,-601"/>
<text text-anchor="start" x="4" y="-606.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_198"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-601 107,-620.25 174.25,-620.25 174.25,-601 107,-601"/>
<text text-anchor="start" x="111" y="-606.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_199"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-581.75 0,-601 107,-601 107,-581.75 0,-581.75"/>
<text text-anchor="start" x="4" y="-587.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node6_200"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-581.75 107,-601 174.25,-601 174.25,-581.75 107,-581.75"/>
<text text-anchor="start" x="111" y="-587.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_201"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-561 0,-581.75 107,-581.75 107,-561 0,-561"/>
<text text-anchor="start" x="4" y="-567.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node6_202"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-561 107,-581.75 174.25,-581.75 174.25,-561 107,-561"/>
<text text-anchor="start" x="111" y="-568.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node6_203"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-541.75 0,-561 107,-561 107,-541.75 0,-541.75"/>
<text text-anchor="start" x="4" y="-547.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node6_204"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-541.75 107,-561 174.25,-561 174.25,-541.75 107,-541.75"/>
<text text-anchor="start" x="111" y="-547.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_205"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-521 0,-541.75 107,-541.75 107,-521 0,-521"/>
<text text-anchor="start" x="4" y="-527.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node6_206"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-521 107,-541.75 174.25,-541.75 174.25,-521 107,-521"/>
<text text-anchor="start" x="111" y="-528.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_207"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-501.75 0,-521 107,-521 107,-501.75 0,-501.75"/>
<text text-anchor="start" x="4" y="-507.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node6_208"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-501.75 107,-521 174.25,-521 174.25,-501.75 107,-501.75"/>
<text text-anchor="start" x="111" y="-507.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-846.88C362.92,-846.88 410.08,-846.75 598.75,-846.75 598.75,-846.75 598.75,-846.75 777.75,-846.75 796.74,-846.75 1053.89,-715.14 1103.58,-698.17"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.82,-700.27 1109.13,-696.78 1102.8,-696.2 1103.82,-700.27"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-649.88C245.29,-649.88 171.38,-791.5 231.67,-802.01"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-804.1 237.59,-802.49 231.78,-799.91 231.44,-804.1"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-571.38C289.74,-571.38 155.11,-134.87 239.25,-55.75 355.89,53.92 438.65,-32.75 598.75,-32.75 598.75,-32.75 598.75,-32.75 970.5,-32.75 1096.92,-32.75 1152.05,-24.73 1243.75,-111.75 1305.85,-170.69 1225.53,-291.88 1301.44,-298.93"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301,-301.01 1307.09,-299.18 1301.18,-296.82 1301,-301.01"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-369C924.92,-369 949.9,-381.26 1045.75,-368.75 1163.06,-353.44 1186.85,-301.55 1301.09,-299.33"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.11,-301.43 1307.09,-299.27 1301.07,-297.23 1301.11,-301.43"/>
</g>
<g id="node8" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1045.75,-358 893.25,-358 893.25,-85.5 1045.75,-85.5 1045.75,-358"/>
<polygon fill="#f1efe8" stroke="none" points="893.25,-85.5 893.25,-358 1045.75,-358 1045.75,-85.5 893.25,-85.5"/>
<g id="a_node8_209"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="893.25,-338.75 893.25,-358 1045.75,-358 1045.75,-338.75 893.25,-338.75"/>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-338.75 893.25,-358 1045.75,-358 1045.75,-338.75 893.25,-338.75"/>
<text text-anchor="start" x="952.25" y="-345.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_210"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-319.5 893.25,-338.75 978.5,-338.75 978.5,-319.5 893.25,-319.5"/>
<text text-anchor="start" x="897.25" y="-325.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node8_211"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-319.5 978.5,-338.75 1045.75,-338.75 1045.75,-319.5 978.5,-319.5"/>
<text text-anchor="start" x="982.5" y="-325.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_212"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-300.25 893.25,-319.5 978.5,-319.5 978.5,-300.25 893.25,-300.25"/>
<text text-anchor="start" x="897.25" y="-306" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node8_213"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-300.25 978.5,-319.5 1045.75,-319.5 1045.75,-300.25 978.5,-300.25"/>
<text text-anchor="start" x="982.5" y="-306" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node8_214"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-281 893.25,-300.25 978.5,-300.25 978.5,-281 893.25,-281"/>
<text text-anchor="start" x="897.25" y="-287.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node8_215"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-281 978.5,-300.25 1045.75,-300.25 1045.75,-281 978.5,-281"/>
<text text-anchor="start" x="982.5" y="-286.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_216"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-261.75 893.25,-281 978.5,-281 978.5,-261.75 893.25,-261.75"/>
<text text-anchor="start" x="897.25" y="-268.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node8_217"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-261.75 978.5,-281 1045.75,-281 1045.75,-261.75 978.5,-261.75"/>
<text text-anchor="start" x="982.5" y="-267.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_218"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-241 893.25,-261.75 978.5,-261.75 978.5,-241 893.25,-241"/>
<text text-anchor="start" x="897.25" y="-247.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node8_219"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-241 978.5,-261.75 1045.75,-261.75 1045.75,-241 978.5,-241"/>
<text text-anchor="start" x="982.5" y="-248.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node8_220"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-221.75 893.25,-241 978.5,-241 978.5,-221.75 893.25,-221.75"/>
<text text-anchor="start" x="897.25" y="-227.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node8_221"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-221.75 978.5,-241 1045.75,-241 1045.75,-221.75 978.5,-221.75"/>
<text text-anchor="start" x="982.5" y="-227.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_222"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-202.5 893.25,-221.75 978.5,-221.75 978.5,-202.5 893.25,-202.5"/>
<text text-anchor="start" x="897.25" y="-208.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node8_223"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-202.5 978.5,-221.75 1045.75,-221.75 1045.75,-202.5 978.5,-202.5"/>
<text text-anchor="start" x="982.5" y="-208.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_224"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-183.25 893.25,-202.5 978.5,-202.5 978.5,-183.25 893.25,-183.25"/>
<text text-anchor="start" x="897.25" y="-189" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node8_225"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-183.25 978.5,-202.5 1045.75,-202.5 1045.75,-183.25 978.5,-183.25"/>
<text text-anchor="start" x="982.5" y="-189" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_226"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-164 893.25,-183.25 978.5,-183.25 978.5,-164 893.25,-164"/>
<text text-anchor="start" x="897.25" y="-169.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node8_227"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-164 978.5,-183.25 1045.75,-183.25 1045.75,-164 978.5,-164"/>
<text text-anchor="start" x="982.5" y="-169.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_228"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-144.75 893.25,-164 978.5,-164 978.5,-144.75 893.25,-144.75"/>
<text text-anchor="start" x="897.25" y="-150.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node8_229"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-144.75 978.5,-164 1045.75,-164 1045.75,-144.75 978.5,-144.75"/>
<text text-anchor="start" x="982.5" y="-150.5" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_230"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-125.5 893.25,-144.75 978.5,-144.75 978.5,-125.5 893.25,-125.5"/>
<text text-anchor="start" x="897.25" y="-131.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node8_231"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-125.5 978.5,-144.75 1045.75,-144.75 1045.75,-125.5 978.5,-125.5"/>
<text text-anchor="start" x="982.5" y="-131.25" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_232"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-106.25 893.25,-125.5 978.5,-125.5 978.5,-106.25 893.25,-106.25"/>
<text text-anchor="start" x="897.25" y="-112" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_233"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-106.25 978.5,-125.5 1045.75,-125.5 1045.75,-106.25 978.5,-106.25"/>
<text text-anchor="start" x="982.5" y="-112" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_234"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-85.5 893.25,-106.25 978.5,-106.25 978.5,-85.5 893.25,-85.5"/>
<text text-anchor="start" x="897.25" y="-92" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_235"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-85.5 978.5,-106.25 1045.75,-106.25 1045.75,-85.5 978.5,-85.5"/>
<text text-anchor="start" x="982.5" y="-92.75" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-348.25C854.43,-348.25 862.82,-348.35 885.66,-348.37"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="885.58,-350.47 891.59,-348.38 885.59,-346.27 885.58,-350.47"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-251.38C1242.99,-251.38 919.61,-684.72 1103.12,-696.15"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.03,-698.24 1109.09,-696.33 1103.15,-694.05 1103.03,-698.24"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-95.88C1190.91,-95.88 1162.08,-292.16 1301.12,-299.07"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.04,-301.16 1307.09,-299.21 1301.14,-296.96 1301.04,-301.16"/>
</g>
</g>
</svg>
</figure>

A click on a section's head leads to its section below, a click on a field to its row in the field table; anywhere else the diagram opens enlarged. On its own: [inventory-schema.svg](site/en/assets/diagrams/inventory-schema.svg).

### Conventions

**Ids.** Entries are keyed by id: lower-case letters, digits and dashes, starting with a letter or digit (`grammi`, `realtox-dus`, `home-private`). A reference field holds such an id and must name an existing entry of the right section.

**Required and optional.** A field is optional unless the table says *required*. Optional fields left out are filled in by the derived view – with the default the table gives, otherwise `null` or `[]` – so a consumer never has to write `or`.

**Unknown fields are errors.** A typo (`critcality`) is reported with the list of the known fields, in the editor right away and in `nix flake check`.

**One direction.** Every relation is stored where it starts (`hosts.runsOn`, `services.dependsOn`, `hosts.contracts`); the reverse (`guests`, `neededBy`, `covers`) is derived.

**Formats.** Strings with a format are checked against it:

| Format | Example | Used by |
| --- | --- | --- |
| IPv4 address | `192.0.2.10` | `interfaces.<name>.ipv4.address`, `dhcpPool` |
| IPv4 prefix (no host bits) | `192.0.2.0/24` | `networks.ipv4` |
| IPv6 prefix | `2001:db8:1::/64` | `networks.ipv6` |
| ULA /48 (in `fd00::/8`) | `fd12:3456:789a::/48` | `sites.ipv6Ula` |
| MAC address, lower case | `52:54:00:12:34:56` | `interfaces.<name>.mac` |
| Link-local | `eui64`, `stable-privacy`, `random` or `fe80::1234` | `interfaces.<name>.linkLocal` |
| SSH public key without comment | `ssh-ed25519 AAAAC3Nz…` | `hosts.sshHostKeys` |
| Date | `2026-10-22` | `contracts.since`, `contracts.renews` |
| Domain name, lower case | `cloud.example.org` | `services.endpoints[].fqdn` |
| Interface name | `eno1`, `eno1.20`, `wlp2s0f0` | keys of `hosts.interfaces` |

**Money** is in whole cents (`899` = 8.99) – no floating point, no rounding.

**What the schema cannot say.** A JSON Schema checks one entry at a time. Everything between entries – references, cycles, addresses inside a prefix, a contract with the right provider – is checked by `inventory.nix` only; each section below lists those rules briefly, [Validation](#validation) has them all.

### owners

Who administers a device – whom to call and what may be changed.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="owners-contact"></span>`contact` | string |  | Who to talk to when this owner's devices are affected. |
| <span id="owners-name"></span>`name` | string | required | Display name. |
| <span id="owners-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  }
}
```

Rule beyond the schema: every owner owns at least one host.

### providers

A company or club the lab depends on: an ISP, a hoster, a service bought from outside, the hackerspace.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="providers-contact"></span>`contact` | string |  | How to reach them (support address, phone, ticket system). |
| <span id="providers-name"></span>`name` | string | required | Display name of the company or club. |
| <span id="providers-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="providers-url"></span>`url` | string |  | Website or customer portal. |

```json
{
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  }
}
```

Rule beyond the schema: something refers to every provider – a site, a line, a service or a contract.

### contracts

What is paid to a provider. A provider can have several; a host, line or service names the ones it is paid by.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="contracts-cost"></span>`cost` | object |  | What it costs. Leave it out until known - the contract is then listed in pending. |
| <span id="contracts-cost-amount"></span>`cost.amount` | integer ≥ 0 | required | Amount per period in cents (899 = 8.99) - whole numbers only. |
| <span id="contracts-cost-currency"></span>`cost.currency` | one of `EUR` `USD` `CHF` `GBP` | required | Currency of amount. Totals are kept per currency, never converted. |
| <span id="contracts-cost-duemonth"></span>`cost.dueMonth` | integer 1–12 |  | Only with period year, and required there: the month (1-12) the yearly amount is charged in. |
| <span id="contracts-cost-period"></span>`cost.period` | one of `month` `year` `once` | required | How often amount is charged. |
| <span id="contracts-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="contracts-notice"></span>`notice` | string |  | Notice period, as the contract words it. |
| <span id="contracts-product"></span>`product` | string |  | Product or plan name as the provider calls it. |
| <span id="contracts-provider"></span>`provider` | id from [providers](#providers-1) | required | Who the contract is with. |
| <span id="contracts-renews"></span>`renews` | string: a date like 2026-10-22 |  | Next date the contract renews or ends unless cancelled. |
| <span id="contracts-since"></span>`since` | string: a date like 2026-10-22 |  | Start of the contract. |

```json
{
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  }
}
```

Rules beyond the schema: `cost.dueMonth` exactly with `period` `year`; `renews` not before `since`; a contract named by a host, line or service is with that one's provider (for a host: the provider of its site). A contract without `cost` is listed under `pending`, one nothing names under `gaps`.

### uplinks

An internet line. All fields are optional, so a line can be entered before its details are known.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="uplinks-asn"></span>`asn` | integer ≥ 1 |  | Autonomous system number of the provider's network, without the AS prefix. |
| <span id="uplinks-bandwidth"></span>`bandwidth` | object |  | Booked bandwidth in Mbit/s. |
| <span id="uplinks-bandwidth-down"></span>`bandwidth.down` | integer ≥ 1 | required | Downstream in Mbit/s. |
| <span id="uplinks-bandwidth-up"></span>`bandwidth.up` | integer ≥ 1 | required | Upstream in Mbit/s. |
| <span id="uplinks-contracts"></span>`contracts` | list of id from [contracts](#contracts-1), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="uplinks-ipv4"></span>`ipv4` | one of `public` `cgnat` `none` |  | What the line gives for IPv4. |
| <span id="uplinks-ipv4static"></span>`ipv4Static` | boolean |  | Whether the public IPv4 address is fixed. Only meaningful with ipv4 = public. |
| <span id="uplinks-ipv6"></span>`ipv6` | boolean |  | Whether the line has native IPv6. |
| <span id="uplinks-ipv6prefixlength"></span>`ipv6PrefixLength` | integer 1–128 |  | Size of the IPv6 prefix the provider delegates (e.g. 56 for a /56). Only with ipv6. |
| <span id="uplinks-ipv6static"></span>`ipv6Static` | boolean |  | Whether the delegated IPv6 prefix is fixed. Only with ipv6. |
| <span id="uplinks-medium"></span>`medium` | one of `fiber` `dsl` `cable` `lte` `satellite` `datacenter` |  | Kind of line. |
| <span id="uplinks-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="uplinks-provider"></span>`provider` | id from [providers](#providers-1) |  | Internet provider (for a data centre: the hoster). |

```json
{
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  }
}
```

Rules beyond the schema: `ipv6PrefixLength` and `ipv6Static` only with `ipv6`; every line is used by a site; `contracts` are with the line's `provider`.

### sites

A place where devices stand.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="sites-city"></span>`city` | string | required | City the site is in. |
| <span id="sites-ipv6ula"></span>`ipv6Ula` | string: a ULA /48 like fd12:3456:789a::/48 |  | Unique local IPv6 prefix of the site (RFC 4193, random 40 bits). Only where the lab runs the network; its networks take their /64 by ipv6SubnetId. |
| <span id="sites-kind"></span>`kind` | one of `residential` `hackerspace` `club` `datacenter` | required | Kind of place. club: a club's premises the lab connects to (Remote, issue #84). |
| <span id="sites-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="sites-provider"></span>`provider` | id from [providers](#providers-1) |  | Who runs the place (hoster, club); empty for a home. |
| <span id="sites-uplinks"></span>`uplinks` | list of id from [uplinks](#uplinks-1), no duplicates | required | Internet lines of the site, the primary one first, backups after it. |

```json
{
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ],
      "ipv6Ula": "fd12:3456:789a::/48"
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  }
}
```

Rules beyond the schema: at least one uplink, the primary first; something stands at every site. `ipv6Ula` only where the lab runs the network itself – random once (RFC 4193), never changed afterwards.

### networks

A layer-2 network with its IPv4 prefix.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="networks-dhcppool"></span>`dhcpPool` | object |  | Range the DHCP server hands out dynamically; static addresses must lie outside it. |
| <span id="networks-dhcppool-end"></span>`dhcpPool.end` | string: an IPv4 address | required | Last address of the pool. |
| <span id="networks-dhcppool-start"></span>`dhcpPool.start` | string: an IPv4 address | required | First address of the pool. |
| <span id="networks-dhcpserver"></span>`dhcpServer` | id from [hosts](#hosts-2) |  | The host serving DHCP for IPv4 here; it needs an interface in this network. |
| <span id="networks-ipv4"></span>`ipv4` | string: an IPv4 prefix like 192.0.2.0/24 |  | IPv4 prefix. |
| <span id="networks-ipv6"></span>`ipv6` | string: an IPv6 prefix like 2001:db8::/64 |  | IPv6 prefix, when it is fixed (static GUA). A ULA from the site's ipv6Ula is derived, not entered. |
| <span id="networks-ipv6subnetid"></span>`ipv6SubnetId` | integer 0–65535 |  | Subnet id of the network, decimal (192, often the VLAN id): its /64 inside the site's ipv6Ula and inside the prefix the primary uplink delegates. The hex form is derived. |
| <span id="networks-name"></span>`name` | string | required | Display name. |
| <span id="networks-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="networks-site"></span>`site` | id from [sites](#sites-1) | required | Where the network is. |
| <span id="networks-vlan"></span>`vlan` | integer 1–4094 |  | 802.1Q VLAN id. Leave out for an untagged network. |

```json
{
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "vlan": 192,
      "ipv6": "2001:db8:1::/64",
      "ipv6SubnetId": 192,
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  }
}
```

Rules beyond the schema: the prefix has no host bits; the pool lies inside it, start before end, and needs `ipv4` and `dhcpServer`; the DHCP server is at the site and has an interface in the network; a VLAN id once per site; `ipv6SubnetId` once per site and small enough for the prefix the primary uplink delegates (0–255 for a /56). It is decimal; the derived view adds `ipv6SubnetHex` and the network's ULA `/64`.

### hosts

Every device with an address that matters – managed by this flake or not.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="hosts-availability"></span>`availability` | one of `always-on` `intermittent` | default `"always-on"` | intermittent: being offline is normal (a laptop) and is not an incident. |
| <span id="hosts-contracts"></span>`contracts` | list of id from [contracts](#contracts-1), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="hosts-criticality"></span>`criticality` | one of `core` `service` `lab` | default `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="hosts-inside"></span>`inside` | id from [hosts](#hosts-2) |  | Physically built into another device, e.g. a PCIe KVM card in its host. |
| <span id="hosts-interfaces"></span>`interfaces` | object: name → object |  | Network interfaces by name (as the OS calls them; for an appliance any label like lan/wan). A VLAN interface (eno1.10) is an entry of its own. |
| <span id="hosts-interfaces-name-connector"></span>`interfaces.<name>.connector` | one of `qsfp-plus` `qsfp28` `rj45` `sfp` `sfp-plus` `sfp28` |  | Only ethernet: the port - rj45 or an SFP/QSFP cage. |
| <span id="hosts-interfaces-name-ipv4"></span>`interfaces.<name>.ipv4` | object |  | IPv4 addressing of this interface in its network. |
| <span id="hosts-interfaces-name-ipv4-address"></span>`interfaces.<name>.ipv4.address` | string: an IPv4 address |  | The address - required for reserved and static. |
| <span id="hosts-interfaces-name-ipv4-mode"></span>`interfaces.<name>.ipv4.mode` | one of `reserved` `static` `dhcp` | required | reserved: fixed DHCP lease by MAC; static: configured on the device; dhcp: dynamic. |
| <span id="hosts-interfaces-name-linklocal"></span>`interfaces.<name>.linkLocal` | string: eui64, stable-privacy, random or an fe80:: address |  | How the IPv6 link-local address is formed: eui64 (computed from mac), stable-privacy (RFC 7217), random - or the fixed fe80:: address itself. |
| <span id="hosts-interfaces-name-mac"></span>`interfaces.<name>.mac` | string: a lower-case MAC address like aa:bb:cc:dd:ee:ff |  | Hardware address, lower case. |
| <span id="hosts-interfaces-name-medium"></span>`interfaces.<name>.medium` | one of `ethernet` `wifi` |  | Physical medium. |
| <span id="hosts-interfaces-name-module"></span>`interfaces.<name>.module` | object |  | Only a cage (not rj45): what is plugged into it. |
| <span id="hosts-interfaces-name-module-kind"></span>`interfaces.<name>.module.kind` | one of `dac` `aoc` `sm` `mm` `copper` | required | dac/aoc: a fixed cable; sm/mm: a transceiver for singlemode/multimode fibre; copper: an RJ45 transceiver. |
| <span id="hosts-interfaces-name-module-standard"></span>`interfaces.<name>.module.standard` | one of `1000base-bx` `1000base-lx` `1000base-sx` `1000base-t` `10gbase-bx` `10gbase-er` `10gbase-lr` `10gbase-lrm` `10gbase-sr` `10gbase-t` `2.5gbase-t` `25gbase-lr` `25gbase-sr` |  | Only a transceiver (not dac/aoc): the standard printed on it, e.g. 10gbase-sr. |
| <span id="hosts-interfaces-name-network"></span>`interfaces.<name>.network` | id from [networks](#networks-1) |  | The network this interface is in. |
| <span id="hosts-interfaces-name-note"></span>`interfaces.<name>.note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-interfaces-name-speed"></span>`interfaces.<name>.speed` | one of `10` `100` `1000` `2500` `5000` `10000` `25000` `40000` `100000` |  | Only ethernet: the most this interface can do, in Mbit/s (2500 = 2.5G) - with what sits in its cage, not what the link partner negotiates. |
| <span id="hosts-interfaces-name-wifistandard"></span>`interfaces.<name>.wifiStandard` | one of `wifi4` `wifi5` `wifi6` `wifi6e` `wifi7` |  | Only wifi: the newest Wi-Fi generation the interface supports. |
| <span id="hosts-kind"></span>`kind` | one of `server` `hypervisor` `vm` `container` `router` `switch` `ap` `pdu` `ups` `kvm` `nas` `workstation` `laptop` `phone` `tablet` `watch` `appliance` | required | What the device is. |
| <span id="hosts-managed"></span>`managed` | boolean | required | Configured by this flake (nixosConfigurations/darwinConfigurations). Must match the flake. |
| <span id="hosts-manages"></span>`manages` | list of id from [hosts](#hosts-2), no duplicates |  | Only kvm: the machines this KVM gives out-of-band access to. |
| <span id="hosts-model"></span>`model` | string |  | Hardware model without the vendor (ThinkCentre M720q), or for a VM the provider's product or plan name. |
| <span id="hosts-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-owner"></span>`owner` | id from [owners](#owners-1) | required | Who administers the device. |
| <span id="hosts-power"></span>`power` | id from [hosts](#hosts-2) |  | Where the power comes from: a PDU/UPS, a PoE switch, or the host a card sits in. |
| <span id="hosts-productid"></span>`productId` | string |  | The vendor's product id for drivers and firmware: Lenovo machine type (10T7...), Apple model identifier (Mac16,10). Not for vm/container. |
| <span id="hosts-runson"></span>`runsOn` | id from [hosts](#hosts-2) |  | Only vm/container: the machine it runs on. Optional - a rented VM's host is not in the inventory. |
| <span id="hosts-serial"></span>`serial` | string |  | Serial number. Unique lab-wide. Not for vm/container. |
| <span id="hosts-site"></span>`site` | id from [sites](#sites-1) |  | Where the device is. Optional for entries with runsOn or inside - they inherit it. |
| <span id="hosts-sshhostkeys"></span>`sshHostKeys` | list of string: an OpenSSH public key "<type> <base64>" without comment, no duplicates |  | The device's SSH host public keys (/etc/ssh/ssh_host_*_key.pub without the comment). Feeds known_hosts and the sops check. |
| <span id="hosts-unlock"></span>`unlock` | object |  | Disk unlock after a reboot. Leave it out for an unencrypted disk. |
| <span id="hosts-unlock-fallback"></span>`unlock.fallback` | one of `remote-ssh` `console` |  | How a human unlocks when the methods fail: over SSH (initrd, FileVault) or at the console/KVM. |
| <span id="hosts-unlock-methods"></span>`unlock.methods` | list of one of `tpm` `nbde`, no duplicates | required | Automatic unlock methods. Empty when only a human can unlock. |
| <span id="hosts-unlock-tang"></span>`unlock.tang` | list of id from [hosts](#hosts-2), no duplicates |  | Tang servers for nbde; any one of them is enough. |
| <span id="hosts-unlock-threshold"></span>`unlock.threshold` | integer ≥ 1 | default `1` | How many of the methods must succeed (Clevis sss threshold). Defaults to 1. |
| <span id="hosts-vendor"></span>`vendor` | string |  | Hardware manufacturer (Lenovo, Apple, GL.iNet). Not for vm/container. |

```json
{
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "medium": "ethernet",
          "speed": 10000,
          "connector": "sfp-plus",
          "module": {
            "kind": "mm",
            "standard": "10gbase-sr"
          },
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "medium": "wifi",
          "wifiStandard": "wifi6",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  }
}
```

Rules beyond the schema (the most important ones – [Validation](#validation) has all):

- `site` is required unless it can be inherited along `runsOn` or `inside`, and an explicit one matches the inherited one.
- `runsOn` only for `vm`/`container`, on an allowed kind; `manages` only for `kvm`; `vendor`/`productId`/`serial` not on a `vm`/`container`.
- `runsOn`, `inside` and `power` free of cycles; every host with `nbde` reaches a Tang server that comes up without a human.
- `managed` matches `flake.nix` in both directions.
- Addresses: inside the network's prefix, by mode (`reserved` needs `mac` and a DHCP server, `static` outside the pool), each once per network; MACs and host keys once lab-wide.

### services

What the hosts run, and what is bought from outside.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="services-backup"></span>`backup` | list of object, no duplicates |  | How its data is backed up. Only for stateful. |
| <span id="services-backup-interval"></span>`backup[].interval` | one of `hourly` `daily` `weekly` `monthly` |  | How often it runs. |
| <span id="services-backup-keep"></span>`backup[].keep` | object |  | Which versions are kept - at the target, or on the machine without to. Left out: unknown. |
| <span id="services-backup-keep-all"></span>`backup[].keep.all` | boolean |  | Only true, and only alone: every version is kept, nothing is ever pruned. |
| <span id="services-backup-keep-daily"></span>`backup[].keep.daily` | integer ≥ 1 |  | One per day for the last n days. |
| <span id="services-backup-keep-last"></span>`backup[].keep.last` | integer ≥ 1 |  | The newest n versions. |
| <span id="services-backup-keep-monthly"></span>`backup[].keep.monthly` | integer ≥ 1 |  | One per month for the last n months. |
| <span id="services-backup-keep-weekly"></span>`backup[].keep.weekly` | integer ≥ 1 |  | One per week for the last n weeks. |
| <span id="services-backup-method"></span>`backup[].method` | one of `restic` `arq` `btrbk` `pgdump` `provider-snapshot` `ha-backup` | required | restic/arq copy to another service (to); btrbk, pgdump and provider-snapshot stay on the same machine or provider; ha-backup (Home Assistant's own backup) stays on the machine without to, or goes to an upload target with to. |
| <span id="services-backup-note"></span>`backup[].note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-backup-to"></span>`backup[].to` | id from [services](#services-1) |  | The service the copy goes to - required with restic/arq, optional with ha-backup. |
| <span id="services-contracts"></span>`contracts` | list of id from [contracts](#contracts-1), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="services-criticality"></span>`criticality` | one of `core` `service` `lab` | default `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="services-data"></span>`data` | one of `stateful` `stateless` | required | stateful: it keeps data that is lost with it; stateless: it can be rebuilt from the repository. |
| <span id="services-dependson"></span>`dependsOn` | list of id from [services](#services-1), no duplicates |  | Services it cannot work without. |
| <span id="services-endpoints"></span>`endpoints` | list of object, no duplicates |  | How the service is reached. |
| <span id="services-endpoints-exposure"></span>`endpoints[].exposure` | one of `public` `proxy` `mesh` `lan` `loopback` | required | public: open on the internet from its own host; proxy: through a reverse proxy (name it in via); mesh: only inside the overlay network; lan: only in a local network; loopback: only on the host itself. |
| <span id="services-endpoints-fqdn"></span>`endpoints[].fqdn` | string: a lower-case domain name like cloud.example.org | required | Name it is reached by. |
| <span id="services-endpoints-note"></span>`endpoints[].note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-endpoints-port"></span>`endpoints[].port` | integer 1–65535 |  | Port, when it is not the protocol's default. |
| <span id="services-endpoints-via"></span>`endpoints[].via` | id from [services](#services-1) |  | The service it is reached through - the reverse proxy for exposure proxy (required there). Counts as a dependency. |
| <span id="services-hosts"></span>`hosts` | list of id from [hosts](#hosts-2), no duplicates |  | The machines it runs on. Exactly one of hosts and provider. |
| <span id="services-name"></span>`name` | string | required | Display name. |
| <span id="services-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-package"></span>`package` | string |  | Only on managed hosts: option path of the package in the host's configuration (services.paperless.package) - version, license and language are read from there. |
| <span id="services-provider"></span>`provider` | id from [providers](#providers-1) |  | For a service bought from outside: who runs it. Exactly one of hosts and provider. |
| <span id="services-software"></span>`software` | string |  | The software it is (Paperless-ngx, Garage) - the version comes from package or version. |
| <span id="services-uses"></span>`uses` | list of id from [services](#services-1), no duplicates |  | Services it works without, but degraded (new logins fail, one feature is missing). |
| <span id="services-version"></span>`version` | string |  | Version, by hand - only where there is no package to read it from. |

```json
{
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

Rules beyond the schema: exactly one of `hosts` and `provider`; `package` only on managed hosts and not together with `version`; no `core`/`service` service on an `intermittent` host; no hard dependency (`dependsOn`, `via`) on a less critical service, and none in a cycle; `via` required with `exposure` `proxy`; every `fqdn` once; `backup` only for `stateful`, `to` exactly with `restic`/`arq`. A `stateful` service whose backups all stay on its own hosts – `storage` above – is listed under `gaps`.

### A complete example

A valid inventory with every section – the source of the examples above, `docs/inventory-example.json`. Copy it as a start; `"$schema": "./inventory.schema.json"` at the top gives the editor its completion.

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  },
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  },
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  },
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  },
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ],
      "ipv6Ula": "fd12:3456:789a::/48"
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  },
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "vlan": 192,
      "ipv6": "2001:db8:1::/64",
      "ipv6SubnetId": 192,
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  },
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "medium": "ethernet",
          "speed": 10000,
          "connector": "sfp-plus",
          "module": {
            "kind": "mm",
            "standard": "10gbase-sr"
          },
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "medium": "wifi",
          "wifiStandard": "wifi6",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  },
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

What `just inventory` derives from it, for instance: `hosts.club-vm.site` is `club` (inherited from `pve`); `services.docs.upstreamHosts` is `club-vm`, `pve`, `vps`; `providers.hoster.affects` is `docs`, `login`, `proxy`; `costs.monthly` is `{"EUR": 6145, "USD": 250}`, and November carries the 30.00 USD of the mail contract in `costs.byMonth`.

### In the editor

`inventory.json` starts with `"$schema": "./inventory.schema.json"`. Editors that read JSON Schema (VS Code, Zed, IntelliJ, Neovim with a JSON language server) then offer the fields as completion, show the descriptions of the tables above on hover, and underline wrong types, unknown fields and malformed values while typing. References and every rule between entries are only checked by `nix flake check` (or `just inventory-test`).

After changing `spec` in `inventory.nix`: `just inventory-schema` and `just inventory-diagram`, a test case in `tests/inventory.nix`, and – if the example should show the new field – `docs/inventory-example.json`. The checks fail until all of it is in step.

## Lab map

Every machine and every service of the [inventory](#inventory), by site: at the top each site's line with its networks, below it the hosts with the services they run, at the bottom the services bought in, by provider. A click on a service or a host draws what it depends on, what it uses, where it is backed up to and what it is reached through, and shows its entry next to the map; the names there can be clicked again. On the right of a service, one tag per endpoint tells how it is reached: `pub` public, `prox` through a proxy, `mesh` mesh only, `lan` LAN only; a click on one selects the service with that endpoint. A click on an empty spot of the map enlarges it.

<figure class="nx-labmap" data-default="mail">
<div class="stats"><div><b>7</b><span>hosts</span></div><div><b>4</b><span>managed by the flake</span></div><div><b>5</b><span>services run here</span></div><div><b>1</b><span>bought in</span></div><div><b>3</b><span>sites</span></div><div><b>4</b><span>providers</span></div></div>
<div class="nx-lm-layout">
<div class="nx-lm-map"><svg class="nx-lm-edges" aria-hidden="true"></svg>
<div class="nx-lm-sites">
<section class="site" style="flex: 1 1 200px"><div class="site-head"><div class="row"><span class="site-code">dc</span><span class="site-city">Exampleburg · data centre · Example Hosting</span></div><div class="uplink">Example Hosting · AS64497 · DC uplink · IPv4 static · IPv6</div></div><div class="hosts one"><div class="host" data-hostcard="vps" tabindex="0" role="button" aria-label="Host vps"><div class="host-top"><span class="host-name">vps</span></div><div class="host-kind">VM · VPS M</div><div class="pills"><span class="pill core">core</span><span class="pill managed">flake</span></div><div class="chips"><span class="svc stateful c-core" data-svc="login" data-host="vps"><button type="button" class="nm" title="Example IdP">Login</button><span class="x"><button type="button" class="tg" data-ep="0" title="auth.example.org · public">pub</button></span></span><span class="svc c-core" data-svc="proxy" data-host="vps"><button type="button" class="nm" title="Reverse proxy">Reverse proxy</button><span class="x"><button type="button" class="tg" data-ep="0" title="proxy.example.org · public">pub</button></span></span></div></div></div></section>
<section class="site" style="flex: 1 1 200px"><div class="site-head"><div class="row"><span class="site-code">club</span><span class="site-city">Exampletown · hackerspace · Example hackerspace</span></div><div class="uplink">None · cable · IPv4 static · IPv6</div><div class="nets"><span class="net" title="Hackerspace LAN">198.51.100.0/24 · VLAN 10</span></div></div><div class="hosts one"><div class="host" data-hostcard="pve" tabindex="0" role="button" aria-label="Host pve"><div class="host-top"><span class="host-name">pve</span><span class=ip>198.51.100.2</span></div><div class="host-kind">hypervisor</div><div class="pills"><span class="pill ext">owned by Example hackerspace</span></div><div class="guest"><div class="host" data-hostcard="club-vm" tabindex="0" role="button" aria-label="Host club-vm"><div class="host-top"><span class="host-name">club-vm</span></div><div class="host-kind">VM · Proxmox VM</div><div class="pills"><span class="pill managed">flake</span></div><div class="chips"><span class="svc stateful" data-svc="docs" data-host="club-vm"><button type="button" class="nm" title="Documents">Documents</button><span class="x"><button type="button" class="tg" data-ep="0" title="docs.example.org · through a proxy">prox</button></span></span><span class="svc" data-svc="route" data-host="club-vm"><button type="button" class="nm" title="Overlay routing peer">Route into the hackerspace</button></span></div></div></div></div></div></section>
<section class="site" style="flex: 3 1 600px"><div class="site-head"><div class="row"><span class="site-code">home</span><span class="site-city">Exampletown · home</span></div><div class="uplink">Example ISP · AS64496 · fibre · ↓600 ↑300 Mbit/s · IPv4 dynamic · IPv6 /56 dyn.<br>None · LTE · IPv4 dynamic</div><div class="nets"><span class="net" title="Home LAN">192.0.2.0/24 · VLAN 192 · DHCP router</span></div></div><div class="hosts"><div class="host" data-hostcard="router" tabindex="0" role="button" aria-label="Host router"><div class="host-top"><span class="host-name">router</span><span class=ip>192.0.2.1</span></div><div class="host-kind">router · Example Networks R1</div><div class="pills"><span class="pill core">core</span></div></div><div class="host" data-hostcard="laptop" tabindex="0" role="button" aria-label="Host laptop"><div class="host-top"><span class="host-name">laptop</span></div><div class="host-kind">laptop · Example Corp Book 14</div><div class="pills"><span class="pill lab">lab</span><span class="pill managed">flake</span><span class="pill ext">intermittent</span></div></div><div class="host" data-hostcard="nas" tabindex="0" role="button" aria-label="Host nas"><div class="host-top"><span class="host-name">nas</span><span class=ip>192.0.2.10</span></div><div class="host-kind">NAS · Example Corp NAS 4</div><div class="pills"><span class="pill managed">flake</span></div><div class="chips"><span class="svc stateful" data-svc="storage" data-host="nas"><button type="button" class="nm" title="Example S3">S3 storage</button><span class="x"><button type="button" class="tg" data-ep="0" title="s3.example.org:3900 · LAN only">lan</button><button type="button" class="tg" data-ep="1" title="s3-console.example.org · through a proxy">prox</button></span></span></div><div class="guest"><div class="host" data-hostcard="kvm" tabindex="0" role="button" aria-label="Host kvm"><div class="host-top"><span class="host-name">kvm</span></div><div class="host-kind">KVM</div><div class="pills"><span class="pill lab">lab</span></div></div></div></div></div></section>
<section class="site" style="flex: 1 1 100%"><div class="site-head"><div class="row"><span class="site-code">External</span><span class="site-city">services bought in or hosted elsewhere</span></div></div><div class="ext-groups"><div class="prov"><div class="prov-name">Example Mail</div><div class="chips"><span class="svc stateful" data-svc="mail"><button type="button" class="nm" title="Mail">Mail</button></span></div><div class="contract">30 USD/year</div></div></div></section>
</div></div>
<div class="nx-lm-aside"><div class="box nx-lm-detail"><div class="box-title">Selection</div><p class="hint">Click a service or a host to see its dependencies and details.</p></div><div class="box legend-box"><div class="box-title">Legend</div><div class="legend"><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-dep"/></svg>depends on</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-use"/></svg>uses (optional)</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-bak"/></svg>backed up to</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-via"/></svg>reached through</div><div><span class="svc stateful demo"><span class="nm">service</span></span> holds data <span class="svc demo"><span class="nm">service</span></span> stateless</div><div class="abbr"><span class="tg">pub</span> public · <span class="tg">prox</span> through a proxy · <span class="tg">mesh</span> mesh only · <span class="tg">lan</span> LAN only</div><div><span class="pill core">core</span><span class="pill service">service</span><span class="pill">lab</span><span class="pill managed">flake</span> criticality, managed by the flake</div></div><label class="toggle"><input type="checkbox" class="nx-lm-all"> Show every relation</label><button type="button" class="nx-lm-zoom">Enlarge</button></div></div>
</div>
</figure>

The map is generated from `inventory.json` on every docs build (`docs/gen-lab-map.py`), so it cannot go stale. SSH host keys, serials and MAC addresses are not in it. The PDF shows sites, hosts and services without the lines.

## Services

Services are named by function, not by product. There are three kinds of reachability: public directly, public behind the NetBird reverse proxy with SSO, or mesh only.

| Name (`.homelab.example`) | App | Host | Reachable |
| --- | --- | --- | --- |
| `auth` | Pocket ID | zummi | public (nginx) |
| `mesh` | NetBird management/dashboard | grammi | public (Traefik terminates TLS) |
| `s3.aldrin` | Garage S3 API | aldrin | public (nginx) |
| `cloud` | OpenCloud | aldrin | public (nginx), login via Pocket ID; not behind the reverse proxy, its SSO would stop the sync clients |
| `tabs` | WebDAV for floccus (rclone) | aldrin | public (nginx), one account with basic auth ([why](#floccus-tabs-and-bookmarks-through-tabs)) |
| `rezepte` | Mealie | grammi | reverse proxy + SSO |
| `grist` | Grist | grammi | reverse proxy + SSO |
| `logs` | logchef | grammi | reverse proxy + SSO |
| `metrics` | Grafana | grammi | reverse proxy + SSO |
| `dash` | Grafana, public dashboards only | grammi | reverse proxy without login, Traefik passes only the public-dashboard paths ([why](#grafana-public-dashboards-through-dash)) |
| `vm` / `vl` | VictoriaMetrics / VictoriaLogs UI | grammi | reverse proxy + SSO |
| `alertmanager` / `alerts` | Alertmanager UI (alerts, silences) | grammi | reverse proxy + SSO, `homelab_admins` only ([Alerting](#alerting)) |
| `s3-admin` | garage-ui | aldrin | mesh only |
| `dokumente` | Paperless + paperless-gpt (`/paperless-gpt/`) | ursalia | in the mesh directly; from outside, through the reverse proxy, share links via PIN and the app via SSO ([why](#paperless-from-outside-share-links-pin-and-the-app-sso)) |
| `llm` | Ollama (behind Caddy) | zorlock | mesh only |
| `health` | [HealthLog](https://github.com/MBombeck/HealthLog) ([`0497d60`](https://github.com/MBombeck/HealthLog/tree/0497d60a893784e709899cdb6fbdf155ef29e3e3) by Marc Bombeck) | ursalia | mesh only (the iOS app needs NetBird too), login via Pocket ID only (group `healthlog_users`); its own encrypted off-host copies in Garage on aldrin (bucket `healthlog-backups`, 30 days) |
| `bambuddy` | [Bambuddy](https://github.com/maziggy/bambuddy) ([`98ecaf5`](https://github.com/maziggy/bambuddy/tree/98ecaf5020e3a20a5de49859b8ad5a754d5ad85c) by MartinNYHC) | ursalia | through the reverse proxy with SSO (groups `bambuddy_user` / `bambuddy_admin`), then Bambuddy's own login via Pocket ID; printers by IP in LAN mode; virtual printer for Bambu Studio on ursalia's LAN address (ports in the home LAN only, from outside via the NetBird route into the home LAN) |
| `inv` | [OpenInvento](https://github.com/openinvento/openinvento) (mrtncode), test system from upstream `main` and unreleased branches | ursalia | through the reverse proxy with SSO (groups `inventar_users` / `inventar_admins`), then login via Pocket ID without another prompt; image built locally with `just openinvento-image` |
| `dns` | [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) | ursalia | DNS for the home LAN (53, DoT/DoQ 853, DoH) and people's devices in the mesh (NetBird nameserver group) ([why](#dns-with-adguard-home)) |
| `adguard` | AdGuard Home, admin UI | ursalia | through the reverse proxy with SSO (`homelab_admins`), then AdGuard's own login ([why](#dns-with-adguard-home)) |
| `mqtt` | Mosquitto (Home Assistant add-on) | Home Assistant (home LAN, NetBird peer) | port 8883, MQTT over TLS: at home straight to HA (home router (Flint 4) answers the name locally), from outside through the reverse proxy as TLS passthrough to the peer, no SSO ([why](#mqtt-from-outside-tls-passthrough-to-home-assistant)) |
| `acme` | dns01proxy (DNS-01 for Home Assistant) | grammi | mesh only, port 8446; HA resolves it through the home router (Flint 4) ([why](#mqtt-from-outside-tls-passthrough-to-home-assistant)) |
| `doku` | This documentation (private version) | aldrin + ursalia | in the mesh admin devices only ([why](#private-docs-admin-devices-home-lan-login)), one A record per host; in the home LAN through a record of the router's own to ursalia, except a deny list; from outside a redirect to the public docs through the reverse proxy, `/login` to `doku-login` |
| `doku-login` | This documentation (private version) from the internet | aldrin | through the reverse proxy with SSO (group `docs-readers`), only with the proxy's secret header |

**Reverse proxy:** Traefik on grammi owns port 443. It terminates `mesh.homelab.example` itself and hands everything else via TCP passthrough with PROXY protocol v2 to `netbird-proxy`, which does TLS and ACME (tls-alpn-01) on its own. Login at the proxy is SSO against Pocket ID, limited to the NetBird groups of the respective app; `dokumente` additionally with a PIN (share links only). The proxy reaches every service on grammi through the Traefik entrypoint `apps` (port 8090), which puts the maintenance switch and error pages in front ([maintenance mode](#maintenance-mode)).

**Mesh-only names:** Every name is its own NetBird DNS zone with one A record pointing at the mesh address (192.0.2.x). Public DNS does not know them; the certificate comes via DNS-01 through deSEC.

**Across all Linux hosts:** vmagent ships metrics, Vector ships journald and nginx logs to grammi. CrowdSec reads the nginx/Traefik logs on the public hosts. restic backups go to Garage buckets on aldrin, for Paperless additionally append-only to BorgBase.

## Modules

The 20 modules under `modules/` carry the configuration shared by all hosts; every file explains in its header comment why it is the way it is. The public version contains them anonymised under `modules/` – as a reference, not directly importable: some read `hosts/<host>/*.yaml` and assume sops-nix. Five have options of their own.

| Module | Purpose | Options / notes |
| --- | --- | --- |
| [auto-upgrade-git.nix](modules/auto-upgrade-git.nix) | Nightly `nixos-rebuild switch`, commits and pushes the new `flake.lock` back to the repo | `services.autoUpgradeGit`: `enable`, `flakeDir`, `flakeAttr`, `updateInputs`, `dates`, `allowReboot`, `rebootWindow`, `deployKeySecret`, `gitAuthorEmail`, `holdFile`, `holdCheck`, `pull` |
| [log-shipping.nix](modules/log-shipping.nix) | journald and nginx logs to VictoriaLogs via Vector | `services.logShipping`: `enable`, `victoriaLogsUrl` |
| [metrics-shipping.nix](modules/metrics-shipping.nix) | vmagent scrapes the local exporters and remote-writes to VictoriaMetrics | `services.metricsShipping`: `enable`, `remoteWriteUrl`, `exporterPorts` |
| [disk-health.nix](modules/disk-health.nix) | SMART of physical disks: smartd self-tests (short weekly, extended monthly, staggered per disk), smartctl_exporter, `smart_selftest_*` textfile metrics, dashboard Disk Health | `services.diskHealth.devices` (by-id paths; the order decides the test slot); on ursalia and tummi |
| [home-wifi.nix](modules/home-wifi.nix) | WLAN on the home network "homelab": 5 GHz preferred, all bands as fallback, passphrase from sops, optionally a wired port with a higher metric as fallback, WLAN metrics (`wifi_link_*`) | `services.homeWifi`: `enable`, `interface`, `wiredFallback`; on tummi |
| [samba-mesh.nix](modules/samba-mesh.nix) | Samba for the mesh only: SMB3, macOS friendly, no guests, no NetBIOS; passwords of the Samba accounts from sops | `services.sambaMesh`: `enable`, `users`; shares, accounts and ACLs stay with the host; on ursalia and tummi |
| [deploy-hold.nix](modules/deploy-hold.nix) | Hold for `just try`: `nixos-hold`, metric `nixlab_deploy_hold_since_seconds`, warning in the login shell | on cuckoosegg too – [Test a branch before merging](#test-a-branch-on-a-host-before-merging) |
| [deploy.nix](modules/deploy.nix) | The lab's policy for auto-upgrade-git: GitHub deploy key, pinned host key, reboot window 04:00–06:00 | kept apart from the mechanism so that stays reusable |
| [nix-cache.nix](modules/nix-cache.nix) | The lab's own binary cache in Garage (`s3://nix-cache`): substituter and read key on every host; on ursalia the nightly lock update, build of every host and upload | `services.nixCache.prebuild`: `enable`, `updateInputs`, `dates`; secrets from `just nix-cache-secrets` |
| [acme.nix](modules/acme.nix) | ACME defaults for every TLS host: DNS-01 against deSEC | token from `hosts/<host>/desec.yaml` (from Tofu) |
| [netbird.nix](modules/netbird.nix) | NetBird client in the mesh, registration via setup key, local metrics | setup key from `hosts/<host>/netbird.yaml` (from Tofu) |
| [tailscale.nix](modules/tailscale.nix) | Shared Tailscale agent | `tailscale serve` stays in the host config |
| [ssh.nix](modules/ssh.nix) | Who may log in from where: root only via mesh or Tailscale | keys stay per host |
| [firewall.nix](modules/firewall.nix) | Only 22/80/443 public, tailnet as trusted interface | |
| [crowdsec.nix](modules/crowdsec.nix) | CrowdSec engine and firewall bouncer, whitelist for the lab hosts and for nix cache lookups | workarounds for bugs in the nixpkgs modules, documented in the header |
| [networking.nix](modules/networking.nix) | ifstate skeleton, systemd-resolved with DNS over TLS, no fallback resolvers | addresses and routes stay in the host config |
| [metrics.nix](modules/metrics.nix) | Prometheus exporters per host | protected by the firewall instead of bind addresses |
| [logging.nix](modules/logging.nix) | Bounds journald, which otherwise grows up to 4 GB | |
| [qemu-guest.nix](modules/qemu-guest.nix) | QEMU guest agent with an RPC deny list: snapshots yes, shell and file access over the channel no | |
| [watchdog.nix](modules/watchdog.nix) | Hardware watchdog held by systemd: PID 1 opens the device and pings it every half timeout; if PID 1 or the kernel hangs, the hardware resets the host. Holding it also keeps any other process (procd in a container, #117) from arming it. Marker metric `nixlab_hardware_watchdog_enabled`, alert `HardwareWatchdogInactive` | `services.hardwareWatchdog`: `enable`, `device` (default `/dev/watchdog0`), `softdog`, `blacklistedModules` (other watchdog drivers, so there is exactly one); timeout = the device's own (`RuntimeWatchdogSec=default`); on ursalia and tummi (`iTCO_wdt` blacklisted), aldrin and grammi (QEMU iTCO), cuckoosegg (i6300esb from Proxmox); `softdog` (kernel software watchdog, plus `kernel.panic=10` and `softlockup_panic`) on zummi |
| [nix.nix](modules/nix.nix) | Nix daemon, garbage collection, store optimisation | |
| [docs-site.nix](modules/docs-site.nix) | The private docs site (flake package `docs-site`) under `doku` on the mesh | `services.docsSite`: `enable`, `package`, `fqdn`, `allow` (default: the whole mesh; in the lab only the admin devices from `admin-peers.json`); on aldrin and ursalia |
| [maintenance.nix](modules/maintenance.nix) | Maintenance mode for nginx and Traefik: a flag file switches a name to a 503 page, the same page on 502/504 | `services.maintenance`, see [Maintenance mode](#maintenance-mode) |
| [hotfixes.nix](modules/hotfixes.nix) | Package hotfixes that switch themselves off and warn once nixpkgs has the fix | module argument `hotfix`, overlays from `modules/hotfixes/`, see [Hotfix a package](#hotfix-a-package) |
| [base.nix](modules/base.nix) | Locale, console, time and tools for debugging | |

## just recipes

| Recipe | Purpose |
| --- | --- |
| `just try <host>` | Deploy the current topic branch to a host and hold it there until the branch is merged ([Test a branch before merging](#test-a-branch-on-a-host-before-merging)) |
| `just try-confirm <host> [minutes] [via]` | Like `try`, but rolls itself back unless the host is reached and confirmed within the deadline ([with automatic rollback](#with-automatic-rollback-just-try-confirm)) |
| `just release <host>` / `holds` | Drop a hold without merging / list every hold |
| `just restore-test <host> [isolation]` | Restore grammi or zummi from restic into a throwaway VM on ursalia without network and measure the RTO ([Test a restore](#test-a-restore)) |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Edit host secrets on the host and fetch them back |
| `just topology` | Regenerate the topology dashboard (otherwise `nix flake check` fails) |
| `just inventory` | Show the validated inventory with everything derived ([Inventory](#inventory)) |
| `just inventory-test` | Check `inventory.json`, run the validator tests, check the schema is fresh |
| `just inventory-schema` | Regenerate `inventory.schema.json` after a format change |
| `just inventory-diagram` | Regenerate the diagram of all fields on [Inventory schema](#inventory-schema) after a format change |
| `just inventory-collect [--force] [host …]` | Fetch SSH host keys, interfaces (MAC, medium, link-local) and hardware (vendor, model, product id, serial) from the devices into `inventory.json` – fills gaps and reports differences; `--force` takes the device values |
| `just services [--json]` | What the inventory's services run, from the host configurations: version, license, language ([Software view](#software-view)) |
| `just sbom [host …]` | SBOM (CycloneDX, SPDX, CSV) of the running system of each host into `sbom/` ([Software view](#software-view)) |
| `just wifi-qr [ssid]` | A WLAN of gruffi: SSID, PSK, encryption and a QR code to join it, from `openwrt/gruffi/uci.nix` and its `secrets.yaml` (prints the PSK); without an SSID the list of WLANs |
| `just known-hosts` | Write `~/.ssh/known_hosts.nixlab` from the inventory – for a workstation outside this repo; gusto gets the keys system-wide |
| `just netbird-plan` / `netbird-apply` | Change the NetBird account; apply also rewrites `expected-peers.json` (commit it, deploy grammi) and `admin-peers.json` (commit it, deploy aldrin and ursalia) |
| `just netbird-proxy-certs` | Get proxy services without a certificate one and bring the dashboard up to date (NetBird #7118); runs at the end of `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | New random PIN for Paperless share links from outside (then `netbird-apply`), or show the current one |
| `just netbird-key <host>` | New setup key for a host, 24 h to deploy |
| `just netbird-import` | Rebuild the Tofu state from the account – only needed when git does not have it either ([Tofu state](#tofu-state)) |
| `just netbird-renew-token` | Yearly renewal of the service user token |
| `just tf-state-passphrase` | Once: the passphrase for the Tofu states into `terraform/secrets.yaml` (never overwrites) |
| `just github-key <host>` | New GitHub deploy key for a host (key via sops, registration via Tofu) |
| `just github-plan` / `github-apply` | Change the repositories and deploy keys on GitHub |
| `just garage-plan` / `garage-apply` | Change the buckets, keys and permissions in Garage on aldrin (`terraform/garage`) |
| `just garage-admin-token` | Copy Garage's admin token from aldrin into `terraform/secrets.yaml` over SSH – once per workstation key, and again after rotating it |
| `just desec-key <host>` / `desec-verify` | Rotate a deSEC token, or check the scopes from every host |
| `just nanokvm-mcp-key` | Store the NanoKVM Go+ MCP API key encrypted for ursalia (then commit, deploy ursalia) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude Code bridge to the NanoKVM Go+ on ursalia: set up once, start, stop, state, log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (default gusto, or zorlock over SSH): show what a switch would change (nvd, Homebrew removals/installs), or switch with a summary – see [macOS hosts](#macos-hosts) |
| `just apps [term] [--host h]` / `apps-list [host]` / `apps-rm <name> [host]` | Software of a Mac (`hosts/<host>/apps.json`): a round of searching nixpkgs, Homebrew and the App Store, adding (after a pin check) and removing, then one switch and one commit; list; remove one entry – on gusto also as `apps`, `apps-list`, `apps-rm` from any directory, see [Software on the Macs](#software-on-the-macs) |
| `just mac-upgrade` | On gusto: update the Homebrew pins, switch, `brew upgrade`, NetBird version next to the mesh pin; commit `flake.lock` |
| `just gc <host>` | Delete store generations older than 7 days |
| `just docs` | Build this documentation: private PDFs (de/en) and the anonymised public version (README, PDFs, site sources, modules) in `public-docs/` (gitignored clone of `nixlab-docs`), committed and pushed there; GitHub builds the site from it |
| `just docs-serve` | Build the private site with real values locally and serve it at `http://127.0.0.1:8000` |

Recipes that need sops get the workstation's age key from 1Password through `SOPS_AGE_KEY_CMD`. On gusto home-manager sets it and `op` unlocks through the 1Password app (Touch ID); sops, tofu and age come from the devShell (direnv in the checkout). Without that setup:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```

## Troubleshooting

- After a `nixos-rebuild`, `systemctl --failed` says nothing about the past – the switch clears failed states. Use `journalctl -u <unit>` instead.
- NetBird down, Tailscale still there: put `NIXLAB_DOMAIN=example-tailnet.ts.net` in front of the recipe.
- Tofu recipes refuse to run against an empty state, so no second `servers` group or set of tokens gets created.
- WLAN on tummi: `iw dev wlo1 link` shows band, signal and PHY mode. The router's 5 GHz radio is on channel 36-48 (no DFS) with a 100 TU beacon interval; band, signal, rates and PHY mode also go to VictoriaMetrics (node_exporter `wifi` collector plus `wifi_link_*`), Grafana dashboard "Homelab / WLAN".
- After a network change NetBird can keep a dead P2P path for minutes while still showing `Connected` (seen on ursalia, 2026-10-19). Fix: `systemctl restart netbird-mesh` on the host, via Tailscale if the mesh is down.
- A proxy service hangs at "Issuing certificate…" in the NetBird dashboard or fails the TLS handshake from outside ("internal error"): `just netbird-proxy-certs` – requests the names without a certificate from outside and restarts `netbird-proxy` on grammi (NetBird discussion #7118). Also runs at the end of `just netbird-apply`.
- A host restarted with no shutdown in the journal: look for the hardware watchdog in the previous boot, `journalctl -b -1 -k | grep -i watchdog` ("watchdog did not stop!" means some process armed it and let go without the magic close). Where `services.hardwareWatchdog` is on, systemd holds the device and any other process gets EBUSY; `fuser -v /dev/watchdog0` shows who holds it, `wdctl` the timeout. Test: `kill -SEGV 1` must reset the host within one timeout (#117).

## Conventions

- One git worktree per topic (`.worktrees/<topic>`), removed and its branch deleted when done. Tofu state always stays in the main checkout (encrypted and committed, see [Tofu state](#tofu-state)).
- Plan first, implement after approval.
- Subdomains by function (`rezepte`, not `mealie`).
- New web services on grammi use PostgreSQL instead of SQLite.
- Dual stack wherever possible.
- Code comments explain the *why*, including the mistakes that led to a decision, with a date.
- Code comments, commit messages and changelogs in English; the project documentation exists in German and English.
- The docs site loads nothing from third parties: the fonts and glightbox ship with the site (`docs/assets.nix`) instead of coming from Google Fonts or unpkg.com. Why: GDPR, and private docs that work without internet access.
- Infrastructure that mainly fills a role at one place (gateways, access points, switches) is named `<role>-<site>`: `gw-hq`, `ap-flur`. The role comes first so devices of the same role sit next to each other in lists and dashboards; the site is in the inventory anyway. The lab's own servers keep their Gummi Bears names.
- Interface names are limited to 15 characters on Linux. For `tun-<site>-uplink<n>` (`tun-hq-uplink1`) that means a site code of at most three characters.
- Whenever a flow, a structure or a relationship is quicker to grasp as a picture than as text (traffic flows, dependencies, layers), the page gets a diagram, and always a zoomable, clickable one like the inventory schema: boxes jump to their section, a click elsewhere enlarges it. No diagram as an `<img>` or as a plain picture without jumps when the page has sections it can point to.
- Diagrams in the docs are inline SVG in `<figure class="nx-diagram">` (viewBox 680 wide, no `width`/`height`), so boxes can link to sections of the page and a click elsewhere on the diagram enlarges it (in the site's lightbox): `<a data-target="<heading id>" tabindex="0" role="link">` around the box, without `href` – the theme throws on SVG links with one, and `site/common/javascripts/diagrams.js` does the jump (click and Enter). No markers for arrowheads, but paths in the line's colour, since WeasyPrint cannot do `context-stroke` in the PDF. Light colours sit in the SVG's own `<style>`, the dark scheme in `site/common/stylesheets/diagrams.css`, which only the site loads. Check with `just docs-serve` (both colour schemes) and in the PDF.
- The exception is the [lab map](#lab-map): HTML rather than SVG, generated from `inventory.json` (`docs/gen-lab-map.py`), because it shows every host and service and must not go stale. Clickable there means: a click on a service or host selects it and draws its relations (`site/common/javascripts/lab-map.js`); a click on an empty spot enlarges it in the lightbox. The PDF shows it without the lines (`doc.css`).
- Every page of the site is also there as plain Markdown, at its source path (`how-to/new-host.md` next to `how-to/new-host/`), with an index `llms.txt` and all pages in one file `llms-full.txt` ([llms.txt](https://llmstxt.org)) – English at the root, German under `de/`. For language models: Markdown costs them far fewer tokens than the HTML pages. `docs/gen-llms.py` writes them after the Zensical build, on both sites. A diagram is replaced there by its `aria-label`, so every diagram needs one that says in a sentence what it shows; the lab map becomes its JSON data block. The description in `llms.txt` is the first sentence of the page's first paragraph.

## Open items

- [ ] NetBird provider: replace the build from PR #215 (IPv6 overlay) with the registry version again once it is released ([exit nodes & IPv6](#provider-from-pr-215))
- [ ] Home Assistant: check whether `trusted_proxies`/`trusted_networks` know only `192.0.2.0/24` and add `2001:db8:203:0::/64` (not in the repo)
- [ ] Upstream PRs to the NetBird provider (#247 `direct_upstream`/cluster targets, #248 `crowdsec_mode`); then switch the proxy targets on grammi to `localhost`
- [ ] NetBird: narrow `servers-to-servers` to the ports in use (ingest 8428/9428, Garage 443, dns01proxy 8446, exporters, SSH for deploys, llm) – all ports today ([Who reaches the servers](#who-reaches-the-servers))
- [ ] NetBird: feature request for ICMP types in policies ([netbird#8447](https://github.com/netbirdio/netbird/discussions/8447)); until then `to-servers-icmp` allows every ICMP type, not just ping ([Who reaches the servers](#who-reaches-the-servers))
- [ ] Remove Tailscale from the servers once nothing depends on it any more
- [ ] Grafana alerting (contact point still missing) for SMART, fwupd, Paperless, NetBird expected ≠ known, ursalia's WLAN (not associated, stuck on 2.4 GHz, weak signal)
- [ ] Update notifications for the inputs pinned by hand (NetBird, Pocket ID)
- [ ] Declarative root passwords via sops
- [ ] Keep the host list in one place instead of `flake.nix`, the Tofu modules and `justfile`
- [ ] gusto: after the first switch check whether the NetBird app updates itself (or follows the dashboard's auto-update) and switch that off, so the version comes from `netbirdio-tap` only
- [ ] gusto: default git address `admin@homelab.example` instead of `mail@admin.org`, together with a new layout of `~/Projects`
- [ ] Inventory: a field for a device's DNS name (arkkvm answers as `arkkvm01`, today only in its note), and public addresses for the managed hosts – then `hosts/gusto/ssh.nix` derives its fallback names from them
- [ ] Docs site: `<link rel="alternate" type="text/markdown">` in every HTML page, pointing to its Markdown version (`docs/gen-llms.py`) – needs a theme override, so only once Zensical is at 1.0
