# Modules (generated)

Generated from the header comment and the options of every module under `modules/` – the counterpart of the [hand-written overview](modules.md).

## acme-caa-options.nix

Options of the CAA check (admin/nixlab#411): a host's ACME clients, where
each keeps its account and which names it gets. Shared by the NixOS side
(modules/acme-caa.nix, a sandboxed systemd writer) and the Mac side
(modules/darwin/acme-caa.nix, a launchd job); see modules/acme-caa.nix for
what the check does.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/acme-caa-options.nix)

## acme-caa.nix

Reusable module: the ACME clients of a host, their accounts, and a check
that the CAA records still let each account renew (admin/nixlab#411).

Every public name is pinned by CAA (RFC 8657 accounturi +
validationmethods, records in the DNSControl repo) to the Let's Encrypt
account and method of the client that gets its certificate. The price:
a new account - a lost state directory, a changed email in lego's account
path - can no longer renew until the record is changed. Two things here
keep that from happening quietly:


```
backupPaths  where each client keeps its account. Hosts add the list to
their restic paths, so a restored host comes back with the
same account instead of registering a new one.
the check    a textfile writer (modules/textfile-metrics-lab.nix) that
resolves the CAA records applying to each name the way
Let's Encrypt does (follow the CNAME, climb towards the
apex) and compares them with the account in use. Alerts:
hosts/grammi/alerting/security.nix (AcmeCaa*).
```


A client says where its account is in one of three ways:

```
accountJson  a JSON file holding the URI (lego, Caddy), by glob - the
lego directory name contains a hash of email, key type and
server that the NixOS module does not expose
accountKey   the account key itself (NetBird proxy's autocert stores no
URI); the check derives the URI from Let's Encrypt with a
`newAccount` + `onlyReturnExisting` request signed with it
accountUri   the URI as a string, for an account on a device the lab
does not manage (Home Assistant's add-on)
```


Root-only sources (account JSON, a 0700 state directory) are read by a
root ExecStartPre step that writes only the URI and the names into the
unit's runtime directory; a key reaches the sandboxed check as a
credential, never through the filesystem.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/acme-caa.nix)

## acme.nix

ACME defaults for every host that serves TLS.

DNS-01 against deSEC rather than HTTP-01: it needs no inbound port 80 for the
challenge and can issue for names that never resolve publicly.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/acme.nix)

## auto-upgrade-git-pull.nix

auto-upgrade-git-pull: fast-forward a checkout to its upstream, but only
to a commit whose SSH signature checks out. Used by
modules/auto-upgrade-git.nix (the nightly upgrade), by modules/
nix-cache.nix (the prebuild) and by hand; tested by
tests/auto-upgrade-git-pull.nix.


```
auto-upgrade-git-pull <dir>           fetch, verify @{upstream}, merge --ff-only
auto-upgrade-git-pull --verify <rev>  only verify <rev> (in the current directory)
```


The rule, walked from the commit to be merged:

- signed by a trusted signer: accepted, and everything before it with it.
  The signer vouches for the whole history it signed on top of.
- signed by a lock-only signer: accepted only if it has exactly one
  parent and changes `lockFile` and nothing else; then its parent is
  checked the same way. So a host that signs the nightly lock update
  cannot launder anything else - not its own changes, and not an
  unsigned commit someone slipped in underneath.
- anything else (unsigned, unknown key, bad signature): refused.

`%G?` and `%GS` rather than `git verify-commit`: the latter would refuse
an unknown key as well (git 2.54: `%G?` = U, exit 1), but the signer's
name from the allowed-signers file is what picks one of the two rules.

A merge made on github.com carries GitHub's PGP signature; git then tries
gpg, which is deliberately not here ("cannot run gpg"), and `%G?` is N -
refused like any other commit outside the list.

Two layers: `core` reads its settings from the environment, so the test
can run it against keys generated at build time; the package itself is a
wrapper that fixes those settings to the signers given here.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git-pull.nix)

## auto-upgrade-git.nix

Reusable module: nightly `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`
via system.autoUpgrade, optionally after fast-forwarding the checkout the
flake lives in to a verified upstream commit. It never commits or pushes: a
flake.lock changed by `updateInputs` is built and switched, then reset at
the next start. Meant to be dropped into any host's `modules` list
unchanged (see hosts/zummi for the reference usage).

**Options** (`services.autoUpgradeGit`):

| Option | Description |
| --- | --- |
| `enable` | Enable: nightly auto-upgrade of the flake checkout |
| `flakeDir` | Directory containing the flake (and its git checkout) to upgrade from. |
| `flakeAttr` | nixosConfigurations attribute name to build, i.e. the `#<attr>` part of the flake ref. |
| `updateInputs` | Flake inputs to update before rebuilding. Empty list skips the update step entirely. |
| `pull` | Fast-forward the checkout (`git pull --ff-only`) before updating and rebuilding. With `updateInputs = [ ]` this makes the host follow a flake.lock that is updated - and ideally prebuilt - elsewhere. |
| `dates` | systemd calendar expression for when to run, passed through to system.autoUpgrade.dates. |
| `allowReboot` | Whether to allow automatic reboots after a kernel/boot-relevant upgrade. |
| `rebootWindow` | Restrict automatic reboots to this time window. Null means no restriction beyond `dates`. |
| `deployKeySecret` | Name of the sops secret holding the SSH deploy key for the flake's git repo. Read-only is enough: this module never pushes. Declared automatically by this module (mode 0400, owner root) - just put the key under this name in the host's secrets.yaml. |
| `holdFile` | Skip the whole run (no input update, no switch, no reboot) while this file exists - the host deliberately runs something other than the checkout. Checked by `holdCheck`, which must exit 0 to go ahead and 1 to skip (systemd's ExecCondition semantics); null disables both. |
| `holdCheck` | Command deciding whether `holdFile` still applies. Null means the file's presence alone skips the run. |
| `gitAuthorEmail` | Email used for the git author/committer identity of git operations run by the unit. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git.nix)

## base.nix

Baseline every host in this lab shares: accounts, kernel hardening,
locale, console, time, and the handful of tools that should exist on any machine you might have to debug
from a VNC console at two in the morning.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/base.nix)

## container-pins.nix

Registry images for virtualisation.oci-containers, pinned by digest.

A tag - `latest` as much as `1.3.1` - is whatever the registry says it is
today; a digest is the content itself, the way a fetcher's hash is. Each pin
names the image, the tag its digest was read from (for people and for the
version check), the digest that is pulled, and the upstream repository the
version check looks for releases in. A container uses the pin's `ref`:


```
services.containerPins.images.app = {
image = "ghcr.io/example/app";
tag = "1.2.3";
digest = "sha256:0123...";
source = "https://github.com/example/app";
};
virtualisation.oci-containers.containers.app.image =
config.services.containerPins.images.app.ref;
```


With `enforce` (the default), every oci container on the host has to be
pinned by digest or built locally (pull = "never"), and none may carry
podman's auto-update label: `podman auto-update` would otherwise move the
image behind the configuration's back.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/container-pins.nix)

## crowdsec-dynamic-allow.nix

Reusable module: never let CrowdSec ban a client whose address is dynamic
but tracked by a DNS name (a dyndns name for a home line). admin/nixlab#444.

A postoverflow whitelist, not a parser whitelist and not a LAPI allowlist:

- Static whitelists cannot resolve names. CrowdSec's expr helper
  LookupHost() can, and in the postoverflow stage it only runs when a
  scenario has already overflowed - rarely, so one lookup each time costs
  nothing and is never stale beyond the record's TTL. No timer, no list
  to keep in sync, no token on the host.
- A failed lookup returns an empty list (LookupHost logs and swallows the
  error), so the exemption fails closed: the ban happens as before.
- The lookup runs inline in CrowdSec's output loop. With DNS down, an
  overflow of a listed scenario waits for the resolver's timeout (a few
  seconds through resolved), and overflows behind it - an attack
  included - wait with it. The scenario filter comes first, so only the
  listed scenarios ever look up, and only while DNS is down. Accepted:
  a ban seconds late, not a ban lost.
- LAPI allowlists (`cscli allowlists`) are also checked by the AppSec
  runner, which then skips the in-band block for that address entirely
  (pkg/acquisition/modules/appsec/appsec_runner.go in 1.7.8). Here the
  WAF still answers 403; only the ban that would follow is dropped.
- What this does not cover: the community blocklist and decisions added
  by hand, which only a LAPI allowlist filters.

IPv6: the name's AAAA is one address of the line; every device behind it
has its own from the delegated prefix, so the AAAA is widened to
ipv6PrefixLength. Likewise ipv4PrefixLength (32: just the address).

A whitelisted overflow is counted by CrowdSec itself, as
cs_node_wl_hits_ok_total{name="<whitelistName>"}. Whether the name
resolves at all is exported by a textfile writer, so a name that stopped
resolving - and with it the exemption - shows up before the next ban does.

**Options** (`services.crowdsecDynamicAllow`):

| Option | Description |
| --- | --- |
| `name` | DNS name whose A/AAAA records are never banned. null: no exemption. Resolved through the host's resolver whenever a scenario overflows. |
| `whitelistName` | Name of the postoverflow whitelist, also the `name` label of cs_node_wl_hits_ok_total. |
| `scenarios` | Scenarios whose overflows are dropped for the name's addresses. Empty: all of them. A list keeps the attack scenarios (brute force, CVEs, AppSec) banning, so a compromised device behind the line is still caught. |
| `ipv4PrefixLength` | Prefix length the A record is widened to. |
| `ipv6PrefixLength` | Prefix length the AAAA record is widened to: the delegated prefix of the line. |
| `expression` | The whitelist expression, for tests and documentation; null without a name. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec-dynamic-allow.nix)

## crowdsec.nix

Known issues with the nixpkgs modules, all found the hard way:

- services.crowdsec-firewall-bouncer with registerBouncer.enable destroys
  the engine's state directory (see the disabled block below). Do not
  re-enable it; use secrets.apiKeyPath with a hand-registered bouncer.
- Console enrolment is broken twice over: the setup script's enrolment step
  never runs (inverted condition, see the note below), and console_path
  defaults to a Nix store path, so doing it by hand fails too until that is
  redirected somewhere writable.
- The generated config sets api.server.listen_uri to 127.0.0.1:8080 by
  default, which collides with anything else on that port - garage-ui here.
- Changing listen_uri does not update an already written
  local_api_credentials.yaml; delete it (and the machine) to have the setup
  script regenerate it, or the agent keeps dialling the old port.
- Setting capi.credentialsFile creates a chicken-and-egg: `cscli machine
  add` runs before `cscli capi register` in the setup script but needs the
  file the latter creates. Bootstrap once with `cscli capi register`.
- settings.general.api.server.enable defaults to false and both credential
  paths default to null; all three must be set or the agent dies with
  "no API client section in configuration".
- The module creates its directories via systemd.tmpfiles, not
  StateDirectory=. Removing /var/lib/crowdsec by hand breaks the unit's
  mount namespace until `systemd-tmpfiles --create` re-creates them.

---------------------------------------------------------------------------
CrowdSec, one self-contained Security Engine per host.

Each host runs all three parts locally: the agent (parses logs, applies
scenarios), the Local API on 127.0.0.1:8080 (holds decisions, pulls the
community blocklist), and the firewall bouncer (enforces them as nftables
rules). No host depends on the other - a deliberate choice for a two-host
setup, where a central LAPI would buy little beyond what the shared
community blocklist already covers, at the price of coupling both hosts to
one machine and to the mesh being up.

What this is actually for: SSH here is key-only with root confined to the
mesh (modules/ssh.nix), so the constant bot noise on port 22 cannot
succeed and CrowdSec mostly quiets the logs. The real target is port 443 -
pocket-id on zummi is an OIDC provider and the one place where credentials
can be guessed, and aldrin exposes Garage's S3 API.

**Options** (`services.crowdsecBuckets`):

| Option | Description |
| --- | --- |
| `vhost` | nginx virtualHost (attribute name) that serves the S3 API. It gets its own access log, and only lines from that log can be exempted. null: no bucket whitelist on this host. |
| `buckets` | Bucket names (path-style) whose ordinary traffic is not counted. |
| `logFile` | The vhost's access log, in nginx's combined format, for anything else that reads nginx's access logs. Matches /var/log/nginx/*.log, so CrowdSec and logrotate pick it up without further configuration. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec.nix)

## deploy-hold.nix

Deploy holds: a host runs a topic branch and nothing may switch it back to
main until that branch is merged.

`just try <host>` deploys the current worktree with deploy-push and then
writes /etc/nixos-hold on the host (branch, commit, since, by). Everything
that would otherwise switch the host back to main quietly honours it:

- the nightly nixos-upgrade (modules/auto-upgrade-git.nix, holdFile)
- `just rebuild` / `just deploy` / `ship` / `deploy-all` (justfile)
- `just deploy-push` from another checkout (justfile)
- ursalia's nightly push to cuckoosegg (hosts/ursalia/push-cuckoosegg.nix)

The rule is the same everywhere: a hold blocks a deploy unless the held
commit is contained in what is about to be deployed - then the branch has
been merged, the hold has done its job and is removed. A rebase merge
rewrites the commit, so that case needs `just release <host>`.

Visibility: a node_exporter textfile metric (nixlab_deploy_hold_since_seconds,
panel "Deploy holds" in Homelab / Hosts Overview, red after 48 h) and a
warning in every interactive login shell on the host.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy-hold.nix)

## deploy.nix

How this lab ships and updates itself: every host keeps /etc/nixos as a
checkout of the private GitHub repo admin/nixlab, pulls from it on deploy,
and upgrades itself nightly - committing the refreshed flake.lock back.

Kept separate from modules/auto-upgrade-git.nix on purpose. That module
documents itself as host-agnostic and reusable; hardcoding a git forge and a
specific secret name into it would take that away. It stays the mechanism,
this file is the lab's policy.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy.nix)

## dns01-names.nix

Names a host answers ACME DNS-01 challenges for outside of
security.acme.certs: a Caddy of its own (nix-darwin has no security.acme),
or a DNS-01 proxy that writes challenges for other clients with this
host's DNS provider token.

Only a declaration - nothing here acts on it. Whatever scopes the host's
token reads it together with security.acme.certs; in this lab that is
lib.dns01Names in flake.nix, which feeds terraform/desec-tokens.
Plain option module, so it works on NixOS and nix-darwin alike.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/dns01-names.nix)

## docs-site.nix

The private docs site (flake package docs-site, built from docs/) on the
NetBird mesh under doku.homelab.example.

Who may read it is the allow list (option allow): the whole mesh by
default, in this lab only the admins' devices - the docs carry every
internal address and how the lab is run, which is more than everyone with
a device in the mesh needs to see. Enforced here in nginx because the
NetBird policies cannot tell this site apart from the other services on
the same hosts (terraform/netbird/admin-peers.tf has the reasoning).

Mesh-only like the other admin names: the name is a NetBird DNS zone with
one A record per host that imports this module
(terraform/netbird/mesh-services.tf), public DNS has no record, and the
vhost admits only mesh addresses. Certificate via DNS-01 (modules/acme.nix)

- each host gets its own; its deSEC token may write the challenge record
  once `just desec-names` and `just desec-apply` have run
  (terraform/desec-tokens).

Two more ways in, both optional and both only additions - the mesh way
above stays the one that does not depend on anything but the host
(decided 2026-10-23):

- Login from the internet (option login): a NetBird reverse proxy
  service with SSO (terraform/netbird/reverse-proxy.tf, doku_login)
  forwards to a listener of its own here. The proxy sends a secret
  header, and only requests that carry it get the docs - the admin
  workstations and the other servers reach this port over the mesh
  (people's devices did too, until to-servers was narrowed to 80/443 on
  2026-11-01), and without the header the admin-only rule would end at
  the port. doku.homelab.example/login
  leads there; without zummi (Pocket ID) and grammi (proxy) it is gone,
  which is fine for a way meant for a device without NetBird.
- The home LAN (option lan): the router answers doku.homelab.example with
  this host's LAN address, and every LAN device gets the docs except the
  ones on a deliberate deny list. A deny list by address only catches
  devices with a fixed one; guests and anything with a changing address
  are in.

On more than one host on purpose: the docs are what you read when
something is broken, so they must not depend on a single machine - least
of all on grammi, which runs the NetBird server and the reverse proxy.
Every host builds the site itself from its /etc/nixos checkout, so all of
them serve the same commit after a deploy or the nightly upgrade.

**Options** (`services.docsSite`):

| Option | Description |
| --- | --- |
| `enable` | Enable: the private docs site on the mesh |
| `package` | The built site - the flake's docs-site package. |
| `fqdn` | Name the site is served under (a mesh-only NetBird DNS zone). |
| `allow` | Addresses or networks nginx serves the site to; everyone else gets 403, with a page that says why and how a device gets in. Default: the whole mesh. The lab sets the admins' devices from terraform/netbird/admin-peers.json (flake.nix) - see the header of terraform/netbird/admin-peers.tf for why it is an address list. |
| `redirectPort` | Port of a plain-HTTP listener that answers every request with a redirect to redirectTo, keeping the path - the target of the NetBird reverse proxy service for the same name, so a visitor from outside the mesh lands on the public docs. A port of its own because the proxy's peer has no address that is known in advance; the port is only open on the mesh (nb-mesh is a trusted interface) and admits only the mesh. null: no listener. |
| `redirectTo` | Where redirectPort sends visitors, without a trailing slash; the request path is appended. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/docs-site.nix)

## firewall.nix

Shared firewall baseline for every homelab host.

Public surface is deliberately tiny: SSH plus HTTP(S). The NetBird mesh
interface is trusted by modules/netbird.nix; NetBird's own UDP port is
opened there too.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/firewall.nix)

## flake-input-tags.nix

Reusable module: how long a newer tag of a tag-pinned flake input has been
waiting (admin/nixlab#327, decision 4a). Inputs pinned by tag are bumped by
hand (`just bump`), so nothing else notices a new release of them.

The pins come from the flake.lock this system was built from (lockFile):
every direct input of type github whose owner is in `owners` and whose ref
is a version tag (v1.2.3 / 1.2.3). A writer of modules/textfile-metrics.nix
asks the GitHub API for each one's newest version tag, a few unauthenticated
requests per input and run, and exports


```
<prefix>flake_input_newer_tag_age_seconds{input,repo,pinned,latest}
```


0 while the pin is the newest tag, else the newest tag's age. The script
is modules/flake-input-tags.sh.

**Options** (`services.flakeInputTags`):

| Option | Description |
| --- | --- |
| `enable` | Enable: the age of newer tags of tag-pinned flake inputs as metrics |
| `lockFile` | flake.lock of the flake this system is built from. |
| `owners` | GitHub owners whose tag-pinned inputs are watched. |
| `inputs` | The watched inputs and their pinned tags, as read from lockFile. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/flake-input-tags.nix)

## forwarding.nix

IP forwarding with a default-drop filter, for hosts that route between
their interfaces: VPN exit nodes, routing peers into a LAN, hosts with
containers on a bridge.

Why a filter at all: overlay clients (NetBird, Tailscale) put their own
chains on the forward hook, but those only judge traffic that comes *out*
of the overlay. Traffic from any other interface into the overlay passes
them untouched - and NetBird even masquerades it as the routing host
(its 0x1bd22 mark), so an on-link neighbour that routes the overlay's
range via this host reaches the overlay peers with the host's identity.
Shown on four hosts with a network-namespace neighbour (admin/nixlab#311).

What this module does:

- turns forwarding on (IPv4, optionally IPv6),
- switches on the NixOS firewall's forward chain (policy drop; replies
  and port forwards (ct status dnat) pass on their own) and accepts new
  connections only for the `allow` pairs,
- a guard chain of its own that drops new connections into an overlay
  interface from anywhere else, unless an `allow` pair names that way.
  Needed because the firewall's forward-allow chain accepts all ICMPv6
  before any extraForwardRules run - without the guard, ping6 into the
  overlay still passes.

A drop in any base chain is final, so the guard cannot let through what
the firewall's chain drops, and the other way round.

**Options** (`networking.forwardFilter`):

| Option | Description |
| --- | --- |
| `enable` | Enable: IP forwarding, filtered: new connections only along the allowed interface pairs |
| `ipv6` | Also forward IPv6 (net.ipv6.conf.all.forwarding). The filter covers both families either way. |
| `allow` | Interface pairs along which new connections are forwarded. Replies (established/related) and destination-NATed port forwards need no entry. Whatever filtering the overlay client does on top stays in force. |
| `overlayInterfaces` | Overlay interfaces (VPN meshes). New connections into them from any other interface are dropped by a guard chain unless an `allow` pair names that way, ICMPv6 included. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/forwarding.nix)

## hotfixes.nix

Package hotfixes that switch themselves off.

MANDATORY (rule of 2026-11-15, nixlab#321): every override that waits for
nixpkgs - "drop this once nixpkgs has ..." - goes through `hotfix`, never
a bare overrideAttrs with such a comment. Overrides that are meant to stay
(a local patch, a build variant, tests switched off) are not hotfixes and
stay plain overrides; their comment says so ("permanent, not a hotfix").
The Macs load this module too (profiles/darwin.nix).

A hotfix pins a package to a newer version (or adds a patch) until nixpkgs
catches up. Written by hand, it has to be removed by hand too - and since
the nightly auto-upgrade moves nixpkgs on its own, nobody notices the day
it becomes dead weight, or worse, the day it starts pinning an OLDER
version than nixpkgs ships. That happened with the paperless-ngx 3.3.2
bump on ursalia: nixos-unstable had 3.3.2 by 2026-10-23, the override
still said "drop me once it does" (found while adopting this module).

`hotfix` (a module argument, usable by any host module) applies an
override only while nixpkgs still needs it:


```
hotfix {
name = "sudo CVE-2025-32463";   # for the warning
pkg = prev.sudo;                # what nixpkgs ships
fixedVersion = "1.9.17p1";      # first version with the fix
fixPatch = "CVE-2025-32463";    # optional, see below
override = pkg: pkg.overrideAttrs (old: { ... });
}
```


It returns `pkg` untouched once pkg.version >= fixedVersion, or once one of
pkg.patches has `fixPatch` in its name - stable releases usually backport a
CVE as a patch without bumping the version. In every case evaluation warns
that the hotfix can go, so it does not linger; the override (and its src
hash) is then not evaluated at all.

A fix that no version number marks takes `fixedWhen` instead of (or next
to) fixedVersion: a boolean that turns true once nixpkgs has it, e.g. "the
package's own list of relaxed dependencies now names the one the override
relaxes". Pick a test that flips in the same
nixpkgs commit as the fix, so it cannot switch the hotfix off early.

Credits: the pattern is snowball's (BBBSnowball), offered for reuse on
2026-10-23 - version check plus CVE patch detection, one overlay per file:
https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes
Ours adds the warning: there the override goes quiet without telling anyone.

Hotfixes for packages from the host's own pkgs go into modules/hotfixes/,
one overlay per file, as `hotfix: final: prev: { <pkg> = hotfix { ... }; }`;
every file there is loaded on every NixOS host and every Mac. An overlay
is lazy: a host that does not use the package never evaluates it. Packages taken from another
nixpkgs (`inputs.<pin>.legacyPackages.${system}`) do not see these overlays - call
`hotfix` on them in the host module instead.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/hotfixes.nix)

## intel-gpu-metrics-lab.nix

The lab side of the intel-gpu-metrics module from the input
intel-gpu-metrics (github.com/tioan/nixos-intel-gpu-metrics, #327, item 2):
the bridge writes into its own sandboxed writer directory of
modules/textfile-metrics-lab.nix instead of the textfile root, root-owned
because the unit stays root. Metric names keep the module's default prefix
intel_gpu_ (not textfileMetrics.metricPrefix), which
hosts/grammi/dashboards/immich.json reads.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/intel-gpu-metrics-lab.nix)

## lab.nix

Lab-wide constants that several modules and hosts need, declared once.
The values are set from inventory.json by profiles/common.nix and
profiles/pulled.nix;
this file only declares them, so the modules that read them stay free of
lab values.

The mesh ranges and the OIDC issuer (admin/nixlab#319) and the S3 endpoint
of the restic jobs (modules/restic-lab.nix, #318).

**Options** (`lab.mesh`):

| Option | Description |
| --- | --- |
| `ipv4` | IPv4 range of the mesh overlay every peer gets its address from. |
| `ipv6` | IPv6 range of the mesh overlay; null when it has none. |
| `networks` | Both ranges as a list, for allow lists. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/lab.nix)

## log-shipping.nix

Reusable module: ship this host's journald log and nginx's access log to a
central VictoriaLogs instance (grammi) via Vector. Switched on per host with
services.logShipping.enable (on every NixOS host: profiles/common.nix).

nginx access log: /var/log/nginx is drwxr-x--- nginx:nginx, same obstacle
CrowdSec and the nginxlog Prometheus exporter hit (see modules/crowdsec.nix,
modules/metrics.nix) - both already prove SupplementaryGroups = [ "nginx" ]
works fine under DynamicUser in this nixpkgs, so Vector gets the same
treatment below rather than the "not attempted yet" this module used to say.

Field mapping verified against a real payload (query against
/select/logsql/query): Vector's `journald` source renames journald's
MESSAGE field to its own lowercase `message` on the way in - the raw
uppercase journald field names (_SYSTEMD_UNIT, __REALTIME_TIMESTAMP, etc.)
survive untouched, but the message text itself does not, so _msg_field has
to point at the renamed field or VictoriaLogs can't find any content
("missing _msg field" for every entry). `timestamp` and `host` matched
already and needed no change. Vector's `file` source uses the same
`message`/`timestamp` field names for the raw log line and its own read
time, and stamps `.host` with the local hostname same as every other
source, so the nginx access log needs no separate _msg_field/_time_field -
it rides the same sink as journald.

**Options** (`services.logShipping`):

| Option | Description |
| --- | --- |
| `enable` | Enable: ship this host's journald log to grammi's VictoriaLogs via Vector |
| `victoriaLogsUrl` | Base URL of the VictoriaLogs instance to ship to. Over the NetBird mesh, same reasoning as services.metricsShipping.remoteWriteUrl. |
| `httpRetryStrategy` | Vector retry_strategy for every sink that writes to the ingest with httpAuth. |
| `httpAuth` | Vector `auth` block for basicAuth (null without), for other sinks or http_client sources on this host that reach the same ingest. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/log-shipping.nix)

## logging.nix

Log retention.

File logs are already handled: NixOS enables logrotate by default and the
nginx module ships its own rule (weekly, 26 rotations, compressed). That rule
rotates by rename plus `kill -USR1`, not copytruncate, which matters here -
CrowdSec tails /var/log/nginx/*.log and follows the new inode cleanly, and
the rotated access.log.1 does not match the glob, so nothing is read twice.

journald is the part nobody bounds: it rotates itself, not via logrotate, and
defaults to 10% of the filesystem capped at 4G. On zummi that had grown to
2.6G, most of it the constant SSH bot noise on port 22.

Deliberately capping the size rather than quieting sshd: that noise is
exactly what CrowdSec parses into ssh-bruteforce scenarios, so turning down
the log level would blind the detection to save disk that is not scarce.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/logging.nix)

## loopback-v6-proxy.nix

Reusable module: answer on [::1] for a service that only listens on
127.0.0.1, so a loopback-only endpoint is dual stack like the rest of the lab.

Why a proxy: most exporters (prometheus_client, node-style Go exporters)
take exactly one listen address, and the family follows from it. Binding
"::" would cover both families but also the mesh interface, which is
trusted (modules/netbird.nix). systemd owns the
[::1] socket and starts systemd-socket-proxyd on the first connection, so
an idle endpoint costs nothing and the service itself stays untouched.

Scrapers keep using 127.0.0.1 (modules/metrics-shipping.nix): one scrape per
exporter, otherwise every series would arrive twice.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/loopback-v6-proxy.nix)

## maintenance.nix

Maintenance mode for the lab's web services, the same for nginx and
Traefik: a flag file switches a name to a 503 page, and the proxy shows
the same page (with 502/504) when the service behind it does not answer.
Decided 2026-10-22 (idea from a blog post on an nginx toggle script);
docs: docs/site/*/how-to/maintenance.md.

The pieces:

- Flags: /var/lib/maintenance/<fqdn> or /var/lib/maintenance/all, the
  file's content is the reason shown on the page. Persistent on purpose:
  a reboot in the middle of maintenance keeps the service closed.
  Set with `maintenance on|off|status` on the host, or
  `just maintenance <name> ...` from the workstation.
- Responder (maintenance/responder.py): socket-activated, loopback only,
  renders the page for both proxies - one place that decides between
  maintenance and failure, instead of one nginx and one Traefik version.
- nginx (option nginx.vhosts): checks the flag on every request -
  `if (-f ...)` is evaluated per request (no open_file_cache here), so
  switching needs no reload. Its own 502/504 go to the same page; the
  service's own error responses pass untouched (proxy_intercept_errors
  stays off - S3's XML errors, OIDC's JSON).
- Traefik (option traefik.enable): has no file test, so a oneshot turns
  the flags into routers in a watched directory (maintenance/
  traefik-sync.py); Traefik picks them up without a restart.
- Bypass: whoever holds the cookie (token from sops, hosts/<host>/
  maintenance.yaml, the same on every host) sees the service anyway.
  A convenience for testing in the browser, not a security boundary: the
  service's own login, the proxy's SSO and allow/deny all still apply.

Caveat for nginx vhosts with allow/deny: the check is a rewrite-phase
`return`, which runs before allow/deny (modules/docs-site.nix has the
details), so the page would also reach clients the vhost otherwise
refuses. Only list vhosts whose port only allowed clients reach anyway.

**Options** (`services.maintenance`):

| Option | Description |
| --- | --- |
| `enable` | Enable: maintenance mode and error pages for the host's web front (nginx/Traefik) |
| `port` | Loopback port of the responder that renders the maintenance and error pages. |
| `retryAfter` | Retry-After (seconds) on the 503 maintenance page. |
| `cookieDomain` | Domain of the bypass cookie: one cookie for every service below it. |
| `cookieMaxAge` | Lifetime of the bypass cookie in seconds (default 12 h). |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/maintenance.nix)

## metrics-shipping.nix

Reusable module: scrape this host's own Prometheus exporters with vmagent
and remote_write them to a central VictoriaMetrics instance (grammi). Meant
to be dropped into any host's `modules` list unchanged and switched on per
host with services.metricsShipping.enable (see hosts/aldrin, hosts/zummi).

vmagent ships as part of the same `victoriametrics` package that provides
victoria-metrics/victoria-logs (nixpkgs builds all of VictoriaMetrics' Go
binaries from one derivation) - no separate NixOS module exists for it
upstream, hence the hand-rolled systemd unit below, in the same spirit as
modules/auto-upgrade-git.nix.

**Options** (`services.metricsShipping`):

| Option | Description |
| --- | --- |
| `enable` | Enable: ship this host's Prometheus exporters to grammi's VictoriaMetrics via vmagent |
| `remoteWriteUrl` | VictoriaMetrics remote_write endpoint, over the NetBird mesh. Mesh-only by design - see hosts/grammi/telemetry-ingest.nix, the ingest port is not in networking.firewall.allowedTCPPorts, only reachable over the trusted mesh interface. |
| `exporterPorts` | Local ports to scrape, named - this host's own services.prometheus.exporters.<name>.port values. The name becomes this target's `instance` label in VictoriaMetrics, so vmui shows e.g. "node"/"nginx" instead of an undifferentiated "127.0.0.1:9113". |
| `defaultExporters` | services.prometheus.exporters.<name> registered in exporterPorts automatically wherever they are enabled, so hosts list only their own extra exporters. |
| `exporterAddresses` | Loopback address to scrape per exporterPorts name, "127.0.0.1" where absent. For exporters that also answer on [::1] through modules/loopback-v6-proxy.nix: the lab prefers IPv6, so those are scraped there. IPv6 literals need their brackets. |
| `extraScrapeConfigs` | Additional vmagent scrape_configs, for targets exporterPorts cannot express - metrics_path is per job, so anything not on /metrics needs a job of its own. Named "<host>-<service>" like the crowdsec job. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics-shipping.nix)

## metrics.nix

Per-node metrics exporters.

Every exporter here listens on 127.0.0.1 only (nixlab#15, decision 3b of
2026-11-01): each host's own vmagent scrapes them locally
(modules/metrics-shipping.nix) and no host scrapes another, so nothing
needs them on the mesh. Until 2026-11 they bound 0.0.0.0 and the firewall
kept them off the internet - which left them open to every mesh peer the
NetBird policies let through.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics.nix)

## netbird-exit-node.nix

This host as a NetBird exit node (terraform/netbird/exit-nodes.tf: which
hosts, who may use them, IPv4 and IPv6 routes). Imported by aldrin and
zummi, each naming its public interface.

Routing and NAT are NetBird's: with masquerade on the route, the client
puts its own masquerade rules (v4 and v6) and the policy's forward ACL
into its nftables tables. What this module adds:

- forwarding for both families through modules/forwarding.nix, set here
  so it does not depend on the client switching it on and is visible in
  the config: new connections only from nb-mesh out of the public
  interface, nothing from the public side into the mesh
  (admin/nixlab#311),
- counters of the forwarded traffic per family and direction, for the
  "Exit nodes" panels in hosts/grammi/dashboards/netbird.json.

Reverse-path filtering stays at modules/firewall.nix' "strict": client
packets arrive on nb-mesh from the overlay ranges (connected routes on
nb-mesh), the internet's replies on the public interface, whose default
routes cover them.

**Options** (`services.netbirdExitNode`):

| Option | Description |
| --- | --- |
| `enable` | Enable: this host as a NetBird exit node |
| `wanInterface` | The public interface exit traffic leaves through. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird-exit-node.nix)

## netbird.nix

NetBird client, joining the homelab mesh (control plane: mesh.homelab.example,
hosts/grammi/netbird.nix; account: terraform/netbird). The only overlay
since Tailscale was removed (2026-11, admin/nixlab#360).

The host registers once with a single-use setup key from
hosts/<host>/netbird.yaml, written by `just netbird-key <host>` (24 h
valid). After that its identity lives in /var/lib/netbird-mesh/ and the
key is spent; a host only needs a new one after losing that state.

The peer shows up as <hostname>.peer.homelab.example with an address out of
192.0.2.0/24, in the group its setup key assigns (terraform/netbird,
local.hosts): "servers" for the lab's own hosts, "subraum-devices" for
cuckoosegg, which only gets what terraform/netbird/subraum.tf grants.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird.nix)

## networking.nix

Networking baseline every host in this lab shares. The host-specific part -
which interface, which addresses, which routes - stays in each host's own
configuration.nix under networking.ifstate.settings; only the shape of the
setup lives here, so a new machine inherits it by importing this module.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/networking.nix)

## nix-cache.nix

The lab's own binary cache: bucket nix-cache in Garage on aldrin
(terraform/garage/nix-cache.tf), filled every night by ursalia and read by
every host next to cache.nixos.org.

Why: the smaller hosts kept building what cache.nixos.org cannot have -
anything built against this flake's own pins, sops-nix's
sops-install-secrets above all, plus the hundreds of small configuration
derivations. On zummi (2 vCPU, 1.8 GiB) that Go build thrashed inside the
memory limits of nixos-upgrade and ran into its 2h timeout three nights in
a row (2026-10-29 to -31). Now ursalia updates flake.lock, builds every
host, uploads what it built and only then pushes the lock; the hosts pull
it in their own nightly upgrade and substitute instead of building.

Two halves, both here:

- every host: the substituter, its public key and the read-only S3 key
  (secrets/nix-cache.yaml, one file for all hosts).
- prebuild.enable (ursalia): the nightly update + build + upload, with
  the read-write key and the signing key (hosts/ursalia/nix-cache.yaml).
  Both files come from `just nix-cache-secrets`.

**Options** (`services.nixCache.prebuild`):

| Option | Description |
| --- | --- |
| `enable` | Enable: the nightly flake.lock update, build of every host and upload to the nix cache |
| `updateInputs` | Flake inputs the nightly run updates. |
| `dates` | When to run. Early enough to be done before the hosts' nixos-upgrade (04:00 plus up to 45 minutes); a host that starts before the new lock is pushed just pulls nothing new tonight. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/nix-cache.nix)

## nix.nix

Nix daemon and store housekeeping, shared by every host.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/nix.nix)

## no-redirects.nix

No ICMP redirects, in either direction (admin/nixlab#310). Imported by
modules/base.nix for every host and by the gw-remote container
(hosts/gw-remote/container.nix), whose network namespace has values of its
own - the host's never reach it. Only net.* keys, so it works inside a
container, where the rest of /proc/sys is read-only.

Nothing here learns its routes from redirects: routing is static
(ifstate, modules/networking.nix) or NetBird's. Accepting them only lets
whoever shares a link rewrite a route; sending them tells the other side
of a tunnel about this host's routing, and on the forwarding hosts
(exit nodes, routing peers, gw-remote) every client sits behind a WireGuard
or OpenVPN link where a redirect has nothing to point to.

Globs, not just "all" and "default": for IPv4 the kernel combines "all"
with the interface's own value (OR for send_redirects, and for
accept_redirects on a host that does not forward), so an interface that
exists before systemd-sysctl runs keeps its 1 - seen on zummi, where
ens6/send_redirects was 1 under all=0. systemd-sysctl applies the glob to
every existing interface, "default" covers interfaces created later (the
tunnels, nb-mesh), and on hosts with udev its 99-systemd.rules reapplies
the glob to every new one as well.

rp_filter, forwarding and accept_ra are not set here: modules/firewall.nix,
modules/netbird-exit-node.nix / the hosts, and modules/networking.nix own
them.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/no-redirects.nix)

## pinned-releases.nix

Reusable module: how long a newer upstream release of a pinned package has
been waiting. Packages taken from a nixpkgs pin that is bumped by hand
(flake.nix: nixpkgs-readeck and its siblings) do not move with the nightly
update, and nothing else notices when upstream has moved on - the weekly
version check (pkgs/version-check) only reports it. Sibling of
modules/flake-input-tags.nix, which does the same for flake inputs pinned by
tag.


```
services.pinnedReleases.packages.readeck = {
version = config.services.readeck.package.version;
api = "https://codeberg.org/api/v1";   # Forgejo; GitHub by default
repo = "readeck/readeck";
};
```


The version comes from the evaluated package, so it follows the pin by
itself. A writer of modules/textfile-metrics-lab.nix asks the forge's releases
API (GitHub and Forgejo/Gitea answer alike, unauthenticated, one request
per package and run) and exports


```
<prefix>pinned_newer_release_age_seconds{package,repo,pinned,latest}
```


0 while the pin is the newest stable release, else the age of the oldest
release newer than the pin. The script is modules/pinned-releases.sh.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/pinned-releases.nix)

## public-probes-targets.nix

What every public endpoint must answer, and from where it is probed - the
data behind modules/public-probes.nix (the probes on zummi and grammi) and
the PublicProbeMissing series in hosts/grammi/alerting/hosts-services.nix. admin/nixlab#169.

The endpoints come from inventory.json: every endpoint with exposure
"public" of a service that runs on a lab host. A new public endpoint
without an entry in `checks` below stops the evaluation, so nothing goes
public unprobed. Services without hosts (public-docs on GitHub Pages) are
not the lab's to watch.

Each check is probed twice, over IPv4 and over IPv6, without falling back
from one to the other: a broken AAAA record or IPv6 route shows as its own
failure instead of hiding behind a working IPv4.

Port 80 (admin/nixlab#234): it does nothing but redirect to https, for
every name. Probed for every web endpoint the lab serves itself - public
and mesh ones on their own host, proxy ones on the reverse proxy's host -
by name, and once per host and kind of address also with `Host:
localhost` and an unknown name, the two cases that once got a page
instead (modules/web-baseline.nix has the default servers). Mesh names
are probed from grammi, the rest as above. The appliances' own web
interfaces (LuCI, cameras) are probed from ursalia, see applianceProbes.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/public-probes-targets.nix)

## public-probes.nix

Reusable module: probe the lab's public endpoints from outside, with
Prometheus' blackbox exporter. admin/nixlab#169.

What is probed and from which host comes from modules/public-probes-targets.nix
(the endpoints in inventory.json); each host probes the ones assigned to it.
The exporter listens on loopback only, and the probes are scraped by this
host's own scraper - vmagent (modules/metrics-shipping.nix) or, on grammi,
VictoriaMetrics itself - as one job, `<host>-public-probes`, with the labels

```
target     the endpoint's name, e.g. short.homelab.example
path       what was requested, e.g. /healthz
ip_family  4 or 6
service    the service id in inventory.json
```

on probe_success, probe_duration_seconds, probe_http_status_code and
probe_ssl_earliest_cert_expiry. Alerts PublicServiceDown,
PublicProbeMissing and ServedCertExpiring in hosts/grammi/alerting/hosts-services.nix,
dashboard Homelab / Public endpoints.

Heartbeat (optional, `heartbeat.sopsFile`): every 5 minutes, if all of this
host's probes succeed, a ping to an external dead man's switch
(healthchecks.io). The ping asks the exporter directly, not
VictoriaMetrics, and needs neither grammi's alerting nor Home Assistant: a
failing endpoint, a dead exporter or a dead host all end in no ping, and
healthchecks.io notifies on its own channels.

**Options** (`services.publicProbes`):

| Option | Description |
| --- | --- |
| `enable` | Enable: probes of the public endpoints assigned to this host (modules/public-probes-targets.nix) |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/public-probes.nix)

## qemu-guest.nix

The QEMU guest agent on every host in this lab, with its RPC surface cut
down to what the hypervisor legitimately needs.

Why run it at all: the agent is the only way the hypervisor can quiesce our
filesystems before a provider-side snapshot (guest-fsfreeze-*) - without it
every such snapshot is crash-consistent and you find out how well that went
at restore time. It also gives a clean shutdown/reboot from the panel
instead of firing ACPI into the dark, and the IP display there. Costs a few
MB of RSS, which even zummi's 1.8 GiB can spare.

Why filter it: the virtio channel is unauthenticated by design - whoever
sits on the host side is root in the guest. That is no protection against
the hoster itself, who owns our RAM either way. It protects against the
realistic case: someone takes over the provider account and thereby has a
root shell on every host, with no SSH key, past CrowdSec, past the mesh -
and read access to /run/secrets, where sops-nix has already decrypted
everything. guest-exec and guest-file-* ARE that shell; the rest of the list
below is incidental.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/qemu-guest.nix)

## restic-data.nix

Backs up a home host's whole data disk to Garage on aldrin, via restic
(modules/restic-lab.nix). The same job on tummi and ursalia, next to
whatever else the host backs up.

Its own bucket and key instead of a path in the host's existing repository:
data disks are measured in terabytes, and a nightly job for Paperless should
not wait for their prune and check, or share their retention.

Consistency: restic reads a read-only btrfs snapshot. It has to live on the
data disk itself (a snapshot cannot cross filesystems), and restic does not
descend from it into itself because a snapshot leaves nested subvolumes out.
If the disk is not mounted, /data is a plain directory on the root volume,
`btrfs subvolume snapshot` refuses it and the run fails - it cannot store an
empty disk as a backup.

Bandwidth: no --limit-upload, SQM cake on gruffi shapes uploads per host and
measured all of them passing through it (nixlab#180).

Verification (restic-verified, input nixos-restic-verified), different from the other jobs:

- minPercent 1: on a box for sorting files, moving a disk image away is
  normal. With the default every later run would fail, because the verified
  size it compares against only moves on a verified run.
- checkSubset 1%: 5% of 3 TB would be 150 GB through the home line each Sunday.

No restic exporter: the NixOS module runs one per host, and ursalia's watches
its Paperless repository. The verified metrics and the receiving side
(hosts/aldrin/s3-upload-metrics.nix) cover these jobs, see the alerts in
hosts/grammi/alerting/backups.nix.

Setting up a host:

```
add the bucket to terraform/garage/buckets.tf, services.crowdsecBuckets in
hosts/aldrin/configuration.nix and hosts/aldrin/s3-upload-metrics.nix,
and deploy aldrin first
just garage-apply
just data-backup-secrets <host>
deploy the host, then once: restic-data init
```


Restoring: paths carry the snapshot's prefix. Use the snapshot ID from
nixlab_backup_verified_snapshot_info rather than `latest`, and --sparse so that
the holes of a sparse disk image stay holes:

```
restic-data restore <id> --sparse --target /root/restore --include /data/.restic-snapshot/<path>
```

**Options** (`services.resticData`):

| Option | Description |
| --- | --- |
| `enable` | Enable: the restic backup of the data disk to Garage on aldrin |
| `secretsFile` | sops file from `just data-backup-secrets <host>`. |
| `snapshotName` | Name of the snapshot below the data disk's mount point, for a host's Samba share to hide. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-data.nix)

## restic-lab.nix

The lab's part of the restic jobs (#318): restic-s3 and restic-s3-sops from
the input restic-verified (github.com/tioan/nixos-restic-verified, #327) are
reusable and hold no lab values, this file fills them in for the lab. Like
modules/waf.nix next to modules/waf-lab.nix.

- target: Garage on aldrin, the endpoint from inventory.json
  (lab.s3.endpoint, profiles/lab-s3.nix), region `garage`
- secrets: `hostSecrets` keeps the names from before restic-s3,
  one set per host (restic_password, garage_backup_key_id,
  garage_backup_secret_key, template restic-s3-env); every Garage job
  except the data jobs of modules/restic-data.nix uses them
- metrics: restic-verified writes into the textfile directory
  of modules/textfile-metrics.nix, with its prefix, so the alerts in
  hosts/grammi/alerting/backups.nix read the same series as always
- exporter: dual stack on loopback through modules/loopback-v6-proxy.nix,
  registered with modules/metrics-shipping.nix where that is enabled; a
  host that scrapes itself (grammi) registers it on its own

Retries: restic-verified's default retryAt (05:15, 07:15) lies
after the upgrade/reboot window at 04:00 (modules/deploy.nix).

Setting up a job: bucket and key in terraform/garage, `just garage-apply`,
the secrets into the job's sops file, deploy, then once `restic-<job> init`.
The exporter's read-only key: terraform/garage/restic-exporter.tf, into sops
with `just restic-exporter-secrets` (#312).

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-lab.nix)

## restic-sqlite-steps.nix

The prepare/cleanup steps of modules/restic-sqlite.nix, on their own so
tests/restic-sqlite.nix can run them without a restic job.


```
databases: { <name> = "/path/to/file.db"; ... }
dir:       where the copies go, <dir>/<name>/<file name of the database>
```


prepare: a consistent copy of each database with SQLite's online backup
(.backup), safe while the service writes - WAL mode included - and checked
with PRAGMA quick_check; a missing database or a bad copy fails the step,
so the backup run fails instead of saving a broken copy. Runs as root, so
a -wal/-shm file sqlite3 had to create gets the database's owner back -
otherwise a service that opens its database later could not.
cleanup: removes the copies.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-sqlite-steps.nix)

## restic-sqlite.nix

Reusable module: SQLite databases a restic job backs up as consistent
copies instead of the live files.


```
services.resticS3.jobs.aldrin.sqlite.readeck = "/var/lib/readeck/data/db.sqlite3";
```


Before the job reads, each database is copied with SQLite's online backup
into the job's runtime directory, /run/restic-backups-<job>/<name>/<file>,
which joins the job's paths; afterwards the copies are removed. A copy of
the live file - in a btrfs snapshot or not - can miss what is still in the
-wal file or catch a write halfway; .backup cannot. The steps are
modules/restic-sqlite-steps.nix, tested by tests/restic-sqlite.nix.

Restoring: take <name>/<file> from the snapshot, stop the service, put it
in place of the database, remove a stale -wal/-shm next to it, give it the
service's owner, start the service.

The service's other files (attachments, assets) stay the job's own `paths`;
the live database among them does no harm but is not the one to restore.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-sqlite.nix)

## samba-mesh.nix

Samba for the NetBird mesh: the lab's SMB policy (SMB3 only, macOS
friendly, no guests, no NetBIOS, mesh clients only) and the passwords of
the Samba-only accounts from sops. Shares, the accounts themselves and
their file permissions stay with the host - ursalia's Paperless consume
share (hosts/ursalia/samba.nix), tummi's /data. Taken out of
hosts/ursalia/samba.nix when tummi got a share (2026-11-01).

Accounts are Samba-only (no shell, no login, no home); SMB authenticates
with NTLMv2 against a password hash, which Pocket ID (passkeys, no LDAP)
cannot serve. Their passwords: smb_password_<user> in the host's default
sops file, entered with `just secrets <host>`.

Reachable over the NetBird mesh only: smbd listens everywhere, the firewall
admits 445 only on the trusted nb-mesh (openFirewall stays off, the LAN
side has no 445), and "hosts allow" limits clients to the mesh.

**Options** (`services.sambaMesh`):

| Option | Description |
| --- | --- |
| `enable` | Enable: Samba for the NetBird mesh |
| `users` | Samba-only accounts whose SMB password is set from sops (smb_password_<user>) on every boot and switch. The system users themselves are declared by the host. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/samba-mesh.nix)

## ssh.nix

Shared sshd policy. The authorized keys themselves stay per host - each host
has its own keypair on purpose - so this module only defines *who may log in
from where*, never *with which key*.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/ssh.nix)

## telemetry-ingest.nix

Reusable module: vmauth as the one way in for metrics and logs from other
hosts, in front of a VictoriaMetrics and a VictoriaLogs that listen on
loopback only. Every sender is a user of its own (basic auth) and may
reach only the write paths it needs:


```
/api/v1/write    -> VictoriaMetrics (vmagent's remote write)
/insert/jsonline -> VictoriaLogs    (Vector's http sink)
/api/v1/query    -> VictoriaMetrics (only for users with query = true)
```


Everything else - other query APIs, vmui, delete_series, /metrics, /flags -
is answered by vmauth itself with 400 (no route) or 401 (no or wrong
credentials); its own internal endpoints listen on loopback only.

forceHost puts the sender's identity on everything it writes: extra_label
for VictoriaMetrics, extra_fields for VictoriaLogs. For logs the stream
fields are fixed here as well (logStreamFields): without them a sender
could send its own `_stream` field and keep a forged `host` in the stream
identity while only the plain field is replaced. vmauth's own query
arguments come first and VictoriaLogs reads the first, so a sender's
_stream_fields or extra_fields are ignored. All checked against VM
1.156.0 / VL 1.52.1 on 2026-11-15. Leave forceHost null only for a sender
that legitimately writes for other hosts (a scraper for devices that
cannot ship themselves); it keeps its own stream fields.

Passwords come from environmentFile, one variable per user
(envName below); vmauth replaces %{VAR} in its config with them, so
the config in the store holds no secret.

**Options** (`services.telemetryIngest`):

| Option | Description |
| --- | --- |
| `enable` | Enable: vmauth as the authenticated ingest endpoint for VictoriaMetrics and VictoriaLogs |
| `listenAddress` | Where vmauth accepts senders (vmauth's default port). |
| `internalListenAddress` | vmauth's own /metrics, /health and /-/reload. Kept off listenAddress so senders cannot reach them. |
| `metricsUrl` | VictoriaMetrics to forward to. |
| `logsUrl` | VictoriaLogs to forward to. |
| `logStreamFields` | VictoriaLogs stream fields forced for users with forceHost - the ones the senders use themselves (modules/log-shipping.nix). |
| `environmentFile` | KEY=VALUE file with one password per user, named TELEMETRY_<USER> (upper case, dashes as underscores). Read by systemd, so it may be root-only (a sops template). |
| `envName` | User name -> its variable in environmentFile, for whoever writes that file. |
| `users` | One entry per sender; the name is the basic-auth user name. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/telemetry-ingest.nix)

## telemetry-sender.nix

This lab's senders of metrics and logs: once hosts/<host>/telemetry.yaml
exists (`just telemetry-credentials`), vmagent and Vector ship to grammi's
vmauth on :8427 (hosts/grammi/telemetry-ingest.nix, nixlab#15) as the user
named after this host, instead of to VictoriaMetrics/-Logs directly.
Without the file nothing changes.

The password comes from sops; a host without sops of its own (the gw-remote
container, whose secrets aldrin mounts in) sets fromSops = false and
passwordFile instead.

**Options** (`services.telemetrySender`):

| Option | Description |
| --- | --- |
| `url` | grammi's ingest endpoint (vmauth). |
| `fromSops` | Take the password from hosts/<host>/telemetry.yaml via sops. |
| `passwordFile` | This host's ingest password; null keeps shipping without one, to the old ports. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/telemetry-sender.nix)

## textfile-metrics-lab.nix

The lab side of the textfile-metrics collection, the input
textfile-metrics (github.com/tioan/nixos-textfile-metrics, #327, item 3):
the sandbox profile, the textfile collector with its sandboxed writers, the
state-metrics jobs and the single writers. Every module that writes
textfile metrics or uses the sandbox profile imports this file, so the
lab's prefix is set wherever the options exist.

The lab's own metrics keep the prefix nixlab_, which the alert rules on
grammi (hosts/grammi/alerting/) and the dashboards read.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/textfile-metrics-lab.nix)

## v64-measure.nix

Measures what ipv64.net's v64 blocklist would add on top of CrowdSec,
without blocking anything (admin/nixlab#171). Run for about 30 days, then
decide: block with guardrails, or drop this module.

The list: Honeypot64 by IPv64.net, CC BY 4.0, daily version without account

```
https://ipv64.net/blocklists/ipv64_blocklist_v64.txt
https://github.com/ipv64net/node64/blob/68b0c62fe986b490168e5ea9bc990d71f72022cc/docs/HONEYPOT64.md
```

Attribution is required if it is ever used for blocking.

Two counting points in the input hook, rules with `counter` and no verdict:

```
pre   priority filter - 10, before CrowdSec's bouncer and the firewall:
every packet from a listed source.
post  priority filter + 10, after both: what CrowdSec and nixos-fw let
through - the traffic v64 would actually have stopped in addition.
```


NetBird's client watches for foreign input chains and puts an
`iifname "nb-mesh" accept` at the top of each, these two included (seen on
zummi 2026-11-15). Harmless here: accept only ends that base chain, CrowdSec
and nixos-fw still see the packet, and mesh sources are never on the list.

The table is this module's own, not in networking.nftables.tables: the
nftables service deletes and re-creates its declared tables on every
reload, which would empty the sets and reset the counters on each switch.
v64-table creates the skeleton when it is missing; loading a list only
replaces the set contents, in one nft transaction. Stopping v64-table (or
removing this module) deletes the table.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/v64-measure.nix)

## waf-lab.nix

The lab's glue for modules/waf.nix: where the bouncer key lives. The WAF
module itself takes the key as a runtime path and knows nothing of sops or
this repository's layout (admin/nixlab#327).

`just waf-key <host>` registers the bouncer with the host's LAPI and writes
its key to hosts/<host>/waf.yaml (sops): crowdsec_nginx_bouncer_api_key on
an nginx host, crowdsec_traefik_bouncer_api_key on a Traefik host. Until
that file exists the AppSec engine runs, but no proxy asks it.

The Traefik plugin judges the client by X-Forwarded-For only when the peer
is the mesh: the NetBird reverse proxy reaches Traefik's apps entrypoint
from there (hosts/grammi/traefik.nix).

Plus the metrics for "AppSec unreachable" and "AppSec refuses the key": a
textfile writer (modules/textfile-metrics-lab.nix) runs the WAF module's probe
once a minute with the bouncer's key. Both bouncers fail open
(services.waf.failOpen), so without it an AppSec that is down would only
show as a WAF that never blocks. The alerts are WafAppsecDown and
WafAppsecProbeFailed in hosts/grammi/alerting/security.nix.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/waf-lab.nix)

## waf.nix

Web application firewall: CrowdSec's AppSec component in front of public
web vhosts, through nginx (OpenResty + CrowdSec's Lua bouncer) or Traefik
(CrowdSec's Traefik plugin). Decided 2026-10-25 - until then CrowdSec only
read the access logs after the fact (modules/crowdsec.nix), so it banned a
scanner once it had shown itself, but the one request carrying an exploit
still reached the service. AppSec judges each request before the proxy
passes it on. Rolled out to every front door in admin/nixlab#4.

Self-contained: no lab values in here. The host says which names go
through AppSec, in which mode, with which exceptions, and where the
bouncer's API key is at runtime (modules/waf-lab.nix does that from sops
for this lab).

Why AppSec and not ModSecurity: one engine for nginx and Traefik, and its
matches become CrowdSec alerts and bans like everything else - no second
log to wire up. The OWASP Core Rule Set still comes along, run by AppSec's
Coraza engine, just out of band.

The pieces:

- Rules, in band (decide before the request is let through):
  crowdsecurity/appsec-virtual-patching (~200 rules for known CVEs),
  crowdsecurity/appsec-generic-rules (.env, .git, SSTI, ...), and the
  own ones below (homelab/*: script types and stacks nothing here runs).
- Rules, out of band (only evaluated, never block a request by
  themselves): crowdsecurity/appsec-crs, the OWASP CRS. Its hits are
  events; crowdsecurity/crowdsec-appsec-outofband bans an IP when its
  bucket overflows: capacity 5, one token leaking every 30 s.
- Bans: every in-band match gets a 403; the IP is banned once two
  *different* in-band rules hit within 60 s (crowdsecurity/appsec-vpatch:
  capacity 1 with distinct rule_name). Enforced by whatever bouncers the
  host runs - the firewall bouncer on every port, the Lua bouncer and the
  Traefik plugin for requests that arrive through a proxy.

Mode, per name (option `hosts`, default `mode`):

- block: in-band matches get a 403, matches feed the ban scenarios.
- detect: in-band matches are answered with "allow" and their events are
  cancelled, so nothing is blocked and no ban scenario sees them; the
  alerts stay (`cscli alerts list`, the console). Every new name starts
  here for a week or two.
  The log-based HTTP scenarios from modules/crowdsec.nix do not depend on
  the mode.

Failure: `failOpen` (default). If CrowdSec is down or slow, requests go
through unchecked rather than the services going down with it. Neither the
Lua bouncer nor the Traefik plugin can decide this per name, so it is one
switch for the host; the metric `<prefix>waf_appsec_up` is what gets
noticed. It comes from `probe.package`, which the host runs on a timer
(modules/waf-lab.nix): with the bouncer key it sends one harmless request
from `probe.address` and checks for a 200; the scraper drops the AppSec
counters that request adds (`probe.metricRelabelConfigs`). Until
admin/nixlab#452 the probe asked without key, and CrowdSec logged
"missing API key" at error level once a minute. Single requests AppSec did
not judge in time (`appsecTimeout`, mostly while CrowdSec loads its rules
after a restart) count as `result="unchecked"` in
`<prefix>waf_requests_total` on nginx, next to the latency histogram
`<prefix>waf_appsec_duration_seconds` (admin/nixlab#413).

Docs: docs/site/*/explanation/waf.md.

**Options** (`services.waf`):

| Option | Description |
| --- | --- |
| `enable` | Enable: the CrowdSec AppSec WAF for this host's public web vhosts |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/waf.nix)

## web-baseline.nix

What every web front of the lab does the same way: security headers, a
default server for names nobody serves, and the shape of a vhost.
admin/nixlab#308, #12, #234 and #319; docs: docs/site/*/explanation/
web-baseline.md.

Security headers (option lab.web.securityHeaders). The values are kept
once here; nginx renders them below, Traefik on grammi reads the same
attribute set (hosts/grammi/netbird.nix).

- nginx sets them at the http level, so every server and location
  inherits them - the vhosts of this module, the docs site, the proxy
  listeners and whatever comes next.
- A header the application sends itself wins: each one goes through a map
  on $upstream_http_<name>, and an empty value makes add_header skip it.
  OpenCloud's, paperless' and HealthLog's own (stricter) values stay as
  they are, without a second copy next to them.
- `always`, so the 503 maintenance page and nginx's own errors carry them
  too.
- nginx's add_header inheritance: a level that has an add_header of its
  own inherits none from above. Such a location has to repeat them
  (lab.web.nginx.headers); evaluation fails otherwise.

Default servers (#12, #234 decision 4a). A request for a name no vhost
serves used to land in the first vhost on that address - pocket-id on
zummi, OpenCloud on aldrin, with a 200. Now:

- 443: the TLS handshake is refused for an unknown or missing SNI
  (ssl_reject_handshake, no certificate needed); a known SNI with an
  unknown Host header is closed without an answer (444).
- 80: every Host is redirected to https://$host - port 80 does nothing
  else, whatever the name. What #234's port-80 probes check.

The vhost helper (option lab.vhosts) for the recurring shape: certificate
by DNS-01, forceSSL, proxy to a loopback port, websockets, mesh-only
allow/deny, maintenance and WAF registration. Or, with proxyListener, the
plain-HTTP listener a NetBird reverse proxy service points at. Anything
else of the vhost goes into `nginx`, merged into services.nginx.
virtualHosts as it is.

**Options** (`lab.web`):

| Option | Description |
| --- | --- |
| `securityHeaders` | Response headers every web front adds unless the application sent them itself. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/web-baseline.nix)
