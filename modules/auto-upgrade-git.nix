# Reusable module: nightly `nixos-rebuild switch --flake <flakeDir>#<flakeAttr>`
# via system.autoUpgrade, optionally after fast-forwarding the checkout the
# flake lives in to a verified upstream commit. It never commits or pushes: a
# flake.lock changed by `updateInputs` is built and switched, then reset at
# the next start. Meant to be dropped into any host's `modules` list
# unchanged (see hosts/zummi for the reference usage).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  textfileDir = config.services.textfileMetrics.directory;
  cfg = config.services.autoUpgradeGit;

  # Runs as ExecStopPost, see the note at the unit below.
  resetLock = pkgs.writeShellScript "auto-upgrade-git-reset-lock" ''
    [ "$SERVICE_RESULT" = success ] && exit 0
    cd ${toString cfg.flakeDir} || exit 0
    ${pkgs.git}/bin/git checkout -- flake.lock || true
  '';

  # Runs as ExecStartPost, i.e. only after a successful run. The unit's own
  # failed state is no record of past runs - the next switch clears it - so
  # the time of the last success is kept for hosts/grammi/alerting/units-updates.nix
  # (NixosUpgradeStale). The textfile collector's root directory
  # (modules/textfile-metrics-lab.nix): the upgrade is a root job anyway (#320).
  markSuccess = pkgs.writeShellScript "auto-upgrade-git-mark-success" ''
    set -eu
    out=${textfileDir}/nixos-upgrade.prom
    {
      echo "# HELP nixlab_nixos_upgrade_last_success_seconds Unix time of the last successful nixos-upgrade run."
      echo "# TYPE nixlab_nixos_upgrade_last_success_seconds gauge"
      echo "nixlab_nixos_upgrade_last_success_seconds $(${pkgs.coreutils}/bin/date +%s)"
    } > "$out.tmp"
    ${pkgs.coreutils}/bin/chmod 0644 "$out.tmp"
    ${pkgs.coreutils}/bin/mv "$out.tmp" "$out"
  '';
in
{
  options.services.autoUpgradeGit = {
    enable = lib.mkEnableOption "nightly auto-upgrade of the flake checkout";

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

    pull = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Fast-forward the checkout (`git pull --ff-only`) before updating and
        rebuilding. With `updateInputs = [ ]` this makes the host follow a
        flake.lock that is updated - and ideally prebuilt - elsewhere.
      '';
    };

    verifySignatures = {
      enable = lib.mkEnableOption ''
        signature checks before `pull` merges anything: the upstream commit
        must be SSH-signed by `trustedSigners`, or be a lock-only commit by
        `lockOnlySigners` on top of such a commit (rules in
        auto-upgrade-git-pull.nix). Anything else fails the run before the
        rebuild, and the host stays on what it runs'';

      trustedSigners = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          alice = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
        };
        description = ''
          Signer name to SSH public key. A commit signed by one of these is
          accepted together with all history below it.
        '';
      };

      lockOnlySigners = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
        };
        description = ''
          Signer name to SSH public key, for a machine that commits the
          updated flake.lock. Accepted only for a single-parent commit that
          changes flake.lock and nothing else, on top of an accepted commit.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        default = pkgs.callPackage ./auto-upgrade-git-pull.nix { } {
          inherit (cfg.verifySignatures) trustedSigners lockOnlySigners;
        };
        defaultText = lib.literalMD "`auto-upgrade-git-pull` for the signers above";
        description = ''
          The verifying pull (`auto-upgrade-git-pull <dir>`, or `--verify
          <rev>`), for other units that pull the same checkout.
        '';
      };
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
      type = lib.types.nullOr (
        lib.types.submodule {
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
        }
      );
      default = null;
      description = "Restrict automatic reboots to this time window. Null means no restriction beyond `dates`.";
    };

    deployKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "git_deploy_key";
      description = ''
        Name of the sops secret holding the SSH deploy key for the flake's
        git repo. Read-only is enough: this module never pushes. Declared automatically by this module
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
      description = "Email used for the git author/committer identity of git operations run by the unit.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.verifySignatures.enable -> cfg.pull;
        message = "services.autoUpgradeGit.verifySignatures needs pull = true - there is nothing to verify otherwise.";
      }
      {
        # A verified checkout must build exactly the signed lock; updating
        # inputs on top of it would build something no signer has seen.
        assertion = cfg.verifySignatures.enable -> cfg.updateInputs == [ ];
        message = "services.autoUpgradeGit.verifySignatures needs updateInputs = [ ]: the host would build a lock no signer has seen.";
      }
    ];

    # The verifying pull for interactive use (`just sync`) and the
    # allowed-signers file it checks against, to read or test by hand:
    #   git -c gpg.ssh.allowedSignersFile=/etc/auto-upgrade-git/allowed-signers log --show-signature -1
    environment.systemPackages = lib.mkIf cfg.verifySignatures.enable [ cfg.verifySignatures.package ];
    environment.etc."auto-upgrade-git/allowed-signers" = lib.mkIf cfg.verifySignatures.enable {
      source = cfg.verifySignatures.package.allowedSigners;
    };

    sops.secrets.${cfg.deployKeySecret} = {
      mode = "0400";
      owner = "root";
    };

    # Seed the success marker (markSuccess above) on the first activation
    # with this module, so the alert has a value to age from instead of
    # nothing at all. A switch is as good a starting point as any: the host
    # has just been brought up to date.
    system.activationScripts.nixos-upgrade-marker = ''
      d=${textfileDir}
      if [ -d "$d" ] && [ ! -e "$d/nixos-upgrade.prom" ]; then
        ${markSuccess}
      fi
    '';

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
      path = [
        pkgs.git
        pkgs.openssh
      ];

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
      serviceConfig.ExecStartPost = [ "${markSuccess}" ];

      # ExecStopPost is bounded by TimeoutStopSec, 90s by default - and it
      # runs while the timed-out build is still in this cgroup, dying slowly
      # and holding the unit's memory, CPU and IO limits. On zummi on
      # 2026-10-29, -30 and -31 a thrashing Go build ran into
      # TimeoutStartSec, and the `git checkout` in resetLock then took longer
      # than those 90s and was killed with it, leaving flake.lock modified.
      # Ten minutes is plenty for one file; the reset at the start of the run
      # (preStart below) catches whatever still slips through.
      serviceConfig.TimeoutStopSec = "10min";

      # A hold (modules/deploy-hold.nix) means a topic branch is being tried
      # on this host; rebuilding the checkout would silently switch it back.
      # ExecCondition, not an early `exit 0` in the script: exit 1 there ends
      # the unit as skipped - not failed, and before preStart's input update.
      serviceConfig.ExecCondition = lib.mkIf (cfg.holdFile != null) [
        (pkgs.writeShellScript "auto-upgrade-git-hold" (
          if cfg.holdCheck != null then
            cfg.holdCheck
          else
            ''
              [ -e ${cfg.holdFile} ] || exit 0
              echo "auto-upgrade-git: ${cfg.holdFile} exists, skipping"
              exit 1
            ''
        ))
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
      #
      # Before anything else, put flake.lock back to HEAD: a lock left behind
      # by a run that was killed too hard for ExecStopPost (power loss, a hard
      # reset, resetLock's own timeout) must not be built tonight or block the
      # pull below. Then, with `pull`, fast-forward to what was pushed
      # elsewhere - typically the lock another host updated and prebuilt.
      # With verifySignatures only to a commit that passes the check; a
      # refusal fails the run here, before anything is built or switched.
      preStart = ''
        cd ${toString cfg.flakeDir}
        git checkout -- flake.lock
      ''
      + lib.optionalString cfg.pull (
        if cfg.verifySignatures.enable then
          "${lib.getExe cfg.verifySignatures.package} .\n"
        else
          "git pull --ff-only\n"
      )
      + lib.optionalString (cfg.updateInputs != [ ]) ''
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
        GIT_SSH_COMMAND = "ssh -i ${
          config.sops.secrets.${cfg.deployKeySecret}.path
        } -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes";
      };
    };
  };
}
