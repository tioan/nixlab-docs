# Inventory

`inventory.json` lists every machine of the lab, whether this flake configures it or not: what kind of device it is (vendor, model, serial), where it stands, how that place reaches the internet, what it runs on or is built into, where its power comes from, how its disk gets unlocked after a reboot, its networks, interfaces and addresses, and its SSH host keys. On top of the machines: the services they run and the ones bought from outside, what each service needs, where its data is backed up to, and the providers and contracts behind hosts, lines and services. These are the facts a NixOS config does not hold. Today the host keys are used: every host's known_hosts comes from here, and `nix flake check` ties them to the age keys in `.sops.yaml`. Later the rest is meant for grouping in the topology and for alert dependencies (an uplink is down, so don't page for every host behind it).

What it holds today is drawn on the [lab map](lab-map.md): every host and every service by site, with clickable dependencies.

| File | Role |
| --- | --- |
| `inventory.json` | The data. JSON, so Nix (`builtins.fromJSON`) and OpenTofu (`jsondecode`) can both read it without help. |
| `inventory.nix` | Format (`spec`), validation, derived view, JSON Schema generator. Exposed as `lib.inventory` in `flake.nix`. |
| `inventory.schema.json` | JSON Schema for the editor (completion, hover help, inline errors). Generated, never edited. |
| `tests/inventory.nix` | Tests for the validator: a complete example inventory and one case per rule. |
| `software.nix` | What the services run, read from the host configurations (`lib.software`, `just services`). |
| `flake.nix` | `lib.inventory`, the checks, and `programs.ssh.knownHosts` for every host (NixOS and nix-darwin). |

Rule of thumb for what goes in: **only what cannot be derived from a config.** OS, architecture, CPU/RAM, mesh address and exporters stay out; `topology.nix` reads those from `nixosConfigurations`. A service's version, license and language are read from its package, not written down. What a service *needs* and where its data *should* go is intent, not config – that is in here (`dependsOn`, `backup`). Every relation is stored in **one direction only**; the reverse is derived, so the two cannot disagree.

## Structure

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

### owners

Who administers a device: it decides whom to call and what may be changed.

All fields with type, default and meaning: [Inventory schema → owners](inventory-schema.md#owners).

### uplinks

An internet line. Several sites may share one (rarely), one site may have several (primary and backup).

All fields with type, default and meaning: [Inventory schema → uplinks](inventory-schema.md#uplinks).

All fields are optional, so a line can be entered before its details are known.

### sites

A place where devices stand.

All fields with type, default and meaning: [Inventory schema → sites](inventory-schema.md#sites).

### hosts

Every device with an address that matters: servers, VMs, routers, APs, KVMs, PDUs, appliances.

All fields with type, default and meaning: [Inventory schema → hosts](inventory-schema.md#hosts).

#### Kinds { #kinds }

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

### networks

A layer-2 network with its IPv4 prefix: the home LAN, a VLAN in the hackerspace.

All fields with type, default and meaning: [Inventory schema → networks](inventory-schema.md#networks).

A network without any interface is allowed – it can be entered before its devices are.

### providers

A company or club the lab depends on: an ISP, a hoster, a service bought from outside, the hackerspace.

All fields with type, default and meaning: [Inventory schema → providers](inventory-schema.md#providers).

### contracts

What is paid to a provider. One provider may have several – two VMs and an extra IPv4 at one hoster are three contracts. Hosts, lines and services name their contracts (`contracts: [...]`); what a contract covers is derived.

All fields with type, default and meaning: [Inventory schema → contracts](inventory-schema.md#contracts). The cost is in whole cents per month, per year – with the month it is charged in – or once, in its own currency; totals are kept per currency and never converted.

Customer and contract numbers do **not** go into `inventory.json`: they are in `inventory.secrets.yaml` (sops, workstation and admin key), keyed by contract id. Nothing reads that file automatically.

```yaml
realtox-grammi:
  customer: "…"
  contract: "…"
```

### services

What the hosts run, and what is bought from outside. Per-host plumbing (sshd, exporters, vmagent, Vector, CrowdSec, the mesh client) is not a service here – it is the same on every host and lives in the modules.

All fields with type, default and meaning: [Inventory schema → services](inventory-schema.md#services).

**Dependencies.** `dependsOn` and every `via` are the hard ones: together they must be free of cycles, and a service may not hard-depend on a less critical one (a `core` service on a `lab` one) – raise the other or move it to `uses`. `uses` is not part of the chain: when Pocket ID is gone, NetBird keeps its tunnels and only refuses new logins.

**Backups.** A copy counts as *off-host* when its target runs on none of the service's own hosts, or is a service from outside. A `stateful` service on hosts without an off-host copy is not an error but is listed in `gaps` – local snapshots on the same disk are no backup.

## Interfaces { #interfaces }

`hosts.<id>.interfaces` maps interface names to their data. The name is what the OS calls it (`eno1`, `wlp2s0f0`, `en0`); for an appliance any label (`lan`, `wan`). A VLAN interface on a trunk (`eno1.20`) is an entry of its own; its VLAN id comes from its network.

```json
"interfaces": {
  "eno1":    { "mac": "52:54:00:12:34:56", "medium": "ethernet", "linkLocal": "eui64",
               "network": "lan", "ipv4": { "mode": "reserved", "address": "192.0.2.10" } },
  "eno1.20": { "network": "iot", "linkLocal": "fe80::1234", "ipv4": { "mode": "dhcp" } }
}
```

All fields with type, default and meaning: [Inventory schema → hosts](inventory-schema.md#hosts).

**Link-local.** Only with EUI-64 does the address follow from the MAC (`fe80::` + MAC with the U/L bit flipped and `ff:fe` in the middle); the derived `ipv6LinkLocal` is computed then. Many systems use `stable-privacy` instead (RFC 7217: stable, but not computable), macOS and tvOS do not derive it from the MAC either. When the address is stable and known, enter it directly (`"fe80::…"`); `just inventory-collect` does exactly that when it does not match EUI-64. `eui64` needs a `mac`; with a *locally administered* Wi-Fi MAC (private Wi-Fi address) it is an error, because that MAC – and with it the address – is usually random. A locally administered Ethernet MAC is fine (QEMU's `52:54:00:…` is one).

**IPv4 – `ipv4.mode`:**

| Mode | Meaning | Rules |
| --- | --- | --- |
| `reserved` | Fixed DHCP lease by MAC (reservation on `dhcpServer`) | `address` and `mac` required; the network needs a `dhcpServer`. MAC not looked up yet: the placeholder `aa:bb:cc:dd:ee:ff` - never passed on (`mac` null in the derived view, not in `reservations`), listed under `pending` |
| `static` | Configured on the device itself | `address` required; outside `dhcpPool` |
| `dhcp` | Dynamic | no `address` |

Every `address` lies inside the network's `ipv4` prefix, is neither network nor broadcast address (except /31, /32) and occurs once per network. A network without `ipv4` cannot take addresses.

**IPv6** is in here only as link-local and as a fixed prefix per network: DHCPv6 reservations hang on the DUID, not the MAC, and an ISP prefix (SLAAC) changes.

## SSH host keys { #ssh-host-keys }

`sshHostKeys` holds a device's public host keys – for managed and unmanaged devices alike – as `"<type> <base64>"` without the comment: `ssh-ed25519`, `ecdsa-sha2-nistp256/384/521` or `ssh-rsa`. One ed25519 key is enough; others only when the device has no ed25519 (Dropbear, KVMs). Checked: the format, that the key data matches its type (the base64 starts with the encoded type name), and that no key occurs twice – a cloned VM that kept its host key would show up that way.

Where they go:

| Consumer | How |
| --- | --- |
| Every NixOS host and zorlock | `programs.ssh.knownHosts` from `lib.inventory.knownHosts` (in `flake.nix`, the module `inventoryKnownHosts` in every host's list). Deploys and ursalia's unattended push to cuckoosegg need no trust-on-first-use |
| gusto (workstation) | `programs.ssh.knownHosts` like every host – `/etc/ssh/ssh_known_hosts` after the next `just mac-switch` |
| A workstation outside this repo | `just known-hosts` writes `~/.ssh/known_hosts.nixlab`; ssh reads it with `UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts.nixlab` under `Host *` in `~/.ssh/config` |
| `.sops.yaml` | `checks.inventory-sops`: for every managed host, `ssh-to-age` of its ed25519 key must give the age recipient `&<host>` in `.sops.yaml`. Catches a host key that changed (reinstall, rotation) without `sops updatekeys`, and a mistyped key. Hosts without a key yet are skipped |

Names per key: the host's id, for managed hosts `<host>.peer.homelab.example` (the mesh name), and every fixed IPv4 address of its interfaces (`static`/`reserved`). One entry per key, named `<host>` or `<host>-<n>` with several keys.

## Collecting from the devices

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

## Relations

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

## Disk unlock

```json
"unlock": { "methods": ["tpm", "nbde"], "threshold": 1, "tang": ["nas"], "fallback": "remote-ssh" }
```

All fields with type, default and meaning: [Inventory schema → hosts](inventory-schema.md#hosts).

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

## Validation

`nix flake check` (or just the inventory part: `just inventory-test`) validates in three stages. Each stage only runs when the one before found nothing, so a typo does not turn into twenty follow-up errors. Every error names the path:

**1. Structure** – top level first, on its own, then every entry:

- only `$schema` and the eight sections at the top, all of them present
- valid ids and interface names, no unknown fields (catches typos), required fields present
- types, enums, minimums/maximums, formats (MAC, IPv4 address and prefix, IPv6 prefix, link-local, SSH key), no duplicates in lists
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
- interfaces: network at the host's site; `ipv4` needs a network, `address` according to the mode, inside the prefix, not network/broadcast, static outside the pool, unique per network; `reserved` needs `mac` and a `dhcpServer`; MAC unique and not multicast; `eui64` needs a MAC and no private Wi-Fi MAC
- networks: prefix without host bits; pool inside the prefix, start ≤ end, only with `ipv4` and `dhcpServer`; `dhcpServer` at the site and with an interface in the network; VLAN id unique per site
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

## Derived view

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
| `networks.<id>` | `interfaces` – every interface in it (`host`, `interface`, `mac`, `address`, `mode`); `reservations` – what `dhcpServer` has to hand out by MAC (`host`, `interface`, `mac`, `address`), sorted by address |

Besides `inventory`: `lib.inventory.knownHosts` (the `programs.ssh.knownHosts` value) and `lib.inventory.knownHostsFile` (the same as known_hosts text).

Optional fields are always present in the derived view: defaults filled in (`criticality`, `availability`, `unlock.threshold`), otherwise `null` or `[]`. A consumer never has to write `or`.

If the inventory is invalid, `inventory` throws with **all** errors at once; `lib.inventory.errors` is the list itself (empty when valid).

## Software view { #software }

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

## Examples

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

## Tests

`tests/inventory.nix` holds a complete, fictional inventory (the examples above) and 94 cases. Each case changes exactly one thing and states the expected errors – exact wording and order – or, for valid variants, values of the derived view. A case also fails if a broken inventory does not make `.inventory` throw.

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
| networks | Prefix format, VLAN range and duplicate per site (same id at another site allowed), host bits, pool outside/backwards/without server, DHCP server without interface or at another site; derived reservations |
| services | Neither/both of `hosts` and `provider`, empty `hosts`, `package` with `version`/without hosts/on an unmanaged host, critical service on an intermittent host (a `lab` one allowed), self references, `uses` doubling `dependsOn`, weaker hard dependency, cycles over `dependsOn` and `via`, endpoint rules and duplicate names, domain format, every backup rule; derived dependencies, upstream hosts, off-host backups, `gaps` |
| providers, contracts | Contract with the wrong provider on a host, line and service, on a line without provider, on a service on hosts; `dueMonth`, `renews` before `since`, amount not in whole cents, date format; unused and unknown provider; derived totals per currency and per month, `pending` for a missing cost |

```
just inventory-test
```

builds `checks.<system>.inventory` (the real file is valid), `inventory-tests` (all cases pass), `inventory-schema` (schema fresh), `inventory-diagram` (the [schema diagram](inventory-schema.md#all-fields-at-a-glance) fresh) and `inventory-sops` (host keys ↔ `.sops.yaml`). On failure the message lists each failing case with "want" and "got".

**A new rule** gets a case in the same commit: change one thing in `base` with `set`/`del`, paste the exact message. **Changed wording** of an error fails the tests – adjust case and this page together.

## Workflows

| What | Steps |
| --- | --- |
| New host / device | Add an entry to `inventory.json` (for a flake host `"managed": true` – otherwise `nix flake check` fails anyway), `just inventory-collect`, `network`/`ipv4` by hand, `just inventory-test` |
| Host key changed (reinstall) | `just inventory-collect --force <host>`, `.sops.yaml` + `sops updatekeys` (see [Rotate keys](../how-to/key-rotation.md)), deploy, `just known-hosts` |
| New DHCP reservation | Interface with `mac`, `network`, `ipv4.mode: reserved` + `address`; the list for the router: `networks.<id>.reservations` in `just inventory` |
| Fill in a line's details | Fields in `uplinks.<id>`, nothing else to do |
| New service | Entry in `services` with `hosts` (and `package` on a managed host) or `provider`, `endpoints`, `dependsOn`/`uses`, `data`, `backup`; `just inventory-test` – a missing off-host backup shows up under "worth a look" |
| New contract | Entry in `contracts`, the id into `contracts` of the host, line or service it pays for; customer/contract number into `inventory.secrets.yaml` (`sops inventory.secrets.yaml`) |
| New field or kind | `spec` in `inventory.nix`, then `just inventory-schema` and `just inventory-diagram`, a test case in `tests/inventory.nix`, this page (de/en); `docs/inventory-example.json` if the [schema page](inventory-schema.md)'s example should show it |
| Look at it | `just inventory` |
