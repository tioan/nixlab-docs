# Deploy holds: a host runs a topic branch and nothing may switch it back to
# main until that branch is merged.
#
# `just try <host>` deploys the current worktree with deploy-push and then
# writes /etc/nixos-hold on the host (branch, commit, since, by). Everything
# that would otherwise switch the host back to main quietly honours it:
#
#   - the nightly nixos-upgrade (modules/auto-upgrade-git.nix, holdFile)
#   - `just rebuild` / `just deploy` / `ship` / `deploy-all` (justfile)
#   - `just deploy-push` from another checkout (justfile)
#   - ursalia's nightly push to cuckoosegg (hosts/ursalia/push-cuckoosegg.nix)
#
# The rule is the same everywhere: a hold blocks a deploy unless the held
# commit is contained in what is about to be deployed - then the branch has
# been merged, the hold has done its job and is removed. A rebase merge
# rewrites the commit, so that case needs `just release <host>`.
#
# Visibility: a node_exporter textfile metric (nixlab_deploy_hold_since_seconds,
# panel "Deploy holds" in Homelab / Hosts Overview, red after 48 h) and a
# warning in every interactive login shell on the host.
{ pkgs, ... }:
let
  holdFile = "/etc/nixos-hold";
  # Same directory modules/metrics.nix points node_exporter's textfile
  # collector at.
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";

  nixos-hold = pkgs.writeShellApplication {
    name = "nixos-hold";
    runtimeInputs = [ pkgs.git pkgs.coreutils pkgs.gnused ];
    text = ''
      hold=${holdFile}
      field() { sed -n "s/^$1=//p" "$hold" | head -n1; }
      refresh() { systemctl start --no-block deploy-hold-metrics.service 2>/dev/null || true; }

      case "''${1:-status}" in
        status)
          if [ -e "$hold" ]; then
            since=$(field since)
            echo "held by branch $(field branch) at $(field commit)" \
                 "since $(date -d "@$since" '+%Y-%m-%d %H:%M') ($(( ($(date +%s) - since) / 3600 )) h), by $(field by)"
          else
            echo "no hold"
          fi
          ;;
        # Machine-readable, for the justfile: prints `branch commit`, nothing
        # without a hold.
        get)
          if [ -e "$hold" ]; then echo "$(field branch) $(field commit)"; fi
          ;;
        set)
          [ $# -eq 4 ] || { echo "usage: nixos-hold set <branch> <commit> <by>" >&2; exit 2; }
          printf 'branch=%s\ncommit=%s\nsince=%s\nby=%s\n' "$2" "$3" "$(date +%s)" "$4" > "$hold.tmp"
          mv "$hold.tmp" "$hold"
          refresh
          ;;
        clear)
          rm -f "$hold"
          refresh
          ;;
        # Exit 0 when nothing holds the host back from <repo>'s HEAD: no hold,
        # or the held commit is in HEAD's history (merged - the hold is then
        # removed). Exit 1 otherwise, which is what systemd's ExecCondition
        # treats as "skip this run" rather than a failure. A held commit the
        # repo does not know at all counts as not merged.
        merged)
          [ $# -eq 2 ] || { echo "usage: nixos-hold merged <repo>" >&2; exit 2; }
          [ -e "$hold" ] || exit 0
          commit=$(field commit)
          if git -C "$2" merge-base --is-ancestor "$commit" HEAD 2>/dev/null; then
            echo "nixos-hold: branch $(field branch) ($commit) is merged, removing the hold"
            rm -f "$hold"
            refresh
            exit 0
          fi
          echo "nixos-hold: held by branch $(field branch) at $commit, not in $2's HEAD - skipping"
          exit 1
          ;;
        *)
          echo "usage: nixos-hold [status|get|set <branch> <commit> <by>|clear|merged <repo>]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ nixos-hold ];

  # Interactive shells only, so `ssh host <command>` output stays clean.
  environment.interactiveShellInit = ''
    if [ -e ${holdFile} ]; then
      echo "*** deploy hold: $(${nixos-hold}/bin/nixos-hold status)"
      __since=$(sed -n 's/^since=//p' ${holdFile})
      if [ $(( $(date +%s) - ''${__since:-0} )) -gt 172800 ]; then
        echo "*** older than 48 h - merge the branch, or \`just release $(hostname)\`"
      fi
      unset __since
    fi
  '';

  # One sample while a hold exists, none otherwise, so the panel empties
  # itself after a merge. Labels lose quotes and backslashes; git allows a
  # quote in a branch name, the text format does not without escaping.
  systemd.services.deploy-hold-metrics = {
    description = "Deploy hold for node_exporter's textfile collector";
    path = [ pkgs.coreutils pkgs.gnused ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      out=${textfileDir}/deploy-hold.prom
      {
        echo "# HELP nixlab_deploy_hold_since_seconds Unix time a topic branch was deployed with just try; absent without a hold."
        echo "# TYPE nixlab_deploy_hold_since_seconds gauge"
        if [ -e ${holdFile} ]; then
          f() { sed -n "s/^$1=//p" ${holdFile} | head -n1 | tr -d '"\\'; }
          echo "nixlab_deploy_hold_since_seconds{branch=\"$(f branch)\",commit=\"$(f commit)\"} $(f since)"
        fi
      } > "$out.tmp"
      chmod 0644 "$out.tmp"
      mv "$out.tmp" "$out"
    '';
  };
  systemd.timers.deploy-hold-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "15min";
    };
  };
}
