# Secrets, Netzwerk & Zugriff

## Secrets (sops-nix, age)

Jede Host-Datei ist für genau zwei Empfänger verschlüsselt: den age-Key aus dem SSH-Host-Key des Hosts und den Offline-Recovery-Key `admin`. Das MacBook kann Host-Secrets also nicht lesen – `just secrets <host>` editiert sie auf dem Host und holt das Ergebnis zurück. Verschlüsseln für einen Host geht dagegen überall (nur der öffentliche Key ist nötig); genau das nutzen `netbird-key` und `desec-key`.

| Datei | Empfänger | Inhalt |
| --- | --- | --- |
| `hosts/<host>/secrets.yaml` | Host + admin | Deploy-Key, App-Passwörter, OIDC-Clients, restic |
| `hosts/<host>/netbird.yaml` | Host + admin | NetBird-Setup-Key (von Tofu) |
| `hosts/<host>/desec.yaml` | Host + admin | deSEC-Token (von Tofu) |
| `hosts/<host>/github.yaml` | Host + admin | GitHub-Deploy-Key (von `just github-key`) |
| `hosts/<host>/waf.yaml` | Host + admin | Schlüssel des WAF-Bouncers (von `just waf-key`, siehe [WAF](waf.md)) |
| `terraform/*/secrets.yaml` | workstation + admin | API-Tokens für die Provider |

Der Workstation-Key liegt in 1Password und wird über `SOPS_AGE_KEY_CMD` gelesen, nie als Datei. `env.sh` in jedem Tofu-Modul entschlüsselt die Tokens in nicht exportierte Variablen der Shell des jeweiligen Rezepts: Nur der `tofu`-Prozess bekommt sie in seine Umgebung (`tf_env` und `tf_tofu` in `terraform/lib.sh`) und von ihm die Provider-Plugins des Moduls – nicht `jq`, `curl`, `git`, `ssh` oder `sops`, die das Rezept ebenfalls aufruft (admin/nixlab#474). Kein Modul hat einen `local-exec`-Provisioner oder eine `external`- oder `http`-Datenquelle, die sie weiterreichen würde.

## Netzwerk

- **NetBird-Mesh** (`192.0.2.0/24` und `2001:db8:203:0::/64`, Peer-Namen unter `peer.homelab.example`): Control Plane auf grammi, Login über Pocket ID. Private Range (RFC 1918) statt CGNAT, weil tailscaled Pakete aus 100.64/10 verwarf, solange beide Clients parallel liefen; ein Umnummerieren würde heute jeden Peer verschieben.
- **Gruppen:** `servers` (alle Hosts außer cuckoosegg), `subraum-devices`, `remote-devices` (gw-remote, [Standort-Gateway](site-gateway.md)), `admin-workstations` (MacBook), dazu Personengruppen aus Pocket ID.
- **Heim-LAN** (`198.51.100.0/24`): Route über ursalia (Metrik 100), die beiden Apple TVs als Rückfall (Gruppe `home-routers`, Metrik 200, eigener Setup-Key per `just netbird-router-key`, keiner Person zugeordnet, in keiner Policy); für Gruppe `home-lan`, nicht für Geräte, die schon zu Hause sind (Posture-Check `not-at-home`). Rosenpass ist seit 2026-10-24 im ganzen Mesh aus (bis 2026-10-31, siehe [macOS-Hosts](macos-hosts.md#netbird-auf-den-beiden-macs)); „Quantum-Resistance“ in der App der Apple TVs gehört für diese Zeit ebenfalls aus.
- **Reiserouter** (Mudi 7, GL.iNet GL-E5800): Peer `mudi7`, Gruppe `travel-routers`, eigener Setup-Key per `just netbird-key-mudi7`, keiner Person zugeordnet und vorerst in keiner Policy. Das OpenWrt-Paket liefert nur NetBird 0.24.3; das Binary wird von Hand gegen das `linux_arm64`-Release in der Mesh-Version getauscht (`terraform/netbird/travel-router.tf`).
- **TECHO5** (Echo Show 8 mit der TECHO5-Firmware, vorerst das Testgerät „TECHO5 Test“): Gruppe `techo5`, eigener Setup-Key per `just netbird-key-techo5`, einzufügen auf der Setup-Seite des Geräts (Network → NetBird), keiner Person zugeordnet. Home Assistant erreicht die ESPHome-API (TCP 6053), `admin-workstations` Setup-Seite (TCP 8181), SSH und Ping; mehr lässt die Firewall von TECHO5 aus dem Mesh ohnehin nicht herein, DNS und Routen aus dem Mesh nimmt das Gerät nicht an. Als oft ausgeschaltetes Testgerät nicht in den erwarteten Peers gezählt (`terraform/netbird/techo5.tf`).
- **Anbindung von ursalia:** seit 2026-11-02 per 2,5G-Kabel (`enp46s0`, `hosts/ursalia/lan.nix`) ins Hauptnetz des Heim-LANs, DHCP ohne Reservierung. Das WLAN (Intel AX211, `modules/home-wifi.nix`) ist aus: Am Flint 4 scheiterte die Anmeldung, weil das 5-GHz-Netz SAE H2E ankündigt und wpa_supplicant dafür die Passphrase in der eigenen Konfiguration braucht, die per `ext_password` aber nicht dort steht („SAE: Could not find PT for group 19“). Ein WLAN als Reserve neben dem Kabel ist bewusst weggelassen: Beide Verbindungen gleichzeitig aktiv hat NetBird auf der M720q schlecht vertragen.
- **Anbindung von zorlock:** ebenfalls WLAN (`en1`, Broadcom); `hosts/zorlock/wifi.nix` stellt sicher, dass `homelab` als bevorzugtes Netz eingetragen ist (`networksetup`, fügt nur hinzu, Passwort per sops in `hosts/zorlock/wifi.yaml`). nix-darwin hat kein WLAN-Modul; die Bandwahl bleibt bei macOS.
- **Exit-Nodes und IPv6:** aldrin und zummi als Exit-Nodes für die Gruppe `exit-nodes`; das Mesh ist Dualstack (`2001:db8:203:0::/64`) – siehe [Exit-Nodes & IPv6](#exit-nodes).
- **Subraum:** Route über cuckoosegg für `subraum-access`. cuckoosegg selbst darf nur grammis Ingest (TCP 8427, vmauth: nur schreiben, nur als es selbst) erreichen und nur vom MacBook per SSH erreicht werden.
- **Subraum-Namen pro Gerät:** Die Domain-Resource `subraum-names` (`*.subraum.hackspace.example`, seit 2026-11-13) gibt `subraum-access`-Geräten außerhalb des Subraums die interne Sicht des Subraum-Routers: A-Records und ULAs statt nur öffentlicher GUAs. Der NetBird-Client schickt die Anfragen an den DNS-Forwarder auf cuckoosegg und routet jede Antwort-Adresse, IPv4 wie IPv6, über cuckoosegg. Standardmäßig ausgewählt; abschalten im Networks-Menü oder mit `netbird networks deselect subraum-names`, dann gilt wieder die öffentliche Sicht. Im Subraum selbst greift der Posture-Check `not-in-subraum`. Die Apex `subraum.hackspace.example` bleibt öffentlich. cuckoosegg nimmt DNS nur per DHCPv4 vom Subraum-Router an, nicht aus Router Advertisements – ein zweites Gerät in VLAN 10 kündigt sich dort als DNS-Server an und liefert keine A-Records.
- **Notzugang bei totem Mesh** (grammi weg, gusto aus dem Mesh): für die Hosts mit öffentlicher Adresse (aldrin, grammi, zummi) über admin auf dem öffentlichen Namen des Hosts zu seiner eigenen Mesh-Adresse springen, `ssh -i ~/.ssh/pub/<host>.homelab.example.pub -J admin@<host>.homelab.example root@<eigene nb-mesh-Adresse>` (die Adresse: `ip -4 -o addr show dev nb-mesh` als admin). root kommt hinein, weil die Verbindung auf der Mesh-Adresse ankommt (`modules/ssh.nix`); ein funktionierendes Mesh braucht es nicht, nur die Adresse noch auf `nb-mesh` – also nicht nach einem Neustart während des Ausfalls. Dann: Provider-Konsole (realtox: aldrin, grammi; IONOS: zummi) mit dem root-Passwort aus `just root-password-show <host>`. Beides am 2026-11-15 geprobt. Tailscale, der frühere Notzugang, ist seit [nixlab#360](https://github.com/admin/nixlab/issues/360) weg.

### Exit-Nodes & IPv6 { #exit-nodes }

aldrin und zummi sind Exit-Nodes: Ein Client kann seinen gesamten Verkehr, IPv4 und IPv6, durch einen der beiden schicken und erscheint im Internet dann mit dessen öffentlicher Adresse. Die beiden stehen bei verschiedenen Providern (realtox in Düsseldorf, IONOS in Berlin), daher zwei getrennte Routen statt einer HA-Route – der Client wählt den Ausgang. Konfiguration: `terraform/netbird/exit-nodes.tf` (Routen, Policy) und `modules/netbird-exit-node.nix` (Hosts).

<figure class="nx-diagram">
<svg viewBox="0 0 680 420" role="img" aria-label="Ein Client der Gruppe exit-nodes schickt seinen gesamten IPv4- und IPv6-Verkehr durch den NetBird-Tunnel entweder an aldrin oder an zummi; der Exit-Node maskiert ihn auf seine öffentlichen Adressen bei realtox bzw. IONOS" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}.nx-blue rect{fill:#e6f1fb;stroke:#185fa5}.nx-blue .nx-t{fill:#042c53}.nx-blue .nx-s{fill:#185fa5}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}</style>
<text class="nx-t" x="16" y="24">Exit-Nodes: ein Client, zwei Ausgänge</text>
<text class="nx-s" x="16" y="42">Der Client wählt einen der beiden, v4 und v6 immer zusammen</text>
<text class="nx-s" x="86" y="72" text-anchor="middle">Client</text>
<text class="nx-s" x="266" y="72" text-anchor="middle">NetBird-Mesh</text>
<text class="nx-s" x="446" y="72" text-anchor="middle">Exit-Node</text>
<text class="nx-s" x="596" y="72" text-anchor="middle">Internet als</text>
<path class="nx-line" d="M156 180 H176"/><path class="nx-line" d="M170 176 L176 180 L170 184"/>
<path class="nx-line" d="M356 180 H366 V120 H376"/><path class="nx-line" d="M370 116 L376 120 L370 124"/>
<path class="nx-line" d="M366 180 V240 H376"/><path class="nx-line" d="M370 236 L376 240 L370 244"/>
<path class="nx-line" d="M516 120 H528"/><path class="nx-line" d="M522 116 L528 120 L522 124"/>
<path class="nx-line" d="M516 240 H528"/><path class="nx-line" d="M522 236 L528 240 L522 244"/>
<a data-target="exit-nodes-use" tabindex="0" role="link" class="nx-teal"><rect x="16" y="145" width="140" height="70" rx="8" stroke-width="1"/><text class="nx-t" x="86" y="168" text-anchor="middle">Client</text><text class="nx-s" x="86" y="185" text-anchor="middle">Gruppe exit-nodes</text><text class="nx-s" x="86" y="202" text-anchor="middle">App oder CLI</text></a>
<a data-target="mesh-ipv6" tabindex="0" role="link" class="nx-gray"><rect x="176" y="135" width="180" height="90" rx="8" stroke-width="1"/><text class="nx-t" x="266" y="159.5" text-anchor="middle">WireGuard-Tunnel</text><text class="nx-s" x="266" y="176.5" text-anchor="middle">192.0.2.0/24</text><text class="nx-s" x="266" y="193.5" text-anchor="middle">2001:db8:203:0::/64</text><text class="nx-s" x="266" y="210.5" text-anchor="middle">0.0.0.0/0 + ::/0</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-blue"><rect x="376" y="90" width="140" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="446" y="108" text-anchor="middle">aldrin</text><text class="nx-s" x="446" y="125" text-anchor="middle">exit-aldrin</text><text class="nx-s" x="446" y="142" text-anchor="middle">NAT44 + NAT66</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-blue"><rect x="376" y="210" width="140" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="446" y="228" text-anchor="middle">zummi</text><text class="nx-s" x="446" y="245" text-anchor="middle">exit-zummi</text><text class="nx-s" x="446" y="262" text-anchor="middle">NAT44 + NAT66</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-coral"><rect x="528" y="90" width="136" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="596" y="108" text-anchor="middle">realtox</text><text class="nx-s" x="596" y="125" text-anchor="middle">203.0.113.11</text><text class="nx-s" x="596" y="142" text-anchor="middle">2001:db8:11::2</text></a>
<a data-target="exit-nodes-hosts" tabindex="0" role="link" class="nx-coral"><rect x="528" y="210" width="136" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="596" y="228" text-anchor="middle">IONOS</text><text class="nx-s" x="596" y="245" text-anchor="middle">203.0.113.10</text><text class="nx-s" x="596" y="262" text-anchor="middle">2001:db8:10::1</text></a>
<a data-target="exit-nodes-who" tabindex="0" role="link" class="nx-gray"><rect x="16" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="118" y="318" text-anchor="middle">Wer darf</text><text class="nx-s" x="118" y="335" text-anchor="middle">Pocket-ID-Gruppe exit-nodes</text><text class="nx-s" x="118" y="352" text-anchor="middle">Policy → exit-node-access</text></a>
<a data-target="exit-nodes-use" tabindex="0" role="link" class="nx-gray"><rect x="238" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="318" text-anchor="middle">Auswahl im Client</text><text class="nx-s" x="340" y="335" text-anchor="middle">skip_auto_apply: aus, bis gewählt</text><text class="nx-s" x="340" y="352" text-anchor="middle">ein Schalter für v4 und v6</text></a>
<a data-target="exit-nodes-monitoring" tabindex="0" role="link" class="nx-gray"><rect x="460" y="300" width="204" height="60" rx="8" stroke-width="1"/><text class="nx-t" x="562" y="318" text-anchor="middle">Zähler → Grafana</text><text class="nx-s" x="562" y="335" text-anchor="middle">nftables, postrouting</text><text class="nx-s" x="562" y="352" text-anchor="middle">Homelab / NetBird</text></a>
<text class="nx-s" x="16" y="390">Ohne Auswahl ändert sich nichts: der Client geht wie bisher über seinen eigenen Anschluss ins Internet.</text>
<text class="nx-s" x="16" y="406">Das Overlay ist ULA; die öffentlichen Adressen kommen erst per Masquerade auf dem Exit-Node dazu.</text>
</svg>
</figure>

#### Wer darf { #exit-nodes-who }

Die Pocket-ID-Gruppe `exit-nodes`. Jemand kommt dazu, indem man ihn in Pocket ID (auth.homelab.example) in die Gruppe aufnimmt; der [Gruppensync](#group-sync) überträgt die Mitgliedschaft innerhalb einer Minute auf die NetBird-Gruppe gleichen Namens und damit auf alle Geräte der Person. Die Policy `exit-nodes` erlaubt nur dieser Gruppe den Weg in die Zugriffsgruppe `exit-node-access` der Routen. Bewusst nicht alle: Wer den Exit-Node nutzt, tritt mit der Adresse des Servers auf.

#### Benutzen { #exit-nodes-use }

Die Routen sind auf jedem Gerät der Gruppe vorhanden, aber aus (`skip_auto_apply`), bis man eine auswählt – in der NetBird-App unter „Exit Node“ bzw. „Networks“, oder per CLI:

```bash
netbird networks select exit-aldrin
```

```bash
netbird networks deselect exit-aldrin
```

Pro Exit-Node gibt es zwei Routen, `exit-aldrin` (`0.0.0.0/0`) und `exit-aldrin-v6` (`::/0`). Ein Client ab 0.81 koppelt sie über den Namen und zeigt sie als einen Eintrag „0.0.0.0/0, ::/0“: Ein Schalter verlegt v4 und v6, kein IPv6 läuft am Exit-Node vorbei über den eigenen Anschluss. Prüfen lässt sich das mit `curl -4 ifconfig.co` und `curl -6 ifconfig.co`.

#### Auf den Hosts { #exit-nodes-hosts }

Routing und NAT richtet der NetBird-Client selbst ein: Masquerade für v4 (NAT44) und v6 (NAT66) auf die öffentlichen Adressen des Hosts, die ACL der Policy in seiner eigenen nftables-Tabelle. `modules/netbird-exit-node.nix` schaltet zusätzlich das Forwarding für beide Familien ein, damit es nicht vom Client abhängt. Reverse-Path-Filter bleibt „strict“.

**Forwarding wird gefiltert** (`modules/forwarding.nix`, #311), auf jedem Host, der routet – aldrin, zummi, ursalia, cuckoosegg: Die Forward-Kette der NixOS-Firewall verwirft standardmäßig und lässt neue Verbindungen entlang der Paare durch, die die jeweilige Rolle nennt, dazu DNAT-Portweiterleitungen und ICMPv6 (außer ins nb-mesh, siehe die Sperrkette unten) (Exit-Node: nb-mesh → öffentliche Schnittstelle; Routing-Peer: nb-mesh → LAN; dazu auf aldrin der gw-remote-Container ins Internet und auf ursalia die Podman-Bridge). Eine eigene Sperrkette verwirft alles Neue *ins* nb-mesh von jeder anderen Schnittstelle, ICMPv6 eingeschlossen. Warum: NetBirds Forward-Kette prüft nur Verkehr, der aus dem Mesh kommt, und NetBird maskiert Verkehr von außen ins Mesh als den routenden Host – vor dem Filter erreichte ein Gerät im Heimnetz, im Subraum oder direkt im Provider-Netz mit einer einzigen Route die Mesh-Peers als dieser Host (mit einem Namespace-Nachbarn auf allen vier Hosts gezeigt). `just test-vm forwarding` prüft das Modul in VMs, `just forward-probe <host>` wiederholt den Nachbar-Test auf dem laufenden Host.

Warum NAT66 und keine öffentlichen Adressen für die Clients: Die Overlay-Adresse eines Clients gilt im ganzen Mesh, unabhängig vom Exit-Node – eine GUA aus aldrins Netz würde über zummi mit fremder Absenderadresse hinausgehen. Außerdem hat keiner der beiden ein geroutetes Präfix: aldrins /64 ist on-link, zummi hat eine /128.

#### Dualstack im Mesh { #mesh-ipv6 }

Seit 2026-10-25 ist das ganze Mesh Dualstack. Jeder Peer bekommt neben seiner Adresse aus `192.0.2.0/24` eine aus der ULA `2001:db8:203:0::/64` (`ipv6_enabled_groups` = All, `terraform/netbird/main.tf`). Peer-Namen unter `peer.homelab.example` und die Dienstnamen (`s3-admin`, `dokumente`, `doku`, `ollama`, `acme`, `terraform/netbird/mesh-services.tf`) haben AAAA neben A; NetBird liefert AAAA nur an Peers, die selbst v6 haben. Die Apple TVs (Client 0.66) bleiben bei v4.

Die Range steht überall neben `192.0.2.0/24`: root-SSH (`modules/ssh.nix`), CrowdSec-Whitelist, Doku-Site, garage-ui auf aldrin, Paperless und Samba auf ursalia, Traefiks `trustedIPs` auf grammi, Caddy auf zorlock. `admin-peers.json` führt pro Gerät v4 und v6. Wer eine neue Allowlist für das Mesh anlegt, trägt beide Ranges ein.

Wechseln die Gruppen in `ipv6_enabled_groups`, vergibt NetBird neue v6-Adressen. Die AAAA-Einträge der Dienste liest Tofu beim Plan; nach so einem Wechsel oder für einen neu registrierten Peer braucht es deshalb ein zweites `just netbird-apply`.

#### Monitoring { #exit-nodes-monitoring }

Jeder Exit-Node zählt den weitergeleiteten Verkehr je Familie und Richtung in einer eigenen nftables-Tabelle und gibt ihn als `netbird_exit_node_bytes_total` / `netbird_exit_node_packets_total` an den node_exporter. Im Dashboard „Homelab / NetBird“ zeigt der Abschnitt „Exit nodes“ Durchsatz und Volumen. Die Zähler hängen an `postrouting`, nicht an `forward`: Der NetBird-Client setzt `iifname nb-mesh accept` an den Anfang jeder fremden Forward-Chain, Zähler dahinter würden nie erreicht.

#### Provider aus PR #215 { #netbird-provider-pr215 }

Der veröffentlichte NetBird-Provider (v0.0.10) kennt `ipv6_enabled_groups` und `network_range_v6` nicht und setzt sie bei jedem Apply der Account-Settings zurück ([#243](https://github.com/netbirdio/terraform-provider-netbird/issues/243)). Bis [PR #215](https://github.com/netbirdio/terraform-provider-netbird/pull/215) veröffentlicht ist, baut `pkgs/terraform-provider-netbird.nix` den Provider aus diesem PR, und `terraform/netbird/env.sh` setzt ihn per `dev_overrides` ein; Tofu warnt deshalb bei jedem Lauf. Rückbau: Paketdatei, ihre Zeilen in `pkgs/default.nix` und in `ownPlatforms` (`flake.nix`) und Block in `env.sh` entfernen, `tofu init -upgrade` ([offener Punkt](../project/open-items.md)).

### DNS mit AdGuard Home { #adguard }

AdGuard Home auf ursalia (`hosts/ursalia/adguardhome.nix`, seit 2026-11-01) filtert DNS für das Heim-LAN und für alle Personengeräte im Mesh. Upstream ist dieselbe DoT-Verbindung zu Freifunk München wie auf allen Hosts. Ausgewählt gegen Pi-hole (kann kein DoT zum Upstream ohne Zusatzdienst) und Technitium (Konfiguration nur über UI/API, liegt in `/var/lib` statt in der Flake).

| Wer | Wie | Protokoll |
| --- | --- | --- |
| Heim-LAN | Der Flint 4 verteilt ursalia per DHCP als DNS-Server | DNS auf 53 (per nftables auf 5354 umgeleitet), DoT/DoQ auf 853 (`dns.homelab.example`), DoH über nginx (`https://dns.homelab.example/dns-query`) |
| Personengeräte im Mesh (`homelab`, `homelab_admins`) | NetBird-Nameserver-Gruppe `adguard`, primär (`terraform/netbird/nameservers.tf`) | DNS auf 5354 über die Mesh-Adresse (Policies `to-dns-udp`/`to-dns-tcp`, nur ursalia); die Strecke läuft in WireGuard |
| Server, Apple TVs, cuckoosegg, Home Assistant | gar nicht – eigene Resolver-Policy bzw. der Router | – |

- **Port 5354 statt 53:** resolveds Stub belegt `127.0.0.53:53`, AdGuard kann daneben kein TCP auf `0.0.0.0:53` öffnen. Den Stub abschalten geht nicht (NixOS lässt `/etc/resolv.conf` auf ihn zeigen), feste Adressen bräuchten die Mesh-IP im Repo und `ip_nonlocal_bind` für den ganzen Host. Darum: AdGuard auf 5354, im LAN leitet nftables 53 dorthin um, die NetBird-Gruppe nutzt 5354 direkt. Auf ursalia selbst testen mit `dig @127.0.0.1 -p 5354`.
- **Mesh-Namen** (`peer.homelab.example`, die Zonen aus `mesh-services.tf`) beantwortet der NetBird-Client selbst, sie erreichen AdGuard nie.
- **Subraum-Namen** (`*.subraum.hackspace.example`) gehen, solange die Resource `subraum-names` ausgewählt ist, an den Forwarder auf cuckoosegg statt an AdGuard – siehe oben.
- **Namen des Routers:** `doku.homelab.example`, `mqtt.homelab.example` und `.lan` gibt AdGuard an den Flint 4 weiter, nur für das LAN – siehe [unten](#adguard-router-names).
- **ursalia selbst** löst nicht über AdGuard auf, sondern direkt über den Router (DHCP-DNS ignoriert): ein Ausfall von AdGuard darf ursalias NetBird und die Route ins Heim-LAN nicht mitnehmen.
- **Konfiguration nur aus Nix** (`mutableSettings = false`): Änderungen in der UI sind nach einem Neustart weg. Die UI ist für Abfrageprotokoll (7 Tage), Statistik und kurzfristiges Freischalten.
- **Admin-UI** über `adguard.homelab.example`: Reverse Proxy mit SSO für `homelab_admins`, danach AdGuards eigener Login (Benutzer `admin`). Beides: Den Listener auf ursalia (Port 8096) erreichen außer dem Proxy auch die Admin-Workstations (alle Ports), und AdGuard soll nicht davon abhängen, dass die Policies so eng bleiben – ohne eigenen Login stünde es jedem offen, der den Port direkt anspricht.
- **Passwort:** Klartext nur in 1Password, ursalia bekommt nur den bcrypt-Hash (`hosts/ursalia/adguardhome.yaml`), den AdGuard beim Start in seine Konfiguration einsetzt. Neues Passwort: `just adguardhome-password`, in 1Password ablegen, committen, ursalia deployen.
- **Break-Glass** ohne Pocket ID und Proxy: `ssh -L 3020:127.0.0.1:3020 root@ursalia.peer.homelab.example`, dann `http://127.0.0.1:3020` mit dem Passwort aus 1Password.
- **Ausfall von ursalia im Mesh:** NetBird versucht AdGuard noch etwa eine Minute lang, weicht dann auf das DNS des Geräts aus und kehrt von selbst zurück, sobald AdGuard wieder antwortet (getestet 2026-11-01 mit dem iPhone: AdGuard 2 min gestoppt, Seiten luden weiter, gut 20 s nach dem Neustart wieder bei AdGuard). Ein Ausfall kostet also das Filtern, nicht die Namensauflösung. Im LAN gibt es keinen solchen Rückfall, solange der Flint 4 nur ursalia verteilt.
- **Am Flint 4 von Hand:** DHCP-Option DNS auf ursalias LAN-Adresse; IPv6-DNS (RA/DHCPv6) prüfen – solange der Router sich dort selbst ankündigt, fragen Dualstack-Geräte teils an AdGuard vorbei. Für IPv6 hat ursalia eine feste Adresse im ULA des Heimnetzes, `<ULA-/64>::53` auf dem Kabel (aus `sites.home.ipv6Ula` und `ipv6SubnetId` abgeleitet, `hosts/ursalia/adguardhome.nix`); das OpenWrt-Image von gruffi (`openwrt/gruffi/`) soll genau diese ankündigen. ursalia selbst übernimmt angekündigte DNS-Server weder per DHCPv4 noch per RA/DHCPv6. Home Assistant behält den Router als DNS.

#### Namen des Routers: bedingte Weiterleitung { #adguard-router-names }

Manche Namen beantwortet der Router selbst mit einer LAN-Adresse (lokaler Eintrag), damit sie zu Hause direkt und auch ohne Internet funktionieren – etwa `mqtt.homelab.example` → Home Assistant. Seit AdGuard der DNS-Server im LAN ist, fragt kein Gerät mehr den Router direkt. AdGuard reicht diese Namen deshalb an den Router weiter (*Conditional Forwarding*), statt die Adressen selbst zu kennen:

```nix
upstream_dns = [
  "tls://dot.ffmuc.net"                                   # alles andere
  "[/doku.homelab.example/mqtt.homelab.example/lan/]198.51.100.1"  # diese Namen: der Router
];
```

- **Syntax:** `[/name1/name2/]server` gilt für die genannten Namen *und alle Unternamen*; der spezifischste Treffer gewinnt. `[/sub.name/]#` nimmt einen Unternamen wieder aus (zurück zum normalen Upstream).
- **Reihenfolge einer Anfrage:** Rewrites in AdGuard (hier nur `dns.homelab.example`) → Blocklisten → Cache → passender Upstream. Gefiltert wird also auch, was zum Router geht.
- **Warum Weiterleiten statt Rewrite:** Die Einträge bleiben an *einer* Stelle, im Router. Keine IP doppelt im Repo, Änderungen am Router wirken sofort – bis auf den Cache: AdGuard hält die Antwort für ihre TTL; ungeduldig: UI → Settings → DNS settings → Clear cache.
- **Nur fürs LAN:** Für die Mesh-Bereiche (`192.0.2.0/24`, `2001:db8:203:0::/64`) gibt es in AdGuard einen festen Client „NetBird mesh“ mit eigenen Upstreams – nur ffmuc. Eigene Upstreams eines Clients *ersetzen* die globale Liste ganz, die Weiterleitungszeile fehlt dort also. Ein Handy unterwegs bekommt für `mqtt.homelab.example` die öffentliche Antwort (Reverse Proxy) statt 198.51.100.168, das es dort nicht erreicht.
- **Reverse-Lookups** (PTR für private Adressen) gehen per `local_ptr_upstreams` ebenfalls an den Router, der die DHCP-Namen kennt; private PTR-Anfragen verlassen das Haus nie.

**Einen neuen lokalen Namen anlegen:**

1. Eintrag am Router (Flint 4) anlegen.
2. Den Namen in die Weiterleitungszeile in `hosts/ursalia/adguardhome.nix` aufnehmen, ursalia deployen. AdGuard weiß nicht von selbst, welche Namen der Router überschreibt – ohne diesen Schritt kommt im LAN die öffentliche Antwort.
3. Prüfen, im LAN und im Mesh:

```bash
dig +short mqtt.homelab.example @ursalia.peer.homelab.example -p 5354
```

Das Gegenstück in NetBird sind Nameserver-Gruppen mit `domains` (Match-Domains): dieselbe Idee eine Ebene höher, pro Peer-Gruppe statt pro Client-Adresse.

#### Clients hinter gruffi: Client-Erkennung per ECS { #adguard-ecs }

Fragt ein Forwarder AdGuard im Auftrag seiner Clients, sieht AdGuard nur den Forwarder: Query-Log, Statistik, Regeln und Upstreams pro Client gelten dann für ihn. Für die IoT-Gruppen, die über gruffis dnsmasq auflösen sollen (nixlab#105, Option 4a′), nimmt AdGuard die Client-Adresse deshalb aus einem EDNS-Client-Subnet-Feld (ECS), das dnsmasq anhängt (`add-subnet=32,128`).

- **Gepatchtes AdGuard Home:** `use_client_addr_from_ecs` gibt es noch in keinem Release. ursalia betreibt AdGuard Home aus nixpkgs mit sechs Patches (`pkgs/adguardhome-ecs/`, `pkgs.nixlab.adguardhome-ecs`). Das ist ein dauerhaftes Override, kein [Hotfix](../how-to/hotfix.md); nixlab#416 verfolgt, es zu entfernen, sobald AdGuard Home die Option selbst hat.
- **Nur von vertrauenswürdigen Absendern:** AdGuard glaubt ECS nur von `trusted_proxies` (Loopback für nginx und gruffis Adresse im Server-Netz) und nur mit Host-Präfix (`/32`, `/128`). ECS von allen anderen wird ignoriert und entfernt, ein Client kann sich also nicht als ein anderer ausgeben. gruffi muss genau von der vertrauenswürdigen Adresse aus senden (`server=<AdGuard>@<Adresse>`): Von jeder anderen Adresse erscheinen seine Anfragen als gruffi, nicht als die Geräte. gruffis dnsmasq braucht dazu `strip-subnet`, sonst reicht er ein ECS-Feld weiter, das der Client selbst mitgeschickt hat.
- **Nicht weitergereicht:** AdGuard entfernt das genutzte ECS-Feld vor dem Weiterleiten, LAN-Adressen kommen also nie bei ffmuc an. Ohne diesen Patch reicht AdGuard ECS unverändert weiter, auch bei ausgeschaltetem `edns_client_subnet` (gemessen, nixlab#105).
- **dnsmasq-Cache:** Mit `add-subnet` beantwortet dnsmasq 2.93 nichts aus seinem Cache. Zwischen Clients wird also keine Antwort geteilt, und jede Anfrage landet in AdGuards Log. `cachesize=0` ist nicht nötig.
- **Direkte Clients** (alle Netze, die AdGuard selbst fragen, das Mesh) sind nicht betroffen.

**Credits:** Die Option stammt von elkrammer (Mauricio Massa), AdguardTeam/AdGuardHome#8571 ([0ebb59f](https://github.com/elkrammer/AdGuardHome/commit/0ebb59f02e9aa4593b2c64c61d34255beb6d2a0c), [1d449c0](https://github.com/elkrammer/AdGuardHome/commit/1d449c0460489a3affda5df80f6451bf6caf6b5f), [19e67b4](https://github.com/elkrammer/AdGuardHome/commit/19e67b4a25e6f92955551bfbddaffbc00fda4e1e)). Die Prüfung auf vertrauenswürdige Absender, die Host-Präfix-Regel und die Upstreams pro Client ([709e201](https://github.com/admin/AdGuardHome/commit/709e201890bdf0ea18516c422e224c265be0c78f), in #8571 gemergt) sowie das Entfernen vor dem Weiterleiten ([b18395b](https://github.com/admin/AdGuardHome/commit/b18395bd9b0ef862ec3dfd1303f77c7a3699ea68)) und von ECS nicht vertrauenswürdiger Absender ([7891212](https://github.com/admin/AdGuardHome/commit/7891212c64491928a488be88bd5c61ba470ee073)), beide elkrammer/AdGuardHome#2, sind von uns.

## Zugriff

Öffentlich offen sind nur 22/80/443. root-SSH lässt `modules/ssh.nix` nur auf der Mesh-Adresse des Hosts zu (auch über den admin-Sprung oben); jeder Host hat ein eigenes Login-Keypair. Mesh heißt dabei beide Ranges, `192.0.2.0/24` und `2001:db8:203:0::/64` ([Dualstack](#mesh-ipv6)).

### Wer erreicht die Server { #to-servers }

`nb-mesh` ist auf jedem Host eine vertrauenswürdige Schnittstelle; was über das Mesh an einen Server darf, entscheiden allein die NetBird-Policies (`terraform/netbird/main.tf`). Seit 2026-11-01 (Risikoregister R9) sind sie nach Herkunft aufgeteilt – Policies können nur erlauben, also aufteilen statt abziehen:

| Policy | von | an | erlaubt |
|---|---|---|---|
| `to-servers` | Personen-Geräte (`homelab`, `homelab_admins`) | alle Server | TCP 80, 443 |
| `to-smb` | Personen-Geräte | ursalia (Gruppe `smb-servers`) | TCP 445 |
| `admin-to-servers` | `admin-workstations` (gusto) | alle Server | alles |
| `servers-to-servers` | `servers` | alle Server | TCP 443 |
| `servers-telemetry` | `servers` | grammi (Gruppe `telemetry-sink`) | TCP 8427 (vmauth) |
| `icmp-own` | jeder eigene Peer (Server, Personen-Geräte, gusto, Home Assistant, Apple TVs, gruffi, TECHO5, NanoKVM, Reiserouter) | dieselben, in beide Richtungen | ICMP |
| `icmp-foreign` | cuckoosegg, gw-remote | alle Server, in beide Richtungen | ICMP |

Personen-Geräte erreichen damit nur die Web-Eingänge (nginx, Traefik, Caddy mit ihren eigenen Regeln) und die Samba-Freigabe – nicht mehr SSH, Exporter, Garages Admin-API, VictoriaMetrics/-Logs oder Traefiks `apps`-Entrypoint. `homelab_admins` bekommt nicht mehr als `homelab`: Admin ist ein in `admin-workstations` benanntes Gerät, kein Login. Ping geht seit 2026-11-15 zwischen allen eigenen Peers, IPv4 und IPv6; cuckoosegg und gw-remote, die auf fremd administrierter Hardware laufen bzw. fremde Netze anbinden, pingen nur die Server und erfahren von keinem anderen Peer. ICMP ganz statt nur Ping, weil eine NetBird-Regel nicht nach ICMP-Typ filtern kann.

Der Reverse Proxy braucht keine dieser Policies: NetBird erlaubt seinen Peers den Port jedes Dienst-Ziels von selbst (`management/server/types/legacynmap/proxy_policies.go`, 0.81.0). Eigene Policies haben weiter cuckoosegg und gw-remote (nur 8427 auf grammi, dazu ICMP), Home Assistant und die Exit-Nodes. Zwischen den Servern ist seit 2026-11 nur offen, was sie nutzen ([nixlab#14](https://github.com/admin/nixlab/issues/14)): 443 für ursalia → zorlock (Ollama), aldrin → ursalia (Immich-Freigabelinks) und grammi → zummi (Pocket ID für den Gruppen-Sync), dazu der Ingest. Garage S3, die Pocket-ID-Logins und den NetBird-Management-Server erreichen die Server über deren öffentliche Adressen; Deploys kommen von den Admin-Arbeitsplätzen.

Prüfen von einem Gerät nur in `homelab` (MacBook Pro, iPhone): `nc -zv grammi.peer.homelab.example 443` verbindet, `nc -zv grammi.peer.homelab.example 8090` und `… 8427` laufen in den Timeout. Von einem Server, z. B. aldrin: 443 auf einem anderen Server und 8427 auf grammi verbinden, 22 und 8090 laufen in den Timeout.

### Apps auf grammi: nur über Traefik `:8090`

Mealie, Grist, logchef und Grafana lauschen auf grammi nur auf `127.0.0.1`. Der Reverse Proxy erreicht sie über den Traefik-Entrypoint `apps` (Port 8090), der vor jede App Wartungsschalter und Fehlerseiten setzt ([Wartungsmodus](../how-to/maintenance.md)). VictoriaMetrics und VictoriaLogs ebenso; die anderen Hosts erreichen sie nur über vmauth auf 8427, und nur zum Schreiben ([Monitoring](monitoring.md)).

**Restlücke:** `:8090` selbst hat keine SSO. Von 2026-10-23 bis 2026-11-01 war das für jeden Mesh-Peer offen, auch für die Geräte aller Personen; seit [`to-servers`](#to-servers) auf 80/443 eingeschränkt ist, erreichen den Port nur noch der Proxy, die Admin-Geräte und – bis [`servers-to-servers`](#to-servers) 2026-11 auf 443 eingeschränkt wurde – die anderen Server. Ganz zu wird er erst, wenn der Proxy per `direct_upstream` auf Loopback zugreifen kann ([offener Punkt](../project/open-items.md)).

### Private Doku: Admin-Geräte, Heimnetz, Login

Die private Fassung dieser Doku (`doku.homelab.example`, auf aldrin und ursalia) enthält jede interne Adresse und beschreibt, wie das Lab betrieben wird. Das ist mehr, als jedes Gerät im Mesh sehen muss. Deshalb liefert nginx sie nur an die Mesh-Adressen der Admin-Geräte aus; alle anderen bekommen 403 – mit einer eigenen Seite, die sagt, warum, von welcher Adresse die Anfrage kam und wie man ein Gerät freischaltet (ohne Navigation, damit die Seitentitel nicht sichtbar werden). Der Name selbst löst für alle Peers auf.

**Von außen** führt derselbe Name auf die öffentliche, anonymisierte Doku (GitHub Pages): Öffentlich ist `doku` ein CNAME auf den Reverse Proxy, dessen Dienst `doku` ohne Login an einen Listener auf aldrin (Port 8091, nur Mesh) weiterreicht, der nur eine Weiterleitung kennt. Wer im Mesh ist, kommt über die NetBird-Zone direkt zu aldrin und ursalia.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Extern oder NetBird aus | Reverse Proxy (grammi) → aldrin:8091 | 301 auf die öffentliche Doku |
| Im Mesh, Gerät in `admin-workstations` | direkt aldrin/ursalia | private Doku |
| Im Mesh, anderes Gerät | direkt aldrin/ursalia | 403-Seite |
| Extern, `doku.homelab.example/login` | aldrin:8091 → 302 auf `doku-login.homelab.example` → Reverse Proxy mit SSO (`docs-readers`) → aldrin:8094 | private Doku |
| Heimnetz, über den eigenen Eintrag des Routers | direkt ursalias LAN-Adresse | private Doku, außer Geräten auf der Deny-Liste |

**Login aus dem Internet** (entschieden 2026-10-23): für ein Gerät ohne NetBird, etwa einen Firmenlaptop. `doku.homelab.example/login` führt auf `doku-login.homelab.example`, einen eigenen Dienst im Reverse Proxy mit SSO für die Pocket-ID-Gruppe `docs-readers` – ein eigener Name, weil der Proxy die Anmeldung je Dienst kennt, nicht je Pfad, und SSO auf `doku` selbst die öffentliche Doku dahinter stellen würde. Sein Ziel ist ein Listener auf aldrin (Port 8094), der die private Seite ausliefert. Weil die Admin-Geräte und die anderen Server diesen Port über das Mesh ebenfalls erreichen (bis 2026-11-01 auch die Geräte aller Personen, siehe [`to-servers`](#to-servers)), schickt der Proxy einen geheimen Header (`X-Nixlab-Docs-Key`) mit, und aldrin liefert nur an Anfragen, die ihn tragen; neuer Schlüssel: `just docs-login-key`. Dieser Weg hängt an grammi und zummi – er ist eine Ergänzung, wenn das Mesh nicht zur Hand ist, kein Ersatz dafür.

**Heimnetz** (entschieden 2026-10-23): Der Router zu Hause beantwortet `doku.homelab.example` mit ursalias LAN-Adresse (ein eigener Eintrag, wie bei `mqtt.homelab.example`), und ursalia liefert die private Doku an das ganze Hauptnetz – außer an die Adressen auf einer bewussten Deny-Liste (`services.docsSite.lan` in `hosts/ursalia/configuration.nix`, Inventar-Geräte mit fester Adresse). Eine Deny-Liste nach Adresse erwischt nur Geräte mit reservierter Adresse; Gäste und alles mit wechselnder Adresse kommen hinein. Die Apple TVs gehören darauf, sobald sie eine Reservierung haben: Als NetBird-Ausweichrouter ins LAN maskieren sie Mesh-Peers auf ihre eigene Adresse. Mesh-Geräte betrifft das nicht – für sie löst der Name weiter auf die Mesh-Adressen auf.

**Warum über den Proxy:** So steht `doku` mit den anderen öffentlichen Namen im NetBird-Dashboard, statt als eigener öffentlicher vHost auf aldrin. Der Proxy selbst kann nicht umleiten, nur weiterreichen – daher der Weiterleitungs-Listener. Er hat einen eigenen Port, statt dass der Doku-vHost den Proxy an seiner Adresse erkennt: Der Proxy ist ein eigener Peer, dessen Mesh-Adresse Tofu nicht kennt. Die Verknüpfung von `homelab.example` mit der öffentlichen Doku ist dabei bewusst in Kauf genommen; die echten Adressen bleiben dort weiter ersetzt.

**Wer als Admin-Gerät zählt:** die Geräte der Gruppe `admin-workstations` (`terraform/netbird/subraum.tf`), heute das MacBook – dasselbe Gerät, das auch per SSH an die Subraum-Geräte darf. Bewusst nicht die Personengruppe `homelab_admins`: die füllt sich aus Pocket ID mit *allen* Geräten eines Admin-Users. Heute wären das keine (Calla hat keine eigenen Geräte), und ein Telefon, das sich unter einem Admin-User anmeldet, wäre sofort drin. Admin ist hier ein Gerät, das in Tofu mit Namen steht, nicht eine Anmeldung. Ein weiteres Gerät in `admin-workstations` bekommt damit auch SSH auf die Subraum-Geräte – dasselbe Vertrauen. Tofu liest die Mitglieder bei jedem `just netbird-apply` und schreibt Name → Adresse nach `terraform/netbird/admin-peers.json`; `profiles/docs-site.nix` übergibt die Adressen an `services.docsSite.allow`. Ein neues Admin-Gerät kommt also nach `just netbird-apply`, Commit und Deploy von aldrin und ursalia hinein.

**Warum in nginx und nicht in einer NetBird-Policy:** [`to-servers`](#to-servers) erlaubt den Geräten aller Personen (`homelab` und `homelab_admins`) Port 443 auf allen Servern, und die Doku teilt sich 443 mit allem anderen, was nginx dort ausliefert. Eine Policy wirkt je Port, nicht je vhost. Die Policy entscheidet also, welche Ports ein Gerät erreicht, und nginx, wer die Doku bekommt.

**Warum keine Anmeldung im Mesh (Pocket ID):** Die Doku liest man, wenn etwas kaputt ist. Ein Login hinge sie an zummi (Pocket ID) und, über den Reverse Proxy, an grammi – genau die Hosts, von denen sie unabhängig sein soll. Eine Adressliste braucht zur Laufzeit nichts außer nginx auf dem Host selbst. Der Login aus dem Internet oben ändert daran nichts: Mesh und Heimnetz funktionieren ohne ihn weiter.

**Was das bewusst in Kauf nimmt:**

- Die Liste ist so aktuell wie das letzte `just netbird-apply` mit anschließendem Deploy. Ein neues Admin-Gerät sieht bis dahin 403, ein entferntes Gerät kommt bis dahin noch hinein.
- Die Adresse steht für das Gerät, nicht für die Person: Wer ein Admin-Gerät benutzt, liest die Doku.
- Leer darf die Liste nicht werden – `just netbird-admin-peers` verweigert eine leere Ausgabe, und das Modul bricht den Build mit einer Assertion ab, statt still allen 403 zu geben.
- v4 und v6 je Gerät, wie das Mesh ([Dualstack](#mesh-ipv6)). Die v6-Adresse vergibt NetBird neu, wenn sich die Gruppen in `ipv6_enabled_groups` ändern – dann `just netbird-apply` und Deploy von aldrin und ursalia, sonst sieht das Gerät über v6 ein 403.

### Pocket ID: Admin-Bereich nur von Admin-Geräten { #pocket-id-admin }

Seit 2026-10-25 beantwortet nginx auf zummi die Admin-Pfade von Pocket ID mit 403, außer die Anfrage kommt von einer Adresse aus `admin-peers.json` – derselben Liste wie bei der privaten Doku. Gesperrt ist alles, was eine Admin-Sitzung oder ein Admin-API-Key kann: `/settings/admin`, Nutzer, Gruppen, OIDC-Clients, APIs, API-Keys, Einstellungen, Audit-Log, Signup-Tokens, SCIM (Liste: `$pocketid_admin_path` in `hosts/zummi/pocket-id-nginx.nix`, nach den Berechtigungen der Routen in Pocket ID 2.19.2 – bei jedem Minor-Update prüfen). Login, Konto-Seiten (`/api/users/me…`), OIDC-Endpunkte und Logos bleiben öffentlich. Einzige weitere Ausnahme: lesende Zugriffe des [Gruppensyncs](#group-sync) von grammi. Seit #441 gilt dasselbe für jede Anfrage mit API-Key (`X-API-Key`): Außer von den Admin-Geräten ist sie 403, die Lesezugriffe des Gruppensyncs ausgenommen – ein API-Key hat auch alle Konto-Rechte, und die Konto-Pfade sind öffentlich. Die Regeln prüfen den dekodierten Pfad (`$uri`), den auch Pocket IDs Router sieht; `%`-kodierte Varianten eines Pfads bekommen also dieselbe Antwort und dasselbe Rate-Limit. Test: `just test-vm pocket-id-nginx` (`tests/pocket-id-nginx.nix`), dieselben Regeln vor einem Stub.

Damit die Admin-Geräte mit ihrer Mesh-Adresse ankommen, zeigt eine NetBird-DNS-Zone `auth.homelab.example` nur für `admin-workstations` auf zummis Mesh-Adressen (`terraform/netbird/pocket-id-admin.tf`); der vhost lauscht dafür auf der Wildcard. Alle anderen Peers, auch NetBirds Server auf grammi, behalten den öffentlichen Eintrag.

- Ohne NetBird auf dem Gerät gilt der öffentliche Eintrag: Login geht, der Admin-Bereich antwortet 403. Ein Browser mit eigenem DNS-over-HTTPS umgeht NetBirds DNS ebenso.
- `just pocketid-plan`/`-apply` brauchen deshalb NetBird auf dem MacBook.
- Ein neues Admin-Gerät: in `admin-workstations`, `just netbird-apply`, dann zummi deployen (wie bei der Doku auch aldrin und ursalia).

### Zertifikate: deSEC-Tokens und CAA { #acme-caa }

Jeder Host holt seine Zertifikate per DNS-01 mit einem eigenen deSEC-Token (`terraform/desec-tokens`). Seit 2026-11-15 darf jeder Token nur die `_acme-challenge`-TXT-Records der Namen seines Hosts schreiben (`acme-names.json`, von `just desec-names` aus `security.acme.certs` abgeleitet), sonst nichts; die Tokens der VMs sind zusätzlich an die öffentliche Adresse des Hosts gebunden. Kein Token kann ein Zertifikat für den Namen eines anderen Hosts oder eine Wildcard bekommen.

Dazu CAA (Repo DNSControl, seit 2026-11-15):

- **Pocket ID ist an zummis Konto gebunden:** `auth` ist ein CNAME auf `zummi`, also liest Let's Encrypt die CAA-Records von `zummi.homelab.example` – `issue` nur für Konto `3599937201`, nur `dns-01`, `issuewild ";"`. Selbst mit einem Token, der `_acme-challenge.auth` schreiben darf, braucht ein Zertifikat zummis Kontoschlüssel.
- **Keine Wildcards:** `issuewild ";"` am Apex aller vier Zonen; im Lab nutzt niemand eine.
- **Ein neues ACME-Konto auf zummi bricht die Erneuerung:** Das lego-Kontoverzeichnis hängt an E-Mail, Schlüsseltyp und Server – eine geänderte `security.acme.defaults.email` (`modules/acme.nix`) oder ein verlorenes `/var/lib/acme` registriert ein neues Konto, das CAA ablehnt. Vorher die `accounturi` in DNSControl anpassen. Das Konto liegt in zummis restic-Backup (`pocket-id`).
- **Clients ohne E-Mail sind Absicht:** dns01proxy (Caddy) und der NetBird-Proxy auf grammi haben ihre Konten ohne E-Mail registriert. Let's Encrypt verschickt keine Ablauf-Mails mehr; den Ablauf überwacht der Zertifikats-Exporter (`modules/metrics.nix`), und eine E-Mail nachzutragen würde neue Konten anlegen.
- **Tokens, die CAA noch schreiben können:** `DNSControl` (Workstation, sops) und der Tofu-Bootstrap-Token (`OpenTofu API-Key Management`), der Tokens verwalten darf und damit faktisch Vollzugriff hat (sops, `terraform/desec-tokens/secrets.yaml`). Beide bleiben bewusst so.

### Pocket ID → NetBird: Gruppensync { #group-sync }

Wer in welcher Personengruppe ist, steht nur in Pocket ID (`terraform/netbird/people.tf`). Bis 2026-11-01 kam eine Änderung erst mit dem nächsten `just netbird-apply` in NetBird an – und damit auch erst dann bei den SSO-Gruppenprüfungen des Reverse Proxys. Seitdem gleicht ein Timer auf grammi jede Minute ab (`hosts/grammi/netbird-group-sync.nix`): Für jede Person aus `local.people` setzt er `auto_groups` und `is_blocked` genau so, wie `netbird_user.person` sie berechnet (Personengruppen in Tofus Reihenfolge, in Pocket ID deaktiviert = in NetBird gesperrt). Der nächste Plan zeigt dafür also keine Drift. Andere Gruppen in `auto_groups` bleiben unangetastet. Wer in Pocket ID weder in `homelab` noch in `homelab_admins` ist, wird nicht angefasst, und der Lauf schlägt fehl (dieselbe Prüfung wie die Precondition in Tofu). Jede Änderung steht als Zeile im Journal (`naddi: +home-lan`); sofort statt nach bis zu einer Minute: `just netbird-group-sync`.

Entschieden 2026-11-01 (1b) gegen ein unbeaufsichtigtes `tofu apply` (wendet alles an, der State liegt auf der Workstation) und gegen bloße Drift-Erkennung. NetBirds eigener JWT-Gruppensync bleibt aus (Begründung im Kopf von `people.tf`). Ein SCIM-Empfänger, dem Pocket ID Änderungen sofort schickt, ist für später notiert.

**Zugangsdaten**, je eine eigene sops-Datei, damit sich jede einzeln erneuern lässt:

- **NetBird:** Token des Service-Users `group-sync` (`terraform/netbird/group-sync.tf`), Rolle admin – weniger erlaubt NetBird 0.81 für das Ändern von Nutzern nicht (`network_admin` darf Nutzer nur lesen). Wer grammi übernimmt, hat NetBirds Datenbank ohnehin. Ablegen: `just netbird-group-sync-token`, jährlich erneuern: `just netbird-group-sync-token renew`.
- **Pocket ID:** API-Key des eigenen Admin-Users `netbird-group-sync` (ohne Passkey, nur für diesen Key; im Audit-Log getrennt sichtbar, Deaktivieren des Users sperrt den Key sofort). Pocket ID 2.19.2 kann API-Keys nicht einschränken: Der Key kann alles, was ein Admin kann. Eingehegt wird er auf zummi: Von grammis Mesh-Adressen lässt nginx nur `GET` auf die Nutzerliste, einzelne Nutzer und die eigene Key-Liste durch (`$pocketid_sync_allowed`); jede andere Anfrage mit API-Key ist 403, von grammi wie aus dem Internet, der Key kann also auch sein eigenes Konto nicht ändern. Voll nutzbar wäre der Key nur von den Admin-Geräten, und zummi baut nicht, sollten grammis Adressen je unter ihnen auftauchen. Deshalb spricht der Sync Pocket ID über zummis Mesh-Namen an (TLS weiter für `auth.homelab.example`). Key anlegen: als `netbird-group-sync` per Login-Code aus der Admin-Oberfläche anmelden, API-Key „netbird-group-sync“ mit einem Jahr Laufzeit erzeugen, alte Keys dieses Users löschen, dann `just netbird-group-sync-pocketid-key`.

Danach jeweils Commit und Deploy von grammi. **Alarme** (`hosts/grammi/alerting/identity.nix`): NetbirdGroupSyncStale (eine Stunde ohne fehlerfreien Lauf), SyncCredentialExpiring (Token oder Key laufen in weniger als 30 Tagen ab), PersonNotManaged (jemand ist in Pocket ID in `homelab`/`homelab_admins`, steht aber nicht in `people.tf`); jeder Fehlschlag löst außerdem UnitFailed aus.

- Neue Person: nach `just netbird-apply` die neue `terraform/netbird/group-sync.json` committen und grammi deployen.
- `group-sync.json` enthält auch grammis Mesh-Adressen; ändern die sich (neue v6-Adresse), zummi deployen.

### Paperless: von außen Freigabelinks (offen) und App (SSO)

Im Mesh löst `dokumente.homelab.example` über die NetBird-Zone direkt zu ursalia auf (volle App, Login per Pocket ID).

**Von außen** ist `dokumente` ein CNAME auf den Reverse Proxy. Dessen Dienst `dokumente` hat zwei Ziele, beide ein Listener auf ursalia (Port 8092, nur Mesh, HTTP durch den Tunnel), unterschieden nach Pfad (`access_action`, ab NetBird 0.81):

- **`/share/` ohne Anmeldung**, für Dritte mit einem Freigabelink: nur `share/<slug>` (Dokumente und Bündel, beides `SharedLinkView` in Paperless), sonst 404. Ein abgelaufener oder unbekannter Link führt in Paperless auf die Login-Seite; der Listener fängt diese Weiterleitung ab und antwortet mit einem kurzen Hinweistext.
- **alles andere mit SSO** über Pocket ID (Gruppen `paperless-users`/`paperless-admins`): die volle App samt paperless-gpt wie im Mesh. Danach folgt noch der Pocket-ID-Login von Paperless selbst, meist ohne Eingabe.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Extern ohne Anmeldung | Reverse Proxy (grammi) → ursalia:8092 | nur `/share/<slug>`; jeder andere Pfad führt zum SSO |
| Extern mit SSO | Reverse Proxy (grammi) → ursalia:8092 | volle App |
| Im Mesh | direkt ursalia:443 | volle App |

**Woran der Listener SSO erkennt:** am Header `X-NetBird-User`. Der Proxy löscht bei jeder Anfrage, was der Client unter diesem Namen schickt – auch auf dem offenen Pfad –, und setzt ihn nur bei SSO-Sitzungen auf die E-Mail-Adresse (`stampNetBirdIdentity` in NetBird, geprüft mit 0.81.0; ein gefälschter Header auf dem offenen Pfad mit 0.82.0 als entfernt getestet – bei NetBird-Updates erneut prüfen). Der Header wählt nur die Pfade, er meldet niemanden an: Paperless verlangt weiter seinen eigenen Login. Ein Mesh-Peer, der den Header direkt an Port 8092 schickt, bekommt nichts, was er über 443 nicht ohnehin bekäme.

**Warum derselbe Name:** Paperless baut den Freigabelink aus dem Origin der Oberfläche. Ein Link `https://dokumente.homelab.example/share/<slug>` funktioniert so für Dritte ohne Umschreiben – egal ob im Mesh oder per SSO erzeugt. Eine eigene Adresse für Freigabelinks kennt Paperless nicht (upstream abgelehnt, [paperless-ngx#14251](https://github.com/paperless-ngx/paperless-ngx/pull/14251)).

**Zwei Filter:** Der Proxy lässt nur `/share/` ohne Anmeldung durch (wörtliches Präfix mit Groß-/Kleinschreibung: `/share` ohne Schrägstrich und `/SHARE/` gehen zum SSO; Traversal wird abgewiesen). Dahinter liefert ursalias Listener einer Anfrage ohne `X-NetBird-User` nur `share/<slug>`. Jeder der beiden hielte die App allein schon zu.

**Terraform-Provider:** Das Release in der Registry kennt `access_action` noch nicht. `pkgs/terraform-provider-netbird.nix` baut ihn aus Upstream-PR #215 plus einem Patch mit `access_action` und PR #264 (zwei Ziele auf einem Peer), beides von Sebastien Baillet; er entfällt mit dem ersten Release, das beides enthält.

**Was das bewusst in Kauf nimmt:**

- Wer einen Link hat, bekommt das Dokument, ohne zweite Hürde – wie bei den geteilten Links von Immich (`fotos`). Der 50-stellige Slug ist das Geheimnis. Freigaben in Paperless deshalb mit Ablaufdatum anlegen und löschen, wenn sie nicht mehr gebraucht werden.
- Die Unterscheidung der Pfade im Listener hängt an einem Verhalten des Proxys, nicht an einer dokumentierten Schnittstelle.
- CrowdSec sieht keine Anfragen an die App oder die Freigabelinks (TCP-Passthrough, kein HTTP-Log auf grammi), wie bei allen Proxy-Namen; es bleiben die IP-/Geo-/CrowdSec-Regeln des Proxys und der Login von Paperless.
- ursalias nginx loggt als Absender die Mesh-Adresse des Proxys, nicht die des Besuchers (kein `realip`: es würde die Adresse vor `allow`/`deny` umschreiben).

### Grafana: öffentliche Dashboards über `dash`

Seit 2026-10-23 lassen sich Dashboards nach außen teilen („Share externally“, in Grafana „öffentliche Dashboards“). Das Recht dazu hat nur die Grafana-Rolle Admin. Die vergibt der SSO-Login an die Pocket-ID-Gruppe `grafana_admins` (eigens dafür, `terraform/netbird/people.tf`; Mitglieder in Pocket ID pflegen, wirksam beim nächsten Grafana-Login). Alle anderen sind seit #306 Viewer: Dashboards ja, Explore nein – Explore hieße beliebige Abfragen gegen das Journal aller Hosts. Aus demselben Grund lassen `vm.homelab.example` und `vl.homelab.example` (die vmui von VictoriaMetrics und VictoriaLogs, ohne eigene Anmeldung) nur `homelab_admins` herein. Die Viewer-Rolle blendet Explore aus, ist aber keine harte Schranke: Grafana OSS kennt keine Rechte pro Datenquelle, ein Viewer kann über `/api/ds/query` weiter Abfragen schicken; die eigentliche Schranke ist die Proxy-Gruppe von `metrics`.

**Der Weg:** `dash.homelab.example` ist ein eigener Dienst im Reverse Proxy, **ohne Login**. Sein Ziel ist derselbe Entrypoint `apps` von Traefik auf grammi wie bei `metrics`, aber für diesen Namen lässt Traefik nur `/public-dashboards/`, `/api/public/` und `/public/` (Assets) zu Grafana durch. Alles andere beantwortet Traefik mit 404. Dieser Router hält die App von anonymen Besuchern fern, nicht der Proxy.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Jeder mit Link | Reverse Proxy → Traefik `apps` (Host `dash`) → Grafana | nur das freigegebene Dashboard, lesend |
| SSO | `metrics.homelab.example` | Dashboards; Explore und Freigaben nur `grafana_admins` |

**Link weitergeben:** Grafana baut den Link aus `root_url`, er lautet also `https://metrics.homelab.example/public-dashboards/<token>` – unter `metrics` landet ein Gast beim SSO-Login. Den Link für Gäste zeigt das Dashboard „Homelab / Shared dashboards“: ein Timer auf grammi fragt alle 10 Sekunden die Grafana-API ab und schreibt jede Freigabe mit ihrer `dash`-Adresse und den genutzten Template-Variablen als Metrik `grafana_public_dashboard_info` (`hosts/grammi/grafana-shares.nix`). Jedes Dashboard verlinkt oben rechts dorthin („Share externally“). Die Spalte „Manage“ öffnet den Freigabe-Dialog des jeweiligen Dashboards zum Pausieren und Widerrufen – ein Schalter direkt in der Tabelle geht nicht, weil Grafana Panel-Actions seine eigene API nur per POST/PUT aufrufen lässt und das Pausieren PATCH braucht. Die Tokens liegen damit in VictoriaMetrics, sichtbar für alle, die Grafana öffnen können.

**Was das bewusst in Kauf nimmt:**

- Der Token im Link ist das einzige Geheimnis, keine PIN davor. Ein öffentliches Dashboard ist nur lesbar, und in Grafana lässt es sich jederzeit pausieren oder löschen.
- Dashboards mit Template-Variablen teilt Grafana zwar, aber Panels, die eine Variable nutzen (etwa `$job` in Hosts Overview), bleiben für Gäste leer; dafür braucht es eine Kopie ohne Variablen. Die Spalte „Variables“ in „Homelab / Shared dashboards“ zeigt, welche Freigabe das betrifft. Außerdem braucht jedes Panel die UID seiner Datenquelle; die UIDs sind deshalb in der Provisionierung festgelegt und in allen Dashboards eingetragen (`hosts/grammi/grafana.nix`).
- Wie bei allen Proxy-Namen sieht CrowdSec auf grammi nur, was Traefik im Entrypoint `apps` loggt, nicht den TLS-Teil davor.

### MQTT von außen: TLS-Passthrough zu Home Assistant

`mqtt.homelab.example:8883` ist das Mosquitto-Add-on auf Home Assistant, für MQTT-Geräte, die auch außerhalb der Wohnung laufen (AWTRIX NG auf einem Ulanzi TC002). Überall derselbe Name, derselbe Port und dasselbe Zertifikat, ein Gerät wird also einmal eingerichtet:

| Wo | Weg |
| --- | --- |
| Zu Hause | der Heimrouter (Flint 4) beantwortet `mqtt.homelab.example` mit HAs LAN-Adresse (lokaler DNS-Eintrag) → HA:8883 direkt, auch ohne Internet |
| Außen | öffentlicher CNAME auf den Reverse Proxy → `netbird-proxy` auf grammi, Port 8883 → durchs Mesh zu HA:8883 |

**HA ist ein NetBird-Peer** (NetBird-Add-on, `terraform/netbird/home-assistant.tf`), in einer eigenen Gruppe `home-assistant` – nicht in `servers`, es erreicht also genau zwei Dinge, und außer dem Proxy erreicht nichts HA. Die DNS-Verwaltung durch NetBird ist für die Gruppe aus: HA löst weiter über den Heimrouter (Flint 4) auf, auch wenn das Internet weg ist.

**TLS endet in Mosquitto, nicht am Proxy.** Der Service `mqtt` (`terraform/netbird/reverse-proxy.tf`) läuft im L4-Modus `tls` mit dem Peer HA als Ziel: Der Proxy liest nur die SNI und reicht die Verbindung unverändert durch. Für einen L4-Service mit eigenem Port bindet der Proxy diesen Port selbst auf allen Adressen (einen PROXY-Header muss dort nur 127.0.0.1 schicken); grammis Firewall öffnet 8883 in `hosts/grammi/netbird-proxy.nix`.

**Ratenbegrenzung statt Login** (nixlab#309). L4 hat kein SSO, die Mosquitto-Nutzer sind also die Schranke – und Mosquitto sieht für jede Verbindung von außen die Mesh-Adresse des Proxys, CrowdSec sieht von der Durchleitung nichts. Die echte Quelle kennt nur grammis Kernel: Die nftables-Tabelle `mqtt-ratelimit` (gleiche Datei) lässt jede Quelle (IPv4-Adresse, IPv6-/64) 20 neue Verbindungen auf einmal und danach 4 pro Minute aufbauen und verwirft den Rest; bestehende Verbindungen bleiben unberührt. Ein Gerät, das sich nach einem Stromausfall neu verbindet (AWTRIX: etwa 5 Versuche in 70 s), bleibt weit darunter. Verworfene und angenommene Verbindungen werden gezählt (`nixlab_mqtt_ratelimit_packets_total`, Dashboard *Homelab / MQTT edge*), und der Alarm `MqttConnectionFlood` schlägt bei mehr als 50 verworfenen in 15 Minuten an. Client-Zertifikate für die Geräte draußen wären die stärkere Schranke, offen in nixlab#347.

**Das Zertifikat** gilt für `homeassistant.homelab.example` und `mqtt.homelab.example`. HAs Let's-Encrypt-Add-on holt es per DNS-01 – aber ohne eigenen deSEC-Token (der ließe sich an keine Adresse binden, die Heimadresse wechselt). Es fragt stattdessen dns01proxy auf grammi (`hosts/grammi/dns01proxy.nix`, Provider `dns-httpreq`), unter `https://acme.homelab.example:8446`:

- Der Port ist nur im Mesh offen, und die Policy `home-assistant-acme` lässt nur HA hin. HA löst den Namen über den Heimrouter (Flint 4) auf (lokaler Eintrag auf grammis Mesh-Adresse, `tofu output acme_proxy_address`), alle anderen Peers über die NetBird-Zone.
- Der Proxy schreibt die TXT-Records mit grammis an die Adresse gebundenem Token. HAs Account (Passwort im Add-on, bcrypt-Hash in `hosts/grammi/dns01proxy.yaml`, `just dns01proxy-key-homeassistant`) darf nur Challenges für die beiden Namen oben beantworten.
- dns01proxy spricht selbst HTTPS und holt sein eigenes Zertifikat für `acme.homelab.example` auf demselben Weg.

**Die beiden lokalen DNS-Einträge** sind `domain`-Einträge in dnsmasq auf gruffi, von Hand per SSH gesetzt (`uci add dhcp domain`, dann `name` und `ip`, `uci commit dhcp`, dnsmasq neu starten). Die Seite „Hostnames“ fehlt in GL.iNets LuCI (404 auf `view/network/hosts.js`):

| Name | Adresse | Wozu |
| --- | --- | --- |
| `mqtt.homelab.example` | 198.51.100.168 (HAs LAN-Adresse) | MQTT bleibt im Heimnetz und läuft auch ohne Internet |
| `acme.homelab.example` | 192.0.2.122 (grammis Mesh-Adresse, `tofu output acme_proxy_address`) | HA erreicht dns01proxy; NetBird verwaltet HAs DNS nicht |

Ändert sich HAs Adresse oder grammis Mesh-Adresse (neue Lease, NetBird-Neuregistrierung), muss der Eintrag von Hand nachgezogen werden.

Das Add-on erneuert nicht von selbst: Eine HA-Automation startet es täglich und startet Mosquitto wöchentlich neu, damit das erneuerte Zertifikat geladen wird.

**Was das bewusst in Kauf nimmt:**

- Kein Login am Proxy – L4 hat keinen. Einzige Hürde sind die Benutzer von Mosquitto, und dazu gehört jeder Login, den das Add-on annimmt (seine eigene Liste und die Home-Assistant-Benutzer).
- Mosquitto sieht für jede Verbindung von außen die Mesh-Adresse des Proxys als Absender (das Add-on kann keinen PROXY-Header annehmen) – weder HA noch CrowdSec können also einzelne Clients per Adresse sperren. Der Proxy kann nach Land oder Adressbereich filtern (`access_restrictions`), vorerst nicht gesetzt.
- Die Erneuerung des Zertifikats braucht grammi und das Mesh – mit 30 Tagen Puffer vor Ablauf.
- Ein Gerät, das bei ausgefallenem Internet neu startet, braucht die Uhrzeit von woanders als aus dem Internet, um das Zertifikat zu prüfen.

### floccus: Tabs und Lesezeichen über `tabs` { #tabs }

floccus synchronisiert Lesezeichen und offene Tabs zwischen Browsern, auch zwischen Profilen auf Geräten außerhalb des Mesh. Ziel ist ein eigener WebDAV-Server auf aldrin (`hosts/aldrin/floccus.nix`): `rclone serve webdav` auf Loopback, davor nginx unter `tabs.homelab.example`, öffentlich.

- **Nicht OpenCloud:** floccus kann nur Basic Auth. OpenCloud bräuchte dafür ein App-Token, und das hätte Zugriff auf alle Dateien des Accounts – in einem Browser auf einem Gerät, das jemand anderes verwaltet. Das Passwort hier erreicht nur ein Verzeichnis mit Tab-Listen.
- **Nicht nginx-DAV:** floccus fragt die Dateigröße per PROPFIND ab, das kann nginx nur mit dem Modul `dav_ext`, und damit müsste nginx bei jedem Update aus dem Quellcode gebaut werden. rclone kommt aus dem Cache und kann alles, was floccus schickt: GET, PUT, DELETE, MOVE, PROPFIND.
- **Account:** einer (`floccus`). `just floccus-password` legt ein zufälliges Passwort in die Zwischenablage und den bcrypt-Hash in `hosts/aldrin/floccus.yaml`; ohne diese Datei tut das Modul nichts. Das alte Passwort gilt bis zum nächsten Deploy von aldrin.
- **Inhalt:** In floccus ist eine Passphrase gesetzt, der Server sieht nur die verschlüsselte Datei.
- **Backup:** `/data/floccus` ist ein eigenes btrfs-Subvolume und bekommt dieselben btrbk-Snapshots wie OpenCloud – lokal, auf demselben Volume.

**In floccus:** Profil mit Sync-Methode WebDAV, URL `https://tabs.homelab.example/`, Benutzer `floccus`, Passwort aus dem Rezept, dieselbe Passphrase auf jedem Gerät. Für Tabs ein Profil vom Typ „Tabs“, für Lesezeichen ein eigenes mit einem anderen Dateinamen – zwei Profile dürfen nie dieselbe Datei teilen. Auf Geräten mit getrennten Browser-Profilen (dienstlich/privat) floccus nur im privaten Profil einrichten.
