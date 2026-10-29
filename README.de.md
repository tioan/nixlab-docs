# nixlab – Projektdokumentation

Stand: 19.10.2026 · [English](README.md) · [PDF](nixlab-documentation.de.pdf) · [Website](https://tioan.github.io/nixlab-docs/de/)

> Diese Dokumentation beschreibt ein privates Repo. Domain und interne Adressen sind durch Beispielwerte ersetzt: die Domain durch `homelab.example` ([RFC 2606](https://www.rfc-editor.org/rfc/rfc2606)), IPv4 nach [RFC 5737](https://www.rfc-editor.org/rfc/rfc5737) (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), IPv6 nach [RFC 3849](https://www.rfc-editor.org/rfc/rfc3849) (`2001:db8::/32`), der Tailnet-Name durch `example-tailnet.ts.net`. Die echte Mesh-Range ist ein /22 aus RFC 1918. Module, Dokumentation und Build-Werkzeuge sind zusammen mit Claude (Anthropic) entstanden. Lizenz: [MIT](LICENSE).


## Überblick

nixlab ist das Flake-Monorepo für das Homelab **homelab.example**: fünf NixOS-Hosts, ein Mac mini mit nix-darwin und die Admin-Workstation gusto (ein MacBook, nix-darwin + home-manager), dazu drei OpenTofu-Module für den NetBird-Account, die deSEC-API-Tokens und die GitHub-Repos samt Deploy-Keys. Bedient wird alles über ein `justfile` von gusto aus; die Hosts ziehen ihre Konfiguration selbst aus dem privaten GitHub-Repo und aktualisieren sich nachts.

Kurzantwort auf die Frage *„Hast du NixOS und OpenTofu irgendwie miteinander verdrahtet?“*: **Ja, aber bewusst lose – über Dateien im Repo, nicht über ein gemeinsames Tool.** OpenTofu schreibt sops-verschlüsselte Dateien in `hosts/<host>/`, die NixOS-Module beim Build lesen, und beide Seiten lesen dieselbe Dienstliste `hosts/grammi/proxy-services.json`. Kein terranix, kein Tofu-Lauf aus Nix heraus. Details unter [NixOS & OpenTofu](#nixos--opentofu).

Zielgruppe: Leute, die NixOS-Flakes, sops-nix und Terraform/OpenTofu lesen können.

## NixOS & OpenTofu

Ja, beides ist verdrahtet – über das Repo als gemeinsame Schnittstelle. OpenTofu verwaltet das, was außerhalb der Maschinen per API existiert (NetBird-Account, deSEC-Tokens, Pocket-ID-Gruppen); NixOS verwaltet die Maschinen. Die beiden reden nie direkt miteinander: Tofu läuft nur auf dem MacBook über `just`, Nix wertet nie Tofu-State aus.

<figure class="nx-diagram">
<svg viewBox="0 0 680 452" role="img" aria-label="Tofu und NixOS teilen sich nur Dateien im Repo: OpenTofu spricht mit den APIs, seine Ergebnisse landen als Dateien im Repo, und der Nix-Flake liest diese Dateien" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-ts{font-size:12px}.nx-tx{font-size:11px}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}.nx-blue rect{fill:#e6f1fb;stroke:#185fa5}.nx-blue .nx-t{fill:#042c53}.nx-blue .nx-s{fill:#185fa5}</style>
<text class="nx-t" x="16" y="24">Tofu und NixOS teilen sich nur Dateien im Repo</text>
<text class="nx-s" x="16" y="42">Pfeile zeigen, wohin Daten fließen</text>
<text class="nx-s" x="76" y="78" text-anchor="middle">API (per Netz)</text>
<text class="nx-s" x="224" y="78" text-anchor="middle">OpenTofu auf dem MacBook</text>
<text class="nx-s" x="387" y="78" text-anchor="middle">Repo-Dateien</text>
<text class="nx-s" x="571" y="78" text-anchor="middle">Nix-Flake</text>
<path class="nx-line" d="M152 114.0 H136"/><path class="nx-line" d="M142 110.0 L136 114.0 L142 118.0"/><path class="nx-line" d="M146 110.0 L152 114.0 L146 118.0"/>
<path class="nx-line" d="M152 174.0 H136"/><path class="nx-line" d="M142 170.0 L136 174.0 L142 178.0"/><path class="nx-line" d="M146 170.0 L152 174.0 L146 178.0"/>
<path class="nx-line" d="M152 234.0 H136"/><path class="nx-line" d="M142 230.0 L136 234.0 L142 238.0"/><path class="nx-line" d="M146 230.0 L152 234.0 L146 238.0"/>
<path class="nx-line" d="M296 114.0 H312"/><path class="nx-line" d="M306 110.0 L312 114.0 L306 118.0"/>
<path class="nx-line" d="M312 174.0 H296"/><path class="nx-line" d="M302 170.0 L296 174.0 L302 178.0"/>
<path class="nx-line" d="M296 234.0 H312"/><path class="nx-line" d="M306 230.0 L312 234.0 L306 238.0"/>
<path class="nx-line" d="M462 114.0 H478"/><path class="nx-line" d="M472 110.0 L478 114.0 L472 118.0"/>
<path class="nx-line" d="M462 174.0 H478"/><path class="nx-line" d="M472 170.0 L478 174.0 L472 178.0"/>
<path class="nx-line" d="M462 234.0 H478"/><path class="nx-line" d="M472 230.0 L478 234.0 L472 238.0"/>
<path class="nx-line" d="M462 294.0 H478"/><path class="nx-line" d="M472 290.0 L478 294.0 L472 298.0"/>
<path class="nx-line" d="M296 186 H304 V294.0 H312"/><path class="nx-line" d="M306 290.0 L312 294.0 L306 298.0"/>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="16" y="90" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="112" text-anchor="middle">NetBird API</text><text class="nx-s" x="76" y="129" text-anchor="middle">mesh.homelab.example</text></a>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="16" y="150" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="172" text-anchor="middle">Pocket ID API</text><text class="nx-s" x="76" y="189" text-anchor="middle">auth.homelab.example</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="16" y="210" width="120" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="76" y="232" text-anchor="middle">deSEC API</text><text class="nx-s" x="76" y="249" text-anchor="middle">Token-Verwaltung</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="152" y="90" width="144" height="108" rx="8" stroke-width="1"/><text class="nx-t" x="224" y="142" text-anchor="middle">netbird</text><text class="nx-s" x="224" y="159" text-anchor="middle">terraform/netbird</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="152" y="210" width="144" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="224" y="232" text-anchor="middle">desec-tokens</text><text class="nx-s" x="224" y="249" text-anchor="middle">terraform/desec-tokens</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="312" y="90" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="387" y="112" text-anchor="middle">netbird.yaml</text><text class="nx-s" x="387" y="129" text-anchor="middle">hosts/host/, sops</text></a>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-blue"><rect x="312" y="150" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="387" y="172" text-anchor="middle">proxy-services.json</text><text class="nx-s" x="387" y="189" text-anchor="middle">hosts/grammi/, Klartext</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="312" y="210" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="387" y="232" text-anchor="middle">desec.yaml</text><text class="nx-s" x="387" y="249" text-anchor="middle">hosts/host/, sops</text></a>
<a data-target="peers" tabindex="0" role="link" class="nx-gray"><rect x="312" y="270" width="150" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="387" y="292" text-anchor="middle">expected-peers.json</text><text class="nx-s" x="387" y="309" text-anchor="middle">terraform/netbird/</text></a>
<a data-target="netbird-setup-key" tabindex="0" role="link" class="nx-gray"><rect x="478" y="90" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="112" text-anchor="middle">netbird.nix</text><text class="nx-s" x="571" y="129" text-anchor="middle">modules/, Setup-Key</text></a>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-gray"><rect x="478" y="150" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="172" text-anchor="middle">topology.nix</text><text class="nx-s" x="571" y="189" text-anchor="middle">Grafana-Topologie</text></a>
<a data-target="desec-token" tabindex="0" role="link" class="nx-gray"><rect x="478" y="210" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t" x="571" y="232" text-anchor="middle">acme.nix</text><text class="nx-s" x="571" y="249" text-anchor="middle">modules/, DNS-01-Token</text></a>
<a data-target="peers" tabindex="0" role="link" class="nx-gray"><rect x="478" y="270" width="186" height="48" rx="8" stroke-width="1"/><text class="nx-t nx-tx" x="571" y="292" text-anchor="middle">netbird-expected-peers.nix</text><text class="nx-s" x="571" y="309" text-anchor="middle">hosts/grammi/, Metrik</text></a>
<text class="nx-s" x="16" y="346">tofu apply legt Account, Policies und Tokens an und bekommt Setup-Keys und Tokens zurück;</text>
<text class="nx-s" x="16" y="363">just netbird-key und desec-key verschlüsseln sie per sops für den Ziel-Host ins Repo.</text>
<a data-target="proxy-services" tabindex="0" role="link" class="nx-blue"><rect x="16" y="382" width="316" height="52" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="174" y="406" text-anchor="middle">Beide Seiten lesen proxy-services.json</text><text class="nx-s" x="174" y="423" text-anchor="middle">von Hand gepflegt, Klartext im Repo</text></a>
<a data-target="nixos-to-tofu" tabindex="0" role="link" class="nx-coral"><rect x="348" y="382" width="316" height="52" rx="8" stroke-width="1"/><text class="nx-t nx-ts" x="506" y="406" text-anchor="middle">Läuft selbst auf NixOS (grammi, zummi)</text><text class="nx-s" x="506" y="423" text-anchor="middle">Gegenrichtung: ohne diese Hosts kein tofu apply</text></a>
</svg>
</figure>

Tofu schreibt nie direkt auf einen Host: jedes Ergebnis landet als Datei im Repo und erreicht den Host erst mit dem nächsten Deploy.

### Die Berührungspunkte

#### NetBird-Setup-Key

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/netbird.yaml` | `just netbird-key <host>` (`tofu output setup_keys` → `sops encrypt`) | `modules/netbird.nix` (`sopsFile`) | Einmal-Setup-Key, 24 h gültig |

Der Ablauf für einen neuen Host: Tofu legt den Setup-Key an, `just netbird-key` schreibt ihn verschlüsselt für genau diesen Host (age-Key aus seinem SSH-Host-Key) nach `hosts/<host>/netbird.yaml`, Commit, Deploy innerhalb von 24 h. Der Host registriert sich beim Start selbst; Peers selbst verwaltet Tofu nicht, es findet sie per `data "netbird_peer"` über den Namen.

#### deSEC-Token

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/desec.yaml` | `just desec-key <host>` (`tofu output acme_tokens` → `sops encrypt`) | `modules/acme.nix` (`sopsFile`) | deSEC-Token nur für TXT-Records, VMs auf ihre IP gepinnt |

#### Soll- und Admin-Peers

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `terraform/netbird/expected-peers.json` | `just netbird-apply` (`tofu output expected_peers`, aus den Policies in `expected-peers.tf` berechnet) | `hosts/grammi/netbird-expected-peers.nix` (`builtins.readFile`) | Soll-Anzahl NetBird-Peers je Host als Metrik `netbird_expected_peers`, im NetBird-Dashboard neben der echten Network Map (z. B. aldrin 6, grammi 8) |
| Tofu → NixOS | `terraform/netbird/admin-peers.json` | `just netbird-apply` (`tofu output admin_peers`, aus der Gruppe `admin-workstations`, `admin-peers.tf`) | `flake.nix` (`builtins.readFile`, Option `services.docsSite.allow`) | Mesh-Adressen der Admin-Geräte (v4 und v6 je Gerät) – wer die private Doku lesen darf |

#### proxy-services.json

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| gemeinsam | `hosts/grammi/proxy-services.json` | von Hand | `terraform/netbird/reverse-proxy.tf` (`jsondecode(file(...))`) und `topology.nix` | Name → App, Port, Gruppen der Reverse-Proxy-Dienste |

#### GitHub-Deploy-Key

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Repo → beide | `hosts/<host>/github.yaml` + `github-deploy.pub` | `just github-key <host>` (`ssh-keygen` → `sops encrypt`) | privat: `modules/deploy.nix` (`sopsFile`); öffentlich: `terraform/github` (`file(...)`) | Deploy-Key für `/etc/nixos`; Tofu sieht nur den öffentlichen Teil |

#### NixOS → Tofu

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| NixOS → Tofu | NetBird-Server auf grammi | `hosts/grammi/netbird.nix` | Provider über `https://mesh.homelab.example` | Die API, gegen die Tofu überhaupt erst läuft |
| NixOS → Tofu | Bootstrap-Tokens | `just netbird-setup-owner`, `netbird-proxy-token` (SSH auf grammi, Server-API) | `terraform/netbird/secrets.yaml` bzw. `hosts/grammi/netbird-proxy.yaml` | Owner-PAT, Proxy-Token |

### Tofu-State

Jedes Modul hat genau eine State-Datei im Haupt-Checkout (`terraform/<modul>/<name>.tfstate`), auch wenn ein Rezept aus einem Worktree läuft. Sie hält Setup-Keys und Tokens und ist deshalb mit OpenTofus State-Verschlüsselung verschlüsselt (AES-GCM, Schlüssel per PBKDF2) und **committet**. Die Passphrase ist `tf_state_passphrase` in `terraform/secrets.yaml`, per sops für den Workstation- und den Admin-Key verschlüsselt, eine für alle Module. `terraform/lib.sh` baut daraus `TF_ENCRYPTION`, die Passphrase steht nie in einer Datei. Rezepte, deren Tofu-Aufruf den State geändert hat, committen genau diese Datei sofort danach (andere gestagte Änderungen bleiben unberührt); pushen bleibt Handarbeit. Ein Klartext-State wird nie committet – `tf_init` und der Commit verweigern ihn.

**Wiederherstellen** nach verlorener Workstation: Repo klonen, sops-Key einrichten (siehe [Rezepte](#just-rezepte)), fertig – die Rezepte lesen den State aus dem Checkout. Ohne Workstation-Key entschlüsselt der Admin-Recovery-Key `terraform/secrets.yaml`. `just netbird-import` braucht es nur noch, wenn auch git den State nicht hat. Seit 2026-10-24; davor war der State gitignored und lag nur auf der Workstation (am 2026-10-22 nur noch im Time-Machine-Backup des alten MacBooks).

### Was bewusst nicht verdrahtet ist

- **Keine gemeinsame Host-Liste.** Hosts stehen dreimal: `nixosConfigurations` in `flake.nix`, `local.hosts` in den Tofu-Modulen und `hosts :=` im `justfile`. Ein neuer Host muss an allen drei Stellen eingetragen werden.
- **Kein terranix / kein Tofu im Nix-Build.** Tofu läuft nur auf der Workstation; der State liegt verschlüsselt im Repo ([Tofu-State](#tofu-state)), und Nix wertet ihn nie aus.
- **Kein Provisioning der Maschinen.** Die VMs werden beim Anbieter von Hand angelegt, ursalia/cuckoosegg nach `docs/install-*.md`.
- **Öffentliches DNS** liegt in DNSControl (eigenes Repo, nur per Symlink eingebunden), nicht in Tofu.

Die Grenze ist also: Was Nix aus dem Repo heraus deterministisch bauen kann, macht Nix. Was nur einmal per API erzeugt wird und ein Geheimnis zurückgibt, macht Tofu – und übergibt es verschlüsselt als Datei.

## Secrets, Netzwerk & Zugriff

### Secrets (sops-nix, age)

Jede Host-Datei ist für genau zwei Empfänger verschlüsselt: den age-Key aus dem SSH-Host-Key des Hosts und den Offline-Recovery-Key `admin`. Das MacBook kann Host-Secrets also nicht lesen – `just secrets <host>` editiert sie auf dem Host und holt das Ergebnis zurück. Verschlüsseln für einen Host geht dagegen überall (nur der öffentliche Key ist nötig); genau das nutzen `netbird-key` und `desec-key`.

| Datei | Empfänger | Inhalt |
| --- | --- | --- |
| `hosts/<host>/secrets.yaml` | Host + admin | Deploy-Key, App-Passwörter, OIDC-Clients, restic |
| `hosts/<host>/netbird.yaml` | Host + admin | NetBird-Setup-Key (von Tofu) |
| `hosts/<host>/desec.yaml` | Host + admin | deSEC-Token (von Tofu) |
| `hosts/<host>/github.yaml` | Host + admin | GitHub-Deploy-Key (von `just github-key`) |
| `hosts/<host>/waf.yaml` | Host + admin | Schlüssel des WAF-Bouncers (von `just waf-key`, siehe [WAF](#web-application-firewall)) |
| `terraform/*/secrets.yaml` | workstation + admin | API-Tokens für die Provider |

Der Workstation-Key liegt in 1Password und wird über `SOPS_AGE_KEY_CMD` gelesen, nie als Datei. `env.sh` in jedem Tofu-Modul entschlüsselt die Tokens nur in die Shell des jeweiligen Rezepts.

### Netzwerk

- **NetBird-Mesh** (`192.0.2.0/24` und `2001:db8:203:0::/64`, Peer-Namen unter `peer.homelab.example`): Control Plane auf grammi, Login über Pocket ID. Private Range (RFC 1918) statt CGNAT, weil tailscaled Pakete aus 100.64/10 verwirft, solange beide Clients parallel laufen.
- **Gruppen:** `servers` (alle Hosts außer cuckoosegg), `subraum-devices`, `admin-workstations` (MacBook), dazu Personengruppen aus Pocket ID.
- **Heim-LAN** (`198.51.100.0/24`): Route über ursalia (Metrik 100), die beiden Apple TVs als Rückfall (Gruppe `home-routers`, Metrik 200, eigener Setup-Key per `just netbird-router-key`, keiner Person zugeordnet, in keiner Policy); für Gruppe `home-lan`, nicht für Geräte, die schon zu Hause sind (Posture-Check `not-at-home`). Rosenpass ist seit 2026-10-24 im ganzen Mesh aus (bis 2026-10-31, siehe [macOS-Hosts](#netbird-auf-den-beiden-macs)); „Quantum-Resistance“ in der App der Apple TVs gehört für diese Zeit ebenfalls aus.
- **Anbindung von ursalia:** WLAN ins Hauptnetz des Heim-LANs (Intel AX211, `hosts/ursalia/wifi.nix`): wpa_supplicant, WPA3 mit WPA2-Rückfall, Land DE, alle Bänder, Passwort per sops. Am endgültigen Platz gibt es kein Kabel; eno1 behält DHCP als Rückfall mit schlechterer Routen-Metrik, damit das WLAN die Hauptverbindung bleibt, wenn beide aktiv sind.
- **Anbindung von zorlock:** ebenfalls WLAN (`en1`, Broadcom); `hosts/zorlock/wifi.nix` stellt sicher, dass `homelab` als bevorzugtes Netz eingetragen ist (`networksetup`, fügt nur hinzu, Passwort per sops in `hosts/zorlock/wifi.yaml`). nix-darwin hat kein WLAN-Modul; die Bandwahl bleibt bei macOS.
- **Exit-Nodes und IPv6:** aldrin und zummi als Exit-Nodes für die Gruppe `exit-nodes`; das Mesh ist Dualstack (`2001:db8:203:0::/64`) – siehe [Exit-Nodes & IPv6](#exit-nodes--ipv6).
- **Subraum:** Route über cuckoosegg für `subraum-access`. cuckoosegg selbst darf nur grammis Ingest (TCP 8428/9428) erreichen und nur vom MacBook per SSH erreicht werden.
- **Tailscale** läuft während der Migration noch parallel und dient als Break-Glass: `NIXLAB_DOMAIN=example-tailnet.ts.net just deploy zummi`.

#### Exit-Nodes & IPv6

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

##### Wer darf

Die Pocket-ID-Gruppe `exit-nodes`. Jemand kommt dazu, indem man ihn in Pocket ID (auth.homelab.example) in die Gruppe aufnimmt und danach `just netbird-apply` ausführt; das überträgt die Mitgliedschaft auf die NetBird-Gruppe gleichen Namens und damit auf alle Geräte der Person. Die Policy `exit-nodes` erlaubt nur dieser Gruppe den Weg in die Zugriffsgruppe `exit-node-access` der Routen. Bewusst nicht alle: Wer den Exit-Node nutzt, tritt mit der Adresse des Servers auf.

##### Benutzen

Die Routen sind auf jedem Gerät der Gruppe vorhanden, aber aus (`skip_auto_apply`), bis man eine auswählt – in der NetBird-App unter „Exit Node“ bzw. „Networks“, oder per CLI:

```bash
netbird networks select exit-aldrin
```

```bash
netbird networks deselect exit-aldrin
```

Pro Exit-Node gibt es zwei Routen, `exit-aldrin` (`0.0.0.0/0`) und `exit-aldrin-v6` (`::/0`). Ein Client ab 0.81 koppelt sie über den Namen und zeigt sie als einen Eintrag „0.0.0.0/0, ::/0“: Ein Schalter verlegt v4 und v6, kein IPv6 läuft am Exit-Node vorbei über den eigenen Anschluss. Prüfen lässt sich das mit `curl -4 ifconfig.co` und `curl -6 ifconfig.co`.

##### Auf den Hosts

Routing und NAT richtet der NetBird-Client selbst ein: Masquerade für v4 (NAT44) und v6 (NAT66) auf die öffentlichen Adressen des Hosts, die ACL der Policy in seiner eigenen nftables-Tabelle. `modules/netbird-exit-node.nix` schaltet zusätzlich das Forwarding für beide Familien ein, damit es nicht vom Client abhängt. Reverse-Path-Filter bleibt „strict“, die NixOS-Firewall filtert Forwarding nicht (`filterForward` aus, wie überall).

Warum NAT66 und keine öffentlichen Adressen für die Clients: Die Overlay-Adresse eines Clients gilt im ganzen Mesh, unabhängig vom Exit-Node – eine GUA aus aldrins Netz würde über zummi mit fremder Absenderadresse hinausgehen. Außerdem hat keiner der beiden ein geroutetes Präfix: aldrins /64 ist on-link, zummi hat eine /128.

##### Dualstack im Mesh

Seit 2026-10-25 ist das ganze Mesh Dualstack. Jeder Peer bekommt neben seiner Adresse aus `192.0.2.0/24` eine aus der ULA `2001:db8:203:0::/64` (`ipv6_enabled_groups` = All, `terraform/netbird/main.tf`). Peer-Namen unter `peer.homelab.example` und die Dienstnamen (`s3-admin`, `dokumente`, `doku`, `llm`, `acme`, `terraform/netbird/mesh-services.tf`) haben AAAA neben A; NetBird liefert AAAA nur an Peers, die selbst v6 haben. Die Apple TVs (Client 0.66) bleiben bei v4.

Die Range steht überall neben `192.0.2.0/24`: root-SSH (`modules/ssh.nix`), CrowdSec-Whitelist, Doku-Site, garage-ui auf aldrin, Paperless und Samba auf ursalia, Traefiks `trustedIPs` auf grammi, Caddy auf zorlock. `admin-peers.json` führt pro Gerät v4 und v6. Wer eine neue Allowlist für das Mesh anlegt, trägt beide Ranges ein.

Wechseln die Gruppen in `ipv6_enabled_groups`, vergibt NetBird neue v6-Adressen. Die AAAA-Einträge der Dienste liest Tofu beim Plan; nach so einem Wechsel oder für einen neu registrierten Peer braucht es deshalb ein zweites `just netbird-apply`.

##### Monitoring

Jeder Exit-Node zählt den weitergeleiteten Verkehr je Familie und Richtung in einer eigenen nftables-Tabelle und gibt ihn als `netbird_exit_node_bytes_total` / `netbird_exit_node_packets_total` an den node_exporter. Im Dashboard „Homelab / NetBird“ zeigt der Abschnitt „Exit nodes“ Durchsatz und Volumen. Die Zähler hängen an `postrouting`, nicht an `forward`: Der NetBird-Client setzt `iifname nb-mesh accept` an den Anfang jeder fremden Forward-Chain, Zähler dahinter würden nie erreicht.

##### Provider aus PR #215

Der veröffentlichte NetBird-Provider (v0.0.10) kennt `ipv6_enabled_groups` und `network_range_v6` nicht und setzt sie bei jedem Apply der Account-Settings zurück ([#243](https://github.com/netbirdio/terraform-provider-netbird/issues/243)). Bis [PR #215](https://github.com/netbirdio/terraform-provider-netbird/pull/215) veröffentlicht ist, baut `pkgs/terraform-provider-netbird.nix` den Provider aus diesem PR, und `terraform/netbird/env.sh` setzt ihn per `dev_overrides` ein; Tofu warnt deshalb bei jedem Lauf. Rückbau: Paket, Flake-Output und Block in `env.sh` entfernen, `tofu init -upgrade` ([offener Punkt](#offene-punkte)).

### Zugriff

Öffentlich offen sind nur 22/80/443. root-SSH lässt `modules/ssh.nix` nur von Mesh- oder Tailscale-Adressen zu; jeder Host hat ein eigenes Login-Keypair. Mesh heißt dabei beide Ranges, `192.0.2.0/24` und `2001:db8:203:0::/64` ([Dualstack](#dualstack-im-mesh)).

#### Apps auf grammi: nur über Traefik `:8090`

Mealie, Grist, logchef und Grafana lauschen auf grammi nur auf `127.0.0.1`. Der Reverse Proxy erreicht sie über den Traefik-Entrypoint `apps` (Port 8090), der vor jede App Wartungsschalter und Fehlerseiten setzt ([Wartungsmodus](#wartungsmodus)). VictoriaMetrics (8428) und VictoriaLogs (9428) lauschen weiter auf allen Adressen, weil die anderen Hosts ihre Metriken und Logs über das Mesh dorthin schicken.

**Bewusste Lücke:** `:8090` selbst ist für jeden Mesh-Peer offen (`nb-mesh` ist vertrauenswürdig), ohne die SSO des Proxys. Wer im Mesh ist, erreicht mit dem passenden `Host`-Header jede App direkt, VictoriaMetrics/-Logs sogar ohne Login, weil sie keinen eigenen haben. Das ist so gewollt (2026-10-23): Wer grammi erreicht, entscheiden die NetBird-Policies, und Mealie, Grist, logchef und Grafana verlangen ihren eigenen Login. Neu bewerten, wenn ins Mesh Peers kommen, denen man weniger traut, oder sobald der Proxy per `direct_upstream` auf Loopback zugreifen kann ([offener Punkt](#offene-punkte)).

#### Private Doku: Admin-Geräte, Heimnetz, Login

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
- v4 und v6 je Gerät, wie das Mesh ([Dualstack](#dualstack-im-mesh)). Die v6-Adresse vergibt NetBird neu, wenn sich die Gruppen in `ipv6_enabled_groups` ändern – dann `just netbird-apply` und Deploy von aldrin und ursalia, sonst sieht das Gerät über v6 ein 403.

#### Pocket ID: Admin-Bereich nur von Admin-Geräten

Seit 2026-10-25 beantwortet nginx auf zummi die Admin-Pfade von Pocket ID mit 403, außer die Anfrage kommt von einer Adresse aus `admin-peers.json` – derselben Liste wie bei der privaten Doku. Gesperrt ist alles, was eine Admin-Sitzung oder ein Admin-API-Key kann: `/settings/admin`, Nutzer, Gruppen, OIDC-Clients, APIs, API-Keys, Einstellungen, Audit-Log, Signup-Tokens, SCIM (Liste: `$pocketid_admin_path` in `hosts/zummi/configuration.nix`, nach den Berechtigungen der Routen in Pocket ID 2.19.1 – bei jedem Minor-Update prüfen). Login, Konto-Seiten (`/api/users/me…`), OIDC-Endpunkte und Logos bleiben öffentlich.

Damit die Admin-Geräte mit ihrer Mesh-Adresse ankommen, zeigt eine NetBird-DNS-Zone `auth.homelab.example` nur für `admin-workstations` auf zummis Mesh-Adressen (`terraform/netbird/pocket-id-admin.tf`); der vhost lauscht dafür auf der Wildcard. Alle anderen Peers, auch NetBirds Server auf grammi, behalten den öffentlichen Eintrag.

- Ohne NetBird auf dem Gerät gilt der öffentliche Eintrag: Login geht, der Admin-Bereich antwortet 403. Ein Browser mit eigenem DNS-over-HTTPS umgeht NetBirds DNS ebenso.
- `just pocketid-plan`/`-apply` brauchen deshalb NetBird auf dem MacBook.
- Ein neues Admin-Gerät: in `admin-workstations`, `just netbird-apply`, dann zummi deployen (wie bei der Doku auch aldrin und ursalia).

#### Paperless: von außen Freigabelinks (PIN) und App (SSO)

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

#### Grafana: öffentliche Dashboards über `dash`

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

#### MQTT von außen: TLS-Passthrough zu Home Assistant

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

#### floccus: Tabs und Lesezeichen über `tabs`

floccus synchronisiert Lesezeichen und offene Tabs zwischen Browsern, auch zwischen Profilen auf Geräten außerhalb des Mesh. Ziel ist ein eigener WebDAV-Server auf aldrin (`hosts/aldrin/floccus.nix`): `rclone serve webdav` auf Loopback, davor nginx unter `tabs.homelab.example`, öffentlich.

- **Nicht OpenCloud:** floccus kann nur Basic Auth. OpenCloud bräuchte dafür ein App-Token, und das hätte Zugriff auf alle Dateien des Accounts – in einem Browser auf einem Gerät, das jemand anderes verwaltet. Das Passwort hier erreicht nur ein Verzeichnis mit Tab-Listen.
- **Nicht nginx-DAV:** floccus fragt die Dateigröße per PROPFIND ab, das kann nginx nur mit dem Modul `dav_ext`, und damit müsste nginx bei jedem Update aus dem Quellcode gebaut werden. rclone kommt aus dem Cache und kann alles, was floccus schickt: GET, PUT, DELETE, MOVE, PROPFIND.
- **Account:** einer (`floccus`). `just floccus-password` legt ein zufälliges Passwort in die Zwischenablage und den bcrypt-Hash in `hosts/aldrin/floccus.yaml`; ohne diese Datei tut das Modul nichts. Das alte Passwort gilt bis zum nächsten Deploy von aldrin.
- **Inhalt:** In floccus ist eine Passphrase gesetzt, der Server sieht nur die verschlüsselte Datei.
- **Backup:** `/data/floccus` ist ein eigenes btrfs-Subvolume und bekommt dieselben btrbk-Snapshots wie OpenCloud – lokal, auf demselben Volume.

**In floccus:** Profil mit Sync-Methode WebDAV, URL `https://tabs.homelab.example/`, Benutzer `floccus`, Passwort aus dem Rezept, dieselbe Passphrase auf jedem Gerät. Für Tabs ein Profil vom Typ „Tabs“, für Lesezeichen ein eigenes mit einem anderen Dateinamen – zwei Profile dürfen nie dieselbe Datei teilen. Auf Geräten mit getrennten Browser-Profilen (dienstlich/privat) floccus nur im privaten Profil einrichten.

## Deployment & Betrieb

Die Pull-Hosts (zummi, aldrin, grammi, ursalia) halten `/etc/nixos` als Checkout des privaten GitHub-Repos und bauen sich selbst. cuckoosegg wird gepusht, zorlock und gusto werden auf dem Mac selbst per `darwin-rebuild` umgestellt ([macOS-Hosts](#macos-hosts)).

| Host | Manueller Deploy | Automatisch |
| --- | --- | --- |
| zummi, aldrin, grammi, ursalia | `just ship <host> "<Nachricht>"` = commit, push, `git pull` + `nixos-rebuild switch` auf dem Host | nächtliches Auto-Upgrade, Reboot-Fenster 04:00–06:00 |
| cuckoosegg | `just deploy-push cuckoosegg` (gebaut auf ursalia, kopiert zum Ziel) | ursalia pusht täglich um 06:30 |
| zorlock | `just mac-switch zorlock` (= `deploy-zorlock`: `git pull` + `darwin-rebuild switch` mit sudo, mit Zusammenfassung) | keins |
| gusto | `just mac-switch` auf gusto, aus der Arbeitskopie | keins – `just mac-upgrade` für die Homebrew-Pins |

### Nächtliches Upgrade

`modules/auto-upgrade-git.nix` aktualisiert `nixpkgs`, `nixpkgs-unstable` und `sops-nix`, baut, schaltet um und pusht die neue `flake.lock` mit dem Deploy-Key des Hosts zurück nach GitHub. Der GitHub-Host-Key ist gepinnt, weil niemand zusieht. Ein Konfigurationsfehler, der erst beim Kaltstart auffällt, legt den Host also um 04:00 lahm – bei den VMs gibt es dafür die Konsole des Anbieters.

Hält `just try` einen Host auf einem Themen-Branch, überspringt das Upgrade ihn, bis der Branch gemergt ist ([Branch vor dem Merge testen](#branch-vor-dem-merge-auf-einem-host-testen)).

## Monitoring

Alles landet auf grammi: **vmagent** auf jedem Host schickt Metriken an VictoriaMetrics (`:8428`), **Vector** journald- und nginx-Logs an VictoriaLogs (`:9428`), beides über das Mesh. Grafana (`metrics`) und logchef (`logs`) liegen hinter dem Reverse Proxy mit SSO. Die Exporter je Host kommen aus `modules/metrics.nix`; was keinen eigenen Endpunkt hat, geht über den textfile-Collector von node_exporter (`/var/lib/prometheus-node-exporter-text-files`), geschrieben von kleinen Timern oder Diensten:

| Textfile-Metrik | Host | Quelle |
| --- | --- | --- |
| `tailscale_*` | Hosts mit Tailscale | `tailscale metrics write`, alle 30 s |
| `fwupd_updates_*` | ursalia | `fwupdmgr get-updates` nach jedem Metadaten-Refresh |
| `wifi_link_*` | ursalia | `iw dev wlo1 link` (PHY-Modus, Breite, MCS, NSS), alle 30 s |
| `node_wifi_*`, `wifi_link_*` | zorlock | `system_profiler SPAirPortDataType -json` alle 60 s, dieselben Namen wie auf ursalia (unter macOS ohne Empfangsrate, Retries und eigenen PHY-Modus für den Empfang; SSID/BSSID schwärzt macOS ohne Ortungsdienste auch für root, im Dashboard „n/a“), dazu `wifi_link_noise_dbm` |
| `unit_cgroup_*` | alle Linux-Hosts | CPU-Zeit und Speicher je systemd-Dienst aus seiner cgroup, alle 15 s (`unit-metrics` in `modules/metrics.nix`); zählt alle Prozesse der Unit, Container mit `--cgroups=split` eingeschlossen |
| `esphome_builder_data_bytes` | ursalia | Größe von `/var/lib/esphome-builder` (Toolchain-Cache), stündlich |
| `grafana_public_dashboard_info` | grammi | öffentliche Dashboards aus der Grafana-API mit ihrem `dash`-Link und den genutzten Template-Variablen, alle 10 s |
| `netbird_expected_peers` | grammi | `terraform/netbird/expected-peers.json`, beim Bauen ins System übernommen |

Die Dashboards liegen als JSON in `hosts/grammi/dashboards/` und werden aus dem Repo provisioniert (Änderungen nur per Commit + Deploy von grammi). `topology.json` erzeugt `just topology`. „Export als Bild“ rendert der Grafana Image Renderer auf grammi (Headless-Chromium, nur Loopback `127.0.0.1:8082`); Teilen nach außen siehe [Zugriff](#grafana-öffentliche-dashboards-über-dash).

| Dashboard | Zeigt |
| --- | --- |
| Hosts Overview | Scrape-Ziele, CPU/RAM/Platte/Netz je Host, fehlgeschlagene Units, Zertifikate, Backups (btrbk, restic), ausstehende Firmware, WLAN-Band/-Signal |
| Topology | Hosts, Exporter und Datenflüsse als Graphviz-Diagramm |
| NetBird | Erreichbarkeit der Control Plane je Host; Peers je Host als Soll (Tofu) / known (Network Map) / connected P2P / connected Relay, dazu Abweichungen; Verlauf der Verbindungen, P2P-Latenz, Sync- und Aufbauzeiten; netbird-server (Signal, Relay, gRPC, API); Durchsatz und Volumen der Exit-Nodes aldrin/zummi je IP-Familie ([Exit-Nodes](#monitoring)) |
| WLAN | Band von ursalia und zorlock (2,4 / 5 / 6 GHz) über die Zeit, Kanal, Signal, PHY-Modus, Linkrate, Verkehr, MCS, Retries, Verbindungsdauer |
| Disk Health | SMART/NVMe von ursalia: Status, kritische Warnungen, Verschleiß, Reserve, Temperatur, geschriebene Daten |
| Paperless | Zustand (Celery, Redis, DB, Index, Classifier), Dokumente, Inbox, fehlgeschlagene Tasks, Speicher, Log-Warnungen |
| paperless-gpt | OCR- und Vorschlags-Rückstau, OCR-Zeit je Seite, LLM-Anfragen, -Dauern, -Tokens, -Fehler; GPU und Speicher von zorlock |
| ESPHome builds | Build-Server auf ursalia: Zustand, ESPHome-Version, Builds und Erfolgsquote, Dauer je Build und Gerät, CPU und Speicher neben Paperless, Größe des Toolchain-Caches, Warnungen. Builds und Dauern kommen per LogsQL aus den Log-Zeilen „Starting job …“ / „Job … completed/failed“, device-builder hat keinen Metrik-Endpunkt |
| Shared dashboards | Alle öffentlichen Dashboards mit dem Link für Gäste (`dash.homelab.example`) ob sie pausiert sind und welche Variablen sie nutzen (deren Panels bleiben für Gäste leer); jedes Dashboard verlinkt oben rechts hierher |
| Web & Security | Anfragen an nginx und Traefik, Statuscodes, Dauern; CrowdSec-Bans, -Alerts, Parser-Treffer |
| Garage (S3 storage) | Garage auf aldrin: Cluster-Zustand, Platte, S3-Anfragen/-Fehler/-Dauer, Resync- und GC-Warteschlangen |
| VictoriaMetrics & VictoriaLogs | Ingest-Rate, Plattenbelegung, Abfragedauer, aktive Serien |
| zorlock (Mac mini) | mactop: Thermal State, CPU/GPU, Leistung, Temperaturen, Speicher, Lüfter; Ollama-Anfragen, -Geschwindigkeit, Ladezeiten der Modelle |

**Soll gegen known (NetBird):** „expected“ berechnet OpenTofu aus den Policies mit der Gruppenmitgliedschaft beim letzten `just netbird-apply` (Beispiel: aldrin 6, grammi 8, cuckoosegg 4). „known“ ist, was der Management-Server tatsächlich verteilt. Ein später hinzukommendes Gerät erhöht known sofort, das Soll erst nach dem nächsten Apply + Deploy von grammi – gewollt, damit ein neuer Peer auffällt. Das Modell ignoriert Posture Checks; siehe Kopf von `expected-peers.tf`.

**Log-Level:** Vector macht aus journalds `PRIORITY` das Feld `level`. Python-Dienste schreiben ihr Log nach stderr, journald stuft dann jede Zeile als Fehler ein. Zeilen im Format `<Datum> <Zeit> INFO|WARNING|ERROR …` bekommen deshalb das Level aus dem Text, ohne Farbcodes (`modules/log-shipping.nix`).

**Grafana-Falle:** State-Timelines mit `mergeValues` und Farbmodus „thresholds“ machen aus Zahlen Schwellwert-Stufen („1+“, „< 1“), bevor die Wert-Zuordnungen greifen. Farbmodus „fixed“ verwenden und Text und Farbe in die Zuordnungen legen.

## Web Application Firewall

CrowdSec liest auf jedem Host die Access-Logs von nginx und Traefik und sperrt Adressen, die auffallen (`modules/crowdsec.nix`). Das geschieht im Nachhinein: Der eine Request, der eine Lücke ausnutzt, ist dann schon beim Dienst angekommen. Die WAF (`modules/waf.nix`, seit 2026-10-25) prüft jeden Request, bevor nginx ihn weiterreicht – mit CrowdSecs AppSec-Komponente, also derselben Engine, denselben Alerts und denselben Bans.

### Aufbau

| Teil | Was es tut |
| --- | --- |
| OpenResty | ersetzt nginx (dasselbe NixOS-Modul, Lua eingebaut) |
| Lua-Bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | schickt in der Access-Phase jeden Request der gelisteten vhosts an AppSec auf `127.0.0.1:7422` und setzt dessen Antwort um |
| AppSec (Teil von CrowdSec) | wertet die Regeln aus, erzeugt Alerts |
| Firewall-Bouncer | setzt Bans wie bisher in nftables um, auf allen Ports |

Ist CrowdSec nicht erreichbar, lässt nginx die Requests ungeprüft durch (`APPSEC_FAILURE_ACTION=passthrough`) – Pocket ID soll nicht mit CrowdSec ausfallen.

### Regeln

| Regeln | Phase | Folge |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – rund 200 Regeln für bekannte CVEs (PHP-CGI, Spring4Shell, Grafana File Read, …) | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Methoden-Allowlist pro Name (`services.waf.allowedMethods`) – auf `auth.homelab.example` nur GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | kein Block; mehr als 5 Treffer in 30 s bannen die IP |

Jeder In-band-Treffer bekommt 403. Gebannt wird die IP, sobald zwei *verschiedene* In-band-Regeln innerhalb von 60 s treffen (`crowdsecurity/appsec-vpatch`: capacity 1 mit `distinct: rule_name`) – dieselbe Regel wiederholt füllt den Bucket nicht. Wer Scanner sucht, trifft in der Regel schnell mehrere.

Die beiden eigenen Regeln sind das grobe Netz unter den CVE-Regeln: Kein öffentlicher Dienst hier führt PHP, ASP, JSP oder CGI aus, also ist jede Anfrage danach ein Scan oder ein Exploit – auch für eine Lücke, für die es noch keine eigene Regel gibt. Die CRS läuft nur out-of-band, weil sie breit ist und einzelne Fehlalarme kein Grund sein sollen, einen legitimen Nutzer auszusperren.

Ausnahmen pro Name: `services.waf.ruleExclusions."<fqdn>" = [ "<regel>" ];`. OpenCloud (aldrin) braucht das für `homelab/no-server-side-scripts`, weil es ownClouds `/remote.php`, `/status.php` und `/ocs/v*.php` für die Desktop-Clients beibehält.

### Modi

- **`detect`** (Standard für jeden neuen Host): In-band-Treffer bekommen „allow“, die Ban-Szenarien der WAF laufen in der Simulation. Alerts erscheinen in `cscli alerts list` und in der Console mit „(simul)“, gesperrt wird durch die WAF nichts.
- **`block`**: In-band-Treffer bekommen 403, die IP wird gebannt.

Die log-basierten HTTP-Szenarien aus `modules/crowdsec.nix` hängen nicht am Modus und bannen wie bisher.

### Hosts

| Host | vhosts | Modus |
| --- | --- | --- |
| zummi | `auth.homelab.example` (Pocket ID) | detect (Pilot seit 2026-10-25) |

Geplant: grammi (Traefik-Plugin, nur Dashboard, `/oauth2/` und die öffentlichen Grafana-Pfade), aldrin (garage-ui, OpenCloud). Nie durch die WAF: Garages S3-API und NetBirds gRPC/Relay/API – signierte oder binäre Bodies, nichts für die Regeln zu finden, viel falsch zu lesen.

### Einen Host anschließen

1. `services.waf = { enable = true; nginx.vhosts = [ "<vhost>" ]; };` in der Host-Konfiguration, `./modules/waf.nix` in der Modulliste des Hosts in `flake.nix`, `waf` in die Zeile des Hosts in `.sops.yaml`.
2. Deployen. Die AppSec-Engine läuft dann schon; nginx fragt sie noch nicht (Warnung beim Evaluieren).
3. `just waf-key <host>` – registriert den Bouncer `nginx-appsec` beim LAPI des Hosts und schreibt den Schlüssel nach `hosts/<host>/waf.yaml`. Committen, deployen.
4. Prüfen: `cscli bouncers list` zeigt `nginx-appsec` mit frischem „Last API pull“; `curl -I https://<vhost>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` erzeugt einen Test-Alert (`cscli alerts list`).
5. Nach ein, zwei Wochen ohne Fehlalarme: `mode = "block";`.

Quellen: Die nginx-Einbindung folgt CrowdSecs [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) aus cs-nginx-bouncer v1.2.3; die Lua-Bibliothek ist CrowdSecs [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633).

## macOS-Hosts

Zwei Maschinen in diesem Repo laufen mit macOS und nix-darwin statt NixOS: **zorlock**, der Mac mini mit Ollama, und **gusto**, das MacBook, die Admin-Workstation. Beide sind `darwinConfigurations` im selben Flake und nutzen dasselbe für macOS getestete nixpkgs (`nixpkgs-darwin`). Ansonsten sind sie Gegensätze – der eine ein Server, an dem niemand sitzt, der andere ein Laptop, der nur von einem Menschen benutzt wird – und manches ist deshalb bewusst unterschiedlich gelöst. Diese Seite erklärt, was beide teilen, wo sie sich unterscheiden und warum.

| | zorlock | gusto |
| --- | --- | --- |
| Rolle | LLM-Server (Ollama für paperless-gpt) | Admin-Workstation: Deploys, Secrets, Tofu, Doku |
| Konfiguration | `hosts/zorlock/` | `hosts/gusto/` (System) + `home.nix`, `ssh.nix` (home-manager) |
| Gebaut und geschaltet | auf zorlock, aus `/etc/nixos` (`just mac-switch zorlock`) | auf gusto, aus der Arbeitskopie (`just mac-switch`) |
| Homebrew | aus | an – die Apps sind Casks |
| Softwareliste | in `configuration.nix` | `hosts/gusto/apps.json` – `apps`, `apps-rm` |
| home-manager | nein | ja, für admins Dotfiles |
| NetBird-Client | nix-darwin `services.netbird`, Client aus `nixpkgs-netbird` | Homebrew-Cask `netbird-ui` aus NetBirds Tap |
| NetBird-Anmeldung | Setup-Key aus sops, unbeaufsichtigt | SSO (Pocket ID) in der App |
| SSH hinein | ja, als admin, nur Schlüssel | nein – Entfernte Anmeldung bleibt aus |
| sops-Secrets | ja (Deploy-Key, deSEC-Token, NetBird-Key, WLAN) | keine |
| Monitoring, Logs | vmagent, Vector → grammi | keins – nicht in der Topologie |
| Verfügbarkeit | immer an (`criticality: service`) | zeitweise (`kind: laptop`) |

Keins der `modules/*.nix` gilt für die Macs – diese Module sind für NixOS geschrieben (systemd, ifstate, nginx). Was sich übertragen lässt, steht in der `configuration.nix` des jeweiligen Hosts in nix-darwin-Form. Das einzige Modul, das beide teilen, ist `modules/darwin/homebrew.nix`.

### Homebrew: eine Richtlinie für beide Macs

Manche macOS-Software gibt es nur als Homebrew-Cask, oder sie soll vom Hersteller signiert kommen: 1Password, Vivaldi, Arq, Ghostty, die NetBird-App. `modules/darwin/homebrew.nix` wird von jeder `darwinConfiguration` importiert und legt eine Richtlinie fest (entschieden am 2026-10-21). Sie greift nur, wo ein Host `homebrew.enable = true` setzt – heute gusto; auf zorlock ändert das Modul nichts, seine System-Closure ist mit und ohne es identisch.

**Homebrew und seine Taps sind in `flake.lock` festgeschrieben.** Homebrew selbst wird nicht mit dem `curl | bash`-Skript installiert, sondern über den Input `nix-homebrew`. `homebrew-core`, `homebrew-cask` und jeder Drittanbieter-Tap sind Flake-Inputs (`flake = false`), dazu `mutableTaps = false`. Es gibt keinen Git-Checkout, den `brew update` verschieben könnte: Welche Version eines Casks ein Switch installiert, hängt allein an `flake.lock` – dieselbe Logik wie bei nixpkgs. Ein Host fügt einen Tap mit einer Zeile hinzu,

```nix
nix-homebrew.taps."netbirdio/homebrew-tap" = inputs.netbirdio-tap;
```

und `homebrew.taps` (die Liste, die nix-darwin in den Brewfile schreibt) ergibt sich daraus automatisch.

**Homebrews eigene Version ist per Tag festgeschrieben.** nix-homebrew bringt einen eigenen Homebrew-Pin mit (7.0.4, Stand 2026-10-28), der hinter den Casks zurückbleibt: Seit [Homebrew/brew#24369](https://github.com/Homebrew/brew/pull/24369) (2026-10-27) schreibt homebrew-cask `zap :not_required`, das erst Homebrew 7.0.11 versteht ([Homebrew/brew#24315](https://github.com/Homebrew/brew/pull/24315)) – mit 7.0.4 brach `brew bundle` bei `android-platform-tools` ab. Deshalb hat `flake.nix` einen eigenen Input `brew-src` auf einem Release-Tag und lenkt nix-homebrew darauf um (`nix-homebrew.inputs.brew-src.follows`); `modules/darwin/homebrew.nix` benennt das Paket nach diesem Tag, damit der Switch-Diff die echte Version zeigt (`brew --version` taugt dafür nicht: Es meldet bei jedem Pin `>=4.3.0 (shallow or no git repository)`). `just mac-upgrade` verschiebt kein Tag – Homebrew zu aktualisieren heißt, diese Zeile zu ändern. Sobald nix-homebrew selbst 7.0.11 oder neuer pinnt, fallen Input und `follows` wieder weg.

**Ein Switch tut, was in der Konfig steht – und sonst nichts.**

- `onActivation.autoUpdate = false`: kein `brew update` beim Switch.
- `onActivation.upgrade = false`: auch kein `brew upgrade` beim Switch; ein installierter Cask bleibt auf seiner Version, bis er gezielt aktualisiert wird.
- `onActivation.cleanup = "zap"`: Was installiert, aber nicht deklariert ist, wird entfernt, Casks samt ihren App-Daten (`brew uninstall --zap`). Einen Cask aus der Konfiguration (`apps.json`) zu löschen, deinstalliert die App also wirklich mit ihren Einstellungen. Das gilt auch für Mac-App-Store-Apps (früher ließ Homebrew sie in Ruhe). `just mac-diff` zeigt das, bevor es passiert, und `just mac-switch` hält davor an: Würde der Switch etwas entfernen, zeigt er die Liste und fragt `[y/N]`, ohne Terminal bricht er ab. `MAC_SWITCH_ALLOW_REMOVALS=1 just mac-switch` geht ohne Frage weiter. Meist ist die Lösung aber, das Fehlende in `apps.json` einzutragen (entschieden am 2026-10-23, nachdem ein Switch drei von Hand installierte App-Store-Apps entfernt hätte).
- `global.autoUpdate = false` und `global.brewfile = true`: dasselbe für `brew` von Hand, und `HOMEBREW_BUNDLE_FILE` zeigt auf den erzeugten Brewfile, sodass ein einfaches `brew bundle check` gegen die Konfig vergleicht.

Apps mit eigenem Updater und Mac-App-Store-Apps aktualisieren sich weiter selbst; die Richtlinie betrifft nur, was Homebrew tut.

**Kein `brew shellenv`.** Weder die Shell-Integration von nix-darwin noch die von nix-homebrew wird genutzt – beide würden in jeder neuen Shell `brew shellenv` ausführen und Homebrew *vor* Nix in den `PATH` stellen. Stattdessen kommen `/opt/homebrew/bin` und `sbin` direkt in den System-`PATH`, hinter die Nix-Profile und vor die macOS-eigenen Verzeichnisse:

```text
~/.nix-profile/bin : /etc/profiles/per-user/$USER/bin : /run/current-system/sw/bin : /nix/var/nix/profiles/default/bin : /opt/homebrew/bin : /opt/homebrew/sbin : /usr/local/bin : /usr/bin : …
```

Ein Tool aus Nix gewinnt immer gegen dasselbe Tool aus Homebrew, Homebrew gegen Apples Platzhalter, und beim Öffnen einer Shell läuft kein `brew`.

#### Die mac-*-Rezepte

| Rezept | Was es tut |
| --- | --- |
| `just mac-diff [host]` | Baut die Konfig und zeigt, was ein Switch ändern würde: die Nix-Closure (`nvd diff`), die Casks und Formulae, die **entfernt** würden (`brew bundle cleanup --zap` ohne `--force`), und die, die **installiert** würden. Ändert nichts. |
| `just mac-switch [host]` | Baut, hält an, falls Homebrew etwas entfernen würde (siehe oben), schaltet und endet mit einer kompakten Zusammenfassung: Nix-Pakete neu/entfernt/aktualisiert (nvd) und Homebrew `- entfernt` / `+ neu`. |
| `just mac-upgrade` | Aktualisiert nur die Homebrew-Pins (`nix-homebrew` und jeder Input aus einem Repo `github:<owner>/homebrew-<name>` – `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap`, gefunden in `flake.lock`), schaltet, führt `brew upgrade` aus und zeigt `alt -> neu` je aktualisiertem Paket, dazu die NetBird-Client-Version auf gusto neben dem Pin des Mesh. Ergebnis ist eine Änderung an `flake.lock`, die committet wird. |

Standard-Host ist `gusto`, gebaut aus der Arbeitskopie (auch mit nicht committeten Änderungen – nix sieht aber nur Dateien, die git kennt, neue also erst `git add`). `zorlock` wird per SSH erreicht: `git pull` in `/etc/nixos`, dann dasselbe Skript mit sudo. `deploy-zorlock` und `check-zorlock` sind jetzt Kurzformen von `mac-switch zorlock` und `mac-diff zorlock`. Die eigentliche Arbeit macht `modules/darwin/rebuild.sh` auf dem Mac.

`mac-upgrade` gibt es nur für gusto: Es ändert `flake.lock`, und das wird auf der Workstation committet; zorlock hat kein Homebrew.

#### Software als Daten: apps.json

Was ein Mac installiert – Casks, Homebrew-Formeln, Mac-App-Store-Apps und nixpkgs-Pakete – steht nicht in seiner `configuration.nix`, sondern in `hosts/<host>/apps.json` (entschieden 2026-10-22; heute gusto, zorlock nutzt es nicht). `modules/darwin/apps.nix` macht daraus `homebrew.casks`, `homebrew.brews`, `homebrew.masApps`, `environment.systemPackages`, die `home.packages` des Benutzers und `fonts.packages`. Jeder Eintrag heißt so wie in seiner Quelle und trägt eine `note` (warum er da ist) und das Datum `added`; nixpkgs-Einträge zusätzlich einen `scope` (`system`, `user`, `font`). Taps bleiben Nix, in der Konfiguration des Hosts – sie sind Flake-Inputs; `apps` kann einen anlegen (unten).

Die Datei ist mit Absicht Daten: Ein Werkzeug kann Einträge hinzufügen und entfernen, ohne Nix zu parsen, und die Konfiguration prüft sie bei jeder Auswertung – unbekannte Quellen oder Felder, ein nixpkgs-Attribut, das es nicht gibt, ein Eintrag aus einem Tap, den der Host nicht pinnt – und listet alle Probleme auf einmal (`checks.darwin-apps`). `modules/darwin/apps.schema.json` liefert im Editor Vervollständigung und Hover-Hilfe.

`apps` ist dieses Werkzeug (`pkgs/nixlab-apps`): eine Runde aus Suchen, Hinzufügen und Entfernen, dann ein Switch und ein Commit. Es sucht online in nixpkgs, Homebrew und dem Mac App Store, fasst Treffer derselben Software zusammen und markiert die empfohlene Quelle – für eine GUI-App Cask vor App Store vor nixpkgs (signiert, in `/Applications`, aktualisiert sich selbst), für ein Kommandozeilenwerkzeug nixpkgs vor einer Formel. Die Auswahl wird dann gegen den **Pin** geprüft, denn ein Switch installiert, was in `flake.lock` steht, nicht was die Suche gezeigt hat: Ein nixpkgs-Paket muss in `nixpkgs-darwin` auswertbar sein (verfügbar, nicht unfree), ein Cask oder eine Formel muss im gepinnten Tap liegen. Fehlt ein Cask oder eine Formel, kann das Werkzeug `homebrew-cask` / `homebrew-core` in einem eigenen Commit aktualisieren – harmlos, `upgrade = false` lässt installierte Casks in Ruhe. `nixpkgs-darwin` wird dort nie angefasst: Das ist das ganze System beider Macs. Die gepinnten Drittanbieter-Taps durchsucht es ebenfalls, offline aus ihrem Pin; einen Cask aus einem noch nicht gepinnten Tap findet es über den vollen Namen (`apps stablyai/orca/orca`), und die Auswahl pinnt den Tap – Flake-Input, Zeile in `nix-homebrew.taps`, `nix flake lock`, eigener Commit –, nachdem es gezeigt hat, wer ihn veröffentlicht, und gefragt hat. Diese Frage ist die Vertrauensentscheidung: Jedem gepinnten Tap wird vertraut (entschieden 2026-10-23, mit Orca als erstem solchen Tap). Schritte: [Software auf den Macs](#software-auf-den-macs).

### NetBird auf den beiden Macs

Beide Macs sind Peers im NetBird-Mesh, bekommen ihren Client aber auf zwei verschiedenen Wegen. Das ist Absicht.

#### zorlock: nix-darwin-Modul, Client aus dem Mesh-Pin

`hosts/zorlock/netbird.nix` schaltet nix-darwins `services.netbird` ein. Das Modul startet nur den Daemon – `netbird service run` als launchd-Daemon, als root, Zustand in `/var/lib/netbird` – und überlässt Anmeldung und Einstellungen dem Benutzer. Den Rest erledigt ein zweiter launchd-Job, `netbird-login`, nach demselben Muster wie auf den Linux-Hosts:

- Das **Client-Binary** kommt aus dem Input `nixpkgs-netbird`, dem Pin, den der NetBird-Server auf grammi und alle NixOS-Clients nutzen. Das ganze Mesh zieht gemeinsam mit `nix flake update nixpkgs-netbird` um – Server zuerst, dann die Clients.
- Die **Anmeldung** läuft unbeaufsichtigt: `netbird-login` registriert sich einmal mit einem Einmal-Setup-Key aus `hosts/zorlock/netbird.yaml` (sops, `just netbird-key zorlock`). Danach ist der Key verbraucht, die Identität des Peers liegt in `/var/lib/netbird/config.json`.
- **Rosenpass** schaltet derselbe Job aus (seit 2026-10-24 im ganzen Mesh aus, bis 2026-10-31, siehe unten), den lokalen Prometheus-Endpunkt des Clients (`127.0.0.1:9191`, von vmagent abgefragt) ein – das nix-darwin-Modul hat kein `config.d` wie das NixOS-Modul.
- Nach einem Neustart kommt zorlock erst ins Mesh, wenn FileVault entsperrt ist (per SSH aus dem Heim-LAN), weil der Daemon auf dem Datenvolume liegt.

Das braucht ein Server: keine GUI-Sitzung (zorlock soll abgemeldet bleiben, Ollama zählt freien Arbeitsspeicher), von selbst wiederkommen, dieselbe Client-Version wie der Rest des Mesh und Metriken.

#### gusto: die offizielle App als Homebrew-Cask

gusto installiert `netbirdio/homebrew-tap/netbird-ui`, den Cask aus NetBirds eigenem Tap, festgeschrieben als Flake-Input `netbirdio-tap` (entschieden am 2026-10-21). Der Cask ist die signierte Menüleisten-App; er hängt von der Formula `netbird` aus demselben Tap ab (CLI und Daemon), und sein Installer registriert den Daemon als `/Library/LaunchDaemons/netbird.plist`. Das ist dieselbe Software, die auch das offizielle `.pkg`-Installationspaket auf einen Mac bringt, nur über die Konfig installiert und entfernt. Die Formula steht zusätzlich einzeln in der Konfig (`homebrew.brews`), damit `cleanup = "zap"` den Daemon nie als verwaist ansieht und unter der App wegzieht.

- Die **Anmeldung** ist interaktiv: in der App, per SSO über Pocket ID – der Peer gehört dann zum Benutzer des Admins und seinen Gruppen, wie es sich für das Gerät eines Menschen gehört. Es gibt keinen Setup-Key und keine sops-Datei für gusto.
- **Rosenpass** wird einmal in den Einstellungen der App gesetzt (Quantum-Resistance); der Daemon behält das in seiner eigenen Konfig. Seit 2026-10-21 ist es auf der Workstation **aus** – ein Test gegen Tunnel, die nach dem Ablauf des Rosenpass-Schlüssels ohne WireGuard-Handshake auf „Connected“ stehen blieben (upstream #3107, #3121); gusto startet genauso, aus. Die toten Tunnel kamen trotzdem wieder, zwischen zwei Peers, die beide Rosenpass sprachen (ursalia↔zorlock, 2026-10-23: Schlüssel ohne Erneuerung abgelaufen, danach verschiedene Pre-Shared-Keys auf beiden Seiten, kein Handshake mehr – und Rosenpass läuft selbst durch diesen Tunnel). Deshalb ist Rosenpass seit 2026-10-24 im **ganzen Mesh aus**, eine Woche lang bis 2026-10-31; die Apps (iPhone, Apple TVs, Home Assistant) von Hand. Danach wird entschieden: keine toten Tunnel mehr – es bleibt aus, bis upstream das Re-Keying repariert; tote Tunnel trotzdem – Rosenpass war nicht die Ursache und kommt permissiv wieder.
- **Version**: das, was der festgeschriebene Tap enthält. Sie ändert sich nur mit `just mac-upgrade`, das die Client-Version von gusto neben der von `nixpkgs-netbird` anzeigt, damit die beiden nicht weit auseinanderlaufen. Die übliche Regel gilt weiter: Zuerst wird der Server (grammi) aktualisiert, die Clients folgen.
- **Updates von anderswo**: Der eigene Update-Hinweis der App und das über das Dashboard gesteuerte Auto-Update von NetBird dürfen die Version nicht an der Konfig vorbei verschieben; das wird beim ersten Switch geprüft und abgeschaltet, falls die App es anbietet.
- Kein Metrik-Endpunkt und kein Log-Versand – gusto wird nicht überwacht.

#### Warum nicht auf beiden gleich?

| Frage | Antwort |
| --- | --- |
| Warum nutzt gusto nicht das nix-darwin-Modul wie zorlock? | Das Modul hat keine Menüleisten-App; alles liefe über die Kommandozeile. Auf einem Laptop, der ständig das Netz wechselt, sieht man über die App auf einen Blick, ob das Mesh steht, wechselt Profile und meldet sich neu an. Die Anmeldung ist auf gusto ohnehin SSO, und dafür braucht es einen Browser und einen Menschen – der unbeaufsichtigte Setup-Key-Job, der zorlocks Variante lohnend macht, entfällt. |
| Warum nutzt zorlock nicht den Cask? | Ein Server muss nach einem Neustart von selbst wiederkommen, ohne dass sich jemand anmeldet, mit derselben Client-Version wie das Mesh und mit Metriken. Die App des Casks braucht eine GUI-Sitzung, und ihre Version folgt dem Tap, nicht dem Mesh-Pin. |
| Warum nicht `netbird-ui` aus nixpkgs auf gusto? | nixpkgs paketiert die UI in erster Linie für Linux; ob sie auf macOS sauber baut und läuft (Signatur, Menüleiste), ist nicht geprüft, und es wäre nicht das signierte Binary, das NetBird ausliefert. |
| Mac App Store? | NetBird bietet keine Version im Mac App Store an (nur für iOS). |
| Was kostet es? | Die Client-Version von gusto ist getrennt von der des Mesh festgeschrieben (`netbirdio-tap` statt `nixpkgs-netbird`). `just mac-upgrade` macht den Abstand sichtbar; geschlossen wird er von Hand. |

#### Der Peer in Tofu

`terraform/netbird/subraum.tf` holt sich die Admin-Workstation über den Peer-Namen (`data "netbird_peer"`) für die Gruppe `admin-workstations` – die Gruppe, die die Subraum-Geräte und die Doku-Site erreichen darf. Ein Wechsel der Workstation (altes MacBook → gusto) läuft mit beiden Peers kurz parallel in der Gruppe: zweiter data source `gusto`, `just netbird-apply`, aldrin und ursalia deployen (Freigabeliste der Doku-Site), testen, erst dann den alten Peer entfernen.

### gusto im Einzelnen

Hier die Gründe hinter gustos Aufbau; die vollständige Liste, was darauf ist, jede Einstellung und die Abläufe im Alltag stehen unter [gusto – die Admin-Workstation](#gusto--die-admin-workstation).

#### Nackt starten

gusto wurde bewusst schlank aufgesetzt (2026-10-21): keine App-Liste aus der alten Installation übernommen, nur eine kleine Grundausstattung. Alles Weitere kommt dazu, sobald es gebraucht wird – `apps` (in `hosts/gusto/apps.json`, Switch, Commit), und falls es Daten gibt, kommen sie aus dem Backup zurück.

| Wo | Was |
| --- | --- |
| Casks | 1Password + `1password-cli`, Vivaldi, Arq, Claude, Ghostty, NetBird |
| System (`environment.systemPackages`) | git, gh, just, jq, neovim (`EDITOR`), curl, wget, rsync |
| admin (home-manager) | zsh, atuin, fzf, zoxide, direnv + nix-direnv, bat, eza, ripgrep, fd, tree, lazygit, btop, yazi, tmux, nvd, nix-output-monitor, uv, typst |
| Schrift | Maple Mono NF (Nerd Font) für Ghostty und die TUIs |
| Repo-Werkzeuge | sops, age, ssh-to-age, opentofu, nvd – aus der devShell des Flakes; dnscontrol aus einer eigenen für das DNSControl-Repo, siehe unten |

`op` kommt als Cask und nicht aus nixpkgs, weil die CLI über die 1Password-App mit Touch ID entsperrt – das geht nur mit dem signierten Binary des Herstellers.

#### XDG und home-manager

Projektregel: Konfiguration liegt unter `~/.config/<tool>`, wo immer das Tool es unterstützt – zsh (`ZDOTDIR=~/.config/zsh`), git (`~/.config/git/config`), Ghostty, tmux, direnv. Ein Tool ohne XDG-Unterstützung behält die echte Datei am klassischen Ort und bekommt einen Link `~/.config/<tool>` darauf, z. B. `~/.config/ssh → ~/.ssh`. Daten landen in `~/.local/share`, Zustand (zsh-Verlauf) in `~/.local/state`.

Der `PATH` bekommt genau ein persönliches Verzeichnis, `~/.local/bin`: `GOBIN` zeigt dorthin, `CARGO_INSTALL_ROOT` ist `~/.local`, und `uv tool install` nutzt es von sich aus. `GOPATH` und `CARGO_HOME` liegen unter `~/.local/share`. Kein `~/go/bin`, `~/.cargo/bin` oder pnpm-Pfad mehr.

git: Name `admin`, Standardadresse `mail@admin.org`; für alles unter `~/Projects/homelab/` schaltet ein `includeIf gitdir:` auf `admin@homelab.example` um.

#### SSH: nur 1Password

Die privaten Schlüssel gibt es nur in 1Password; dessen Agent bietet sie an. Zwei Links machen den Agent unter einem Pfad ohne Leerzeichen erreichbar: `~/.1password/agent.sock` (home-manager) und `SSH_AUTH_SOCK` – in jeder Shell (home-manager) und für GUI-Apps über `launchd.user.envVariables`.

`~/.ssh/config` erzeugt home-manager (`hosts/gusto/ssh.nix`):

- **Globale Zeilen zuerst**, vor jedem `Host`-Block (`extraOptionOverrides`): `IdentityAgent`, `IdentitiesOnly`, `Compression`, `SendEnv`. Der erste Wert, den ssh findet, gewinnt – kein späterer Block und keine eingebundene Datei kann den Agent woandershin lenken. Genau daran war die alte Konfig gescheitert: Ein `Host *` in einer eingebundenen Datei schickte IdentityAgent zum Agent eines anderen Benutzers.
- **Ein Schlüssel pro Ziel**: `IdentityFile` nennt die *öffentliche* Hälfte (`hosts/gusto/ssh/*.pub`, verlinkt nach `~/.ssh/pub/`). Daran erkennt der Agent, welchen Schlüssel er anbieten soll; die private Hälfte liegt nie auf der Platte.
- **Lab-Hosts werden erzeugt** aus `inventory.json` – jeder verwaltete Host außer gusto: `<host>` / `<host>.peer.homelab.example` über das Mesh als root (zorlock als admin); `<host>.example-tailnet.ts.net`, solange Tailscale noch läuft; und für Hosts mit öffentlicher Adresse (aldrin, grammi, zummi) `<host>.homelab.example` als admin – root ist auf öffentlichen Adressen gesperrt (`modules/ssh.nix`), so funktioniert dieser Ausweg, wenn das Mesh nicht geht. Die alternativen Namen nutzen `HostKeyAlias <host>.peer.homelab.example`, damit alle gegen den einen Host-Key aus dem Inventar geprüft werden.
- **Host-Keys** kommen aus dem Inventar (`/etc/ssh/ssh_known_hosts`, wie auf jedem Host); GitHubs Schlüssel ist in `configuration.nix` festgeschrieben. `just known-hosts` braucht es auf gusto nicht.
- Von Hand: `zorlock-lan` (FileVault entsperren), `opnsense`, `arkkvm`/`arkkvm01`, der Subraum-Router als Jumphost (mit seinen Portweiterleitungen), vogon, amnesia, unifi, git.c3pb.de, edi, ein Block für alte Switches, der Legacy-Algorithmen nur *ergänzt* (`+…`), und GitHub (mit 60 s ControlMaster).

#### devShell und direnv

Die Werkzeuge des Repos werden nicht global installiert. `flake.nix` hat `devShells.aarch64-darwin.default` mit sops, age, ssh-to-age, opentofu und nvd aus den Pins des Flakes; `.envrc` (`use flake`) lässt direnv sie laden, sobald eine Shell den Checkout betritt – einmal pro Checkout `direnv allow`. nix-direnv cacht die Shell und schützt sie vor der Garbage Collection. Die Doku-Werkzeuge sind nicht drin: `just docs` und `just docs-serve` holen sich ihre eigenen per `nix shell`.

sops nimmt auf gusto den age-Schlüssel der Workstation direkt aus 1Password: home-manager setzt `SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"'`, `op` entsperrt per Touch ID über die App – kein `op signin`, keine Schlüsseldatei.

#### DNSControl

Die öffentlichen DNS-Records liegen im Repo nebenan, `~/Projects/homelab/DNSControl` (lokal, ohne Remote; hier als Symlink `dnsconfig.js` eingebunden). dnscontrol kommt aus einer zweiten, schlanken devShell `devShells.aarch64-darwin.dns`, die nur dnscontrol und sops enthält; die `.envrc` dort lädt sie mit `use flake ../nixlab#dns`. Eine eigene `flake.nix` bekommt DNSControl nicht – so bleibt dnscontrol auf den Pins dieses Flakes, ohne zweites `flake.lock`.

Die Zugangsdaten der Provider (deSEC, OVH, hosting.de) liegen sops-verschlüsselt in `creds.sops.json` im Repo, nie im Klartext auf der Platte. Die `.sops.yaml` dort nennt dieselben Empfänger wie die Tofu-Module: den Workstation-Schlüssel und den Recovery-Key `admin` – ohne 1Password bleiben sie also lesbar. Den Rest erledigt ein Wrapper:

- `bin/dnscontrol` steht durch die `.envrc` (`PATH_add bin`) vor dem echten Binary, dessen Pfad sie in `DNSCONTROL_BIN` ablegt.
- Bei den Befehlen, die mit Providern reden – `preview`, `push`, `ppreview`, `ppush`, `check-creds`, `get-zones`, `get-certs` – hängt er `--creds '!sops -d …/creds.sops.json --output-type json'` an, außer `--creds` steht schon in der Zeile. Alles andere reicht er unverändert durch. `--output-type` steht absichtlich am Ende: Einen `--creds`-Wert, der auf `.json` endet, hält dnscontrol auch hinter dem `!` für einen Dateinamen.
- sops entschlüsselt mit dem Workstation-Schlüssel (`SOPS_AGE_KEY_CMD`, Touch ID), dnscontrol liest das JSON aus der Ausgabe. Nichts davon landet auf der Platte.

Der Aufruf bleibt `dnscontrol preview` und `dnscontrol push`. Ein Token wechseln heißt: `sops creds.sops.json` und committen. Eine `creds.json` sperrt die `.gitignore` des Repos, damit nie wieder Klartext hineingerät. Eine ausführbare `creds.json` statt des Wrappers geht nicht: dnscontrol prüft das Ausführbar-Bit bei Namen auf `.json` nicht.

## Neuen Host aufnehmen

Ein Host steht an mehreren Stellen im Repo, weil NixOS und OpenTofu bewusst keine gemeinsame Host-Liste haben (siehe [Was bewusst nicht verdrahtet ist](#was-bewusst-nicht-verdrahtet-ist)). Diese Anleitung geht sie der Reihe nach durch.

### 1. Maschine bereitstellen

Gemietete VMs werden beim Anbieter von Hand angelegt; Bare Metal und die Subraum-VM folgen den Installationsanleitungen unter `docs/install-*.md`. Am Ende steht ein NixOS mit SSH-Host-Key – aus dem entsteht gleich der age-Schlüssel des Hosts.

### 2. Konfiguration anlegen

- `hosts/<host>/configuration.nix` und `hardware-configuration.nix` anlegen.
- In `flake.nix` unter `nixosConfigurations` eintragen, mit expliziter Modulliste. Was bewusst fehlt, bekommt einen Kommentar mit Begründung daneben.

### 3. Überall eintragen, wo Hosts aufgezählt sind

| Datei | Eintrag |
| --- | --- |
| `flake.nix` | `nixosConfigurations.<host>` |
| `inventory.json` | `hosts.<host>` mit `"managed": true` – Art, Site, Owner, Entsperren (siehe [Inventar](#inventar)) |
| `justfile` | `hosts := "…"` (nur Pull-Hosts, für `ship-all`) |
| `terraform/netbird/main.tf` | `local.hosts`: Host → Setup-Key-Gruppe (`servers` o. ä.) |
| `terraform/desec-tokens/main.tf` | `local.hosts`: erlaubte Quelladressen, `acme_names` |
| `terraform/github/main.tf` | `local.hosts`: Deploy-Key nur lesend oder mit Schreibrecht |

### 4. sops-Empfänger

Den age-Schlüssel aus dem SSH-Host-Key des neuen Hosts ableiten (`ssh-to-age` auf `/etc/ssh/ssh_host_ed25519_key.pub`) und in `.sops.yaml` eintragen: einen Anker unter `keys` und eine `creation_rule` für `hosts/<host>/(secrets|netbird|desec|github)\.yaml$` mit dem Host und `admin` als Empfängern. Der öffentliche Host-Key selbst kommt in `inventory.json` (`sshHostKeys`, oder später per `just inventory-collect`); `checks.inventory-sops` gleicht beides ab.

### 5. Schlüssel und Tokens erzeugen

| Rezept | Ergebnis | Hinweis |
| --- | --- | --- |
| `just netbird-key <host>` | `hosts/<host>/netbird.yaml` | Einmal-Setup-Key, **24 h gültig** – direkt danach deployen |
| `just desec-key <host>` | `hosts/<host>/desec.yaml` | nur für Hosts mit eigenen Zertifikaten |
| `just github-key <host>` | `hosts/<host>/github.yaml` + `github-deploy.pub` | nur für Pull-Hosts |

Rezepte, die sops brauchen, nehmen den Workstation-Key aus 1Password (auf gusto von home-manager eingerichtet, siehe [just-Rezepte](#just-rezepte)).

### 6. Deployen und prüfen

- Erster Deploy innerhalb von 24 h nach `netbird-key`. Der Host registriert sich beim Start selbst im Mesh; Tofu findet ihn über `data "netbird_peer"` am Namen.
- `just topology` ausführen und das Ergebnis committen – sonst schlägt `nix flake check` fehl.
- `just inventory-collect` (Host-Key, Interfaces), `network`/`ipv4` von Hand ergänzen, dann `just inventory-test`; auf gusto `just mac-switch` (dessen known_hosts kommt aus dem Inventar) – ein neuer verwalteter Host bekommt dort auch automatisch seinen SSH-Block, dazu `hosts/gusto/ssh/<host>.homelab.example.pub`.
- App-Secrets erst eintragen, wenn der Host läuft: [Secrets eintragen](#secrets-eintragen).
- Doku nachziehen: [Hosts & Rollen](#hosts--rollen), [Services](#services-2).

## Neuen Dienst veröffentlichen

Dienste heißen nach ihrer Funktion (`rezepte`, nicht `mealie`); neue Webdienste auf grammi nutzen PostgreSQL. Zuerst entscheiden, wie der Dienst erreichbar sein soll – davon hängt ab, welche Dateien sich ändern.

| Erreichbarkeit | Für | Beispiele |
| --- | --- | --- |
| Nur im Mesh | Admin-Oberflächen, Dienste für die eigenen Geräte | `s3-admin`, `llm` |
| Öffentlich hinter dem Reverse Proxy mit SSO | Web-Apps, die auch von unterwegs ohne NetBird-App erreichbar sein sollen | `rezepte`, `grist`, `metrics`, `dokumente` |
| Direkt öffentlich | Dienste mit eigenem Login für Maschinen oder alle | `auth`, `s3.aldrin` |

### Nur im Mesh

1. In `terraform/netbird/mesh-services.tf` eine Zeile unter `local.mesh_services`: Name → Host(s). Daraus entsteht eine eigene NetBird-DNS-Zone mit A-Record(s) auf die Mesh-Adresse(n); öffentliches DNS kennt den Namen nicht.
2. `just netbird-apply` – neue Zonen kommen seit NetBird 0.81 ohne Neustart bei den Clients an.
3. Auf dem Host einen nginx-vHost mit `enableACME`, `acmeRoot = null` (DNS-01 über deSEC) und `allow 192.0.2.0/24; deny all;`.
4. Steht der Dienst auf ursalia oder zorlock: den Namen in `acme_names` des Hosts in `terraform/desec-tokens/main.tf` ergänzen und `just desec-apply` – deren Tokens dürfen nur genau diese TXT-Records schreiben.
5. Host deployen, `just topology` (neuer vHost).

### Öffentlich hinter dem Reverse Proxy

Für Dienste auf grammi:

1. Eintrag in `hosts/grammi/proxy-services.json`: Name → App, Port, Pocket-ID-Gruppen, optional `start` (wohin `/` weiterleitet). Tofu (`reverse-proxy.tf`), Traefik und `topology.nix` lesen dieselbe Datei; der Proxy erreicht jede App über Traefik `:8090`.
2. Der Dienst lauscht nur auf `127.0.0.1` – Traefik verbindet sich über Loopback, mehr braucht es nicht ([Apps auf grammi](#apps-auf-grammi-nur-über-traefik-8090)).
3. In DNSControl einen CNAME `<name>` → `proxy.homelab.example` pushen – einige Minuten vor dem Apply, sonst cacht der Resolver NXDOMAIN.
4. Erst grammi deployen, dann `just netbird-apply`. Das ruft am Ende `just netbird-proxy-certs` auf: Es fragt jeden neuen Namen einmal von außen ab, damit der Proxy sein Zertifikat holt, und startet `netbird-proxy` danach einmal neu – sonst hängt das Dashboard bei „Issuing certificate…“ (NetBird-Diskussion #7118).

Dienste auf anderen Hosts bekommen eine eigene Ressource in `terraform/netbird/reverse-proxy.tf` mit dem Host als Peer-Ziel (Beispiele: `dokumente` auf ursalia – SSO für die App, PIN nur für Freigabelinks –, `doku` auf aldrin). Auch hier: CNAME vorher pushen, `just netbird-apply` erledigt die Zertifikate.

### Direkt öffentlich

nginx-vHost auf dem Host (ACME per DNS-01), A/AAAA-Records in DNSControl, CrowdSec liest die nginx-Logs mit. Nur für Dienste, die ohnehin eine eigene Anmeldung haben.

### Danach

- Doku: [Services](#services-2), bei neuem Host-Verzeichnis-Inhalt auch [Inhalt von hosts/&lt;host&gt;/](#inhalt-von-hostshost).
- Dual-Stack, wo es geht (A und AAAA).
- Wartungsschalter und Fehlerseiten: [Wartungsmodus](#neuen-dienst-aufnehmen) – auf grammi automatisch, auf anderen Hosts ein Eintrag im Host.

## Wartungsmodus

Ein Dienst lässt sich für eine Wartung abschalten, ohne ihn anzuhalten: Wer ihn aufruft, bekommt eine Seite mit Status 503, dem Grund und `Retry-After`; der Dienst selbst läuft weiter und ist für Tests erreichbar. Dieselbe Seite erscheint mit 502 oder 504, wenn der Dienst gerade nicht antwortet – etwa während eines `switch`. Modul: `modules/maintenance.nix`.

### Wie es funktioniert

Jeder HTTP-Weg zu einem Dienst endet an nginx oder Traefik auf dem Host, auf dem der Dienst läuft – auch der Weg über den NetBird-Reverse-Proxy, der nur weiterreicht. Dort sitzen Wartungsschalter und Fehlerseiten; die Software davor ist ein Detail pro Host.

<figure class="nx-diagram">
<svg viewBox="0 0 680 530" role="img" aria-label="Wege zu den Diensten: jeder HTTP-Weg endet an nginx oder Traefik auf dem Ziel-Host, dort sitzen Wartungsschalter und Fehlerseiten" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}</style>
<text class="nx-s" x="62" y="30" text-anchor="middle">Quelle</text>
<text class="nx-s" x="172" y="30" text-anchor="middle">Eingang grammi</text>
<text class="nx-s" x="298" y="30" text-anchor="middle">Proxy</text>
<text class="nx-s" x="432" y="30" text-anchor="middle">Front am Ziel</text>
<text class="nx-s" x="584" y="30" text-anchor="middle">Dienste</text>
<g class="nx-gray"><rect x="20" y="48" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="78" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 73 H368"/><path class="nx-line" d="M362 69 L368 73 L362 77"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="48" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="70" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="87" text-anchor="middle">aldrin, zummi</text></a>
<path class="nx-line" d="M494 73 H506"/><path class="nx-line" d="M500 69 L506 73 L500 77"/>
<g class="nx-gray"><rect x="508" y="48" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="69" text-anchor="middle">s3.aldrin, cloud,</text><text class="nx-s" x="584" y="85" text-anchor="middle">auth</text></g>
<g class="nx-gray"><rect x="20" y="110" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="140" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 135 H116"/><path class="nx-line" d="M110 131 L116 135 L110 139"/>
<g class="nx-gray"><rect x="118" y="110" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="140" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 135 H238"/><path class="nx-line" d="M232 131 L238 135 L232 139"/>
<g class="nx-gray"><rect x="240" y="110" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="140" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 135 H368"/><path class="nx-line" d="M362 131 L368 135 L362 139"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="110" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="132" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="149" text-anchor="middle">ursalia :8092</text></a>
<path class="nx-line" d="M494 135 H506"/><path class="nx-line" d="M500 131 L506 135 L500 139"/>
<g class="nx-gray"><rect x="508" y="110" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="140" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="172" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="202" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 197 H116"/><path class="nx-line" d="M110 193 L116 197 L110 201"/>
<g class="nx-gray"><rect x="118" y="172" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="202" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 197 H238"/><path class="nx-line" d="M232 193 L238 197 L232 201"/>
<g class="nx-gray"><rect x="240" y="172" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="202" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 197 H368"/><path class="nx-line" d="M362 193 L368 197 L362 201"/>
<a data-target="traefik" tabindex="0" role="link" class="nx-teal"><rect x="370" y="172" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="194" text-anchor="middle">Traefik :8090</text><text class="nx-s" x="432" y="211" text-anchor="middle">alle grammi-Apps</text></a>
<path class="nx-line" d="M494 197 H506"/><path class="nx-line" d="M500 193 L506 197 L500 201"/>
<g class="nx-gray"><rect x="508" y="172" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="193" text-anchor="middle">vm, vl, rezepte,</text><text class="nx-s" x="584" y="209" text-anchor="middle">grist, logs, metrics</text></g>
<g class="nx-gray"><rect x="20" y="234" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="264" text-anchor="middle">Mesh</text></g>
<path class="nx-line" d="M104 259 H368"/><path class="nx-line" d="M362 255 L368 259 L362 263"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="234" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="256" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="273" text-anchor="middle">ursalia :443</text></a>
<path class="nx-line" d="M494 259 H506"/><path class="nx-line" d="M500 255 L506 259 L500 263"/>
<g class="nx-gray"><rect x="508" y="234" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="264" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="296" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="326" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 321 H238"/><path class="nx-line" d="M232 317 L238 321 L232 325"/>
<g class="nx-gray"><rect x="240" y="296" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="318" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="335" text-anchor="middle">:8883, nur TCP</text></g>
<path class="nx-line" d="M356 321 H368"/><path class="nx-line" d="M362 317 L368 321 L362 325"/>
<g class="nx-gray"><rect x="370" y="296" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="326" text-anchor="middle">keine</text></g>
<path class="nx-line" d="M494 321 H506"/><path class="nx-line" d="M500 317 L506 321 L500 325"/>
<g class="nx-gray"><rect x="508" y="296" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="326" text-anchor="middle">mqtt (Home Assistant)</text></g>
<g class="nx-gray"><rect x="20" y="358" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="388" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 383 H116"/><path class="nx-line" d="M110 379 L116 383 L110 387"/>
<g class="nx-gray"><rect x="118" y="358" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="388" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 383 H238"/><path class="nx-line" d="M232 379 L238 383 L232 387"/>
<g class="nx-gray"><rect x="240" y="358" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="380" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="397" text-anchor="middle">Ziel umgestellt</text></g>
<path class="nx-line" d="M356 383 H368" stroke-dasharray="5 4"/><path class="nx-line" d="M362 379 L368 383 L362 387"/>
<a data-target="proxy-maintenance" tabindex="0" role="link" class="nx-teal"><rect x="370" y="358" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="380" text-anchor="middle">Wartungsseite</text><text class="nx-s" x="432" y="397" text-anchor="middle">grammi :8090</text></a>
<g class="nx-gray"><rect x="508" y="358" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="379" text-anchor="middle">wenn der Ziel-Host</text><text class="nx-s" x="584" y="395" text-anchor="middle">ganz aus ist</text></g>
<a data-target="switching" tabindex="0" role="link" class="nx-teal"><rect x="20" y="430" width="640" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="453" text-anchor="middle">Gemeinsam auf jedem Host mit Front</text><text class="nx-s" x="340" y="472" text-anchor="middle">Flag in /var/lib/maintenance · Seite 503/502/504 · Bypass-Cookie</text></a>
<g class="nx-teal"><rect x="20" y="504" width="14" height="14" rx="3" stroke-width="1"/></g><text class="nx-s" x="42" y="515">Wartungs-Check und Fehlerseiten</text>
<g class="nx-gray"><rect x="340" y="504" width="14" height="14" rx="3" stroke-width="1" stroke-dasharray="3 2"/></g><text class="nx-s" x="362" y="515">gestrichelt: Proxy-Wartung, nur bei Bedarf</text>
</svg>
</figure>

- **Flag**: `/var/lib/maintenance/<fqdn>` (oder `all` für den ganzen Host). Der Inhalt der Datei ist der Grund auf der Seite. Die Flags überstehen einen Neustart – eine Wartung bleibt zu, bis sie jemand beendet.
- **Seite**: ein kleines Programm auf jedem Host (`maintenance-responder`, nur 127.0.0.1:8089, startet bei Bedarf über systemd). Es entscheidet für nginx und Traefik gleich zwischen Wartung (503) und Störung (502/504).
- **Bypass**: ein Cookie für alle Namen unter `homelab.example`, mit dem der Dienst trotz Wartung im Browser erreichbar bleibt.

### Ein- und ausschalten

Vom Arbeitsrechner; der Host wird über `inventory.json` gefunden:

```bash
just maintenance dokumente on "Paperless-Upgrade, bis ca. 22 Uhr"
```

```bash
just maintenance dokumente off
```

```bash
just maintenance-list
```

Ein Name ohne Punkt bekommt `.homelab.example` angehängt. Ein ganzer Host (alle Namen mit Wartungsschalter dort):

```bash
just maintenance all on "Umzug auf neue Hardware" aldrin
```

```bash
just maintenance all off "" aldrin
```

Auf dem Host selbst geht dasselbe mit `maintenance on|off|status`. Ein Neuladen von nginx oder Traefik ist nicht nötig; nginx prüft das Flag bei jeder Anfrage, Traefik übernimmt die Änderung nach zwei bis vier Sekunden.

Welche Namen einen Wartungsschalter haben:

| Host | Namen | Front |
| --- | --- | --- |
| aldrin | `s3.aldrin`, `cloud` | nginx |
| zummi | `auth` | nginx |
| ursalia | `dokumente` (443 und der Proxy-Listener 8092) | nginx |
| grammi | alle Namen aus `hosts/grammi/proxy-services.json` | Traefik `:8090` |

Nebenwirkungen: `s3.aldrin` in Wartung heißt, dass die nächtlichen restic-Backups aller Hosts scheitern; `auth` in Wartung heißt, dass sich niemand neu per Pocket ID anmelden kann. `s3-admin` (garage-ui) hat nur die Fehlerseiten: Sein 443 ist öffentlich offen, und die Wartungsprüfung liefe vor dessen Mesh-Sperre (`allow`/`deny`).

### Dienst trotzdem sehen

1. Token in die Zwischenablage holen (wird nie angezeigt):

    ```bash
    just maintenance-key
    ```

2. `https://<name>/_maintenance/bypass` öffnen, z. B. `https://dokumente.homelab.example/_maintenance/bypass`, Token einfügen.

Das Cookie gilt 12 Stunden für alle Namen unter `homelab.example`, auch für den Rückweg nach dem Login bei Pocket ID. Löschen: `https://<name>/_maintenance/clear`. Der Bypass ist Komfort, keine Sicherheitsgrenze – Login, SSO am Proxy und Mesh-Sperren gelten weiter. Das Token liegt per sops in `hosts/<host>/maintenance.yaml` (gleiches Token auf allen vier Hosts); neu erzeugen: alle vier Dateien löschen, `just maintenance-token`, committen, die vier Hosts deployen.

Der Schlüssel wird per Formular geschickt, nicht als `?key=` in der Adresse: Adressen stehen in den Zugriffsprotokollen, und die landen in VictoriaLogs.

### Hinter der Wartung testen mit ssh -L

Für Prüfungen ohne Browser – Healthcheck, API, Versionsabfrage – reicht ein Tunnel direkt zum Dienst, an nginx und Traefik vorbei:

```bash
ssh -L 8000:127.0.0.1:8000 root@ursalia.peer.homelab.example
```

```bash
curl -sI http://localhost:8000/api/
```

Weitere Beispiele: Grafana `ssh -L 3000:127.0.0.1:3000 root@grammi.peer.homelab.example`, Garage-S3 `ssh -L 3900:127.0.0.1:3900 root@aldrin.peer.homelab.example` (dann ein S3-Client gegen `http://localhost:3900`).

Für einen Test im Browser taugt das meist nicht: Dienste, die ihre eigene Adresse prüfen, lehnen `localhost` ab. paperless vergleicht beim Login den `Origin` mit `PAPERLESS_URL` (CSRF), OpenCloud und alles mit OIDC leiten nach der Anmeldung auf ihre echte Adresse zurück – die gerade in Wartung ist. Für den Browser ist der [Bypass](#dienst-trotzdem-sehen) da.

### Wenn der Host ganz aus ist

Ist der Ziel-Host selbst aus (Neustart, Umzug), fehlt auch seine Wartungsseite, und der NetBird-Proxy zeigt seinen eigenen Fehler. Für die Dienste außerhalb von grammi (`dokumente`, `doku`) lässt sich das Proxy-Ziel deshalb auf grammi umstellen, wo Traefik jeden Namen, den es nicht selbst bedient, mit der Wartungsseite beantwortet:

```bash
just proxy-maintenance dokumente on "ursalia wird neu installiert"
```

```bash
just proxy-maintenance dokumente off
```

Das schreibt `terraform/netbird/proxy-maintenance.json`, ruft `just netbird-apply` auf und setzt bzw. löscht das Flag auf grammi. Danach `proxy-maintenance.json` und `expected-peers.json` committen (solange umgestellt ist, fällt der Host aus den Zielen des Proxys). Der Login (SSO, PIN) bleibt davor; aus dem Mesh direkt bleibt der Host natürlich unerreichbar.

### Fehlerseiten bei 502 und 504

Ohne Schalter: Antwortet der Dienst nicht (502) oder zu langsam (504), zeigt die Front dieselbe Seite mit „Gerade nicht erreichbar“ und dem echten Statuscode.

#### nginx

nginx ersetzt nur seine eigenen Fehler (`error_page`). Fehlerantworten des Dienstes selbst kommen unverändert durch – `proxy_intercept_errors` bleibt aus, damit S3-Clients ihr XML und OIDC-Clients ihr JSON bekommen.

#### Traefik

Traefik ersetzt mit der `errors`-Middleware auch Antworten des Dienstes, deshalb nur 502 und 504, nicht 503. Die Wartungs-Router erzeugt `maintenance-traefik-sync` aus den Flags in `/run/traefik-dynamic/`, das Traefik beobachtet. Der Kontroll-Endpunkt `mesh.homelab.example` bekommt nie einen Wartungsschalter.

### Neuen Dienst aufnehmen

- **nginx**: den vHost (Attributname) in `services.maintenance.nginx.vhosts` des Hosts eintragen, oder in `nginx.errorPagesOnly` für nur die Fehlerseiten. Nicht für vHosts mit `allow`/`deny`, deren Port auch Abgewiesene erreichen – die Wartungsprüfung läuft vor `allow`/`deny`.
- **grammi**: jeder Eintrag in `hosts/grammi/proxy-services.json` ist automatisch dabei.
- **Neuer Host**: `./modules/maintenance.nix` in `flake.nix` importieren, `services.maintenance.enable = true`, den Host in `.sops.yaml` (`maintenance`) und in `just maintenance-token` aufnehmen und das Token neu erzeugen.

## Secrets eintragen

App-Passwörter, OIDC-Clients und Ähnliches liegen in `hosts/<host>/secrets.yaml`, verschlüsselt für den Host und den Recovery-Key `admin`. Das MacBook kann diese Dateien nicht entschlüsseln – deshalb wird auf dem Host editiert (Hintergrund: [Secrets, Netzwerk & Zugriff](#secrets-netzwerk--zugriff)).

### Ablauf

1. `just sync <host>` – sonst liegt auf dem Host ein veralteter Stand von `secrets.yaml`, und `pull-secrets` holt ihn zurück ins Repo.
2. `just secrets <host>` – öffnet sops auf dem Host (mit dessen Host-Key, ohne 1Password-Anmeldung) und holt das Ergebnis danach per `pull-secrets` ins Repo.
3. Werte immer in Anführungszeichen: `key: "wert"`, einfache Anführungszeichen, wenn der Wert `"` oder `\` enthält. Ein unquotierter Wert kann von YAML als Zahl oder Bool gelesen werden; sops-nix bricht dann `setupSecrets` ab und **kein** Secret dieser Generation wird installiert.
4. Die NixOS-Seite (`sops.secrets."<name>"`) im Host-Modul ergänzen, committen, deployen: `just ship <host> "<nachricht>"`.

### Was nicht von Hand editiert wird

| Datei | Erzeugt von |
| --- | --- |
| `hosts/<host>/netbird.yaml` | `just netbird-key <host>` |
| `hosts/<host>/desec.yaml` | `just desec-key <host>` |
| `hosts/<host>/github.yaml` | `just github-key <host>` |
| `terraform/*/secrets.yaml` | sops auf dem MacBook mit dem Workstation-Key aus 1Password |

Alles, was auf dem MacBook sops braucht, läuft mit vorangestellter Anmeldung – siehe [just-Rezepte](#just-rezepte).

## Schlüssel rotieren

Was sich wie erneuern lässt und was danach zu tun ist. Die Rezepte ersetzen den alten Schlüssel jeweils sofort – deshalb direkt danach committen und deployen.

| Schlüssel | Rezept | Danach | Wann |
| --- | --- | --- | --- |
| NetBird-Setup-Key eines Hosts | `just netbird-key <host>` | Deploy innerhalb von 24 h | bei Neuinstallation oder verlorenem Client-State |
| deSEC-Token eines Hosts | `just desec-key <host>` | sofort deployen, dann `just desec-verify` | bei Verdacht, sonst nie |
| GitHub-Deploy-Key eines Hosts | `just github-key <host>` | commit + deploy | bei Verdacht |
| Tofu-Token für NetBird (Service-User `terraform`) | `just netbird-renew-token` | – | jährlich |
| App-Secrets | `just secrets <host>` (siehe [Secrets eintragen](#secrets-eintragen)) | deploy | bei Verdacht |

### SSH-Host-Key (= sops-Empfänger)

Der age-Schlüssel eines Hosts ist aus seinem SSH-Host-Key abgeleitet. Ein neuer Host-Key heißt deshalb auch:

1. Neuen age-Schlüssel per `ssh-to-age` ableiten und in `.sops.yaml` ersetzen.
2. Die Dateien des Hosts mit `sops updatekeys` neu verschlüsseln – dafür braucht es einen Schlüssel, der sie noch lesen kann (der alte Host-Key oder `admin`).
3. Den neuen öffentlichen Key in `inventory.json` übernehmen: `just inventory-collect --force <host>`. `nix flake check` (`checks.inventory-sops`) schlägt fehl, bis Inventar und `.sops.yaml` übereinstimmen.
4. Committen und deployen, bevor der alte Key verschwindet – die known_hosts aller Hosts kommt aus dem Inventar. Auf gusto: `just mac-switch`.

### Nach einer Rotation

- Alte Schlüssel beim Gegenüber löschen (GitHub, deSEC und NetBird erledigt das Rezept per Tofu).
- `just docs`, falls sich Namen oder Abläufe geändert haben.

## Software auf den Macs

Alles, was auf gusto installiert ist – Casks, Homebrew-Formeln, Mac-App-Store-Apps, nixpkgs-Pakete und Schriften – steht in `hosts/gusto/apps.json`. Drei Befehle verwalten sie – `apps`, `apps-list` und `apps-rm`, auf gusto installiert und in jedem Ordner nutzbar; im Repo-Ordner tun `just apps`, `just apps-list` und `just apps-rm` dasselbe. Den Hintergrund (warum eine Datendatei, warum die Pin-Prüfung) erklärt [macOS-Hosts](#software-als-daten-appsjson).

### Eine Runde: hinzufügen und entfernen

```bash
apps obsidian
```

Der Suchbegriff ist optional (`apps` allein startet mit leerer Suche). Eine Runde sind beliebig viele Änderungen und endet mit einem Switch und einem Commit:

```
╭──────────── search: obsidian  filter: export ─╮   ← beide Felder
│ filter> export                                 │   ← das aktive
╰────────────────────────────────────────────────╯
  this round:  + ripgrep (nixpkgs, user)   − shottr (cask) ZAP
  enter: add / remove   tab: search ⇄ filter   ctrl-s: done   esc: cancel
  nixpkgs ✓ 12  Homebrew ✓ 2  App Store ✓ 10
   nixpkgs  obsidian-export   25.3.0   CLI  Rust library and CLI to export …
…
  [ Done · ctrl-s ]  [ Cancel · esc ]     shift-tab: buttons
```

- **Zwei Felder, `tab` wechselt.** `search>` sucht online; `filter>` (optional) grenzt die Treffer dieser Suche in fzf unscharf ein, ohne neu zu suchen (`'wort` für einen exakten Treffer). Ein neuer Suchbegriff leert den Filter – er gehörte zu den alten Treffern. Der Rahmen oben zeigt beide.
- **Die Suche** läuft beim Tippen (ab 2 Zeichen, nach einer kurzen Pause) gegen nixpkgs (search.nixos.org, Release von `nixpkgs-darwin`), Homebrew (formulae.brew.sh), den Mac App Store und die Drittanbieter-Taps, die gusto pinnt (offline, aus ihrem Pin). Ein voll qualifizierter Begriff – `owner/tap/name`, wie in `brew install --cask owner/tap/name` – schlägt diesen einen Cask oder diese Formel zusätzlich auf GitHub nach, wenn ihr Tap noch nicht gepinnt ist (siehe [Ein Cask aus einem Drittanbieter-Tap](#ein-cask-aus-einem-drittanbieter-tap)). Ist search.nixos.org nicht erreichbar, übernimmt `nix search` gegen den Pin – langsamer, aber immer verfügbar. Die Zeile über der Liste zeigt, was jede Quelle geliefert hat.
- **★** markiert die empfohlene Quelle, wenn es dieselbe Software mehrfach gibt: für eine GUI-App Cask vor App Store vor nixpkgs, für ein Kommandozeilenwerkzeug nixpkgs vor einer Homebrew-Formel. Die Vorschau unten zeigt Beschreibung, Version, Lizenz, Homepage – und bei einem deklarierten Eintrag seine Notiz.
- **Enter auf einen neuen Treffer fügt ihn hinzu.** Die Liste schließt sich für die Fragen:
    1. Die Pin-Prüfung –

        | Quelle | Prüfung | Wenn sie scheitert |
        | --- | --- | --- |
        | nixpkgs | auswertbar im gepinnten `nixpkgs-darwin`, verfügbar auf aarch64-darwin, nicht unfree | nicht hinzugefügt – kommt mit dem nächsten System-Update; unfree: den Cask nehmen |
        | Cask / Formel | die `.rb`-Datei liegt im gepinnten Tap | bietet an, `homebrew-cask` / `homebrew-core` zu aktualisieren (eigener Commit) |
        | Cask / Formel aus einem nicht gepinnten Tap | – (kommt vor der Prüfung) | zeigt, wer den Tap veröffentlicht und was er herunterlädt, und bietet dann an, ihn zu pinnen **und ihm zu vertrauen** (eigener Commit) |
        | App Store | – (kein Pin, der Store installiert die aktuelle Version) | – |

    2. bei nixpkgs der Scope: `user` (admins `home.packages`, Standard), `system` (root und jede Shell) oder `font`;
    3. eine Notiz – warum es da ist, auf Englisch, wie ein Kommentar in der Konfiguration; Enter lässt sie weg.

    Danach ist die Liste mit derselben Suche und demselben Filter wieder da, im Feld, in dem du warst, bereit für das Nächste. Ctrl-C während der Fragen überspringt diesen Treffer.
- **Enter auf einen deklarierten Eintrag (✓) merkt ihn zum Entfernen vor** (rot, durchgestrichen, `−`). Gelöscht wird noch nichts.
- **Enter auf etwas, das in dieser Runde dazukam oder vorgemerkt wurde, nimmt es zurück.**
- Die Kopfzeile listet die Runde: `+` grün, `−` rot, **ZAP** bei einem Cask – einen Cask zu entfernen löscht beim Switch die App *und ihre Daten* (Einstellungen, Caches, Container).

**Fertig** – `ctrl-s`, oder mit `shift-tab` auf den Button *Done* und Enter (ein Klick geht auch):

1. die Runde noch einmal, dann wird die Konfiguration ausgewertet; scheitert das, steht der Fehler da und du bist zurück in der Liste;
2. zu zappende Casks: `just mac-diff` zeigt sie, dann *Continue? [y/N]* – Nein führt zurück in die Liste;
3. auf gusto selbst: Switch? (Standard ja, nein wenn etwas gezappt wird);
4. der Commit folgt auf einen erfolgreichen Switch – oder einen abgelehnten; ein gescheiterter Switch lässt alles uncommittet.

Ein Commit pro Runde, nur `apps.json`: `gusto: add obsidian (cask), remove shottr (cask)`, mit einer Liste im Text; bei einer längeren Runde steht im Betreff die Anzahl (`gusto: add 3 and remove 1 apps`). Ein Tap-Bump ist ein eigener Commit davor (`flake.lock: bump homebrew-cask for …`), ebenso ein neuer Tap (`gusto: pin tap stablyai/homebrew-orca for orca`).

**Abbrechen** – `esc` oder der Button *Cancel*: Mit Änderungen in der Runde fragt es *Discard N change(s)?*, danach sind `apps.json` (und `flake.lock`, bei einem neuen Tap auch `flake.nix` und `configuration.nix`) wieder wie vorher. Hat `apps.json` beim Start von `apps` schon uncommittete Änderungen, bricht es ab, bevor es etwas ändert; für die anderen Dateien gilt das, sobald eine Runde sie ändern würde.

### Ein Cask aus einem Drittanbieter-Tap

Manche Hersteller veröffentlichen ihre Mac-App nur in einem eigenen Tap; ihre Installationszeile lautet dann `brew install --cask <owner>/<tap>/<name>`. Genau diesen Namen bekommt `apps`:

```bash
apps stablyai/orca/orca
```

- Ist der Tap gepinnt, erscheinen seine Casks und Formeln in jeder Suche wie die anderen; die Suche liest sie aus dem Pin, ohne Netz. In `apps.json` heißen sie `"<owner>/homebrew-<tap>/<name>"`, z. B. `stablyai/homebrew-orca/orca`.
- Einen noch nicht gepinnten Tap findet nur der voll qualifizierte Name; der Treffer ist mit *tap not pinned* markiert. Enter darauf zeigt, wer den Tap veröffentlicht (GitHub-Owner, verifiziert oder nicht, Alter des Repos, letzter Push) und von welchen URLs der Cask lädt, und fragt *Pin stablyai/homebrew-orca as flake input stablyai-orca-tap for gusto and trust it?*
- **Ja** trägt den Input in `flake.nix` ein (nach dem letzten Tap-Input, mit einem erzeugten Kommentar – umschreiben, wenn der Grund mehr verdient), die Zeile `nix-homebrew.taps."stablyai/homebrew-orca" = inputs.stablyai-orca-tap;` in `hosts/gusto/configuration.nix` und führt `nix flake lock` aus. Danach folgen die übliche Pin-Prüfung und die Notiz. Weil der Startbegriff genau diesen Cask genannt hat, endet die Runde dort – kein Zurück in die Liste, keine *Switch?*-Frage: Zusammenfassung, Auswertung, `just mac-switch`, dann der Tap als eigener Commit (`flake.nix`, `flake.lock`, `configuration.nix`) vor dem von `apps.json`. Dasselbe gilt für `apps owner/tap/name`, dessen Tap schon gepinnt ist. Eine Runde mit einer Entfernung fragt vor dem Switch weiterhin.
- **Jedem gepinnten Tap wird vertraut** (`brew trust`, [macOS-Hosts](#homebrew-eine-richtlinie-für-beide-macs)): Ein Cask führt seinen Installationscode als du aus. Vor dem Ja den Herausgeber prüfen.
- Ab dann aktualisiert `just mac-upgrade` den neuen Input mit den anderen – es findet jeden Tap-Input in `flake.lock` selbst.

Entfernen des letzten Casks eines Taps lässt den Tap gepinnt und vertraut; der kommt von Hand raus (Input, Zeile in `nix-homebrew.taps`, `nix flake lock`).

### Eins direkt entfernen

```bash
apps-rm shottr
```

Für ein einzelnes Entfernen ohne Suche. Ein Cask will zur Bestätigung den Namen getippt haben, dann `just mac-diff`, Switch (Standard nein), Commit. Auch eine **Mac-App-Store**-App wird beim Switch deinstalliert, wenn ihr Eintrag geht. Ist ein Name aus zwei Quellen deklariert, mit `--source` wählen, z. B. `apps-rm obsidian --source nixpkgs`.

### Auflisten

```bash
apps-list
```

Nach Quelle, mit dem Datum, an dem es dazukam, und der Notiz.

### Von Hand

`apps.json` lässt sich direkt bearbeiten (der Editor ergänzt die Felder über `modules/darwin/apps.schema.json`), danach `just mac-diff` und `just mac-switch`. Fehler zeigen sich bei der Auswertung mit der vollständigen Liste der Probleme; `nix build .#checks.aarch64-darwin.darwin-apps` prüft nur die Datei.

Nicht in `apps.json`:

- **Ein neuer Drittanbieter-Tap** – er ist ein Flake-Input: `apps <owner>/<tap>/<name>` legt ihn an (oben); von Hand den Input in `flake.nix` anlegen und `nix-homebrew.taps."<owner>/homebrew-<tap>" = inputs.<input>;` in `hosts/gusto/configuration.nix`, dann `nix flake lock`. Seine Casks und Formeln heißen in `apps.json` dann `"<owner>/homebrew-<tap>/<name>"`.
- **Ein Werkzeug mit Konfiguration** – `programs.<tool>` in `hosts/gusto/home.nix` (zsh, git, tmux, …).

### Welcher Checkout, welcher Mac

Die Befehle ändern den nixlab-Checkout (oder Worktree), in dem der aktuelle Ordner liegt; überall sonst den aus `NIXLAB_REPO` (`~/Projects/homelab/nixlab`, gesetzt in `home.nix`), oder `--repo <pfad>`. Sie sind das Paket `nixlab-apps` aus diesem Flake, installiert über `home.nix` – eine Änderung am Werkzeug selbst kommt mit dem nächsten `just mac-switch`; `just apps*` nutzt immer die Version aus der Arbeitskopie.

Der Host ist standardmäßig gusto; `--host zorlock` geht, sofern der Host `nixlab.apps.file` setzt – zorlock tut das heute nicht. Für einen anderen Mac als den, an dem du sitzt, committet die Runde ohne Switch; danach `just push` und `just mac-switch <host>`.

## Paket per Hotfix fixen

Wenn nixpkgs eine Version mit Sicherheitslücke oder Bug ausliefert und der Fix noch nicht in unserem Pin ist, pinnen wir das Paket selbst – aber über `hotfix` aus [`modules/hotfixes.nix`](modules/hotfixes.nix), nicht mit einem nackten `overrideAttrs`. `hotfix` wendet das Override nur an, solange nixpkgs es noch braucht, und warnt, sobald es das nicht mehr tut.

Warum: Der nächtliche Auto-Upgrade bewegt `nixpkgs` und `nixpkgs-unstable` von selbst. Ein handgeschriebener Pin veraltet unbemerkt und pinnt, sobald nixpkgs weiter ist, eine *ältere* Version. So geschehen beim paperless-3.3.2-Bump auf ursalia: unstable hatte 3.3.2 schon eine Weile, bevor es jemand bemerkte. Die Warnung ist unsere Ergänzung, der Rest ist snowballs Arbeit, siehe [Credits](#credits).

### Wann sich der Hotfix abschaltet

`hotfix` gibt das nixpkgs-Paket unverändert zurück und warnt, sobald eins von beidem gilt:

- `pkg.version` ≥ `fixedVersion` – nixpkgs hat aktualisiert, oder
- einer von `pkg.patches` hat `fixPatch` im Dateinamen – stable hat den Fix als Patch zurückportiert, ohne die Version anzuheben (bei CVEs auf einem stable Release der Normalfall).

Das Override selbst samt src-Hash wird dann gar nicht mehr ausgewertet.

### Paket aus dem nixpkgs des Hosts: Overlay in `modules/hotfixes/`

Für Pakete aus dem normalen `pkgs` eines NixOS-Hosts (sudo, openssh, nginx …). Jede Datei in `modules/hotfixes/` wird auf **jedem** NixOS-Host als Overlay geladen – nicht aber auf den Macs, die `modules/*.nix` nicht bekommen.

```nix
# modules/hotfixes/sudo.nix
# CVE-2025-32463: chroot option lets local users run code as root.
hotfix: final: prev: {
  sudo = hotfix {
    name = "sudo CVE-2025-32463";
    pkg = prev.sudo;
    fixedVersion = "1.9.17p1";
    fixPatch = "CVE-2025-32463";
    override = pkg: pkg.overrideAttrs (old: rec {
      version = "1.9.17p1";
      src = final.fetchurl {
        url = "https://www.sudo.ws/dist/sudo-${version}.tar.gz";
        hash = "sha256-…";
      };
    });
  };
}
```

`fixPatch` ist optional und nur sinnvoll, wo der nixpkgs-Patch absehbar einen erkennbaren Namen hat (CVE-Nummer). Hash eintragen: erst `lib.fakeHash` stehen lassen, dann den richtigen Wert aus dem Build-Fehler übernehmen.

### Paket aus einem anderen nixpkgs: `hotfix` im Host-Modul

Pakete aus `import nixpkgs-unstable { … }` (paperless, Grist, …) sehen die Overlays nicht. Dort wird `hotfix` als Modul-Argument benutzt:

```nix
{ pkgs, nixpkgs-unstable, hotfix, ... }:
let
  unstable = import nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  paperless = hotfix {
    name = "paperless-ngx GHSA-…";
    pkg = unstable.paperless-ngx;
    fixedVersion = "3.4.1";
    override = pkg: pkg.overrideAttrs (finalAttrs: prev: { version = "3.4.1"; src = …; });
  };
in
```

Änderungen, die *nicht* an einer Version hängen – ein Patch für ein offenes Upstream-Issue, abgeschaltete Tests – bleiben außerhalb von `hotfix`, als normales `overrideAttrs` auf dem Ergebnis.

### Wo die Warnung erscheint

Es ist eine Evaluation-Warnung:

```
evaluation warning: hotfix "sudo CVE-2025-32463" is no longer needed: nixpkgs' sudo has version 1.9.17p1 (fix in 1.9.17p1) - remove it
```

Sie erscheint bei jedem `just ship`, `nixos-rebuild` und `nix eval` des Hosts – und auf den Pull-Hosts im Journal des nächtlichen Upgrades, wo sie niemand liest:

```bash
journalctl -u nixos-upgrade --since today | grep 'hotfix "'
```

Dann die Datei in `modules/hotfixes/` löschen bzw. das `hotfix { … }` aus dem Host-Modul entfernen und deployen.

### Credits

Das Muster – Versionsvergleich, Erkennung eines zurückportierten CVE-Patches, ein automatisch geladenes Overlay pro Datei – ist von snowball ([BBBSnowball](https://github.com/BBBSnowball)) und ausdrücklich zur Übernahme angeboten: [`hotfixes/` in BBBSnowball/nixcfg](https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes). Unsere Fassung ergänzt die Warnung und das Modul-Argument `hotfix` für Pakete aus einem anderen nixpkgs.

## Branch vor dem Merge auf einem Host testen

Ein Thema wird aus seinem Worktree auf einen Host deployt und erst nach erfolgreichem Test in main gemergt. Ohne Vorkehrung hielte das nur bis 04:00: Das nächtliche Upgrade baut `/etc/nixos` – also main – und schaltet den Host still zurück. Dasselbe passiert bei einem `just deploy` aus einem anderen Thema. `just try` setzt deshalb einen **Halt** auf dem Host, den alle Wege zurück zu main beachten ([`modules/deploy-hold.nix`](modules/deploy-hold.nix)).

### Ablauf

Aus dem Worktree des Themas, in einem echten Terminal – die Rezepte brauchen SSH und funktionieren nicht per `!` in der Claude-App:

```bash
cd .worktrees/<thema>
git rebase origin/main
just try ursalia
```

`just try <host>`:

1. bricht ab bei uncommitteten Änderungen (der Halt nennt einen Commit), auf main oder wenn der Branch nicht auf dem aktuellen `origin/main` aufsetzt – sonst würde der Test zurückdrehen, was andere inzwischen gemergt haben;
2. bricht ab, wenn ein **anderer** Branch den Host schon hält (derselbe Branch darf erneut deployen);
3. baut auf ursalia und schaltet um wie `just deploy-push`;
4. schreibt `/etc/nixos-hold` auf den Host: Branch, Commit, Zeitpunkt, von wo.

Läuft es, mergen und deployen:

```bash
git switch main && git merge --ff-only <thema> && git push
just deploy ursalia
```

`just deploy` (genauer `rebuild`) sieht, dass der gehaltene Commit jetzt in `/etc/nixos` enthalten ist, hebt den Halt auf und baut normal.

Läuft es nicht: zurück zu main mit

```bash
just release ursalia
just deploy ursalia
```

### Mit automatischem Zurückrollen: `just try-confirm`

Für Änderungen, die den Host abschneiden können – Netzwerk, NetBird, SSH, Firewall –, gibt es eine Variante mit Totmannschalter:

```bash
just try-confirm ursalia        # 5 Minuten zum Bestätigen
just try-confirm ursalia 10     # 10 Minuten
```

1. Dieselben Prüfungen und derselbe Build wie bei `just try`, aber nixos-rebuild schaltet nichts um.
2. Auf dem Host wird zuerst ein Timer gestellt: Nach Ablauf schaltet er zurück auf die Generation, die jetzt läuft.
3. Dann wird der Branch mit `switch-to-configuration test` aktiviert, als eigene Unit auf dem Host – die Aktivierung übersteht eine abgerissene SSH-Verbindung. `test` lässt den Boot-Eintrag in Ruhe: Auch ein Neustart oder ein Hänger landet in der alten Generation.
4. Die Workstation wartet, bis sie den Host wieder über das Mesh erreicht und die Aktivierung fertig ist, und fragt **Keep it? [y/N]**.
5. Erst `y` stoppt den Timer, setzt Systemprofil und Boot-Eintrag und schreibt den Halt wie `just try`. Alles andere – `n`, keine Antwort, keine Verbindung – und der Host rollt bei Ablauf von selbst zurück (`n` sofort).

Meldet sich der Host danach unter einem anderen Namen (Umbenennung), nennt `via` die Adresse, an die deployt wird; die Bestätigung geht immer an `<host>.peer.homelab.example`:

```bash
just try-confirm ursalia 10 root@ursalia-next.peer.homelab.example
```

Die Frage braucht ein echtes Terminal; ohne eines gilt die Antwort als „nein“.

Das Muster – einspielen, von außen prüfen, nur bei Bestätigung innerhalb einer Frist behalten, sonst zurück – stammt von snowball (BBBSnowball): [`firewall-update.sh`](https://github.com/BBBSnowball/nixcfg/blob/35264a74189686e8ce0231b4752f85225d0c9e00/hosts/sonline0/firewall-update.sh) macht das für iptables-Regeln, `try-confirm` für eine ganze NixOS-Generation.

### Wer den Halt beachtet

| Weg | Verhalten bei Halt |
| --- | --- |
| nächtliches `nixos-upgrade` | übersprungen (`ExecCondition`, kein Fehlschlag): kein Flake-Update, kein Switch, kein Reboot. Ist der gehaltene Commit inzwischen in `/etc/nixos`, hebt es den Halt auf und läuft. |
| `just rebuild`/`deploy`/`ship`/`deploy-all` | Abbruch, außer der gehaltene Commit ist im frisch gepullten `/etc/nixos` – dann Halt weg und Deploy |
| `just deploy-push <host>` | dieselbe Regel gegen den `HEAD` des lokalen Checkouts |
| ursalias nächtlicher Push nach cuckoosegg | übersprungen, außer der gehaltene Commit ist in ursalias `/etc/nixos` |

Die Regel ist überall dieselbe: Ein Halt blockiert, solange das, was deployt werden soll, den gehaltenen Commit nicht enthält. Ein **Rebase-Merge** schreibt den Commit neu – dann erkennt nichts den Merge, und der Halt muss mit `just release <host>` weg.

### cuckoosegg

`just try cuckoosegg` funktioniert genauso, der Halt liegt auf cuckoosegg. Nach dem Merge gibt es kein `just deploy cuckoosegg`: Entweder ursalias Push um 06:30 übernimmt, sobald ursalias Checkout den Merge hat (`just deploy ursalia` oder `just sync ursalia`), oder sofort aus main mit `just deploy-push cuckoosegg`.

### Sehen, wer was hält

- `just holds` – alle NixOS-Hosts auf einmal
- Login-Shell auf dem Host – eine Warnzeile, ab 48 h mit Hinweis auf `just release`
- Grafana „Homelab / Hosts Overview“, Panel **Deploy holds (just try)** – Metrik `nixlab_deploy_hold_since_seconds{branch,commit}`, orange solange ein Halt besteht, rot ab 48 h. Echte Alarmierung gibt es im Lab nicht; das Panel ist der Hinweis.

### Grenzen

- **Tofu** (`netbird-apply`, `desec-apply`, `pocketid-apply`) hat einen State und wird nur aus main angewandt. Ein Thema, das Tofu ändert, lässt sich damit nicht vorab testen.
- **Macs** (gusto, zorlock) sind nicht abgedeckt – sie haben kein nächtliches Upgrade, das zurückdrehen würde.
- **Zwei Themen auf einem Host** gleichzeitig gehen nicht: Das zweite `just try` bricht ab, bis das erste gemergt oder freigegeben ist.
- Ein Host vor `modules/deploy-hold.nix` kennt keinen Halt; der erste `just try` darauf bringt das Modul mit.
- **`try-confirm` und das nächtliche Upgrade:** Bis zur Bestätigung gibt es keinen Halt. Fällt die Frist über 04:00, baut `nixos-upgrade` main. Ändert der Branch den Hostnamen, baut es sogar main für den *neuen* Namen – beim Cut-over von ursalia (2026-10-27) bootete die NUC so die Konfiguration der M720q. Vorher `nixos-hold set` setzen oder nicht in die Nacht hinein testen.

## Repository-Struktur

Ein Flake, `nixosConfigurations` für fünf Hosts plus `darwinConfigurations` für die beiden Macs (zorlock, gusto) und zwei `devShells`: eine zum Arbeiten am Repo, eine mit dnscontrol für das DNSControl-Repo. Jeder Host bekommt eine explizite Modulliste in `flake.nix`; was fehlt, fehlt mit Begründung im Kommentar daneben.

| Pfad | Inhalt |
| --- | --- |
| `flake.nix` / `flake.lock` | Inputs, Host-Definitionen, Pakete, `lib.topology`, `lib.inventory`, `checks` |
| `modules/` | 19 geteilte Module: base, nix, hotfixes, ssh, firewall, networking (ifstate), acme, crowdsec, tailscale, netbird, metrics/metrics-shipping, logging/log-shipping, qemu-guest, deploy, auto-upgrade-git, docs-site, maintenance |
| `modules/darwin/` | Für die Macs: `homebrew.nix` (eine Homebrew-Richtlinie für jeden darwin-Host) und `rebuild.sh` (die Mechanik hinter den `mac-*`-Rezepten) |
| `hosts/gusto/` | Die Workstation: `configuration.nix` (System, Casks, macOS-Einstellungen), `home.nix` und `ssh.nix` (home-manager), `ssh/*.pub` (öffentliche Hälften der 1Password-SSH-Schlüssel) |
| `.envrc` | direnv: lädt die devShell des Flakes (sops, age, tofu, …) im Checkout |
| `hosts/<host>/` | `configuration.nix`, Hardware, Dienst-Module, sops-Dateien (`secrets.yaml`, `netbird.yaml`, `desec.yaml`) |
| `pkgs/` | Eigene Pakete: garage-ui, logchef, paperless-gpt, prometheus-paperless-exporter, ollama-metrics-proxy |
| `terraform/netbird/` | OpenTofu: NetBird-Account, Policies, DNS-Zonen, Reverse-Proxy-Dienste, Personen/Gruppen (inkl. Pocket ID) |
| `terraform/desec-tokens/` | OpenTofu: eng gescopte deSEC-Tokens pro Host für DNS-01 |
| `terraform/github/` | OpenTofu: die Repos `nixlab` (privat) und `nixlab-docs` (öffentlich), Deploy-Keys pro Host |
| `topology.nix` | Generiert das Topologie-Dashboard für Grafana aus den Host-Configs |
| `inventory.json` / `inventory.nix` | Lab-Inventar (jede Maschine: Art, Site, Uplink, Beziehungen, Entsperren) und seine Prüfung, siehe [Inventar](#inventar) |
| `inventory.schema.json` | JSON-Schema zum Bearbeiten von `inventory.json`, generiert |
| `tests/` | Tests, die `nix flake check` auswertet (`inventory.nix`) |
| `justfile` | Alle Bedienabläufe: deploy, secrets, netbird-\*, desec-\* |
| `docs/` | Diese Projektdokumentation: Seiten unter `site/{de,en}/`, Zensical-Konfiguration, Build (`build.sh`, `site-src.sh`, `assemble.py`, `gen-reference.py`, `gen-llms.py`), Paket der privaten Site (`package.nix`) und was sie sonst von Dritten laden würde – Schriften, glightbox (`assets.nix`), Installationsanleitungen (ursalia, cuckoosegg, gusto), Upstream-Issue-Entwürfe |
| `dnsconfig.js` | Symlink ins separate DNSControl-Repo – öffentliche DNS-Records leben dort |
| `.sops.yaml` | age-Empfänger pro Host, `admin` (Offline-Recovery) und `workstation` (1Password) |

## Wo ändere ich was?

Welche Datei für welche Änderung zuständig ist, wie oft das vorkommt und was danach zu tun ist.

| Was | Wo | Wie oft | Danach |
| --- | --- | --- | --- |
| Dienst, Paket oder Option auf einem Host | `hosts/<host>/*.nix` | häufig | `just ship <host> "…"` |
| Etwas für alle Hosts | `modules/*.nix` | gelegentlich | `just ship-all "…"`; neues Modul: öffentlich oder in `docs/modules-private.txt`? |
| Name hinter dem Reverse Proxy (grammi) | `hosts/grammi/proxy-services.json` | selten | CNAME in DNSControl, grammi deployen, `just netbird-apply` |
| Name nur im Mesh | `terraform/netbird/mesh-services.tf` | selten | `just netbird-apply` |
| Wer die private Doku lesen darf | Gruppe `admin-workstations` (`terraform/netbird/subraum.tf`, Peer-Namen) | selten | `just netbird-apply`, `admin-peers.json` committen, aldrin und ursalia deployen |
| NetBird-Policies, Gruppen, Personen, Routen | `terraform/netbird/*.tf` | selten | `just netbird-plan`, `just netbird-apply` |
| Wer die Exit-Nodes nutzen darf | Pocket-ID-Gruppe `exit-nodes` (auth.homelab.example) | selten | `just netbird-apply` |
| Öffentliche DNS-Records | DNSControl-Repo (`dnsconfig.js`) | selten | dort `dnscontrol preview`, `dnscontrol push`, committen |
| Was ein deSEC-Token darf | `terraform/desec-tokens/main.tf` | selten | `just desec-apply` |
| Repos, Deploy-Keys | `terraform/github/` | selten | `just github-plan`, `just github-apply` |
| Version eines automatisch aktualisierten Inputs | `flake.lock` | nachts automatisch | – |
| Version eines separat gepinnten Inputs | `flake.lock` (`nix flake update <input>`) | von Hand | Hosts deployen, die ihn nutzen |
| Eine Paketversion, die nixpkgs noch nicht hat (Sicherheitsfix) | `modules/hotfixes/` oder `hotfix` im Host-Modul | bei Bedarf | deployen; entfernen, sobald der Build warnt – [Paket per Hotfix fixen](#paket-per-hotfix-fixen) |
| Ein Thema vor dem Merge auf einem Host testen | Worktree des Themas | bei Bedarf | `just try <host>`, nach dem Merge `just deploy <host>` – [Branch vor dem Merge testen](#branch-vor-dem-merge-auf-einem-host-testen) |
| Grafana-Dashboard | `hosts/grammi/dashboards/*.json` | gelegentlich | grammi deployen |
| Topologie (neuer Host, Exporter, vHost) | `topology.nix` erzeugt sie | bei Bedarf | `just topology`, committen |
| Maschinendaten: Art, Hardware, Site, Uplink, Strom, Entsperren, Netze, Interfaces, Host-Keys | `inventory.json` | mit jedem neuen Gerät | `just inventory-collect`, `just inventory-test` ([Inventar](#inventar)) |
| Eine App oder ein CLI-Tool auf der Workstation | `hosts/gusto/configuration.nix` (Cask) oder `hosts/gusto/home.nix` (CLI) | bei Bedarf | `just mac-diff`, `just mac-switch` |
| Homebrew-Richtlinie der Macs | `modules/darwin/homebrew.nix` | selten | `just mac-switch` auf jedem Mac mit Homebrew |
| Versionen der Casks | `flake.lock` (Homebrew-Inputs) | von Hand | `just mac-upgrade`, committen |
| Inventar-Format (Felder, Gerätearten) | `spec` in `inventory.nix` | selten | `just inventory-schema`, Testfall, Doku |
| Secrets eines Hosts | `hosts/<host>/secrets.yaml` | selten | [Secrets eintragen](#secrets-eintragen) |
| Diese Dokumentation | `docs/site/{de,en}/` | mit jeder Änderung | `just docs` |

## Inhalt von hosts/&lt;host&gt;/

Was in einem Host-Verzeichnis liegt und wer es schreibt. Nicht jeder Host hat jede Datei.

| Datei | Inhalt | Geschrieben von |
| --- | --- | --- |
| `configuration.nix` | Host-Konfiguration: Netz, Dienste, vHosts | von Hand |
| `hardware-configuration.nix` | Hardware, Dateisysteme | `nixos-generate-config`, danach von Hand |
| `disk-config.nix` | Partitionierung (disko, nur ursalia) | von Hand |
| weitere `*.nix` | ein Dienst pro Datei, z. B. `backup.nix`, `samba.nix`, `netbird.nix`, `traefik.nix` | von Hand |
| `secrets.yaml` | App-Secrets, verschlüsselt für Host + admin | `just secrets <host>` |
| `netbird.yaml` | NetBird-Setup-Key | `just netbird-key <host>` (Tofu) |
| `desec.yaml` | deSEC-Token für DNS-01 | `just desec-key <host>` (Tofu) |
| `maintenance.yaml` | Bypass-Token des [Wartungsmodus](#dienst-trotzdem-sehen), gleich auf aldrin, zummi, grammi, ursalia | `just maintenance-token` |
| `github.yaml` | privater Teil des Deploy-Keys | `just github-key <host>` |
| `github-deploy.pub` | öffentlicher Teil, von `terraform/github` gelesen | `just github-key <host>` |
| weitere `*.yaml` | sops-Dateien einzelner Dienste, z. B. `netbird-server.yaml`, `netbird-proxy.yaml` (grammi), `push-cuckoosegg.yaml` (ursalia) | ihre Rezepte, z. B. `just netbird-server-secrets`, `just netbird-proxy-token` |
| `push-key.pub` | öffentlicher Schlüssel für den Push-Deploy (nur cuckoosegg) | `just cuckoosegg-push-key` |
| `dashboards/*.json` | Grafana-Dashboards (nur grammi) | von Hand, `topology.json` per `just topology` |
| `proxy-services.json` | Dienste hinter dem Reverse Proxy (nur grammi) | von Hand, gelesen von Tofu und `topology.nix` |

## Inputs und ihre Pins

Nur `nixpkgs`, `nixpkgs-unstable` und `sops-nix` laufen im nächtlichen Auto-Upgrade mit (`updateInputs` in `modules/deploy.nix`). Alles, was bei einem kaputten Release das ganze Lab aussperren würde, ist separat gepinnt und wird von Hand gebumpt.

| Input | Branch / Tag | Wer nutzt es | Nachts mit? |
| --- | --- | --- | --- |
| `nixpkgs` | nixos-26.05 | alle NixOS-Hosts | ja |
| `nixpkgs-unstable` | nixos-unstable | grammi (Grist), ursalia (Paperless 3.x), zorlock (mactop) | ja |
| `sops-nix` | main | alle | ja |
| `nixpkgs-netbird` | nixos-unstable | NetBird-Server und alle Clients | nein – Server zuerst, dann Clients |
| `nixpkgs-pocketid` | nixos-26.05 | zummi (pocket-id-Paket) | nein |
| `disko` | main | ursalia (alle Mounts) | nein |
| `lanzaboote` | v1.1.0 | ursalia (Secure Boot) | nein |
| `nixpkgs-darwin`, `nix-darwin` | 26.05-darwin | zorlock, gusto | nein (kein Auto-Upgrade) |
| `home-manager` | release-26.05 | gusto (Dotfiles) | nein – zusammen mit `nix-darwin` |
| `nix-homebrew` | main | Macs mit Homebrew (gusto): das Modul, das Homebrew installiert | nein – `just mac-upgrade` |
| `brew-src` | Tag `7.0.11` (`flake = false`) | Macs mit Homebrew: Homebrew selbst, statt des eigenen Pins von nix-homebrew | nein – Tag in `flake.nix` ändern |
| `homebrew-core`, `homebrew-cask` | main (`flake = false`) | Macs mit Homebrew: die festgeschriebenen Taps | nein – `just mac-upgrade` |
| `netbirdio-tap` | main (`flake = false`) | gusto: NetBird-App (Cask `netbird-ui`) | nein – `just mac-upgrade` |
| `stablyai-orca-tap` | main (`flake = false`) | gusto: Orca (Cask `orca`), gepinnt von `apps` | nein – `just mac-upgrade` |

Die Homebrew-Inputs sind der Grund, warum ein Cask eine feste Version hat: Mit `mutableTaps = false` kann Homebrew seine Taps nicht selbst aktualisieren, siehe [macOS-Hosts](#macos-hosts).

`nix flake check` prüft zusätzlich, dass `hosts/grammi/dashboards/topology.json` zu dem passt, was `topology.nix` gerade erzeugt – ein neuer Exporter ohne `just topology` lässt den Check fehlschlagen.

## Hosts & Rollen

Drei gemietete VMs tragen die öffentlichen Dienste, ursalia und zorlock stehen zu Hause, cuckoosegg im Subraum; gusto ist die Admin-Workstation (ein MacBook). Alle Server sind über `<host>.peer.homelab.example` im NetBird-Mesh erreichbar; root-SSH gibt es nur dort. Art, Site, Uplink und Entsperren jeder Maschine – auch der Router, des KVM und der Appliances – stehen im [Inventar](#inventar), alles zusammen auf einen Blick in der [Lagekarte](#lagekarte).

| Host | Plattform | Rolle | Besonderheiten |
| --- | --- | --- | --- |
| grammi | NixOS, gemietete VM | NetBird-Server (`mesh.homelab.example`) + Reverse Proxy, Traefik, Monitoring (VictoriaMetrics/-Logs, Grafana, logchef), Mealie, Grist, PostgreSQL | Zentrale Senke für Metriken und Logs aller Hosts |
| zummi | NixOS, gemietete VM | Pocket ID (`auth.homelab.example`) – Login für alle Dienste und NetBird | pocket-id separat gepinnt |
| aldrin | NixOS, gemietete VM | Garage S3 (`s3.aldrin.homelab.example`), garage-ui (`s3-admin`), Backup-Ziel für restic, Doku-Site (`doku`) | Fork-Paket garage-ui mit Subpath-Support |
| ursalia | NixOS, Bare Metal (ASRock NUC BOX-1260P) | Paperless-ngx 3 + paperless-gpt (`dokumente`), HealthLog (`health`), Doku-Site (`doku`), Samba für den Scanner, Routing-Peer ins Heim-LAN, Build-Host für cuckoosegg, ESPHome-Build-Server für Home Assistant (nur Heim-LAN, Port 6055), Claude-Code-Brücke zum NanoKVM Go+ (nur bei Bedarf) | LUKS + btrfs via disko, TPM-Unlock, Secure Boot (lanzaboote), WLAN (Intel BE200), kein CrowdSec |
| cuckoosegg | NixOS, VM auf dem Subraum-Proxmox | NetBird-Routing-Peer in die Subraum-Netze | Gruppe `subraum-devices` statt `servers`, kein Repo/Deploy-Key, wird per Push deployed |
| zorlock | macOS + nix-darwin, Mac mini M4 | Ollama auf der Apple-GPU (`llm`), genutzt von paperless-gpt | Keins der `modules/*.nix`; FileVault-Unlock nach Reboot per LAN-SSH |
| gusto | macOS + nix-darwin + home-manager, MacBook Pro | Admin-Workstation: Deploys, Secrets, Tofu, Doku | Laptop, kein sshd, keine Secrets, nicht überwacht; Apps als Homebrew-Casks, NetBird als offizielle App – siehe [gusto](#gusto--die-admin-workstation) und [macOS-Hosts](#macos-hosts) |

## gusto – die Admin-Workstation

gusto ist das MacBook Pro, von dem aus alles in diesem Repo läuft: Deploys, Secrets, Tofu, die Doku. Es ist der zweite nix-darwin-Host neben zorlock und das einzige Gerät im Lab, an dem ein Mensch sitzt. Diese Seite ist die vollständige Referenz dafür – was darauf ist, wo jeder Teil konfiguriert wird, wie es im Alltag benutzt wird und was zu prüfen ist, wenn etwas nicht geht. *Warum* es so gebaut ist (Homebrew-Richtlinie, NetBird als App, die Unterschiede zu zorlock), steht unter [macOS-Hosts](#macos-hosts).

### Überblick

| | |
| --- | --- |
| Hardware | Apple MacBook Pro (Apple Silicon), im Inventar `kind: laptop`, `availability: intermittent` |
| System | macOS (Englisch, Region Deutschland), FileVault an |
| Konfiguration | `darwinConfigurations.gusto` in `flake.nix`: nix-darwin + home-manager (Benutzer `admin`) |
| Gebaut und geschaltet | auf gusto selbst, aus dem Arbeitsklon `~/Projects/homelab/nixlab` – `just mac-switch` |
| Apps | Homebrew-Casks; Homebrew und seine Taps in `flake.lock` festgeschrieben (`modules/darwin/homebrew.nix`); alle Software steht in `hosts/gusto/apps.json` |
| Repo-Werkzeuge | aus der devShell des Flakes, von direnv im Repo-Ordner geladen |
| SSH | nur Client, Schlüssel nur in 1Password; kein Remote Login (kein sshd) |
| Mesh | NetBird-Peer `gusto` (Cask `netbird-ui`), Gruppe `admin-workstations` |
| Secrets | nur `hosts/gusto/mcp.yaml` (die [MCP-Server der Claude-App](#mcp-server-der-claude-app)), verschlüsselt für den Workstation-age-Schlüssel aus 1Password; gusto hat keinen eigenen Host-Schlüssel |
| Monitoring | keins; nicht in der Topologie, nichts im Lab hängt davon ab (`criticality: lab`) |
| Sicherung | Arq 7 nach Garage auf aldrin, dazu Time Machine |

### Dateien

| Datei | Inhalt |
| --- | --- |
| `hosts/gusto/configuration.nix` | System: Hostname, Nix-Einstellungen, Touch ID für sudo, Taps, SSH-Hostkeys, `SSH_AUTH_SOCK` für GUI-Apps, macOS-Einstellungen, Einbindung von home-manager |
| `hosts/gusto/home.nix` | admins Home: Umgebung, Links, zsh und Helfer, CLI-/TUI-Werkzeuge, Ghostty, git |
| `hosts/gusto/ssh.nix` | `~/.ssh/config` und `~/.ssh/pub/` |
| `hosts/gusto/mcp.nix`, `mcp.yaml` | Die MCP-Server der Claude-App: `mcp-run` und ihre Einträge in den Konfigs von Claude; ihre Zugangsdaten (sops) |
| `hosts/gusto/ssh/*.pub` | Öffentliche Hälften der SSH-Schlüssel (einer pro Ziel), verlinkt nach `~/.ssh/pub/` |
| `hosts/gusto/apps.json` | Alle Software: Casks, Formeln, Mac App Store, nixpkgs (System, Benutzer, Schrift), jeweils mit Notiz – `apps-list` |
| `modules/darwin/apps.nix`, `apps.schema.json` | Macht aus `apps.json` die Optionen und prüft sie; Editor-Schema |
| `pkgs/nixlab-apps/` | Das Werkzeug hinter `apps`, `apps-list`, `apps-rm` |
| `modules/darwin/homebrew.nix` | Homebrew-Richtlinie, gemeinsam mit zorlock |
| `modules/darwin/rebuild.sh` | Die Mechanik hinter den `mac-*`-Rezepten |
| `.envrc` | `use flake` – direnv lädt die devShell im Repo-Ordner |
| `docs/install-gusto.md` | gusto von Grund auf aufsetzen (nur in der privaten Doku) |

Flake-Inputs nur für gusto: `home-manager`, `nix-homebrew`, `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap` – siehe [Flake-Inputs](#inputs-und-ihre-pins).

### Was installiert ist

gusto wurde am 2026-10-21 bewusst „nackt“ aufgesetzt: keine App-Liste aus der vorherigen Installation übernommen, nur die Grundausstattung unten. Alles andere kommt dazu, wenn es gebraucht wird (siehe [Im Alltag](#im-alltag)). Die Tabellen beschreiben sie; die vollständige, aktuelle Liste ist `hosts/gusto/apps.json` – `apps-list`.

#### Apps (Homebrew-Casks)

| Cask | Wofür |
| --- | --- |
| `1password`, `1password-cli` | Passwörter, der SSH-Agent mit allen SSH-Schlüsseln, `op` für Skripte (age-Schlüssel für sops). Die CLI als Cask, nicht aus nixpkgs: Sie entsperrt über die App mit Touch ID, und das geht nur mit dem signierten Binary des Herstellers. |
| `vivaldi` | Browser |
| `arq` | Sicherung nach Garage auf aldrin |
| `claude` | Claude-Desktop-App; ihre lokalen MCP-Server: [MCP-Server der Claude-App](#mcp-server-der-claude-app) |
| `ghostty` | Terminal |
| `netbirdio/homebrew-tap/netbird-ui` (+ Formula `netbird`) | NetBird-Menüleisten-App und Daemon – siehe [NetBird](#netbird) |
| `stablyai/homebrew-orca/orca` | Orca – IDE, um mehrere KI-Coding-Agenten nebeneinander in Terminals und Worktrees laufen zu lassen; aus Stablys eigenem Tap (Input `stablyai-orca-tap`), aktualisiert sich selbst. Entfernen löscht per zap auch `~/.orca` |
| `shottr` | Screenshots |
| `telegram`, `whatsapp` | Messenger |
| `spotify` | Musik |
| `visual-studio-code` | Editor (Microsofts Build wegen Remote-SSH und Pylance); Telemetrie aus, `settings.json` kommt aus home-manager und ist schreibgeschützt |

Aus dem Mac App Store (`homebrew.masApps`, über `mas`; braucht die App-Store-Anmeldung): **1Blocker**, **1Password for Safari**, **Ivory**, **TestFlight**. `zap` entfernt auch App-Store-Apps, die nicht deklariert sind; `just mac-switch` hält vorher an und fragt (siehe [macOS-Hosts](#macos-hosts)).

#### Systemweit (nix-darwin)

`git`, `gh`, `just`, `jq`, `neovim` (`EDITOR`/`VISUAL`, bleibt auch unter sudo erhalten), `curl`, `wget`, `rsync`; zsh als Systemshell (`programs.zsh`); die Schrift **Maple Mono NF** (Nerd Font) für Ghostty und die TUIs.

#### admin (home-manager)

| Werkzeug | Hinweise |
| --- | --- |
| zsh | Konfig in `~/.config/zsh`, Autosuggestions, Syntax-Hervorhebung, Verlauf in `~/.local/state/zsh/history` |
| atuin | Shell-Verlauf in SQLite, Suche mit Ctrl-R / ↑; Update-Prüfung aus |
| fzf | Ctrl-T (Dateien), Alt-C (cd) |
| zoxide | `z <Teil eines Pfads>` |
| direnv + nix-direnv | Umgebungen pro Ordner; hält Flake-Shells im Cache und schützt sie vor der GC |
| bat, eza, ripgrep, fd, tree | Ersatz für `cat`/`ls`/`grep`/`find`; eza bringt `ls`, `ll`, `la`, `lt` mit |
| lazygit, btop, yazi, tmux | TUIs; yazi als `y` (wechselt beim Beenden in den letzten Ordner), tmux mit Maus, `tmux-256color` |
| nvd, nix-output-monitor | Closure-Vergleiche, lesbare Build-Ausgabe (`nom`) |
| uv | Python-Werkzeuge (`uv tool install` → `~/.local/bin`) |
| typst | Dokumente (real-fast-document) |

#### Repo-Werkzeuge (devShell)

`sops`, `age`, `ssh-to-age`, `opentofu`, `nvd` – aus `devShells.aarch64-darwin.default`, in den Versionen aus `flake.lock`. Sie sind in jeder Shell im Repo-Ordner da (direnv), sonst nicht. `dnscontrol` kommt aus `devShells.aarch64-darwin.dns` und ist nur im DNSControl-Ordner da, dort hinter einem Wrapper, der die Zugangsdaten mit sops entschlüsselt – siehe [macOS-Hosts](#dnscontrol). Die Doku-Werkzeuge (pandoc, WeasyPrint, Zensical) gehören nicht dazu; `just docs` und `just docs-serve` holen sich ihre eigenen.

### Umgebung

| Variable / Pfad | Wert | Warum |
| --- | --- | --- |
| `PATH` | Nix-Profile, dann `/opt/homebrew/bin:sbin`, dann die macOS-Ordner; für admin `~/.local/bin` davor | Nix vor Homebrew, Homebrew vor Apples Platzhaltern; nirgends `brew shellenv` |
| `SSH_AUTH_SOCK` | `~/.1password/agent.sock` | jeder SSH-Client spricht mit 1Password – in Shells (home-manager) und GUI-Apps (`launchd.user.envVariables`) |
| `SOPS_AGE_KEY_CMD` | `op read "op://<vault>/<item>/password"` | sops holt den Workstation-Schlüssel aus 1Password, wenn es ihn braucht; nie auf der Platte |
| `EDITOR`, `VISUAL` | `nvim` | |
| `GOPATH` / `GOBIN` | `~/.local/share/go` / `~/.local/bin` | XDG; Programme in den einen persönlichen PATH-Ordner |
| `CARGO_HOME` / `CARGO_INSTALL_ROOT` | `~/.local/share/cargo` / `~/.local` | ebenso; `cargo install` schreibt nach `<root>/bin` |
| `ZDOTDIR` | `~/.config/zsh` | gesetzt vom Platzhalter `~/.zshenv`, den home-manager schreibt |

#### Von home-manager verwaltete Dateien und Links

| Pfad | |
| --- | --- |
| `~/.zshenv` → `~/.config/zsh/.zshenv`, `.zshrc` | zsh |
| `~/.config/git/config` | git |
| `~/.config/ghostty/config` | Ghostty |
| `~/.config/tmux/tmux.conf`, `~/.config/atuin/config.toml`, `~/.config/direnv/…`, `~/.config/lazygit/config.yml` | die Werkzeuge |
| `~/.ssh/config`, `~/.ssh/pub/` | SSH |
| `~/.1password/agent.sock` → `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` | Pfad ohne Leerzeichen für den Agent; 1Password legt ihn nicht selbst an |
| `~/.config/ssh` → `~/.ssh` | XDG-Regel: Werkzeuge ohne XDG-Unterstützung bekommen einen Link unter `~/.config` |

Findet home-manager eine Datei schon vor, die es schreiben will (erster Switch auf frischem macOS), wird sie in `<Name>.before-hm` umbenannt, statt den Switch abzubrechen.

### macOS-Einstellungen

Am 2026-10-21 einzeln entschieden; alles nicht Genannte ist macOS-Standard.

| Bereich | Einstellung | nix-darwin-Option |
| --- | --- | --- |
| Menüleisten-Uhr | 24 h, Wochentag, kein Datum | `menuExtraClock.Show24Hour`, `ShowDayOfWeek`, `ShowDate = 2` |
| Dock | immer sichtbar, keine Vergrößerung, Symbolgröße 66 | `dock.autohide`, `magnification`, `tilesize` |
| | keine Startanimation, kein Hüpfen | `dock.launchanim`, `CustomUserPreferences."com.apple.dock"."no-bouncing"` |
| | ins App-Symbol minimieren, Effekt „Skalieren“, keine zuletzt benutzten Apps | `minimize-to-application`, `mineffect`, `show-recents` |
| | aktive Ecke unten rechts: Schnelle Notiz | `dock.wvous-br-corner = 14` |
| | Dock-Inhalt | (noch) nicht verwaltet |
| Finder | Pfadleiste an, Statusleiste aus, Symbole auf dem Schreibtisch, Listenansicht, Ordner zuerst (Fenster und Schreibtisch) | `finder.ShowPathbar`, `ShowStatusBar`, `CreateDesktop`, `FXPreferredViewStyle = "Nlsv"`, `_FXSortFoldersFirst`, `_FXSortFoldersFirstOnDesktop` |
| Allgemein | dunkles Erscheinungsbild, alle Dateiendungen, automatische Großschreibung, Punkt nach doppeltem Leerzeichen | `NSGlobalDomain.AppleInterfaceStyle`, `AppleShowAllExtensions`, `NSAutomaticCapitalizationEnabled`, `NSAutomaticPeriodSubstitutionEnabled` |
| Trackpad | Force Click an, Zeigergeschwindigkeit 1 | `NSGlobalDomain."com.apple.trackpad.forceClick"`, `"com.apple.trackpad.scaling"` |
| Tastatur | Eingabequellen Deutsch (Haupt) und U.S. | `CustomUserPreferences."com.apple.HIToolbox".AppleEnabledInputSources` – U.S. für KVM-Sitzungen (NanoKVM Go+ und ArkKVM tippen PC-Scancodes); wirkt nach einmal Ab- und Anmelden |
| Netzwerknamen | `gusto` als Computer-, lokaler Host- und SMB-NetBIOS-Name | `networking.*Name`, `smb.NetBIOSName` |
| Sprache, Region | Englisch, Deutschland | nicht über Nix – bei der macOS-Einrichtung |

Nach jedem Switch läuft `activateSettings -u` als admin, damit die meisten Einstellungen ohne Abmelden greifen.

### Nix

Experimentelle Features `nix-command flakes`; `admin` ist trusted user; keine Channels; `min-free` 5 GiB / `max-free` 20 GiB; Store-Optimierung an; Garbage Collection sonntags 12:15, alles älter als 30 Tage. Keine zusätzlichen Binary-Caches – alle Inputs folgen nixpkgs, ein Community-Cache hätte keine Treffer.

### Sicherheit

- **FileVault** an (macOS-Einrichtung).
- **sudo mit Touch ID** (`/etc/pam.d/sudo_local`, das macOS-Updates in Ruhe lassen), auch in tmux (`pam_reattach`).
- **Kein Remote Login**: gusto hat kein sshd und nimmt keine SSH-Verbindungen an. Weder das Inventar noch `.sops.yaml` haben einen Schlüssel dafür, also wird nie ein Secret dafür verschlüsselt.
- **Schlüssel nur in 1Password**: SSH-Schlüssel (Agent), der age-Schlüssel für sops (`op read`), die Arq-Zugangsdaten. Nichts Privates unter `~/.ssh`. Die Zugangsdaten der MCP-Server liegen in sops (`hosts/gusto/mcp.yaml`), lesbar nur mit diesem age-Schlüssel.

### SSH

`~/.ssh/config` wird erzeugt (`hosts/gusto/ssh.nix`). Ganz oben, vor jedem `Host`-Block: `IdentityAgent ~/.1password/agent.sock`, `IdentitiesOnly yes`, `Compression yes`, `SendEnv LANG LC_*` – in ssh_config gewinnt der erste Wert, also kann nichts weiter unten sie ändern. Jedes `IdentityFile` nennt einen **öffentlichen** Schlüssel in `~/.ssh/pub/`; daran erkennt der Agent, welchen einen Schlüssel er anbieten soll.

Hostkeys: Lab-Hosts aus `inventory.json` (`/etc/ssh/ssh_known_hosts`), GitHub fest hinterlegt; der Rest landet beim ersten Kontakt in `~/.ssh/known_hosts`.

| `ssh …` | Ziel | Benutzer | Schlüssel (`~/.ssh/pub/`) | Hinweise |
| --- | --- | --- | --- | --- |
| `aldrin`, `grammi`, `zummi`, `ursalia`, `cuckoosegg` (auch `<host>.peer.homelab.example`) | `<host>.peer.homelab.example` (NetBird) | root | `<host>.homelab.example.pub` | aus dem Inventar erzeugt: jeder verwaltete Host außer gusto |
| `zorlock` | `zorlock.peer.homelab.example` | admin | `zorlock.homelab.example.pub` | kein root auf macOS |
| `<host>.example-tailnet.ts.net` | Tailscale | wie oben | wie oben | Notzugang, solange Tailscale läuft; nicht für cuckoosegg. Fällt mit Tailscale weg. |
| `aldrin.homelab.example`, `grammi.homelab.example`, `zummi.homelab.example` | öffentliche Adresse | admin | wie oben | Ausweichweg, wenn das Mesh nicht geht – root ist auf öffentlichen Adressen gesperrt (`modules/ssh.nix`) |
| `zorlock-lan` | 198.51.100.86 | admin | `zorlock.homelab.example.pub` | FileVault-Entsperren nach einem Neustart, aus dem Heimnetz |
| `opnsense` | 198.51.100.1 | root | `opnsense.pub` | |
| `arkkvm`, `arkkvm01` | `arkkvm01` (DHCP-Name) | root | `arkkvm.pub` | |
| `subraum-router` | hackspace.c3pb.de | admin | `c3pb.de.pub` | Jumphost; Weiterleitungen 8006 → Proxmox, 8080/8081 → Home Assistant |
| `vogon`, `amnesia`, `unifi` | `<name>.subraum.c3pb.de` über `subraum-router` | root | `<name>.subraum.c3pb.de.pub` | |
| `git.c3pb.de` | | git | `git.c3pb.de.pub` | |
| `edi` | | admin | – | `HostKeyAlgorithms +ssh-rsa` |
| `switch-*`, `172.31.64.*`, `172.31.65.*` | | bernd (Switches) | – | alte Switches: *ergänzt* SHA-1-KEX, `ssh-rsa`, CBC-Ciphers |
| `github.com` | | git | `github.com.pub` | ControlMaster, 60 s |
| `github-443` | ssh.github.com:443 | git | `github.com.pub` | für Netze, die Port 22 sperren |

Die zusätzlichen Namen (Tailnet, öffentlich) tragen `HostKeyAlias <host>.peer.homelab.example`, werden also alle gegen den einen Hostkey aus dem Inventar geprüft. Ein neuer verwalteter Host erscheint nach `just mac-switch` von selbst – nur seine öffentliche Schlüsseldatei muss nach `hosts/gusto/ssh/`.

### git

`~/.config/git/config`: Name `admin`, Adresse `mail@admin.org`; unterhalb von `~/Projects/homelab/` (`includeIf gitdir:`) `admin@homelab.example`. `init.defaultBranch = main`, `pull.rebase = true`, Alias `lg = log --oneline`. GitHub per SSH mit dem Schlüssel `github.com SSH (admin)` aus 1Password; `gh` für die API.

### NetBird

Die offizielle App aus NetBirds Tap (Cask `netbird-ui`, Formula `netbird` für den Daemon), festgeschrieben als Input `netbirdio-tap`. Anmeldung per SSO (Pocket ID) in der App, Peer-Name `gusto`, Gruppe `admin-workstations` (Subraum-Geräte, Doku-Site). Rosenpass ist auf der Workstation **aus** (seit 2026-10-21, seit 2026-10-24 im ganzen Mesh bis 2026-10-31). Die Version folgt dem Tap, nicht `nixpkgs-netbird`; `just mac-upgrade` zeigt beide an. Details und der Vergleich mit zorlock: [macOS-Hosts](#netbird-auf-den-beiden-macs).

### MCP-Server der Claude-App

Die Desktop-App und Claude Code starten ihre lokalen MCP-Server als stdio-Prozesse über `mcp-run <server>` (`hosts/gusto/mcp.nix`, eingerichtet am 2026-10-23). Bei jedem Start entschlüsselt `mcp-run` nur den Abschnitt dieses Servers aus `hosts/gusto/mcp.yaml`. Die Datei ist mit sops für die Schlüssel `workstation` und `admin` verschlüsselt; `op` fragt dabei unter Umständen nach Touch ID. Danach startet `mcp-run` den Server. In keiner Konfigdatei von Claude steht ein Zugangsdatum.

| Server | Was | Start | Zugangsdaten in `mcp.yaml` | Desktop | Claude Code |
| --- | --- | --- | --- | --- | --- |
| `homeassistant` | [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) als App (Add-on) auf dem Raspberry Pi, Port 9583 | `uvx fastmcp-remote <url>`, Brücke von HTTP auf stdio | `homeassistant.url`: die geheime URL der App, Host `homeassistant.peer.homelab.example` | ja | ja |
| `feedbin` | [FeedbinMCP](https://github.com/admin/FeedbinMCP), admins Fork von [hypermoose/FeedbinMCP](https://github.com/hypermoose/FeedbinMCP) | `uv run --directory ~/Projects/personal/FeedbinMCP feedbin-mcp` | `feedbin.email`, `feedbin.password` | ja | nein |
| `arkkvm` | [arkkvm-mcp](https://github.com/admin/arkkvm-mcp) | `uv run --directory ~/Projects/arkkvm/arkkvm-mcp arkkvm-mcp`, Host `arkkvm01`, Tastaturlayout `de` | `arkkvm.password` | ja | ja |

- **ha-mcp statt der eingebauten Integration „Model Context Protocol Server“:** Die eingebaute Integration sieht nur, was für Assist freigegeben ist, und keine Geräte-Registry. ha-mcp kann Automationen, Dashboards, Registries, Verlauf und mehr, mit Schreibrechten. Das ist bewusst so: Claude fragt vor jedem Werkzeugaufruf, und ha-mcp legt vor Änderungen ein Backup an. Die App spricht über den Supervisor mit HA, es braucht also kein Long-lived Token. Ihre geheime URL steht beim Start im Log der App.
- **Erreichbar über das Mesh:** Zu Hause und unterwegs gilt dieselbe URL. Die NetBird-Policy `home-assistant-mcp` (`terraform/netbird/home-assistant.tf`) erlaubt `admin-workstations` → HA, nur TCP 9583. Außerhalb von LAN und Mesh nützt die URL allein nichts.
- **Feedbin nicht in Claude Code:** Feed-Artikel sind fremder Text, also ein Weg für Prompt Injection, und Claude Code hat auf gusto eine Shell und sops.
- **Konfig:** Jeder Switch trägt die Server per `jq` in `mcpServers` von `~/Library/Application Support/Claude/claude_desktop_config.json` bzw. `~/.claude.json` ein, nach Namen. Von Hand ergänzte Server bleiben erhalten; einen hier entfernten Server musst du dort von Hand löschen. Die Apps lesen die Datei beim Start, nach einem Switch also neu starten.
- **Zugangsdaten ändern:** `cd ~/Projects/homelab/nixlab && sops hosts/gusto/mcp.yaml`. Die Änderung gilt ab dem nächsten Serverstart, ohne Switch, denn `mcp-run` liest die Datei im Arbeitsklon. Die HA-URL lässt sich direkt aus der Zwischenablage übernehmen, dabei wird der Host durch den Mesh-Namen ersetzt:
  `cd ~/Projects/homelab/nixlab && sops set hosts/gusto/mcp.yaml '["homeassistant"]["url"]' "\"$(pbpaste | sed -E 's#^http://[^/]+#http://homeassistant.peer.homelab.example:9583#')\""`
- **MoneyMoney** ist noch nicht eingerichtet, weil MoneyMoney seit der Neuinstallation nicht auf gusto ist. Früher lief es als `npx -y moneymoney-mcp`; das braucht Node und die laufende, entsperrte App.

### Sicherung

- **Arq 7** sichert die ganze Platte in das Garage-Bucket auf aldrin, mit einem eigenen Backup-Plan für gusto (der Plan des vorigen MacBooks bleibt nur zum Wiederherstellen). Verschlüsselungspasswort und Garage-Zugangsdaten liegen in 1Password.
- **Time Machine** zusätzlich.
- Zum Neuaufbau braucht gusto keine Sicherung: System und Dotfiles sind dieses Repo, die Schlüssel liegen in 1Password. Die Sicherung ist für Daten.

### Im Alltag

| Aufgabe | Wie |
| --- | --- |
| Apps und CLI-Werkzeuge hinzufügen oder entfernen | `apps [suche]` (in jedem Ordner; im Repo auch `just apps`) – eine Runde: suchen, auswählen, Suche ändern, wieder auswählen …, dann ein Switch und ein Commit ([Anleitung](#software-auf-den-macs)); ein Werkzeug mit Konfiguration: `programs.<tool>` in `hosts/gusto/home.nix` |
| Eins direkt entfernen | `apps-rm <name>`; Casks gehen samt Daten (`zap`) – vorher kommt `mac-diff` |
| Sehen, was deklariert ist | `apps-list` |
| Apps aktualisieren (Homebrew) | `just mac-upgrade` – aktualisiert nur die Tap-Inputs, Switch, `brew upgrade`, Zusammenfassung; danach `flake.lock` committen |
| System aktualisieren (Nix) | `nix flake update nixpkgs-darwin nix-darwin home-manager` → `just mac-switch` → auch `just mac-switch zorlock` (gleiche Inputs) |
| NixOS-Host deployen | `just ship <host> "<Nachricht>"` oder `just deploy <host>` – übers Mesh als root |
| Secrets bearbeiten | `just secrets <host>` (Touch ID für `op`) |
| Doku | `just docs-serve` (Vorschau), `just docs` (PDFs + öffentliches Repo) |
| Neuer Klon oder Worktree | einmal `direnv allow` darin |

Alle `mac-*`-Rezepte nehmen den Host als optionalen Parameter (Standard `gusto`; `zorlock` läuft per SSH nach einem `git pull` dort). Neue Dateien muss git kennen (`git add`), bevor ein Switch sie sieht.

### Fehlersuche

| Symptom | Prüfen |
| --- | --- |
| `ssh-add -L`: „The agent has no identities“ / „Could not open a connection“ | 1Password läuft und ist entsperrt, Settings → Developer → *Use the SSH agent*; `ls -l ~/.1password/agent.sock`; `echo $SSH_AUTH_SOCK` |
| ssh bietet den falschen Schlüssel an / „Too many authentication failures“ | `ssh -G <host> \| grep -E 'identityfile\|identityagent'` – genau eine `.pub` aus `~/.ssh/pub/` |
| Hostkey passt nicht bei einem Lab-Host | Host neu installiert oder Schlüssel getauscht: Inventar aktualisiert? Dann `just mac-switch` (die Hostkeys gehören zum System) |
| `sops`, `tofu` nicht gefunden | nicht im Repo-Ordner, oder `direnv allow` fehlt |
| sops: „failed to get the data key“ | `op read "op://<vault>/<item>/password" \| age-keygen -y` muss das `age1…` der Workstation ausgeben |
| `brew` installiert nichts / Tap fehlt | Taps kommen nur aus `flake.lock` (`mutableTaps = false`); `brew tap` und `brew update` sind nicht der Weg – Input anlegen, `just mac-switch` |
| Eine Einstellung greift nicht | einmal ab- und anmelden (Eingabequellen, manche Dock-/Finder-Schlüssel) |
| `.before-hm`-Dateien im Home | Reste vom ersten Switch; vergleichen und löschen |
| Ein MCP-Server verbindet nicht | im Terminal `mcp-run <server>` starten: hängt es an Touch ID oder sops, fehlt ein Wert in `mcp.yaml`, fehlt der Checkout? Die Desktop-App protokolliert nach `~/Library/Logs/Claude/mcp-server-<name>.log` |
| `homeassistant` hängt | Port in der URL muss 9583 sein, die Policy verwirft jeden anderen still (Timeout nach 30 s): `sops decrypt --extract '["homeassistant"]["url"]' hosts/gusto/mcp.yaml \| cut -d/ -f3` zeigt nur Host und Port; `nc -z homeassistant.peer.homelab.example 9583`; zeigt `netbird status -d` HA als „Connected“, aber ohne WireGuard-Handshake, steht Rosenpass in der NetBird-App auf HA auf strikt – dort `rosenpass_permissive` einschalten (bis 2026-10-31 gehört Rosenpass dort ganz aus) |
| NetBird getrennt | Menüleisten-App → Connect; `netbird status -d`; Daemon: `sudo launchctl print system/netbird` |

## Inventar

`inventory.json` führt jede Maschine des Labs, ob dieser Flake sie konfiguriert oder nicht: was für ein Gerät es ist (Hersteller, Modell, Seriennummer), wo es steht, wie dieser Ort ans Internet kommt, worauf es läuft oder worin es steckt, woher es Strom bekommt, wie seine Platte nach einem Reboot entsperrt wird, seine Netze, Interfaces und Adressen und seine SSH-Host-Keys. Dazu kommen die Dienste, die darauf laufen oder von außen eingekauft sind, was jeder Dienst braucht, wohin seine Daten gesichert werden, und die Anbieter und Verträge hinter Hosts, Anschlüssen und Diensten. Das sind die Angaben, die in keiner NixOS-Config stehen. Genutzt werden heute die Host-Keys: Die known_hosts jedes Hosts kommt von hier, und `nix flake check` gleicht sie mit den age-Schlüsseln in `.sops.yaml` ab. Der Rest soll später der Gruppierung in der Topologie und den Abhängigkeiten im Alerting dienen (der Uplink ist weg, also nicht für jeden Host dahinter alarmieren).

Was heute drinsteht, zeigt die [Lagekarte](#lagekarte): jeder Host und jeder Dienst nach Standort, mit klickbaren Abhängigkeiten.

| Datei | Aufgabe |
| --- | --- |
| `inventory.json` | Die Daten. JSON, damit Nix (`builtins.fromJSON`) und OpenTofu (`jsondecode`) sie beide ohne Umweg lesen. |
| `inventory.nix` | Format (`spec`), Validierung, abgeleitete Sicht, Generator für das JSON-Schema. In `flake.nix` als `lib.inventory`. |
| `inventory.schema.json` | JSON-Schema für den Editor (Vervollständigung, Hover-Hilfe, Fehler direkt im Text). Generiert, nie von Hand ändern. |
| `tests/inventory.nix` | Tests für die Validierung: ein vollständiges Beispielinventar und ein Fall je Regel. |
| `software.nix` | Was die Dienste betreiben, gelesen aus den Host-Konfigurationen (`lib.software`, `just services`). |
| `flake.nix` | `lib.inventory`, die Checks und `programs.ssh.knownHosts` für jeden Host (NixOS und nix-darwin). |

Faustregel für den Inhalt: **nur, was sich nicht aus einer Config ableiten lässt.** OS, Architektur, CPU/RAM, Mesh-Adresse und Exporter bleiben draußen; die liest `topology.nix` aus `nixosConfigurations`. Version, Lizenz und Sprache eines Dienstes kommen aus seinem Paket und werden nicht eingetragen. Was ein Dienst *braucht* und wohin seine Daten *gehören*, ist Absicht und keine Config – das steht hier drin (`dependsOn`, `backup`). Jede Beziehung steht **nur in einer Richtung** drin; die Gegenrichtung wird abgeleitet, damit beide nicht auseinanderlaufen können.

### Aufbau

Acht Abschnitte, jeder ein Objekt aus Einträgen mit ID als Schlüssel. IDs bestehen aus Kleinbuchstaben, Ziffern und Bindestrichen (unverändert als Graphviz-Knoten oder Label verwendbar).

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

Ein Schlüssel `"$schema": "./inventory.schema.json"` ganz oben ist erlaubt und wird ignoriert; er sagt dem Editor, wo das Schema liegt.

#### owners

Wer ein Gerät administriert: entscheidet, wen man anruft und was man ändern darf.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → owners](#owners-1).

#### uplinks

Ein Internetanschluss. Mehrere Sites können sich einen teilen (selten), eine Site kann mehrere haben (primär und Backup).

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → uplinks](#uplinks-1).

Alle Felder sind optional, damit ein Anschluss schon eingetragen werden kann, bevor die Details bekannt sind.

#### sites

Ein Ort, an dem Geräte stehen.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → sites](#sites-1).

#### hosts

Jedes Gerät mit einer Adresse, auf die es ankommt: Server, VMs, Router, APs, KVMs, PDUs, Appliances.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → hosts](#hosts-2).

##### Gerätearten

| Art | Für |
| --- | --- |
| `server` | Physische Maschine mit Diensten |
| `hypervisor` | Physische Maschine, die VMs/Container für andere betreibt |
| `vm`, `container` | Virtuell; die einzigen Arten, die `runsOn` haben dürfen |
| `router`, `switch`, `ap` | Netz (`ap` = WLAN-Access-Point) |
| `pdu`, `ups` | Strom |
| `kvm` | IP-KVM, extern oder als Karte im Host; die einzige Art, die `manages` haben darf |
| `nas`, `workstation`, `laptop` | Wie benannt |
| `phone`, `tablet`, `watch` | Mobilgeräte: iPhone, iPad, Apple Watch; meist mit `availability: intermittent` |
| `appliance` | Alles andere mit Adresse: Apple TV, Drucker, … |

Ob ein Host virtuell ist, folgt aus `kind` (`vm`, `container`) – nicht aus `runsOn`. Eine gemietete VM ist eine `vm` ohne `runsOn`: Der Hypervisor des Anbieters steht nicht im Inventar.

#### networks

Ein Layer-2-Netz mit seinem IPv4-Präfix: das Heimnetz, ein VLAN im Hackerspace.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → networks](#networks-1).

Ein Netz ohne Interface ist erlaubt – es kann vor seinen Geräten eingetragen werden.

#### providers

Eine Firma oder ein Verein, von dem das Lab abhängt: Provider, Hoster, ein von außen eingekaufter Dienst, der Hackerspace.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → providers](#providers-1).

#### contracts

Was an einen Anbieter bezahlt wird. Ein Anbieter kann mehrere haben – zwei VMs und eine Zusatz-IPv4 beim selben Hoster sind drei Verträge. Hosts, Anschlüsse und Dienste nennen ihre Verträge (`contracts: [...]`); was ein Vertrag abdeckt, wird abgeleitet.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → contracts](#contracts-1). Die Kosten stehen in ganzen Cent pro Monat, pro Jahr – mit dem Monat, in dem abgebucht wird – oder einmalig, in ihrer eigenen Währung; Summen werden je Währung geführt und nie umgerechnet.

Kunden- und Vertragsnummern gehören **nicht** in `inventory.json`: Sie stehen in `inventory.secrets.yaml` (sops, Workstation- und Admin-Schlüssel), mit der Vertrags-ID als Schlüssel. Nichts liest diese Datei automatisch.

```yaml
realtox-grammi:
  customer: "…"
  contract: "…"
```

#### services

Was die Hosts betreiben und was von außen eingekauft ist. Die Grundausstattung jedes Hosts (sshd, Exporter, vmagent, Vector, CrowdSec, Mesh-Client) ist hier kein Dienst – sie ist überall gleich und steht in den Modulen.

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → services](#services-1).

**Abhängigkeiten.** `dependsOn` und jedes `via` sind die harten: Zusammen müssen sie zyklenfrei sein, und ein Dienst darf nicht hart von einem weniger kritischen abhängen (ein `core`-Dienst von einem `lab`-Dienst) – entweder den anderen hochstufen oder nach `uses` verschieben. `uses` gehört nicht zur Kette: Ist Pocket ID weg, hält NetBird seine Tunnel und lehnt nur neue Logins ab.

**Backups.** Eine Kopie gilt als *außer Haus*, wenn ihr Ziel auf keinem der eigenen Hosts des Dienstes läuft oder ein Dienst von außen ist. Ein `stateful`-Dienst auf Hosts ohne Kopie außer Haus ist kein Fehler, steht aber unter `gaps` – lokale Snapshots auf derselben Platte sind kein Backup.

### Interfaces

`hosts.<id>.interfaces` ordnet Interface-Namen ihre Daten zu. Der Name ist der des Betriebssystems (`eno1`, `wlp2s0f0`, `en0`); bei einer Appliance ein beliebiges Label (`lan`, `wan`). Ein VLAN-Interface auf einem Trunk (`eno1.20`) ist ein eigener Eintrag; seine VLAN-ID kommt aus seinem Netz.

```json
"interfaces": {
  "eno1":    { "mac": "52:54:00:12:34:56", "medium": "ethernet", "linkLocal": "eui64",
               "network": "lan", "ipv4": { "mode": "reserved", "address": "192.0.2.10" } },
  "eno1.20": { "network": "iot", "linkLocal": "fe80::1234", "ipv4": { "mode": "dhcp" } }
}
```

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → hosts](#hosts-2).

**Link-Local.** Nur bei EUI-64 folgt die Adresse aus der MAC (`fe80::` + MAC mit umgedrehtem U/L-Bit und `ff:fe` in der Mitte); das abgeleitete `ipv6LinkLocal` wird dann berechnet. Viele Systeme nutzen stattdessen `stable-privacy` (RFC 7217: stabil, aber nicht berechenbar), auch macOS und tvOS leiten sie nicht aus der MAC ab. Ist die Adresse stabil und bekannt, trägt man sie direkt ein (`"fe80::…"`); genau das macht `just inventory-collect`, wenn sie nicht zu EUI-64 passt. `eui64` braucht eine `mac`; mit einer *lokal verwalteten* WLAN-MAC (private WLAN-Adresse) ist es ein Fehler, weil diese MAC – und damit die Adresse – meist zufällig ist. Eine lokal verwaltete Ethernet-MAC ist in Ordnung (QEMUs `52:54:00:…` ist eine).

**IPv4 – `ipv4.mode`:**

| Modus | Bedeutung | Regeln |
| --- | --- | --- |
| `reserved` | Feste DHCP-Lease per MAC (Reservierung auf dem `dhcpServer`) | `address` und `mac` Pflicht; das Netz braucht einen `dhcpServer`. MAC noch nicht nachgeschlagen: der Platzhalter `aa:bb:cc:dd:ee:ff` – wird nie weitergegeben (`mac` in der abgeleiteten Sicht null, nicht in `reservations`), steht unter `pending` |
| `static` | Auf dem Gerät selbst eingetragen | `address` Pflicht; außerhalb des `dhcpPool` |
| `dhcp` | Dynamisch | keine `address` |

Jede `address` liegt im `ipv4`-Präfix des Netzes, ist weder Netz- noch Broadcast-Adresse (außer bei /31, /32) und kommt je Netz nur einmal vor. Ein Netz ohne `ipv4` kann keine Adressen aufnehmen.

**IPv6** steht hier nur als Link-Local und als festes Präfix je Netz: DHCPv6-Reservierungen hängen an der DUID, nicht an der MAC, und ein Provider-Präfix (SLAAC) wechselt.

### SSH-Host-Keys

`sshHostKeys` enthält die öffentlichen Host-Keys eines Geräts – verwaltet oder nicht – als `"<typ> <base64>"` ohne Kommentar: `ssh-ed25519`, `ecdsa-sha2-nistp256/384/521` oder `ssh-rsa`. Ein ed25519-Key genügt; andere nur, wenn das Gerät kein ed25519 hat (Dropbear, KVMs). Geprüft wird das Format, ob die Key-Daten zum Typ passen (das Base64 beginnt mit dem kodierten Typnamen) und dass kein Key doppelt vorkommt – so fiele eine geklonte VM auf, die ihren Host-Key behalten hat.

Wohin sie gehen:

| Abnehmer | Wie |
| --- | --- |
| Jeder NixOS-Host und zorlock | `programs.ssh.knownHosts` aus `lib.inventory.knownHosts` (in `flake.nix` das Modul `inventoryKnownHosts` in jeder Host-Liste). Deploys und ursalias unbeaufsichtigter Push nach cuckoosegg brauchen kein Trust-on-first-use |
| gusto (Workstation) | `programs.ssh.knownHosts` wie jeder Host – `/etc/ssh/ssh_known_hosts` nach dem nächsten `just mac-switch` |
| Eine Workstation außerhalb dieses Repos | `just known-hosts` schreibt `~/.ssh/known_hosts.nixlab`; ssh liest sie mit `UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts.nixlab` unter `Host *` in `~/.ssh/config` |
| `.sops.yaml` | `checks.inventory-sops`: Für jeden verwalteten Host muss `ssh-to-age` seines ed25519-Keys den age-Empfänger `&<host>` in `.sops.yaml` ergeben. Fängt einen Host-Key, der sich ohne `sops updatekeys` geändert hat (Neuinstallation, Rotation), und einen vertippten Key. Hosts ohne Key werden übersprungen |

Namen je Key: die ID des Hosts, bei verwalteten Hosts `<host>.peer.homelab.example` (der Mesh-Name) und jede feste IPv4-Adresse seiner Interfaces (`static`/`reserved`). Ein Eintrag je Key, benannt `<host>` bzw. `<host>-<n>` bei mehreren Keys.

### Von den Geräten einsammeln

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

### Beziehungen

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

### Entsperren

```json
"unlock": { "methods": ["tpm", "nbde"], "threshold": 1, "tang": ["nas"], "fallback": "remote-ssh" }
```

Alle Felder mit Typ, Standardwert und Bedeutung: [Inventar-Schema → hosts](#hosts-2).

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

### Prüfung

`nix flake check` (oder nur der Inventar-Teil: `just inventory-test`) prüft in drei Stufen. Jede Stufe läuft nur, wenn die vorige nichts gefunden hat, damit aus einem Tippfehler keine zwanzig Folgefehler werden. Jeder Fehler nennt den Pfad:

**1. Struktur** – zuerst die oberste Ebene, allein, dann jeder Eintrag:

- oben nur `$schema` und die acht Abschnitte, alle vorhanden
- gültige IDs und Interface-Namen, keine unbekannten Felder (fängt Tippfehler), Pflichtfelder vorhanden
- Typen, Enums, Mindest-/Höchstwerte, Formate (MAC, IPv4-Adresse und -Präfix, IPv6-Präfix, Link-Local, SSH-Key), keine Duplikate in Listen
- Referenzen zeigen auf einen vorhandenen Eintrag des richtigen Abschnitts

```
hosts.vps.critcality: unknown field (known: availability, contracts, criticality, inside, interfaces, kind, managed, manages, model, note, owner, power, productId, runsOn, serial, site, sshHostKeys, unlock, vendor)
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
- Dienste: genau eins von `hosts`/`provider`; `package` nur auf verwalteten Hosts und nicht zusammen mit `version`; kein `core`/`service`-Dienst auf einem `intermittent`-Host; kein Verweis auf sich selbst, nichts zugleich in `dependsOn` und `uses`, keine harte Abhängigkeit von einem weniger kritischen Dienst; `dependsOn`/`via` zyklenfrei; `via` bei `proxy`, nicht bei `loopback`; jeder `fqdn` nur einmal je Port; `backup` nur bei `stateful`, `to` Pflicht bei `restic`/`arq`, optional bei `ha-backup`, sonst nicht, und auf ein `stateful`-Ziel; `contracts` nur mit `provider`
- Verträge: `dueMonth` genau bei `year`; `renews` nicht vor `since`; ein Vertrag, den ein Host, Anschluss oder Dienst nennt, ist mit dessen Anbieter geschlossen (bei einem Host: dem Anbieter seiner Site); kein Anbieter, auf den nichts verweist

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

**3. Entsperr-Ketten** – siehe [Entsperren](#entsperren):

```
hosts.nas.unlock: never unlocks unattended - none of its Tang servers (vps) comes up without a human
```

**Getrennt davon**, als eigener Check, weil er `ssh-to-age` braucht: `checks.inventory-sops` (siehe [SSH-Host-Keys](#ssh-host-keys)).

```
hosts.cuckoosegg: host key gives age1z9rt…, .sops.yaml has age1z8uz… - host key changed without sops updatekeys, or a wrong key in inventory.json
```

Das Schema in `inventory.schema.json` deckt nur Stufe 1 ab (ohne Referenzen) und ist für den Editor da; maßgeblich ist die Prüfung in `inventory.nix`. Die Fehlermeldungen sind wie der Code englisch.

### Abgeleitete Sicht

`lib.inventory.inventory` (auf der Konsole: `just inventory`) ist das geprüfte Inventar mit allem Abgeleiteten. Jeder Eintrag bekommt seine `id`, dazu:

| Abschnitt | Abgeleitet |
| --- | --- |
| `owners.<id>` | `hosts` – die Hosts, die er administriert |
| `uplinks.<id>` | `sites` – die Sites an diesem Anschluss |
| `sites.<id>` | `hosts` – alles dort, geerbte Sites eingeschlossen |
| `hosts.<id>` | `site` (wirksam, geerbt entlang `runsOn`/`inside`), `virtual`, `uplinks` (seiner Site, primärer zuerst), `guests`, `contains`, `powers`, `managedBy`, `tangClients`, `upstream` (transitiv, nächster zuerst), `unattendedBoot`, `services` (die darauf laufen) |
| `hosts.<id>.interfaces.<name>` | `name`, `vlan` (aus seinem Netz), `ipv6LinkLocal` (bei `eui64` berechnet, bei fester Adresse wie eingetragen, sonst `null`) |
| `pending` | jede Platzhalter-MAC, die noch ersetzt werden muss, jeder Vertrag ohne `cost`; `just inventory-test` gibt die Liste aus |
| `gaps` | erlaubt, aber einen Blick wert: `stateful`-Dienste ohne Backup außer Haus, Verträge, auf die nichts verweist; gibt `just inventory-test` aus |
| `services.<id>` | `external` (hat einen `provider`), `sites` (seiner Hosts), `requires` (`dependsOn` + `via`), `upstream` (transitiv über `requires`, nächster zuerst), `upstreamHosts` (seine Hosts, die seines Upstreams und alles, worauf diese laufen, worin sie stecken, woher sie Strom bekommen – die Grundlage für Alert-Abhängigkeiten), `neededBy`, `usedBy`, `backup[].offsite`, `offsiteBackup` |
| `providers.<id>` | `services`, `contracts`, `sites`, `uplinks`, `affects` (was mit ihm ausfällt: Dienste auf Hosts an einer Site, die er betreibt, oder hinter Anschlüssen, die alle seine sind, und alles, was hart von diesen oder seinen eigenen Diensten abhängt), `degrades` (Dienste, die sie oder deren Abhängige nur über `uses` nutzen), `monthly` (je Währung) |
| `contracts.<id>` | `monthly` (Jahresbetrag durch 12, auf den Cent abgerundet; `null` bei `once` oder ohne Kosten), `covers` (`hosts`, `uplinks`, `services`, die ihn nennen) |
| `costs` | `monthly` – das Lab pro Monat, je Währung; `byMonth` – zwölf Einträge, was in welchem Kalendermonat abgebucht wird (Monatsbeträge jeden Monat, Jahresbeträge in ihrem `dueMonth`). Einmalzahlungen bleiben draußen |
| `networks.<id>` | `interfaces` – jedes Interface darin (`host`, `interface`, `mac`, `address`, `mode`); `reservations` – was der `dhcpServer` per MAC vergeben muss (`host`, `interface`, `mac`, `address`), nach Adresse sortiert |

Neben `inventory`: `lib.inventory.knownHosts` (der Wert für `programs.ssh.knownHosts`) und `lib.inventory.knownHostsFile` (dasselbe als known_hosts-Text).

Optionale Felder sind in der abgeleiteten Sicht immer vorhanden: Standardwerte eingesetzt (`criticality`, `availability`, `unlock.threshold`), sonst `null` bzw. `[]`. Wer sie nutzt, braucht nie ein `or`.

Ist das Inventar ungültig, wirft `inventory` mit **allen** Fehlern auf einmal; `lib.inventory.errors` ist die Liste selbst (leer, wenn gültig).

### Software-Sicht

`lib.software.services` (auf der Konsole: `just services`, alles mit `just services --json`) folgt dem `package`-Pfad jedes Dienstes in die Konfigurationen seiner Hosts und meldet, was dort ist – nichts wird eingetragen, nichts gebaut:

| Feld | Bedeutung |
| --- | --- |
| `name`, `version` | Des Pakets (vom ersten Host; `perHost` hat jeden Host) |
| `license` | SPDX-IDs aus `meta.license` |
| `language` | Geschätzt aus dem Bauweg: `goModules` → Go, `cargoDeps` → Rust, die Caches der JS-Builder → JavaScript, ein `dist`-Output → Python, ein C-Compiler im stdenv → C/C++ (`languageGuessed` true), sonst `null` (eine statische Seite) |
| `dependencies` | Direkte Abhängigkeiten, wie das Paket sie angibt (`name`, `version`): Python-Pakete einer Python-Anwendung, Bibliotheken eines C/C++-Programms. Go- und Rust-Module werden in einem Stück geladen und tauchen nicht auf – die SBOM pro Host hat den vollständigen Closure |
| `perHost` | Dasselbe pro Host, ohne Abhängigkeiten – Hosts auf unterschiedlichen Pins unterscheiden sich hier |

`checks.inventory-packages` schlägt fehl, wenn ein `package`-Pfad auf einem der Hosts des Dienstes zu keinem Paket führt (umbenannte Option, Host hat den Dienst verloren). Anders als die übrigen Inventar-Checks wertet er die Hosts aus und gehört deshalb nicht zu `just inventory-test`.

**SBOM pro Host.** `just sbom [host …]` (ohne Hosts: jeder verwaltete Host) schreibt den vollständigen Laufzeit-Closure dessen, was ein Host betreibt – `/run/current-system` – als CycloneDX (`sbom/<host>.cdx.json`), SPDX und CSV, erzeugt von sbomnix. Es läuft dort, wo das System ist: auf gusto selbst, auf den anderen über das Mesh, gepinnt auf das eigene nixpkgs des Hosts (der erste Lauf holt es dort, etwa 180 MB, bis zur nächsten GC); ein Linux-System lässt sich auf dem Mac nicht lesen. `sbom/` ist von git ignoriert – die Dateien ändern sich mit jedem Upgrade. Nicht enthalten: nixpkgs-Metadaten wie Lizenzen (die hat sbomnix nur bei einem Flake-Verweis, nicht bei einem laufenden System – die Lizenzen der Dienste stehen in der Software-Sicht) und die Go- und Rust-Module innerhalb eines Pakets.

### Beispiele

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
  "fiber-home": { "provider": "isp", "contracts": ["isp-fiber"], "asn": 64496, "medium": "fiber",
                  "bandwidth": { "down": 1000, "up": 500 }, "ipv4": "cgnat", "ipv6": true },
  "lte-backup": { "medium": "lte" }
},
"sites": {
  "home": { "city": "Exampletown", "kind": "residential", "uplinks": ["fiber-home", "lte-backup"] }
}
```

**Ein Anbieter mit zwei Verträgen an einer VM, der jährliche im März fällig:**

```json
"providers": { "hoster": { "name": "Example Hosting", "url": "https://hosting.example" } },
"contracts": {
  "vps-plan": { "provider": "hoster", "product": "VPS M", "since": "2025-03-01", "renews": "2027-03-01",
                "cost": { "amount": 12000, "currency": "EUR", "period": "year", "dueMonth": 3 } },
  "vps-ipv4": { "provider": "hoster", "cost": { "amount": 150, "currency": "EUR", "period": "month" } }
},
"vps": { "kind": "vm", "site": "dc", "contracts": ["vps-plan", "vps-ipv4"], … }
```

Abgeleitet: `contracts.vps-plan.monthly` = `1000`, `providers.hoster.monthly` = `{"EUR": 1150}`; in `costs.byMonth` trägt der März die 120,00.

**Dienste: ein Login, ein Reverse-Proxy, etwas dahinter, ein Backup-Ziel und Mail von außen:**

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

Abgeleitet: `docs.upstreamHosts` = `app, nas, pve, ups1, vps`; `auth.neededBy` = `notes`, `auth.usedBy` = `docs`; `providers.mail.degrades` = `auth`; `gaps` nennt `storage` (nur btrbk auf der eigenen Platte).

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

### Tests

`tests/inventory.nix` enthält ein vollständiges, erfundenes Inventar (die Beispiele oben) und 94 Fälle. Jeder Fall ändert genau eine Sache und nennt die erwarteten Fehler – exakter Wortlaut und Reihenfolge – oder, bei gültigen Varianten, Werte der abgeleiteten Sicht. Ein Fall schlägt auch fehl, wenn ein kaputtes Inventar `.inventory` nicht werfen lässt.

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
| Dienste | Weder/beides von `hosts` und `provider`, leere `hosts`, `package` mit `version`/ohne Hosts/auf nicht verwaltetem Host, kritischer Dienst auf einem zeitweise erreichbaren Host (ein `lab`-Dienst erlaubt), Selbstverweise, `uses` doppelt zu `dependsOn`, schwächere harte Abhängigkeit, Zyklen über `dependsOn` und `via`, Endpoint-Regeln und doppelte Namen, Domain-Format, alle Backup-Regeln; abgeleitete Abhängigkeiten, Upstream-Hosts, Backups außer Haus, `gaps` |
| Anbieter, Verträge | Vertrag mit falschem Anbieter an Host, Anschluss und Dienst, an einem Anschluss ohne Anbieter, an einem Dienst auf Hosts; `dueMonth`, `renews` vor `since`, Betrag nicht in ganzen Cent, Datumsformat; ungenutzter und unbekannter Anbieter; abgeleitete Summen je Währung und Monat, `pending` bei fehlenden Kosten |

```
just inventory-test
```

baut `checks.<system>.inventory` (die echte Datei ist gültig), `inventory-tests` (alle Fälle bestehen), `inventory-schema` (Schema aktuell), `inventory-diagram` (das [Schema-Diagramm](#alle-felder-auf-einen-blick) aktuell) und `inventory-sops` (Host-Keys ↔ `.sops.yaml`). Bei einem Fehler listet die Meldung jeden fehlgeschlagenen Fall mit „want“ und „got“.

**Eine neue Regel** bekommt im selben Commit einen Fall: in `base` mit `set`/`del` genau eine Sache ändern, die exakte Meldung eintragen. **Geänderter Wortlaut** einer Meldung lässt die Tests fehlschlagen – Fall und diese Seite zusammen anpassen.

### Abläufe

| Was | Schritte |
| --- | --- |
| Neuer Host / neues Gerät | Eintrag in `inventory.json` (bei einem Flake-Host `"managed": true` – sonst schlägt `nix flake check` ohnehin fehl), `just inventory-collect`, `network`/`ipv4` von Hand, `just inventory-test` |
| Host-Key geändert (Neuinstallation) | `just inventory-collect --force <host>`, `.sops.yaml` + `sops updatekeys` (siehe [Schlüssel rotieren](#schlüssel-rotieren)), deployen, `just known-hosts` |
| Neue DHCP-Reservierung | Interface mit `mac`, `network`, `ipv4.mode: reserved` + `address`; die Liste für den Router: `networks.<id>.reservations` in `just inventory` |
| Details eines Anschlusses nachtragen | Felder in `uplinks.<id>`, sonst nichts zu tun |
| Neuer Dienst | Eintrag in `services` mit `hosts` (und `package` auf verwaltetem Host) oder `provider`, `endpoints`, `dependsOn`/`uses`, `data`, `backup`; `just inventory-test` – ein fehlendes Backup außer Haus erscheint unter „worth a look“ |
| Neuer Vertrag | Eintrag in `contracts`, die ID in `contracts` des Hosts, Anschlusses oder Dienstes, den er bezahlt; Kunden-/Vertragsnummer in `inventory.secrets.yaml` (`sops inventory.secrets.yaml`) |
| Neues Feld oder neue Geräteart | `spec` in `inventory.nix`, dann `just inventory-schema` und `just inventory-diagram`, ein Testfall in `tests/inventory.nix`, diese Seite (de/en); `docs/inventory-example.json`, wenn das Beispiel der [Schema-Seite](#inventar-schema) es zeigen soll |
| Ansehen | `just inventory` |

## Inventar-Schema

`inventory.json` folgt einem festen Format: acht Abschnitte, jeder ein Objekt aus Einträgen mit ID als Schlüssel, jedes Feld mit einem Typ, manche davon Verweise in einen anderen Abschnitt. Diese Seite ist die vollständige Referenz dieses Formats – jedes Feld mit Typ, ob es Pflicht ist, seinem Standardwert und seiner Bedeutung, ein Beispiel pro Abschnitt und ein ganzes Beispiel-Inventar. *Wozu* das Inventar da ist, wie es geprüft wird und was daraus abgeleitet wird, steht unter [Inventar](#inventar).

Das Format ist an genau einer Stelle definiert, in `spec` in `inventory.nix`. Alles auf dieser Seite, was ein Feld beschreibt, wird daraus erzeugt und kann deshalb nicht von dem abweichen, was die Prüfung tatsächlich prüft:

| Erzeugt | Aus | Aktuell gehalten durch |
| --- | --- | --- |
| `inventory.schema.json` – JSON Schema für den Editor | `spec` | `just inventory-schema`, `checks.inventory-schema` |
| Die Feldtabellen unten | `inventory.schema.json` | den Doku-Build (`docs/gen-reference.py`) |
| Das Diagramm aller Felder | `spec` | `just inventory-diagram`, `checks.inventory-diagram` |
| Die Beispiele unten | `docs/inventory-example.json` | den Doku-Build; ein Test (`tests/inventory.nix`) hält die Datei gültig |

Die Feldbeschreibungen in den Tabellen sind englisch – sie stehen so im Schema und erscheinen genauso als Hover-Hilfe im Editor.

### Überblick

Die Pfeile zeigen von dem Feld, das den Verweis enthält, auf den Abschnitt, den es nennt. Verweise eines Abschnitts auf sich selbst stehen in seinem Kasten (↺). Jeder Kasten führt zu seinem Abschnitt weiter unten.

<figure class="nx-diagram">
<svg viewBox="0 0 680 416" role="img" aria-label="Die acht Abschnitte von inventory.json und die Felder, die von einem auf einen anderen verweisen" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-purple rect{fill:#eeedfe;stroke:#534ab7}.nx-purple .nx-t{fill:#26215c}.nx-purple .nx-s{fill:#534ab7}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}</style>
<path class="nx-line" d="M260 48 H180"/><path class="nx-line" d="M186 44 L180 48 L186 52"/>
<text class="nx-s" x="220" y="42" text-anchor="middle">owner</text>
<path class="nx-line" d="M500 40 H420"/><path class="nx-line" d="M426 36 L420 40 L426 44"/>
<text class="nx-s" x="460" y="34" text-anchor="middle">hosts[]</text>
<path class="nx-line" d="M420 66 H450 V198 H500"/><path class="nx-line" d="M494 194 L500 198 L494 202"/>
<text class="nx-s" x="456" y="130" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M340 76 V170"/><path class="nx-line" d="M336 164 L340 170 L344 164"/>
<text class="nx-s" x="346" y="128" text-anchor="start">site</text>
<path class="nx-line" d="M290 76 V130 H120 V170"/><path class="nx-line" d="M116 164 L120 170 L124 164"/>
<text class="nx-s" x="205" y="147" text-anchor="middle">interfaces.*.network</text>
<path class="nx-line" d="M80 170 V110 H275 V76"/><path class="nx-line" d="M271 82 L275 76 L279 82"/>
<text class="nx-s" x="178" y="104" text-anchor="middle">dhcpServer</text>
<path class="nx-line" d="M180 198 H260"/><path class="nx-line" d="M254 194 L260 198 L254 202"/>
<text class="nx-s" x="220" y="192" text-anchor="middle">site</text>
<path class="nx-line" d="M300 226 V270 H100 V320"/><path class="nx-line" d="M96 314 L100 320 L104 314"/>
<text class="nx-s" x="200" y="264" text-anchor="middle">uplinks[]</text>
<path class="nx-line" d="M340 226 V320"/><path class="nx-line" d="M336 314 L340 320 L344 314"/>
<text class="nx-s" x="346" y="290" text-anchor="start">provider</text>
<path class="nx-line" d="M180 348 H260"/><path class="nx-line" d="M254 344 L260 348 L254 352"/>
<text class="nx-s" x="220" y="342" text-anchor="middle">provider</text>
<path class="nx-line" d="M580 226 V348 H420"/><path class="nx-line" d="M426 344 L420 348 L426 352"/>
<text class="nx-s" x="574" y="290" text-anchor="end">provider</text>
<path class="nx-line" d="M560 76 V170"/><path class="nx-line" d="M556 164 L560 170 L564 164"/>
<text class="nx-s" x="566" y="128" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M660 48 H670 V364 H420"/><path class="nx-line" d="M426 360 L420 364 L426 368"/>
<text class="nx-s" x="540" y="380" text-anchor="middle">provider</text>
<path class="nx-line" d="M100 376 V400 H610 V226"/><path class="nx-line" d="M606 232 L610 226 L614 232"/>
<text class="nx-s" x="360" y="395" text-anchor="middle">contracts[]</text>
<a data-target="owners" tabindex="0" role="link" class="nx-gray"><rect x="20" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="44" text-anchor="middle">owners</text><text class="nx-s" x="100" y="62" text-anchor="middle">wer administriert</text></a>
<a data-target="hosts" tabindex="0" role="link" class="nx-gray"><rect x="260" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="44" text-anchor="middle">hosts</text><text class="nx-s" x="340" y="62" text-anchor="middle">↺ runsOn, power …</text></a>
<a data-target="services" tabindex="0" role="link" class="nx-purple"><rect x="500" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="44" text-anchor="middle">services</text><text class="nx-s" x="580" y="62" text-anchor="middle">↺ dependsOn, uses …</text></a>
<a data-target="networks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="194" text-anchor="middle">networks</text><text class="nx-s" x="100" y="212" text-anchor="middle">Layer 2 + Präfix</text></a>
<a data-target="sites" tabindex="0" role="link" class="nx-gray"><rect x="260" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="194" text-anchor="middle">sites</text><text class="nx-s" x="340" y="212" text-anchor="middle">wo etwas steht</text></a>
<a data-target="contracts" tabindex="0" role="link" class="nx-coral"><rect x="500" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="194" text-anchor="middle">contracts</text><text class="nx-s" x="580" y="212" text-anchor="middle">was bezahlt wird</text></a>
<a data-target="uplinks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="344" text-anchor="middle">uplinks</text><text class="nx-s" x="100" y="362" text-anchor="middle">Internetanschlüsse</text></a>
<a data-target="providers" tabindex="0" role="link" class="nx-coral"><rect x="260" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="344" text-anchor="middle">providers</text><text class="nx-s" x="340" y="362" text-anchor="middle">Firmen, Vereine</text></a>
</svg>
</figure>

### Alle Felder auf einen Blick

Jeder Abschnitt mit allen Feldern – **fett** sind Pflichtfelder, verschachtelte Objekte ausgeschrieben (`unlock.methods`, `endpoints[].fqdn`, `interfaces.<name>.mac`), und jedes Verweisfeld hat seinen Pfeil (Verweise innerhalb eines Abschnitts nur in der Typspalte: `→ hosts`).

<figure class="nx-diagram nx-diagram-wide">
<svg
 viewBox="0.00 0.00 1372.50 978.81" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 974.81)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1227.25,-645.06 1094.25,-645.06 1094.25,-412.56 1227.25,-412.56 1227.25,-645.06"/>
<polygon fill="#f1efe8" stroke="none" points="1094.25,-412.56 1094.25,-645.06 1227.25,-645.06 1227.25,-412.56 1094.25,-412.56"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1094.25,-625.81 1094.25,-645.06 1227.25,-645.06 1227.25,-625.81 1094.25,-625.81"/>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-625.81 1094.25,-645.06 1227.25,-645.06 1227.25,-625.81 1094.25,-625.81"/>
<text text-anchor="start" x="1139.38" y="-632.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-606.56 1094.25,-625.81 1166.75,-625.81 1166.75,-606.56 1094.25,-606.56"/>
<text text-anchor="start" x="1098.25" y="-612.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-606.56 1166.75,-625.81 1227.25,-625.81 1227.25,-606.56 1166.75,-606.56"/>
<text text-anchor="start" x="1170.75" y="-612.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-587.31 1094.25,-606.56 1166.75,-606.56 1166.75,-587.31 1094.25,-587.31"/>
<text text-anchor="start" x="1098.25" y="-594.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-587.31 1166.75,-606.56 1227.25,-606.56 1227.25,-587.31 1166.75,-587.31"/>
<text text-anchor="start" x="1170.75" y="-593.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-568.06 1094.25,-587.31 1166.75,-587.31 1166.75,-568.06 1094.25,-568.06"/>
<text text-anchor="start" x="1098.25" y="-574.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-568.06 1166.75,-587.31 1227.25,-587.31 1227.25,-568.06 1166.75,-568.06"/>
<text text-anchor="start" x="1170.75" y="-573.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-548.81 1094.25,-568.06 1166.75,-568.06 1166.75,-548.81 1094.25,-548.81"/>
<text text-anchor="start" x="1098.25" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-548.81 1166.75,-568.06 1227.25,-568.06 1227.25,-548.81 1166.75,-548.81"/>
<text text-anchor="start" x="1170.75" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-529.56 1094.25,-548.81 1166.75,-548.81 1166.75,-529.56 1094.25,-529.56"/>
<text text-anchor="start" x="1098.25" y="-536.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-529.56 1166.75,-548.81 1227.25,-548.81 1227.25,-529.56 1166.75,-529.56"/>
<text text-anchor="start" x="1170.75" y="-535.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-510.31 1094.25,-529.56 1166.75,-529.56 1166.75,-510.31 1094.25,-510.31"/>
<text text-anchor="start" x="1098.25" y="-516.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-510.31 1166.75,-529.56 1227.25,-529.56 1227.25,-510.31 1166.75,-510.31"/>
<text text-anchor="start" x="1170.75" y="-516.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-491.06 1094.25,-510.31 1166.75,-510.31 1166.75,-491.06 1094.25,-491.06"/>
<text text-anchor="start" x="1098.25" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-491.06 1166.75,-510.31 1227.25,-510.31 1227.25,-491.06 1166.75,-491.06"/>
<text text-anchor="start" x="1170.75" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-471.81 1094.25,-491.06 1166.75,-491.06 1166.75,-471.81 1094.25,-471.81"/>
<text text-anchor="start" x="1098.25" y="-477.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-471.81 1166.75,-491.06 1227.25,-491.06 1227.25,-471.81 1166.75,-471.81"/>
<text text-anchor="start" x="1170.75" y="-477.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-451.06 1094.25,-471.81 1166.75,-471.81 1166.75,-451.06 1094.25,-451.06"/>
<text text-anchor="start" x="1098.25" y="-458.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-451.06 1166.75,-471.81 1227.25,-471.81 1227.25,-451.06 1166.75,-451.06"/>
<text text-anchor="start" x="1170.75" y="-458.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-431.81 1094.25,-451.06 1166.75,-451.06 1166.75,-431.81 1094.25,-431.81"/>
<text text-anchor="start" x="1098.25" y="-437.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-431.81 1166.75,-451.06 1227.25,-451.06 1227.25,-431.81 1166.75,-431.81"/>
<text text-anchor="start" x="1170.75" y="-437.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-412.56 1094.25,-431.81 1166.75,-431.81 1166.75,-412.56 1094.25,-412.56"/>
<text text-anchor="start" x="1098.25" y="-418.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-412.56 1166.75,-431.81 1227.25,-431.81 1227.25,-412.56 1166.75,-412.56"/>
<text text-anchor="start" x="1170.75" y="-418.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node5" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1364.5,-305.93 1292.25,-305.93 1292.25,-209.68 1364.5,-209.68 1364.5,-305.93"/>
<polygon fill="#f1efe8" stroke="none" points="1292.25,-209.68 1292.25,-305.93 1364.5,-305.93 1364.5,-209.68 1292.25,-209.68"/>
<g id="a_node5_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1292.25,-286.68 1292.25,-305.93 1364.5,-305.93 1364.5,-286.68 1292.25,-286.68"/>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-286.68 1292.25,-305.93 1364.5,-305.93 1364.5,-286.68 1292.25,-286.68"/>
<text text-anchor="start" x="1306.25" y="-293.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node5_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-267.43 1292.25,-286.68 1332.5,-286.68 1332.5,-267.43 1292.25,-267.43"/>
<text text-anchor="start" x="1296.25" y="-273.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-267.43 1332.5,-286.68 1364.5,-286.68 1364.5,-267.43 1332.5,-267.43"/>
<text text-anchor="start" x="1336.5" y="-273.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-248.18 1292.25,-267.43 1332.5,-267.43 1332.5,-248.18 1292.25,-248.18"/>
<text text-anchor="start" x="1296.25" y="-254.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-248.18 1332.5,-267.43 1364.5,-267.43 1364.5,-248.18 1332.5,-248.18"/>
<text text-anchor="start" x="1336.5" y="-253.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-228.93 1292.25,-248.18 1332.5,-248.18 1332.5,-228.93 1292.25,-228.93"/>
<text text-anchor="start" x="1296.25" y="-234.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-228.93 1332.5,-248.18 1364.5,-248.18 1364.5,-228.93 1332.5,-228.93"/>
<text text-anchor="start" x="1336.5" y="-234.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-209.68 1292.25,-228.93 1332.5,-228.93 1332.5,-209.68 1292.25,-209.68"/>
<text text-anchor="start" x="1296.25" y="-215.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node5_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-209.68 1332.5,-228.93 1364.5,-228.93 1364.5,-209.68 1332.5,-209.68"/>
<text text-anchor="start" x="1336.5" y="-215.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1227.25,-461.43C1303.5,-461.43 1219.35,-307.09 1284.95,-296.84"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.76,-298.96 1290.59,-296.43 1284.45,-294.77 1284.76,-298.96"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="457.75,-693.56 239.25,-693.56 239.25,-64.06 457.75,-64.06 457.75,-693.56"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-64.06 239.25,-693.56 457.75,-693.56 457.75,-64.06 239.25,-64.06"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-674.31 239.25,-693.56 457.75,-693.56 457.75,-674.31 239.25,-674.31"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-674.31 239.25,-693.56 457.75,-693.56 457.75,-674.31 239.25,-674.31"/>
<text text-anchor="start" x="335.75" y="-681.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-655.06 239.25,-674.31 387.5,-674.31 387.5,-655.06 239.25,-655.06"/>
<text text-anchor="start" x="243.25" y="-660.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-655.06 387.5,-674.31 457.75,-674.31 457.75,-655.06 387.5,-655.06"/>
<text text-anchor="start" x="391.5" y="-660.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-634.31 239.25,-655.06 387.5,-655.06 387.5,-634.31 239.25,-634.31"/>
<text text-anchor="start" x="243.25" y="-640.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-634.31 387.5,-655.06 457.75,-655.06 457.75,-634.31 387.5,-634.31"/>
<text text-anchor="start" x="391.5" y="-641.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-615.06 239.25,-634.31 387.5,-634.31 387.5,-615.06 239.25,-615.06"/>
<text text-anchor="start" x="243.25" y="-620.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-615.06 387.5,-634.31 457.75,-634.31 457.75,-615.06 387.5,-615.06"/>
<text text-anchor="start" x="391.5" y="-620.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-594.31 239.25,-615.06 387.5,-615.06 387.5,-594.31 239.25,-594.31"/>
<text text-anchor="start" x="243.25" y="-600.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-594.31 387.5,-615.06 457.75,-615.06 457.75,-594.31 387.5,-594.31"/>
<text text-anchor="start" x="391.5" y="-601.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-575.06 239.25,-594.31 387.5,-594.31 387.5,-575.06 239.25,-575.06"/>
<text text-anchor="start" x="243.25" y="-580.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-575.06 387.5,-594.31 457.75,-594.31 457.75,-575.06 387.5,-575.06"/>
<text text-anchor="start" x="391.5" y="-580.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-555.81 239.25,-575.06 387.5,-575.06 387.5,-555.81 239.25,-555.81"/>
<text text-anchor="start" x="243.25" y="-561.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-555.81 387.5,-575.06 457.75,-575.06 457.75,-555.81 387.5,-555.81"/>
<text text-anchor="start" x="391.5" y="-561.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-536.56 239.25,-555.81 387.5,-555.81 387.5,-536.56 239.25,-536.56"/>
<text text-anchor="start" x="243.25" y="-542.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-536.56 387.5,-555.81 457.75,-555.81 457.75,-536.56 387.5,-536.56"/>
<text text-anchor="start" x="391.5" y="-542.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-517.31 239.25,-536.56 387.5,-536.56 387.5,-517.31 239.25,-517.31"/>
<text text-anchor="start" x="243.25" y="-524.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-517.31 387.5,-536.56 457.75,-536.56 457.75,-517.31 387.5,-517.31"/>
<text text-anchor="start" x="391.5" y="-523.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-498.06 239.25,-517.31 387.5,-517.31 387.5,-498.06 239.25,-498.06"/>
<text text-anchor="start" x="243.25" y="-503.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-498.06 387.5,-517.31 457.75,-517.31 457.75,-498.06 387.5,-498.06"/>
<text text-anchor="start" x="391.5" y="-503.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-478.81 239.25,-498.06 387.5,-498.06 387.5,-478.81 239.25,-478.81"/>
<text text-anchor="start" x="243.25" y="-484.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-478.81 387.5,-498.06 457.75,-498.06 457.75,-478.81 387.5,-478.81"/>
<text text-anchor="start" x="391.5" y="-484.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-459.56 239.25,-478.81 387.5,-478.81 387.5,-459.56 239.25,-459.56"/>
<text text-anchor="start" x="243.25" y="-465.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-459.56 387.5,-478.81 457.75,-478.81 457.75,-459.56 387.5,-459.56"/>
<text text-anchor="start" x="391.5" y="-465.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-438.81 239.25,-459.56 387.5,-459.56 387.5,-438.81 239.25,-438.81"/>
<text text-anchor="start" x="243.25" y="-445.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-438.81 387.5,-459.56 457.75,-459.56 457.75,-438.81 387.5,-438.81"/>
<text text-anchor="start" x="391.5" y="-446.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-419.56 239.25,-438.81 387.5,-438.81 387.5,-419.56 239.25,-419.56"/>
<text text-anchor="start" x="243.25" y="-425.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-419.56 387.5,-438.81 457.75,-438.81 457.75,-419.56 387.5,-419.56"/>
<text text-anchor="start" x="391.5" y="-425.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-400.31 239.25,-419.56 387.5,-419.56 387.5,-400.31 239.25,-400.31"/>
<text text-anchor="start" x="243.25" y="-407.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-400.31 387.5,-419.56 457.75,-419.56 457.75,-400.31 387.5,-400.31"/>
<text text-anchor="start" x="391.5" y="-406.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-381.06 239.25,-400.31 387.5,-400.31 387.5,-381.06 239.25,-381.06"/>
<text text-anchor="start" x="243.25" y="-387.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-381.06 387.5,-400.31 457.75,-400.31 457.75,-381.06 387.5,-381.06"/>
<text text-anchor="start" x="391.5" y="-386.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-360.31 239.25,-381.06 387.5,-381.06 387.5,-360.31 239.25,-360.31"/>
<text text-anchor="start" x="243.25" y="-366.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-360.31 387.5,-381.06 457.75,-381.06 457.75,-360.31 387.5,-360.31"/>
<text text-anchor="start" x="391.5" y="-367.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-341.06 239.25,-360.31 387.5,-360.31 387.5,-341.06 239.25,-341.06"/>
<text text-anchor="start" x="243.25" y="-346.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-341.06 387.5,-360.31 457.75,-360.31 457.75,-341.06 387.5,-341.06"/>
<text text-anchor="start" x="391.5" y="-346.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-321.81 239.25,-341.06 387.5,-341.06 387.5,-321.81 239.25,-321.81"/>
<text text-anchor="start" x="243.25" y="-327.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-321.81 387.5,-341.06 457.75,-341.06 457.75,-321.81 387.5,-321.81"/>
<text text-anchor="start" x="391.5" y="-327.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-301.06 239.25,-321.81 387.5,-321.81 387.5,-301.06 239.25,-301.06"/>
<text text-anchor="start" x="243.25" y="-308.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-301.06 387.5,-321.81 457.75,-321.81 457.75,-301.06 387.5,-301.06"/>
<text text-anchor="start" x="391.5" y="-308.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-280.31 239.25,-301.06 387.5,-301.06 387.5,-280.31 239.25,-280.31"/>
<text text-anchor="start" x="243.25" y="-286.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-280.31 387.5,-301.06 457.75,-301.06 457.75,-280.31 387.5,-280.31"/>
<text text-anchor="start" x="391.5" y="-287.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-261.06 239.25,-280.31 387.5,-280.31 387.5,-261.06 239.25,-261.06"/>
<text text-anchor="start" x="243.25" y="-266.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-261.06 387.5,-280.31 457.75,-280.31 457.75,-261.06 387.5,-261.06"/>
<text text-anchor="start" x="391.5" y="-266.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-240.31 239.25,-261.06 387.5,-261.06 387.5,-240.31 239.25,-240.31"/>
<text text-anchor="start" x="243.25" y="-246.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-240.31 387.5,-261.06 457.75,-261.06 457.75,-240.31 387.5,-240.31"/>
<text text-anchor="start" x="391.5" y="-247.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-221.06 239.25,-240.31 387.5,-240.31 387.5,-221.06 239.25,-221.06"/>
<text text-anchor="start" x="243.25" y="-226.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-221.06 387.5,-240.31 457.75,-240.31 457.75,-221.06 387.5,-221.06"/>
<text text-anchor="start" x="391.5" y="-226.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-200.31 239.25,-221.06 387.5,-221.06 387.5,-200.31 239.25,-200.31"/>
<text text-anchor="start" x="243.25" y="-206.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-200.31 387.5,-221.06 457.75,-221.06 457.75,-200.31 387.5,-200.31"/>
<text text-anchor="start" x="391.5" y="-207.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-181.06 239.25,-200.31 387.5,-200.31 387.5,-181.06 239.25,-181.06"/>
<text text-anchor="start" x="243.25" y="-186.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-181.06 387.5,-200.31 457.75,-200.31 457.75,-181.06 387.5,-181.06"/>
<text text-anchor="start" x="391.5" y="-186.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-161.81 239.25,-181.06 387.5,-181.06 387.5,-161.81 239.25,-161.81"/>
<text text-anchor="start" x="243.25" y="-167.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-161.81 387.5,-181.06 457.75,-181.06 457.75,-161.81 387.5,-161.81"/>
<text text-anchor="start" x="391.5" y="-167.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-142.56 239.25,-161.81 387.5,-161.81 387.5,-142.56 239.25,-142.56"/>
<text text-anchor="start" x="243.25" y="-148.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-142.56 387.5,-161.81 457.75,-161.81 457.75,-142.56 387.5,-142.56"/>
<text text-anchor="start" x="391.5" y="-148.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-123.31 239.25,-142.56 387.5,-142.56 387.5,-123.31 239.25,-123.31"/>
<text text-anchor="start" x="243.25" y="-130.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-123.31 387.5,-142.56 457.75,-142.56 457.75,-123.31 387.5,-123.31"/>
<text text-anchor="start" x="391.5" y="-129.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-102.56 239.25,-123.31 387.5,-123.31 387.5,-102.56 239.25,-102.56"/>
<text text-anchor="start" x="243.25" y="-109.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-102.56 387.5,-123.31 457.75,-123.31 457.75,-102.56 387.5,-102.56"/>
<text text-anchor="start" x="391.5" y="-109.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-83.31 239.25,-102.56 387.5,-102.56 387.5,-83.31 239.25,-83.31"/>
<text text-anchor="start" x="243.25" y="-89.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-83.31 387.5,-102.56 457.75,-102.56 457.75,-83.31 387.5,-83.31"/>
<text text-anchor="start" x="391.5" y="-89.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-64.06 239.25,-83.31 387.5,-83.31 387.5,-64.06 239.25,-64.06"/>
<text text-anchor="start" x="243.25" y="-69.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-64.06 387.5,-83.31 457.75,-83.31 457.75,-64.06 387.5,-64.06"/>
<text text-anchor="start" x="391.5" y="-69.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-644.68C738.18,-644.68 810.07,-635.59 1086.84,-635.43"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.59,-637.54 1092.59,-635.43 1086.58,-633.34 1086.59,-637.54"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="643.75,-609.18 522.75,-609.18 522.75,-394.43 643.75,-394.43 643.75,-609.18"/>
<polygon fill="#f1efe8" stroke="none" points="522.75,-394.43 522.75,-609.18 643.75,-609.18 643.75,-394.43 522.75,-394.43"/>
<g id="a_node3_95"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="522.75,-589.93 522.75,-609.18 643.75,-609.18 643.75,-589.93 522.75,-589.93"/>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-589.93 522.75,-609.18 643.75,-609.18 643.75,-589.93 522.75,-589.93"/>
<text text-anchor="start" x="562.25" y="-596.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_96"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-570.68 522.75,-589.93 599,-589.93 599,-570.68 522.75,-570.68"/>
<text text-anchor="start" x="526.75" y="-576.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_97"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-570.68 599,-589.93 643.75,-589.93 643.75,-570.68 599,-570.68"/>
<text text-anchor="start" x="603" y="-576.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_98"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-551.43 522.75,-570.68 599,-570.68 599,-551.43 522.75,-551.43"/>
<text text-anchor="start" x="526.75" y="-558.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_99"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-551.43 599,-570.68 643.75,-570.68 643.75,-551.43 599,-551.43"/>
<text text-anchor="start" x="603" y="-557.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_100"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-532.18 522.75,-551.43 599,-551.43 599,-532.18 522.75,-532.18"/>
<text text-anchor="start" x="526.75" y="-538.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_101"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-532.18 599,-551.43 643.75,-551.43 643.75,-532.18 599,-532.18"/>
<text text-anchor="start" x="603" y="-537.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_102"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-511.43 522.75,-532.18 599,-532.18 599,-511.43 522.75,-511.43"/>
<text text-anchor="start" x="526.75" y="-517.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_103"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-511.43 599,-532.18 643.75,-532.18 643.75,-511.43 599,-511.43"/>
<text text-anchor="start" x="603" y="-518.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_104"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-492.18 522.75,-511.43 599,-511.43 599,-492.18 522.75,-492.18"/>
<text text-anchor="start" x="526.75" y="-497.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_105"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-492.18 599,-511.43 643.75,-511.43 643.75,-492.18 599,-492.18"/>
<text text-anchor="start" x="603" y="-497.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_106"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-472.93 522.75,-492.18 599,-492.18 599,-472.93 522.75,-472.93"/>
<text text-anchor="start" x="526.75" y="-478.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_107"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-472.93 599,-492.18 643.75,-492.18 643.75,-472.93 599,-472.93"/>
<text text-anchor="start" x="603" y="-478.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_108"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-453.68 522.75,-472.93 599,-472.93 599,-453.68 522.75,-453.68"/>
<text text-anchor="start" x="526.75" y="-460.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_109"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-453.68 599,-472.93 643.75,-472.93 643.75,-453.68 599,-453.68"/>
<text text-anchor="start" x="603" y="-459.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_110"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-434.43 522.75,-453.68 599,-453.68 599,-434.43 522.75,-434.43"/>
<text text-anchor="start" x="526.75" y="-440.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_111"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-434.43 599,-453.68 643.75,-453.68 643.75,-434.43 599,-434.43"/>
<text text-anchor="start" x="603" y="-440.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_112"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-413.68 522.75,-434.43 599,-434.43 599,-413.68 522.75,-413.68"/>
<text text-anchor="start" x="526.75" y="-421.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_113"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-413.68 599,-434.43 643.75,-434.43 643.75,-413.68 599,-413.68"/>
<text text-anchor="start" x="603" y="-420.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-394.43 522.75,-413.68 599,-413.68 599,-394.43 522.75,-394.43"/>
<text text-anchor="start" x="526.75" y="-400.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-394.43 599,-413.68 643.75,-413.68 643.75,-394.43 599,-394.43"/>
<text text-anchor="start" x="603" y="-400.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-449.18C527.86,-449.18 455.71,-588.6 515.26,-598.95"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="514.94,-601.03 521.09,-599.42 515.28,-596.85 514.94,-601.03"/>
</g>
<g id="node4" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="619.38,-322.31 547.12,-322.31 547.12,-245.31 619.38,-245.31 619.38,-322.31"/>
<polygon fill="#f1efe8" stroke="none" points="547.12,-245.31 547.12,-322.31 619.38,-322.31 619.38,-245.31 547.12,-245.31"/>
<g id="a_node4_116"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="547.12,-303.06 547.12,-322.31 619.38,-322.31 619.38,-303.06 547.12,-303.06"/>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-303.06 547.12,-322.31 619.38,-322.31 619.38,-303.06 547.12,-303.06"/>
<text text-anchor="start" x="566.38" y="-309.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node4_117"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-283.81 547.12,-303.06 587.38,-303.06 587.38,-283.81 547.12,-283.81"/>
<text text-anchor="start" x="551.12" y="-289.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node4_118"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-283.81 587.38,-303.06 619.38,-303.06 619.38,-283.81 587.38,-283.81"/>
<text text-anchor="start" x="591.38" y="-289.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_119"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-264.56 547.12,-283.81 587.38,-283.81 587.38,-264.56 547.12,-264.56"/>
<text text-anchor="start" x="551.12" y="-271.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_120"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-264.56 587.38,-283.81 619.38,-283.81 619.38,-264.56 587.38,-264.56"/>
<text text-anchor="start" x="591.38" y="-270.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_121"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-245.31 547.12,-264.56 587.38,-264.56 587.38,-245.31 547.12,-245.31"/>
<text text-anchor="start" x="551.12" y="-251.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_122"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-245.31 587.38,-264.56 619.38,-264.56 619.38,-245.31 587.38,-245.31"/>
<text text-anchor="start" x="591.38" y="-251.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-311.43C494.42,-311.43 505.41,-312.52 538.67,-312.67"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="538.46,-314.77 544.46,-312.68 538.46,-310.57 538.46,-314.77"/>
</g>
<g id="node7" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="811.75,-434.06 708.75,-434.06 708.75,-315.56 811.75,-315.56 811.75,-434.06"/>
<polygon fill="#f1efe8" stroke="none" points="708.75,-315.56 708.75,-434.06 811.75,-434.06 811.75,-315.56 708.75,-315.56"/>
<g id="a_node7_123"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="708.75,-414.81 708.75,-434.06 811.75,-434.06 811.75,-414.81 708.75,-414.81"/>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-414.81 708.75,-434.06 811.75,-434.06 811.75,-414.81 708.75,-414.81"/>
<text text-anchor="start" x="749.38" y="-421.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node7_124"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-395.56 708.75,-414.81 751.25,-414.81 751.25,-395.56 708.75,-395.56"/>
<text text-anchor="start" x="712.75" y="-402.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node7_125"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-395.56 751.25,-414.81 811.75,-414.81 811.75,-395.56 751.25,-395.56"/>
<text text-anchor="start" x="755.25" y="-401.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_126"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-376.31 708.75,-395.56 751.25,-395.56 751.25,-376.31 708.75,-376.31"/>
<text text-anchor="start" x="712.75" y="-383.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node7_127"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-376.31 751.25,-395.56 811.75,-395.56 811.75,-376.31 751.25,-376.31"/>
<text text-anchor="start" x="755.25" y="-382.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_128"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-357.06 708.75,-376.31 751.25,-376.31 751.25,-357.06 708.75,-357.06"/>
<text text-anchor="start" x="712.75" y="-362.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_129"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-357.06 751.25,-376.31 811.75,-376.31 811.75,-357.06 751.25,-357.06"/>
<text text-anchor="start" x="755.25" y="-362.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_130"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-336.31 708.75,-357.06 751.25,-357.06 751.25,-336.31 708.75,-336.31"/>
<text text-anchor="start" x="712.75" y="-342.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_131"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-336.31 751.25,-357.06 811.75,-357.06 811.75,-336.31 751.25,-336.31"/>
<text text-anchor="start" x="755.25" y="-343.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_132"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-315.56 708.75,-336.31 751.25,-336.31 751.25,-315.56 708.75,-315.56"/>
<text text-anchor="start" x="712.75" y="-323.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node7_133"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-315.56 751.25,-336.31 811.75,-336.31 811.75,-315.56 751.25,-315.56"/>
<text text-anchor="start" x="755.25" y="-322.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-210.68C541.11,-210.68 579.18,-182.08 643.75,-234.81 710.74,-289.51 624.97,-416.69 701.38,-424.09"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="701,-426.18 707.09,-424.36 701.19,-421.98 701,-426.18"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M644.75,-521.81C683.59,-521.81 669.2,-579.85 643.75,-609.18 608.09,-650.28 572.15,-605 522.75,-627.81 490.53,-642.68 495.03,-678.41 465.15,-683.36"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="465.23,-681.25 459.41,-683.8 465.55,-685.43 465.23,-681.25"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M643.75,-424.06C669.93,-424.06 678.32,-424.37 701.16,-424.42"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="701.08,-426.52 707.09,-424.43 701.09,-422.32 701.08,-426.52"/>
</g>
<g id="node6" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-970.81 0,-970.81 0,-382.81 174.25,-382.81 174.25,-970.81"/>
<polygon fill="#f1efe8" stroke="none" points="0,-382.81 0,-970.81 174.25,-970.81 174.25,-382.81 0,-382.81"/>
<g id="a_node6_134"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-951.56 0,-970.81 174.25,-970.81 174.25,-951.56 0,-951.56"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-951.56 0,-970.81 174.25,-970.81 174.25,-951.56 0,-951.56"/>
<text text-anchor="start" x="68" y="-958.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node6_135"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-932.31 0,-951.56 107,-951.56 107,-932.31 0,-932.31"/>
<text text-anchor="start" x="4" y="-938.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node6_136"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-932.31 107,-951.56 174.25,-951.56 174.25,-932.31 107,-932.31"/>
<text text-anchor="start" x="111" y="-938.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_137"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-913.06 0,-932.31 107,-932.31 107,-913.06 0,-913.06"/>
<text text-anchor="start" x="4" y="-918.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node6_138"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-913.06 107,-932.31 174.25,-932.31 174.25,-913.06 107,-913.06"/>
<text text-anchor="start" x="111" y="-918.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_139"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-893.81 0,-913.06 107,-913.06 107,-893.81 0,-893.81"/>
<text text-anchor="start" x="4" y="-899.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node6_140"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-893.81 107,-913.06 174.25,-913.06 174.25,-893.81 107,-893.81"/>
<text text-anchor="start" x="111" y="-899.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node6_141"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-874.56 0,-893.81 107,-893.81 107,-874.56 0,-874.56"/>
<text text-anchor="start" x="4" y="-880.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node6_142"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-874.56 107,-893.81 174.25,-893.81 174.25,-874.56 107,-874.56"/>
<text text-anchor="start" x="111" y="-880.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node6_143"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-855.31 0,-874.56 107,-874.56 107,-855.31 0,-855.31"/>
<text text-anchor="start" x="4" y="-861.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node6_144"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-855.31 107,-874.56 174.25,-874.56 174.25,-855.31 107,-855.31"/>
<text text-anchor="start" x="111" y="-861.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_145"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-836.06 0,-855.31 107,-855.31 107,-836.06 0,-836.06"/>
<text text-anchor="start" x="4" y="-841.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node6_146"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-836.06 107,-855.31 174.25,-855.31 174.25,-836.06 107,-836.06"/>
<text text-anchor="start" x="111" y="-841.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_147"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-816.81 0,-836.06 107,-836.06 107,-816.81 0,-816.81"/>
<text text-anchor="start" x="4" y="-822.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node6_148"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-816.81 107,-836.06 174.25,-836.06 174.25,-816.81 107,-816.81"/>
<text text-anchor="start" x="111" y="-822.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_149"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-797.56 0,-816.81 107,-816.81 107,-797.56 0,-797.56"/>
<text text-anchor="start" x="4" y="-803.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node6_150"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-797.56 107,-816.81 174.25,-816.81 174.25,-797.56 107,-797.56"/>
<text text-anchor="start" x="111" y="-803.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_151"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-778.31 0,-797.56 107,-797.56 107,-778.31 0,-778.31"/>
<text text-anchor="start" x="4" y="-785.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node6_152"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-778.31 107,-797.56 174.25,-797.56 174.25,-778.31 107,-778.31"/>
<text text-anchor="start" x="111" y="-784.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_153"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-759.06 0,-778.31 107,-778.31 107,-759.06 0,-759.06"/>
<text text-anchor="start" x="4" y="-764.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node6_154"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-759.06 107,-778.31 174.25,-778.31 174.25,-759.06 107,-759.06"/>
<text text-anchor="start" x="111" y="-764.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_155"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-738.31 0,-759.06 107,-759.06 107,-738.31 0,-738.31"/>
<text text-anchor="start" x="4" y="-744.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node6_156"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-738.31 107,-759.06 174.25,-759.06 174.25,-738.31 107,-738.31"/>
<text text-anchor="start" x="111" y="-745.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_157"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-717.56 0,-738.31 107,-738.31 107,-717.56 0,-717.56"/>
<text text-anchor="start" x="4" y="-724.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node6_158"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-717.56 107,-738.31 174.25,-738.31 174.25,-717.56 107,-717.56"/>
<text text-anchor="start" x="111" y="-724.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node6_159"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-698.31 0,-717.56 107,-717.56 107,-698.31 0,-698.31"/>
<text text-anchor="start" x="4" y="-704.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node6_160"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-698.31 107,-717.56 174.25,-717.56 174.25,-698.31 107,-698.31"/>
<text text-anchor="start" x="111" y="-704.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_161"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-679.06 0,-698.31 107,-698.31 107,-679.06 0,-679.06"/>
<text text-anchor="start" x="4" y="-685.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node6_162"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-679.06 107,-698.31 174.25,-698.31 174.25,-679.06 107,-679.06"/>
<text text-anchor="start" x="111" y="-684.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_163"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-658.31 0,-679.06 107,-679.06 107,-658.31 0,-658.31"/>
<text text-anchor="start" x="4" y="-664.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node6_164"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-658.31 107,-679.06 174.25,-679.06 174.25,-658.31 107,-658.31"/>
<text text-anchor="start" x="111" y="-665.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_165"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-639.06 0,-658.31 107,-658.31 107,-639.06 0,-639.06"/>
<text text-anchor="start" x="4" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node6_166"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-639.06 107,-658.31 174.25,-658.31 174.25,-639.06 107,-639.06"/>
<text text-anchor="start" x="111" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_167"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-619.81 0,-639.06 107,-639.06 107,-619.81 0,-619.81"/>
<text text-anchor="start" x="4" y="-626.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node6_168"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-619.81 107,-639.06 174.25,-639.06 174.25,-619.81 107,-619.81"/>
<text text-anchor="start" x="111" y="-625.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_169"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-600.56 0,-619.81 107,-619.81 107,-600.56 0,-600.56"/>
<text text-anchor="start" x="4" y="-607.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node6_170"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-600.56 107,-619.81 174.25,-619.81 174.25,-600.56 107,-600.56"/>
<text text-anchor="start" x="111" y="-606.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_171"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-581.31 0,-600.56 107,-600.56 107,-581.31 0,-581.31"/>
<text text-anchor="start" x="4" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node6_172"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-581.31 107,-600.56 174.25,-600.56 174.25,-581.31 107,-581.31"/>
<text text-anchor="start" x="111" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_173"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-562.06 0,-581.31 107,-581.31 107,-562.06 0,-562.06"/>
<text text-anchor="start" x="4" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node6_174"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-562.06 107,-581.31 174.25,-581.31 174.25,-562.06 107,-562.06"/>
<text text-anchor="start" x="111" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_175"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-541.31 0,-562.06 107,-562.06 107,-541.31 0,-541.31"/>
<text text-anchor="start" x="4" y="-547.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node6_176"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-541.31 107,-562.06 174.25,-562.06 174.25,-541.31 107,-541.31"/>
<text text-anchor="start" x="111" y="-548.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_177"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-520.56 0,-541.31 107,-541.31 107,-520.56 0,-520.56"/>
<text text-anchor="start" x="4" y="-527.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node6_178"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-520.56 107,-541.31 174.25,-541.31 174.25,-520.56 107,-520.56"/>
<text text-anchor="start" x="111" y="-527.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node6_179"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-501.31 0,-520.56 107,-520.56 107,-501.31 0,-501.31"/>
<text text-anchor="start" x="4" y="-508.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_180"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-501.31 107,-520.56 174.25,-520.56 174.25,-501.31 107,-501.31"/>
<text text-anchor="start" x="111" y="-507.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_181"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-482.06 0,-501.31 107,-501.31 107,-482.06 0,-482.06"/>
<text text-anchor="start" x="4" y="-487.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_182"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-482.06 107,-501.31 174.25,-501.31 174.25,-482.06 107,-482.06"/>
<text text-anchor="start" x="111" y="-487.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_183"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-462.81 0,-482.06 107,-482.06 107,-462.81 0,-462.81"/>
<text text-anchor="start" x="4" y="-468.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node6_184"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-462.81 107,-482.06 174.25,-482.06 174.25,-462.81 107,-462.81"/>
<text text-anchor="start" x="111" y="-468.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_185"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-442.06 0,-462.81 107,-462.81 107,-442.06 0,-442.06"/>
<text text-anchor="start" x="4" y="-448.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node6_186"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-442.06 107,-462.81 174.25,-462.81 174.25,-442.06 107,-442.06"/>
<text text-anchor="start" x="111" y="-449.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node6_187"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-422.81 0,-442.06 107,-442.06 107,-422.81 0,-422.81"/>
<text text-anchor="start" x="4" y="-428.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node6_188"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-422.81 107,-442.06 174.25,-442.06 174.25,-422.81 107,-422.81"/>
<text text-anchor="start" x="111" y="-428.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_189"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-402.06 0,-422.81 107,-422.81 107,-402.06 0,-402.06"/>
<text text-anchor="start" x="4" y="-408.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node6_190"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-402.06 107,-422.81 174.25,-422.81 174.25,-402.06 107,-402.06"/>
<text text-anchor="start" x="111" y="-409.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_191"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-382.81 0,-402.06 107,-402.06 107,-382.81 0,-382.81"/>
<text text-anchor="start" x="4" y="-388.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node6_192"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-382.81 107,-402.06 174.25,-402.06 174.25,-382.81 107,-382.81"/>
<text text-anchor="start" x="111" y="-388.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-727.93C355.58,-727.93 400.92,-727.81 582.25,-727.81 582.25,-727.81 582.25,-727.81 761.25,-727.81 884.82,-727.81 910.24,-687.06 1029.25,-653.81 1055.57,-646.45 1062.95,-637.26 1086.7,-635.67"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.66,-637.78 1092.59,-635.49 1086.52,-633.58 1086.66,-637.78"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-530.93C245.39,-530.93 171.29,-672.79 231.66,-683.32"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-685.41 237.59,-683.8 231.78,-681.22 231.44,-685.41"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-452.43C264.22,-452.43 172.7,-113.36 239.25,-52.81 352.26,50.02 429.46,-29.81 582.25,-29.81 582.25,-29.81 582.25,-29.81 954,-29.81 1078.15,-29.81 1135.47,-4.2 1227.25,-87.81 1297.04,-151.39 1200.73,-288.54 1284.73,-295.99"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.5,-298.08 1290.59,-296.24 1284.68,-293.89 1284.5,-298.08"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M811.75,-346.68C840.64,-346.68 847.86,-346.78 876.75,-346.81 944.53,-346.87 961.78,-353.23 1029.25,-346.81 1145.19,-335.78 1172.09,-297.98 1284.71,-296.36"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.6,-298.46 1290.59,-296.32 1284.57,-294.26 1284.6,-298.46"/>
</g>
<g id="node8" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1029.25,-336.06 876.75,-336.06 876.75,-63.56 1029.25,-63.56 1029.25,-336.06"/>
<polygon fill="#f1efe8" stroke="none" points="876.75,-63.56 876.75,-336.06 1029.25,-336.06 1029.25,-63.56 876.75,-63.56"/>
<g id="a_node8_193"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="876.75,-316.81 876.75,-336.06 1029.25,-336.06 1029.25,-316.81 876.75,-316.81"/>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-316.81 876.75,-336.06 1029.25,-336.06 1029.25,-316.81 876.75,-316.81"/>
<text text-anchor="start" x="935.75" y="-323.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_194"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-297.56 876.75,-316.81 962,-316.81 962,-297.56 876.75,-297.56"/>
<text text-anchor="start" x="880.75" y="-303.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node8_195"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-297.56 962,-316.81 1029.25,-316.81 1029.25,-297.56 962,-297.56"/>
<text text-anchor="start" x="966" y="-303.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_196"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-278.31 876.75,-297.56 962,-297.56 962,-278.31 876.75,-278.31"/>
<text text-anchor="start" x="880.75" y="-284.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node8_197"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-278.31 962,-297.56 1029.25,-297.56 1029.25,-278.31 962,-278.31"/>
<text text-anchor="start" x="966" y="-284.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node8_198"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-259.06 876.75,-278.31 962,-278.31 962,-259.06 876.75,-259.06"/>
<text text-anchor="start" x="880.75" y="-265.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node8_199"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-259.06 962,-278.31 1029.25,-278.31 1029.25,-259.06 962,-259.06"/>
<text text-anchor="start" x="966" y="-264.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_200"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-239.81 876.75,-259.06 962,-259.06 962,-239.81 876.75,-239.81"/>
<text text-anchor="start" x="880.75" y="-246.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node8_201"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-239.81 962,-259.06 1029.25,-259.06 1029.25,-239.81 962,-239.81"/>
<text text-anchor="start" x="966" y="-245.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_202"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-219.06 876.75,-239.81 962,-239.81 962,-219.06 876.75,-219.06"/>
<text text-anchor="start" x="880.75" y="-225.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node8_203"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-219.06 962,-239.81 1029.25,-239.81 1029.25,-219.06 962,-219.06"/>
<text text-anchor="start" x="966" y="-226.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node8_204"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-199.81 876.75,-219.06 962,-219.06 962,-199.81 876.75,-199.81"/>
<text text-anchor="start" x="880.75" y="-205.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node8_205"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-199.81 962,-219.06 1029.25,-219.06 1029.25,-199.81 962,-199.81"/>
<text text-anchor="start" x="966" y="-205.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_206"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-180.56 876.75,-199.81 962,-199.81 962,-180.56 876.75,-180.56"/>
<text text-anchor="start" x="880.75" y="-186.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node8_207"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-180.56 962,-199.81 1029.25,-199.81 1029.25,-180.56 962,-180.56"/>
<text text-anchor="start" x="966" y="-186.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_208"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-161.31 876.75,-180.56 962,-180.56 962,-161.31 876.75,-161.31"/>
<text text-anchor="start" x="880.75" y="-167.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node8_209"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-161.31 962,-180.56 1029.25,-180.56 1029.25,-161.31 962,-161.31"/>
<text text-anchor="start" x="966" y="-167.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_210"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-142.06 876.75,-161.31 962,-161.31 962,-142.06 876.75,-142.06"/>
<text text-anchor="start" x="880.75" y="-147.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node8_211"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-142.06 962,-161.31 1029.25,-161.31 1029.25,-142.06 962,-142.06"/>
<text text-anchor="start" x="966" y="-147.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_212"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-122.81 876.75,-142.06 962,-142.06 962,-122.81 876.75,-122.81"/>
<text text-anchor="start" x="880.75" y="-128.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node8_213"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-122.81 962,-142.06 1029.25,-142.06 1029.25,-122.81 962,-122.81"/>
<text text-anchor="start" x="966" y="-128.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_214"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-103.56 876.75,-122.81 962,-122.81 962,-103.56 876.75,-103.56"/>
<text text-anchor="start" x="880.75" y="-109.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node8_215"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-103.56 962,-122.81 1029.25,-122.81 1029.25,-103.56 962,-103.56"/>
<text text-anchor="start" x="966" y="-109.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_216"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-84.31 876.75,-103.56 962,-103.56 962,-84.31 876.75,-84.31"/>
<text text-anchor="start" x="880.75" y="-90.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_217"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-84.31 962,-103.56 1029.25,-103.56 1029.25,-84.31 962,-84.31"/>
<text text-anchor="start" x="966" y="-90.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_218"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-63.56 876.75,-84.31 962,-84.31 962,-63.56 876.75,-63.56"/>
<text text-anchor="start" x="880.75" y="-70.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_219"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-63.56 962,-84.31 1029.25,-84.31 1029.25,-63.56 962,-63.56"/>
<text text-anchor="start" x="966" y="-70.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M811.75,-325.93C837.93,-325.93 846.32,-326.34 869.16,-326.42"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="869.08,-328.52 875.09,-326.43 869.09,-324.32 869.08,-328.52"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1029.25,-229.43C1209.49,-229.43 919.63,-624.41 1087.02,-635.21"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.52,-637.29 1092.59,-635.38 1086.65,-633.09 1086.52,-637.29"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1029.25,-73.93C1179.78,-73.93 1140.56,-288.99 1284.79,-296.13"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.54,-298.22 1290.59,-296.27 1284.64,-294.02 1284.54,-298.22"/>
</g>
</g>
</svg>
</figure>

Ein Klick auf den Kopf eines Abschnitts führt zu seinem Abschnitt weiter unten, ein Klick auf ein Feld zu seiner Zeile in der Feldtabelle; anderswo öffnet sich das Diagramm vergrößert. Als Datei: [inventory-schema.svg](site/de/assets/diagrams/inventory-schema.svg).

### Konventionen

**IDs.** Einträge haben eine ID als Schlüssel: Kleinbuchstaben, Ziffern und Bindestriche, am Anfang ein Buchstabe oder eine Ziffer (`grammi`, `realtox-dus`, `home-main`). Ein Verweisfeld enthält eine solche ID und muss einen vorhandenen Eintrag des richtigen Abschnitts nennen.

**Pflicht und optional.** Ein Feld ist optional, wenn die Tabelle nicht *Pflicht* sagt. Fehlende optionale Felder füllt die abgeleitete Sicht auf – mit dem Standardwert aus der Tabelle, sonst `null` oder `[]` –, damit ein Nutzer der Daten nie `or` schreiben muss.

**Unbekannte Felder sind Fehler.** Ein Tippfehler (`critcality`) wird mit der Liste der bekannten Felder gemeldet, im Editor sofort und in `nix flake check`.

**Eine Richtung.** Jede Beziehung steht dort, wo sie beginnt (`hosts.runsOn`, `services.dependsOn`, `hosts.contracts`); die Gegenrichtung (`guests`, `neededBy`, `covers`) wird abgeleitet.

**Formate.** Strings mit einem Format werden dagegen geprüft:

| Format | Beispiel | Verwendet von |
| --- | --- | --- |
| IPv4-Adresse | `192.0.2.10` | `interfaces.<name>.ipv4.address`, `dhcpPool` |
| IPv4-Präfix (ohne Host-Bits) | `192.0.2.0/24` | `networks.ipv4` |
| IPv6-Präfix | `2001:db8:1::/64` | `networks.ipv6` |
| MAC-Adresse, Kleinbuchstaben | `52:54:00:12:34:56` | `interfaces.<name>.mac` |
| Link-Local | `eui64`, `stable-privacy`, `random` oder `fe80::1234` | `interfaces.<name>.linkLocal` |
| SSH-Public-Key ohne Kommentar | `ssh-ed25519 AAAAC3Nz…` | `hosts.sshHostKeys` |
| Datum | `2026-10-22` | `contracts.since`, `contracts.renews` |
| Domainname, Kleinbuchstaben | `cloud.example.org` | `services.endpoints[].fqdn` |
| Interface-Name | `eno1`, `eno1.20`, `wlp2s0f0` | Schlüssel von `hosts.interfaces` |

**Geld** steht in ganzen Cent (`899` = 8,99) – keine Kommazahlen, keine Rundung.

**Was das Schema nicht ausdrücken kann.** Ein JSON Schema prüft einen Eintrag für sich. Alles zwischen Einträgen – Verweise, Zyklen, Adressen innerhalb eines Präfixes, ein Vertrag mit dem richtigen Anbieter – prüft nur `inventory.nix`; jeder Abschnitt unten nennt diese Regeln kurz, [Prüfung](#prüfung) hat sie alle.

### owners

Wer ein Gerät administriert – wen man anruft und was geändert werden darf.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="owners-contact"></span>`contact` | String |  | Who to talk to when this owner's devices are affected. |
| <span id="owners-name"></span>`name` | String | Pflicht | Display name. |
| <span id="owners-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  }
}
```

Regel über das Schema hinaus: Jeder Owner hat mindestens einen Host.

### providers

Eine Firma oder ein Verein, von dem das Lab abhängt: Provider, Hoster, ein von außen eingekaufter Dienst, der Hackerspace.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="providers-contact"></span>`contact` | String |  | How to reach them (support address, phone, ticket system). |
| <span id="providers-name"></span>`name` | String | Pflicht | Display name of the company or club. |
| <span id="providers-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="providers-url"></span>`url` | String |  | Website or customer portal. |

```json
{
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  }
}
```

Regel über das Schema hinaus: Auf jeden Anbieter verweist etwas – eine Site, ein Anschluss, ein Dienst oder ein Vertrag.

### contracts

Was an einen Anbieter bezahlt wird. Ein Anbieter kann mehrere haben; ein Host, Anschluss oder Dienst nennt die, über die er bezahlt wird.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="contracts-cost"></span>`cost` | Objekt |  | What it costs. Leave it out until known - the contract is then listed in pending. |
| <span id="contracts-cost-amount"></span>`cost.amount` | Ganzzahl ≥ 0 | Pflicht | Amount per period in cents (899 = 8.99) - whole numbers only. |
| <span id="contracts-cost-currency"></span>`cost.currency` | eins von `EUR` `USD` `CHF` `GBP` | Pflicht | Currency of amount. Totals are kept per currency, never converted. |
| <span id="contracts-cost-duemonth"></span>`cost.dueMonth` | Ganzzahl 1–12 |  | Only with period year, and required there: the month (1-12) the yearly amount is charged in. |
| <span id="contracts-cost-period"></span>`cost.period` | eins von `month` `year` `once` | Pflicht | How often amount is charged. |
| <span id="contracts-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="contracts-notice"></span>`notice` | String |  | Notice period, as the contract words it. |
| <span id="contracts-product"></span>`product` | String |  | Product or plan name as the provider calls it. |
| <span id="contracts-provider"></span>`provider` | ID aus [providers](#providers-1) | Pflicht | Who the contract is with. |
| <span id="contracts-renews"></span>`renews` | String: a date like 2026-10-22 |  | Next date the contract renews or ends unless cancelled. |
| <span id="contracts-since"></span>`since` | String: a date like 2026-10-22 |  | Start of the contract. |

```json
{
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  }
}
```

Regeln über das Schema hinaus: `cost.dueMonth` genau bei `period` `year`; `renews` nicht vor `since`; ein Vertrag, den ein Host, Anschluss oder Dienst nennt, ist mit dessen Anbieter geschlossen (bei einem Host: dem Anbieter seiner Site). Ein Vertrag ohne `cost` steht unter `pending`, einer, den nichts nennt, unter `gaps`.

### uplinks

Ein Internetanschluss. Alle Felder sind optional, damit ein Anschluss eingetragen werden kann, bevor seine Details bekannt sind.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="uplinks-asn"></span>`asn` | Ganzzahl ≥ 1 |  | Autonomous system number of the provider's network, without the AS prefix. |
| <span id="uplinks-bandwidth"></span>`bandwidth` | Objekt |  | Booked bandwidth in Mbit/s. |
| <span id="uplinks-bandwidth-down"></span>`bandwidth.down` | Ganzzahl ≥ 1 | Pflicht | Downstream in Mbit/s. |
| <span id="uplinks-bandwidth-up"></span>`bandwidth.up` | Ganzzahl ≥ 1 | Pflicht | Upstream in Mbit/s. |
| <span id="uplinks-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts-1), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="uplinks-ipv4"></span>`ipv4` | eins von `public` `cgnat` `none` |  | What the line gives for IPv4. |
| <span id="uplinks-ipv4static"></span>`ipv4Static` | Boolean |  | Whether the public IPv4 address is fixed. Only meaningful with ipv4 = public. |
| <span id="uplinks-ipv6"></span>`ipv6` | Boolean |  | Whether the line has native IPv6. |
| <span id="uplinks-ipv6prefixlength"></span>`ipv6PrefixLength` | Ganzzahl 1–128 |  | Size of the IPv6 prefix the provider delegates (e.g. 56 for a /56). Only with ipv6. |
| <span id="uplinks-ipv6static"></span>`ipv6Static` | Boolean |  | Whether the delegated IPv6 prefix is fixed. Only with ipv6. |
| <span id="uplinks-medium"></span>`medium` | eins von `fiber` `dsl` `cable` `lte` `satellite` `datacenter` |  | Kind of line. |
| <span id="uplinks-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="uplinks-provider"></span>`provider` | ID aus [providers](#providers-1) |  | Internet provider (for a data centre: the hoster). |

```json
{
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  }
}
```

Regeln über das Schema hinaus: `ipv6PrefixLength` und `ipv6Static` nur mit `ipv6`; jeder Anschluss gehört zu einer Site; `contracts` sind mit dem `provider` des Anschlusses geschlossen.

### sites

Ein Ort, an dem Geräte stehen.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="sites-city"></span>`city` | String | Pflicht | City the site is in. |
| <span id="sites-kind"></span>`kind` | eins von `residential` `hackerspace` `datacenter` | Pflicht | Kind of place. |
| <span id="sites-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="sites-provider"></span>`provider` | ID aus [providers](#providers-1) |  | Who runs the place (hoster, club); empty for a home. |
| <span id="sites-uplinks"></span>`uplinks` | Liste von ID aus [uplinks](#uplinks-1), ohne Duplikate | Pflicht | Internet lines of the site, the primary one first, backups after it. |

```json
{
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ]
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  }
}
```

Regeln über das Schema hinaus: mindestens ein Anschluss, der primäre zuerst; an jeder Site steht etwas.

### networks

Ein Layer-2-Netz mit seinem IPv4-Präfix.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="networks-dhcppool"></span>`dhcpPool` | Objekt |  | Range the DHCP server hands out dynamically; static addresses must lie outside it. |
| <span id="networks-dhcppool-end"></span>`dhcpPool.end` | String: an IPv4 address | Pflicht | Last address of the pool. |
| <span id="networks-dhcppool-start"></span>`dhcpPool.start` | String: an IPv4 address | Pflicht | First address of the pool. |
| <span id="networks-dhcpserver"></span>`dhcpServer` | ID aus [hosts](#hosts-2) |  | The host serving DHCP for IPv4 here; it needs an interface in this network. |
| <span id="networks-ipv4"></span>`ipv4` | String: an IPv4 prefix like 192.0.2.0/24 |  | IPv4 prefix. |
| <span id="networks-ipv6"></span>`ipv6` | String: an IPv6 prefix like 2001:db8::/64 |  | IPv6 prefix, when it is fixed (ULA or static GUA). |
| <span id="networks-name"></span>`name` | String | Pflicht | Display name. |
| <span id="networks-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="networks-site"></span>`site` | ID aus [sites](#sites-1) | Pflicht | Where the network is. |
| <span id="networks-vlan"></span>`vlan` | Ganzzahl 1–4094 |  | 802.1Q VLAN id. Leave out for an untagged network. |

```json
{
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "ipv6": "2001:db8:1::/64",
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  }
}
```

Regeln über das Schema hinaus: Das Präfix hat keine Host-Bits; der Pool liegt darin, Start vor Ende, und braucht `ipv4` und `dhcpServer`; der DHCP-Server steht an der Site und hat ein Interface im Netz; eine VLAN-ID nur einmal pro Site.

### hosts

Jedes Gerät mit einer Adresse, die zählt – von diesem Flake verwaltet oder nicht.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="hosts-availability"></span>`availability` | eins von `always-on` `intermittent` | Standard `"always-on"` | intermittent: being offline is normal (a laptop) and is not an incident. |
| <span id="hosts-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts-1), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="hosts-criticality"></span>`criticality` | eins von `core` `service` `lab` | Standard `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="hosts-inside"></span>`inside` | ID aus [hosts](#hosts-2) |  | Physically built into another device, e.g. a PCIe KVM card in its host. |
| <span id="hosts-interfaces"></span>`interfaces` | Objekt: Name → Objekt |  | Network interfaces by name (as the OS calls them; for an appliance any label like lan/wan). A VLAN interface (eno1.10) is an entry of its own. |
| <span id="hosts-interfaces-name-ipv4"></span>`interfaces.<name>.ipv4` | Objekt |  | IPv4 addressing of this interface in its network. |
| <span id="hosts-interfaces-name-ipv4-address"></span>`interfaces.<name>.ipv4.address` | String: an IPv4 address |  | The address - required for reserved and static. |
| <span id="hosts-interfaces-name-ipv4-mode"></span>`interfaces.<name>.ipv4.mode` | eins von `reserved` `static` `dhcp` | Pflicht | reserved: fixed DHCP lease by MAC; static: configured on the device; dhcp: dynamic. |
| <span id="hosts-interfaces-name-linklocal"></span>`interfaces.<name>.linkLocal` | String: eui64, stable-privacy, random or an fe80:: address |  | How the IPv6 link-local address is formed: eui64 (computed from mac), stable-privacy (RFC 7217), random - or the fixed fe80:: address itself. |
| <span id="hosts-interfaces-name-mac"></span>`interfaces.<name>.mac` | String: a lower-case MAC address like aa:bb:cc:dd:ee:ff |  | Hardware address, lower case. |
| <span id="hosts-interfaces-name-medium"></span>`interfaces.<name>.medium` | eins von `ethernet` `wifi` |  | Physical medium. |
| <span id="hosts-interfaces-name-network"></span>`interfaces.<name>.network` | ID aus [networks](#networks-1) |  | The network this interface is in. |
| <span id="hosts-interfaces-name-note"></span>`interfaces.<name>.note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-kind"></span>`kind` | eins von `server` `hypervisor` `vm` `container` `router` `switch` `ap` `pdu` `ups` `kvm` `nas` `workstation` `laptop` `phone` `tablet` `watch` `appliance` | Pflicht | What the device is. |
| <span id="hosts-managed"></span>`managed` | Boolean | Pflicht | Configured by this flake (nixosConfigurations/darwinConfigurations). Must match the flake. |
| <span id="hosts-manages"></span>`manages` | Liste von ID aus [hosts](#hosts-2), ohne Duplikate |  | Only kvm: the machines this KVM gives out-of-band access to. |
| <span id="hosts-model"></span>`model` | String |  | Hardware model without the vendor (ThinkCentre M720q), or for a VM the provider's product or plan name. |
| <span id="hosts-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-owner"></span>`owner` | ID aus [owners](#owners-1) | Pflicht | Who administers the device. |
| <span id="hosts-power"></span>`power` | ID aus [hosts](#hosts-2) |  | Where the power comes from: a PDU/UPS, a PoE switch, or the host a card sits in. |
| <span id="hosts-productid"></span>`productId` | String |  | The vendor's product id for drivers and firmware: Lenovo machine type (10T7...), Apple model identifier (Mac16,10). Not for vm/container. |
| <span id="hosts-runson"></span>`runsOn` | ID aus [hosts](#hosts-2) |  | Only vm/container: the machine it runs on. Optional - a rented VM's host is not in the inventory. |
| <span id="hosts-serial"></span>`serial` | String |  | Serial number. Unique lab-wide. Not for vm/container. |
| <span id="hosts-site"></span>`site` | ID aus [sites](#sites-1) |  | Where the device is. Optional for entries with runsOn or inside - they inherit it. |
| <span id="hosts-sshhostkeys"></span>`sshHostKeys` | Liste von String: an OpenSSH public key "<type> <base64>" without comment, ohne Duplikate |  | The device's SSH host public keys (/etc/ssh/ssh_host_*_key.pub without the comment). Feeds known_hosts and the sops check. |
| <span id="hosts-unlock"></span>`unlock` | Objekt |  | Disk unlock after a reboot. Leave it out for an unencrypted disk. |
| <span id="hosts-unlock-fallback"></span>`unlock.fallback` | eins von `remote-ssh` `console` |  | How a human unlocks when the methods fail: over SSH (initrd, FileVault) or at the console/KVM. |
| <span id="hosts-unlock-methods"></span>`unlock.methods` | Liste von eins von `tpm` `nbde`, ohne Duplikate | Pflicht | Automatic unlock methods. Empty when only a human can unlock. |
| <span id="hosts-unlock-tang"></span>`unlock.tang` | Liste von ID aus [hosts](#hosts-2), ohne Duplikate |  | Tang servers for nbde; any one of them is enough. |
| <span id="hosts-unlock-threshold"></span>`unlock.threshold` | Ganzzahl ≥ 1 | Standard `1` | How many of the methods must succeed (Clevis sss threshold). Defaults to 1. |
| <span id="hosts-vendor"></span>`vendor` | String |  | Hardware manufacturer (Lenovo, Apple, GL.iNet). Not for vm/container. |

```json
{
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "medium": "ethernet",
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "medium": "wifi",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  }
}
```

Regeln über das Schema hinaus (die wichtigsten – [Prüfung](#prüfung) hat alle):

- `site` ist Pflicht, außer sie lässt sich entlang `runsOn` oder `inside` erben, und eine angegebene stimmt mit der geerbten überein.
- `runsOn` nur bei `vm`/`container`, auf einer erlaubten Geräteart; `manages` nur bei `kvm`; `vendor`/`productId`/`serial` nicht bei `vm`/`container`.
- `runsOn`, `inside` und `power` ohne Zyklen; jeder Host mit `nbde` erreicht einen Tang-Server, der ohne Menschen hochkommt.
- `managed` stimmt in beide Richtungen mit `flake.nix` überein.
- Adressen: innerhalb des Präfixes des Netzes, passend zum Modus (`reserved` braucht `mac` und einen DHCP-Server, `static` liegt außerhalb des Pools), jede nur einmal pro Netz; MACs und Host-Keys nur einmal im ganzen Lab.

### services

Was die Hosts betreiben und was von außen eingekauft ist.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="services-backup"></span>`backup` | Liste von Objekt, ohne Duplikate |  | How its data is backed up. Only for stateful. |
| <span id="services-backup-interval"></span>`backup[].interval` | eins von `hourly` `daily` `weekly` `monthly` |  | How often it runs. |
| <span id="services-backup-keep"></span>`backup[].keep` | Objekt |  | Which versions are kept - at the target, or on the machine without to. Left out: unknown. |
| <span id="services-backup-keep-all"></span>`backup[].keep.all` | Boolean |  | Only true, and only alone: every version is kept, nothing is ever pruned. |
| <span id="services-backup-keep-daily"></span>`backup[].keep.daily` | Ganzzahl ≥ 1 |  | One per day for the last n days. |
| <span id="services-backup-keep-last"></span>`backup[].keep.last` | Ganzzahl ≥ 1 |  | The newest n versions. |
| <span id="services-backup-keep-monthly"></span>`backup[].keep.monthly` | Ganzzahl ≥ 1 |  | One per month for the last n months. |
| <span id="services-backup-keep-weekly"></span>`backup[].keep.weekly` | Ganzzahl ≥ 1 |  | One per week for the last n weeks. |
| <span id="services-backup-method"></span>`backup[].method` | eins von `restic` `arq` `btrbk` `pgdump` `provider-snapshot` `ha-backup` | Pflicht | restic/arq copy to another service (to); btrbk, pgdump and provider-snapshot stay on the same machine or provider; ha-backup (Home Assistant's own backup) stays on the machine without to, or goes to an upload target with to. |
| <span id="services-backup-note"></span>`backup[].note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-backup-to"></span>`backup[].to` | ID aus [services](#services-1) |  | The service the copy goes to - required with restic/arq, optional with ha-backup. |
| <span id="services-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts-1), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="services-criticality"></span>`criticality` | eins von `core` `service` `lab` | Standard `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="services-data"></span>`data` | eins von `stateful` `stateless` | Pflicht | stateful: it keeps data that is lost with it; stateless: it can be rebuilt from the repository. |
| <span id="services-dependson"></span>`dependsOn` | Liste von ID aus [services](#services-1), ohne Duplikate |  | Services it cannot work without. |
| <span id="services-endpoints"></span>`endpoints` | Liste von Objekt, ohne Duplikate |  | How the service is reached. |
| <span id="services-endpoints-exposure"></span>`endpoints[].exposure` | eins von `public` `proxy` `mesh` `lan` `loopback` | Pflicht | public: open on the internet from its own host; proxy: through a reverse proxy (name it in via); mesh: only inside the overlay network; lan: only in a local network; loopback: only on the host itself. |
| <span id="services-endpoints-fqdn"></span>`endpoints[].fqdn` | String: a lower-case domain name like cloud.example.org | Pflicht | Name it is reached by. |
| <span id="services-endpoints-note"></span>`endpoints[].note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-endpoints-port"></span>`endpoints[].port` | Ganzzahl 1–65535 |  | Port, when it is not the protocol's default. |
| <span id="services-endpoints-via"></span>`endpoints[].via` | ID aus [services](#services-1) |  | The service it is reached through - the reverse proxy for exposure proxy (required there). Counts as a dependency. |
| <span id="services-hosts"></span>`hosts` | Liste von ID aus [hosts](#hosts-2), ohne Duplikate |  | The machines it runs on. Exactly one of hosts and provider. |
| <span id="services-name"></span>`name` | String | Pflicht | Display name. |
| <span id="services-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-package"></span>`package` | String |  | Only on managed hosts: option path of the package in the host's configuration (services.paperless.package) - version, license and language are read from there. |
| <span id="services-provider"></span>`provider` | ID aus [providers](#providers-1) |  | For a service bought from outside: who runs it. Exactly one of hosts and provider. |
| <span id="services-software"></span>`software` | String |  | The software it is (Paperless-ngx, Garage) - the version comes from package or version. |
| <span id="services-uses"></span>`uses` | Liste von ID aus [services](#services-1), ohne Duplikate |  | Services it works without, but degraded (new logins fail, one feature is missing). |
| <span id="services-version"></span>`version` | String |  | Version, by hand - only where there is no package to read it from. |

```json
{
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

Regeln über das Schema hinaus: genau eins von `hosts` und `provider`; `package` nur auf verwalteten Hosts und nicht zusammen mit `version`; kein `core`/`service`-Dienst auf einem `intermittent`-Host; keine harte Abhängigkeit (`dependsOn`, `via`) von einem weniger kritischen Dienst und keine im Kreis; `via` Pflicht bei `exposure` `proxy`; jeder `fqdn` nur einmal; `backup` nur bei `stateful`, `to` genau bei `restic`/`arq`. Ein `stateful`-Dienst, dessen Backups alle auf den eigenen Hosts bleiben – `storage` oben –, steht unter `gaps`.

### Ein vollständiges Beispiel

Ein gültiges Inventar mit allen Abschnitten – die Quelle der Beispiele oben, `docs/inventory-example.json`. Zum Kopieren als Anfang; `"$schema": "./inventory.schema.json"` ganz oben gibt dem Editor seine Vervollständigung.

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  },
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  },
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  },
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  },
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ]
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  },
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "ipv6": "2001:db8:1::/64",
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  },
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "medium": "ethernet",
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "medium": "wifi",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  },
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

Was `just inventory` daraus ableitet, zum Beispiel: `hosts.club-vm.site` ist `club` (geerbt von `pve`); `services.docs.upstreamHosts` ist `club-vm`, `pve`, `vps`; `providers.hoster.affects` ist `docs`, `login`, `proxy`; `costs.monthly` ist `{"EUR": 6145, "USD": 250}`, und in `costs.byMonth` trägt der November die 30,00 USD des Mail-Vertrags.

### Im Editor

`inventory.json` beginnt mit `"$schema": "./inventory.schema.json"`. Editoren, die JSON Schema lesen (VS Code, Zed, IntelliJ, Neovim mit einem JSON-Language-Server), bieten dann die Felder zur Vervollständigung an, zeigen die Beschreibungen aus den Tabellen oben beim Überfahren und unterstreichen falsche Typen, unbekannte Felder und fehlerhafte Werte schon beim Tippen. Verweise und alle Regeln zwischen Einträgen prüft erst `nix flake check` (oder `just inventory-test`).

Nach einer Änderung an `spec` in `inventory.nix`: `just inventory-schema` und `just inventory-diagram`, ein Testfall in `tests/inventory.nix` und – wenn das Beispiel das neue Feld zeigen soll – `docs/inventory-example.json`. Die Checks schlagen fehl, bis alles zusammenpasst.

## Lagekarte

Jede Maschine und jeder Dienst aus dem [Inventar](#inventar), nach Standort: oben der Anschluss jedes Standorts mit seinen Netzen, darunter die Hosts mit den Diensten, die auf ihnen laufen, ganz unten die eingekauften Dienste nach Anbieter. Ein Klick auf einen Dienst oder Host zeichnet ein, wovon er abhängt, was er nutzt, wohin er gesichert wird und worüber er erreichbar ist, und zeigt daneben seinen Eintrag; die Namen dort sind wieder anklickbar. Rechts an einem Dienst steht je Endpunkt ein Kürzel, wie er erreichbar ist: `pub` öffentlich, `prox` über einen Proxy, `mesh` nur im Mesh, `lan` nur im LAN; ein Klick darauf wählt den Dienst mit diesem Endpunkt. Ein Klick auf eine freie Stelle der Karte vergrößert sie.

<figure class="nx-labmap" data-default="mail">
<div class="stats"><div><b>7</b><span>Hosts</span></div><div><b>4</b><span>vom Flake verwaltet</span></div><div><b>5</b><span>Dienste selbst betrieben</span></div><div><b>1</b><span>eingekauft</span></div><div><b>3</b><span>Standorte</span></div><div><b>4</b><span>Anbieter</span></div></div>
<div class="nx-lm-layout">
<div class="nx-lm-map"><svg class="nx-lm-edges" aria-hidden="true"></svg>
<div class="nx-lm-sites">
<section class="site" style="flex: 1 1 200px"><div class="site-head"><div class="row"><span class="site-code">dc</span><span class="site-city">Exampleburg · Rechenzentrum · Example Hosting</span></div><div class="uplink">Example Hosting · AS64497 · RZ-Anbindung · IPv4 statisch · IPv6</div></div><div class="hosts one"><div class="host" data-hostcard="vps" tabindex="0" role="button" aria-label="Host vps"><div class="host-top"><span class="host-name">vps</span></div><div class="host-kind">VM · VPS M</div><div class="pills"><span class="pill core">core</span><span class="pill managed">Flake</span></div><div class="chips"><span class="svc stateful c-core" data-svc="login" data-host="vps"><button type="button" class="nm" title="Example IdP">Login</button><span class="x"><button type="button" class="tg" data-ep="0" title="auth.example.org · öffentlich">pub</button></span></span><span class="svc c-core" data-svc="proxy" data-host="vps"><button type="button" class="nm" title="Reverse proxy">Reverse proxy</button><span class="x"><button type="button" class="tg" data-ep="0" title="proxy.example.org · öffentlich">pub</button></span></span></div></div></div></section>
<section class="site" style="flex: 1 1 200px"><div class="site-head"><div class="row"><span class="site-code">club</span><span class="site-city">Exampletown · Hackerspace · Example hackerspace</span></div><div class="uplink">None · Kabel · IPv4 statisch · IPv6</div><div class="nets"><span class="net" title="Hackerspace LAN">198.51.100.0/24 · VLAN 10</span></div></div><div class="hosts one"><div class="host" data-hostcard="pve" tabindex="0" role="button" aria-label="Host pve"><div class="host-top"><span class="host-name">pve</span><span class=ip>198.51.100.2</span></div><div class="host-kind">Hypervisor</div><div class="pills"><span class="pill ext">gehört Example hackerspace</span></div><div class="guest"><div class="host" data-hostcard="club-vm" tabindex="0" role="button" aria-label="Host club-vm"><div class="host-top"><span class="host-name">club-vm</span></div><div class="host-kind">VM · Proxmox VM</div><div class="pills"><span class="pill managed">Flake</span></div><div class="chips"><span class="svc stateful" data-svc="docs" data-host="club-vm"><button type="button" class="nm" title="Documents">Documents</button><span class="x"><button type="button" class="tg" data-ep="0" title="docs.example.org · über Proxy">prox</button></span></span><span class="svc" data-svc="route" data-host="club-vm"><button type="button" class="nm" title="Overlay routing peer">Route into the hackerspace</button></span></div></div></div></div></div></section>
<section class="site" style="flex: 3 1 600px"><div class="site-head"><div class="row"><span class="site-code">home</span><span class="site-city">Exampletown · Zuhause</span></div><div class="uplink">Example ISP · AS64496 · Glasfaser · ↓600 ↑300 Mbit/s · IPv4 dynamisch · IPv6 /56 dyn.<br>None · LTE · IPv4 dynamisch</div><div class="nets"><span class="net" title="Home LAN">192.0.2.0/24 · DHCP router</span></div></div><div class="hosts"><div class="host" data-hostcard="router" tabindex="0" role="button" aria-label="Host router"><div class="host-top"><span class="host-name">router</span><span class=ip>192.0.2.1</span></div><div class="host-kind">Router · Example Networks R1</div><div class="pills"><span class="pill core">core</span></div></div><div class="host" data-hostcard="laptop" tabindex="0" role="button" aria-label="Host laptop"><div class="host-top"><span class="host-name">laptop</span></div><div class="host-kind">Laptop · Example Corp Book 14</div><div class="pills"><span class="pill lab">lab</span><span class="pill managed">Flake</span><span class="pill ext">zeitweise</span></div></div><div class="host" data-hostcard="nas" tabindex="0" role="button" aria-label="Host nas"><div class="host-top"><span class="host-name">nas</span><span class=ip>192.0.2.10</span></div><div class="host-kind">NAS · Example Corp NAS 4</div><div class="pills"><span class="pill managed">Flake</span></div><div class="chips"><span class="svc stateful" data-svc="storage" data-host="nas"><button type="button" class="nm" title="Example S3">S3 storage</button><span class="x"><button type="button" class="tg" data-ep="0" title="s3.example.org:3900 · nur LAN">lan</button><button type="button" class="tg" data-ep="1" title="s3-console.example.org · über Proxy">prox</button></span></span></div><div class="guest"><div class="host" data-hostcard="kvm" tabindex="0" role="button" aria-label="Host kvm"><div class="host-top"><span class="host-name">kvm</span></div><div class="host-kind">KVM</div><div class="pills"><span class="pill lab">lab</span></div></div></div></div></div></section>
<section class="site" style="flex: 1 1 100%"><div class="site-head"><div class="row"><span class="site-code">Extern</span><span class="site-city">eingekaufte und gehostete Dienste</span></div></div><div class="ext-groups"><div class="prov"><div class="prov-name">Example Mail</div><div class="chips"><span class="svc stateful" data-svc="mail"><button type="button" class="nm" title="Mail">Mail</button></span></div><div class="contract">30 USD/Jahr</div></div></div></section>
</div></div>
<div class="nx-lm-aside"><div class="box nx-lm-detail"><div class="box-title">Auswahl</div><p class="hint">Dienst oder Host anklicken, um Abhängigkeiten und Details zu sehen.</p></div><div class="box legend-box"><div class="box-title">Legende</div><div class="legend"><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-dep"/></svg>hängt ab von</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-use"/></svg>nutzt (optional)</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-bak"/></svg>Backup nach</div><div><svg width="34" height="8" aria-hidden="true"><path d="M1 4H33" class="e-via"/></svg>erreichbar über</div><div><span class="svc stateful demo"><span class="nm">Dienst</span></span> mit Daten <span class="svc demo"><span class="nm">Dienst</span></span> zustandslos</div><div class="abbr"><span class="tg">pub</span> öffentlich · <span class="tg">prox</span> über Proxy · <span class="tg">mesh</span> nur Mesh · <span class="tg">lan</span> nur LAN</div><div><span class="pill core">core</span><span class="pill service">service</span><span class="pill">lab</span><span class="pill managed">Flake</span> Kritikalität, vom Flake verwaltet</div></div><label class="toggle"><input type="checkbox" class="nx-lm-all"> Alle Beziehungen einblenden</label><button type="button" class="nx-lm-zoom">Vergrößern</button></div></div>
</div>
</figure>

Die Karte wird bei jedem Doku-Bau aus `inventory.json` erzeugt (`docs/gen-lab-map.py`) und kann deshalb nicht veralten. SSH-Host-Keys, Seriennummern und MAC-Adressen stehen nicht darin. Im PDF stehen Standorte, Hosts und Dienste ohne die Linien.

## Services

Dienste sind nach Funktion benannt, nicht nach Produkt. Es gibt drei Arten der Erreichbarkeit: direkt öffentlich, öffentlich hinter dem NetBird-Reverse-Proxy mit SSO, oder nur im Mesh.

| Name (`.homelab.example`) | App | Host | Erreichbar |
| --- | --- | --- | --- |
| `auth` | Pocket ID | zummi | öffentlich (nginx) |
| `mesh` | NetBird Management/Dashboard | grammi | öffentlich (Traefik terminiert TLS) |
| `s3.aldrin` | Garage S3-API | aldrin | öffentlich (nginx) |
| `cloud` | OpenCloud | aldrin | öffentlich (nginx), Login über Pocket ID; nicht hinter dem Reverse Proxy, dessen SSO würde die Sync-Clients aufhalten |
| `tabs` | WebDAV für floccus (rclone) | aldrin | öffentlich (nginx), ein Account mit Basic Auth ([warum](#floccus-tabs-und-lesezeichen-über-tabs)) |
| `rezepte` | Mealie | grammi | Reverse Proxy + SSO |
| `grist` | Grist | grammi | Reverse Proxy + SSO |
| `logs` | logchef | grammi | Reverse Proxy + SSO |
| `metrics` | Grafana | grammi | Reverse Proxy + SSO |
| `dash` | Grafana, nur öffentliche Dashboards | grammi | Reverse Proxy ohne Login, Traefik lässt nur die Pfade öffentlicher Dashboards durch ([warum](#grafana-öffentliche-dashboards-über-dash)) |
| `vm` / `vl` | VictoriaMetrics / VictoriaLogs UI | grammi | Reverse Proxy + SSO |
| `s3-admin` | garage-ui | aldrin | nur Mesh |
| `dokumente` | Paperless + paperless-gpt (`/paperless-gpt/`) | ursalia | im Mesh direkt; von außen über den Reverse Proxy Freigabelinks per PIN und die App per SSO ([warum](#paperless-von-außen-freigabelinks-pin-und-app-sso)) |
| `llm` | Ollama (hinter Caddy) | zorlock | nur Mesh |
| `health` | [HealthLog](https://github.com/MBombeck/HealthLog) ([`0497d60`](https://github.com/MBombeck/HealthLog/tree/0497d60a893784e709899cdb6fbdf155ef29e3e3) von Marc Bombeck) | ursalia | nur Mesh (auch die iOS-App braucht NetBird), Login nur über Pocket ID (Gruppe `healthlog_users`); eigene verschlüsselte Off-host-Kopien in Garage auf aldrin (Bucket `healthlog-backups`, 30 Tage) |
| `mqtt` | Mosquitto (Home-Assistant-Add-on) | Home Assistant (Heim-LAN, NetBird-Peer) | Port 8883, MQTT über TLS: zu Hause direkt zu HA (der Heimrouter (OPNsense) beantwortet den Namen lokal), von außen über den Reverse Proxy als TLS-Passthrough zum Peer, ohne SSO ([warum](#mqtt-von-außen-tls-passthrough-zu-home-assistant)) |
| `acme` | dns01proxy (DNS-01 für Home Assistant) | grammi | nur Mesh, Port 8446; HA löst ihn über den Heimrouter (OPNsense) auf ([warum](#mqtt-von-außen-tls-passthrough-zu-home-assistant)) |
| `doku` | Diese Dokumentation (private Fassung) | aldrin + ursalia | im Mesh nur Admin-Geräte ([warum](#private-doku-admin-geräte-heimnetz-login)), ein A-Record je Host; im Heimnetz über einen eigenen Eintrag des Routers ursalia, außer einer Deny-Liste; von außen über den Reverse Proxy eine Weiterleitung auf die öffentliche Doku, `/login` auf `doku-login` |
| `doku-login` | Diese Dokumentation (private Fassung) aus dem Internet | aldrin | über den Reverse Proxy mit SSO (Gruppe `docs-readers`), nur mit dem geheimen Header des Proxys |

**Reverse Proxy:** Traefik auf grammi besitzt Port 443. `mesh.homelab.example` terminiert es selbst, alles andere reicht es per TCP-Passthrough mit PROXY-Protokoll v2 an `netbird-proxy` weiter, das TLS und ACME (tls-alpn-01) selbst macht. Login am Proxy ist SSO gegen Pocket ID, begrenzt auf die NetBird-Gruppen der jeweiligen App; `dokumente` zusätzlich mit PIN (nur Freigabelinks). Die Dienste auf grammi erreicht der Proxy alle über den Traefik-Entrypoint `apps` (Port 8090), der Wartungsschalter und Fehlerseiten davorsetzt ([Wartungsmodus](#wartungsmodus)).

**Mesh-only-Namen:** Jeder Name ist eine eigene NetBird-DNS-Zone mit einem A-Record auf die Mesh-Adresse (192.0.2.x). Öffentliches DNS kennt sie nicht; das Zertifikat kommt per DNS-01 über deSEC.

**Querschnitt auf allen Linux-Hosts:** vmagent schickt Metriken, Vector schickt journald- und nginx-Logs an grammi. CrowdSec liest die nginx/Traefik-Logs auf den öffentlichen Hosts. restic-Backups gehen in Garage-Buckets auf aldrin, für Paperless zusätzlich append-only zu BorgBase.

## Module

Die 20 Module unter `modules/` tragen die gemeinsame Konfiguration aller Hosts; jede Datei erklärt im Kopfkommentar, warum sie so ist. Die öffentliche Fassung enthält sie anonymisiert unter `modules/` – als Referenz, nicht direkt importierbar: einige lesen `hosts/<host>/*.yaml` und setzen sops-nix voraus. Fünf haben eigene Optionen.

| Modul | Zweck | Optionen / Besonderheiten |
| --- | --- | --- |
| [auto-upgrade-git.nix](modules/auto-upgrade-git.nix) | Nächtliches `nixos-rebuild switch`, committet und pusht die neue `flake.lock` zurück ins Repo | `services.autoUpgradeGit`: `enable`, `flakeDir`, `flakeAttr`, `updateInputs`, `dates`, `allowReboot`, `rebootWindow`, `deployKeySecret`, `gitAuthorEmail`, `holdFile`, `holdCheck` |
| [log-shipping.nix](modules/log-shipping.nix) | journald- und nginx-Logs per Vector an VictoriaLogs | `services.logShipping`: `enable`, `victoriaLogsUrl` |
| [metrics-shipping.nix](modules/metrics-shipping.nix) | vmagent scrapt die lokalen Exporter und schreibt per remote_write an VictoriaMetrics | `services.metricsShipping`: `enable`, `remoteWriteUrl`, `exporterPorts` |
| [deploy-hold.nix](modules/deploy-hold.nix) | Halt für `just try`: `nixos-hold`, Metrik `nixlab_deploy_hold_since_seconds`, Warnung in der Login-Shell | auch auf cuckoosegg – [Branch vor dem Merge testen](#branch-vor-dem-merge-auf-einem-host-testen) |
| [deploy.nix](modules/deploy.nix) | Die Lab-Policy für auto-upgrade-git: GitHub-Deploy-Key, gepinnter Hostkey, Reboot-Fenster 04:00–06:00 | getrennt vom Mechanismus, damit der wiederverwendbar bleibt |
| [acme.nix](modules/acme.nix) | ACME-Defaults für jeden TLS-Host: DNS-01 gegen deSEC | Token aus `hosts/<host>/desec.yaml` (von Tofu) |
| [netbird.nix](modules/netbird.nix) | NetBird-Client im Mesh, Registrierung per Setup-Key, lokale Metriken | Setup-Key aus `hosts/<host>/netbird.yaml` (von Tofu) |
| [tailscale.nix](modules/tailscale.nix) | Gemeinsamer Tailscale-Agent | `tailscale serve` bleibt in der Host-Config |
| [ssh.nix](modules/ssh.nix) | Wer sich von wo anmelden darf: root nur über Mesh oder Tailscale | Schlüssel bleiben pro Host |
| [firewall.nix](modules/firewall.nix) | Öffentlich nur 22/80/443, Tailnet als vertrauenswürdiges Interface | |
| [crowdsec.nix](modules/crowdsec.nix) | CrowdSec-Engine und Firewall-Bouncer, Whitelist für die Lab-Hosts | Umgehungen für Fehler in den nixpkgs-Modulen, im Kopf dokumentiert |
| [networking.nix](modules/networking.nix) | ifstate-Gerüst, systemd-resolved mit DNS-over-TLS, keine Fallback-Resolver | Adressen und Routen bleiben in der Host-Config |
| [metrics.nix](modules/metrics.nix) | Prometheus-Exporter pro Host | Schutz über die Firewall statt über Bind-Adressen |
| [logging.nix](modules/logging.nix) | Begrenzt journald, das sonst bis 4 GB wächst | |
| [qemu-guest.nix](modules/qemu-guest.nix) | QEMU Guest Agent mit gesperrter RPC-Liste: Snapshots ja, Shell und Dateizugriff über den Kanal nein | |
| [nix.nix](modules/nix.nix) | Nix-Daemon, Garbage Collection, Store-Optimierung | |
| [docs-site.nix](modules/docs-site.nix) | Die private Doku-Site (Flake-Paket `docs-site`) unter `doku` im Mesh | `services.docsSite`: `enable`, `package`, `fqdn`, `allow` (Standard: das ganze Mesh; im Lab nur die Admin-Geräte aus `admin-peers.json`); auf aldrin und ursalia |
| [maintenance.nix](modules/maintenance.nix) | Wartungsmodus für nginx und Traefik: eine Flag-Datei schaltet einen Namen auf eine 503-Seite, dieselbe Seite bei 502/504 | `services.maintenance`, siehe [Wartungsmodus](#wartungsmodus) |
| [hotfixes.nix](modules/hotfixes.nix) | Paket-Hotfixes, die sich selbst abschalten und warnen, sobald nixpkgs den Fix hat | Modul-Argument `hotfix`, Overlays aus `modules/hotfixes/`, siehe [Paket per Hotfix fixen](#paket-per-hotfix-fixen) |
| [base.nix](modules/base.nix) | Locale, Konsole, Zeit und Werkzeuge zum Debuggen | |

## just-Rezepte

| Rezept | Zweck |
| --- | --- |
| `just try <host>` | Aktuellen Themen-Branch auf einen Host deployen und ihn dort halten, bis der Branch gemergt ist ([Branch vor dem Merge testen](#branch-vor-dem-merge-auf-einem-host-testen)) |
| `just try-confirm <host> [minutes] [via]` | Wie `try`, rollt aber von selbst zurück, wenn der Host nicht innerhalb der Frist erreicht und bestätigt wird ([mit automatischem Zurückrollen](#mit-automatischem-zurückrollen-just-try-confirm)) |
| `just release <host>` / `holds` | Halt ohne Merge aufheben / alle Halte anzeigen |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Host-Secrets auf dem Host editieren und zurückholen |
| `just topology` | Topologie-Dashboard neu erzeugen (sonst schlägt `nix flake check` fehl) |
| `just inventory` | Das geprüfte Inventar mit allem Abgeleiteten anzeigen ([Inventar](#inventar)) |
| `just inventory-test` | `inventory.json` prüfen, die Tests der Validierung laufen lassen, Schema auf Aktualität prüfen |
| `just inventory-schema` | `inventory.schema.json` nach einer Formatänderung neu erzeugen |
| `just inventory-diagram` | Das Diagramm aller Felder auf [Inventar-Schema](#inventar-schema) nach einer Formatänderung neu erzeugen |
| `just inventory-collect [--force] [host …]` | SSH-Host-Keys, Interfaces (MAC, Medium, Link-Local) und Hardware (Hersteller, Modell, Produkt-ID, Seriennummer) von den Geräten in `inventory.json` holen – füllt Lücken und meldet Abweichungen; `--force` übernimmt die Werte des Geräts |
| `just services [--json]` | Was die Dienste des Inventars betreiben, aus den Host-Konfigurationen: Version, Lizenz, Sprache ([Software-Sicht](#software-sicht)) |
| `just sbom [host …]` | SBOM (CycloneDX, SPDX, CSV) des laufenden Systems jedes Hosts nach `sbom/` ([Software-Sicht](#software-sicht)) |
| `just known-hosts` | `~/.ssh/known_hosts.nixlab` aus dem Inventar schreiben – für eine Workstation außerhalb dieses Repos; gusto bekommt die Schlüssel systemweit |
| `just netbird-plan` / `netbird-apply` | NetBird-Account ändern; apply schreibt auch `expected-peers.json` (committen, grammi deployen) und `admin-peers.json` (committen, aldrin und ursalia deployen) neu |
| `just netbird-proxy-certs` | Proxy-Diensten ohne Zertifikat eins holen und das Dashboard nachziehen (NetBird #7118); läuft am Ende von `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | Neue zufällige PIN für Paperless-Freigabelinks von außen (danach `netbird-apply`) bzw. aktuelle anzeigen |
| `just netbird-key <host>` | Neuer Setup-Key für einen Host, 24 h Zeit zum Deployen |
| `just netbird-import` | Tofu-State aus dem Account neu aufbauen – nur nötig, wenn auch git ihn nicht hat ([Tofu-State](#tofu-state)) |
| `just netbird-renew-token` | Jährliche Erneuerung des Service-User-Tokens |
| `just tf-state-passphrase` | Einmalig: Passphrase für die Tofu-States nach `terraform/secrets.yaml` (überschreibt nie) |
| `just github-key <host>` | Neuer GitHub-Deploy-Key für einen Host (Schlüssel per sops, Registrierung per Tofu) |
| `just github-plan` / `github-apply` | Repos und Deploy-Keys auf GitHub ändern |
| `just desec-key <host>` / `desec-verify` | deSEC-Token tauschen bzw. Scopes von jedem Host aus prüfen |
| `just nanokvm-mcp-key` | MCP-API-Key des NanoKVM Go+ verschlüsselt für ursalia ablegen (danach committen, ursalia deployen) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude-Code-Brücke zum NanoKVM Go+ auf ursalia: einmal einrichten, starten, stoppen, Zustand, Log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (Standard gusto, oder zorlock per SSH): zeigen, was ein Switch ändern würde (nvd, Homebrew entfernt/installiert), oder schalten mit Zusammenfassung – siehe [macOS-Hosts](#macos-hosts) |
| `just apps [suche] [--host h]` / `apps-list [host]` / `apps-rm <name> [host]` | Software eines Macs (`hosts/<host>/apps.json`): eine Runde aus Suchen in nixpkgs, Homebrew und App Store, Hinzufügen (nach Pin-Prüfung) und Entfernen, dann ein Switch und ein Commit; auflisten; einen Eintrag entfernen – auf gusto auch als `apps`, `apps-list`, `apps-rm` in jedem Ordner, siehe [Software auf den Macs](#software-auf-den-macs) |
| `just mac-upgrade` | Auf gusto: Homebrew-Pins aktualisieren, schalten, `brew upgrade`, NetBird-Version neben dem Mesh-Pin; `flake.lock` committen |
| `just gc <host>` | Store-Generationen älter als 7 Tage löschen |
| `just docs` | Diese Doku bauen: private PDFs (de/en) und die anonymisierte öffentliche Fassung (README, PDFs, Site-Quellen, Module) in `public-docs/` (Clone von `nixlab-docs`, gitignored), dort committet und gepusht; GitHub baut daraus die Site |
| `just docs-serve` | Private Site mit echten Werten lokal bauen und unter `http://127.0.0.1:8000` zeigen |

Rezepte, die sops brauchen, bekommen den age-Key der Workstation über `SOPS_AGE_KEY_CMD` aus 1Password. Auf gusto setzt home-manager die Variable, und `op` entsperrt über die 1Password-App (Touch ID); sops, tofu und age kommen aus der devShell (direnv im Checkout). Ohne diese Einrichtung:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```

## Troubleshooting

- Nach einem `nixos-rebuild` sagt `systemctl --failed` nichts über die Vergangenheit – der Switch räumt Failed-States ab. Stattdessen `journalctl -u <unit>`.
- NetBird down, Tailscale noch da: `NIXLAB_DOMAIN=example-tailnet.ts.net` vor das Rezept setzen.
- Tofu-Rezepte verweigern den Lauf gegen leeren State, damit keine zweite `servers`-Gruppe oder Token-Garnitur entsteht.
- WLAN auf ursalia: `iw dev wlo1 link` zeigt Band, Signal und PHY-Modus. Das 5-GHz-Netz des Routers liegt auf einem DFS-Kanal mit 300 TU Beacon-Intervall, ein einzelner Scan kann es verpassen; Band, Signal, Raten und PHY-Modus gehen auch an VictoriaMetrics (node_exporter-Collector `wifi` plus `wifi_link_*`), Grafana-Dashboard „Homelab / WLAN“.
- Nach einem Netzwechsel kann NetBird minutenlang an einem toten P2P-Weg festhalten und trotzdem `Connected` zeigen (gesehen auf ursalia, 2026-10-19). Abhilfe: `systemctl restart netbird-mesh` auf dem Host, notfalls über Tailscale.
- Ein Proxy-Dienst hängt im NetBird-Dashboard bei „Issuing certificate…“ oder liefert von außen einen TLS-Fehler („internal error“): `just netbird-proxy-certs` – fragt die Namen ohne Zertifikat von außen ab und startet `netbird-proxy` auf grammi neu (NetBird-Diskussion #7118). Läuft auch am Ende von `just netbird-apply`.

## Konventionen

- Pro Thema ein eigener Git-Worktree (`.worktrees/<thema>`), nach Abschluss entfernen und Branch löschen. Tofu-State bleibt dabei immer im Haupt-Checkout (verschlüsselt und committet, siehe [Tofu-State](#tofu-state)).
- Erst planen, dann nach Freigabe umsetzen.
- Subdomains nach Funktion (`rezepte`, nicht `mealie`).
- Neue Webdienste auf grammi nutzen PostgreSQL statt SQLite.
- Dual-Stack, wo immer möglich.
- Kommentare im Code erklären das *Warum*, inklusive der Fehler, die zu einer Entscheidung geführt haben, mit Datum.
- Code-Kommentare, Commit-Messages und Changelogs auf Englisch; die Projektdoku gibt es auf Deutsch und Englisch.
- Die Doku-Site lädt nichts von Dritten: Schriften und glightbox liegen in der Site selbst (`docs/assets.nix`), statt von Google Fonts bzw. unpkg.com zu kommen. Grund: DSGVO und eine private Doku, die ohne Internet funktioniert.
- Infrastruktur, die vor allem eine Rolle an einem Ort erfüllt (Gateways, Access Points, Switches), heißt `<aufgabe>-<standort>`: `gw-hq`, `ap-flur`. Die Aufgabe steht vorn, damit Geräte gleicher Rolle in Listen und Dashboards nebeneinander stehen; der Standort steht ohnehin im Inventar. Eigene Server behalten ihre Gummibären-Namen.
- Interface-Namen haben unter Linux höchstens 15 Zeichen. Bei `tun-<standort>-uplink<n>` (`tun-hq-uplink1`) heißt das: Standortkürzel mit höchstens drei Zeichen.
- Wann immer ein Ablauf, ein Aufbau oder ein Zusammenhang sich als Bild schneller erfassen lässt als als Text (Trafficflüsse, Abhängigkeiten, Schichten), bekommt die Seite ein Diagramm, und zwar immer zoom- und klickbar wie das Inventar-Schema: Kästen springen zu ihrem Abschnitt, ein Klick anderswo vergrößert. Kein Diagramm als `<img>` oder als reines Bild ohne Sprünge, wenn die Seite Abschnitte hat, auf die es zeigen kann.
- Diagramme in der Doku sind Inline-SVG in `<figure class="nx-diagram">` (viewBox 680 breit, ohne `width`/`height`), damit Kästen auf Abschnitte der Seite verlinken können und ein Klick anderswo auf das Diagramm es vergrößert (in der Lightbox der Website): `<a data-target="<Überschrift-ID>" tabindex="0" role="link">` um den Kasten, ohne `href` – mit `href` wirft das Theme bei SVG-Links einen Fehler, und `site/common/javascripts/diagrams.js` übernimmt den Sprung (Klick und Enter). Keine Marker für Pfeilspitzen, sondern Pfade in der Linienfarbe, weil WeasyPrint `context-stroke` im PDF nicht kann. Helle Farben stehen im `<style>` des SVG, das Dunkel-Schema in `site/common/stylesheets/diagrams.css`, das nur die Website lädt. Prüfen mit `just docs-serve` (beide Farbschemata) und im PDF.
- Ausnahme ist die [Lagekarte](#lagekarte): HTML statt SVG, erzeugt aus `inventory.json` (`docs/gen-lab-map.py`), weil sie jeden Host und Dienst zeigt und nicht veralten darf. Klickbar heißt dort: Ein Klick auf einen Dienst oder Host wählt ihn aus und zeichnet seine Beziehungen ein (`site/common/javascripts/lab-map.js`); ein Klick auf eine freie Stelle vergrößert sie in der Lightbox. Im PDF steht sie ohne Linien (`doc.css`).
- Jede Seite der Site gibt es auch als reines Markdown, unter ihrem Quellpfad (`how-to/new-host.md` neben `how-to/new-host/`), mit dem Inhaltsverzeichnis `llms.txt` und allen Seiten in einer Datei `llms-full.txt` ([llms.txt](https://llmstxt.org)) – Englisch im Root, Deutsch unter `de/`. Für Sprachmodelle: Markdown kostet sie weit weniger Token als die HTML-Seiten. `docs/gen-llms.py` schreibt sie nach dem Zensical-Build, auf beiden Sites. Ein Diagramm wird dort durch sein `aria-label` ersetzt, deshalb braucht jedes Diagramm eines, das in einem Satz sagt, was es zeigt; die Lagekarte wird zu ihrem JSON-Datenblock. Die Beschreibung in `llms.txt` ist der erste Satz des ersten Absatzes der Seite.

## Offene Punkte

- [ ] NetBird-Provider: den Build aus PR #215 (IPv6-Overlay) wieder durch die Registry-Version ersetzen, sobald er veröffentlicht ist ([Exit-Nodes & IPv6](#provider-aus-pr-215))
- [ ] Home Assistant: prüfen, ob `trusted_proxies`/`trusted_networks` nur `192.0.2.0/24` kennen, und `2001:db8:203:0::/64` ergänzen (liegt nicht im Repo)
- [ ] Upstream-PRs im NetBird-Provider (#247 `direct_upstream`/Cluster-Targets, #248 `crowdsec_mode`); danach Proxy-Targets auf grammi auf `localhost` umstellen
- [ ] Tailscale von den Servern entfernen, sobald nichts mehr darauf angewiesen ist
- [ ] Grafana-Alerting (Kontaktpunkt fehlt noch) für SMART, fwupd, Paperless, NetBird Soll ≠ known, WLAN von ursalia (nicht verbunden, hängt auf 2,4 GHz, schwaches Signal)
- [ ] Update-Benachrichtigung für die von Hand gepinnten Inputs (NetBird, Pocket ID)
- [ ] Root-Passwörter deklarativ über sops
- [ ] Host-Liste an einer Stelle führen statt in `flake.nix`, den Tofu-Modulen und `justfile`
- [ ] gusto: nach dem ersten Switch prüfen, ob sich die NetBird-App selbst aktualisiert (oder dem Auto-Update im Dashboard folgt), und das abschalten, damit die Version nur aus `netbirdio-tap` kommt
- [ ] gusto: Standard-Git-Adresse `admin@homelab.example` statt `mail@admin.org`, zusammen mit einer neuen Ordnung von `~/Projects`
- [ ] Inventar: ein Feld für den DNS-Namen eines Geräts (arkkvm antwortet als `arkkvm01`, heute nur in seiner Notiz) und öffentliche Adressen der verwalteten Hosts – dann leitet `hosts/gusto/ssh.nix` seine Ausweichnamen daraus ab
- [ ] Doku-Site: `<link rel="alternate" type="text/markdown">` in jeder HTML-Seite, das auf ihre Markdown-Fassung zeigt (`docs/gen-llms.py`) – braucht einen Theme-Override, deshalb erst, wenn Zensical bei 1.0 ist
