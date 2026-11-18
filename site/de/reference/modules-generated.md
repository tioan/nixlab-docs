# Module (generiert)

Automatisch erzeugt aus dem Kopfkommentar und den Optionen jedes Moduls unter `modules/` – Gegenstück zur [handgeschriebenen Übersicht](modules.md). Die Kommentare sind englisch, wie aller Code-Kommentar im Repo.

## acme.nix

ACME defaults for every host that serves TLS.

DNS-01 against deSEC rather than HTTP-01: it needs no inbound port 80 for the
challenge and can issue for names that never resolve publicly.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/acme.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git-pull.nix)

## auto-upgrade-git.nix

Reusable module: nightly `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`
via system.autoUpgrade, optionally after fast-forwarding the checkout the
flake lives in to a verified upstream commit. It never commits or pushes: a
flake.lock changed by `updateInputs` is built and switched, then reset at
the next start. Meant to be dropped into any host's `modules` list
unchanged (see hosts/zummi for the reference usage).

**Optionen** (`services.autoUpgradeGit`):

| Option | Beschreibung |
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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/auto-upgrade-git.nix)

## base.nix

Baseline every host in this lab shares: accounts, kernel hardening,
locale, console, time, and the handful of tools that should exist on any machine you might have to debug
from a VNC console at two in the morning.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/base.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/container-pins.nix)

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

**Optionen** (`services.crowdsecBuckets`):

| Option | Beschreibung |
| --- | --- |
| `vhost` | nginx virtualHost (attribute name) that serves the S3 API. It gets its own access log, and only lines from that log can be exempted. null: no bucket whitelist on this host. |
| `buckets` | Bucket names (path-style) whose ordinary traffic is not counted. |
| `logFile` | The vhost's access log, in nginx's combined format, for anything else that reads nginx's access logs. Matches /var/log/nginx/*.log, so CrowdSec and logrotate pick it up without further configuration. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/crowdsec.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy-hold.nix)

## deploy.nix

How this lab ships and updates itself: every host keeps /etc/nixos as a
checkout of the private GitHub repo admin/nixlab, pulls from it on deploy,
and upgrades itself nightly - committing the refreshed flake.lock back.

Kept separate from modules/auto-upgrade-git.nix on purpose. That module
documents itself as host-agnostic and reusable; hardcoding a git forge and a
specific secret name into it would take that away. It stays the mechanism,
this file is the lab's policy.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy.nix)

## disk-health.nix

SMART health of a physical host's disks: smartd runs the drives' own
self-tests and watches their attributes, smartctl_exporter publishes the
values, vmagent ships them to grammi - dashboard
hosts/grammi/dashboards/disk-health.json. For bare-metal hosts only; the
VMs have no SMART to speak of. Switched on by listing the disks:


```
services.diskHealth.devices = [
"/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_<serial>"
"/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_<serial>"
];
```


Listed, not autodiscovered: behind the ArkKVM a host also sees the KVM's
virtual USB drive and virtual media, which are not worth polling. By-id
paths with model and serial rather than kernel names, because /dev/sdX
moves with whatever USB devices are plugged in, and the path ends up in
the exporter's `device` label - it should say which disk it is.

Schedule, staggered by position in the list so no two tests of one host
run at the same time (a long test reads the whole disk - 640 min on the
8 TB QVO - and slows its I/O while it runs):

```
short     every Sunday, 03:00 for the first disk, 04:00 for the second, ...
extended  monthly at 01:00, on the 1st for the first disk, the 2nd for
the second, ...
```

smartd's -a additionally checks health and attributes every 30 minutes and
logs every change and every failed test to the journal, which log
shipping forwards to VictoriaLogs on grammi.

smartctl_exporter 0.14 does not export the self-test log, so the outcome
of the tests goes through node_exporter's textfile collector instead
(hourly, same `device` label as the exporter - the by-id basename):


```
smart_selftest_running{device}                      1 while a test runs
smart_selftest_last_passed{device,test}             1 = completed without error
smart_selftest_last_power_on_hours{device,test}     power-on hours of that test
```


test is short/extended/other. last_passed is 0 for aborted tests too (a
reboot during the 11 h QVO test, for instance) - the journal says which.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/disk-health.nix)

## dns01-names.nix

Names a host answers ACME DNS-01 challenges for outside of
security.acme.certs: a Caddy of its own (nix-darwin has no security.acme),
or a DNS-01 proxy that writes challenges for other clients with this
host's DNS provider token.

Only a declaration - nothing here acts on it. Whatever scopes the host's
token reads it together with security.acme.certs; in this lab that is
lib.dns01Names in flake.nix, which feeds terraform/desec-tokens.
Plain option module, so it works on NixOS and nix-darwin alike.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/dns01-names.nix)

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

**Optionen** (`services.docsSite`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: the private docs site on the mesh |
| `package` | The built site - the flake's docs-site package. |
| `fqdn` | Name the site is served under (a mesh-only NetBird DNS zone). |
| `allow` | Addresses or networks nginx serves the site to; everyone else gets 403, with a page that says why and how a device gets in. Default: the whole mesh. The lab sets the admins' devices from terraform/netbird/admin-peers.json (flake.nix) - see the header of terraform/netbird/admin-peers.tf for why it is an address list. |
| `redirectPort` | Port of a plain-HTTP listener that answers every request with a redirect to redirectTo, keeping the path - the target of the NetBird reverse proxy service for the same name, so a visitor from outside the mesh lands on the public docs. A port of its own because the proxy's peer has no address that is known in advance; the port is only open on the mesh (nb-mesh is a trusted interface) and admits only the mesh. null: no listener. |
| `redirectTo` | Where redirectPort sends visitors, without a trailing slash; the request path is appended. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/docs-site.nix)

## firewall.nix

Shared firewall baseline for every homelab host.

Public surface is deliberately tiny: SSH plus HTTP(S). The NetBird mesh
interface is trusted by modules/netbird.nix; NetBird's own UDP port is
opened there too.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/firewall.nix)

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

**Optionen** (`networking.forwardFilter`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: IP forwarding, filtered: new connections only along the allowed interface pairs |
| `ipv6` | Also forward IPv6 (net.ipv6.conf.all.forwarding). The filter covers both families either way. |
| `allow` | Interface pairs along which new connections are forwarded. Replies (established/related) and destination-NATed port forwards need no entry. Whatever filtering the overlay client does on top stays in force. |
| `overlayInterfaces` | Overlay interfaces (VPN meshes). New connections into them from any other interface are dropped by a guard chain unless an `allow` pair names that way, ICMPv6 included. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/forwarding.nix)

## fwupd.nix

Firmware updates from LVFS on the physical host (ursalia).
Nothing is ever installed automatically, and that has to stay so: a BIOS
capsule moves PCR 0 and with it the TPM keyslot that unlocks the disk, and
under Secure Boot without shim the firmware runs fwupdx64.efi only when it
is signed with the host's own sbctl key - see docs/install-ursalia.md
("Firmware-Updates"). Updates are installed by hand, with somebody at the
console or the ArkKVM.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/fwupd.nix)

## hardening.nix

Reusable module: one systemd sandbox profile for services, in graded
levels, instead of a hand-copied block of directives per unit
(admin/nixlab#18, #320).


```
systemd.services.foo.hardening = {
enable = true;
level = "standard";
network = "loopback";
capabilities = [ "CAP_DAC_READ_SEARCH" ];
};
```


Every exception is an explicit argument, so `git grep hardening` shows
what each unit was allowed and the comment next to it says why. The
directives are set at normal priority: a unit that defines the same
single-valued directive differently fails evaluation instead of silently
winning or losing - pick one place.

What each directive typically breaks, so an exception is deliberate:


```
level "base" - safe for nearly every daemon
NoNewPrivileges        setuid helpers (sudo, ping without caps, newuidmap)
ProtectSystem=strict   writes outside writablePaths and the unit's own
State/Cache/Logs/RuntimeDirectory
ProtectHome            anything under /home, /root, /run/user
PrivateTmp             sharing files through /tmp with other units
PrivateDevices         raw devices: disks (smartctl), GPU, serial,
/dev/virtio-ports; see `devices`
ProtectKernelTunables  writing /proc/sys, /sys (sysctl, nft does not care)
ProtectKernelModules   modprobe from the service
ProtectKernelLogs      dmesg / /dev/kmsg readers
ProtectControlGroups   cgroup writes (container managers); reads stay
ProtectClock           setting the clock; implies DevicePolicy=closed,
which together with `devices` is fine
ProtectHostname        sethostname
RestrictNamespaces     user namespaces: podman, gVisor, bubblewrap,
Chromium's sandbox
RestrictRealtime       audio/RT scheduling
RestrictSUIDSGID       creating setuid files
LockPersonality        old 32-bit personality tricks
SystemCallArchitectures=native  32-bit binaries on x86_64
```



```
level "standard" - base plus
CapabilityBoundingSet  everything not in `capabilities` (empty = none);
root services that chown, bind < 1024 or read
foreign files need theirs listed
SystemCallFilter       @system-service minus @privileged (chown, setuid,
mount, raw I/O, ...) and @resources (setrlimit,
sched_setaffinity, ...); add back with
`systemCalls`; a violation is EPERM, not a kill
ProtectProc=invisible  seeing other users' processes (/proc/<pid>);
ProcSubset=pid           /proc/cpuinfo, /proc/meminfo, /proc/net -
`seeProcesses` turns both off
UMask=0077             files other users are meant to read: set
`umask` (e.g. "0022" for textfile metrics)
```



```
level "strict" - standard plus
MemoryDenyWriteExecute JIT runtimes: Node, Java, LuaJIT, PyPy, some
regex engines; `writeExecute` keeps them working
PrivateIPC             SysV IPC / POSIX queues shared with other units
RemoveIPC              the same, for a static user's leftovers
```



```
network (independent of the level)
"none"      PrivateNetwork, AF_UNIX only: no sockets but local ones
"netlink"   host namespace, AF_UNIX + AF_NETLINK, no IP sockets: for
kernel state such as nftables counters (with CAP_NET_ADMIN)
or nl80211; cannot open a connection
"loopback"  IP sockets, but IPAddressDeny=any except localhost
"any"       IP sockets to anywhere
`addressFamilies` adds to the list (e.g. AF_NETLINK for getifaddrs).
```

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/hardening.nix)

## hotfixes.nix

Package hotfixes that switch themselves off.

MANDATORY (rule of 2026-11-15, nixlab#321): every override that waits for
nixpkgs - "drop this once nixpkgs has ..." - goes through `hotfix`, never
a bare overrideAttrs with such a comment. Overrides that are meant to stay
(a local patch, a build variant, tests switched off) are not hotfixes and
stay plain overrides; their comment says so ("permanent, not a hotfix").
The Macs do not load this module; there is no hotfix on them yet.

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
package no longer takes the argument the override replaces"
(modules/hotfixes/gotenberg.nix). Pick a test that flips in the same
nixpkgs commit as the fix, so it cannot switch the hotfix off early.

Credits: the pattern is snowball's (BBBSnowball), offered for reuse on
2026-10-23 - version check plus CVE patch detection, one overlay per file:
https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes
Ours adds the warning: there the override goes quiet without telling anyone.

Hotfixes for packages from the host's own pkgs go into modules/hotfixes/,
one overlay per file, as `hotfix: final: prev: { <pkg> = hotfix { ... }; }`;
every file there is loaded on every NixOS host. Packages taken from another
nixpkgs (`inputs.<pin>.legacyPackages.${system}`) do not see these overlays - call
`hotfix` on them in the host module instead.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/hotfixes.nix)

## intel-gpu-metrics.nix

Load of an Intel iGPU for node_exporter's textfile collector, from
intel_gpu_top (igt-gpu-tools). Shipped to grammi with the other node
metrics; panels in hosts/grammi/dashboards/immich.json (ursalia's iGPU runs
Immich's machine learning through OpenVINO and its video transcoding
through Quick Sync).

Neither node_exporter nor a packaged exporter covers i915 engine load. The
one exporter around (onedr0p/intel-gpu-exporter) is archived, carries no
license, and reads engine names with a "/0" suffix that current
intel_gpu_top no longer prints - its busy values would stay 0. So a small
bridge of our own: intel_gpu_top -J runs for good, one sample every 15 s,
and modules/intel-gpu-metrics.py rewrites intel-gpu.prom after each one.


```
intel_gpu_engine_busy_percent{engine}          Render/3D, Video, VideoEnhance, Blitter, ...
intel_gpu_engine_wait_percent{engine}
intel_gpu_frequency_mhz{type}                  requested / actual
intel_gpu_rc6_percent                          time in the power-saving state
intel_gpu_power_watts{domain}                  gpu / package (RAPL)
intel_gpu_interrupts_per_second
intel_gpu_imc_bandwidth_mibps{direction}       only where the uncore PMU offers it
intel_gpu_client_busy_percent{name,engine}     per process name (gunicorn = Immich ML, ffmpeg)
intel_gpu_client_memory_resident_bytes{name}   GPU buffers in system RAM
intel_gpu_last_sample_timestamp_seconds        stale = the bridge is down
```


Process names, not pids: a pid label would start new series on every
restart. NixOS wrapper names (".gunicorn-wrapped", cut to 15 characters)
are reduced to the program name.

**Optionen** (`services.intelGpuMetrics`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: Intel iGPU load metrics from intel_gpu_top |
| `device` | intel_gpu_top -d filter; null takes the first Intel GPU. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/intel-gpu-metrics.nix)

## lab.nix

Lab-wide constants that several modules and hosts need, declared once.
The values are set from inventory.json by profiles/services.nix;
this file only declares them, so the modules that read them stay free of
lab values.

Only the mesh ranges for now (admin/nixlab#319). Their other literal uses
(sshd's Match, CrowdSec's whitelist, Samba, Traefik's trustedIPs, ...)
move over one by one - the list is in that issue.

**Optionen** (`lab.mesh`):

| Option | Beschreibung |
| --- | --- |
| `ipv4` | IPv4 range of the mesh overlay every peer gets its address from. |
| `ipv6` | IPv6 range of the mesh overlay; null when it has none. |
| `networks` | Both ranges as a list, for allow lists. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/lab.nix)

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

**Optionen** (`services.logShipping`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: ship this host's journald log to grammi's VictoriaLogs via Vector |
| `victoriaLogsUrl` | Base URL of the VictoriaLogs instance to ship to. Over the NetBird mesh, same reasoning as services.metricsShipping.remoteWriteUrl. |
| `httpRetryStrategy` | Vector retry_strategy for every sink that writes to the ingest with httpAuth. |
| `httpAuth` | Vector `auth` block for basicAuth (null without), for other sinks or http_client sources on this host that reach the same ingest. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/log-shipping.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/logging.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/loopback-v6-proxy.nix)

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

**Optionen** (`services.maintenance`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: maintenance mode and error pages for the host's web front (nginx/Traefik) |
| `port` | Loopback port of the responder that renders the maintenance and error pages. |
| `retryAfter` | Retry-After (seconds) on the 503 maintenance page. |
| `cookieDomain` | Domain of the bypass cookie: one cookie for every service below it. |
| `cookieMaxAge` | Lifetime of the bypass cookie in seconds (default 12 h). |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/maintenance.nix)

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

**Optionen** (`services.metricsShipping`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: ship this host's Prometheus exporters to grammi's VictoriaMetrics via vmagent |
| `remoteWriteUrl` | VictoriaMetrics remote_write endpoint, over the NetBird mesh. Mesh-only by design - see hosts/grammi/configuration.nix, the ingest port is not in networking.firewall.allowedTCPPorts, only reachable over the trusted mesh interface. |
| `exporterPorts` | Local ports to scrape, named - this host's own services.prometheus.exporters.<name>.port values. The name becomes this target's `instance` label in VictoriaMetrics, so vmui shows e.g. "node"/"nginx" instead of an undifferentiated "127.0.0.1:9113". |
| `defaultExporters` | services.prometheus.exporters.<name> registered in exporterPorts automatically wherever they are enabled, so hosts list only their own extra exporters. |
| `exporterAddresses` | Loopback address to scrape per exporterPorts name, "127.0.0.1" where absent. For exporters that also answer on [::1] through modules/loopback-v6-proxy.nix: the lab prefers IPv6, so those are scraped there. IPv6 literals need their brackets. |
| `extraScrapeConfigs` | Additional vmagent scrape_configs, for targets exporterPorts cannot express - metrics_path is per job, so anything not on /metrics needs a job of its own. Named "<host>-<service>" like the crowdsec job. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics-shipping.nix)

## metrics.nix

Per-node metrics exporters.

Every exporter here listens on 127.0.0.1 only (nixlab#15, decision 3b of
2026-11-01): each host's own vmagent scrapes them locally
(modules/metrics-shipping.nix) and no host scrapes another, so nothing
needs them on the mesh. Until 2026-11 they bound 0.0.0.0 and the firewall
kept them off the internet - which left them open to every mesh peer the
NetBird policies let through.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/metrics.nix)

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

**Optionen** (`services.netbirdExitNode`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: this host as a NetBird exit node |
| `wanInterface` | The public interface exit traffic leaves through. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird-exit-node.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/netbird.nix)

## networking.nix

Networking baseline every host in this lab shares. The host-specific part -
which interface, which addresses, which routes - stays in each host's own
configuration.nix under networking.ifstate.settings; only the shape of the
setup lives here, so a new machine inherits it by importing this module.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/networking.nix)

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

**Optionen** (`services.nixCache.prebuild`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: the nightly flake.lock update, build of every host and upload to the nix cache |
| `updateInputs` | Flake inputs the nightly run updates. |
| `dates` | When to run. Early enough to be done before the hosts' nixos-upgrade (04:00 plus up to 45 minutes); a host that starts before the new lock is pushed just pulls nothing new tonight. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/nix-cache.nix)

## nix.nix

Nix daemon and store housekeeping, shared by every host.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/nix.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/no-redirects.nix)

## public-probes-targets.nix

What every public endpoint must answer, and from where it is probed - the
data behind modules/public-probes.nix (the probes on zummi and grammi) and
the PublicProbeMissing series in hosts/grammi/alerting.nix. admin/nixlab#169.

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/public-probes-targets.nix)

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
PublicProbeMissing and ServedCertExpiring in hosts/grammi/alerting.nix,
dashboard Homelab / Public endpoints.

Heartbeat (optional, `heartbeat.sopsFile`): every 5 minutes, if all of this
host's probes succeed, a ping to an external dead man's switch
(healthchecks.io). The ping asks the exporter directly, not
VictoriaMetrics, and needs neither grammi's alerting nor Home Assistant: a
failing endpoint, a dead exporter or a dead host all end in no ping, and
healthchecks.io notifies on its own channels.

**Optionen** (`services.publicProbes`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: probes of the public endpoints assigned to this host (modules/public-probes-targets.nix) |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/public-probes.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/qemu-guest.nix)

## restic-data.nix

Backs up a home host's whole data disk to Garage on aldrin, via restic. The
same job on tummi and ursalia, next to whatever else the host backs up.

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

Verification (modules/restic-verified.nix), different from the other jobs:

- minPercent 1: on a box for sorting files, moving a disk image away is
  normal. With the default every later run would fail, because the verified
  size it compares against only moves on a verified run.
- checkSubset 1%: 5% of 3 TB would be 150 GB through the home line each Sunday.

No restic exporter: the NixOS module runs one per host, and ursalia's watches
its Paperless repository. The verified metrics and the receiving side
(hosts/aldrin/s3-upload-metrics.nix) cover these jobs, see the alerts in
hosts/grammi/alerting.nix.

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

**Optionen** (`services.resticData`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: the restic backup of the data disk to Garage on aldrin |
| `secretsFile` | sops file from `just data-backup-secrets <host>`. |
| `snapshotName` | Name of the snapshot below the data disk's mount point, for a host's Samba share to hide. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-data.nix)

## restic-verified.nix

A backup only counts as successful once that has been verified (#238).

On 2026-11-08 ursalia's job to aldrin failed, and `systemctl show` still said
Result=success: the nightly switch resets failed units, and success is what
a reset unit reports. Apart from that, a unit's result says little anyway.
restic exits 0 when --files-from names a missing path (tested with 0.18.1)
or an empty directory, and it happily stores yesterday's dump when today's
failed. So for each job listed here this module replaces the ExecStart of
services.restic.backups.<name> with modules/restic-verified.sh:


```
before  every required path holds something, declared inputs (dumps, the
paperless export) finished successfully within maxAgeHours
backup  always attempted; if the checks above failed the snapshot is tagged
`unverified`, because one bad part must not cost the night's other
new data
after   the snapshot is read back from the repository: it exists, it is
from this run, its size is plausible against the last verified one,
the required paths are in it, `restic check` passes (Sundays with
a sample of the data, checkSubset)
only then
nixlab_backup_verified_timestamp_seconds moves and forget/prune
runs. Anything else sets nixlab_backup_last_run_failed, which only
a verified run clears and which, being a file, survives switches.
```


Failed jobs are started again by a timer after the upgrade window, for
whatever the reason was. Alerts: hosts/grammi/alerting.nix. Restoring: use the
snapshot ID in nixlab_backup_verified_snapshot_info rather than `latest`,
which may be an `unverified` one.

Requires `initialize = false`: the module's `restic cat config || restic init`
would answer an emptied bucket with a new repository that then counts as a
backup, and costs another five minutes when the target is unreachable.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/restic-verified.nix)

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

**Optionen** (`services.sambaMesh`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: Samba for the NetBird mesh |
| `users` | Samba-only accounts whose SMB password is set from sops (smb_password_<user>) on every boot and switch. The system users themselves are declared by the host. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/samba-mesh.nix)

## ssh.nix

Shared sshd policy. The authorized keys themselves stay per host - each host
has its own keypair on purpose - so this module only defines *who may log in
from where*, never *with which key*.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/ssh.nix)

## state-metrics.nix

Reusable module: an app's state as metrics, without changing the app. Each
job runs a command on a timer that prints Prometheus text format to stdout,
usually a read-only query against the app's own database; the result goes
into node_exporter's textfile collector (modules/metrics.nix) and from there
to grammi like every other node metric. admin/nixlab#268.

For apps that have no metrics endpoint and will not get one (Chhoto URL:
SinTan1729/chhoto-url#158), or whose interesting state is a timestamp in
their database rather than anything they would export.

Each job is a writer of modules/textfile-metrics.nix: it runs as its own
user (or the one given, e.g. for PostgreSQL peer auth) in that module's
sandbox, without a network, and can write nothing but its own directory.
A failed query keeps the previous file, so the success timestamp ages.

Every job exports

```
nixlab_state_metrics_last_success_timestamp_seconds{name}
nixlab_state_metrics_interval_seconds{name}
```

and StateMetricsStale (hosts/grammi/alerting.nix) compares the two, so a
query that starts failing - an upstream schema change, a lost GRANT - shows
up without an alert per job.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/state-metrics.nix)

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

**Optionen** (`services.telemetryIngest`):

| Option | Beschreibung |
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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/telemetry-ingest.nix)

## telemetry-sender.nix

This lab's senders of metrics and logs: once hosts/<host>/telemetry.yaml
exists (`just telemetry-credentials`), vmagent and Vector ship to grammi's
vmauth on :8427 (hosts/grammi/telemetry-ingest.nix, nixlab#15) as the user
named after this host, instead of to VictoriaMetrics/-Logs directly.
Without the file nothing changes.

The password comes from sops; a host without sops of its own (the gw-remote
container, whose secrets aldrin mounts in) sets fromSops = false and
passwordFile instead.

**Optionen** (`services.telemetrySender`):

| Option | Beschreibung |
| --- | --- |
| `url` | grammi's ingest endpoint (vmauth). |
| `fromSops` | Take the password from hosts/<host>/telemetry.yaml via sops. |
| `passwordFile` | This host's ingest password; null keeps shipping without one, to the old ports. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/telemetry-sender.nix)

## textfile-metrics.nix

Reusable module: node_exporter's textfile collector, with every writer in
a sandbox that can write its own files and nothing else
(admin/nixlab#320).

Layout under `directory`:


```
<directory>/*.prom                 root-owned; only for writers that are
root jobs anyway (an upgrade, a backup)
<directory>/writers/<name>/*.prom  one directory per writer, owned by the
writer's user, 0755
```


node_exporter reads both: the textfile flag is repeatable and takes a glob
(node_exporter >= 1.8). A writer's user owns only its own directory and
its unit sees the filesystem read-only apart from it (ProtectSystem=strict
via modules/hardening.nix), so a broken or compromised writer can neither
fake another writer's metrics nor write anywhere else.

Two ways in:


```
writers.<name>      a oneshot unit plus timer; the script prints the
metrics to stdout, the module writes them atomically
to writers/<name>/<file> - or, with file = null, the
script writes its files itself with `write-prom`.
directories.<name>  just the directory, for a unit defined elsewhere (a
long-running exporter bridge, several units sharing
one user); that unit puts the path into its own
ReadWritePaths.
```


Files are written as "<dir>/.<file>.tmp" and renamed, because the collector
reads whatever is there whenever it is scraped; a failing run keeps the
previous file. Moving a writer here from the root directory removes its old
file there (legacyFiles), so the two never export the same series twice.

**Optionen** (`services.textfileMetrics`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: node_exporter's textfile collector with sandboxed writers |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/textfile-metrics.nix)

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

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/v64-measure.nix)

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

Plus the metric for "AppSec unreachable": a textfile writer
(modules/textfile-metrics.nix) asks the AppSec port once a minute. Both
bouncers fail open (services.waf.failOpen), so without it an AppSec that
is down would only show as a WAF that never blocks. The alert is
WafAppsecDown in hosts/grammi/alerting.nix.

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/waf-lab.nix)

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
noticed.

Docs: docs/site/*/explanation/waf.md.

**Optionen** (`services.waf`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: the CrowdSec AppSec WAF for this host's public web vhosts |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/waf.nix)

## watchdog.nix

The hardware watchdog, held by systemd (issue #117).

With RuntimeWatchdogSec set, PID 1 opens the watchdog device at boot and
pings it every half timeout. If PID 1 hangs (a crash freezes it, see
CrashAction= in systemd-system.conf(5)) or the kernel locks up, the pings
stop and the hardware resets the host. RebootWatchdogSec (systemd's 10 min
default) already covered a hanging shutdown; this adds the running system.

Holding the device is also a guard: a watchdog device can only be open
once, so nothing else gets it (EBUSY). That is how ursalia was reset four
times on 2026-11-02/03: procd, PID 1 of gruffi's OpenWrt dry-run container
(openwrt/gruffi/dryrun.sh, a VM since #181), opened /dev/watchdog, armed intel_oc_wdt and
let go without the magic close when the container was removed - the
hardware reset the host a minute later.

The timeout stays the device's own ("default" - 60 s for intel_oc_wdt on
the NUCs, 30 s for the ICH9 iTCO that QEMU emulates on the VMs). TCO v2
cannot go much beyond that anyway.

A host with more than one watchdog lists the others in blacklistedModules:
the kernel numbers watchdogs in probe order, so with two drivers loading
in parallel watchdog0 is not fixed, and the one systemd does not hold
would be free for a container to arm.

Hosts without any watchdog device (zummi on IONOS) get softdog, the
kernel's software watchdog - see the softdog option.

Test: `kill -SEGV 1` freezes systemd; the host has to reset within one
timeout. `kill -STOP 1` does nothing (the kernel ignores SIGSTOP for
init), and `echo c > /proc/sysrq-trigger` tests the panic path, not the
watchdog.

**Optionen** (`services.hardwareWatchdog`):

| Option | Beschreibung |
| --- | --- |
| `enable` | Enable: the hardware watchdog, held and pinged by systemd |
| `device` | The watchdog device systemd opens (WatchdogDevice=). |
| `softdog` | Load the kernel's software watchdog, for hosts without a hardware one. It catches a hung PID 1, but not a kernel that stops running timers. |
| `blacklistedModules` | Other watchdog drivers to keep from loading, so the host has exactly one watchdog. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/watchdog.nix)

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

**Optionen** (`lab.web`):

| Option | Beschreibung |
| --- | --- |
| `securityHeaders` | Response headers every web front adds unless the application sent them itself. |

[Quelltext](https://github.com/tioan/nixlab-docs/blob/main/modules/web-baseline.nix)
