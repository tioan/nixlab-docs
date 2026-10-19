# Schlüssel rotieren

Was sich wie erneuern lässt und was danach zu tun ist. Die Rezepte ersetzen den alten Schlüssel jeweils sofort – deshalb direkt danach committen und deployen.

| Schlüssel | Rezept | Danach | Wann |
| --- | --- | --- | --- |
| NetBird-Setup-Key eines Hosts | `just netbird-key <host>` | Deploy innerhalb von 24 h | bei Neuinstallation oder verlorenem Client-State |
| deSEC-Token eines Hosts | `just desec-key <host>` | sofort deployen, dann `just desec-verify` | bei Verdacht, sonst nie |
| GitHub-Deploy-Key eines Hosts | `just github-key <host>` | commit + deploy | bei Verdacht |
| Tofu-Token für NetBird (Service-User `terraform`) | `just netbird-renew-token` | – | jährlich |
| App-Secrets | `just secrets <host>` (siehe [Secrets eintragen](secrets.md)) | deploy | bei Verdacht |

## SSH-Host-Key (= sops-Empfänger)

Der age-Schlüssel eines Hosts ist aus seinem SSH-Host-Key abgeleitet. Ein neuer Host-Key heißt deshalb auch:

1. Neuen age-Schlüssel per `ssh-to-age` ableiten und in `.sops.yaml` ersetzen.
2. Die Dateien des Hosts mit `sops updatekeys` neu verschlüsseln – dafür braucht es einen Schlüssel, der sie noch lesen kann (der alte Host-Key oder `admin`).
3. Committen und deployen, bevor der alte Key verschwindet.

## Nach einer Rotation

- Alte Schlüssel beim Gegenüber löschen (GitHub, deSEC und NetBird erledigt das Rezept per Tofu).
- `just docs`, falls sich Namen oder Abläufe geändert haben.
