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

Der Workstation-Key liegt in 1Password und wird über `SOPS_AGE_KEY_CMD` gelesen, nie als Datei. `env.sh` in jedem Tofu-Modul entschlüsselt die Tokens nur in die Shell des jeweiligen Rezepts.

## Netzwerk

- **NetBird-Mesh** (`192.0.2.0/24` und `2001:db8:203:0::/64`, Peer-Namen unter `peer.homelab.example`): Control Plane auf grammi, Login über Pocket ID. Private Range (RFC 1918) statt CGNAT, weil tailscaled Pakete aus 100.64/10 verwirft, solange beide Clients parallel laufen.
- **Gruppen:** `servers` (alle Hosts außer cuckoosegg), `subraum-devices`, `admin-workstations` (MacBook), dazu Personengruppen aus Pocket ID.
- **Heim-LAN** (`198.51.100.0/24`): Route über ursalia (Metrik 100), die beiden Apple TVs als Rückfall (Gruppe `home-routers`, Metrik 200, eigener Setup-Key per `just netbird-router-key`, keiner Person zugeordnet, in keiner Policy); für Gruppe `home-lan`, nicht für Geräte, die schon zu Hause sind (Posture-Check `not-at-home`). Rosenpass ist seit 2026-10-24 im ganzen Mesh aus (bis 2026-10-31, siehe [macOS-Hosts](macos-hosts.md#netbird-auf-den-beiden-macs)); „Quantum-Resistance“ in der App der Apple TVs gehört für diese Zeit ebenfalls aus.
- **Anbindung von ursalia:** WLAN ins Hauptnetz des Heim-LANs (Intel AX211, `hosts/ursalia/wifi.nix`): wpa_supplicant, WPA3 mit WPA2-Rückfall, Land DE, alle Bänder, Passwort per sops. Am endgültigen Platz gibt es kein Kabel; eno1 behält DHCP als Rückfall mit schlechterer Routen-Metrik, damit das WLAN die Hauptverbindung bleibt, wenn beide aktiv sind.
- **Anbindung von zorlock:** ebenfalls WLAN (`en1`, Broadcom); `hosts/zorlock/wifi.nix` stellt sicher, dass `homelab` als bevorzugtes Netz eingetragen ist (`networksetup`, fügt nur hinzu, Passwort per sops in `hosts/zorlock/wifi.yaml`). nix-darwin hat kein WLAN-Modul; die Bandwahl bleibt bei macOS.
- **Exit-Nodes und IPv6:** aldrin und zummi als Exit-Nodes für die Gruppe `exit-nodes`; das Mesh ist Dualstack (`2001:db8:203:0::/64`) – siehe [Exit-Nodes & IPv6](#exit-nodes).
- **Subraum:** Route über cuckoosegg für `subraum-access`. cuckoosegg selbst darf nur grammis Ingest (TCP 8428/9428) erreichen und nur vom MacBook per SSH erreicht werden.
- **Tailscale** läuft während der Migration noch parallel und dient als Break-Glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

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

Die Pocket-ID-Gruppe `exit-nodes`. Jemand kommt dazu, indem man ihn in Pocket ID (auth.homelab.example) in die Gruppe aufnimmt und danach `just netbird-apply` ausführt; das überträgt die Mitgliedschaft auf die NetBird-Gruppe gleichen Namens und damit auf alle Geräte der Person. Die Policy `exit-nodes` erlaubt nur dieser Gruppe den Weg in die Zugriffsgruppe `exit-node-access` der Routen. Bewusst nicht alle: Wer den Exit-Node nutzt, tritt mit der Adresse des Servers auf.

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

Routing und NAT richtet der NetBird-Client selbst ein: Masquerade für v4 (NAT44) und v6 (NAT66) auf die öffentlichen Adressen des Hosts, die ACL der Policy in seiner eigenen nftables-Tabelle. `modules/netbird-exit-node.nix` schaltet zusätzlich das Forwarding für beide Familien ein, damit es nicht vom Client abhängt. Reverse-Path-Filter bleibt „strict“, die NixOS-Firewall filtert Forwarding nicht (`filterForward` aus, wie überall).

Warum NAT66 und keine öffentlichen Adressen für die Clients: Die Overlay-Adresse eines Clients gilt im ganzen Mesh, unabhängig vom Exit-Node – eine GUA aus aldrins Netz würde über zummi mit fremder Absenderadresse hinausgehen. Außerdem hat keiner der beiden ein geroutetes Präfix: aldrins /64 ist on-link, zummi hat eine /128.

#### Dualstack im Mesh { #mesh-ipv6 }

Seit 2026-10-25 ist das ganze Mesh Dualstack. Jeder Peer bekommt neben seiner Adresse aus `192.0.2.0/24` eine aus der ULA `2001:db8:203:0::/64` (`ipv6_enabled_groups` = All, `terraform/netbird/main.tf`). Peer-Namen unter `peer.homelab.example` und die Dienstnamen (`s3-admin`, `dokumente`, `doku`, `llm`, `acme`, `terraform/netbird/mesh-services.tf`) haben AAAA neben A; NetBird liefert AAAA nur an Peers, die selbst v6 haben. Die Apple TVs (Client 0.66) bleiben bei v4.

Die Range steht überall neben `192.0.2.0/24`: root-SSH (`modules/ssh.nix`), CrowdSec-Whitelist, Doku-Site, garage-ui auf aldrin, Paperless und Samba auf ursalia, Traefiks `trustedIPs` auf grammi, Caddy auf zorlock. `admin-peers.json` führt pro Gerät v4 und v6. Wer eine neue Allowlist für das Mesh anlegt, trägt beide Ranges ein.

Wechseln die Gruppen in `ipv6_enabled_groups`, vergibt NetBird neue v6-Adressen. Die AAAA-Einträge der Dienste liest Tofu beim Plan; nach so einem Wechsel oder für einen neu registrierten Peer braucht es deshalb ein zweites `just netbird-apply`.

#### Monitoring { #exit-nodes-monitoring }

Jeder Exit-Node zählt den weitergeleiteten Verkehr je Familie und Richtung in einer eigenen nftables-Tabelle und gibt ihn als `netbird_exit_node_bytes_total` / `netbird_exit_node_packets_total` an den node_exporter. Im Dashboard „Homelab / NetBird“ zeigt der Abschnitt „Exit nodes“ Durchsatz und Volumen. Die Zähler hängen an `postrouting`, nicht an `forward`: Der NetBird-Client setzt `iifname nb-mesh accept` an den Anfang jeder fremden Forward-Chain, Zähler dahinter würden nie erreicht.

#### Provider aus PR #215 { #netbird-provider-pr215 }

Der veröffentlichte NetBird-Provider (v0.0.10) kennt `ipv6_enabled_groups` und `network_range_v6` nicht und setzt sie bei jedem Apply der Account-Settings zurück ([#243](https://github.com/netbirdio/terraform-provider-netbird/issues/243)). Bis [PR #215](https://github.com/netbirdio/terraform-provider-netbird/pull/215) veröffentlicht ist, baut `pkgs/terraform-provider-netbird.nix` den Provider aus diesem PR, und `terraform/netbird/env.sh` setzt ihn per `dev_overrides` ein; Tofu warnt deshalb bei jedem Lauf. Rückbau: Paket, Flake-Output und Block in `env.sh` entfernen, `tofu init -upgrade` ([offener Punkt](../project/open-items.md)).

## Zugriff

Öffentlich offen sind nur 22/80/443. root-SSH lässt `modules/ssh.nix` nur von Mesh- oder Tailscale-Adressen zu; jeder Host hat ein eigenes Login-Keypair. Mesh heißt dabei beide Ranges, `192.0.2.0/24` und `2001:db8:203:0::/64` ([Dualstack](#mesh-ipv6)).

### Apps auf grammi: nur über Traefik `:8090`

Mealie, Grist, logchef und Grafana lauschen auf grammi nur auf `127.0.0.1`. Der Reverse Proxy erreicht sie über den Traefik-Entrypoint `apps` (Port 8090), der vor jede App Wartungsschalter und Fehlerseiten setzt ([Wartungsmodus](../how-to/maintenance.md)). VictoriaMetrics (8428) und VictoriaLogs (9428) lauschen weiter auf allen Adressen, weil die anderen Hosts ihre Metriken und Logs über das Mesh dorthin schicken.

**Bewusste Lücke:** `:8090` selbst ist für jeden Mesh-Peer offen (`nb-mesh` ist vertrauenswürdig), ohne die SSO des Proxys. Wer im Mesh ist, erreicht mit dem passenden `Host`-Header jede App direkt, VictoriaMetrics/-Logs sogar ohne Login, weil sie keinen eigenen haben. Das ist so gewollt (2026-10-23): Wer grammi erreicht, entscheiden die NetBird-Policies, und Mealie, Grist, logchef und Grafana verlangen ihren eigenen Login. Neu bewerten, wenn ins Mesh Peers kommen, denen man weniger traut, oder sobald der Proxy per `direct_upstream` auf Loopback zugreifen kann ([offener Punkt](../project/open-items.md)).

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

**Login aus dem Internet** (entschieden 2026-10-23): für ein Gerät ohne NetBird, etwa einen Firmenlaptop. `doku.homelab.example/login` führt auf `doku-login.homelab.example`, einen eigenen Dienst im Reverse Proxy mit SSO für die Pocket-ID-Gruppe `docs-readers` – ein eigener Name, weil der Proxy die Anmeldung je Dienst kennt, nicht je Pfad, und SSO auf `doku` selbst die öffentliche Doku dahinter stellen würde. Sein Ziel ist ein Listener auf aldrin (Port 8094), der die private Seite ausliefert. Weil die Geräte aller Personen diesen Port über das Mesh ebenfalls erreichen (`to-servers`), schickt der Proxy einen geheimen Header (`X-Nixlab-Docs-Key`) mit, und aldrin liefert nur an Anfragen, die ihn tragen; neuer Schlüssel: `just docs-login-key`. Dieser Weg hängt an grammi und zummi – er ist eine Ergänzung, wenn das Mesh nicht zur Hand ist, kein Ersatz dafür.

**Heimnetz** (entschieden 2026-10-23): Der Router zu Hause beantwortet `doku.homelab.example` mit ursalias LAN-Adresse (ein eigener Eintrag, wie bei `mqtt.homelab.example`), und ursalia liefert die private Doku an das ganze Hauptnetz – außer an die Adressen auf einer bewussten Deny-Liste (`services.docsSite.lan` in `hosts/ursalia/configuration.nix`, Inventar-Geräte mit fester Adresse). Eine Deny-Liste nach Adresse erwischt nur Geräte mit reservierter Adresse; Gäste und alles mit wechselnder Adresse kommen hinein. Die Apple TVs gehören darauf, sobald sie eine Reservierung haben: Als NetBird-Ausweichrouter ins LAN maskieren sie Mesh-Peers auf ihre eigene Adresse. Mesh-Geräte betrifft das nicht – für sie löst der Name weiter auf die Mesh-Adressen auf.

**Warum über den Proxy:** So steht `doku` mit den anderen öffentlichen Namen im NetBird-Dashboard, statt als eigener öffentlicher vHost auf aldrin. Der Proxy selbst kann nicht umleiten, nur weiterreichen – daher der Weiterleitungs-Listener. Er hat einen eigenen Port, statt dass der Doku-vHost den Proxy an seiner Adresse erkennt: Der Proxy ist ein eigener Peer, dessen Mesh-Adresse Tofu nicht kennt. Die Verknüpfung von `homelab.example` mit der öffentlichen Doku ist dabei bewusst in Kauf genommen; die echten Adressen bleiben dort weiter ersetzt.

**Wer als Admin-Gerät zählt:** die Geräte der Gruppe `admin-workstations` (`terraform/netbird/subraum.tf`), heute das MacBook – dasselbe Gerät, das auch per SSH an die Subraum-Geräte darf. Bewusst nicht die Personengruppe `homelab_admins`: die füllt sich aus Pocket ID mit *allen* Geräten eines Admin-Users. Heute wären das keine (Calla hat keine eigenen Geräte), und ein Telefon, das sich unter einem Admin-User anmeldet, wäre sofort drin. Admin ist hier ein Gerät, das in Tofu mit Namen steht, nicht eine Anmeldung. Ein weiteres Gerät in `admin-workstations` bekommt damit auch SSH auf die Subraum-Geräte – dasselbe Vertrauen. Tofu liest die Mitglieder bei jedem `just netbird-apply` und schreibt Name → Adresse nach `terraform/netbird/admin-peers.json`; `flake.nix` übergibt die Adressen an `services.docsSite.allow`. Ein neues Admin-Gerät kommt also nach `just netbird-apply`, Commit und Deploy von aldrin und ursalia hinein.

**Warum in nginx und nicht in einer NetBird-Policy:** `to-servers` erlaubt den Geräten aller Personen (`homelab` und `homelab_admins`) alle Ports auf allen Servern. NetBird-Policies können nur erlauben, nicht verbieten – eine engere Regel für die Doku änderte nichts, solange `to-servers` so bleibt. `to-servers` auf eine Port-Liste je Dienst einzuschränken, ginge, berührt aber jeden Dienst auf jedem Server für eine statische Seite. Die Doku über einen eigenen Port abzutrennen, scheitert am selben Punkt. Die Policy entscheidet also weiter, welche Hosts ein Gerät erreicht, und nginx, wer die Doku bekommt.

**Warum keine Anmeldung im Mesh (Pocket ID):** Die Doku liest man, wenn etwas kaputt ist. Ein Login hinge sie an zummi (Pocket ID) und, über den Reverse Proxy, an grammi – genau die Hosts, von denen sie unabhängig sein soll. Eine Adressliste braucht zur Laufzeit nichts außer nginx auf dem Host selbst. Der Login aus dem Internet oben ändert daran nichts: Mesh und Heimnetz funktionieren ohne ihn weiter.

**Was das bewusst in Kauf nimmt:**

- Die Liste ist so aktuell wie das letzte `just netbird-apply` mit anschließendem Deploy. Ein neues Admin-Gerät sieht bis dahin 403, ein entferntes Gerät kommt bis dahin noch hinein.
- Die Adresse steht für das Gerät, nicht für die Person: Wer ein Admin-Gerät benutzt, liest die Doku.
- Leer darf die Liste nicht werden – `just netbird-admin-peers` verweigert eine leere Ausgabe, und das Modul bricht den Build mit einer Assertion ab, statt still allen 403 zu geben.
- v4 und v6 je Gerät, wie das Mesh ([Dualstack](#mesh-ipv6)). Die v6-Adresse vergibt NetBird neu, wenn sich die Gruppen in `ipv6_enabled_groups` ändern – dann `just netbird-apply` und Deploy von aldrin und ursalia, sonst sieht das Gerät über v6 ein 403.

### Pocket ID: Admin-Bereich nur von Admin-Geräten { #pocket-id-admin }

Seit 2026-10-25 beantwortet nginx auf zummi die Admin-Pfade von Pocket ID mit 403, außer die Anfrage kommt von einer Adresse aus `admin-peers.json` – derselben Liste wie bei der privaten Doku. Gesperrt ist alles, was eine Admin-Sitzung oder ein Admin-API-Key kann: `/settings/admin`, Nutzer, Gruppen, OIDC-Clients, APIs, API-Keys, Einstellungen, Audit-Log, Signup-Tokens, SCIM (Liste: `$pocketid_admin_path` in `hosts/zummi/configuration.nix`, nach den Berechtigungen der Routen in Pocket ID 2.19.1 – bei jedem Minor-Update prüfen). Login, Konto-Seiten (`/api/users/me…`), OIDC-Endpunkte und Logos bleiben öffentlich.

Damit die Admin-Geräte mit ihrer Mesh-Adresse ankommen, zeigt eine NetBird-DNS-Zone `auth.homelab.example` nur für `admin-workstations` auf zummis Mesh-Adressen (`terraform/netbird/pocket-id-admin.tf`); der vhost lauscht dafür auf der Wildcard. Alle anderen Peers, auch NetBirds Server auf grammi, behalten den öffentlichen Eintrag.

- Ohne NetBird auf dem Gerät gilt der öffentliche Eintrag: Login geht, der Admin-Bereich antwortet 403. Ein Browser mit eigenem DNS-over-HTTPS umgeht NetBirds DNS ebenso.
- `just pocketid-plan`/`-apply` brauchen deshalb NetBird auf dem MacBook.
- Ein neues Admin-Gerät: in `admin-workstations`, `just netbird-apply`, dann zummi deployen (wie bei der Doku auch aldrin und ursalia).

### Paperless: von außen Freigabelinks (PIN) und App (SSO)

Im Mesh löst `dokumente.homelab.example` über die NetBird-Zone direkt zu ursalia auf (volle App, Login per Pocket ID).

**Von außen** ist `dokumente` ein CNAME auf den Reverse Proxy. Dessen Dienst `dokumente` bietet zwei Anmeldungen und reicht beide an einen Listener auf ursalia weiter (Port 8092, nur Mesh, HTTP durch den Tunnel):

- **PIN**, für Dritte mit einem Freigabelink: nur `share/<slug>` (Dokumente und Bündel, beides `SharedLinkView` in Paperless), sonst 404. Ein abgelaufener oder unbekannter Link führt in Paperless auf die Login-Seite; der Listener beantwortet das mit einem kurzen Hinweistext.
- **SSO** über Pocket ID (Gruppen `paperless-users`/`paperless-admins`): die volle App samt paperless-gpt wie im Mesh. Danach folgt noch der Pocket-ID-Login von Paperless selbst, meist ohne Eingabe.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Extern mit PIN | Reverse Proxy (grammi) → ursalia:8092 | nur `/share/<slug>`, sonst 404 |
| Extern mit SSO | Reverse Proxy (grammi) → ursalia:8092 | volle App |
| Im Mesh | direkt ursalia:443 | volle App, Freigabelinks ohne PIN |

**Woran der Listener SSO erkennt:** am Header `X-NetBird-User`. Der Proxy löscht bei jeder Anfrage, was der Client unter diesem Namen schickt, und setzt ihn nur bei SSO-Sitzungen auf die E-Mail-Adresse (`stampNetBirdIdentity` in NetBird, geprüft mit 0.81.0 – bei NetBird-Updates erneut prüfen). Der Header wählt nur die Pfade, er meldet niemanden an: Paperless verlangt weiter seinen eigenen Login. Ein Mesh-Peer, der den Header direkt an Port 8092 schickt, bekommt nichts, was er über 443 nicht ohnehin bekäme.

**Warum derselbe Name:** Paperless baut den Freigabelink aus dem Origin der Oberfläche. Ein Link `https://dokumente.homelab.example/share/<slug>` funktioniert so für Dritte ohne Umschreiben – egal ob im Mesh oder per SSO erzeugt. Ein eigener Name für eine der beiden Anmeldungen hieße, Links von Hand anzupassen.

**Warum der Listener filtert und nicht die PIN:** Die PIN ist eine zweite Hürde vor dem nicht ratbaren Slug, kein Ersatz. Dass PIN-Besucher die App nicht sehen, hängt allein an nginx auf ursalia. Der Proxy-Dienst hat keinen Pfadfilter (Ziel-`path`), sonst käme die Weiterleitung auf `/accounts/login/` bei abgelaufenen Links nicht mehr beim Listener an.

**PIN:** genau 6 Ziffern (mehr nimmt die NetBird-API nicht an), eine für alle Freigaben. Neu: `just dokumente-share-pin` (zufällig, nach `terraform/netbird/secrets.yaml`), dann `just netbird-apply`; anzeigen: `just dokumente-share-pin-show`. Der Proxy sperrt eine Client-Adresse nach 5 falschen PINs in 5 Minuten für 15 Minuten.

**Was das bewusst in Kauf nimmt:**

- Eine noch gültige PIN-Sitzung (Cookie des Proxys) überspringt die Anmeldeseite. Wer dann per SSO in die App will, landet auf einer Hinweisseite und muss erst die Website-Daten löschen oder ein privates Fenster nehmen.
- Wer die PIN kennt, kommt an jeden Link, dessen Slug er kennt – nicht an andere. Freigaben in Paperless deshalb mit Ablaufdatum anlegen.
- Die Unterscheidung PIN/SSO hängt an einem Verhalten des Proxys, nicht an einer dokumentierten Schnittstelle.
- CrowdSec sieht weder PIN-Versuche noch Anfragen an die App (TCP-Passthrough, kein HTTP-Log auf grammi), wie bei allen Proxy-Namen; es bleiben die Sperre des Proxys und der Login von Paperless.
- ursalias nginx loggt als Absender die Mesh-Adresse des Proxys, nicht die des Besuchers (kein `realip`: es würde die Adresse vor `allow`/`deny` umschreiben).

### Grafana: öffentliche Dashboards über `dash`

Seit 2026-10-23 lassen sich Dashboards nach außen teilen („Share externally“, in Grafana „öffentliche Dashboards“). Das Recht dazu hat nur die Grafana-Rolle Admin. Die vergibt der SSO-Login an die Pocket-ID-Gruppe `grafana_admins` (eigens dafür, `terraform/netbird/people.tf`; Mitglieder in Pocket ID pflegen, wirksam beim nächsten Grafana-Login), alle anderen bleiben Editor.

**Der Weg:** `dash.homelab.example` ist ein eigener Dienst im Reverse Proxy, **ohne Login**. Sein Ziel ist derselbe Entrypoint `apps` von Traefik auf grammi wie bei `metrics`, aber für diesen Namen lässt Traefik nur `/public-dashboards/`, `/api/public/` und `/public/` (Assets) zu Grafana durch. Alles andere beantwortet Traefik mit 404. Dieser Router hält die App von anonymen Besuchern fern, nicht der Proxy.

| Wer | Weg | Ergebnis |
| --- | --- | --- |
| Jeder mit Link | Reverse Proxy → Traefik `apps` (Host `dash`) → Grafana | nur das freigegebene Dashboard, lesend |
| SSO | `metrics.homelab.example` | volle App |

**Link weitergeben:** Grafana baut den Link aus `root_url`, er lautet also `https://metrics.homelab.example/public-dashboards/<token>` – unter `metrics` landet ein Gast beim SSO-Login. Den Link für Gäste zeigt das Dashboard „Homelab / Shared dashboards“: ein Timer auf grammi fragt alle 10 Sekunden die Grafana-API ab und schreibt jede Freigabe mit ihrer `dash`-Adresse und den genutzten Template-Variablen als Metrik `grafana_public_dashboard_info` (`hosts/grammi/grafana-shares.nix`). Jedes Dashboard verlinkt oben rechts dorthin („Nach außen teilen“). Die Spalte „Verwalten“ öffnet den Freigabe-Dialog des jeweiligen Dashboards zum Pausieren und Widerrufen – ein Schalter direkt in der Tabelle geht nicht, weil Grafana Panel-Actions seine eigene API nur per POST/PUT aufrufen lässt und das Pausieren PATCH braucht. Die Tokens liegen damit in VictoriaMetrics, sichtbar für alle, die Grafana öffnen können.

**Was das bewusst in Kauf nimmt:**

- Der Token im Link ist das einzige Geheimnis, keine PIN davor. Ein öffentliches Dashboard ist nur lesbar, und in Grafana lässt es sich jederzeit pausieren oder löschen.
- Dashboards mit Template-Variablen teilt Grafana zwar, aber Panels, die eine Variable nutzen (etwa `$job` in Hosts Overview), bleiben für Gäste leer; dafür braucht es eine Kopie ohne Variablen. Die Spalte „Variablen“ in „Homelab / Shared dashboards“ zeigt, welche Freigabe das betrifft. Außerdem braucht jedes Panel die UID seiner Datenquelle; die UIDs sind deshalb in der Provisionierung festgelegt und in allen Dashboards eingetragen (`hosts/grammi/configuration.nix`).
- Wie bei allen Proxy-Namen sieht CrowdSec auf grammi nur, was Traefik im Entrypoint `apps` loggt, nicht den TLS-Teil davor.

### MQTT von außen: TLS-Passthrough zu Home Assistant

`mqtt.homelab.example:8883` ist das Mosquitto-Add-on auf Home Assistant, für MQTT-Geräte, die auch außerhalb der Wohnung laufen (AWTRIX NG auf einem Ulanzi TC002). Überall derselbe Name, derselbe Port und dasselbe Zertifikat, ein Gerät wird also einmal eingerichtet:

| Wo | Weg |
| --- | --- |
| Zu Hause | die OPNsense beantwortet `mqtt.homelab.example` mit HAs LAN-Adresse (lokaler DNS-Eintrag) → HA:8883 direkt, auch ohne Internet |
| Außen | öffentlicher CNAME auf den Reverse Proxy → `netbird-proxy` auf grammi, Port 8883 → durchs Mesh zu HA:8883 |

**HA ist ein NetBird-Peer** (NetBird-Add-on, `terraform/netbird/home-assistant.tf`), in einer eigenen Gruppe `home-assistant` – nicht in `servers`, es erreicht also genau zwei Dinge, und außer dem Proxy erreicht nichts HA. Die DNS-Verwaltung durch NetBird ist für die Gruppe aus: HA löst weiter über die OPNsense auf, auch wenn das Internet weg ist.

**TLS endet in Mosquitto, nicht am Proxy.** Der Service `mqtt` (`terraform/netbird/reverse-proxy.tf`) läuft im L4-Modus `tls` mit dem Peer HA als Ziel: Der Proxy liest nur die SNI und reicht die Verbindung unverändert durch. Für einen L4-Service mit eigenem Port bindet der Proxy diesen Port selbst auf allen Adressen (einen PROXY-Header muss dort nur 127.0.0.1 schicken); grammis Firewall öffnet 8883 in `hosts/grammi/netbird-proxy.nix`.

**Das Zertifikat** gilt für `homeassistant.homelab.example` und `mqtt.homelab.example`. HAs Let's-Encrypt-Add-on holt es per DNS-01 – aber ohne eigenen deSEC-Token (der ließe sich an keine Adresse binden, die Heimadresse wechselt). Es fragt stattdessen dns01proxy auf grammi (`hosts/grammi/dns01proxy.nix`, Provider `dns-httpreq`), unter `https://acme.homelab.example:8446`:

- Der Port ist nur im Mesh offen, und die Policy `home-assistant-acme` lässt nur HA hin. HA löst den Namen über die OPNsense auf (lokaler Eintrag auf grammis Mesh-Adresse, `tofu output acme_proxy_address`), alle anderen Peers über die NetBird-Zone.
- Der Proxy schreibt die TXT-Records mit grammis an die Adresse gebundenem Token. HAs Account (Passwort im Add-on, bcrypt-Hash in `hosts/grammi/dns01proxy.yaml`, `just dns01proxy-key-homeassistant`) darf nur Challenges für die beiden Namen oben beantworten.
- dns01proxy spricht selbst HTTPS und holt sein eigenes Zertifikat für `acme.homelab.example` auf demselben Weg.

**Die beiden lokalen DNS-Einträge** sind Host-Overrides in Unbound auf der OPNsense (Services → Unbound DNS → Overrides), von Hand gesetzt – der API-Schlüssel `inventory-ro` darf nur lesen:

| Name | Adresse | Wozu |
| --- | --- | --- |
| `mqtt.homelab.example` | 198.51.100.168 (HAs LAN-Adresse) | MQTT bleibt im Heimnetz und läuft auch ohne Internet |
| `acme.homelab.example` | 192.0.2.122 (grammis Mesh-Adresse, `tofu output acme_proxy_address`) | HA erreicht dns01proxy; NetBird verwaltet HAs DNS nicht |

Ändert sich HAs Adresse oder grammis Mesh-Adresse (neue Lease, NetBird-Neuregistrierung), muss der Override von Hand nachgezogen werden.

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
