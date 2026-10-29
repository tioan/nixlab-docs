# Branch vor dem Merge auf einem Host testen

Ein Thema wird aus seinem Worktree auf einen Host deployt und erst nach erfolgreichem Test in main gemergt. Ohne Vorkehrung hielte das nur bis 04:00: Das nächtliche Upgrade baut `/etc/nixos` – also main – und schaltet den Host still zurück. Dasselbe passiert bei einem `just deploy` aus einem anderen Thema. `just try` setzt deshalb einen **Halt** auf dem Host, den alle Wege zurück zu main beachten ([`modules/deploy-hold.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/deploy-hold.nix)).

## Ablauf { #flow }

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

## Mit automatischem Zurückrollen: `just try-confirm` { #confirm }

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

## Wer den Halt beachtet { #honoured }

| Weg | Verhalten bei Halt |
| --- | --- |
| nächtliches `nixos-upgrade` | übersprungen (`ExecCondition`, kein Fehlschlag): kein Flake-Update, kein Switch, kein Reboot. Ist der gehaltene Commit inzwischen in `/etc/nixos`, hebt es den Halt auf und läuft. |
| `just rebuild`/`deploy`/`ship`/`deploy-all` | Abbruch, außer der gehaltene Commit ist im frisch gepullten `/etc/nixos` – dann Halt weg und Deploy |
| `just deploy-push <host>` | dieselbe Regel gegen den `HEAD` des lokalen Checkouts |
| ursalias nächtlicher Push nach cuckoosegg | übersprungen, außer der gehaltene Commit ist in ursalias `/etc/nixos` |

Die Regel ist überall dieselbe: Ein Halt blockiert, solange das, was deployt werden soll, den gehaltenen Commit nicht enthält. Ein **Rebase-Merge** schreibt den Commit neu – dann erkennt nichts den Merge, und der Halt muss mit `just release <host>` weg.

## cuckoosegg { #cuckoosegg }

`just try cuckoosegg` funktioniert genauso, der Halt liegt auf cuckoosegg. Nach dem Merge gibt es kein `just deploy cuckoosegg`: Entweder ursalias Push um 06:30 übernimmt, sobald ursalias Checkout den Merge hat (`just deploy ursalia` oder `just sync ursalia`), oder sofort aus main mit `just deploy-push cuckoosegg`.

## Sehen, wer was hält { #status }

- `just holds` – alle NixOS-Hosts auf einmal
- Login-Shell auf dem Host – eine Warnzeile, ab 48 h mit Hinweis auf `just release`
- Grafana „Homelab / Hosts Overview“, Panel **Deploy holds (just try)** – Metrik `nixlab_deploy_hold_since_seconds{branch,commit}`, orange solange ein Halt besteht, rot ab 48 h. Echte Alarmierung gibt es im Lab nicht; das Panel ist der Hinweis.

## Grenzen { #limits }

- **Tofu** (`netbird-apply`, `desec-apply`, `pocketid-apply`) hat einen State und wird nur aus main angewandt. Ein Thema, das Tofu ändert, lässt sich damit nicht vorab testen.
- **Macs** (gusto, zorlock) sind nicht abgedeckt – sie haben kein nächtliches Upgrade, das zurückdrehen würde.
- **Zwei Themen auf einem Host** gleichzeitig gehen nicht: Das zweite `just try` bricht ab, bis das erste gemergt oder freigegeben ist.
- Ein Host vor `modules/deploy-hold.nix` kennt keinen Halt; der erste `just try` darauf bringt das Modul mit.
- **`try-confirm` und das nächtliche Upgrade:** Bis zur Bestätigung gibt es keinen Halt. Fällt die Frist über 04:00, baut `nixos-upgrade` main. Ändert der Branch den Hostnamen, baut es sogar main für den *neuen* Namen – beim Cut-over von ursalia (2026-10-27) bootete die NUC so die Konfiguration der M720q. Vorher `nixos-hold set` setzen oder nicht in die Nacht hinein testen.
