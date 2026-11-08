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
| Display | ab dem nächsten Image [glinet-panel-ui](https://github.com/blogic/glinet-panel-ui) von John Crispin (LVGL, ucode; Feed [blogic/feed-blogic](https://github.com/blogic/feed-blogic)), gebaut aus unseren Forks mit Modi public und private, Rotation und PIN-Sperre, bis das upstream ist. Das laufende Image zeichnet noch nichts. Ohne PIN sichtbar: Traffic, System und der QR-Code des Gastnetzes; Seiten und PIN stehen in `glinet_panel` (`uci.nix`, PIN aus sops). Der Stock-U-Boot ist kein Hindernis: Ohne Übergabe vom Bootloader initialisiert `panel-mipi-dbi` das Panel selbst. Es fehlt nur die Boot-Anzeige aus BL2/U-Boot |

## Dateien

| Datei | Inhalt |
| --- | --- |
| `openwrt/gruffi/uci.nix` | Alles, was beim ersten Boot gesetzt wird: Portrollen, Bridge und VLANs, Netze, DHCP mit allen Reservierungen, DNS, Firewall-Zonen und -Regeln, PPPoE, SQM, WLANs, Thread-sysctl, avahi; dazu die Erwartungen für den Probelauf (`dryrun`). Leitet Adressen, Pools, Präfixe und Reservierungen aus dem Inventory ab |
| `openwrt/gruffi/gen-files.sh` | Erzeugt `files/` fürs Image aus `uci.nix` und setzt die Geheimnisse ein (WLAN-Schlüssel, Root-Passwort-Hash aus `secrets.yaml`, sops, Workstation-Schlüssel aus 1Password) |
| `openwrt/gruffi/secrets.yaml` | sops: WLAN-Schlüssel, Root-Passwort und sein Hash |
| `openwrt/gruffi/config.seed` | Die Paketauswahl und Optionen des Builds |
| `openwrt/gruffi/inner.sh` | Läuft im Build-Container: PR-Head holen, Fix cherry-picken, Kernel-Optionen setzen, bauen, `BUILDINFO` schreiben |
| `openwrt/gruffi/build.sh`, `Containerfile` | Startet den Build auf ursalia (Debian-Container, inkrementell, Zustand in `/var/lib/openwrt-build/gruffi`) |
| `openwrt/gruffi/node-exporter.init`, `node-exporter-modem.uc`, `node-exporter-dhcp-leases.uc` | Eigener Dienst für den Node-Exporter, der Modem-Collector und der Lease-Collector (siehe [Metriken](#metriken)) |
| `openwrt/gruffi/dryrun.sh`, `dryrun-guest.sh` | Probelauf mit echten Clients in einer VM auf ursalia (siehe [Änderungen](#anderungen)) |

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
- **Offload:** Flow-Offloading nur in Software. Hardware-Offloading (PPE) ist seit dem 2026-11-07 aus, wie in der GL-Firmware: Flows in der PPE liefen an cake auf `pppoe-wan` und an den Netdev-Zählern (node-exporter, Panel) vorbei, und 300/150 Mbit/s braucht sie nicht. `bridger` (Gerätepaket des GL-BE14000, legt Bridge-Flows zwischen den beiden Switches und dem WLAN in die PPE) ist aus demselben Grund seit dem 2026-11-07 live gestoppt und deaktiviert. `config.seed` lässt es weg; im Image fehlt es erst ab dem nächsten Build, `inner.sh` bricht ab, falls es doch ausgewählt bleibt. Die CPU bridget 2,8 Gbit/s in Software, die Clients haben höchstens 2,5G.

## Metriken

`prometheus-node-exporter-ucode` lauscht auf `198.51.100.1:9100`, nur ursalia kommt per Firewall-Regel `r_node_exporter` dorthin, `r_node_exporter_mgmt` sperrt `mgmt` aus, dessen Zone sonst Eingehendes annimmt. Im Mesh begrenzen die NetBird-Policies den Zugriff (`terraform/netbird/gruffi.tf`), denn NetBird nimmt `wt0` schon vor den Firewall-Zonen an; `r_node_exporter_mesh` wirkt nicht, solange NetBird läuft; vmagent auf ursalia fragt ihn als Job `gruffi` ab (Dashboard „Homelab / Fiber modem“). Seit 2026-11-07, nixlab#178.

- **Eigener Dienst:** `/etc/init.d/node-exporter`, angepasst aus dem [Startskript des Pakets von Andre Heider](https://github.com/openwrt/packages/blob/d4a4de8309c2462d29a48597c711116360a0e8fa/utils/prometheus-node-exporter-ucode/files/init). Der Dienst des Pakets bleibt deaktiviert, so überschreibt ein `apk upgrade` nichts.
- **Enger Jail:** eigener Benutzer `node-exporter` (UID 9100) statt root, kein `ubus`, von `/etc/config` nur die eigene Datei. `/etc/config/wireless` ist für alle lesbar und enthält die WLAN-Schlüssel, und `network.wireless status` liefert sie ebenfalls.
- **Weg nach außen:** `/usr/share/nftables.d/chain-pre/output/90-node-exporter.nft` erlaubt diesem Benutzer neue Verbindungen nur zu `203.0.113.201:80`, alles andere wird abgewiesen und gezählt.
- **Modem-Collector:** `modem.uc` liest `/ONT/client/data/Status.json` (ohne Login, braucht browserähnliche Header, Timeout 3 s) und übernimmt nur Felder aus einer festen Liste. Die Seriennummer steht ebenfalls in der Antwort und wird nie gelesen. `link_status` entfällt: Firmware .001 zeigte bei 2500 Mbit/s 0, seit .013 zeigt es 2500. Die Reihen tragen `host="glasfasermodem-2"`, der Job braucht deshalb `honor_labels`.
- **Stationen:** `wifi_ap.uc` liest APs und Stationen per nl80211, ohne `ubus` (der `wifi.uc` des Feeds fragt `network.wireless status` ab, dessen Antwort die WLAN-Schlüssel enthält). Dazu `gruffi_pci_devices`: 4 mit laufendem Modul. Die Reihen pro Station tragen die MAC der Clients und zeigen, wer wann zu Hause ist, deshalb hat das Dashboard „Homelab / gruffi Wi-Fi“ keinen Freigabe-Link. Vorlage: [`wifi.uc` in openwrt/packages](https://github.com/openwrt/packages/blob/85ba4cff22728b21527e4bf1e29411e7c68a4a3c/utils/prometheus-node-exporter-ucode/files/extra/wifi.uc).
- **Leases:** `dhcp_leases.uc` liest `/tmp/dhcp.leases`, die einzige Datei aus `/tmp` im Jail, und braucht weder `ubus` noch root. dnsmasq schreibt die Datei an Ort und Stelle neu, die Einbindung bleibt also gültig. Netze und Pools kommen aus der uci-Sektion `collector dhcp_leases`, abgeleitet aus dem Inventar. Hostnamen der Clients gelten als nicht vertrauenswürdig: nur Buchstaben, Ziffern, `.`, `_` und `-`, höchstens 63 Zeichen. Die Serien tragen MAC und Hostname, das Dashboard „Homelab / gruffi DHCP“ ist also nicht zum öffentlichen Teilen. Alarm `DhcpPoolFilling` über 80 % für 30 Minuten. nixlab#115.
- **Flows:** Je Bridge `br-lan.191`-`195` exportiert ein `softflowd` IPFIX an ursalia, vor dem NAT. goflow2 läuft dort als Kindprozess von Vector (`hosts/ursalia/flows.nix`), der das Gerät per MAC aus dem Inventar und AS und Land aus DB-IP Lite ergänzt und alles an VictoriaLogs auf grammi schickt, 30 Tage. Die Bytes stimmen mit Offloading an mit conntrack überein (nixlab#59). softflowd setzt `br-lan` in den Promiscuous-Modus. Ein Flow erscheint, wenn er endet, lange jede Minute. Verbindungen zwischen zwei VLANs zählen einmal. Als intern gilt auch gruffis delegiertes IPv6-Präfix: `ipv6_prefix.uc` meldet das per DHCPv6-PD erhaltene (seine unreachable-Route in `/proc/net/ipv6_route`), Vector liest es alle 5 Minuten aus VictoriaMetrics zurück; die Präfixlänge aus dem Inventar ist der Rückfall. Alarme `GruffiPrefixLengthMismatch` (gelieferte Länge weicht vom Inventar ab) und `GruffiNoDelegatedPrefix`. Verbindungen innerhalb eines VLANs sind größtenteils nicht sichtbar. Multicast und Broadcast werden verworfen. `/etc/hotplug.d/iface/90-softflowd` startet ihn neu, wenn ein Netz hochkommt. Alarm `FlowExportStopped`.
- **Log:** `logd` schickt das Systemlog samt DHCP-Ereignissen per UDP an Vector auf ursalia, der es nur von gruffi annimmt. In VictoriaLogs steht es als `host=gruffi`. Das Dashboard „gruffi DHCP“ zeigt die DHCP-Ereignisse.
- **Firmware des Modems:** .013 seit 2026-11-07, von Hand eingespielt; das Modem war trotz aktiver Auto-Updates noch auf .001. Der wöchentliche Versions-Check vergleicht `modem_info` mit der neuesten Version in [Telekoms Liste](https://www.telekom.de/hilfe/downloads/firmware-aenderungen-glasfaser-modem-2). Ändert Telekom das Format der PDF, meldet er „unknown“.
- **Kein Flash nötig gewesen:** Pakete per `apk add` installiert, Dateien per `scp`. `config.seed` und `gen-files.sh` nehmen alles beim nächsten Build mit; `sysupgrade -n` entfernt live installierte Pakete. Der Probelauf prüft nur, wer den Port des Exporters erreicht, nicht den Exporter selbst.
- **Temperaturen und Lüfter:** `hwmon.uc` liest CPU, die drei mt7996-Sensoren, Drehzahl und PWM aus `sysfs`, unter den Namen des offiziellen node_exporter. Dashboard „gruffi cooling“. Seit dem 2026-11-09 live, nixlab#255.

## Lüfter

[fancontrol von JiaY-shi](https://github.com/JiaY-shi/fancontrol/commit/bdd72939b50a483333a6928f37bddce31259c002) (MIT) regelt den Lüfter stufenlos statt der drei Kernel-Stufen. Es kommt mit dem nächsten Image auf gruffi; bis dahin regelt der Kernel. Die Kurve steht in `fanSettings` in `openwrt/gruffi/uci.nix` (nixlab#255).

- **Kurve:** aus unter 55 °C, dann von PWM 40 (etwa 1430 RPM) linear bis PWM 240 bei 85 °C; aus bei 52 °C. Kein Kick, denn ab PWM 30 läuft der Lüfter aus dem Stillstand an.
- **Sensor:** nur die CPU-Zone. Die WLAN-Sensoren zeigt das Dashboard; bleiben sie deutlich über der CPU, müsste die Kurve auch ihnen folgen, was einen Patch braucht.
- **Obergrenze 240:** auch für Sensorausfall und Beenden, deren Standard 255 ist. Der Device Tree von OpenWrt sagt, dass 255 diesen Lüfter anhält. Gemessen lief er 5 s lang mit 5370 RPM, und [Tomato64](https://github.com/tomato64/tomato64/blob/8b144be1b07c406abada39a4a7d4c75e031f587d/tomato64/board/arm64/be14000/linux-patches/00002-mt7988a-glinet-gl-be14000.dts.patch) misst auf der Stock-Firmware ebenfalls keinen Stillstand. Einen Dauerlauf gab es nicht; 240 kostet rund 5 % Drehzahl.
- **Kernel als Rückfallebene:** `step_wise` bleibt aktiv und schreibt bei jedem Überschreiten eines Trip-Punkts seine Stufe, bis der Daemon sie nach höchstens 2 s korrigiert. Damit das beim Abkühlen nicht stört, setzt `fan-trip` den untersten Trip-Punkt beim Booten von 60 auf `start_temp`. `user_space` wäre ruhiger, aber ohne Daemon kühlte dann niemand nach.
- **Messen:** Ein Schreibzugriff auf `pwm1` verschiebt auch `cur_state` des Cooling Device. Tests dürfen den alten Wert also nicht daraus lesen.
- **Last:** Volle CPU-Last ohne Lüfter erreichte in 4 Minuten nur 54,8 °C, ausgehend von 51 °C. Verkehr und WLAN waren dabei nicht dabei.

## Änderungen

Am Gerät wird nichts dauerhaft von Hand geändert – Änderungen gehen in `uci.nix` (oder ins Inventory), dann:

1. `nix develop -c openwrt/gruffi/build.sh` – Build auf ursalia (braucht 1Password für sops).
2. `nix develop -c openwrt/gruffi/dryrun.sh` – führt das `90-gruffi` des letzten Builds in einer OpenWrt-x86-VM auf ursalia aus (QEMU/KVM ohne Netzwerkkarte und ohne Watchdog-Gerät, die Clients als Namespaces in der VM an veth-Ports in gruffis Namen) und prüft pro Netz: DHCPv4-Lease (Pool, Router, DNS), die erste Reservierung, das RA (ULA-Präfix, DNS) mit `rdisc6`, dazu `fw4 check`, die Zahl der DHCP-Bereiche, den Modem-Zugriff pro Zone und dass nur ursalia den Port des Node Exporters erreicht. Mit `--no-dhcpv4` muss er fehlschlagen. Bis nixlab#181 lief der Probelauf in privilegierten Containern, die ursalia über den Hardware-Watchdog zurücksetzen konnten. Die Probeläufe von ap-og und sw-og-flur laufen noch so; der der WLAN-Bridges läuft in zwei VMs (`openwrt/bridge/dryrun.sh`).
3. Image nach gusto und gruffi, SHA-256 vergleichen, `sysupgrade -T`, dann `sysupgrade -n`.
4. gruffi wieder im Mesh anmelden: `sysupgrade -n` löscht die Anmeldung, der alte Peer bleibt aber stehen, also zuerst im NetBird-Dashboard löschen. `just netbird-key-gruffi` legt einen neuen Setup-Key in die Zwischenablage, der Befehl zum Anmelden steht in `terraform/netbird/gruffi.tf`. Ohne `--management-url` geht `netbird up` an die NetBird-Cloud.

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
