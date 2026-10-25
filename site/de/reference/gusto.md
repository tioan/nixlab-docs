# gusto – die Admin-Workstation

gusto ist das MacBook Pro, von dem aus alles in diesem Repo läuft: Deploys, Secrets, Tofu, die Doku. Es ist der zweite nix-darwin-Host neben zorlock und das einzige Gerät im Lab, an dem ein Mensch sitzt. Diese Seite ist die vollständige Referenz dafür – was darauf ist, wo jeder Teil konfiguriert wird, wie es im Alltag benutzt wird und was zu prüfen ist, wenn etwas nicht geht. *Warum* es so gebaut ist (Homebrew-Richtlinie, NetBird als App, die Unterschiede zu zorlock), steht unter [macOS-Hosts](../explanation/macos-hosts.md).

## Überblick

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

## Dateien

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

Flake-Inputs nur für gusto: `home-manager`, `nix-homebrew`, `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap` – siehe [Flake-Inputs](inputs.md).

## Was installiert ist

gusto wurde am 2026-10-21 bewusst „nackt“ aufgesetzt: keine App-Liste aus der vorherigen Installation übernommen, nur die Grundausstattung unten. Alles andere kommt dazu, wenn es gebraucht wird (siehe [Im Alltag](#im-alltag)). Die Tabellen beschreiben sie; die vollständige, aktuelle Liste ist `hosts/gusto/apps.json` – `apps-list`.

### Apps (Homebrew-Casks)

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

Aus dem Mac App Store (`homebrew.masApps`, über `mas`; braucht die App-Store-Anmeldung): **1Blocker**, **1Password for Safari**, **Ivory**, **TestFlight**. `zap` entfernt auch App-Store-Apps, die nicht deklariert sind; `just mac-switch` hält vorher an und fragt (siehe [macOS-Hosts](../explanation/macos-hosts.md)).

### Systemweit (nix-darwin)

`git`, `gh`, `just`, `jq`, `neovim` (`EDITOR`/`VISUAL`, bleibt auch unter sudo erhalten), `curl`, `wget`, `rsync`; zsh als Systemshell (`programs.zsh`); die Schrift **Maple Mono NF** (Nerd Font) für Ghostty und die TUIs.

### admin (home-manager)

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

### Repo-Werkzeuge (devShell)

`sops`, `age`, `ssh-to-age`, `opentofu`, `nvd` – aus `devShells.aarch64-darwin.default`, in den Versionen aus `flake.lock`. Sie sind in jeder Shell im Repo-Ordner da (direnv), sonst nicht. `dnscontrol` kommt aus `devShells.aarch64-darwin.dns` und ist nur im DNSControl-Ordner da, dort hinter einem Wrapper, der die Zugangsdaten mit sops entschlüsselt – siehe [macOS-Hosts](../explanation/macos-hosts.md#dnscontrol). Die Doku-Werkzeuge (pandoc, WeasyPrint, Zensical) gehören nicht dazu; `just docs` und `just docs-serve` holen sich ihre eigenen.

## Umgebung

| Variable / Pfad | Wert | Warum |
| --- | --- | --- |
| `PATH` | Nix-Profile, dann `/opt/homebrew/bin:sbin`, dann die macOS-Ordner; für admin `~/.local/bin` davor | Nix vor Homebrew, Homebrew vor Apples Platzhaltern; nirgends `brew shellenv` |
| `SSH_AUTH_SOCK` | `~/.1password/agent.sock` | jeder SSH-Client spricht mit 1Password – in Shells (home-manager) und GUI-Apps (`launchd.user.envVariables`) |
| `SOPS_AGE_KEY_CMD` | `op read "op://<vault>/<item>/password"` | sops holt den Workstation-Schlüssel aus 1Password, wenn es ihn braucht; nie auf der Platte |
| `EDITOR`, `VISUAL` | `nvim` | |
| `GOPATH` / `GOBIN` | `~/.local/share/go` / `~/.local/bin` | XDG; Programme in den einen persönlichen PATH-Ordner |
| `CARGO_HOME` / `CARGO_INSTALL_ROOT` | `~/.local/share/cargo` / `~/.local` | ebenso; `cargo install` schreibt nach `<root>/bin` |
| `ZDOTDIR` | `~/.config/zsh` | gesetzt vom Platzhalter `~/.zshenv`, den home-manager schreibt |

### Von home-manager verwaltete Dateien und Links

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

## macOS-Einstellungen

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

## Nix

Experimentelle Features `nix-command flakes`; `admin` ist trusted user; keine Channels; `min-free` 5 GiB / `max-free` 20 GiB; Store-Optimierung an; Garbage Collection sonntags 12:15, alles älter als 30 Tage. Keine zusätzlichen Binary-Caches – alle Inputs folgen nixpkgs, ein Community-Cache hätte keine Treffer.

## Sicherheit

- **FileVault** an (macOS-Einrichtung).
- **sudo mit Touch ID** (`/etc/pam.d/sudo_local`, das macOS-Updates in Ruhe lassen), auch in tmux (`pam_reattach`).
- **Kein Remote Login**: gusto hat kein sshd und nimmt keine SSH-Verbindungen an. Weder das Inventar noch `.sops.yaml` haben einen Schlüssel dafür, also wird nie ein Secret dafür verschlüsselt.
- **Schlüssel nur in 1Password**: SSH-Schlüssel (Agent), der age-Schlüssel für sops (`op read`), die Arq-Zugangsdaten. Nichts Privates unter `~/.ssh`. Die Zugangsdaten der MCP-Server liegen in sops (`hosts/gusto/mcp.yaml`), lesbar nur mit diesem age-Schlüssel.

## SSH

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

## git

`~/.config/git/config`: Name `admin`, Adresse `mail@admin.org`; unterhalb von `~/Projects/homelab/` (`includeIf gitdir:`) `admin@homelab.example`. `init.defaultBranch = main`, `pull.rebase = true`, Alias `lg = log --oneline`. GitHub per SSH mit dem Schlüssel `github.com SSH (admin)` aus 1Password; `gh` für die API.

## NetBird

Die offizielle App aus NetBirds Tap (Cask `netbird-ui`, Formula `netbird` für den Daemon), festgeschrieben als Input `netbirdio-tap`. Anmeldung per SSO (Pocket ID) in der App, Peer-Name `gusto`, Gruppe `admin-workstations` (Subraum-Geräte, Doku-Site). Rosenpass ist auf der Workstation **aus** (seit 2026-10-21, seit 2026-10-24 im ganzen Mesh bis 2026-10-31). Die Version folgt dem Tap, nicht `nixpkgs-netbird`; `just mac-upgrade` zeigt beide an. Details und der Vergleich mit zorlock: [macOS-Hosts](../explanation/macos-hosts.md#netbird-auf-den-beiden-macs).

## MCP-Server der Claude-App

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

## Sicherung

- **Arq 7** sichert die ganze Platte in das Garage-Bucket auf aldrin, mit einem eigenen Backup-Plan für gusto (der Plan des vorigen MacBooks bleibt nur zum Wiederherstellen). Verschlüsselungspasswort und Garage-Zugangsdaten liegen in 1Password.
- **Time Machine** zusätzlich.
- Zum Neuaufbau braucht gusto keine Sicherung: System und Dotfiles sind dieses Repo, die Schlüssel liegen in 1Password. Die Sicherung ist für Daten.

## Im Alltag

| Aufgabe | Wie |
| --- | --- |
| Apps und CLI-Werkzeuge hinzufügen oder entfernen | `apps [suche]` (in jedem Ordner; im Repo auch `just apps`) – eine Runde: suchen, auswählen, Suche ändern, wieder auswählen …, dann ein Switch und ein Commit ([Anleitung](../how-to/software.md)); ein Werkzeug mit Konfiguration: `programs.<tool>` in `hosts/gusto/home.nix` |
| Eins direkt entfernen | `apps-rm <name>`; Casks gehen samt Daten (`zap`) – vorher kommt `mac-diff` |
| Sehen, was deklariert ist | `apps-list` |
| Apps aktualisieren (Homebrew) | `just mac-upgrade` – aktualisiert nur die Tap-Inputs, Switch, `brew upgrade`, Zusammenfassung; danach `flake.lock` committen |
| System aktualisieren (Nix) | `nix flake update nixpkgs-darwin nix-darwin home-manager` → `just mac-switch` → auch `just mac-switch zorlock` (gleiche Inputs) |
| NixOS-Host deployen | `just ship <host> "<Nachricht>"` oder `just deploy <host>` – übers Mesh als root |
| Secrets bearbeiten | `just secrets <host>` (Touch ID für `op`) |
| Doku | `just docs-serve` (Vorschau), `just docs` (PDFs + öffentliches Repo) |
| Neuer Klon oder Worktree | einmal `direnv allow` darin |

Alle `mac-*`-Rezepte nehmen den Host als optionalen Parameter (Standard `gusto`; `zorlock` läuft per SSH nach einem `git pull` dort). Neue Dateien muss git kennen (`git add`), bevor ein Switch sie sieht.

## Fehlersuche

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
