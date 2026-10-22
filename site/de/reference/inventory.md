# Inventar

`inventory.json` führt jede Maschine des Labs, ob dieser Flake sie konfiguriert oder nicht: was für ein Gerät es ist (Hersteller, Modell, Seriennummer), wo es steht, wie dieser Ort ans Internet kommt, worauf es läuft oder worin es steckt, woher es Strom bekommt, wie seine Platte nach einem Reboot entsperrt wird, seine Netze, Interfaces und Adressen und seine SSH-Host-Keys. Das sind die Angaben, die in keiner NixOS-Config stehen. Genutzt werden heute die Host-Keys: Die known_hosts jedes Hosts kommt von hier, und `nix flake check` gleicht sie mit den age-Schlüsseln in `.sops.yaml` ab. Der Rest soll später der Gruppierung in der Topologie und den Abhängigkeiten im Alerting dienen (der Uplink ist weg, also nicht für jeden Host dahinter alarmieren).

| Datei | Aufgabe |
| --- | --- |
| `inventory.json` | Die Daten. JSON, damit Nix (`builtins.fromJSON`) und OpenTofu (`jsondecode`) sie beide ohne Umweg lesen. |
| `inventory.nix` | Format (`spec`), Validierung, abgeleitete Sicht, Generator für das JSON-Schema. In `flake.nix` als `lib.inventory`. |
| `inventory.schema.json` | JSON-Schema für den Editor (Vervollständigung, Hover-Hilfe, Fehler direkt im Text). Generiert, nie von Hand ändern. |
| `tests/inventory.nix` | Tests für die Validierung: ein vollständiges Beispielinventar und ein Fall je Regel. |
| `flake.nix` | `lib.inventory`, die Checks und `programs.ssh.knownHosts` für jeden Host (NixOS und nix-darwin). |

Faustregel für den Inhalt: **nur, was sich nicht aus einer Config ableiten lässt.** OS, Architektur, CPU/RAM, Mesh-Adresse, Exporter und Backup-Ziele bleiben draußen; die liest `topology.nix` aus `nixosConfigurations`. Jede Beziehung steht **nur in einer Richtung** drin; die Gegenrichtung wird abgeleitet, damit beide nicht auseinanderlaufen können.

## Aufbau

Fünf Abschnitte, jeder ein Objekt aus Einträgen mit ID als Schlüssel. IDs bestehen aus Kleinbuchstaben, Ziffern und Bindestrichen (unverändert als Graphviz-Knoten oder Label verwendbar).

```
owners   ◄──────── hosts.owner
uplinks  ◄──────── sites.uplinks[]
sites    ◄──────── hosts.site, networks.site
networks ◄──────── hosts.interfaces.<name>.network
hosts    ◄──────── hosts.runsOn / inside / power / manages[] / unlock.tang[], networks.dhcpServer
```

Ein Schlüssel `"$schema": "./inventory.schema.json"` ganz oben ist erlaubt und wird ignoriert; er sagt dem Editor, wo das Schema liegt.

### owners

Wer ein Gerät administriert: entscheidet, wen man anruft und was man ändern darf.

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `name` | String | Pflicht | Anzeigename |
| `contact` | String | | Ansprechpartner, wenn Geräte dieses Owners betroffen sind |
| `note` | String | | Freitext |

### uplinks

Ein Internetanschluss. Mehrere Sites können sich einen teilen (selten), eine Site kann mehrere haben (primär und Backup).

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `isp` | String | | Provider; im Rechenzentrum der Hoster |
| `asn` | Ganzzahl ≥ 1 | | AS-Nummer des Provider-Netzes, ohne „AS“ |
| `medium` | `fiber` `dsl` `cable` `lte` `satellite` `datacenter` | | Anschlussart |
| `bandwidth` | `{ "down": int, "up": int }` | | Gebuchte Bandbreite in Mbit/s, beide Werte Pflicht |
| `ipv4` | `public` `cgnat` `none` | | Was der Anschluss für IPv4 hergibt |
| `ipv4Static` | Boolean | | Feste öffentliche IPv4-Adresse (nur bei `public` sinnvoll) |
| `ipv6` | Boolean | | Natives IPv6 |
| `ipv6PrefixLength` | Ganzzahl 1–128 | | Größe des delegierten IPv6-Präfixes (56 für ein /56); nur mit `ipv6` |
| `ipv6Static` | Boolean | | Festes IPv6-Präfix; nur mit `ipv6` |
| `note` | String | | Freitext |

Alle Felder sind optional, damit ein Anschluss schon eingetragen werden kann, bevor die Details bekannt sind.

### sites

Ein Ort, an dem Geräte stehen.

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `city` | String | Pflicht | Stadt |
| `kind` | `residential` `hackerspace` `datacenter` | Pflicht | Art des Orts |
| `provider` | String | | Wer den Ort betreibt (Hoster, Verein); bei einer Wohnung leer |
| `uplinks` | Liste von Uplink-IDs | Pflicht, ≥ 1 | Internetanschlüsse, **der primäre zuerst**, Backups danach |
| `note` | String | | Freitext |

### hosts

Jedes Gerät mit einer Adresse, auf die es ankommt: Server, VMs, Router, APs, KVMs, PDUs, Appliances.

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `kind` | siehe [Gerätearten](#kinds) | Pflicht | Was das Gerät ist |
| `vendor` | String | | Hersteller (Lenovo, Apple, GL.iNet). Nicht bei `vm`/`container` |
| `model` | String | | Modell ohne Hersteller (ThinkCentre M720q), bei einer VM das Produkt bzw. der Tarif des Anbieters |
| `productId` | String | | Kennung des Herstellers für Treiber und Firmware: Lenovo-Maschinentyp (`10T7…`), Apple-Modellkennung (`Mac16,10`). Nicht bei `vm`/`container` |
| `serial` | String | | Seriennummer, im ganzen Lab eindeutig. Nicht bei `vm`/`container` |
| `site` | Site-ID | Pflicht\* | Wo es steht. \*Optional mit `runsOn` oder `inside`: dann geerbt |
| `owner` | Owner-ID | Pflicht | Wer es administriert |
| `managed` | Boolean | Pflicht | Von diesem Flake konfiguriert – muss zu `flake.nix` passen |
| `criticality` | `core` `service` `lab` | Standard `service` | `core`: ohne das steht das Lab; `service`: ein Dienst ist weg; `lab`: nichts hängt daran |
| `availability` | `always-on` `intermittent` | Standard `always-on` | `intermittent`: offline ist normal (Laptop), kein Vorfall |
| `unlock` | Objekt, siehe [Entsperren](#entsperren) | | Weglassen bei unverschlüsselter Platte |
| `runsOn` | Host-ID | | Nur `vm`/`container`: die Maschine, auf der es läuft |
| `inside` | Host-ID | | Physisch in ein anderes Gerät eingebaut |
| `power` | Host-ID | | Stromquelle: PDU/USV, PoE-Switch oder der Host, in dem eine Karte steckt |
| `manages` | Liste von Host-IDs | | Nur `kvm`: Maschinen, auf die es Out-of-Band-Zugriff gibt |
| `sshHostKeys` | Liste von Strings | | Öffentliche SSH-Host-Keys, `"<typ> <base64>"` ohne Kommentar, siehe [SSH-Host-Keys](#ssh-host-keys) |
| `interfaces` | Objekt: Name → Interface | | Netzwerk-Interfaces, siehe [Interfaces](#interfaces) |
| `note` | String | | Freitext |

#### Gerätearten { #kinds }

| Art | Für |
| --- | --- |
| `server` | Physische Maschine mit Diensten |
| `hypervisor` | Physische Maschine, die VMs/Container für andere betreibt |
| `vm`, `container` | Virtuell; die einzigen Arten, die `runsOn` haben dürfen |
| `router`, `switch`, `ap` | Netz (`ap` = WLAN-Access-Point) |
| `pdu`, `ups` | Strom |
| `kvm` | IP-KVM, extern oder als Karte im Host; die einzige Art, die `manages` haben darf |
| `nas`, `workstation`, `laptop` | Wie benannt |
| `appliance` | Alles andere mit Adresse: Apple TV, Drucker, … |

Ob ein Host virtuell ist, folgt aus `kind` (`vm`, `container`) – nicht aus `runsOn`. Eine gemietete VM ist eine `vm` ohne `runsOn`: Der Hypervisor des Anbieters steht nicht im Inventar.

### networks

Ein Layer-2-Netz mit seinem IPv4-Präfix: das Heimnetz, ein VLAN im Hackerspace.

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `name` | String | Pflicht | Bezeichnung (die ID ist der technische Schlüssel) |
| `site` | Site-ID | Pflicht | Wo das Netz ist |
| `vlan` | Ganzzahl 1–4094 | | 802.1Q-VLAN-ID; weglassen bei einem ungetaggten Netz. Eindeutig je Site – eine andere Site darf dieselbe ID nutzen |
| `ipv4` | Präfix, z. B. `192.0.2.0/24` | | Ohne Host-Bits |
| `ipv6` | Präfix, z. B. `2001:db8:1::/64` | | Nur wenn es fest ist (ULA, statische GUA) – kein wechselndes Provider-Präfix |
| `dhcpServer` | Host-ID | | Verteilt IPv4 per DHCP; muss an der Site sein und ein Interface in diesem Netz haben |
| `dhcpPool` | `{ "start": ip, "end": ip }` | | Dynamischer Bereich; innerhalb von `ipv4`, Start ≤ Ende. Braucht `ipv4` und `dhcpServer` |
| `note` | String | | Freitext |

Ein Netz ohne Interface ist erlaubt – es kann vor seinen Geräten eingetragen werden.

## Interfaces { #interfaces }

`hosts.<id>.interfaces` ordnet Interface-Namen ihre Daten zu. Der Name ist der des Betriebssystems (`eno1`, `wlp2s0f0`, `en0`); bei einer Appliance ein beliebiges Label (`lan`, `wan`). Ein VLAN-Interface auf einem Trunk (`eno1.20`) ist ein eigener Eintrag; seine VLAN-ID kommt aus seinem Netz.

```json
"interfaces": {
  "eno1":    { "mac": "52:54:00:12:34:56", "medium": "ethernet", "linkLocal": "eui64",
               "network": "lan", "ipv4": { "mode": "reserved", "address": "192.0.2.10" } },
  "eno1.20": { "network": "iot", "linkLocal": "fe80::1234", "ipv4": { "mode": "dhcp" } }
}
```

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `mac` | `aa:bb:cc:dd:ee:ff`, klein | | Hardware-Adresse. Im ganzen Lab eindeutig, keine Multicast-Adresse |
| `medium` | `ethernet` `wifi` | | Physisches Medium |
| `linkLocal` | `eui64` `stable-privacy` `random` oder eine `fe80::`-Adresse | | Wie die IPv6-Link-Local-Adresse entsteht |
| `network` | Netz-ID | | Netz, in dem es hängt; an derselben Site wie der Host |
| `ipv4` | `{ "mode": …, "address": … }` | | IPv4-Adressierung, braucht `network` |
| `note` | String | | Freitext |

**Link-Local.** Nur bei EUI-64 folgt die Adresse aus der MAC (`fe80::` + MAC mit umgedrehtem U/L-Bit und `ff:fe` in der Mitte); das abgeleitete `ipv6LinkLocal` wird dann berechnet. Viele Systeme nutzen stattdessen `stable-privacy` (RFC 7217: stabil, aber nicht berechenbar), auch macOS und tvOS leiten sie nicht aus der MAC ab. Ist die Adresse stabil und bekannt, trägt man sie direkt ein (`"fe80::…"`); genau das macht `just inventory-collect`, wenn sie nicht zu EUI-64 passt. `eui64` braucht eine `mac`; mit einer *lokal verwalteten* WLAN-MAC (private WLAN-Adresse) ist es ein Fehler, weil diese MAC – und damit die Adresse – meist zufällig ist. Eine lokal verwaltete Ethernet-MAC ist in Ordnung (QEMUs `52:54:00:…` ist eine).

**IPv4 – `ipv4.mode`:**

| Modus | Bedeutung | Regeln |
| --- | --- | --- |
| `reserved` | Feste DHCP-Lease per MAC (Reservierung auf dem `dhcpServer`) | `address` und `mac` Pflicht; das Netz braucht einen `dhcpServer`. MAC noch nicht nachgeschlagen: der Platzhalter `aa:bb:cc:dd:ee:ff` – wird nie weitergegeben (`mac` in der abgeleiteten Sicht null, nicht in `reservations`), steht unter `pending` |
| `static` | Auf dem Gerät selbst eingetragen | `address` Pflicht; außerhalb des `dhcpPool` |
| `dhcp` | Dynamisch | keine `address` |

Jede `address` liegt im `ipv4`-Präfix des Netzes, ist weder Netz- noch Broadcast-Adresse (außer bei /31, /32) und kommt je Netz nur einmal vor. Ein Netz ohne `ipv4` kann keine Adressen aufnehmen.

**IPv6** steht hier nur als Link-Local und als festes Präfix je Netz: DHCPv6-Reservierungen hängen an der DUID, nicht an der MAC, und ein Provider-Präfix (SLAAC) wechselt.

## SSH-Host-Keys { #ssh-host-keys }

`sshHostKeys` enthält die öffentlichen Host-Keys eines Geräts – verwaltet oder nicht – als `"<typ> <base64>"` ohne Kommentar: `ssh-ed25519`, `ecdsa-sha2-nistp256/384/521` oder `ssh-rsa`. Ein ed25519-Key genügt; andere nur, wenn das Gerät kein ed25519 hat (Dropbear, KVMs). Geprüft wird das Format, ob die Key-Daten zum Typ passen (das Base64 beginnt mit dem kodierten Typnamen) und dass kein Key doppelt vorkommt – so fiele eine geklonte VM auf, die ihren Host-Key behalten hat.

Wohin sie gehen:

| Abnehmer | Wie |
| --- | --- |
| Jeder NixOS-Host und zorlock | `programs.ssh.knownHosts` aus `lib.inventory.knownHosts` (in `flake.nix` das Modul `inventoryKnownHosts` in jeder Host-Liste). Deploys und ursalias unbeaufsichtigter Push nach cuckoosegg brauchen kein Trust-on-first-use |
| gusto (Workstation) | `programs.ssh.knownHosts` wie jeder Host – `/etc/ssh/ssh_known_hosts` nach dem nächsten `just mac-switch` |
| Eine Workstation außerhalb dieses Repos | `just known-hosts` schreibt `~/.ssh/known_hosts.nixlab`; ssh liest sie mit `UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts.nixlab` unter `Host *` in `~/.ssh/config` |
| `.sops.yaml` | `checks.inventory-sops`: Für jeden verwalteten Host muss `ssh-to-age` seines ed25519-Keys den age-Empfänger `&<host>` in `.sops.yaml` ergeben. Fängt einen Host-Key, der sich ohne `sops updatekeys` geändert hat (Neuinstallation, Rotation), und einen vertippten Key. Hosts ohne Key werden übersprungen |

Namen je Key: die ID des Hosts, bei verwalteten Hosts `<host>.peer.homelab.example` (der Mesh-Name) und jede feste IPv4-Adresse seiner Interfaces (`static`/`reserved`). Ein Eintrag je Key, benannt `<host>` bzw. `<host>-<n>` bei mehreren Keys.

## Von den Geräten einsammeln

`just inventory-collect` holt, was mühsam abzutippen ist:

- **Verwaltete Hosts**, über das Mesh (root, zorlock als `admin`):
    - Host-Keys per `ssh-keyscan` (nur der ed25519-Key, wenn es einen gibt);
    - je Interface Name, MAC, `ethernet`/`wifi` und Link-Local – `eui64`, wenn die Adresse zur MAC passt, sonst die Adresse selbst. Unter Linux jedes Interface mit einem Gerät dahinter (Hardware oder virtio; kein `lo`, Mesh, Tunnel, Bridges, veths), unter macOS die Hardware-Ports ohne Thunderbolt;
    - bei Hardware, die nicht virtuell ist: `vendor`, `model`, `productId`, `serial`. Unter Linux aus `/sys/class/dmi/id` (Lenovo: Modell aus `product_version`, Maschinentyp aus `product_name`; alle anderen: Modell aus `product_name`), unter macOS aus `system_profiler` (Modell als „Mac mini (M4, 16 GB)“, die Modellkennung als `productId`). Platzhalter wie „To be filled by O.E.M.“ fallen weg.
- **Nicht verwaltete Geräte**: nur Host-Keys, an ihrer ersten festen IPv4-Adresse – `network`/`ipv4` also vorher eintragen.

| Aufruf | Wirkung |
| --- | --- |
| `just inventory-collect` | Alle Geräte; **ergänzt** nur, was fehlt, ein abweichender Wert wird ausgegeben und bleibt |
| `just inventory-collect ursalia beryl` | Nur diese Geräte |
| `just inventory-collect --force ursalia` | Übernimmt bei Abweichungen den Wert des Geräts und gibt jeden überschriebenen Wert aus |

Ein geänderter Host-Key soll eine Entscheidung sein, daher `--force` – am besten mit dem Host dazu. Auch `--force` rührt nie an, was das Gerät nicht meldet: `network`, `ipv4`, Notizen und Interfaces, die es nicht mehr hat (die von Hand entfernen).

## Beziehungen

| Feld | Bedeutung | Darf zeigen auf | Abgeleitete Gegenrichtung |
| --- | --- | --- | --- |
| `runsOn` | Virtualisierung | `vm` → `hypervisor`; `container` → `hypervisor`, `server`, `nas`, `vm` | `guests` |
| `inside` | Physischer Einbau (PCIe-Karte, Modul) | jeden Host | `contains` |
| `power` | Stromversorgung | jeden Host | `powers` |
| `manages` | Out-of-Band-Zugriff (am KVM eingetragen) | jeden Host außer sich selbst | `managedBy` |
| `unlock.tang` | Tang-Server für NBDE | jeden Host außer sich selbst | `tangClients` |
| `interfaces.*.network` | Zugehörigkeit zu einem Netz | ein Netz an der Site des Hosts | `networks.<id>.interfaces` |
| `networks.dhcpServer` | DHCP für ein Netz | einen Host mit Interface darin | – |

`runsOn`, `inside` und `power` bilden zusammen den Abhängigkeitsgraphen: Ohne was kann ein Host nicht arbeiten? Er muss zyklenfrei sein; das abgeleitete `upstream` eines Hosts ist seine transitive Hülle. `runsOn` und `inside` schließen sich aus.

`inside` sagt nichts über Strom: Ob eine PCIe-KVM-Karte vom Slot ihres Hosts lebt (Standby-Strom) oder von PoE/USB, sagt `power`. Eine Karte, die nur aus dem Slot zieht, bekommt `"power"` auf ihren Host. Dann deutet „Host und KVM beide weg“ auf Strom oder Netz, „Host weg, KVM noch da“ aufs OS – und der KVM ist der Weg hinein.

## Entsperren

```json
"unlock": { "methods": ["tpm", "nbde"], "threshold": 1, "tang": ["nas"], "fallback": "remote-ssh" }
```

| Feld | Typ | | Bedeutung |
| --- | --- | --- | --- |
| `methods` | Liste aus `tpm`, `nbde` | Pflicht (darf leer sein) | Automatische Methoden. Leer: nur ein Mensch kann entsperren |
| `threshold` | Ganzzahl ≥ 1 | Standard 1 | Wie viele Methoden gelingen müssen – der `sss`-Schwellwert von Clevis. 1 = eine reicht, 2 = TPM **und** Tang |
| `tang` | Liste von Host-IDs | Pflicht bei `nbde` | Tang-Server; einer davon genügt |
| `fallback` | `remote-ssh` `console` | | Was ein Mensch tut, wenn die Methoden scheitern: SSH (initrd-SSH, FileVault per SSH) oder Konsole/KVM |

| Fall | `unlock` |
| --- | --- |
| Unverschlüsselt | weglassen |
| TPM, Passphrase an der Konsole als Rückfall | `{"methods": ["tpm"], "fallback": "console"}` |
| Nur ein Mensch, per SSH (z. B. FileVault) | `{"methods": [], "fallback": "remote-ssh"}` |
| TPM **oder** Tang | `{"methods": ["tpm", "nbde"], "tang": ["a"]}` |
| TPM **und** Tang (Platte entsperrt nur im eigenen Netz) | `{"methods": ["tpm", "nbde"], "threshold": 2, "tang": ["a"]}` |
| Nur Tang, zwei Server | `{"methods": ["nbde"], "tang": ["a", "b"], "fallback": "console"}` |

NBDE ist eine eigene Abhängigkeit: Ein Host, der Tang **braucht** (`nbde` ohne `tpm`, oder `threshold` 2), kommt erst wieder hoch, wenn einer seiner Tang-Server selbst ohne Hilfe läuft. Die Validierung verfolgt diese Ketten. Gibt es einen Host, der nie ohne Mensch hochkäme – zwei Hosts, die gegenseitig ihr einziger Tang-Server sind, oder ein Tang-Server, der selbst an der Passphrase-Abfrage wartet –, ist das ein Fehler. Das abgeleitete `unattendedBoot` sagt je Host, ob er nach Reboot oder Stromausfall von allein wiederkommt.

Nicht geprüft: ob ein Tang-Server wirklich Tang betreibt. Das steht in seiner Config, nicht hier.

## Prüfung

`nix flake check` (oder nur der Inventar-Teil: `just inventory-test`) prüft in drei Stufen. Jede Stufe läuft nur, wenn die vorige nichts gefunden hat, damit aus einem Tippfehler keine zwanzig Folgefehler werden. Jeder Fehler nennt den Pfad:

**1. Struktur** – zuerst die oberste Ebene, allein, dann jeder Eintrag:

- oben nur `$schema`, `owners`, `uplinks`, `sites`, `networks`, `hosts`, alle fünf Abschnitte vorhanden
- gültige IDs und Interface-Namen, keine unbekannten Felder (fängt Tippfehler), Pflichtfelder vorhanden
- Typen, Enums, Mindest-/Höchstwerte, Formate (MAC, IPv4-Adresse und -Präfix, IPv6-Präfix, Link-Local, SSH-Key), keine Duplikate in Listen
- Referenzen zeigen auf einen vorhandenen Eintrag des richtigen Abschnitts

```
hosts.vps.critcality: unknown field (known: availability, criticality, inside, interfaces, kind, managed, manages, model, note, owner, power, productId, runsOn, serial, site, sshHostKeys, unlock, vendor)
hosts.nas.interfaces.eno1.mac: "52-54-00-12-34-56" is not a lower-case MAC address like aa:bb:cc:dd:ee:ff
hosts.app.runsOn: "pve2" is not in hosts
uplinks.fiber-home.asn: expected a whole number, got "AS64496"
```

**2. Regeln zwischen Einträgen:**

- `runsOn` nur für `vm`/`container` und nur auf einer erlaubten Art; nicht zusammen mit `inside`
- `manages` nur für `kvm`; nichts zeigt auf sich selbst
- `runsOn`/`inside`/`power` ohne Zyklen
- `site` vorhanden oder erbbar; ein ausdrückliches `site` passt zum geerbten
- jede Site hat einen Uplink; kein Uplink, keine Site, kein Owner ohne Verwendung; IPv6-Details eines Uplinks nur mit `ipv6`
- `unlock`: mindestens eine Methode oder ein Rückfall; `threshold` ≤ Zahl der Methoden; `tang` genau dann, wenn `nbde`
- `managed` stimmt mit `flake.nix` überein: Jeder Eintrag aus `nixosConfigurations`/`darwinConfigurations` steht hier als managed, und jeder managed-Eintrag hat eine Konfiguration
- Hardware: `vendor`/`productId`/`serial` nicht bei `vm`/`container`; keine Seriennummer doppelt
- SSH-Keys: Key-Daten passen zum Typ, kein Key bei zwei Geräten
- Interfaces: Netz an der Site des Hosts; `ipv4` braucht ein Netz, `address` je nach Modus, im Präfix, nicht Netz-/Broadcast-Adresse, statisch außerhalb des Pools, je Netz eindeutig; `reserved` braucht `mac` und einen `dhcpServer`; MAC eindeutig und kein Multicast; `eui64` braucht eine MAC und keine private WLAN-MAC
- Netze: Präfix ohne Host-Bits; Pool im Präfix, Start ≤ Ende, nur mit `ipv4` und `dhcpServer`; `dhcpServer` an der Site und mit Interface im Netz; VLAN-ID je Site eindeutig

```
hosts.app.runsOn: a vm cannot run on nas (kind nas; allowed: hypervisor)
hosts: runsOn/inside/power form a cycle through pve, ups1
hosts.laptop.managed: true, but flake.nix has no configuration of that name
hosts.router.interfaces.lan.ipv4.address: 192.0.2.150 is static but inside the DHCP pool of network lan
networks.lan.vlan: 20 is also used by networks.iot at site home
hosts.router.sshHostKeys[0]: same key as hosts.nas.sshHostKeys[0] - a cloned machine that kept its host key?
```

**3. Entsperr-Ketten** – siehe [Entsperren](#entsperren):

```
hosts.nas.unlock: never unlocks unattended - none of its Tang servers (vps) comes up without a human
```

**Getrennt davon**, als eigener Check, weil er `ssh-to-age` braucht: `checks.inventory-sops` (siehe [SSH-Host-Keys](#ssh-host-keys)).

```
hosts.cuckoosegg: host key gives age1z9rt…, .sops.yaml has age1z8uz… - host key changed without sops updatekeys, or a wrong key in inventory.json
```

Das Schema in `inventory.schema.json` deckt nur Stufe 1 ab (ohne Referenzen) und ist für den Editor da; maßgeblich ist die Prüfung in `inventory.nix`. Die Fehlermeldungen sind wie der Code englisch.

## Abgeleitete Sicht

`lib.inventory.inventory` (auf der Konsole: `just inventory`) ist das geprüfte Inventar mit allem Abgeleiteten. Jeder Eintrag bekommt seine `id`, dazu:

| Abschnitt | Abgeleitet |
| --- | --- |
| `owners.<id>` | `hosts` – die Hosts, die er administriert |
| `uplinks.<id>` | `sites` – die Sites an diesem Anschluss |
| `sites.<id>` | `hosts` – alles dort, geerbte Sites eingeschlossen |
| `hosts.<id>` | `site` (wirksam, geerbt entlang `runsOn`/`inside`), `virtual`, `uplinks` (seiner Site, primärer zuerst), `guests`, `contains`, `powers`, `managedBy`, `tangClients`, `upstream` (transitiv, nächster zuerst), `unattendedBoot` |
| `hosts.<id>.interfaces.<name>` | `name`, `vlan` (aus seinem Netz), `ipv6LinkLocal` (bei `eui64` berechnet, bei fester Adresse wie eingetragen, sonst `null`) |
| `pending` | jede Platzhalter-MAC, die noch ersetzt werden muss; `just inventory-test` gibt die Liste aus |
| `networks.<id>` | `interfaces` – jedes Interface darin (`host`, `interface`, `mac`, `address`, `mode`); `reservations` – was der `dhcpServer` per MAC vergeben muss (`host`, `interface`, `mac`, `address`), nach Adresse sortiert |

Neben `inventory`: `lib.inventory.knownHosts` (der Wert für `programs.ssh.knownHosts`) und `lib.inventory.knownHostsFile` (dasselbe als known_hosts-Text).

Optionale Felder sind in der abgeleiteten Sicht immer vorhanden: Standardwerte eingesetzt (`criticality`, `availability`, `unlock.threshold`), sonst `null` bzw. `[]`. Wer sie nutzt, braucht nie ein `or`.

Ist das Inventar ungültig, wirft `inventory` mit **allen** Fehlern auf einmal; `lib.inventory.errors` ist die Liste selbst (leer, wenn gültig).

## Beispiele

Die Beispiele sind das Testinventar aus `tests/inventory.nix`, als JSON geschrieben. Es deckt jedes Feld und jede Beziehung ab.

**Gemietete VM** – virtuell, der Hypervisor des Anbieters steht nicht im Inventar:

```json
"vps": { "kind": "vm", "site": "dc", "owner": "lab", "managed": true, "criticality": "core" }
```

**VM auf dem Hypervisor anderer, der an einer USV hängt** – `site` wird von `pve` geerbt:

```json
"pve":  { "kind": "hypervisor", "site": "home", "owner": "club", "managed": false, "power": "ups1" },
"ups1": { "kind": "ups", "site": "home", "owner": "lab", "managed": false },
"app":  { "kind": "vm", "runsOn": "pve", "owner": "lab", "managed": true,
          "unlock": { "methods": ["nbde"], "tang": ["nas"] } }
```

Abgeleitet für `app`: `site` = `home`, `upstream` = `["pve", "ups1"]`, `unattendedBoot` = `true` (über die Kette app → nas → vps).

**NAS mit TPM und Tang gemeinsam, darin eine PCIe-KVM-Karte:**

```json
"nas": { "kind": "nas", "vendor": "Example Corp", "model": "Example NAS", "productId": "EX-1000",
         "serial": "NAS0001", "site": "home", "owner": "lab", "managed": true,
         "unlock": { "methods": ["tpm", "nbde"], "threshold": 2, "tang": ["vps"] } },
"kvmcard": { "kind": "kvm", "inside": "nas", "power": "nas", "manages": ["nas"],
             "owner": "lab", "managed": false }
```

Abgeleitet für `nas`: `contains`, `powers` und `managedBy` = `["kvmcard"]`, `tangClients` = `["app"]`.

**Laptop** – offline ist normal, nur ein Mensch entsperrt:

```json
"laptop": { "kind": "laptop", "site": "home", "owner": "lab", "managed": true,
            "availability": "intermittent", "unlock": { "methods": [], "fallback": "console" } }
```

**Netze, eine Reservierung und ein Router** – der Router vergibt die Adresse von `nas` per MAC; seine eigene ist statisch, außerhalb des Pools:

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

Abgeleitet: `networks.lan.reservations` = `nas/eno1` (192.0.2.10) und `app/ens18` (192.0.2.11); `nas.interfaces.eno1.ipv6LinkLocal` = `fe80::5054:ff:fe12:3456`; known_hosts-Namen für `nas` = `nas`, `nas.peer.example`, `192.0.2.10`.

**Site mit Hauptanschluss und LTE-Backup:**

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

**Woanders lesen.** In Nix (eine weitere Flake-Ausgabe, ein Modul über `specialArgs`):

```nix
self.lib.inventory.inventory.hosts.app.upstream   # [ "pve" "ups1" ]
```

In OpenTofu – die Rohdaten, ohne abgeleitete Werte und ohne Prüfung (die bleibt bei `nix flake check`):

```hcl
locals {
  inventory = jsondecode(file("${path.module}/../../inventory.json"))
  servers   = [for id, h in local.inventory.hosts : id if h.managed]
}
```

## Tests

`tests/inventory.nix` enthält ein vollständiges, erfundenes Inventar (die Beispiele oben) und 72 Fälle. Jeder Fall ändert genau eine Sache und nennt die erwarteten Fehler – exakter Wortlaut und Reihenfolge – oder, bei gültigen Varianten, Werte der abgeleiteten Sicht. Ein Fall schlägt auch fehl, wenn ein kaputtes Inventar `.inventory` nicht werfen lässt.

| Gruppe | Deckt ab |
| --- | --- |
| gültig | Basisinventar mit allen abgeleiteten Werten; Container auf einer VM; Tang-Schleife durch `threshold` 1 aufgelöst; Flake-Abgleich abgeschaltet |
| Uplinks | IPv6-Präfixlänge außerhalb des Bereichs, IPv6-Details ohne IPv6 |
| Struktur | Unbekannter/fehlender Top-Level-Schlüssel, Tippfehler im Feldnamen, Enum, Pflichtfeld, Typ, Mindestwert, Referenz ins Leere und in den falschen Abschnitt, ungültige ID, Duplikate |
| Regeln | `runsOn` auf Nicht-Virtuellem und auf falscher Art, `runsOn` + `inside`, `manages` außerhalb eines KVM und auf sich selbst, Selbstbezug, Zyklus, fehlende/nicht erbbare/widersprüchliche `site`, Site ohne Uplink, unbenutzte Einträge, Inventar ≠ Flake |
| Entsperren | Kein Weg zum Entsperren, `threshold` zu hoch oder ohne Methoden, `nbde` ohne `tang` und umgekehrt, eigener Tang-Server, Tang-Schleife, Tang-Server, der auf einen Menschen wartet |
| Hardware | `vendor`/`serial` bei einer VM, `model` bei einer VM erlaubt, Seriennummer doppelt; abgeleitete Hardware-Felder und Standardwerte |
| SSH-Keys | Falsches Format, mit Kommentar, Key-Daten eines anderen Typs, derselbe Key bei zwei Hosts; abgeleitete known_hosts-Einträge und -Datei |
| Interfaces | MAC-Format, Interface-Name, Link-Local-Wert, MAC doppelt, Multicast-MAC, `eui64` aus privater WLAN-MAC und ohne MAC, Netz an anderer Site, `ipv4` ohne Netz, Adresse je Modus, reserviert ohne MAC oder DHCP-Server, Adresse außerhalb/Broadcast/im Pool/ohne Präfix/doppelt; abgeleitetes Link-Local (EUI-64 einer QEMU-MAC, fest, zufällig) und VLAN |
| Netze | Präfix-Format, VLAN-Bereich und Duplikat je Site (dieselbe ID an anderer Site erlaubt), Host-Bits, Pool außerhalb/rückwärts/ohne Server, DHCP-Server ohne Interface oder an anderer Site; abgeleitete Reservierungen |

```
just inventory-test
```

baut `checks.<system>.inventory` (die echte Datei ist gültig), `inventory-tests` (alle Fälle bestehen) `inventory-schema` (Schema aktuell) und `inventory-sops` (Host-Keys ↔ `.sops.yaml`). Bei einem Fehler listet die Meldung jeden fehlgeschlagenen Fall mit „want“ und „got“.

**Eine neue Regel** bekommt im selben Commit einen Fall: in `base` mit `set`/`del` genau eine Sache ändern, die exakte Meldung eintragen. **Geänderter Wortlaut** einer Meldung lässt die Tests fehlschlagen – Fall und diese Seite zusammen anpassen.

## Abläufe

| Was | Schritte |
| --- | --- |
| Neuer Host / neues Gerät | Eintrag in `inventory.json` (bei einem Flake-Host `"managed": true` – sonst schlägt `nix flake check` ohnehin fehl), `just inventory-collect`, `network`/`ipv4` von Hand, `just inventory-test` |
| Host-Key geändert (Neuinstallation) | `just inventory-collect --force <host>`, `.sops.yaml` + `sops updatekeys` (siehe [Schlüssel rotieren](../how-to/key-rotation.md)), deployen, `just known-hosts` |
| Neue DHCP-Reservierung | Interface mit `mac`, `network`, `ipv4.mode: reserved` + `address`; die Liste für den Router: `networks.<id>.reservations` in `just inventory` |
| Details eines Anschlusses nachtragen | Felder in `uplinks.<id>`, sonst nichts zu tun |
| Neues Feld oder neue Geräteart | `spec` in `inventory.nix`, dann `just inventory-schema`, ein Testfall in `tests/inventory.nix`, diese Seite (de/en) |
| Ansehen | `just inventory` |
