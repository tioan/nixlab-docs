# Container-Image aktualisieren

Die wenigen Dienste, die als Podman-Container laufen (auf ursalia: Bambuddy, HealthLog, der ESPHome-Builder), ziehen ihre Images per Digest, nicht per Tag. Ein Tag wie `latest` oder `1.3.1` ist das, was die Registry heute dafür hält; ein Digest ist der Inhalt selbst, so wie der Hash eines Fetchers in Nix. Nichts aktualisiert sich von selbst: kein `podman auto-update` und kein Auto-Update-Label. [`modules/container-pins.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/container-pins.nix) lässt einen Host mit einem davon nicht auswerten (admin/nixlab#305).

## Wo die Pins liegen

`hosts/<host>/container-images.json`, ein Eintrag je Container:

```json
"healthlog": {
  "image": "ghcr.io/mbombeck/healthlog",
  "tag": "v1.47.6",
  "digest": "sha256:2f88…",
  "source": "https://github.com/MBombeck/HealthLog"
}
```

`tag` sagt nur, von welchem Tag der Digest gelesen wurde. Gezogen wird `image@digest`. In `source` sucht der Version-Check nach Releases.

## Wie eine neue Version auffällt

Der wöchentliche Version-Check auf zorlock führt jeden Pin als Ziel der Art `container`, mit dem Tag als gepinnter Version, und vergleicht ihn mit dem neuesten stabilen GitHub-Release von `source`. Ein neueres Release erscheint dort als `update`, mit Release Notes.

## Bump { #bump }

```bash
just container-bump ursalia healthlog
```

Das Rezept nimmt den neuesten Release-Tag (`1.2.3` oder `v1.2.3`: keine Betas, Dev-Builds oder Tags je Architektur), liest dessen Digest mit skopeo und schreibt beides in die JSON-Datei. Es zeigt alten und neuen Tag und wo die Release Notes stehen. Einen bestimmten Tag gibt man als drittes Argument an: `just container-bump ursalia bambuddy 1.3.0`. Am Host ändert sich noch nichts.

Dann Release Notes lesen, committen und deployen:

```bash
just deploy ursalia
```

Je Dienst vor dem Deploy:

- **HealthLog**: Migrationen gehen nur vorwärts. Der Container schreibt vor dem Migrieren einen pg_dump nach `/var/lib/healthlog/backups`; der Weg zurück ist, den Bump zurückzunehmen und diesen Dump einzuspielen.
- **Bambuddy**: migriert ebenfalls beim Start; der Weg zurück ist, den Bump zurückzunehmen, plus der nächtliche pg_dump.
- **ESPHome-Builder**: Das Add-on in Home Assistant aktualisiert sich selbst und ist bis zum nächsten Bump voraus. Seine Version-Match-Policy muss auf „release“ bleiben (Settings > Send builds), dann nimmt es jedes stabile Release auf Builder-Seite an.

## Ein neuer Container

Einen Eintrag in `container-images.json` des Hosts anlegen (das Rezept braucht darin `image` und `source`; `tag` und `digest` liefert `just container-bump`), `modules/container-pins.nix` in der Datei des Containers importieren und `image = config.services.containerPins.images.<name>.ref` setzen. Ein auf dem Host selbst gebautes Image setzt stattdessen `pull = "never"` (OpenInvento).
