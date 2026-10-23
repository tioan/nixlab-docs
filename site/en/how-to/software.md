# Software on the Macs

Everything installed on gusto – casks, Homebrew formulae, Mac App Store apps, nixpkgs packages and fonts – is listed in `hosts/gusto/apps.json`. Three commands manage it – `apps`, `apps-list` and `apps-rm`, installed on gusto and usable from any directory; inside the checkout `just apps`, `just apps-list` and `just apps-rm` do the same. The background (why a data file, why the pin check) is in [macOS hosts](../explanation/macos-hosts.md#software-as-data-appsjson).

## One round: add and remove

```bash
apps obsidian
```

The start term is optional (`apps` alone starts with an empty search). One round is any number of changes and ends with one switch and one commit:

```
╭──────────── search: obsidian  filter: export ─╮   ← both fields
│ filter> export                                 │   ← the active one
╰────────────────────────────────────────────────╯
  this round:  + ripgrep (nixpkgs, user)   − shottr (cask) ZAP
  enter: add / remove   tab: search ⇄ filter   ctrl-s: done   esc: cancel
  nixpkgs ✓ 12  Homebrew ✓ 2  App Store ✓ 10
   nixpkgs  obsidian-export   25.3.0   CLI  Rust library and CLI to export …
…
  [ Done · ctrl-s ]  [ Cancel · esc ]     shift-tab: buttons
```

- **Two fields, `tab` switches between them.** `search>` searches online; `filter>` (optional) narrows the results of that search in fzf, fuzzy, without searching again (`'word` for an exact match). A new search term empties the filter – it was for the old results. The border above shows both.
- **The search** runs as you type (from 2 characters, after a short pause) against nixpkgs (search.nixos.org, release of `nixpkgs-darwin`), Homebrew (formulae.brew.sh), the Mac App Store and the third-party taps gusto pins (offline, from their pin). A fully qualified term – `owner/tap/name`, as in `brew install --cask owner/tap/name` – also looks that one cask or formula up on GitHub when its tap is not pinned yet (see [A cask from a third-party tap](#a-cask-from-a-third-party-tap)). If search.nixos.org is down, `nix search` against the pin takes over – slower, but always there. The line above the list says what each source returned.
- **★** marks the recommended source where the same software exists more than once: for a GUI app cask before App Store before nixpkgs, for a command line tool nixpkgs before a Homebrew formula. The preview below shows description, version, licence, homepage – and for a declared entry its note.
- **Enter on a new hit adds it.** The list closes for the questions:
    1. The pin check –

        | Source | Check | If it fails |
        | --- | --- | --- |
        | nixpkgs | evaluates in the pinned `nixpkgs-darwin`, available on aarch64-darwin, not unfree | not added – it comes with the next system update; unfree: take the cask |
        | cask / formula | the `.rb` file is in the pinned tap | offers to bump `homebrew-cask` / `homebrew-core` (own commit) |
        | cask / formula from a tap that is not pinned | – (comes before the check) | shows who publishes the tap and what it downloads, then offers to pin **and trust** it (own commit) |
        | App Store | – (no pin, the store installs the current version) | – |

    2. for nixpkgs the scope: `user` (admin's `home.packages`, the default), `system` (root and every shell) or `font`;
    3. a note – why it is there, in English, like a comment in the configuration; Enter leaves it out.

    Then the list is back with the same search and filter, in the field you were in, ready for the next one. Ctrl-C during the questions skips that hit.
- **Enter on a declared entry (✓) marks it for removal** (red, struck through, `−`). Nothing is deleted yet.
- **Enter on something added or marked this round undoes it.**
- The header line lists the round: `+` green, `−` red, **ZAP** for a cask – removing a cask deletes the app *and its data* (settings, caches, containers) on the switch.

**Done** – `ctrl-s`, or `shift-tab` to the *Done* button and Enter (a click works too):

1. the round once more, then the configuration is evaluated; if that fails, the error is shown and you are back in the list;
2. casks to zap: `just mac-diff` shows them, then *Continue? [y/N]* – no takes you back to the list;
3. on gusto itself: switch? (default yes, no if something is zapped);
4. the commit follows a successful switch – or a declined one; a failed switch leaves everything uncommitted.

One commit per round, `apps.json` only: `gusto: add obsidian (cask), remove shottr (cask)`, with a list in the body; a longer round is counted in the subject (`gusto: add 3 and remove 1 apps`). A tap bump is a commit of its own before it (`flake.lock: bump homebrew-cask for …`), so is a new tap (`gusto: pin tap stablyai/homebrew-orca for orca`).

**Cancel** – `esc`, or the *Cancel* button: with changes in the round it asks *Discard N change(s)?*, then `apps.json` (and `flake.lock`, and for a new tap `flake.nix` and `configuration.nix`) are back as they were. If `apps.json` already has uncommitted changes when `apps` starts, it stops before changing anything; the same for the other files once a round would change them.

## A cask from a third-party tap

Some vendors publish their Mac app only in a tap of their own; their install line then reads `brew install --cask <owner>/<tap>/<name>`. Give `apps` exactly that name:

```bash
apps stablyai/orca/orca
```

- Once the tap is pinned, its casks and formulae show up in every search like the others; the search reads them from the pin, without the network. In `apps.json` they are `"<owner>/homebrew-<tap>/<name>"`, e.g. `stablyai/homebrew-orca/orca`.
- A tap that is not pinned yet is found only through the fully qualified name; the hit is marked *tap not pinned*. Enter on it shows who publishes the tap (GitHub owner, verified or not, age of the repository, last push) and the URLs the cask downloads from, and asks *Pin stablyai/homebrew-orca as flake input stablyai-orca-tap for gusto and trust it?*
- **Yes** adds the input to `flake.nix` (after the last tap input, with a generated comment – rewrite it if the reason deserves more), the line `nix-homebrew.taps."stablyai/homebrew-orca" = inputs.stablyai-orca-tap;` to `hosts/gusto/configuration.nix` and runs `nix flake lock`. Then the usual pin check and the note follow. Because the start term named exactly this cask, the round ends right there – no return to the list, no *Switch?* question: summary, evaluation, `just mac-switch`, then the tap as a commit of its own (`flake.nix`, `flake.lock`, `configuration.nix`) before the one of `apps.json`. The same holds for `apps owner/tap/name` whose tap is already pinned. A round with a removal still asks before the switch.
- **Every pinned tap is trusted** (`brew trust`, [macOS hosts](../explanation/macos-hosts.md#homebrew-one-policy-for-both-macs)): a cask runs its install code as you. Check the publisher before saying yes.
- From then on `just mac-upgrade` bumps the new input with the others – it finds every tap input in `flake.lock` by itself.

Removing the last cask of a tap leaves the tap pinned and trusted; take it out by hand (input, `nix-homebrew.taps` line, `nix flake lock`).

## Remove one thing directly

```bash
apps-rm shottr
```

For a single removal without the search. A cask wants its name typed to confirm, then `just mac-diff`, switch (default no), commit. A **Mac App Store** app, too, is uninstalled on the switch when its entry goes. If a name is declared from two sources, choose with `--source`, e.g. `apps-rm obsidian --source nixpkgs`.

## List

```bash
apps-list
```

By source, with the date it came in and the note.

## By hand

`apps.json` can be edited directly (the editor completes fields through `modules/darwin/apps.schema.json`), then `just mac-diff` and `just mac-switch`. Mistakes show up on evaluation with the complete list of problems; `nix build .#checks.aarch64-darwin.darwin-apps` checks the file alone.

Not in `apps.json`:

- **A new third-party tap** – it is a flake input: `apps <owner>/<tap>/<name>` adds it (above); by hand, add the input in `flake.nix` and `nix-homebrew.taps."<owner>/homebrew-<tap>" = inputs.<input>;` in `hosts/gusto/configuration.nix`, then `nix flake lock`. Its casks and formulae are then `"<owner>/homebrew-<tap>/<name>"` in `apps.json`.
- **A tool with configuration** – `programs.<tool>` in `hosts/gusto/home.nix` (zsh, git, tmux, …).

## Which checkout, which Mac

The commands change the nixlab checkout (or worktree) the current directory is in; anywhere else the one in `NIXLAB_REPO` (`~/Projects/homelab/nixlab`, set in `home.nix`), or `--repo <path>`. They are the package `nixlab-apps` from this flake, installed through `home.nix` – a change to the tool itself arrives with the next `just mac-switch`; `just apps*` always runs the working copy's version.

The host defaults to gusto; `--host zorlock` works provided the host has `nixlab.apps.file` set – zorlock does not today. For a Mac other than the one you are on, the round commits without switching; then `just push` and `just mac-switch <host>`.
