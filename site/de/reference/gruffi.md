# gruffi – der Heimrouter

gruffi ist der Router des Heimnetzes: ein GL.iNet Flint 4 (GL-BE14000), seit dem 2026-11-02 mit OpenWrt main statt der GL-Firmware. Er terminiert die PPPoE-Leitung, routet und filtert zwischen den fünf Heimnetzen, verteilt DHCP und Router Advertisements und ist der Switch für die Server. Diese Seite ist die Referenz dafür – was auf ihm läuft, woher das Image kommt, welcher Port wofür ist, was gemessen wurde und was bekannt kaputt ist. Den Plan der Netze (Zonen, Firewall-Matrix, WLANs, Funkplan) beschreibt `docs/plan-heimnetze.md`; die Einrichtung von Grund auf steht in der privaten Anleitung *gruffi aufsetzen*.

## Überblick

| | |
| --- | --- |
| Hardware | GL.iNet Flint 4 (GL-BE14000): MT7988A (4 × Cortex-A73), 2 GiB RAM, 64 GB eMMC; WLAN-Modul MT7996/MT7990 an PCIe (Wi-Fi 7, 2,4/5/6 GHz) |
| System | OpenWrt main, gebaut aus dem PR [openwrt/openwrt#26215](https://github.com/openwrt/openwrt/pull/26215) (GL-BE14000-Unterstützung, John Crispin) plus dem netdev-name-Fix von Nilanka de Silva ([JiaY-shi/openwrt@89988effb0](https://github.com/JiaY-shi/openwrt/commit/89988effb028fce82ab943db5fd11b5a65a118a8)) und einem Kernel mit `IPV6_ROUTER_PREF`/`IPV6_ROUTE_INFO` (Thread, `docs/thread-probe.md`) |
| Bootloader | GLs eigenes U-Boot (Variante „stock U-Boot“ des PR); seine Web-Recovery ist der Rückweg |
| Konfiguration | alles beim ersten Boot aus `/etc/uci-defaults/90-gruffi`, erzeugt aus `inventory.json` über `openwrt/gruffi/uci.nix`; keine Konfiguration von Hand |
| Gebaut | auf ursalia im Container `openwrt-gruffi` (`openwrt/gruffi/build.sh`), geprüft mit `openwrt/gruffi/dryrun.sh` |
| Eingespielt | `sysupgrade -n` mit dem sysupgrade-Image (frisch, ohne alte Konfiguration) |
| Zugang | OpenSSH, nur mit gustos Schlüssel (`hosts/gusto/ssh/gruffi.homelab.example.pub`), aus dem mgmt-Netz, von gusto im privaten Netz und über das Mesh |
| WLAN | im Moment von ap-og (EAP660 HD) – an sw-og-flur (lan6), bis zum Umbau (`docs/install-sw-og-flur.md`) direkt an lan8 – die eigenen Radios starten nicht (siehe [Bekannte Probleme](#bekannte-probleme)) |
| Display | bleibt dunkel: mit dem Stock-U-Boot übernimmt der Panel-Treiber kein vom Bootloader eingeschaltetes Panel |

## Dateien

| Datei | Inhalt |
| --- | --- |
| `openwrt/gruffi/uci.nix` | Alles, was beim ersten Boot gesetzt wird: Portrollen, Bridge und VLANs, Netze, DHCP mit allen Reservierungen, DNS, Firewall-Zonen und -Regeln, PPPoE, SQM, WLANs, Thread-sysctl, avahi; dazu die Erwartungen für den Probelauf (`dryrun`). Leitet Adressen, Pools, Präfixe und Reservierungen aus dem Inventory ab |
| `openwrt/gruffi/gen-files.sh` | Erzeugt `files/` fürs Image aus `uci.nix` und setzt die Geheimnisse ein (WLAN-Schlüssel, Root-Passwort-Hash aus `secrets.yaml`, sops, Workstation-Schlüssel aus 1Password) |
| `openwrt/gruffi/secrets.yaml` | sops: WLAN-Schlüssel, Root-Passwort und sein Hash |
| `openwrt/gruffi/config.seed` | Die Paketauswahl und Optionen des Builds |
| `openwrt/gruffi/inner.sh` | Läuft im Build-Container: PR-Head holen, Fix cherry-picken, Kernel-Optionen setzen, bauen, `BUILDINFO` schreiben |
| `openwrt/gruffi/build.sh`, `Containerfile` | Startet den Build auf ursalia (Debian-Container, inkrementell, Zustand in `/var/lib/openwrt-build/gruffi`) |
| `openwrt/gruffi/dryrun.sh` | Probelauf mit echten Clients (siehe [Änderungen](#anderungen)) |

## Ports und Switches

Drei Wege führen in den SoC: der eingebaute 1G-Switch (MT7988, gmac0), der 2,5G-Switch YT9224 mit dem Vierfach-PHY YT8824 und dem SFP+-Käfig (gmac1, fester 10G-USXGMII-Link, eigener DSA-Baum) und der 10G-Kupferport (RTL8261D, gmac2). Die Namen folgen der Gehäusebeschriftung.

| Port | Switch | Rolle (`uci.nix`) |
| --- | --- | --- |
| `wan` (WAN/LAN1, 10GBASE-T) | RTL8261D | mgmt ungetaggt – das Admin-Kabel |
| `lan2` | YT9224/YT8824 | Uplink: PPPoE auf VLAN 7 (`lan2.7`) |
| `lan3` | YT9224/YT8824 | server ungetaggt (ursalia) |
| `lan4` | YT9224/YT8824 | server ungetaggt (zorlock, nach dem Umzug auf den Mac mini M6) |
| `lan5` | YT9224/YT8824 | Trunk: privat ungetaggt, die übrigen getaggt (Flint 2) |
| `lan6` | MT7988 | Trunk: mgmt ungetaggt, die übrigen getaggt (sw-og-flur, PoE-Switch: ap-og, SLZB-MR3U) |
| `lan7` | MT7988 | server ungetaggt (Home Assistant) |
| `lan8` | MT7988 | Trunk: mgmt ungetaggt, privat/IoT/Gast getaggt: Ersatzanschluss für ap-og (EAP660 HD), das an sw-og-flur hängt |
| `lan9` | MT7988 | IoT ungetaggt (Hue Bridge) |
| `sfp` (SFP+) | YT9224 | Trunk: alle getaggt |

Alle LAN-Ports hängen in einer Bridge `br-lan` mit VLAN-Filter; jedes Netz ist ein VLAN darauf (`br-lan.<VLAN>`), die VLAN-IDs und Präfixe kommen aus dem Inventory. STP ist an, gruffi ist Root-Bridge (Priorität 4096, Forward Delay 4 s): ein neu gesteckter Port leitet erst nach etwa 8 s weiter.

## Netze und Dienste

- **DHCP und RA** in allen fünf Netzen (dnsmasq, odhcpd); `dhcpv4=server` muss gesetzt sein – dnsmasq auf main lässt DHCPv4 sonst aus. Die Reservierungen sind alle Inventory-Interfaces mit `ipv4.mode = "reserved"`.
- **DNS:** mgmt bekommt gruffi selbst, die übrigen Netze AdGuard Home auf ursalia (IPv4 und seine ULA ::53). Die Firewall lässt beide Adressen zu; gruffis dnsmasq beantwortet `.lan` und die LAN-Namen der Dienste, AdGuard leitet sie an ihn weiter.
- **Firewall** (fw4): Zonen = Netze; die Weiterleitungen und Einzelregeln stehen in `uci.nix` und folgen der Matrix in `docs/plan-heimnetze.md`. mgmt darf ins WAN (Entscheidung 5a vom Flash-Tag).
- **PPPoE** auf `lan2.7`, IPv6 per DHCPv6-PD (/56); SQM (cake) auf `pppoe-wan`.
- **Offload:** Flow-Offloading in Software und Hardware an, `bridger` für Bridge-Flows.

## Änderungen

Am Gerät wird nichts dauerhaft von Hand geändert – Änderungen gehen in `uci.nix` (oder ins Inventory), dann:

1. `nix develop -c openwrt/gruffi/build.sh` – Build auf ursalia (braucht 1Password für sops).
2. `nix develop -c openwrt/gruffi/dryrun.sh` – führt das `90-gruffi` des letzten Builds in einem OpenWrt-x86-Container mit veth-Ports in gruffis Namen aus und prüft pro Netz: DHCPv4-Lease (Pool, Router, DNS), die erste Reservierung, das RA (ULA-Präfix, DNS) mit `rdisc6`, dazu `fw4 check` und die Zahl der DHCP-Bereiche. Mit `--no-dhcpv4` muss er fehlschlagen.
3. Image nach gusto und gruffi, SHA-256 vergleichen, `sysupgrade -T`, dann `sysupgrade -n`.

Für Eingriffe am laufenden Gerät (Testregeln, Reservierungen bis zum nächsten Build): uci setzen, `uci commit`, dann **nur** `fw4 reload` bzw. `/etc/init.d/dnsmasq restart`. **Kein `/etc/init.d/network reload`** auf diesem Image – nach einigen solcher Reloads mit geänderten Bridge-VLANs empfing `lan2` nichts mehr, bis zum Neustart. Was die Bridge oder die Ports ändert, braucht einen Neustart.

## Gemessene Leistung

Gemessen am 2026-11-03 auf dem Image aus PR-Head `e3d333fa67` (xfr und iperf3, 8 s je Lauf, 1/4/8 Streams):

| Weg | Link | Ergebnis |
| --- | --- | --- |
| lan4 → lan3, geswitcht | 2,5G | 2,35 Gbit/s in beide Richtungen, 0 Retransmits |
| lan5 → lan3, geroutet | 2,5G | 2,31–2,34 Gbit/s |
| wan → lan3, geroutet | 10G | 2,34 Gbit/s (Grenze ist der 2,5G-Partner) |
| sfp → lan3 mit Cisco SFP-H10GB-CU1M= bzw. MikroTik S+RJ10 | 10G | 2,2–2,35 Gbit/s; das S+RJ10 bekommt 1,5 W und wird 48–55 °C warm |
| iperf3 gegen gruffi selbst über wan bzw. sfp | 10G | 9,39 bzw. 9,31 Gbit/s von gruffi weg, 4–4,6 Gbit/s zu gruffi hin (gruffis CPU als Empfänger) |
| zwei 10G-Clients zwischen wan und sfp, ein VLAN (auf sfp getaggt) | 10G | ~2,8 Gbit/s – in Software gebridget (kein Flow in der PPE) |

Die Ports sind damit bis zur Grenze der Partner sauber; die Details stehen in nixlab#94 und im [Bericht im PR](https://github.com/openwrt/openwrt/pull/26215#issuecomment-6609794789).

## Bekannte Probleme

- **WLAN-Radios fehlen** (nixlab#93): beide PCIe-Controller bekommen beim Boot keinen Link (`PCIe link down, current LTSSM state: detect.quiet`, Probe -110), also keine Radios. Die ersten drei Boots nach dem Flash hatten WLAN, seitdem keiner mehr – kalt, warm und nach `sysupgrade -n`. Ob Modul oder Image schuld sind, klärt eine Gegenprobe mit der GL-Firmware. Bis dahin macht ap-og an lan8 das WLAN.
- **Kein `network reload`** (nixlab#94, siehe [Änderungen](#anderungen)).
- **lan4/lan5** empfingen auf älteren Images nichts – behoben im PR durch den MDI-Swap-Patch (`967-54`); ab Head `e3d333fa67` zeigt `ethtool -S lanN` auch die Hardware-Zähler des YT9224 (`967-55`).
- **Erster Boot nach Stromausfall:** PPPoE braucht oft ein bis zwei PADO-Timeouts (je 35 s), weil die alte Sitzung bei der Telekom noch hängt; nach einem Warmstart steht PPPoE sofort.

## Fehlersuche

| Symptom | Ursache und Abhilfe |
| --- | --- |
| SSH zu gruffi: „Permission denied (publickey)“ mit „communication with agent failed“ | Der 1Password-SSH-Agent will den Schlüssel `gruffi.homelab.example` (wieder) freigegeben haben – den Dialog in 1Password bestätigen |
| „Host key verification failed“ nach einem Upgrade | `sysupgrade -n` erzeugt neue Host-Keys; den neuen Fingerabdruck mit dem aus dem Upgrade-Check vergleichen und ins Inventory (`hosts.gruffi.sshHostKeys`) |
| Aus dem Terminal-Bereich der Claude-App „No route to host“ zu Adressen im LAN | Der App fehlt die macOS-Berechtigung „Local Network“; in Terminal.app geht es |
| Von gusto am Kabel ins Server-Netz „Connection refused“, obwohl der Partner läuft | `netbird down` löscht die Route des Server-Netzes samt der direkten Route über das Kabel; der Verkehr geht dann über gruffi, der Weiterleitungen innerhalb einer Zone ablehnt. Nach `netbird down` die Netzwerkschnittstelle einmal aus- und einschalten |
| Ein USB-Adapter schafft nur ~300 Mbit/s | Er hängt mit USB 2.0 an (`ioreg -r -c IOUSBHostDevice -l -w0`, `UsbLinkSpeed` = 480000000) – anderes Kabel oder direkt an den Mac |
| Kein DHCP in einem Netz | `grep dhcp-range /var/etc/dnsmasq.conf.*` – fehlen Bereiche, fehlt `dhcpv4=server` |
