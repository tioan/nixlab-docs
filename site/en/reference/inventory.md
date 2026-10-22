# Inventory

`inventory.json` lists every machine of the lab, whether this flake configures it or not: what kind of device it is (vendor, model, serial), where it stands, how that place reaches the internet, what it runs on or is built into, where its power comes from, how its disk gets unlocked after a reboot, its networks, interfaces and addresses, and its SSH host keys. These are the facts a NixOS config does not hold. Today the host keys are used: every host's known_hosts comes from here, and `nix flake check` ties them to the age keys in `.sops.yaml`. Later the rest is meant for grouping in the topology and for alert dependencies (an uplink is down, so don't page for every host behind it).

| File | Role |
| --- | --- |
| `inventory.json` | The data. JSON, so Nix (`builtins.fromJSON`) and OpenTofu (`jsondecode`) can both read it without help. |
| `inventory.nix` | Format (`spec`), validation, derived view, JSON Schema generator. Exposed as `lib.inventory` in `flake.nix`. |
| `inventory.schema.json` | JSON Schema for the editor (completion, hover help, inline errors). Generated, never edited. |
| `tests/inventory.nix` | Tests for the validator: a complete example inventory and one case per rule. |
| `flake.nix` | `lib.inventory`, the checks, and `programs.ssh.knownHosts` for every host (NixOS and nix-darwin). |

Rule of thumb for what goes in: **only what cannot be derived from a config.** OS, architecture, CPU/RAM, mesh address, exporters and backup targets stay out; `topology.nix` reads those from `nixosConfigurations`. Every relation is stored in **one direction only**; the reverse is derived, so the two cannot disagree.

## Structure

Five sections, each an object of entries keyed by id. Ids are lower-case letters, digits and dashes (usable unchanged as Graphviz node or label values).

```
owners   ◄──────── hosts.owner
uplinks  ◄──────── sites.uplinks[]
sites    ◄──────── hosts.site, networks.site
networks ◄──────── hosts.interfaces.<name>.network
hosts    ◄──────── hosts.runsOn / inside / power / manages[] / unlock.tang[], networks.dhcpServer
```

A `"$schema": "./inventory.schema.json"` key at the top is allowed and ignored; it tells the editor where the schema is.

### owners

Who administers a device: it decides whom to call and what may be changed.

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `name` | string | required | Display name |
| `contact` | string | | Who to talk to when this owner's devices are affected |
| `note` | string | | Free text |

### uplinks

An internet line. Several sites may share one (rarely), one site may have several (primary and backup).

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `isp` | string | | Provider; for a data centre the hoster |
| `asn` | integer ≥ 1 | | AS number of the provider's network, without "AS" |
| `medium` | `fiber` `dsl` `cable` `lte` `satellite` `datacenter` | | Kind of line |
| `bandwidth` | `{ "down": int, "up": int }` | | Booked bandwidth in Mbit/s, both values required |
| `ipv4` | `public` `cgnat` `none` | | What the line gives for IPv4 |
| `ipv4Static` | boolean | | Fixed public IPv4 address (only meaningful with `public`) |
| `ipv6` | boolean | | Native IPv6 |
| `ipv6PrefixLength` | integer 1–128 | | Size of the delegated IPv6 prefix (56 for a /56); only with `ipv6` |
| `ipv6Static` | boolean | | Fixed IPv6 prefix; only with `ipv6` |
| `note` | string | | Free text |

All fields are optional, so a line can be entered before its details are known.

### sites

A place where devices stand.

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `city` | string | required | City |
| `kind` | `residential` `hackerspace` `datacenter` | required | Kind of place |
| `provider` | string | | Who runs the place (hoster, club); empty for a home |
| `uplinks` | list of uplink ids | required, ≥ 1 | Internet lines, **primary first**, backups after it |
| `note` | string | | Free text |

### hosts

Every device with an address that matters: servers, VMs, routers, APs, KVMs, PDUs, appliances.

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `kind` | see [kinds](#kinds) | required | What the device is |
| `vendor` | string | | Manufacturer (Lenovo, Apple, GL.iNet). Not for `vm`/`container` |
| `model` | string | | Model without the vendor (ThinkCentre M720q), or for a VM the provider's product/plan name |
| `productId` | string | | The vendor's id for drivers and firmware: Lenovo machine type (`10T7…`), Apple model identifier (`Mac16,10`). Not for `vm`/`container` |
| `serial` | string | | Serial number, unique lab-wide. Not for `vm`/`container` |
| `site` | site id | required\* | Where it is. \*Optional with `runsOn` or `inside`: then it is inherited |
| `owner` | owner id | required | Who administers it |
| `managed` | boolean | required | Configured by this flake – must match `flake.nix` |
| `criticality` | `core` `service` `lab` | default `service` | `core`: the lab stops working without it; `service`: a service is down; `lab`: nothing depends on it |
| `availability` | `always-on` `intermittent` | default `always-on` | `intermittent`: offline is normal (laptop), not an incident |
| `unlock` | object, see [Disk unlock](#disk-unlock) | | Leave it out for an unencrypted disk |
| `runsOn` | host id | | Only `vm`/`container`: the machine it runs on |
| `inside` | host id | | Physically built into another device |
| `power` | host id | | Power source: PDU/UPS, PoE switch, or the host a card sits in |
| `manages` | list of host ids | | Only `kvm`: machines it gives out-of-band access to |
| `sshHostKeys` | list of strings | | SSH host public keys, `"<type> <base64>"` without comment, see [SSH host keys](#ssh-host-keys) |
| `interfaces` | object: name → interface | | Network interfaces, see [Interfaces](#interfaces) |
| `note` | string | | Free text |

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
| `appliance` | Anything else with an address: Apple TV, printer, … |

Whether a host is virtual follows from `kind` (`vm`, `container`) – not from `runsOn`. A rented VM is a `vm` without `runsOn`: the provider's hypervisor is not in the inventory.

### networks

A layer-2 network with its IPv4 prefix: the home LAN, a VLAN in the hackerspace.

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `name` | string | required | Display name (the id is the technical key) |
| `site` | site id | required | Where the network is |
| `vlan` | integer 1–4094 | | 802.1Q VLAN id; leave out for an untagged network. Unique per site – another site may use the same id |
| `ipv4` | prefix, e.g. `192.0.2.0/24` | | Without host bits |
| `ipv6` | prefix, e.g. `2001:db8:1::/64` | | Only when it is fixed (ULA, static GUA) – not an ISP prefix that changes |
| `dhcpServer` | host id | | Serves DHCP for IPv4; must be at the site and have an interface in this network |
| `dhcpPool` | `{ "start": ip, "end": ip }` | | Dynamic range; inside `ipv4`, start ≤ end. Needs `ipv4` and `dhcpServer` |
| `note` | string | | Free text |

A network without any interface is allowed – it can be entered before its devices are.

## Interfaces { #interfaces }

`hosts.<id>.interfaces` maps interface names to their data. The name is what the OS calls it (`eno1`, `wlp2s0f0`, `en0`); for an appliance any label (`lan`, `wan`). A VLAN interface on a trunk (`eno1.20`) is an entry of its own; its VLAN id comes from its network.

```json
"interfaces": {
  "eno1":    { "mac": "52:54:00:12:34:56", "medium": "ethernet", "linkLocal": "eui64",
               "network": "lan", "ipv4": { "mode": "reserved", "address": "192.0.2.10" } },
  "eno1.20": { "network": "iot", "linkLocal": "fe80::1234", "ipv4": { "mode": "dhcp" } }
}
```

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `mac` | `aa:bb:cc:dd:ee:ff`, lower case | | Hardware address. Unique lab-wide, no multicast address |
| `medium` | `ethernet` `wifi` | | Physical medium |
| `linkLocal` | `eui64` `stable-privacy` `random` or an `fe80::` address | | How the IPv6 link-local address is formed |
| `network` | network id | | Network it is in; at the same site as the host |
| `ipv4` | `{ "mode": …, "address": … }` | | IPv4 addressing, needs `network` |
| `note` | string | | Free text |

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

| Field | Type | | Meaning |
| --- | --- | --- | --- |
| `methods` | list of `tpm`, `nbde` | required (may be empty) | Automatic methods. Empty: only a human can unlock |
| `threshold` | integer ≥ 1 | default 1 | How many methods must succeed – the Clevis `sss` threshold. 1 = any, 2 = TPM **and** Tang |
| `tang` | list of host ids | required with `nbde` | Tang servers; any one of them is enough |
| `fallback` | `remote-ssh` `console` | | What a human does when the methods fail: SSH (initrd SSH, FileVault over SSH) or console/KVM |

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

- only `$schema`, `owners`, `uplinks`, `sites`, `networks`, `hosts` at the top, all five sections present
- valid ids and interface names, no unknown fields (catches typos), required fields present
- types, enums, minimums/maximums, formats (MAC, IPv4 address and prefix, IPv6 prefix, link-local, SSH key), no duplicates in lists
- references point at an existing entry of the right section

```
hosts.vps.critcality: unknown field (known: availability, criticality, inside, interfaces, kind, managed, manages, model, note, owner, power, productId, runsOn, serial, site, sshHostKeys, unlock, vendor)
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

```
hosts.app.runsOn: a vm cannot run on nas (kind nas; allowed: hypervisor)
hosts: runsOn/inside/power form a cycle through pve, ups1
hosts.laptop.managed: true, but flake.nix has no configuration of that name
hosts.router.interfaces.lan.ipv4.address: 192.0.2.150 is static but inside the DHCP pool of network lan
networks.lan.vlan: 20 is also used by networks.iot at site home
hosts.router.sshHostKeys[0]: same key as hosts.nas.sshHostKeys[0] - a cloned machine that kept its host key?
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
| `hosts.<id>` | `site` (effective, inherited along `runsOn`/`inside`), `virtual`, `uplinks` (of its site, primary first), `guests`, `contains`, `powers`, `managedBy`, `tangClients`, `upstream` (transitive, nearest first), `unattendedBoot` |
| `hosts.<id>.interfaces.<name>` | `name`, `vlan` (from its network), `ipv6LinkLocal` (computed for `eui64`, as given for a fixed address, otherwise `null`) |
| `pending` | every placeholder MAC still to replace; `just inventory-test` prints the list |
| `networks.<id>` | `interfaces` – every interface in it (`host`, `interface`, `mac`, `address`, `mode`); `reservations` – what `dhcpServer` has to hand out by MAC (`host`, `interface`, `mac`, `address`), sorted by address |

Besides `inventory`: `lib.inventory.knownHosts` (the `programs.ssh.knownHosts` value) and `lib.inventory.knownHostsFile` (the same as known_hosts text).

Optional fields are always present in the derived view: defaults filled in (`criticality`, `availability`, `unlock.threshold`), otherwise `null` or `[]`. A consumer never has to write `or`.

If the inventory is invalid, `inventory` throws with **all** errors at once; `lib.inventory.errors` is the list itself (empty when valid).

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
  "fiber-home": { "isp": "Example ISP", "asn": 64496, "medium": "fiber",
                  "bandwidth": { "down": 1000, "up": 500 }, "ipv4": "cgnat", "ipv6": true },
  "lte-backup": { "medium": "lte" }
},
"sites": {
  "home": { "city": "Exampletown", "kind": "residential", "uplinks": ["fiber-home", "lte-backup"] }
}
```

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

`tests/inventory.nix` holds a complete, fictional inventory (the examples above) and 72 cases. Each case changes exactly one thing and states the expected errors – exact wording and order – or, for valid variants, values of the derived view. A case also fails if a broken inventory does not make `.inventory` throw.

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

```
just inventory-test
```

builds `checks.<system>.inventory` (the real file is valid), `inventory-tests` (all cases pass), `inventory-schema` (schema fresh) and `inventory-sops` (host keys ↔ `.sops.yaml`). On failure the message lists each failing case with "want" and "got".

**A new rule** gets a case in the same commit: change one thing in `base` with `set`/`del`, paste the exact message. **Changed wording** of an error fails the tests – adjust case and this page together.

## Workflows

| What | Steps |
| --- | --- |
| New host / device | Add an entry to `inventory.json` (for a flake host `"managed": true` – otherwise `nix flake check` fails anyway), `just inventory-collect`, `network`/`ipv4` by hand, `just inventory-test` |
| Host key changed (reinstall) | `just inventory-collect --force <host>`, `.sops.yaml` + `sops updatekeys` (see [Rotate keys](../how-to/key-rotation.md)), deploy, `just known-hosts` |
| New DHCP reservation | Interface with `mac`, `network`, `ipv4.mode: reserved` + `address`; the list for the router: `networks.<id>.reservations` in `just inventory` |
| Fill in a line's details | Fields in `uplinks.<id>`, nothing else to do |
| New field or kind | `spec` in `inventory.nix`, then `just inventory-schema`, a test case in `tests/inventory.nix`, this page (de/en) |
| Look at it | `just inventory` |
