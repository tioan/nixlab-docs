# Standort-Gateway: Remote

Der Remote-Standort (ein Verein, dessen Omada-Netz von hier aus mitbetreut wird) hängt über **gw-remote** am Lab: einen NixOS-Container auf aldrin, der OpenVPN-Server für den Router des Standorts und im Mesh der Routing-Peer in dessen vier VLANs ist. Nur das Admin-Gerät erreicht die Geräte dort, nichts hinter dem Router erreicht das Lab. Ein Klick auf einen Kasten springt zum passenden Abschnitt.

## Aufbau { #architecture }

<figure class="nx-diagram">
<svg viewBox="0 0 680 490" role="img" aria-labelledby="gw-remote-title gw-remote-desc" xmlns="http://www.w3.org/2000/svg">
<title id="gw-remote-title">Anbindung des Remote-Standorts über gw-remote</title>
<desc id="gw-remote-desc">gusto erreicht über NetBird den Container gw-remote auf aldrin. Der ER7206 am Remote-Standort baut zwei OpenVPN-Tunnel dorthin auf, einen pro Uplink. Andere Peers haben keinen Zugriff, aus dem Standort kommen nur Antworten.</desc>
<style>
.nx-t { font-size: 14px; font-weight: 500; fill: #1f1e1d; }
.nx-s { font-size: 12px; fill: #6b6965; }
.nx-line { stroke: #b4b2a9; stroke-width: 0.75; fill: none; }
.nx-frame { fill: none; stroke: #b4b2a9; stroke-width: 0.75; stroke-dasharray: 4 4; }
.nx-box { fill: #fbfaf7; stroke: #b4b2a9; stroke-width: 0.75; }
.nx-gray rect { fill: #f1efe8; stroke: #5f5e5a; stroke-width: 0.75; }
.nx-gray .nx-t { fill: #444441; } .nx-gray .nx-s { fill: #5f5e5a; }
.nx-purple rect { fill: #eeedfe; stroke: #534ab7; stroke-width: 0.75; }
.nx-purple .nx-t { fill: #3c3489; } .nx-purple .nx-s { fill: #534ab7; }
.nx-coral rect { fill: #faece7; stroke: #993c1d; stroke-width: 0.75; }
.nx-coral .nx-t { fill: #712b13; } .nx-coral .nx-s { fill: #993c1d; }
</style>
<g class="nx-gray"><rect x="40" y="60" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="83" text-anchor="middle">grammi</text><text class="nx-s" x="100" y="102" text-anchor="middle">NetBird-Mgmt</text></g>
<a href="#access"><g class="nx-purple"><rect x="40" y="158" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="181" text-anchor="middle">gusto</text><text class="nx-s" x="100" y="200" text-anchor="middle">MacBook, Mesh</text></g></a>
<a href="#access"><g class="nx-gray"><rect x="40" y="290" width="120" height="56" rx="8"/><text class="nx-t" x="100" y="313" text-anchor="middle">Andere Peers</text><text class="nx-s" x="100" y="332" text-anchor="middle">keine Policy</text></g></a>
<rect class="nx-frame" x="190" y="60" width="260" height="380" rx="16"/>
<text class="nx-t" x="210" y="88">aldrin</text><text class="nx-s" x="210" y="106">Realtox DUS, feste IPv4</text>
<rect class="nx-box" x="210" y="120" width="220" height="300" rx="12"/>
<text class="nx-t" x="225" y="144">gw-remote (Container)</text>
<a href="#access"><g class="nx-purple"><rect x="230" y="158" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="181" text-anchor="middle">NetBird-Router</text><text class="nx-s" x="320" y="200" text-anchor="middle">Policy: nur gusto</text></g></a>
<a href="#isolation"><g class="nx-gray"><rect x="230" y="224" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="247" text-anchor="middle">nftables</text><text class="nx-s" x="320" y="266" text-anchor="middle">vom Standort: nur Antworten</text></g></a>
<a href="#failover"><g class="nx-coral"><rect x="230" y="290" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="313" text-anchor="middle">tun-remote-uplink1</text><text class="nx-s" x="320" y="332" text-anchor="middle">udp/1194</text></g></a>
<a href="#failover"><g class="nx-coral"><rect x="230" y="356" width="180" height="56" rx="8"/><text class="nx-t" x="320" y="379" text-anchor="middle">tun-remote-uplink2</text><text class="nx-s" x="320" y="398" text-anchor="middle">udp/1195</text></g></a>
<rect class="nx-frame" x="475" y="60" width="165" height="360" rx="16"/>
<text class="nx-t" x="490" y="88">Remote-Standort</text>
<g class="nx-coral"><rect x="485" y="100" width="145" height="56" rx="8"/><text class="nx-t" x="557" y="123" text-anchor="middle">LAN</text><text class="nx-s" x="557" y="142" text-anchor="middle">VLANs 1, 79, 80, 81</text></g>
<line class="nx-line" x1="557" y1="156" x2="557" y2="176"/>
<a href="#profiles"><g class="nx-coral"><rect x="485" y="176" width="145" height="56" rx="8"/><text class="nx-t" x="557" y="199" text-anchor="middle">ER7206</text><text class="nx-s" x="557" y="218" text-anchor="middle">OpenVPN-Client 2.3.8</text></g></a>
<g class="nx-coral"><rect x="485" y="296" width="122" height="44" rx="8"/><text class="nx-t" x="546" y="323" text-anchor="middle">SFP WAN</text></g>
<g class="nx-coral"><rect x="485" y="362" width="122" height="44" rx="8"/><text class="nx-t" x="546" y="389" text-anchor="middle">WAN (CGNAT)</text></g>
<path class="nx-line" d="M622 232 L622 384 L609 384"/>
<path class="nx-line" d="M622 318 L609 318"/>
<line x1="160" y1="186" x2="227" y2="186" stroke="#7F77DD" stroke-width="1.5"/><path d="M222 182 L228 186 L222 190" stroke="#7F77DD" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="485" y1="318" x2="413" y2="318" stroke="#D85A30" stroke-width="1.5"/><path d="M418 314 L412 318 L418 322" stroke="#D85A30" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="485" y1="384" x2="413" y2="384" stroke="#D85A30" stroke-width="1.5" stroke-dasharray="5 4"/><path d="M418 380 L412 384 L418 388" stroke="#D85A30" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<line x1="40" y1="462" x2="80" y2="462" stroke="#D85A30" stroke-width="1.5"/>
<text class="nx-s" x="90" y="466">Tunnel aktiv, Metrik 100</text>
<line x1="270" y1="462" x2="310" y2="462" stroke="#D85A30" stroke-width="1.5" stroke-dasharray="5 4"/>
<text class="nx-s" x="320" y="466">Reserve, Metrik 200</text>
<text class="nx-s" x="40" y="486">Pfeil = Richtung des Verbindungsaufbaus</text>
</svg>
</figure>

## Wer darf rein { #access }

Nur das Admin-Gerät: Die vier NetBird-Policies `remote-*` (`terraform/netbird/remote.tf`, eine je VLAN) haben `admin-workstations` als Quelle, also gusto, und keine Personengruppe. Alle anderen Peers bekommen die Route gar nicht erst. Ist gusto selbst am Standort, fällt die Route weg (Posture-Check `not-at-remote`), dann geht der Verkehr direkt.

gw-remote selbst steckt in der Gruppe `remote-devices`, nicht in `servers`: Es beendet Tunnel aus einem Netz, das andere betreiben, und erreicht deshalb nur, was ihm ausdrücklich erlaubt ist, nämlich grammis Metrik- und Log-Eingang (`remote-devices-telemetry`, TCP 8428/9428), wie cuckoosegg.

## Abschottung { #isolation }

Aus dem Standort kommt nichts ins Lab. Dafür sorgen drei Schichten:

- **Container mit eigenem Netz-Namespace** auf aldrin: `tun-remote-*` und ein eigenes `nb-mesh` treffen nie auf aldrins vertrauenswürdiges Mesh-Interface. Kein eigener Kernel – das war die bewusste Abwägung gegenüber einer VM (2026-10-22).
- **nftables im Container** (`hosts/gw-remote/container.nix`): Die Tunnel sind nicht trusted. In den Tunnel dürfen neue Verbindungen nur von den Mesh-Adressen der Admin-Geräte (`admin-peers.json`), aus dem Tunnel kommen nur Antworten (`established,related`), an den Container selbst gar nichts. Masquerade je Tunnel: Der Standort sieht nur die Tunneladresse von gw-remote und braucht keine Route zurück.
- **nftables auf aldrin** (`hosts/aldrin/gw-remote.nix`): Die OpenVPN-Ports werden nur von den Adressen der beiden Anschlüsse an den Container weitergeleitet, der Container erreicht nur das Internet, weder aldrin noch dessen Mesh.

Kein CrowdSec auf den Ports: Der Bouncer hängt nur am Input-Hook, die Ports werden aber weitergeleitet, und Community-Blocklisten führen CGNAT-Adressen. Schutz sind der Quellfilter und `tls-auth`.

Getestet am 2026-11-02: gusto erreicht die Geräte, ursalia und aldrin nicht; vom ER7206 aus bleiben gw-remote, aldrins Seite des Containers und Mesh-Adressen ohne Antwort.

## Tunnel und Failover { #failover }

Ein OpenVPN-Server je Uplink, nicht einer für beide Clients: Mit einem Server würden beide Clients dieselben Netze per `iroute` anmelden, und OpenVPN statt des Kernels wählte, wer den Verkehr bekommt – ohne sauberen Rückweg, wenn der aktive wegfällt. Mit zwei Servern sind es zwei tun-Interfaces, und der Kernel wählt per Routen-Metrik.

| Uplink | Leitung am ER7206 | Port | Interface | Metrik |
| --- | --- | --- | --- | --- |
| uplink1 | SFP WAN, Vodafone, feste IPv4 | udp/1194 | `tun-remote-uplink1` | 100 |
| uplink2 | WAN, CGNAT | udp/1195 | `tun-remote-uplink2` | 200 |

`client-connect` setzt die Routen zu den VLANs, sobald der Client eines Uplinks verbunden ist, `client-disconnect` nimmt sie wieder heraus. OpenVPN läuft dafür ohne root, nur mit `CAP_NET_ADMIN`. Die VLANs kommen aus dem Inventar (Netze mit `site: "remote"`), die Ports, Transfernetze und Metriken aus `hosts/gw-remote/site.json`.

`keepalive 2 10`: Fällt ein Uplink aus, merkt gw-remote das nach 20 s. Im Test mit dem vorherigen `keepalive 10 60` war der Standort genau 120 s nicht erreichbar, das Zurückwechseln kostete 3 s. Verbindungen, die während des Ausfalls über uplink2 aufgebaut wurden, behalten nach dem Zurückwechseln dessen Masquerade-Adresse und können abbrechen.

## Profile am ER7206 { #profiles }

Der ER7206 (Firmware 1.4.3) bringt **OpenVPN 2.3.8** mit. Daraus folgt:

- kein `tls-crypt`: Ein Profil damit verwirft er stillschweigend – kein Paket, kein Log, keine Sitzung. Deshalb `tls-auth`.
- kein Aushandeln des Ciphers: Der Server bietet GCM zuerst an und fällt für ihn auf `AES-256-CBC` mit `auth SHA256` zurück.
- Der Controller nimmt als Server nur eine IP, keinen Namen. `just gw-remote-ovpn` schreibt aldrins Adresse ins Profil.
- Die VPN-Statusseite des Controllers bleibt für diese Clients leer, auch wenn der Tunnel steht. Den Zustand zeigen die Metriken von gw-remote.

Neues Profil (braucht den Workstation-Key):

```bash
just gw-remote-ovpn uplink1 ~/Downloads/remote-uplink1.ovpn
```

Im Controller als VPN-Client vom Typ OpenVPN anlegen (Name `remote_uplink1`, Bindestriche nimmt er nicht), Modus Certificate, Interface SFP WAN (uplink1) bzw. WAN (uplink2), alle vier VLANs als lokale Netze. Danach die Datei löschen. `just gw-remote-pki` legt die CA, das Server- und die beiden Client-Zertifikate an; der CA-Schlüssel wird verworfen, ein neuer Client heißt neue CA und neue Profile.

## Überwachung { #monitoring }

gw-remote schickt Metriken und Logs an grammi wie jeder Host. Dazu kommen je Uplink `nixlab_remote_uplink_connected`, `…_connected_since_seconds` und die Bytes der laufenden Sitzung (`hosts/gw-remote/uplink-metrics.nix`, aus der Status-Datei von OpenVPN). Alarme: **RemoteUplinkDown** (ein Uplink seit 30 min getrennt – auch wenn eine Adresse aus dem Quellfilter gefallen ist) und **RemoteSiteUnreachable** (keiner seit 10 min). Dashboard: Zeile „Site tunnels“ in Homelab / NetBird.

## Betrieb { #operations }

- **Befehle im Container:** `ssh root@aldrin.peer.homelab.example systemd-run -M gw-remote --wait --pipe -q -E PATH=/run/current-system/sw/bin /run/current-system/sw/bin/bash -c '…' </dev/null`. Nicht `nixos-container run` ohne Terminal: Das bleibt gestoppt hängen und hält das init des Containers am Leben (2026-11-02).
- **Erstes Deploy:** Die NetBird-Anmeldung im Container ist bewusst kein Boot-Job (`Type=exec`). aldrin bringt seine Seite der Container-Verbindung erst hoch, wenn der Container „gebootet“ meldet – eine wartende Anmeldung hatte das verklemmt.
- **Adresse von uplink2 geändert:** RemoteUplinkDown feuert, die neue Adresse steht in OpenVPNs Log oder per `tcpdump` auf aldrin; dann `sources.uplink2` in `hosts/aldrin/gw-remote.nix` anpassen. Ob die zusätzlich erlaubte Einzeladresse noch gebraucht wird, wird Ende November 2026 anhand der Logs geprüft.
