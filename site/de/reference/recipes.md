# just-Rezepte

| Rezept | Zweck |
| --- | --- |
| `just try <host>` | Aktuellen Themen-Branch auf einen Host deployen und ihn dort halten, bis der Branch gemergt ist ([Branch vor dem Merge testen](../how-to/try-branch.md)) |
| `just try-confirm <host> [minutes] [via]` | Wie `try`, rollt aber von selbst zurück, wenn der Host nicht innerhalb der Frist erreicht und bestätigt wird ([mit automatischem Zurückrollen](../how-to/try-branch.md#confirm)) |
| `just release <host>` / `holds` | Halt ohne Merge aufheben / alle Halte anzeigen |
| `just test-restic-verified` | Erzwungene Backup-Fehler in einer Wegwerf-VM auf ursalia ([Wann ein Backup als erfolgreich gilt](../explanation/monitoring.md#backup-verified)) |
| `just test-gw-remote-private-users` | gw-remote im User-Namespace in einer Wegwerf-VM auf ursalia: OpenVPN, nftables, WireGuard im Container, dann der Switch zurück ohne |
| `just test-forwarding` | Der Forward-Filter in Wegwerf-VMs auf ursalia: nichts von einem Nachbarn ins Overlay oder auf eine Container-Bridge ([Exit-Nodes](../explanation/secrets-network-access.md)) |
| `just forward-probe <host>` | Live-Prüfung auf einem routenden Host: ein Namespace-Nachbar darf das Mesh nicht erreichen; nur zur Laufzeit, räumt auf |
| `just restore-test <host> [isolation]` | grammi oder zummi aus restic in eine Wegwerf-VM ohne Netz auf ursalia zurückholen und die RTO messen ([Restore testen](../how-to/restore-test.md)) |
| `just check <host>` | `git pull` + `nixos-rebuild dry-activate` |
| `just secrets <host>` / `pull-secrets <host>` | Host-Secrets auf dem Host editieren und zurückholen |
| `just topology` | Topologie-Dashboard neu erzeugen (sonst schlägt `nix flake check` fehl) |
| `just inventory` | Das geprüfte Inventar mit allem Abgeleiteten anzeigen ([Inventar](inventory.md)) |
| `just inventory-test` | `inventory.json` prüfen, die Tests der Validierung laufen lassen, Schema auf Aktualität prüfen |
| `just inventory-schema` | `inventory.schema.json` nach einer Formatänderung neu erzeugen |
| `just inventory-diagram` | Das Diagramm aller Felder auf [Inventar-Schema](inventory-schema.md) nach einer Formatänderung neu erzeugen |
| `just inventory-collect [--force] [host …]` | SSH-Host-Keys, Interfaces (MAC, Medium, Link-Local) und Hardware (Hersteller, Modell, Produkt-ID, Seriennummer) von den Geräten in `inventory.json` holen – füllt Lücken und meldet Abweichungen; `--force` übernimmt die Werte des Geräts |
| `just services [--json]` | Was die Dienste des Inventars betreiben, aus den Host-Konfigurationen: Version, Lizenz, Sprache ([Software-Sicht](inventory.md#software)) |
| `just sbom [host …]` | SBOM (CycloneDX, SPDX, CSV) des laufenden Systems jedes Hosts nach `sbom/` ([Software-Sicht](inventory.md#software)) |
| `just wifi-qr [ssid]` | Ein WLAN von gruffi: SSID, PSK, Verschlüsselung und ein QR-Code zum Verbinden, aus `openwrt/gruffi/uci.nix` und dessen `secrets.yaml` (gibt den PSK aus); ohne SSID die Liste der WLANs |
| `just known-hosts` | `~/.ssh/known_hosts.nixlab` aus dem Inventar schreiben – für eine Workstation außerhalb dieses Repos; gusto bekommt die Schlüssel systemweit |
| `just netbird-plan` / `netbird-apply` | NetBird-Account ändern; apply schreibt auch `expected-peers.json` (committen, grammi deployen) und `admin-peers.json` (committen, aldrin und ursalia deployen) neu |
| `just netbird-proxy-certs` | Proxy-Diensten ohne Zertifikat eins holen und das Dashboard nachziehen (NetBird #7118); läuft am Ende von `netbird-apply` |
| `just dokumente-share-pin` / `dokumente-share-pin-show` | Neue zufällige PIN für Paperless-Freigabelinks von außen (danach `netbird-apply`) bzw. aktuelle anzeigen |
| `just netbird-key <host>` | Neuer Setup-Key für einen Host, 24 h Zeit zum Deployen – ein gezieltes `tofu apply` nur dieses Keys; Tofu zeigt den Plan und fragt vorher, wie bei jedem `netbird-key*`-Rezept |
| `just netbird-key-techo5` | Setup-Key für ein TECHO5-Gerät (Echo Show 8) in die Zwischenablage des Macs, nie ausgegeben; 24 h gültig, Schritte in `terraform/netbird/techo5.tf` |
| `just netbird-import` | Tofu-State aus dem Account neu aufbauen – nur nötig, wenn auch git ihn nicht hat ([Tofu-State](../explanation/nixos-opentofu.md#state)) |
| `just netbird-renew-token` | Service-User-Token erneuern (90 Tage gültig; Alarm NetbirdTokenExpiring drei Wochen vorher) |
| `just tf-state-passphrase` | Einmalig: Passphrase für die Tofu-States nach `terraform/secrets.yaml` (überschreibt nie) |
| `just tf-state-rekey` | Neue zufällige State-Passphrase, alle States damit neu verschlüsselt und mit `terraform/secrets.yaml` in einem Commit; im Haupt-Checkout auf main, danach pushen. Die alten Chiffrate bleiben in der git-Historie |
| `just telemetry-credentials [user]` | Passwörter für grammis Metrik-/Log-Eingang (vmauth, ein Benutzer pro Absender in `hosts/grammi/telemetry-ingest.json`): ergänzt fehlende, oder ein neues für `user`; landet in `hosts/grammi/telemetry-ingest.yaml` und in der `telemetry.yaml` des Absenders, wird nie ausgegeben |
| `just github-key <host>` | Neuer GitHub-Deploy-Key für einen Host (Schlüssel per sops, Registrierung per Tofu) |
| `just github-plan` / `github-apply` | Repos und Deploy-Keys auf GitHub ändern |
| `just garage-plan` / `garage-apply` | Buckets, Keys und Rechte in Garage auf aldrin ändern (`terraform/garage`) |
| `just aldrin-backup-secrets` | Den Garage-Schlüssel des Buckets `aldrin-backups` aus dem Tofu-State und ein neues Repository-Passwort nach `hosts/aldrin/backup.yaml` schreiben – einmal, nach `garage-apply` |
| `just data-backup-secrets <host>` | Dasselbe für den Bucket `<host>-data-backups` nach `hosts/<host>/backup-data.yaml` (`modules/restic-data.nix`) – einmal pro Host, nach `garage-apply` |
| `just garage-admin-token` | Garages Admin-Token per SSH von aldrin nach `terraform/secrets.yaml` kopieren – einmal, und wieder nach jeder Rotation |
| `just desec-key <host>` / `desec-verify` | deSEC-Token tauschen bzw. Scopes von jedem Host aus prüfen |
| `just desec-ddns-key` | dyndns-Token des Heimanschlusses (nur dessen A und AAAA) nach `openwrt/gruffi/secrets.yaml` |
| `just gruffi-ddns-install` | Den dyndns-Updater bis zum nächsten Image auf das laufende gruffi bringen (von gusto, LAN oder Mesh) |
| `just desec-names` | `terraform/desec-tokens/acme-names.json` aus der Flake neu schreiben (Namen, die jeder Token schreiben darf); danach `desec-apply` |
| `just nanokvm-mcp-key` | MCP-API-Key des NanoKVM Go+ verschlüsselt für ursalia ablegen (danach committen, ursalia deployen) |
| `just nanokvm-cert` | Selbstsigniertes Zertifikat des NanoKVM Go+ so holen, wie ursalia es sieht, und nach dem Vergleich pinnen (danach committen, ursalia deployen) |
| `just kvm-bridge setup\|start\|stop\|status\|log` | Claude-Code-Brücke zum NanoKVM Go+ auf ursalia: einmal einrichten, starten, stoppen, Zustand, Log |
| `just mac-diff [host]` / `mac-switch [host]` | Macs (Standard gusto, oder zorlock per SSH): zeigen, was ein Switch ändern würde (nvd, Homebrew entfernt/installiert), oder schalten mit Zusammenfassung – siehe [macOS-Hosts](../explanation/macos-hosts.md) |
| `just apps [suche] [--host h]` / `just apps install\|uninstall <name>…` / `apps-list [host]` / `apps-rm <name> [host]` | Software eines Macs (`hosts/<host>/apps.json`): eine Runde aus Suchen in nixpkgs, Homebrew und App Store, Hinzufügen (nach Pin-Prüfung) und Entfernen, dann ein Switch und ein Commit; exakte Namen wie brew installieren oder deinstallieren; auflisten; einen Eintrag entfernen – auf gusto auch als `apps`, `apps-list`, `apps-rm` in jedem Ordner, siehe [Software auf den Macs](../how-to/software.md) |
| `just mac-upgrade` | Auf gusto: Homebrew-Pins aktualisieren, schalten, `brew upgrade`, NetBird-Version neben dem Mesh-Pin; `flake.lock` committen |
| `just container-bump <host> <name> [tag]` | Container-Image auf den Digest des neuesten Release-Tags (oder des angegebenen) in `hosts/<host>/container-images.json` pinnen; dann committen und deployen ([Container-Image aktualisieren](../how-to/container-images.md)) |
| `just gc <host>` | Nächtliche Garbage Collection jetzt starten (behält die letzten 10 Generationen) |
| `just docs` | Diese Doku bauen: private PDFs (de/en, nur lokal, gitignored) und die anonymisierte öffentliche Fassung (README, PDFs, Site-Quellen, Module) in `public-docs/` (Clone von `nixlab-docs`, gitignored), dort committet und gepusht; GitHub baut daraus die Site |
| `just docs-serve` | Private Site mit echten Werten lokal bauen und unter `http://127.0.0.1:8000` zeigen |

Rezepte, die sops brauchen, bekommen den age-Key der Workstation über `SOPS_AGE_KEY_CMD` aus 1Password. Auf gusto setzt home-manager die Variable, und `op` entsperrt über die 1Password-App (Touch ID); sops, tofu und age kommen aus der devShell (direnv im Checkout). Ohne diese Einrichtung:

```bash
eval $(op signin) && export SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"' && just netbird-plan
```
