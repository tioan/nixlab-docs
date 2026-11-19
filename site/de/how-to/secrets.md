# Secrets eintragen

App-Passwörter, OIDC-Clients und Ähnliches liegen in `hosts/<host>/secrets.yaml`, verschlüsselt für den Host und den Recovery-Key `admin`. Das MacBook kann diese Dateien nicht entschlüsseln – deshalb wird auf dem Host editiert (Hintergrund: [Secrets, Netzwerk & Zugriff](../explanation/secrets-network-access.md)).

## Ablauf

1. `just sync <host>` – sonst liegt auf dem Host ein veralteter Stand von `secrets.yaml`, und `pull-secrets` holt ihn zurück ins Repo.
2. `just secrets <host>` – öffnet sops auf dem Host (mit dessen Host-Key, ohne 1Password-Anmeldung) und holt das Ergebnis danach per `pull-secrets` ins Repo.
3. Werte immer in Anführungszeichen: `key: "wert"`, einfache Anführungszeichen, wenn der Wert `"` oder `\` enthält. Ein unquotierter Wert kann von YAML als Zahl oder Bool gelesen werden; sops-nix bricht dann `setupSecrets` ab und **kein** Secret dieser Generation wird installiert.
4. Die NixOS-Seite (`sops.secrets."<name>"`) im Host-Modul ergänzen, committen, deployen: `just ship <host> "<nachricht>"`.

## Was nicht von Hand editiert wird

| Datei | Erzeugt von |
| --- | --- |
| `hosts/<host>/netbird.yaml` | `just netbird-key <host>` |
| `hosts/<host>/desec.yaml` | `just desec-key <host>` |
| `hosts/<host>/github.yaml` | `just github-key <host>` |
| `terraform/*/secrets.yaml` | sops auf dem MacBook mit dem Workstation-Key aus 1Password |

Alles, was auf dem MacBook sops braucht, läuft mit vorangestellter Anmeldung – siehe [just-Rezepte](../reference/recipes.md).

## Ein Rezept schreiben, das ein Secret anfasst

Die Befehlszeile eines Prozesses sieht jeder auf dem Rechner (`ps`), seine Umgebung derselbe Benutzer. Ein Secret steht deshalb nie in den Argumenten eines Kindprozesses und nie in einer Umgebungsvariable, die für ihn gesetzt wird: an `jq` über eine Pipe (`printf '%s' "$v" | jq -Rs …` oder `--rawfile k <(printf '%s' "$v")` – `printf` ist ein Shell-Builtin, kein eigener Prozess), an `curl` als Header-Datei (`-H @<(printf 'Authorization: Token %s' "$t")`) und Body-Datei (`--data-binary @<(…)`), an `sops` mit `set --value-stdin` oder `scripts/sops-write.sh`, an einen entfernten Host über stdin (nixlab#395, nixlab#401).
