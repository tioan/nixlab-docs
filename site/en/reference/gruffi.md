# gruffi – the home router

gruffi is the home network's router: a GL.iNet Flint 4 (GL-BE14000), running OpenWrt main instead of the GL firmware since 2026-11-02. It terminates the PPPoE line, routes and filters between the five home networks, hands out DHCP and router advertisements and is the switch for the servers. This page is its reference – what runs on it, where the image comes from, which port does what, what was measured and what is known to be broken. The network plan (zones, firewall matrix, WLANs, radio plan) is `docs/plan-heimnetze.md`; setting it up from scratch is in the private guide *Setting up gruffi*.

## Overview

| | |
| --- | --- |
| Hardware | GL.iNet Flint 4 (GL-BE14000): MT7988A (4 × Cortex-A73), 2 GiB RAM, 64 GB eMMC; MT7996/MT7990 Wi-Fi module on PCIe (Wi-Fi 7, 2.4/5/6 GHz) |
| System | OpenWrt main, built from PR [openwrt/openwrt#26215](https://github.com/openwrt/openwrt/pull/26215) (GL-BE14000 support, John Crispin) plus the netdev-name fix by Nilanka de Silva ([JiaY-shi/openwrt@89988effb0](https://github.com/JiaY-shi/openwrt/commit/89988effb028fce82ab943db5fd11b5a65a118a8)) and a kernel with `IPV6_ROUTER_PREF`/`IPV6_ROUTE_INFO` (Thread, `docs/thread-probe.md`) |
| Bootloader | GL's own U-Boot (the PR's "stock U-Boot" variant); its web recovery is the way back |
| Configuration | everything at first boot from `/etc/uci-defaults/90-gruffi`, generated from `inventory.json` by `openwrt/gruffi/uci.nix`; no hand-made configuration |
| Built | on ursalia in the container `openwrt-gruffi` (`openwrt/gruffi/build.sh`), checked with `openwrt/gruffi/dryrun.sh` |
| Installed | `sysupgrade -n` with the sysupgrade image (fresh, without the old configuration) |
| Access | OpenSSH, gusto's key only (`hosts/gusto/ssh/gruffi.homelab.example.pub`), from the mgmt network, from gusto in the private network and over the mesh |
| WLAN | from gruffi itself since 2026-11-07, 2.4 and 5 GHz, no 6 GHz. ap-og (EAP660 HD, stock) on lan8 is cold standby: injector unplugged, plug it in to switch over |
| Display | stays dark: with the stock U-Boot the panel driver has no panel the bootloader switched on to take over |

## Files

| File | Content |
| --- | --- |
| `openwrt/gruffi/uci.nix` | Everything set at first boot: port roles, bridge and VLANs, networks, DHCP with all reservations, DNS, firewall zones and rules, PPPoE, SQM, WLANs, Thread sysctl, avahi; plus the expectations for the dry run (`dryrun`). Derives addresses, pools, prefixes and reservations from the inventory |
| `openwrt/gruffi/gen-files.sh` | Generates the image's `files/` from `uci.nix` and fills in the secrets (WLAN keys, root password hash from `secrets.yaml`, sops, workstation key from 1Password) |
| `openwrt/gruffi/secrets.yaml` | sops: WLAN keys, root password and its hash |
| `openwrt/gruffi/config.seed` | Package selection and options of the build |
| `openwrt/gruffi/inner.sh` | Runs in the build container: fetch the PR head, cherry-pick the fix, set kernel options, build, write `BUILDINFO` |
| `openwrt/gruffi/build.sh`, `Containerfile` | Starts the build on ursalia (Debian container, incremental, state in `/var/lib/openwrt-build/gruffi`) |
| `openwrt/gruffi/node-exporter.init`, `node-exporter-modem.uc` | The node exporter's own service and the modem collector (see [Metrics](#metrics)) |
| `openwrt/gruffi/dryrun.sh` | Dry run with real clients (see [Changes](#changes)) |

## Ports and switches

Three paths lead into the SoC: the built-in 1G switch (MT7988, gmac0), the 2.5G switch YT9224 with the YT8824 quad PHY and the SFP+ cage (gmac1, fixed 10G USXGMII link, its own DSA tree) and the 10G copper port (RTL8261D, gmac2). The names follow the case labels.

| Port | Switch | Role (`uci.nix`) |
| --- | --- | --- |
| `wan` (WAN/LAN1, 10GBASE-T) | RTL8261D | mgmt untagged – the admin cable |
| `lan2` | YT9224/YT8824 | labelled WAN/LAN2, to the modem's Link port. Uplink: PPPoE on VLAN 7 (`lan2.7`); untagged the web interface of fiber modem 2 (gruffi `203.0.113.202`, modem `203.0.113.201`, zone `modem`, from mgmt only) |
| `lan3` | YT9224/YT8824 | server untagged (ursalia) |
| `lan4` | YT9224/YT8824 | server untagged (zorlock, after its move to the Mac mini M6) |
| `lan5` | YT9224/YT8824 | trunk: private untagged, the others tagged (Flint 2) |
| `lan6` | MT7988 | server untagged (SLZB-MR3U); with the PoE switch (#121) a trunk: mgmt untagged, the others tagged, behind it SLZB-MR3U, Home Assistant, Hue Bridge |
| `lan7` | MT7988 | server untagged (Home Assistant); with the PoE switch (#121) free, not in the bridge |
| `lan8` | MT7988 | trunk: private untagged, mgmt/IoT/guest/backhaul tagged (Omada EAP660 HD on stock as cold standby, #96). With OpenWrt: mgmt untagged, private tagged (`docs/install-ap-og.md`). `sw-og-flur` `lan7` is ready for it |
| `lan9` | MT7988 | IoT untagged (Hue Bridge); with the PoE switch (#121) free, not in the bridge |
| `sfp` (SFP+) | YT9224 | trunk: all tagged |
| `vxcudy` | – | VXLAN trunk to the WLAN bridge over `homelab-bh` in its own backhaul network (never inside a VXLAN trunk): mgmt/IoT tagged. `vxflint` (mgmt/private/IoT/guest) only exists with `enabled = true` (`openwrt/bridges.nix`, `docs/install-bridges.md`) |

All LAN ports are in one VLAN-filtering bridge `br-lan`; every network is a VLAN on it (`br-lan.<VLAN>`), VLAN IDs and prefixes come from the inventory. STP is on with gruffi as root bridge (priority 4096, forward delay 4 s): a freshly plugged port forwards after about 8 s.

## Networks and services

- **DHCP and RA** in all five networks (dnsmasq, odhcpd); `dhcpv4=server` has to be set – dnsmasq on main leaves DHCPv4 off otherwise. The reservations are all inventory interfaces with `ipv4.mode = "reserved"`.
- **DNS:** mgmt gets gruffi itself, the other networks AdGuard Home on ursalia (IPv4 and its ULA ::53). The firewall allows both addresses; gruffi's dnsmasq answers `.lan` and the services' LAN names, AdGuard forwards them to it.
- **Firewall** (fw4): zones = networks; forwardings and single rules are in `uci.nix` and follow the matrix in `docs/plan-heimnetze.md`. mgmt may reach the WAN (decision 5a on flash day).
- **PPPoE** on `lan2.7`, IPv6 by DHCPv6-PD (/56); SQM (cake) on `pppoe-wan`.
- **Offload:** software and hardware flow offloading on, `bridger` for bridge flows.

## Metrics

`prometheus-node-exporter-ucode` listens on `198.51.100.1:9100`, only ursalia gets there through the firewall rule `r_node_exporter`; vmagent on ursalia scrapes it as job `gruffi` (dashboard "Homelab / Fiber modem"). Since 2026-11-07, nixlab#178.

- **Own service:** `/etc/init.d/node-exporter`, adapted from the [package's init script by Andre Heider](https://github.com/openwrt/packages/blob/d4a4de8309c2462d29a48597c711116360a0e8fa/utils/prometheus-node-exporter-ucode/files/init). The package's service stays disabled, so an `apk upgrade` overwrites nothing.
- **Narrow jail:** own user `node-exporter` (UID 9100) instead of root, no `ubus`, only its own file from `/etc/config`. `/etc/config/wireless` is world-readable and holds the WLAN keys, and `network.wireless status` returns them too.
- **Way out:** `/usr/share/nftables.d/chain-pre/output/90-node-exporter.nft` allows this user new connections only to `203.0.113.201:80`; everything else is rejected and counted.
- **Modem collector:** `modem.uc` reads `/ONT/client/data/Status.json` (no login, needs browser-like headers, 3 s timeout) and takes only fields from a fixed list. The serial number is in the response as well and is never read. `link_status` is dropped: it reads 0 while `lan2` links at 2500 Mbit/s. The series carry `host="glasfasermodem-2"`, which is why the job needs `honor_labels`.
- **No flash needed:** packages installed with `apk add`, files with `scp`. `config.seed` and `gen-files.sh` take everything along in the next build; `sysupgrade -n` removes live-installed packages. The dry run does not cover the exporter.

## Changes

Nothing on the device is changed by hand for good – changes go into `uci.nix` (or the inventory), then:

1. `nix develop -c openwrt/gruffi/build.sh` – build on ursalia (needs 1Password for sops).
2. `nix develop -c openwrt/gruffi/dryrun.sh` – runs the last build's `90-gruffi` in an OpenWrt x86 container with veth ports named like gruffi's and checks per network: DHCPv4 lease (pool, router, DNS), the first reservation, the RA (ULA prefix, DNS) with `rdisc6`, plus `fw4 check` and the number of DHCP ranges. With `--no-dhcpv4` it has to fail.
3. Image to gusto and gruffi, compare SHA-256, `sysupgrade -T`, then `sysupgrade -n`.

For changes on the running device (test rules, reservations until the next build): set uci, `uci commit`, then `fw4 reload` or `/etc/init.d/dnsmasq restart` where that is enough. `/etc/init.d/network reload` is allowed (`wifi up`, `wifi down` and `wifi reload` trigger it too), but check afterwards that `lan2` receives, for example with a ping to the modem. On 2026-11-02 `lan2` stopped receiving after several reloads until a reboot; on 2026-11-06 that did not recur in 11 reloads on a newer image (nixlab#94). Changes to `lan2.7` or `wan` and to ports with a device attached are untested there, so prefer a reboot for those.

## Measured performance

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

## Known issues

- **Wi-Fi module can go missing** (nixlab#93): from 2026-11-02 to 2026-11-06 both PCIe controllers got no link at boot (`PCIe link down, current LTSSM state: detect.quiet`, probe -110), reboots included. The first 30 s power cut cleared it; since then the module has come up on every boot, warm and after 2 s without power too. The trigger is unknown. If it returns: save `dmesg`, then 30 s without power. Without the module the power strip is unreachable, so press its button on site and plug in ap-og. Since 2026-11-07 the alert GruffiWifiMissing reports it, and Home Assistant also sends a push when the strip is out of reach (nixlab#191).
- **`network reload` with a check afterwards** (nixlab#94, see [Changes](#changes)).
- **lan4/lan5** received nothing on older images – fixed in the PR by the MDI swap patch (`967-54`); from head `e3d333fa67` on, `ethtool -S lanN` also shows the YT9224 hardware counters (`967-55`).
- **First boot after a power cut:** PPPoE often needs one or two PADO timeouts (35 s each) because the old session still hangs at the ISP; after a warm reboot PPPoE is up at once.

## Power watchdog

`gruffi-power-watchdog` on ursalia notices that gruffi is dead, and reaches the strip that powers it over Bluetooth LE, because ursalia has no network path to `shelly-strip-og-flur` without gruffi. **It is a dry run: it logs when it would power-cycle gruffi and cannot switch.** Code: `pkgs/gruffi-power-watchdog`, `hosts/ursalia/gruffi-power-watchdog.nix`; state and next steps in nixlab#177.

ursalia (`lan3`), zorlock (`lan4`) and homeassistant (`lan7`) are wired directly to gruffi, so a cable link or another LAN device says nothing about gruffi. The second sign is the strip's own Wi-Fi state, read over BLE, since the strip joins gruffi's WLAN:

| gruffi answers ping in the LAN | Strip's Wi-Fi | Meaning | Decision |
| --- | --- | --- | --- |
| no, for 10 min | disconnected, for 10 min | gruffi off or dead | `would-cycle` |
| no | connected | cable, NIC, or gruffi half alive | `lan-down-wifi-up`, nothing |
| yes | any | gruffi is alive | `healthy`, nothing |

Brakes: nothing in the first 10 minutes after ursalia boots, at most one action in 30 minutes and 3 in all, then it stops until `gruffi-power-watchdog reset`. BLE without an answer never counts as evidence. A BLE read once a day keeps the path checked (alert `GruffiWatchdogBleStale`).

**Before planned work on gruffi** (sysupgrade, a flash, long maintenance), in a root shell on ursalia:

```bash
gruffi-power-watchdog hold 2h "sysupgrade"
```

```bash
gruffi-power-watchdog release
```

A hold lasts at most 24 hours and ends by itself. `gruffi-power-watchdog status` shows the hold and the count.

**Pairing the strip**, once, while gruffi works. Until then every BLE read fails and the decision stays `lan-down-witness-unknown`. Enable BLE RPC, open pairing, then on ursalia pair with `bluetoothctl` (`agent NoInputNoOutput`, `default-agent`, `scan le`, `pair D8:85:AC:EC:D0:46`). The BLE address is the strip's Wi-Fi MAC plus 2.

```bash
ssh gruffi "wget -qO- 'http://203.0.113.19/rpc/BLE.SetConfig?config=%7B%22rpc%22%3A%7B%22enable%22%3Atrue%7D%7D'"
```

```bash
ssh gruffi "wget -qO- 'http://203.0.113.19/rpc/BLE.StartPairing?timeout=180'"
```

BLE needs the kernel's supervision timeout raised: with the default 420 ms, 6 of 10 connections dropped at -84 dBm with `Connection Timeout (0x08)`, with 6 s none did (`ConnectionSupervisionTimeout=600`). BlueZ reports such a drop as ATT error `0x0e`; the strip does not send it. The strip's RPC runs over GATT as described in Mongoose OS' [rpc-gatts](https://github.com/mongoose-os-libs/rpc-gatts/blob/fa706f66f4bf3632c042248dbf0bf98b5dd60f73/README.md) (Cesanta) and Shelly's [BLE documentation](https://shelly-api-docs.shelly.cloud/gen2/ComponentsAndServices/BLE/).

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| SSH to gruffi: "Permission denied (publickey)" with "communication with agent failed" | The 1Password SSH agent wants the key `gruffi.homelab.example` approved (again) – confirm the dialog in 1Password |
| "Host key verification failed" after an upgrade | `sysupgrade -n` creates new host keys; compare the new fingerprint with the one from the upgrade check and put it into the inventory (`hosts.gruffi.sshHostKeys`) |
| "No route to host" to LAN addresses from the Claude app's terminal pane | The app lacks the macOS "Local Network" permission; Terminal.app works |
| From gusto on a cable into the server network "Connection refused" although the peer runs | `netbird down` removes the server network's route including the direct route over the cable; traffic then goes via gruffi, which rejects forwards within one zone. After `netbird down`, switch the network interface off and on once |
| A USB adapter only does ~300 Mbit/s | It is attached at USB 2.0 (`ioreg -r -c IOUSBHostDevice -l -w0`, `UsbLinkSpeed` = 480000000) – another cable or straight into the Mac |
| No DHCP in a network | `grep dhcp-range /var/etc/dnsmasq.conf.*` – missing ranges mean `dhcpv4=server` is missing |
