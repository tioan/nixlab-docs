# Modules (generated)

Generated from the header comment and the options of every module under `modules/` – the counterpart of the [hand-written overview](modules.md).

## acme.nix

ACME defaults for every host that serves TLS.

DNS-01 against deSEC rather than HTTP-01: it needs no inbound port 80 for the
challenge and can issue for names that never resolve publicly.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/acme.nix)

## auto-upgrade-git.nix

Reusable module: nightly `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`
via system.autoUpgrade, which then commits + pushes the updated flake.lock
back to the git repo the flake lives in. Meant to be dropped into any
host's `modules` list unchanged (see hosts/zummi for the reference usage).

**Options** (`services.autoUpgradeGit`):

| Option | Description |
| --- | --- |
| `enable` | Enable: nightly auto-upgrade with automatic flake.lock commit + push |
| `flakeDir` | Directory containing the flake (and its git checkout) to upgrade from. |
| `flakeAttr` | nixosConfigurations attribute name to build, i.e. the `#<attr>` part of the flake ref. |
| `updateInputs` | Flake inputs to update before rebuilding. Empty list skips the update step entirely. |
| `dates` | systemd calendar expression for when to run, passed through to system.autoUpgrade.dates. |
| `allowReboot` | Whether to allow automatic reboots after a kernel/boot-relevant upgrade. |
| `rebootWindow` | Restrict automatic reboots to this time window. Null means no restriction beyond `dates`. |
| `deployKeySecret` | Name of the sops secret holding the write-enabled SSH deploy key for the flake's git repo. Declared automatically by this module (mode 0400, owner root) - just put the key under this name in the host's secrets.yaml. |
| `gitAuthorEmail` | Email used for the git author/committer identity of the automated flake.lock commit. |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git.nix)

## base.nix

Baseline every host in this lab shares: locale, console, time, and the
handful of tools that should exist on any machine you might have to debug
from a VNC console at two in the morning.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/base.nix)

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
one machine and to the tailnet being up.

What this is actually for: SSH here is key-only with root confined to the
tailnet (modules/ssh.nix), so the constant bot noise on port 22 cannot
succeed and CrowdSec mostly quiets the logs. The real target is port 443 -
pocket-id on zummi is an OIDC provider and the one place where credentials
can be guessed, and aldrin exposes Garage's S3 API.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec.nix)

## deploy.nix

How this lab ships and updates itself: every host keeps /etc/nixos as a
checkout of the private GitHub repo admin/nixlab, pulls from it on deploy,
and upgrades itself nightly - committing the refreshed flake.lock back.

Kept separate from modules/auto-upgrade-git.nix on purpose. That module
documents itself as host-agnostic and reusable; hardcoding a git forge and a
specific secret name into it would take that away. It stays the mechanism,
this file is the lab's policy.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy.nix)

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

- each host gets its own; hosts whose deSEC token is limited to named
  records need "doku" in their acme_names (terraform/desec-tokens/main.tf).

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

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/docs-site.nix)

## firewall.nix

Shared firewall baseline for every homelab host.

Public surface is deliberately tiny: SSH plus HTTP(S). Anything arriving over
the tailnet is trusted wholesale via trustedInterfaces, so tailnet-only
services (garage-ui behind `tailscale serve`, the admin APIs) need no port
openings of their own.

Note that several of these exist only because of Tailscale, but they live
here rather than in tailscale.nix so that the whole networking.firewall
namespace stays in one place.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/firewall.nix)

## log-shipping.nix

Reusable module: ship this host's journald log and nginx's access log to a
central VictoriaLogs instance (grammi) via Vector. Switched on per host with
services.logShipping.enable (see hosts/aldrin, hosts/zummi).

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
| `remoteWriteUrl` | VictoriaMetrics remote_write endpoint, over the NetBird mesh. Mesh-only by design - see hosts/grammi/configuration.nix, the ingest port is not in networking.firewall.allowedTCPPorts, only reachable over the trusted mesh (and tailnet) interface. |
| `exporterPorts` | Local ports to scrape, named - this host's own services.prometheus.exporters.<name>.port values. The name becomes this target's `instance` label in VictoriaMetrics, so vmui shows e.g. "node"/"nginx" instead of an undifferentiated "127.0.0.1:9113". |

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics-shipping.nix)

## metrics.nix

Per-node metrics exporters.

Everything here binds 0.0.0.0 and stays off the public internet through the
firewall rather than through bind addresses: modules/firewall.nix opens only
22/80/443 to the world and trusts tailscale0 wholesale, so an exporter that
is not in allowedTCPPorts is reachable over the tailnet and nowhere else.

Binding the Tailscale address directly would be tighter, but tailscale0 does
not exist yet when these units start at boot, and a listener cannot bind an
address that is not there. The firewall is the more robust guard.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics.nix)

## netbird.nix

NetBird client, joining the homelab mesh (control plane: mesh.homelab.example,
hosts/grammi/netbird.nix; account: terraform/netbird). Runs next to
Tailscale, not instead of it - see modules/tailscale.nix, which stays as
it is until individual services move over.

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

## nix.nix

Nix daemon and store housekeeping, shared by every host.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/nix.nix)

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
root shell on every host, with no SSH key, past CrowdSec, past Tailscale -
and read access to /run/secrets, where sops-nix has already decrypted
everything. guest-exec and guest-file-* ARE that shell; the rest of the list
below is incidental.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/qemu-guest.nix)

## ssh.nix

Shared sshd policy. The authorized keys themselves stay per host - each host
has its own keypair on purpose - so this module only defines *who may log in
from where*, never *with which key*.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/ssh.nix)

## tailscale.nix

Shared Tailscale setup. Per-host `tailscale serve` definitions stay in the
host's own configuration.nix - only the node agent itself is common.

[Source](https://github.com/tioan/nixlab-docs/blob/main/modules/tailscale.nix)
