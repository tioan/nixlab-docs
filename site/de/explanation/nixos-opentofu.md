# NixOS & OpenTofu

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

## Die Berührungspunkte { #touch-points }

### NetBird-Setup-Key { #netbird-setup-key }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/netbird.yaml` | `just netbird-key <host>` (`tofu output setup_keys` → `sops encrypt`) | `modules/netbird.nix` (`sopsFile`) | Einmal-Setup-Key, 24 h gültig |

Der Ablauf für einen neuen Host: Tofu legt den Setup-Key an, `just netbird-key` schreibt ihn verschlüsselt für genau diesen Host (age-Key aus seinem SSH-Host-Key) nach `hosts/<host>/netbird.yaml`, Commit, Deploy innerhalb von 24 h. Der Host registriert sich beim Start selbst; Peers selbst verwaltet Tofu nicht, es findet sie per `data "netbird_peer"` über den Namen.

### deSEC-Token { #desec-token }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `hosts/<host>/desec.yaml` | `just desec-key <host>` (`tofu output acme_tokens` → `sops encrypt`) | `modules/acme.nix` (`sopsFile`) | deSEC-Token nur für TXT-Records, VMs auf ihre IP gepinnt |

### Soll- und Admin-Peers { #peers }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Tofu → NixOS | `terraform/netbird/expected-peers.json` | `just netbird-apply` (`tofu output expected_peers`, aus den Policies in `expected-peers.tf` berechnet) | `hosts/grammi/netbird-expected-peers.nix` (`builtins.readFile`) | Soll-Anzahl NetBird-Peers je Host als Metrik `netbird_expected_peers`, im NetBird-Dashboard neben der echten Network Map (z. B. aldrin 6, grammi 8) |
| Tofu → NixOS | `terraform/netbird/admin-peers.json` | `just netbird-apply` (`tofu output admin_peers`, aus der Gruppe `admin-workstations`, `admin-peers.tf`) | `flake.nix` (`builtins.readFile`, Option `services.docsSite.allow`) | Mesh-Adressen der Admin-Geräte (v4 und v6 je Gerät) – wer die private Doku lesen darf |

### proxy-services.json { #proxy-services }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| gemeinsam | `hosts/grammi/proxy-services.json` | von Hand | `terraform/netbird/reverse-proxy.tf` (`jsondecode(file(...))`) und `topology.nix` | Name → App, Port, Gruppen der Reverse-Proxy-Dienste |

### GitHub-Deploy-Key { #deploy-key }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| Repo → beide | `hosts/<host>/github.yaml` + `github-deploy.pub` | `just github-key <host>` (`ssh-keygen` → `sops encrypt`) | privat: `modules/deploy.nix` (`sopsFile`); öffentlich: `terraform/github` (`file(...)`) | Deploy-Key für `/etc/nixos`; Tofu sieht nur den öffentlichen Teil |

### NixOS → Tofu { #nixos-to-tofu }

| Richtung | Datei | Erzeugt von | Gelesen von | Inhalt |
| --- | --- | --- | --- | --- |
| NixOS → Tofu | NetBird-Server auf grammi | `hosts/grammi/netbird.nix` | Provider über `https://mesh.homelab.example` | Die API, gegen die Tofu überhaupt erst läuft |
| NixOS → Tofu | Bootstrap-Tokens | `just netbird-setup-owner`, `netbird-proxy-token` (SSH auf grammi, Server-API) | `terraform/netbird/secrets.yaml` bzw. `hosts/grammi/netbird-proxy.yaml` | Owner-PAT, Proxy-Token |

## Tofu-State { #state }

Jedes Modul hat genau eine State-Datei im Haupt-Checkout (`terraform/<modul>/<name>.tfstate`), auch wenn ein Rezept aus einem Worktree läuft. Sie hält Setup-Keys und Tokens und ist deshalb mit OpenTofus State-Verschlüsselung verschlüsselt (AES-GCM, Schlüssel per PBKDF2) und **committet**. Die Passphrase ist `tf_state_passphrase` in `terraform/secrets.yaml`, per sops für den Workstation- und den Admin-Key verschlüsselt, eine für alle Module. `terraform/lib.sh` baut daraus `TF_ENCRYPTION`, die Passphrase steht nie in einer Datei. Rezepte, deren Tofu-Aufruf den State geändert hat, committen genau diese Datei sofort danach (andere gestagte Änderungen bleiben unberührt); pushen bleibt Handarbeit. Ein Klartext-State wird nie committet – `tf_init` und der Commit verweigern ihn.

**Wiederherstellen** nach verlorener Workstation: Repo klonen, sops-Key einrichten (siehe [Rezepte](../reference/recipes.md)), fertig – die Rezepte lesen den State aus dem Checkout. Ohne Workstation-Key entschlüsselt der Admin-Recovery-Key `terraform/secrets.yaml`. `just netbird-import` braucht es nur noch, wenn auch git den State nicht hat. Seit 2026-10-24; davor war der State gitignored und lag nur auf der Workstation (am 2026-10-22 nur noch im Time-Machine-Backup des alten MacBooks).

## Was bewusst nicht verdrahtet ist { #not-wired }

- **Keine gemeinsame Host-Liste.** Hosts stehen dreimal: `nixosConfigurations` in `flake.nix`, `local.hosts` in den Tofu-Modulen und `hosts :=` im `justfile`. Ein neuer Host muss an allen drei Stellen eingetragen werden.
- **Kein terranix / kein Tofu im Nix-Build.** Tofu läuft nur auf der Workstation; der State liegt verschlüsselt im Repo ([Tofu-State](#state)), und Nix wertet ihn nie aus.
- **Kein Provisioning der Maschinen.** Die VMs werden beim Anbieter von Hand angelegt, ursalia/cuckoosegg nach `docs/install-*.md`.
- **Öffentliches DNS** liegt in DNSControl (eigenes Repo, nur per Symlink eingebunden), nicht in Tofu.

Die Grenze ist also: Was Nix aus dem Repo heraus deterministisch bauen kann, macht Nix. Was nur einmal per API erzeugt wird und ein Geheimnis zurückgibt, macht Tofu – und übergibt es verschlüsselt als Datei.
