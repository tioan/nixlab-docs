# NixOS & OpenTofu

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

## The touch points { #touch-points }

### NetBird setup key { #netbird-setup-key }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/netbird.yaml` | `just netbird-key <host>` (`tofu output setup_keys` → `sops encrypt`) | `modules/netbird.nix` (`sopsFile`) | One-time setup key, valid for 24 h |

The flow for a new host: Tofu creates the setup key, `just netbird-key` writes it encrypted for exactly that host (age key derived from its SSH host key) to `hosts/<host>/netbird.yaml`, commit, deploy within 24 h. The host registers itself on start; Tofu does not manage peers, it looks them up by name via `data "netbird_peer"`.

### deSEC token { #desec-token }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/desec.yaml` | `just desec-key <host>` (`tofu output acme_tokens` → `sops encrypt`) | `modules/acme.nix` (`sopsFile`) | deSEC token for TXT records only, VMs pinned to their IP |

### Expected and admin peers { #peers }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `terraform/netbird/expected-peers.json` | `just netbird-apply` (`tofu output expected_peers`, computed from the policies in `expected-peers.tf`) | `hosts/grammi/netbird-expected-peers.nix` (`builtins.readFile`) | Expected NetBird peers per host as metric `netbird_expected_peers`, next to the real network map in the NetBird dashboard (e.g. aldrin 6, grammi 8) |
| Tofu → NixOS | `terraform/netbird/admin-peers.json` | `just netbird-apply` (`tofu output admin_peers`, from the group `admin-workstations`, `admin-peers.tf`) | `flake.nix` (`builtins.readFile`, option `services.docsSite.allow`) | Mesh addresses of the admins' devices – who may read the private docs |

### proxy-services.json { #proxy-services }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| shared | `hosts/grammi/proxy-services.json` | by hand | `terraform/netbird/reverse-proxy.tf` (`jsondecode(file(...))`) and `topology.nix` | Name → app, port, groups of the reverse proxy services |

### GitHub deploy key { #deploy-key }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| repo → both | `hosts/<host>/github.yaml` + `github-deploy.pub` | `just github-key <host>` (`ssh-keygen` → `sops encrypt`) | private half: `modules/deploy.nix` (`sopsFile`); public half: `terraform/github` (`file(...)`) | Deploy key for `/etc/nixos`; Tofu only ever sees the public half |

### NixOS → Tofu { #nixos-to-tofu }

| Direction | File | Created by | Read by | Contents |
| --- | --- | --- | --- | --- |
| NixOS → Tofu | NetBird server on grammi | `hosts/grammi/netbird.nix` | provider via `https://mesh.homelab.example` | The API Tofu runs against in the first place |
| NixOS → Tofu | Bootstrap tokens | `just netbird-setup-owner`, `netbird-proxy-token` (SSH to grammi, server API) | `terraform/netbird/secrets.yaml` and `hosts/grammi/netbird-proxy.yaml` | Owner PAT, proxy token |

## What is deliberately not wired { #not-wired }

- **No shared host list.** Hosts are listed three times: `nixosConfigurations` in `flake.nix`, `local.hosts` in the Tofu modules and `hosts :=` in the `justfile`. A new host has to be added in all three places.
- **No terranix / no Tofu in the Nix build.** Tofu state is local (gitignored, in the main checkout, also from worktrees) because it holds setup keys and tokens in plain text.
- **No provisioning of the machines.** The VMs are created by hand at the provider, ursalia/cuckoosegg following `docs/install-*.md`.
- **Public DNS** lives in DNSControl (its own repo, only linked in via symlink), not in Tofu.

So the line is: whatever Nix can build deterministically from the repo, Nix does. Whatever is created once through an API and returns a secret, Tofu does – and hands it over encrypted as a file.
