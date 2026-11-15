# Restore testen

Ein Backup ist nur so gut wie der letzte Restore, der funktioniert hat. `just restore-test <host>` holt grammi oder zummi aus dem restic-Backup in eine Wegwerf-VM auf ursalia zurück und misst, wie lange das dauert – von der leeren Disk, bis die Dienste antworten. Es braucht nichts als dieses Repository und den Recovery-Key `admin`, genau wie nach dem echten Verlust des Hosts.

## Ausführen { #run }

Aus einem Checkout, in einem Terminal, in dem `op` angemeldet ist (`op whoami`; sonst `eval "$(op signin)"`):

```bash
just restore-test grammi isolation
just restore-test grammi
just restore-test zummi
```

- `isolation` ist der Probelauf: Die VM bootet und muss beweisen, dass sie nichts erreicht. Kein Secret ist beteiligt. Zuerst laufen lassen, wenn sich [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix) geändert hat.
- Ohne Modus ist es der Restore. 1Password fragt gleich am Anfang nach dem `admin`-Key (`op://<vault>/<item>/password`, andere Referenz per `NIXLAB_ADMIN_AGE_KEY`).
- Etwa zwei Minuten pro Host. Wiederholen, wenn sich Backup-Pfade, Datenbanken oder das Datenverzeichnis eines Dienstes ändern, sonst alle paar Monate.

## Was passiert { #flow }

1. **Build:** `lib.restoreTest.<host>` – die eigene Konfiguration des Hosts plus [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix) – wird auf ursalia als QEMU-VM gebaut.
2. **T0:** Die VM startet mit leerer Disk. Ihre Dienste kommen leer hoch oder scheitern an fehlenden Secrets, wie nach einer Neuinstallation.
3. **Während sie bootet**, auf ursalia: Der `admin`-Key entschlüsselt `restic_password` und den S3-Key aus `hosts/<host>/secrets.yaml` des Repositorys; restic stellt den neuesten Snapshot wieder her. Der `admin`-Key wird gleich danach gelöscht.
4. **Isolation:** Die VM darf weder ursalia noch das Internet noch das S3 auf aldrin erreichen, und NetBird, Tailscale und die restic-Timer dürfen nicht laufen – geprüft, bevor irgendein Secret in die VM kommt. Die Prüfung beweist sich selbst am eigenen sshd der VM.
5. **Secrets:** Der zurückgeholte SSH-Host-Key muss zu `inventory.json` passen; in der VM entschlüsselt sops-nix damit dann jedes Secret des Hosts.
6. **Daten:** grammi – frischer Postgres-Cluster, `pg_dumpall`-Dump eingespielt, Zustand von mealie, Grist, Grafana, logchef und NetBird an Ort und Stelle. zummi – die pocket-id-Datenbank aus der konsistenten `.backup`-Kopie und der Let's-Encrypt-Account.
7. **Prüfungen:** Jeder Dienst muss per HTTP antworten; die JWKS von pocket-id muss einen Schlüssel enthalten (beweist, dass der Encryption-Key zur Datenbank passt). Dann Anzahlen (User, Peers, Dokumente, OIDC-Clients) in der VM neben denselben Anzahlen auf dem echten Host – dort nur lesend.
8. **Aufräumen:** VM und tmpfs werden gelöscht. Stirbt das Rezept mittendrin, beendet sich die VM nach 2 h selbst, und ein Timer löscht das tmpfs nach 3 h.

## Isolation { #isolation }

Die VM fährt die echte Konfiguration des Hosts mit echten Secrets. Sicher ist das nur, weil sie kein einziges Paket verschicken kann: QEMUs User-Netz mit `restrict=on` (`virtualisation.restrictNetwork`). Der einzige Weg hinein ist SSH auf dem Loopback von ursalia, mit einem Schlüssel, den es nur für diesen Lauf gibt. Ihre Disk, der zurückgeholte Host-Key und jedes entschlüsselte Secret liegen unter `/run/restore-test/<host>` auf ursalia, einem tmpfs – sie berühren nie eine Disk. Der Hostname bleibt der echte, weil die Module daran die sops-Dateien festmachen; ohne Netz taucht er nirgends auf.

## Ergebnis 2026-11-02 { #result }

| | grammi | zummi |
| --- | --- | --- |
| Build (aus dem Cache) | 17–24 s | 14–20 s |
| VM läuft | 12 s | 13 s |
| Backup geholt | 2 s (65,7 MiB) | 2 s (5,2 MiB) |
| Secrets entschlüsselt | 22 s (29/29) | 19 s (13/13) |
| Daten am Platz | 29 s | 48 s |
| **RTO: Dienste antworten** | **38 s** | **48 s** |
| Anzahlen wiederhergestellt / live | NetBird-Peers 15/15, User 6/6; mealie-User 3/3; Grafana-User 3/3; Grist-Dokumente 6/6 | User 4/4, OIDC-Clients 13/13, ACME-Dateien 3/3 |

Nicht gemessen: eine Ersatzmaschine mieten, NixOS darauf installieren, DNS umstellen. Die RTO oben ist der Teil danach.

## Was der Test gefunden hat { #gaps }

1. **Im zummi-Backup war keine pocket-id-Datenbank** – in keinem der 22 Snapshots vom 2026-08-10 bis 2026-11-02. Das nicht verankerte Exclude `"*.db"` traf auch die `.backup`-Kopie. Am selben Tag behoben (auf das Datenverzeichnis verankert).
2. **grist braucht pocket-id zum Start** (OIDC-Discovery bei `auth.homelab.example`): Sind grammi und zummi beide weg, kommt zummi zuerst zurück.
3. **netbird-server braucht `pkgs.netbird.io` zum Start** – er fragt jedes Mal nach der aktuellen GeoLite-Datei, obwohl die Dateien im Backup sind.
4. **Nur numerische Besitzer:** restic hält UIDs, keine Namen, und `/var/lib/nixos` (die UID-Zuordnung) ist in keinem Backup. Ein neu installierter Host vergibt UIDs neu, deshalb chownt ein Restore die Dateien jedes Dienstes nach Namen (der Test macht das).
5. **Wohin die pocket-id-Datenbank gehört** (`data/` im Arbeitsverzeichnis), steht in keinem Backup; die Kopie behält nur ihren Dateinamen.
