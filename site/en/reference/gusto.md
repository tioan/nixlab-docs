# gusto – the admin workstation

gusto is the MacBook Pro everything in this repo is run from: deploys, secrets, Tofu, the docs. It is the second nix-darwin host next to zorlock, and the only machine in the lab a person sits at. This page is the complete reference for it – what is on it, where each part is configured, how it is used day to day and what to check when something does not work. *Why* it is built this way (Homebrew policy, NetBird as an app, the differences to zorlock) is on [macOS hosts](../explanation/macos-hosts.md).

## At a glance

| | |
| --- | --- |
| Hardware | Apple MacBook Pro (Apple silicon), `kind: laptop`, `availability: intermittent` in the inventory |
| System | macOS (English, region Germany), FileVault on |
| Configuration | `darwinConfigurations.gusto` in `flake.nix`: nix-darwin + home-manager (user `admin`) |
| Built and switched | on gusto itself, from the working copy `~/Projects/homelab/nixlab` – `just mac-switch` |
| Apps | Homebrew casks, Homebrew and its taps pinned in `flake.lock` (`modules/darwin/homebrew.nix`); all software listed in `hosts/gusto/apps.json` |
| Repo tools | from the flake's devShell, loaded by direnv in the checkout |
| SSH | client only, keys only in 1Password; no Remote Login (no sshd) |
| Mesh | NetBird peer `gusto` (cask `netbird-ui`), group `admin-workstations` |
| Secrets | only `hosts/gusto/mcp.yaml` (the [Claude app's MCP servers](#the-claude-apps-mcp-servers)), encrypted for the workstation age key from 1Password; gusto has no host key of its own |
| Monitoring | none; not in the topology, nothing in the lab depends on it (`criticality: lab`) |
| Backup | Arq 7 to Garage on aldrin, plus Time Machine |

## Files

| File | Content |
| --- | --- |
| `hosts/gusto/configuration.nix` | System: host name, Nix settings, Touch ID for sudo, taps, SSH known hosts, `SSH_AUTH_SOCK` for GUI apps, macOS settings, home-manager wiring |
| `hosts/gusto/home.nix` | admin's home: environment, links, zsh and its helpers, CLI/TUI tools, Ghostty, git |
| `hosts/gusto/ssh.nix` | `~/.ssh/config` and `~/.ssh/pub/` |
| `hosts/gusto/mcp.nix`, `mcp.yaml` | The Claude app's MCP servers: `mcp-run` and their entries in Claude's config files; their credentials (sops) |
| `hosts/gusto/ssh/*.pub` | Public halves of the SSH keys (one per target), linked to `~/.ssh/pub/` |
| `hosts/gusto/apps.json` | All software: casks, formulae, Mac App Store, nixpkgs (system, user, font), each with a note – `apps-list` |
| `modules/darwin/apps.nix`, `apps.schema.json` | Turns `apps.json` into the options and checks it; editor schema |
| `pkgs/nixlab-apps/` | The tool behind `apps`, `apps-list`, `apps-rm` |
| `modules/darwin/homebrew.nix` | Homebrew policy shared with zorlock |
| `modules/darwin/rebuild.sh` | The engine of the `mac-*` recipes |
| `.envrc` | `use flake` – direnv loads the devShell in the checkout |
| `docs/install-gusto.md` | Setting gusto up from scratch (private docs only) |

Flake inputs used only by gusto: `home-manager`, `nix-homebrew`, `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap` – see [Flake inputs](inputs.md).

## What is installed

gusto was set up deliberately bare on 2026-10-21: no app list taken over from the previous installation, only the base below. Anything else is added when it is needed (see [Day to day](#day-to-day)). The tables describe it; the complete, current list is `hosts/gusto/apps.json` – `apps-list`.

### Apps (Homebrew casks)

| Cask | What for |
| --- | --- |
| `1password`, `1password-cli` | Passwords, the SSH agent with all SSH keys, `op` for scripts (sops' age key). The CLI as a cask, not from nixpkgs: it unlocks through the app with Touch ID, which only works with the vendor's signed binary. |
| `vivaldi` | Browser |
| `arq` | Backup to Garage on aldrin |
| `claude` | Claude desktop app; its local MCP servers: [the Claude app's MCP servers](#the-claude-apps-mcp-servers) |
| `ghostty` | Terminal |
| `netbirdio/homebrew-tap/netbird-ui` (+ formula `netbird`) | NetBird menu-bar app and daemon – see [NetBird](#netbird) |
| `stablyai/homebrew-orca/orca` | Orca – IDE for running several AI coding agents side by side in terminals and worktrees; from Stably's own tap (input `stablyai-orca-tap`), updates itself. Removing it zaps `~/.orca` too |
| `shottr` | Screenshots |
| `telegram`, `whatsapp` | Messengers |
| `spotify` | Music |
| `visual-studio-code` | Editor (Microsoft's build, for Remote-SSH and Pylance); telemetry off, `settings.json` comes from home-manager and is read-only |

From the Mac App Store (`homebrew.masApps`, through `mas`; needs the App Store sign-in): **1Blocker**, **1Password for Safari**, **Ivory**, **TestFlight**. `zap` also removes App Store apps that are not declared; `just mac-switch` stops and asks first (see [macOS hosts](../explanation/macos-hosts.md)).

### System-wide (nix-darwin)

`git`, `gh`, `just`, `jq`, `neovim` (`EDITOR`/`VISUAL`, kept across sudo), `curl`, `wget`, `rsync`; zsh as the system shell (`programs.zsh`); the font **Maple Mono NF** (Nerd Font) for Ghostty and the TUIs.

### admin (home-manager)

| Tool | Notes |
| --- | --- |
| zsh | config in `~/.config/zsh`, autosuggestions, syntax highlighting, history in `~/.local/state/zsh/history` |
| atuin | shell history in SQLite, Ctrl-R / ↑ search; update check off |
| fzf | Ctrl-T (files), Alt-C (cd) |
| zoxide | `z <part of a path>` |
| direnv + nix-direnv | per-directory environments; caches flake shells and protects them from GC |
| bat, eza, ripgrep, fd, tree | `cat`/`ls`/`grep`/`find` replacements; eza brings `ls`, `ll`, `la`, `lt` |
| lazygit, btop, yazi, tmux | TUIs; yazi as `y` (changes into the last directory on exit), tmux with mouse, `tmux-256color` |
| nvd, nix-output-monitor | closure diffs, readable build output (`nom`) |
| uv | Python tools (`uv tool install` → `~/.local/bin`) |
| typst | documents (real-fast-document) |

### Repo tools (devShell)

`sops`, `age`, `ssh-to-age`, `opentofu`, `nvd` – from `devShells.aarch64-darwin.default`, at the versions in `flake.lock`. They are there in every shell inside the checkout (direnv), not elsewhere. `dnscontrol` comes from `devShells.aarch64-darwin.dns` and is only there in the DNSControl folder, behind a wrapper that decrypts the credentials with sops – see [macOS hosts](../explanation/macos-hosts.md#dnscontrol). The docs tools (pandoc, WeasyPrint, Zensical) are not in it; `just docs` and `just docs-serve` fetch their own.

## Environment

| Variable / path | Value | Why |
| --- | --- | --- |
| `PATH` | Nix profiles, then `/opt/homebrew/bin:sbin`, then macOS' directories; `~/.local/bin` in front for admin | Nix wins over Homebrew, Homebrew over Apple's stubs; no `brew shellenv` anywhere |
| `SSH_AUTH_SOCK` | `~/.1password/agent.sock` | every SSH client talks to 1Password – in shells (home-manager) and GUI apps (`launchd.user.envVariables`) |
| `SOPS_AGE_KEY_CMD` | `op read "op://<vault>/<item>/password"` | sops gets the workstation key from 1Password when it needs it; never on disk |
| `EDITOR`, `VISUAL` | `nvim` | |
| `GOPATH` / `GOBIN` | `~/.local/share/go` / `~/.local/bin` | XDG; binaries into the one personal PATH directory |
| `CARGO_HOME` / `CARGO_INSTALL_ROOT` | `~/.local/share/cargo` / `~/.local` | same; `cargo install` writes to `<root>/bin` |
| `ZDOTDIR` | `~/.config/zsh` | set by the stub `~/.zshenv` home-manager writes |

### Files and links home-manager manages

| Path | |
| --- | --- |
| `~/.zshenv` → `~/.config/zsh/.zshenv`, `.zshrc` | zsh |
| `~/.config/git/config` | git |
| `~/.config/ghostty/config` | Ghostty |
| `~/.config/tmux/tmux.conf`, `~/.config/atuin/config.toml`, `~/.config/direnv/…`, `~/.config/lazygit/config.yml` | the tools |
| `~/.ssh/config`, `~/.ssh/pub/` | SSH |
| `~/.1password/agent.sock` → `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` | path without spaces for the agent; 1Password does not create it |
| `~/.config/ssh` → `~/.ssh` | XDG rule: tools without XDG support get a link under `~/.config` |

A file home-manager wants to write but finds already there (first switch on a fresh macOS) is renamed to `<name>.before-hm` instead of failing the switch.

## macOS settings

Decided one by one on 2026-10-21; everything not listed is macOS' default.

| Area | Setting | nix-darwin option |
| --- | --- | --- |
| Menu bar clock | 24 h, weekday, no date | `menuExtraClock.Show24Hour`, `ShowDayOfWeek`, `ShowDate = 2` |
| Dock | always visible, no magnification, icon size 66 | `dock.autohide`, `magnification`, `tilesize` |
| | no launch animation, no bouncing | `dock.launchanim`, `CustomUserPreferences."com.apple.dock"."no-bouncing"` |
| | minimise into the app icon, effect "scale", no recent apps | `minimize-to-application`, `mineffect`, `show-recents` |
| | hot corner bottom right: Quick Note | `dock.wvous-br-corner = 14` |
| | Dock content | not managed (yet) |
| Finder | path bar on, status bar off, icons on the desktop, list view, folders first (windows and desktop) | `finder.ShowPathbar`, `ShowStatusBar`, `CreateDesktop`, `FXPreferredViewStyle = "Nlsv"`, `_FXSortFoldersFirst`, `_FXSortFoldersFirstOnDesktop` |
| General | dark appearance, all file extensions, auto-capitalisation, period on double space | `NSGlobalDomain.AppleInterfaceStyle`, `AppleShowAllExtensions`, `NSAutomaticCapitalizationEnabled`, `NSAutomaticPeriodSubstitutionEnabled` |
| Trackpad | Force Click on, tracking speed 1 | `NSGlobalDomain."com.apple.trackpad.forceClick"`, `"com.apple.trackpad.scaling"` |
| Keyboard | German (main) and U.S. input sources | `CustomUserPreferences."com.apple.HIToolbox".AppleEnabledInputSources` – U.S. for KVM sessions (NanoKVM Go+, ArkKVM type PC scancodes); effective after logging out once |
| Network names | `gusto` as computer, local host and SMB NetBIOS name | `networking.*Name`, `smb.NetBIOSName` |
| Language, region | English, Germany | not in Nix – set during macOS setup |

After each switch `activateSettings -u` runs as admin, so most settings apply without logging out.

## Nix

Experimental features `nix-command flakes`; `admin` is a trusted user; no channels; `min-free` 5 GiB / `max-free` 20 GiB; store optimisation on; garbage collection Sundays 12:15, everything older than 30 days. No extra binary caches – every input follows nixpkgs, a community cache would have no hits.

## Security

- **FileVault** on (macOS setup).
- **sudo with Touch ID** (`/etc/pam.d/sudo_local`, which macOS updates leave alone), working inside tmux too (`pam_reattach`).
- **No Remote Login**: gusto runs no sshd and accepts no SSH connections. Nothing in the inventory or in `.sops.yaml` has a key for it, so no secret is ever encrypted to it.
- **Keys only in 1Password**: SSH keys (agent), the sops age key (`op read`), the Arq credentials. Nothing private under `~/.ssh`. The MCP servers' credentials are in sops (`hosts/gusto/mcp.yaml`), readable only with that age key.

## SSH

`~/.ssh/config` is generated (`hosts/gusto/ssh.nix`). At the very top, before any `Host` block: `IdentityAgent ~/.1password/agent.sock`, `IdentitiesOnly yes`, `Compression yes`, `SendEnv LANG LC_*` – first value wins in ssh_config, so nothing below can change them. Every `IdentityFile` names a **public** key in `~/.ssh/pub/`; that is how the agent knows which single key to offer.

Host keys: lab hosts from `inventory.json` (`/etc/ssh/ssh_known_hosts`), GitHub pinned; the rest goes to `~/.ssh/known_hosts` on first use.

| `ssh …` | Goes to | User | Key (`~/.ssh/pub/`) | Notes |
| --- | --- | --- | --- | --- |
| `aldrin`, `grammi`, `zummi`, `ursalia`, `cuckoosegg` (also `<host>.peer.homelab.example`) | `<host>.peer.homelab.example` (NetBird) | root | `<host>.homelab.example.pub` | generated from the inventory: every managed host except gusto |
| `zorlock` | `zorlock.peer.homelab.example` | admin | `zorlock.homelab.example.pub` | no root on macOS |
| `<host>.example-tailnet.ts.net` | Tailscale | as above | as above | break-glass while Tailscale still runs; not for cuckoosegg. Goes away with Tailscale. |
| `aldrin.homelab.example`, `grammi.homelab.example`, `zummi.homelab.example` | public address | admin | as above | fallback when the mesh is down – root is refused on public addresses (`modules/ssh.nix`) |
| `zorlock-lan` | 198.51.100.86 | admin | `zorlock.homelab.example.pub` | FileVault unlock after a reboot, from the home LAN |
| `opnsense` | 198.51.100.1 | root | `opnsense.pub` | |
| `arkkvm`, `arkkvm01` | `arkkvm01` (DHCP name) | root | `arkkvm.pub` | |
| `subraum-router` | hackspace.c3pb.de | admin | `c3pb.de.pub` | jump host; forwards 8006 → Proxmox, 8080/8081 → Home Assistant |
| `vogon`, `amnesia`, `unifi` | `<name>.subraum.c3pb.de` via `subraum-router` | root | `<name>.subraum.c3pb.de.pub` | |
| `git.c3pb.de` | | git | `git.c3pb.de.pub` | |
| `edi` | | admin | – | `HostKeyAlgorithms +ssh-rsa` |
| `switch-*`, `172.31.64.*`, `172.31.65.*` | | bernd (switches) | – | old switches: *adds* SHA-1 KEX, `ssh-rsa`, CBC ciphers |
| `github.com` | | git | `github.com.pub` | ControlMaster, 60 s |
| `github-443` | ssh.github.com:443 | git | `github.com.pub` | for networks that block port 22 |

The alternative names (tailnet, public) carry `HostKeyAlias <host>.peer.homelab.example`, so all of them are checked against the one host key in the inventory. A new managed host appears here by itself after `just mac-switch` – only its public key file has to be added to `hosts/gusto/ssh/`.

## git

`~/.config/git/config`: name `admin`, address `mail@admin.org`; below `~/Projects/homelab/` (`includeIf gitdir:`) `admin@homelab.example`. `init.defaultBranch = main`, `pull.rebase = true`, alias `lg = log --oneline`. GitHub over SSH with the key `github.com SSH (admin)` from 1Password; `gh` for the API.

## NetBird

The official app from NetBird's tap (cask `netbird-ui`, formula `netbird` for the daemon), pinned as the input `netbirdio-tap`. Sign-in by SSO (Pocket ID) in the app, peer name `gusto`, group `admin-workstations` (Subraum devices, docs site). Rosenpass is **off** on the workstation (since 2026-10-21; mesh-wide since 2026-10-24, until 2026-10-31). The version follows the tap, not `nixpkgs-netbird`; `just mac-upgrade` prints both. Details and the comparison with zorlock: [macOS hosts](../explanation/macos-hosts.md#netbird-on-the-two-macs).

## The Claude app's MCP servers

The desktop app and Claude Code start their local MCP servers as stdio processes through `mcp-run <server>` (`hosts/gusto/mcp.nix`, set up on 2026-10-23). On every start `mcp-run` decrypts only that server's section of `hosts/gusto/mcp.yaml`. The file is encrypted with sops for the keys `workstation` and `admin`; `op` may ask for Touch ID while doing so. Then `mcp-run` starts the server. No credential is in any of Claude's config files.

| Server | What | Start | Credentials in `mcp.yaml` | Desktop | Claude Code |
| --- | --- | --- | --- | --- | --- |
| `homeassistant` | [ha-mcp](https://github.com/homeassistant-ai/ha-mcp) as an app (add-on) on the Raspberry Pi, port 9583 | `uvx fastmcp-remote <url>`, bridges HTTP to stdio | `homeassistant.url`: the app's secret URL, host `homeassistant.peer.homelab.example` | yes | yes |
| `feedbin` | [FeedbinMCP](https://github.com/admin/FeedbinMCP), admin's fork of [hypermoose/FeedbinMCP](https://github.com/hypermoose/FeedbinMCP) | `uv run --directory ~/Projects/personal/FeedbinMCP feedbin-mcp` | `feedbin.email`, `feedbin.password` | yes | no |
| `arkkvm` | [arkkvm-mcp](https://github.com/admin/arkkvm-mcp) | `uv run --directory ~/Projects/arkkvm/arkkvm-mcp arkkvm-mcp`, host `arkkvm01`, keyboard layout `de` | `arkkvm.password` | yes | yes |

- **ha-mcp rather than the built-in "Model Context Protocol Server" integration:** the built-in one only sees what is exposed to Assist and has no device registry. ha-mcp can handle automations, dashboards, registries, history and more, with write access. That is deliberate: Claude asks before every tool call, and ha-mcp takes a backup before it changes anything. The app talks to HA through the Supervisor, so no long-lived token is needed. Its secret URL is in the app's log at start.
- **Reached over the mesh:** the same URL works at home and away. The NetBird policy `home-assistant-mcp` (`terraform/netbird/home-assistant.tf`) allows `admin-workstations` → HA, TCP 9583 only. Outside the LAN and the mesh the URL alone is of no use.
- **No Feedbin in Claude Code:** feed articles are text from strangers, so a way in for prompt injection, and Claude Code has a shell and sops on gusto.
- **Configuration:** every switch merges the servers with `jq` into `mcpServers` of `~/Library/Application Support/Claude/claude_desktop_config.json` and `~/.claude.json`, by name. Servers added by hand stay; one removed here has to be deleted there by hand. The apps read the file at start, so restart them after a switch.
- **Changing credentials:** `cd ~/Projects/homelab/nixlab && sops hosts/gusto/mcp.yaml`. The change applies from the next server start, without a switch, because `mcp-run` reads the file in the working copy. The HA URL can be taken straight from the clipboard, with its host replaced by the mesh name:
  `cd ~/Projects/homelab/nixlab && sops set hosts/gusto/mcp.yaml '["homeassistant"]["url"]' "\"$(pbpaste | sed -E 's#^http://[^/]+#http://homeassistant.peer.homelab.example:9583#')\""`
- **MoneyMoney** is not set up yet, because MoneyMoney has not been on gusto since the reinstall. It used to run as `npx -y moneymoney-mcp`; that needs Node and the app running and unlocked.

## Backup

- **Arq 7** backs up the whole disk to the Garage bucket on aldrin, with its own backup plan for gusto (the previous MacBook's plan is kept for restores only). Encryption password and Garage credentials are in 1Password.
- **Time Machine** in addition.
- Nothing on gusto needs a backup to be rebuilt: the system and the dotfiles are this repo, the keys are in 1Password. A backup is for data.

## Day to day

| Task | How |
| --- | --- |
| Add or remove apps and CLI tools | `apps [term]` (any directory; `just apps` in the checkout) – one round: search, pick, change the search, pick again …, then one switch and one commit ([how-to](../how-to/software.md)); a tool with configuration: `programs.<tool>` in `hosts/gusto/home.nix` |
| Remove one thing directly | `apps-rm <name>`; casks go with their data (`zap`) – `mac-diff` comes first |
| See what is declared | `apps-list` |
| Update apps (Homebrew) | `just mac-upgrade` – bumps only the tap inputs, switches, `brew upgrade`, summary; then commit `flake.lock` |
| Update the system (Nix) | `nix flake update nixpkgs-darwin nix-darwin home-manager` → `just mac-switch` → also `just mac-switch zorlock` (same inputs) |
| Deploy a NixOS host | `just ship <host> "<message>"` or `just deploy <host>` – over the mesh as root |
| Edit secrets | `just secrets <host>` (Touch ID for `op`) |
| Docs | `just docs-serve` (preview), `just docs` (PDFs + public repo) |
| New checkout or worktree | `direnv allow` once inside it |

All `mac-*` recipes take the host as an optional parameter (default `gusto`; `zorlock` runs over SSH after a `git pull` there). New files must be known to git (`git add`) before a switch sees them.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `ssh-add -L`: "The agent has no identities" / "Could not open a connection" | 1Password running and unlocked, Settings → Developer → *Use the SSH agent*; `ls -l ~/.1password/agent.sock`; `echo $SSH_AUTH_SOCK` |
| ssh offers the wrong key / "Too many authentication failures" | `ssh -G <host> \| grep -E 'identityfile\|identityagent'` – exactly one `.pub` from `~/.ssh/pub/` |
| Host key mismatch for a lab host | host reinstalled or key rotated: inventory updated? Then `just mac-switch` (known hosts are part of the system) |
| `sops`, `tofu` not found | not in the checkout, or `direnv allow` missing |
| sops: "failed to get the data key" | `op read "op://<vault>/<item>/password" \| age-keygen -y` must print the workstation's `age1…` |
| `brew` installs nothing / tap missing | taps come only from `flake.lock` (`mutableTaps = false`); `brew tap` and `brew update` are not the way – add an input, `just mac-switch` |
| A setting did not apply | log out and in once (input sources, some Dock/Finder keys) |
| `.before-hm` files in the home directory | left by the first switch; compare and delete |
| An MCP server does not connect | run `mcp-run <server>` in a terminal: does it hang at Touch ID or sops, is a value missing in `mcp.yaml`, is the checkout missing? The desktop app logs to `~/Library/Logs/Claude/mcp-server-<name>.log` |
| `homeassistant` hangs | the URL's port must be 9583, the policy silently drops any other (timeout after 30 s): `sops decrypt --extract '["homeassistant"]["url"]' hosts/gusto/mcp.yaml \| cut -d/ -f3` shows only host and port; `nc -z homeassistant.peer.homelab.example 9583`; if `netbird status -d` shows HA as "Connected" but without a WireGuard handshake, Rosenpass in the NetBird app on HA is strict – turn on `rosenpass_permissive` there (until 2026-10-31 Rosenpass belongs off there entirely) |
| NetBird disconnected | menu-bar app → Connect; `netbird status -d`; daemon: `sudo launchctl print system/netbird` |
