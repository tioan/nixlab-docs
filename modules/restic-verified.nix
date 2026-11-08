# A backup only counts as successful once that has been verified (#238).
#
# On 2026-11-08 ursalia's job to aldrin failed, and `systemctl show` still said
# Result=success: the nightly switch resets failed units, and success is what
# a reset unit reports. Apart from that, a unit's result says little anyway.
# restic exits 0 when --files-from names a missing path (tested with 0.18.1)
# or an empty directory, and it happily stores yesterday's dump when today's
# failed. So for each job listed here this module replaces the ExecStart of
# services.restic.backups.<name> with modules/restic-verified.sh:
#
#   before  every required path holds something, declared inputs (dumps, the
#           paperless export) finished successfully within maxAgeHours
#   backup  always attempted; if the checks above failed the snapshot is tagged
#           `unverified`, because one bad part must not cost the night's other
#           new data
#   after   the snapshot is read back from the repository: it exists, it is
#           from this run, its size is plausible against the last verified one,
#           the required paths are in it, `restic check` passes (Sundays with
#           a sample of the data, checkSubset)
#   only then
#           nixlab_backup_verified_timestamp_seconds moves and forget/prune
#           runs. Anything else sets nixlab_backup_last_run_failed, which only
#           a verified run clears and which, being a file, survives switches.
#
# Failed jobs are started again by a timer after the upgrade window, for
# whatever the reason was. Alerts: hosts/grammi/alerting.nix. Restoring: use the
# snapshot ID in nixlab_backup_verified_snapshot_info rather than `latest`,
# which may be an `unverified` one.
#
# Requires `initialize = false`: the module's `restic cat config || restic init`
# would answer an emptied bucket with a new repository that then counts as a
# backup, and costs another five minutes when the target is unreachable.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.resticVerified;
  stateDir = "/var/lib/restic-verified";
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";

  tool = name: pkgs.writeShellApplication {
    name = "restic-verified";
    runtimeInputs = [
      config.services.restic.backups.${name}.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.jq
      config.systemd.package
    ];
    text = builtins.readFile ./restic-verified.sh;
  };

  jobConfig = name: job:
    let backup = config.services.restic.backups.${name};
    in pkgs.writeText "restic-verified-${name}.json" (builtins.toJSON {
      inherit name stateDir textfileDir;
      inherit (job) inputs maxAgeHours minPercent retryIfOlderThanHours checkSubset;
      requiredPaths = if job.requiredPaths != null then job.requiredPaths else backup.paths;
      # Same arguments as the NixOS module would pass.
      backupArgs = backup.extraBackupArgs
        ++ lib.optional (backup.exclude != [ ])
        "--exclude-file=${pkgs.writeText "exclude-patterns" (lib.concatStringsSep "\n" backup.exclude)}"
        ++ [ "--files-from=/run/restic-backups-${name}/includes" ];
      pruneArgs = backup.pruneOpts;
    });

  command = name: job: verb: "${lib.getExe (tool name)} ${verb} ${jobConfig name job}";

  # After the unit ended, not ExecStartPost: for Type=simple (the paperless
  # exporter) that would run right after the start, whatever the outcome.
  stampScript = pkgs.writeShellScript "restic-verified-stamp" ''
    if [ "''${SERVICE_RESULT:-}" = success ] && [ "''${EXIT_STATUS:-}" = 0 ]; then
      ${pkgs.coreutils}/bin/touch "${stateDir}/stamps/$1"
    fi
  '';

  allInputs = lib.unique (lib.concatMap (job: job.inputs) (lib.attrValues cfg.jobs));
in
{
  options.services.resticVerified.jobs = lib.mkOption {
    default = { };
    description = "Jobs of services.restic.backups whose success gets verified.";
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        requiredPaths = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          description = "Paths that must hold data, before and in the snapshot. Default: the job's `paths`.";
        };
        inputs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Service names (no suffix) that produce what the job stores and must have succeeded recently.";
        };
        maxAgeHours = lib.mkOption {
          type = lib.types.ints.positive;
          default = 26;
          description = "How old the last successful run of an input may be.";
        };
        minPercent = lib.mkOption {
          type = lib.types.ints.between 1 100;
          default = 50;
          description = "Files and bytes must reach this share of the last verified snapshot.";
        };
        checkSubset = lib.mkOption {
          type = lib.types.str;
          default = "5%";
          description = "Share of the repository's data that `restic check` reads on Sundays.";
        };
        retryAt = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          # After the upgrade/reboot window (04:00, modules/deploy.nix).
          default = [ "05:15" "07:15" ];
          description = "When to start the job again if it is not verified.";
        };
        retryIfOlderThanHours = lib.mkOption {
          type = lib.types.ints.positive;
          default = 20;
          description = "A retry does nothing while the last verified backup is younger than this.";
        };
      };
    });
  };

  config = lib.mkIf (cfg.jobs != { }) {
    assertions = lib.mapAttrsToList
      (name: _: {
        assertion = (config.services.restic.backups.${name}.initialize or true) == false;
        message = "services.resticVerified.jobs.${name}: needs services.restic.backups.${name} with initialize = false.";
      })
      cfg.jobs;

    systemd.tmpfiles.settings."10-restic-verified" = {
      ${stateDir}.d = { mode = "0750"; };
      "${stateDir}/stamps".d = { mode = "0750"; };
    };

    systemd.services = lib.mkMerge (
      (lib.mapAttrsToList
        (name: job: {
          "restic-backups-${name}".serviceConfig = {
            ExecStart = lib.mkForce [ (command name job "run") ];
            ExecStopPost = [ (command name job "stop") ];
          };

          "restic-verified-retry-${name}" = {
            description = "Start backup ${name} again unless it is verified";
            serviceConfig.Type = "oneshot";
            serviceConfig.ExecStart = command name job "retry";
          };

          # So that a job which has never been verified shows up as such,
          # instead of not at all.
          "restic-verified-metrics-${name}" = {
            description = "Metrics of backup ${name}";
            wantedBy = [ "multi-user.target" ];
            after = [ "systemd-tmpfiles-setup.service" ];
            serviceConfig.Type = "oneshot";
            serviceConfig.ExecStart = command name job "metrics";
          };
        })
        cfg.jobs)
      ++ map
        (input: {
          ${input}.serviceConfig.ExecStopPost = [ "+${stampScript} ${input}" ];
        })
        allInputs
    );

    systemd.timers = lib.mapAttrs'
      (name: job: lib.nameValuePair "restic-verified-retry-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = job.retryAt;
          RandomizedDelaySec = "10min";
        };
      })
      cfg.jobs;
  };
}
