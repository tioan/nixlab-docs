# Reusable module: nightly `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`
# via system.autoUpgrade, which then commits + pushes the updated flake.lock
# back to the git repo the flake lives in. Meant to be dropped into any
# host's `modules` list unchanged (see hosts/zummi for the reference usage).
{ config, lib, pkgs, ... }:

let
  cfg = config.services.autoUpgradeGit;

  # Runs as ExecStopPost, see the note at the unit below.
  resetLock = pkgs.writeShellScript "auto-upgrade-git-reset-lock" ''
    [ "$SERVICE_RESULT" = success ] && exit 0
    cd ${toString cfg.flakeDir} || exit 0
    ${pkgs.git}/bin/git checkout -- flake.lock || true
  '';
in
{
  options.services.autoUpgradeGit = {
    enable = lib.mkEnableOption "nightly auto-upgrade with automatic flake.lock commit + push";

    flakeDir = lib.mkOption {
      type = lib.types.path;
      default = /etc/nixos;
      description = "Directory containing the flake (and its git checkout) to upgrade from.";
    };

    flakeAttr = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "nixosConfigurations attribute name to build, i.e. the `#<attr>` part of the flake ref.";
    };

    updateInputs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "nixpkgs" ];
      description = "Flake inputs to update before rebuilding. Empty list skips the update step entirely.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
      description = "systemd calendar expression for when to run, passed through to system.autoUpgrade.dates.";
    };

    allowReboot = lib.mkOption {
      type = lib.types.bool;
      # true by default: this module assumes hosts using it have an
      # out-of-band emergency access path (e.g. VNC/console) that makes an
      # automatic reboot safe. Set to false per-host if that's not the case.
      default = true;
      description = "Whether to allow automatic reboots after a kernel/boot-relevant upgrade.";
    };

    rebootWindow = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          lower = lib.mkOption {
            type = lib.types.str;
            description = "Lower bound (HH:MM) of the allowed reboot window.";
          };
          upper = lib.mkOption {
            type = lib.types.str;
            description = "Upper bound (HH:MM) of the allowed reboot window.";
          };
        };
      });
      default = null;
      description = "Restrict automatic reboots to this time window. Null means no restriction beyond `dates`.";
    };

    deployKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "git_deploy_key";
      description = ''
        Name of the sops secret holding the write-enabled SSH deploy key for
        the flake's git repo. Declared automatically by this module
        (mode 0400, owner root) - just put the key under this name in the
        host's secrets.yaml.
      '';
    };

    holdFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Skip the whole run (no input update, no switch, no reboot) while this
        file exists - the host deliberately runs something other than the
        checkout. Checked by `holdCheck`, which must exit 0 to go ahead and
        1 to skip (systemd's ExecCondition semantics); null disables both.
      '';
    };

    holdCheck = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "nixos-hold merged /etc/nixos";
      description = ''
        Command deciding whether `holdFile` still applies. Null means the
        file's presence alone skips the run.
      '';
    };

    gitAuthorEmail = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}@${config.networking.domain}";
      description = "Email used for the git author/committer identity of the automated flake.lock commit.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.${cfg.deployKeySecret} = {
      mode = "0400";
      owner = "root";
    };

    system.autoUpgrade = {
      enable = true;
      flake = "${toString cfg.flakeDir}#${cfg.flakeAttr}";
      # Deliberately no --update-input here; see the mkBefore block on the
      # unit below for why the inputs are updated as an explicit step instead.
      flags = [ "-L" ];
      dates = cfg.dates;
      randomizedDelaySec = "45min";
      persistent = true;
      allowReboot = cfg.allowReboot;
      rebootWindow = cfg.rebootWindow;
    };

    systemd.services.nixos-upgrade = {
      # git/ssh need to be resolvable as bare commands both in our appended
      # script below and inside GIT_SSH_COMMAND.
      path = [ pkgs.git pkgs.openssh ];

      # A failed run leaves the tree dirty, and that breaks the *next* deploy.
      # system.autoUpgrade's script runs `nix flake update` and then the
      # rebuild under `set -e`, so when the rebuild fails the mkAfter block
      # below never runs and the updated flake.lock stays behind as an
      # uncommitted modification in the checkout. `just sync` then does a
      # plain `git pull`, which refuses to fast-forward over a local
      # modification - the same trap already documented for secrets.yaml in
      # the justfile, and a nasty one, because the symptom (deploys stop
      # working) surfaces far away from the cause (a nightly upgrade nobody
      # watched fail). Observed on zummi on 2026-08-21 after three nights of
      # oom-killed upgrades.
      #
      # Discard the lock on any non-success result. Nothing is lost: that
      # lock was never built or activated, and the next run updates it again.
      serviceConfig.ExecStopPost = [ "${resetLock}" ];

      # A hold (modules/deploy-hold.nix) means a topic branch is being tried
      # on this host; rebuilding the checkout would silently switch it back.
      # ExecCondition, not an early `exit 0` in the script: exit 1 there ends
      # the unit as skipped - not failed, and before preStart's input update.
      serviceConfig.ExecCondition = lib.mkIf (cfg.holdFile != null) [
        (pkgs.writeShellScript "auto-upgrade-git-hold" (
          if cfg.holdCheck != null then cfg.holdCheck
          else ''
            [ -e ${cfg.holdFile} ] || exit 0
            echo "auto-upgrade-git: ${cfg.holdFile} exists, skipping"
            exit 1
          ''))
      ];

      # Update the flake inputs before system.autoUpgrade's own script builds
      # and switches. This used to be `--update-input <input>` handed through
      # `flags`, which nix now warns is "a deprecated alias for 'flake update'
      # and will be removed in a future version". Because that flag reaches
      # nix through the rebuild itself, the release that finally drops it
      # would break the nightly on every host in this lab on the same night,
      # unattended and for a reason visible only in a log nobody reads. Doing
      # the update as its own step removes that failure mode, and says plainly
      # what it does.
      #
      # `cd` rather than `--flake`: passing input names positionally predates
      # the `--flake` option, so this form works across more nix versions than
      # the alternative.
      #
      # preStart, not `script = lib.mkBefore ...`: the mkAfter block further
      # down already defines `script`, and an attrset cannot define the same
      # attribute twice - merging the two would need an explicit mkMerge and
      # bury both bodies inside it. ExecStartPre is the plainer fit anyway,
      # and it fails the unit the same way, so a broken update stops short of
      # the rebuild and ExecStopPost above puts flake.lock back.
      preStart = lib.optionalString (cfg.updateInputs != [ ]) ''
        cd ${toString cfg.flakeDir}
        ${config.nix.package}/bin/nix flake update ${lib.escapeShellArgs cfg.updateInputs}
      '';

      # NOTE: this must be `environment` (an attrset), not
      # `serviceConfig.Environment` (a list of raw strings) - systemd's
      # Environment= line splits unquoted values on whitespace, so values
      # containing spaces (the "<host> auto-upgrade" names, the GIT_SSH_COMMAND
      # with its `-o` flags) got silently truncated at the first space when
      # passed as raw strings. `environment` gets quoted correctly by the
      # NixOS systemd module.
      environment = {
        GIT_AUTHOR_NAME = "${cfg.flakeAttr} auto-upgrade";
        GIT_AUTHOR_EMAIL = cfg.gitAuthorEmail;
        GIT_COMMITTER_NAME = "${cfg.flakeAttr} auto-upgrade";
        GIT_COMMITTER_EMAIL = cfg.gitAuthorEmail;
        GIT_SSH_COMMAND = "ssh -i ${config.sops.secrets.${cfg.deployKeySecret}.path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new";
      };

      # system.autoUpgrade defines the actual `nix flake update` +
      # `nixos-rebuild switch` invocation via `script`. mkAfter appends this
      # so it only runs once that has completed successfully (the script
      # runs under `set -e`, so a failed switch never reaches this point).
      # The push can legitimately be rejected as non-fast-forward: the checkout
      # goes stale as soon as anything is pushed from elsewhere (a workstation
      # deploy, or the *other* host's auto-upgrade landing its own flake.lock
      # commit - with several hosts on this module that is the normal case, not
      # the exception). The previous `git push || echo WARN` swallowed that, so
      # the host quietly accumulated commits that never reached the remote.
      # Retry once on top of whatever landed meanwhile.
      script = lib.mkAfter ''
        cd ${toString cfg.flakeDir}
        if ! git diff --quiet -- flake.lock; then
          git add flake.lock
          git commit -m "flake.lock: auto-upgrade on ${cfg.flakeAttr} ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
          if ! git push; then
            # -X theirs keeps this host's flake.lock if upstream touched it
            # too. git's naming is inverted during a rebase: "theirs" is the
            # commit being replayed, i.e. ours. Keeping ours is the right call
            # because it is the lock we just built and activated against.
            if git pull --rebase -X theirs && git push; then
              echo "auto-upgrade-git: pushed after rebasing onto upstream"
            else
              git rebase --abort || true
              echo "WARN: auto-upgrade-git: could not push updated flake.lock;" \
                   "/etc/nixos on ${cfg.flakeAttr} now holds an unpushed commit"
            fi
          fi
        fi
      '';
    };
  };
}
