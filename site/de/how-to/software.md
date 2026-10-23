# Software auf den Macs

Alles, was auf gusto installiert ist – Casks, Homebrew-Formeln, Mac-App-Store-Apps, nixpkgs-Pakete und Schriften – steht in `hosts/gusto/apps.json`. Drei Befehle verwalten sie – `apps`, `apps-list` und `apps-rm`, auf gusto installiert und in jedem Ordner nutzbar; im Repo-Ordner tun `just apps`, `just apps-list` und `just apps-rm` dasselbe. Den Hintergrund (warum eine Datendatei, warum die Pin-Prüfung) erklärt [macOS-Hosts](../explanation/macos-hosts.md#software-als-daten-appsjson).

## Eine Runde: hinzufügen und entfernen

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
- **Die Suche** läuft beim Tippen (ab 2 Zeichen, nach einer kurzen Pause) gegen nixpkgs (search.nixos.org, Release von `nixpkgs-darwin`), Homebrew (formulae.brew.sh) und den Mac App Store. Ist search.nixos.org nicht erreichbar, übernimmt `nix search` gegen den Pin – langsamer, aber immer verfügbar. Die Zeile über der Liste zeigt, was jede Quelle geliefert hat.
- **★** markiert die empfohlene Quelle, wenn es dieselbe Software mehrfach gibt: für eine GUI-App Cask vor App Store vor nixpkgs, für ein Kommandozeilenwerkzeug nixpkgs vor einer Homebrew-Formel. Die Vorschau unten zeigt Beschreibung, Version, Lizenz, Homepage – und bei einem deklarierten Eintrag seine Notiz.
- **Enter auf einen neuen Treffer fügt ihn hinzu.** Die Liste schließt sich für die Fragen:
    1. Die Pin-Prüfung –

        | Quelle | Prüfung | Wenn sie scheitert |
        | --- | --- | --- |
        | nixpkgs | auswertbar im gepinnten `nixpkgs-darwin`, verfügbar auf aarch64-darwin, nicht unfree | nicht hinzugefügt – kommt mit dem nächsten System-Update; unfree: den Cask nehmen |
        | Cask / Formel | die `.rb`-Datei liegt im gepinnten Tap | bietet an, `homebrew-cask` / `homebrew-core` zu aktualisieren (eigener Commit) |
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

Ein Commit pro Runde, nur `apps.json`: `gusto: add obsidian (cask), remove shottr (cask)`, mit einer Liste im Text; bei einer längeren Runde steht im Betreff die Anzahl (`gusto: add 3 and remove 1 apps`). Ein Tap-Bump ist ein eigener Commit davor (`flake.lock: bump homebrew-cask for …`).

**Abbrechen** – `esc` oder der Button *Cancel*: Mit Änderungen in der Runde fragt es *Discard N change(s)?*, danach sind `apps.json` (und `flake.lock`) wieder wie vorher. Hat `apps.json` beim Start von `apps` schon uncommittete Änderungen, bricht es ab, bevor es etwas ändert.

## Eins direkt entfernen

```bash
apps-rm shottr
```

Für ein einzelnes Entfernen ohne Suche. Ein Cask will zur Bestätigung den Namen getippt haben, dann `just mac-diff`, Switch (Standard nein), Commit. Eine **Mac-App-Store**-App bleibt installiert, wenn ihr Eintrag geht – bei Bedarf von Hand löschen. Ist ein Name aus zwei Quellen deklariert, mit `--source` wählen, z. B. `apps-rm obsidian --source nixpkgs`.

## Auflisten

```bash
apps-list
```

Nach Quelle, mit dem Datum, an dem es dazukam, und der Notiz.

## Von Hand

`apps.json` lässt sich direkt bearbeiten (der Editor ergänzt die Felder über `modules/darwin/apps.schema.json`), danach `just mac-diff` und `just mac-switch`. Fehler zeigen sich bei der Auswertung mit der vollständigen Liste der Probleme; `nix build .#checks.aarch64-darwin.darwin-apps` prüft nur die Datei.

Nicht in `apps.json`:

- **Ein neuer Drittanbieter-Tap** – er ist ein Flake-Input: Input in `flake.nix` anlegen und `nix-homebrew.taps."<owner>/homebrew-<tap>" = inputs.<input>;` in `hosts/gusto/configuration.nix`. Seine Casks und Formeln heißen in `apps.json` dann `"<owner>/homebrew-<tap>/<name>"`.
- **Ein Werkzeug mit Konfiguration** – `programs.<tool>` in `hosts/gusto/home.nix` (zsh, git, tmux, …).

## Welcher Checkout, welcher Mac

Die Befehle ändern den nixlab-Checkout (oder Worktree), in dem der aktuelle Ordner liegt; überall sonst den aus `NIXLAB_REPO` (`~/Projects/homelab/nixlab`, gesetzt in `home.nix`), oder `--repo <pfad>`. Sie sind das Paket `nixlab-apps` aus diesem Flake, installiert über `home.nix` – eine Änderung am Werkzeug selbst kommt mit dem nächsten `just mac-switch`; `just apps*` nutzt immer die Version aus der Arbeitskopie.

Der Host ist standardmäßig gusto; `--host zorlock` geht, sofern der Host `nixlab.apps.file` setzt – zorlock tut das heute nicht. Für einen anderen Mac als den, an dem du sitzt, committet die Runde ohne Switch; danach `just push` und `just mac-switch <host>`.
