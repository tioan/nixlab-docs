# macOS hosts

Two machines in this repo run macOS with nix-darwin instead of NixOS: **zorlock**, the Mac mini serving Ollama, and **gusto**, the MacBook that is the admin workstation. Both are `darwinConfigurations` in the same flake and use the same darwin-tested nixpkgs (`nixpkgs-darwin`). Apart from that they are opposites – one is a server nobody sits at, the other a laptop that is only ever used by a person – and several things are therefore solved differently on purpose. This page explains what the two share, where they differ, and why.

| | zorlock | gusto |
| --- | --- | --- |
| Role | LLM server (Ollama for paperless-gpt) | Admin workstation: deploys, secrets, Tofu, docs |
| Configuration | `hosts/zorlock/` | `hosts/gusto/` (system) + `home.nix`, `ssh.nix` (home-manager) |
| Built and switched | on zorlock, from `/etc/nixos` (`just mac-switch zorlock`) | on gusto, from the working copy (`just mac-switch`) |
| Homebrew | off | on – the apps are casks |
| Software list | in `configuration.nix` | `hosts/gusto/apps.json` – `apps`, `apps-rm` |
| home-manager | no | yes, for admin's dotfiles |
| NetBird client | nix-darwin `services.netbird`, client from `nixpkgs-netbird` | Homebrew cask `netbird-ui` from NetBird's tap |
| NetBird login | setup key from sops, unattended | SSO (Pocket ID) in the app |
| SSH into it | yes, as admin, keys only | no – Remote Login stays off |
| sops secrets | yes (deploy key, deSEC token, NetBird key, Wi-Fi) | none |
| Monitoring, logs | vmagent, Vector → grammi | none – not in the topology |
| Availability | always on (`criticality: service`) | intermittent (`kind: laptop`) |

None of `modules/*.nix` applies to either Mac – those modules are written for NixOS (systemd, ifstate, nginx). What does carry over is restated in each host's `configuration.nix` in nix-darwin's terms. The one module the two share is `modules/darwin/homebrew.nix`.

## Homebrew: one policy for both Macs

Some macOS software exists only as a Homebrew cask, or should come signed by its vendor: 1Password, Vivaldi, Arq, Ghostty, the NetBird app. `modules/darwin/homebrew.nix` is imported by every `darwinConfiguration` and sets one policy (decided on 2026-10-21). It only takes effect where a host sets `homebrew.enable = true` – today that is gusto; on zorlock the module changes nothing, its system closure is identical with and without it.

**Homebrew and its taps are pinned in `flake.lock`.** Homebrew itself is not installed with the `curl | bash` script but by the `nix-homebrew` input. `homebrew-core`, `homebrew-cask` and every third-party tap are flake inputs (`flake = false`), with `mutableTaps = false`. There is no git checkout for `brew update` to move: which version of a cask a switch installs depends on `flake.lock` alone – the same logic as for nixpkgs. A host adds a tap with one line,

```nix
nix-homebrew.taps."netbirdio/homebrew-tap" = inputs.netbirdio-tap;
```

and `homebrew.taps` (the list nix-darwin writes into the Brewfile) is derived from that set automatically.

**Homebrew's own version is pinned by tag.** nix-homebrew brings a Homebrew pin of its own (7.0.4 as of 2026-10-28), which lags behind the casks: since [Homebrew/brew#24369](https://github.com/Homebrew/brew/pull/24369) (2026-10-27) homebrew-cask writes `zap :not_required`, which only Homebrew 7.0.11 and later understand ([Homebrew/brew#24315](https://github.com/Homebrew/brew/pull/24315)) – with 7.0.4 `brew bundle` stopped at `android-platform-tools`. So `flake.nix` has its own input `brew-src` on a release tag and points nix-homebrew at it (`nix-homebrew.inputs.brew-src.follows`); `modules/darwin/homebrew.nix` names the package after that tag, so the switch diff shows the real version (`brew --version` cannot tell: it says `>=4.3.0 (shallow or no git repository)` with any pin). `just mac-upgrade` does not move a tag – updating Homebrew is an edit of that line. Once nix-homebrew pins 7.0.11 or later itself, the input and the `follows` go away.

**A switch does what the configuration says – and nothing else.**

- `onActivation.autoUpdate = false`: no `brew update` during a switch.
- `onActivation.upgrade = false`: no `brew upgrade` during a switch either; an installed cask stays at its version until it is upgraded on purpose.
- `onActivation.cleanup = "zap"`: whatever is installed but not declared is removed, casks including their application data (`brew uninstall --zap`). Deleting a cask from the configuration (`apps.json`) therefore really uninstalls the app with its settings. This applies to Mac App Store apps as well (Homebrew used to leave them alone). `just mac-diff` shows this before it happens, and `just mac-switch` stops before it: if the switch would remove anything, it lists it and asks `[y/N]`; without a terminal it aborts. `MAC_SWITCH_ALLOW_REMOVALS=1 just mac-switch` goes ahead without asking. Usually the fix is to declare what is missing in `apps.json` (decided on 2026-10-23, after a switch would have removed three App Store apps installed by hand).
- `global.autoUpdate = false` and `global.brewfile = true`: the same for `brew` typed by hand, and `HOMEBREW_BUNDLE_FILE` points at the generated Brewfile, so a plain `brew bundle check` compares against the configuration.

Apps with their own updater, and Mac App Store apps, keep updating themselves; the policy only concerns what Homebrew does.

**No `brew shellenv`.** Neither nix-darwin's nor nix-homebrew's shell integration is used – both would run `brew shellenv` in every new shell and put Homebrew *in front of* Nix in `PATH`. Instead `/opt/homebrew/bin` and `sbin` are added to the system `PATH` directly, after the Nix profiles and before macOS' own directories:

```text
~/.nix-profile/bin : /etc/profiles/per-user/$USER/bin : /run/current-system/sw/bin : /nix/var/nix/profiles/default/bin : /opt/homebrew/bin : /opt/homebrew/sbin : /usr/local/bin : /usr/bin : …
```

A tool from Nix always wins over the same tool from Homebrew, Homebrew wins over Apple's stubs, and opening a shell starts no `brew` at all.

### The mac-* recipes

| Recipe | What it does |
| --- | --- |
| `just mac-diff [host]` | Builds the configuration and shows what a switch would change: the Nix closure (`nvd diff`), the casks and formulae that would be **removed** (`brew bundle cleanup --zap` without `--force`) and those that would be **installed**. Changes nothing. |
| `just mac-switch [host]` | Builds, stops if Homebrew would remove anything (see above), switches, and ends with a compact summary: Nix packages added/removed/updated (nvd) and Homebrew `- removed` / `+ new`. |
| `just mac-upgrade` | Updates only the Homebrew pins (`nix-homebrew` and every input from a `github:<owner>/homebrew-<name>` repository – `homebrew-core`, `homebrew-cask`, `netbirdio-tap`, `stablyai-orca-tap`, found in `flake.lock`), switches, runs `brew upgrade` and prints `old -> new` per upgraded item, plus the NetBird client version on gusto next to the mesh's pin. The result is a `flake.lock` change to commit. |

The host defaults to `gusto`, which is built from the working copy (uncommitted changes included – but nix only sees files git knows, so `git add` new files first). `zorlock` is reached over SSH: `git pull` in `/etc/nixos`, then the same script under sudo. `deploy-zorlock` and `check-zorlock` are now short forms of `mac-switch zorlock` and `mac-diff zorlock`. The work itself is done by `modules/darwin/rebuild.sh` on the Mac.

`mac-upgrade` exists only for gusto: it changes `flake.lock`, which is committed on the workstation; zorlock has no Homebrew.

### Software as data: apps.json

What a Mac runs – casks, Homebrew formulae, Mac App Store apps and nixpkgs packages – is not written into its `configuration.nix` but listed in `hosts/<host>/apps.json` (decided 2026-10-22; gusto today, zorlock does not opt in). `modules/darwin/apps.nix` turns the file into `homebrew.casks`, `homebrew.brews`, `homebrew.masApps`, `environment.systemPackages`, the user's `home.packages` and `fonts.packages`. Each entry is keyed by its name in its source and carries a `note` (why it is there) and the day it was `added`; nixpkgs entries also a `scope` (`system`, `user`, `font`). Taps stay Nix, in the host's configuration – they are flake inputs; `apps` can add one (below).

The file is data on purpose: a tool can add and remove entries without parsing Nix, and the configuration checks it on every evaluation – unknown sources or fields, a nixpkgs attribute that does not exist, an entry from a tap the host does not pin – and lists every problem at once (`checks.darwin-apps`). `modules/darwin/apps.schema.json` gives the editor completion and hover help.

`apps` is that tool (`pkgs/nixlab-apps`): one round of searching, adding and removing, then one switch and one commit. It searches nixpkgs, Homebrew and the Mac App Store online, groups the hits that are the same software and marks the recommended source – for a GUI app cask before App Store before nixpkgs (signed, in `/Applications`, updates itself), for a command line tool nixpkgs before a formula. The pick is then checked against the **pin**, because a switch installs what `flake.lock` says, not what the search showed: a nixpkgs package must evaluate in `nixpkgs-darwin` (available, not unfree), a cask or formula must be in the pinned tap. A missing cask or formula can bump `homebrew-cask` / `homebrew-core` in a commit of its own – harmless, `upgrade = false` leaves installed casks alone. `nixpkgs-darwin` is never bumped there: it is the whole system of both Macs. The pinned third-party taps are searched too, offline from their pin; a cask from a tap that is not pinned yet is found by its full name (`apps stablyai/orca/orca`), and picking it pins the tap – flake input, `nix-homebrew.taps` line, `nix flake lock`, a commit of its own – after showing who publishes it and asking. That question is the trust decision: every pinned tap is trusted (decided 2026-10-23, with Orca as the first such tap). Steps: [Software on the Macs](../how-to/software.md).

## NetBird on the two Macs

Both Macs are peers in the NetBird mesh, but they get their client in two different ways. This is deliberate.

### zorlock: nix-darwin module, client from the mesh pin

`hosts/zorlock/netbird.nix` turns on nix-darwin's `services.netbird`. That module runs only the daemon – `netbird service run` as a launchd daemon, as root, state in `/var/lib/netbird` – and leaves login and settings to the user. The rest is done by a second launchd job, `netbird-login`, the same pattern as on the Linux hosts:

- The **client binary** comes from the `nixpkgs-netbird` input, the pin the NetBird server on grammi and every NixOS client use. The whole mesh moves together with `nix flake update nixpkgs-netbird` – server first, then the clients.
- **Login** is unattended: `netbird-login` registers once with a single-use setup key from `hosts/zorlock/netbird.yaml` (sops, `just netbird-key zorlock`). After that the key is spent and the peer's identity lives in `/var/lib/netbird/config.json`.
- **Rosenpass** is turned off by the same job (off mesh-wide since 2026-10-24, until 2026-10-31, see below), the client's local Prometheus endpoint (`127.0.0.1:9191`, scraped by vmagent) on – nix-darwin's module has no `config.d` like the NixOS one.
- After a reboot zorlock joins the mesh only once FileVault has been unlocked (over SSH from the home LAN), because the daemon lives on the data volume.

That is what a server needs: no GUI session (zorlock should stay logged out, Ollama counts free RAM), coming back by itself, the same client version as the rest of the mesh, and metrics.

### gusto: the official app as Homebrew cask

gusto installs `netbirdio/homebrew-tap/netbird-ui`, the cask from NetBird's own tap, pinned as the flake input `netbirdio-tap` (decided on 2026-10-21). The cask is the signed menu-bar app; it depends on the formula `netbird` from the same tap (the CLI and daemon), and its installer registers the daemon as `/Library/LaunchDaemons/netbird.plist`. That is the same software the official `.pkg` installer puts on a Mac, only installed and removed through the configuration. The formula is also listed on its own (`homebrew.brews`), so `cleanup = "zap"` can never treat the daemon as an orphan and remove it from under the app.

- **Login** is interactive: in the app, with SSO through Pocket ID – the peer then belongs to the admin's user and its groups, the way a person's device should. There is no setup key and no sops file for gusto.
- **Rosenpass** is set once in the app's settings (Quantum-Resistance); the daemon keeps it in its own config. Since 2026-10-21 it is **off** on the workstation – a test against tunnels that stayed "Connected" without a WireGuard handshake after the Rosenpass key expired (upstream #3107, #3121); gusto starts the same way, off. The dead tunnels came back anyway, between two peers that both ran Rosenpass (ursalia↔zorlock, 2026-10-23: key expired without renewal, the two sides ended up with different pre-shared keys, no handshake any more – and Rosenpass itself runs through that tunnel). So since 2026-10-24 Rosenpass is **off mesh-wide** for a week, until 2026-10-31; the apps (iPhone, Apple TVs, Home Assistant) by hand. Then it is decided: no more dead tunnels – it stays off until upstream fixes the re-keying; dead tunnels anyway – Rosenpass was not the cause and comes back, permissive.
- **Version**: whatever the pinned tap holds. It changes only with `just mac-upgrade`, which prints gusto's client version next to `nixpkgs-netbird`'s so the two do not drift far apart. The usual rule still applies: the server (grammi) is updated first, clients follow.
- **Updates from elsewhere**: the app's own update notice and NetBird's dashboard-driven auto-update must not move the version behind the configuration's back; this is checked on the first switch and switched off if the app offers it.
- No metrics endpoint and no log shipping – gusto is not monitored.

### Why not the same on both?

| Question | Answer |
| --- | --- |
| Why does gusto not use the nix-darwin module like zorlock? | That module has no menu-bar app; everything would be CLI. On a laptop that changes networks all the time, the app is how one sees at a glance whether the mesh is up, switches profiles and signs in again. Login on gusto is SSO anyway, which needs a browser and a person – the unattended setup-key job that makes zorlock's variant worthwhile does not apply. |
| Why does zorlock not use the cask? | A server must come back on its own after a reboot, without anybody signing in, with the same client version as the mesh and with metrics. The cask's app needs a GUI session, and its version follows the tap, not the mesh pin. |
| Why not `netbird-ui` from nixpkgs on gusto? | nixpkgs packages the UI for Linux first; whether it builds and runs properly on macOS (signing, the menu-bar integration) is not verified, and it would not be the signed binary NetBird ships. |
| Mac App Store? | NetBird offers no Mac App Store version (only iOS). |
| What is the price? | gusto's client version is pinned separately from the mesh's (`netbirdio-tap` instead of `nixpkgs-netbird`). `just mac-upgrade` makes the gap visible; it is closed by hand. |

### The peer in Tofu

`terraform/netbird/subraum.tf` looks up the admin workstation by peer name (`data "netbird_peer"`) for the group `admin-workstations` – the group that may reach the Subraum devices and the docs site. Changing the workstation (old MacBook → gusto) is done with both peers in the group for a short while: add a second data source `gusto`, `just netbird-apply`, deploy aldrin and ursalia (docs site allow-list), test, and only then remove the old peer.

## gusto in detail

The reasons behind gusto's setup; the complete list of what is on it, every setting and the day-to-day tasks are on [gusto – the admin workstation](../reference/gusto.md).

### Starting from scratch

gusto was set up deliberately bare (2026-10-21): no app list taken over from the old installation, only a small base. Everything else is added the moment it is needed – `apps` (into `hosts/gusto/apps.json`, switch, commit), and, if there is data, it comes back from the backup.

| Where | What |
| --- | --- |
| Casks | 1Password + `1password-cli`, Vivaldi, Arq, Claude, Ghostty, NetBird |
| System (`environment.systemPackages`) | git, gh, just, jq, neovim (`EDITOR`), curl, wget, rsync |
| admin (home-manager) | zsh, atuin, fzf, zoxide, direnv + nix-direnv, bat, eza, ripgrep, fd, tree, lazygit, btop, yazi, tmux, nvd, nix-output-monitor, uv, typst |
| Font | Maple Mono NF (Nerd Font) for Ghostty and the TUIs |
| Repo tools | sops, age, ssh-to-age, opentofu, nvd – from the flake's devShell; dnscontrol from a separate one for the DNSControl repo, see below |

`op` comes as a cask and not from nixpkgs because the CLI unlocks through the 1Password app with Touch ID, which only works with the vendor's signed binary.

### XDG and home-manager

Project rule: configuration lives under `~/.config/<tool>` wherever the tool supports it – zsh (`ZDOTDIR=~/.config/zsh`), git (`~/.config/git/config`), Ghostty, tmux, direnv. A tool without XDG support keeps its real file in the classic place and gets a link `~/.config/<tool>` pointing at it, e.g. `~/.config/ssh → ~/.ssh`. Data goes to `~/.local/share`, state (zsh history) to `~/.local/state`.

`PATH` gets exactly one personal directory, `~/.local/bin`: `GOBIN` points there, `CARGO_INSTALL_ROOT` is `~/.local`, and `uv tool install` uses it by default. `GOPATH` and `CARGO_HOME` live under `~/.local/share`. No `~/go/bin`, `~/.cargo/bin` or pnpm path any more.

git: name `admin`, default address `mail@admin.org`; for everything below `~/Projects/homelab/` an `includeIf gitdir:` switches to `admin@homelab.example`.

### SSH: 1Password only

The private keys exist only in 1Password; its agent offers them. Two links make the agent reachable under a path without spaces: `~/.1password/agent.sock` (home-manager) and `SSH_AUTH_SOCK` – in every shell (home-manager) and for GUI apps through `launchd.user.envVariables`.

`~/.ssh/config` is generated by home-manager (`hosts/gusto/ssh.nix`):

- **Global lines first**, before any `Host` block (`extraOptionOverrides`): `IdentityAgent`, `IdentitiesOnly`, `Compression`, `SendEnv`. The first value ssh finds wins, so no later block – and no included file – can point the agent elsewhere. Exactly that had broken the old config: an included file's `Host *` sent IdentityAgent to another user's agent.
- **One key per target**: `IdentityFile` names the *public* half (`hosts/gusto/ssh/*.pub`, linked to `~/.ssh/pub/`). That tells the agent which key to offer; the private half never touches the disk.
- **Lab hosts are generated** from `inventory.json` – every managed host except gusto: `<host>` / `<host>.peer.homelab.example` over the mesh as root (zorlock as admin); `<host>.example-tailnet.ts.net` while Tailscale still runs; and for hosts with a public address (aldrin, grammi, zummi) `<host>.homelab.example` as admin – root is refused on public addresses (`modules/ssh.nix`), so this fallback works when the mesh is down. The alternative names use `HostKeyAlias <host>.peer.homelab.example`, so all of them are checked against the one host key from the inventory.
- **Host keys** come from the inventory (`/etc/ssh/ssh_known_hosts`, like on every host); GitHub's key is pinned in `configuration.nix`. `just known-hosts` is not needed on gusto.
- By hand: `zorlock-lan` (FileVault unlock), `opnsense`, `arkkvm`/`arkkvm01`, the Subraum router as jump host (with its port forwards), vogon, amnesia, unifi, git.c3pb.de, edi, a block for old switches that only *adds* legacy algorithms (`+…`), and GitHub (with a 60 s ControlMaster).

### devShell and direnv

The repo's own tools are not installed globally. `flake.nix` has `devShells.aarch64-darwin.default` with sops, age, ssh-to-age, opentofu and nvd from the flake's pins; `.envrc` (`use flake`) makes direnv load it whenever a shell enters the checkout – once per checkout `direnv allow`. nix-direnv caches the shell and protects it from garbage collection. The docs tools are not in it: `just docs` and `just docs-serve` fetch their own through `nix shell`.

sops on gusto takes the workstation's age key straight from 1Password: home-manager sets `SOPS_AGE_KEY_CMD='op read "op://<vault>/<item>/password"'`, `op` unlocks with Touch ID through the app – no `op signin`, no key file.

### DNSControl

The public DNS records live in the repo next door, `~/Projects/homelab/DNSControl` (local, no remote; linked in here as the `dnsconfig.js` symlink). dnscontrol comes from a second, slim devShell `devShells.aarch64-darwin.dns` that holds nothing but dnscontrol and sops; the `.envrc` there loads it with `use flake ../nixlab#dns`. DNSControl gets no `flake.nix` of its own – that keeps dnscontrol on this flake's pins, with no second `flake.lock`.

The providers' credentials (deSEC, OVH, hosting.de) live sops-encrypted in `creds.sops.json` in the repo, never in plaintext on disk. The `.sops.yaml` there names the same recipients as the Tofu modules: the workstation key and the `admin` recovery key – so they stay readable without 1Password. A wrapper does the rest:

- `bin/dnscontrol` sits in front of the real binary through the `.envrc` (`PATH_add bin`), which stores the real one's path in `DNSCONTROL_BIN`.
- For the commands that talk to providers – `preview`, `push`, `ppreview`, `ppush`, `check-creds`, `get-zones`, `get-certs` – it adds `--creds '!sops -d …/creds.sops.json --output-type json'`, unless `--creds` is on the line already. Everything else it passes through unchanged. `--output-type` comes last on purpose: dnscontrol takes a `--creds` value ending in `.json` for a file name, even after the `!`.
- sops decrypts with the workstation key (`SOPS_AGE_KEY_CMD`, Touch ID), dnscontrol reads the JSON from its output. None of it touches the disk.

The commands stay `dnscontrol preview` and `dnscontrol push`. Changing a token means `sops creds.sops.json` and a commit. The repo's `.gitignore` blocks a `creds.json`, so plaintext never gets in again. An executable `creds.json` instead of the wrapper does not work: dnscontrol does not check the executable bit for names ending in `.json`.
