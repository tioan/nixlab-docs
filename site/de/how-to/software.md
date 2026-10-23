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

## Ein Cask aus einem Drittanbieter-Tap

Manche Hersteller veröffentlichen ihre Mac-App nur in einem eigenen Tap; ihre Installationszeile lautet dann `brew install --cask <owner>/<tap>/<name>`. Genau diesen Namen bekommt `apps`:

```bash
apps stablyai/orca/orca
```

- Ist der Tap gepinnt, erscheinen seine Casks und Formeln in jeder Suche wie die anderen; die Suche liest sie aus dem Pin, ohne Netz. In `apps.json` heißen sie `"<owner>/homebrew-<tap>/<name>"`, z. B. `stablyai/homebrew-orca/orca`.
- Einen noch nicht gepinnten Tap findet nur der voll qualifizierte Name; der Treffer ist mit *tap not pinned* markiert. Enter darauf zeigt, wer den Tap veröffentlicht (GitHub-Owner, verifiziert oder nicht, Alter des Repos, letzter Push) und von welchen URLs der Cask lädt, und fragt *Pin stablyai/homebrew-orca as flake input stablyai-orca-tap for gusto and trust it?*
- **Ja** trägt den Input in `flake.nix` ein (nach dem letzten Tap-Input, mit einem erzeugten Kommentar – umschreiben, wenn der Grund mehr verdient), die Zeile `nix-homebrew.taps."stablyai/homebrew-orca" = inputs.stablyai-orca-tap;` in `hosts/gusto/configuration.nix` und führt `nix flake lock` aus. Danach folgen die übliche Pin-Prüfung und die Notiz. Weil der Startbegriff genau diesen Cask genannt hat, endet die Runde dort – kein Zurück in die Liste, keine *Switch?*-Frage: Zusammenfassung, Auswertung, `just mac-switch`, dann der Tap als eigener Commit (`flake.nix`, `flake.lock`, `configuration.nix`) vor dem von `apps.json`. Dasselbe gilt für `apps owner/tap/name`, dessen Tap schon gepinnt ist. Eine Runde mit einer Entfernung fragt vor dem Switch weiterhin.
- **Jedem gepinnten Tap wird vertraut** (`brew trust`, [macOS-Hosts](../explanation/macos-hosts.md#homebrew-eine-richtlinie-fur-beide-macs)): Ein Cask führt seinen Installationscode als du aus. Vor dem Ja den Herausgeber prüfen.
- Ab dann aktualisiert `just mac-upgrade` den neuen Input mit den anderen – es findet jeden Tap-Input in `flake.lock` selbst.

Entfernen des letzten Casks eines Taps lässt den Tap gepinnt und vertraut; der kommt von Hand raus (Input, Zeile in `nix-homebrew.taps`, `nix flake lock`).

## Eins direkt entfernen

```bash
apps-rm shottr
```

Für ein einzelnes Entfernen ohne Suche. Ein Cask will zur Bestätigung den Namen getippt haben, dann `just mac-diff`, Switch (Standard nein), Commit. Auch eine **Mac-App-Store**-App wird beim Switch deinstalliert, wenn ihr Eintrag geht. Ist ein Name aus zwei Quellen deklariert, mit `--source` wählen, z. B. `apps-rm obsidian --source nixpkgs`.

## Auflisten

```bash
apps-list
```

Nach Quelle, mit dem Datum, an dem es dazukam, und der Notiz.

## Von Hand

`apps.json` lässt sich direkt bearbeiten (der Editor ergänzt die Felder über `modules/darwin/apps.schema.json`), danach `just mac-diff` und `just mac-switch`. Fehler zeigen sich bei der Auswertung mit der vollständigen Liste der Probleme; `nix build .#checks.aarch64-darwin.darwin-apps` prüft nur die Datei.

Nicht in `apps.json`:

- **Ein neuer Drittanbieter-Tap** – er ist ein Flake-Input: `apps <owner>/<tap>/<name>` legt ihn an (oben); von Hand den Input in `flake.nix` anlegen und `nix-homebrew.taps."<owner>/homebrew-<tap>" = inputs.<input>;` in `hosts/gusto/configuration.nix`, dann `nix flake lock`. Seine Casks und Formeln heißen in `apps.json` dann `"<owner>/homebrew-<tap>/<name>"`.
- **Ein Werkzeug mit Konfiguration** – `programs.<tool>` in `hosts/gusto/home.nix` (zsh, git, tmux, …).

## Welcher Checkout, welcher Mac

Die Befehle ändern den nixlab-Checkout (oder Worktree), in dem der aktuelle Ordner liegt; überall sonst den aus `NIXLAB_REPO` (`~/Projects/homelab/nixlab`, gesetzt in `home.nix`), oder `--repo <pfad>`. Sie sind das Paket `nixlab-apps` aus diesem Flake, installiert über `home.nix` – eine Änderung am Werkzeug selbst kommt mit dem nächsten `just mac-switch`; `just apps*` nutzt immer die Version aus der Arbeitskopie.

Der Host ist standardmäßig gusto; `--host zorlock` geht, sofern der Host `nixlab.apps.file` setzt – zorlock tut das heute nicht. Für einen anderen Mac als den, an dem du sitzt, committet die Runde ohne Switch; danach `just push` und `just mac-switch <host>`.
