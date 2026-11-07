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
| WLAN | seit dem 2026-11-07 von gruffi selbst, 2,4 und 5 GHz, ohne 6 GHz. ap-og (EAP660 HD, Stock) an lan8 ist Cold Standby: Injektor abgezogen, zum Umschalten einstecken |
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
| `openwrt/gruffi/node-exporter.init`, `node-exporter-modem.uc` | Eigener Dienst für den Node-Exporter und der Modem-Collector (siehe [Metriken](#metriken)) |
| `openwrt/gruffi/dryrun.sh` | Probelauf mit echten Clients (siehe [Änderungen](#anderungen)) |

## Ports und Switches

Drei Wege führen in den SoC: der eingebaute 1G-Switch (MT7988, gmac0), der 2,5G-Switch YT9224 mit dem Vierfach-PHY YT8824 und dem SFP+-Käfig (gmac1, fester 10G-USXGMII-Link, eigener DSA-Baum) und der 10G-Kupferport (RTL8261D, gmac2). Die Namen folgen der Gehäusebeschriftung.

| Port | Switch | Rolle (`uci.nix`) |
| --- | --- | --- |
| `wan` (WAN/LAN1, 10GBASE-T) | RTL8261D | mgmt ungetaggt – das Admin-Kabel |
| `lan2` | YT9224/YT8824 | Gehäuse: WAN/LAN2, an der Link-Buchse des Modems. Uplink: PPPoE auf VLAN 7 (`lan2.7`); ungetaggt das Webinterface des Glasfasermodems 2 (gruffi `203.0.113.202`, Modem `203.0.113.201`, Zone `modem`, nur aus mgmt) |
| `lan3` | YT9224/YT8824 | server ungetaggt (ursalia) |
| `lan4` | YT9224/YT8824 | server ungetaggt (zorlock, nach dem Umzug auf den Mac mini M6) |
| `lan5` | YT9224/YT8824 | Trunk: privat ungetaggt, die übrigen getaggt (Flint 2) |
| `lan6` | MT7988 | server ungetaggt (SLZB-MR3U); mit dem PoE-Switch (#121) Trunk: mgmt ungetaggt, die übrigen getaggt, dahinter SLZB-MR3U, Home Assistant, Hue Bridge |
| `lan7` | MT7988 | server ungetaggt (Home Assistant); mit dem PoE-Switch (#121) frei, nicht in der Bridge |
| `lan8` | MT7988 | Trunk: privat ungetaggt, mgmt/IoT/Gast/Backhaul getaggt (Omada EAP660 HD auf Stock als Cold Standby, #96). Mit OpenWrt: mgmt ungetaggt, privat getaggt (`docs/install-ap-og.md`). `sw-og-flur` `lan7` steht für ihn bereit |
| `lan9` | MT7988 | IoT ungetaggt (Hue Bridge); mit dem PoE-Switch (#121) frei, nicht in der Bridge |
| `sfp` (SFP+) | YT9224 | Trunk: alle getaggt |
| `vxcudy` | – | VXLAN-Trunk zur WLAN-Bridge über `homelab-bh` im eigenen Backhaul-Netz (nie im VXLAN-Trunk): mgmt/IoT getaggt. `vxflint` (mgmt/privat/IoT/Gast) entsteht erst mit `enabled = true` (`openwrt/bridges.nix`, `docs/install-bridges.md`) |

Alle LAN-Ports hängen in einer Bridge `br-lan` mit VLAN-Filter; jedes Netz ist ein VLAN darauf (`br-lan.<VLAN>`), die VLAN-IDs und Präfixe kommen aus dem Inventory. STP ist an, gruffi ist Root-Bridge (Priorität 4096, Forward Delay 4 s): ein neu gesteckter Port leitet erst nach etwa 8 s weiter.

## Netze und Dienste

- **DHCP und RA** in allen fünf Netzen (dnsmasq, odhcpd); `dhcpv4=server` muss gesetzt sein – dnsmasq auf main lässt DHCPv4 sonst aus. Die Reservierungen sind alle Inventory-Interfaces mit `ipv4.mode = "reserved"`.
- **DNS:** mgmt bekommt gruffi selbst, die übrigen Netze AdGuard Home auf ursalia (IPv4 und seine ULA ::53). Die Firewall lässt beide Adressen zu; gruffis dnsmasq beantwortet `.lan` und die LAN-Namen der Dienste, AdGuard leitet sie an ihn weiter.
- **Firewall** (fw4): Zonen = Netze; die Weiterleitungen und Einzelregeln stehen in `uci.nix` und folgen der Matrix in `docs/plan-heimnetze.md`. mgmt darf ins WAN (Entscheidung 5a vom Flash-Tag).
- **PPPoE** auf `lan2.7`, IPv6 per DHCPv6-PD (/56); SQM (cake) auf `pppoe-wan`.
- **Offload:** Flow-Offloading in Software und Hardware an, `bridger` für Bridge-Flows.

## Metriken

`prometheus-node-exporter-ucode` lauscht auf `198.51.100.1:9100`, nur ursalia kommt per Firewall-Regel `r_node_exporter` dorthin; vmagent auf ursalia fragt ihn als Job `gruffi` ab (Dashboard „Homelab / Fiber modem“). Seit 2026-11-07, nixlab#178.

- **Eigener Dienst:** `/etc/init.d/node-exporter`, angepasst aus dem [Startskript des Pakets von Andre Heider](https://github.com/openwrt/packages/blob/d4a4de8309c2462d29a48597c711116360a0e8fa/utils/prometheus-node-exporter-ucode/files/init). Der Dienst des Pakets bleibt deaktiviert, so überschreibt ein `apk upgrade` nichts.
- **Enger Jail:** eigener Benutzer `node-exporter` (UID 9100) statt root, kein `ubus`, von `/etc/config` nur die eigene Datei. `/etc/config/wireless` ist für alle lesbar und enthält die WLAN-Schlüssel, und `network.wireless status` liefert sie ebenfalls.
- **Weg nach außen:** `/usr/share/nftables.d/chain-pre/output/90-node-exporter.nft` erlaubt diesem Benutzer neue Verbindungen nur zu `203.0.113.201:80`, alles andere wird abgewiesen und gezählt.
- **Modem-Collector:** `modem.uc` liest `/ONT/client/data/Status.json` (ohne Login, braucht browserähnliche Header, Timeout 3 s) und übernimmt nur Felder aus einer festen Liste. Die Seriennummer steht ebenfalls in der Antwort und wird nie gelesen. `link_status` entfällt: zeigt 0, während `lan2` mit 2500 Mbit/s läuft. Die Reihen tragen `host="glasfasermodem-2"`, der Job braucht deshalb `honor_labels`.
- **Kein Flash nötig gewesen:** Pakete per `apk add` installiert, Dateien per `scp`. `config.seed` und `gen-files.sh` nehmen alles beim nächsten Build mit; `sysupgrade -n` entfernt live installierte Pakete. Der Probelauf deckt den Exporter nicht ab.

## Änderungen

Am Gerät wird nichts dauerhaft von Hand geändert – Änderungen gehen in `uci.nix` (oder ins Inventory), dann:

1. `nix develop -c openwrt/gruffi/build.sh` – Build auf ursalia (braucht 1Password für sops).
2. `nix develop -c openwrt/gruffi/dryrun.sh` – führt das `90-gruffi` des letzten Builds in einem OpenWrt-x86-Container mit veth-Ports in gruffis Namen aus und prüft pro Netz: DHCPv4-Lease (Pool, Router, DNS), die erste Reservierung, das RA (ULA-Präfix, DNS) mit `rdisc6`, dazu `fw4 check` und die Zahl der DHCP-Bereiche. Mit `--no-dhcpv4` muss er fehlschlagen.
3. Image nach gusto und gruffi, SHA-256 vergleichen, `sysupgrade -T`, dann `sysupgrade -n`.

Für Eingriffe am laufenden Gerät (Testregeln, Reservierungen bis zum nächsten Build): uci setzen, `uci commit`, dann `fw4 reload` bzw. `/etc/init.d/dnsmasq restart`, wenn das reicht. `/etc/init.d/network reload` ist erlaubt (auch `wifi up`, `wifi down` und `wifi reload` lösen ihn aus), danach aber prüfen, ob `lan2` empfängt, zum Beispiel per Ping zum Modem. Am 2026-11-02 empfing `lan2` nach mehreren Reloads nichts mehr, bis zum Neustart; am 2026-11-06 kam das bei 11 Reloads auf einem neueren Image nicht wieder (nixlab#94). Bei Änderungen an `lan2.7` oder `wan` und an Ports mit angeschlossenem Gerät ist das ungetestet, dort lieber neu starten.

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

- **WLAN-Modul kann fehlen** (nixlab#93): Vom 2026-11-02 bis 2026-11-06 bekamen beide PCIe-Controller beim Boot keinen Link (`PCIe link down, current LTSSM state: detect.quiet`, Probe -110), auch nach Neustarts. Die erste Stromtrennung von 30 s löste das, danach kam das Modul bei jedem Boot hoch, auch warm und nach 2 s ohne Strom. Der Auslöser ist unbekannt. Falls es wiederkommt: `dmesg` sichern, 30 s stromlos. Ohne Modul ist die Steckdosenleiste nicht erreichbar, dann vor Ort den Taster drücken und ap-og einstecken. Seit 2026-11-07 meldet das der Alarm GruffiWifiMissing, ein Push aus Home Assistant kommt zusätzlich, wenn die Leiste nicht mehr erreichbar ist (nixlab#191).
- **`network reload` mit Nachprüfung** (nixlab#94, siehe [Änderungen](#anderungen)).
- **lan4/lan5** empfingen auf älteren Images nichts – behoben im PR durch den MDI-Swap-Patch (`967-54`); ab Head `e3d333fa67` zeigt `ethtool -S lanN` auch die Hardware-Zähler des YT9224 (`967-55`).
- **Erster Boot nach Stromausfall:** PPPoE braucht oft ein bis zwei PADO-Timeouts (je 35 s), weil die alte Sitzung bei der Telekom noch hängt; nach einem Warmstart steht PPPoE sofort.

## Power-Watchdog

`gruffi-power-watchdog` auf ursalia bemerkt, dass gruffi tot ist, und erreicht die Leiste, an der gruffi hängt, über Bluetooth LE, weil ursalia ohne gruffi keinen Netzweg zu `shelly-strip-og-flur` hat. **Es ist ein Trockenlauf: Er protokolliert, wann er gruffi aus- und wieder einschalten würde, und kann nicht schalten.** Code: `pkgs/gruffi-power-watchdog`, `hosts/ursalia/gruffi-power-watchdog.nix`; Stand und nächste Schritte in nixlab#177.

ursalia (`lan3`), zorlock (`lan4`) und homeassistant (`lan7`) hängen direkt an gruffi, Kabel-Link oder ein anderes LAN-Gerät sagen also nichts über gruffi aus. Das zweite Zeichen ist der WLAN-Zustand der Leiste selbst, über BLE gelesen, denn die Leiste hängt in gruffis WLAN:

| gruffi antwortet auf Ping im LAN | WLAN der Leiste | Bedeutung | Entscheidung |
| --- | --- | --- | --- |
| nein, 10 min lang | getrennt, 10 min lang | gruffi aus oder tot | `would-cycle` |
| nein | verbunden | Kabel, Netzwerkkarte oder gruffi halb am Leben | `lan-down-wifi-up`, nichts |
| ja | egal | gruffi lebt | `healthy`, nichts |

Bremsen: nichts in den ersten 10 Minuten nach dem Start von ursalia, höchstens eine Aktion in 30 Minuten und 3 insgesamt, danach Stopp bis `gruffi-power-watchdog reset`. BLE ohne Antwort zählt nie als Beleg. Eine tägliche BLE-Abfrage hält den Weg geprüft (Alarm `GruffiWatchdogBleStale`).

**Vor geplanten Arbeiten an gruffi** (Sysupgrade, Flash, längere Wartung), in einer Root-Shell auf ursalia:

```bash
gruffi-power-watchdog hold 2h "sysupgrade"
```

```bash
gruffi-power-watchdog release
```

Eine Sperre dauert höchstens 24 Stunden und endet von selbst. `gruffi-power-watchdog status` zeigt Sperre und Zähler.

**Leiste koppeln**, einmalig und solange gruffi läuft. Bis dahin scheitert jede BLE-Abfrage, und die Entscheidung bleibt `lan-down-witness-unknown`. BLE-RPC einschalten, Pairing öffnen, dann auf ursalia mit `bluetoothctl` koppeln (`agent NoInputNoOutput`, `default-agent`, `scan le`, `pair D8:85:AC:EC:D0:46`). Die BLE-Adresse ist die WLAN-MAC der Leiste plus 2.

```bash
ssh gruffi "wget -qO- 'http://203.0.113.19/rpc/BLE.SetConfig?config=%7B%22rpc%22%3A%7B%22enable%22%3Atrue%7D%7D'"
```

```bash
ssh gruffi "wget -qO- 'http://203.0.113.19/rpc/BLE.StartPairing?timeout=180'"
```

BLE braucht einen längeren Supervision Timeout als der Kernel vorgibt: Mit den standardmäßigen 420 ms rissen bei -84 dBm 6 von 10 Verbindungen mit `Connection Timeout (0x08)` ab, mit 6 s keine (`ConnectionSupervisionTimeout=600`). BlueZ meldet so einen Abriss als ATT-Fehler `0x0e`, die Leiste sendet ihn nicht. RPC läuft über GATT wie bei Mongoose OS' [rpc-gatts](https://github.com/mongoose-os-libs/rpc-gatts/blob/fa706f66f4bf3632c042248dbf0bf98b5dd60f73/README.md) (Cesanta) und in Shellys [BLE-Dokumentation](https://shelly-api-docs.shelly.cloud/gen2/ComponentsAndServices/BLE/) beschrieben.

## Fehlersuche

| Symptom | Ursache und Abhilfe |
| --- | --- |
| SSH zu gruffi: „Permission denied (publickey)“ mit „communication with agent failed“ | Der 1Password-SSH-Agent will den Schlüssel `gruffi.homelab.example` (wieder) freigegeben haben – den Dialog in 1Password bestätigen |
| „Host key verification failed“ nach einem Upgrade | `sysupgrade -n` erzeugt neue Host-Keys; den neuen Fingerabdruck mit dem aus dem Upgrade-Check vergleichen und ins Inventory (`hosts.gruffi.sshHostKeys`) |
| Aus dem Terminal-Bereich der Claude-App „No route to host“ zu Adressen im LAN | Der App fehlt die macOS-Berechtigung „Local Network“; in Terminal.app geht es |
| Von gusto am Kabel ins Server-Netz „Connection refused“, obwohl der Partner läuft | `netbird down` löscht die Route des Server-Netzes samt der direkten Route über das Kabel; der Verkehr geht dann über gruffi, der Weiterleitungen innerhalb einer Zone ablehnt. Nach `netbird down` die Netzwerkschnittstelle einmal aus- und einschalten |
| Ein USB-Adapter schafft nur ~300 Mbit/s | Er hängt mit USB 2.0 an (`ioreg -r -c IOUSBHostDevice -l -w0`, `UsbLinkSpeed` = 480000000) – anderes Kabel oder direkt an den Mac |
| Kein DHCP in einem Netz | `grep dhcp-range /var/etc/dnsmasq.conf.*` – fehlen Bereiche, fehlt `dhcpv4=server` |
