# restic jobs that back up to the lab's Garage S3 store, one bucket each
# (#318). Each job gets what every host used to write out by hand: the
# repository password and the bucket key from sops, the S3 environment file,
# the repository URL, `initialize = false` (modules/restic-verified.nix
# explains why), the timer, the prune policy and the verification by
# modules/restic-verified.nix. Optionally one job per host is watched by the
# restic exporter, which the NixOS module runs once per host - with a
# read-only key of its own, if the host has one (exporter.ownKey).
#
# Not here: buckets and keys (terraform/garage), what a job reads and how it
# makes that consistent (`paths`, `prepare`, `cleanup` per job), restic jobs
# with other targets (BorgBase on ursalia).
#
# Setting up a job: bucket and key in terraform/garage, `just garage-apply`,
# the secrets into the job's sops file, deploy, then once `restic-<job> init`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.resticGarage;

  secretNames =
    name: job:
    if job.hostSecrets then
      {
        password = "restic_password";
        keyId = "garage_backup_key_id";
        secretKey = "garage_backup_secret_key";
        env = "restic-s3-env";
      }
    else
      {
        password = "restic_${name}_password";
        keyId = "restic_${name}_key_id";
        secretKey = "restic_${name}_secret_key";
        env = "restic-${name}-s3-env";
      };

  # The exporter runs under DynamicUser and cannot read root-owned sops files;
  # the job it watches shares its password and S3 environment with it (the
  # environment only while the exporter has no key of its own). Whether
  # that is needed at all: #462.
  watched = name: cfg.exporter.job == name;
  exporterAccess =
    name:
    lib.optionalAttrs (watched name) {
      group = "restic-metrics";
      mode = "0440";
    };
  envAccess = name: lib.optionalAttrs (!cfg.exporter.ownKey) (exporterAccess name);

  # The exporter's own key: read-only on the job's bucket, so the process
  # that runs every hour cannot delete or overwrite the repository (#312).
  # Root-only like any sops file: systemd reads the EnvironmentFile before
  # it drops to the exporter's dynamic user.
  exporterKey = {
    keyId = "restic_exporter_key_id";
    secretKey = "restic_exporter_secret_key";
    env = "restic-exporter-s3-env";
  };
  fromFile = job: lib.optionalAttrs (job.sopsFile != null) { inherit (job) sopsFile; };

  # Per job, under fixed option paths: the job names must not decide which
  # options this module defines, or the module system recurses.
  perJob = f: lib.mkMerge (lib.mapAttrsToList f cfg.jobs);

  secrets =
    name: job:
    let
      s = secretNames name job;
    in
    {
      ${s.password} = fromFile job // exporterAccess name;
      ${s.keyId} = fromFile job;
      ${s.secretKey} = fromFile job;
    };

  # The S3 environment restic reads, for a pair of key secrets.
  s3Env = { keyId, secretKey, ... }: ''
    AWS_ACCESS_KEY_ID=${config.sops.placeholder.${keyId}}
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.${secretKey}}
    AWS_DEFAULT_REGION=garage
  '';

  template =
    name: job:
    let
      s = secretNames name job;
    in
    {
      ${s.env} = envAccess name // {
        content = s3Env s;
      };
    };

  # Snapshots first, then the job's own steps; cleanup the other way round.
  steps =
    job:
    let
      snap = import ./restic-btrfs-snapshots.nix { inherit pkgs; } job.snapshots;
      orEmpty = s: if s == null then "" else s;
      orNull = s: if s == "" then null else s;
      # A one-line step written without its newline must not run into the next.
      line = s: if s == "" || lib.hasSuffix "\n" s then s else s + "\n";
    in
    {
      prepare = orNull (snap.prepare + orEmpty job.prepare);
      cleanup = orNull (
        if snap.cleanup == "" then orEmpty job.cleanup else line (orEmpty job.cleanup) + snap.cleanup
      );
    };

  backup =
    name: job:
    let
      s = secretNames name job;
    in
    {
      inherit (job) paths exclude;
      repository = "s3:${cfg.endpoint}/${job.bucket}";
      passwordFile = config.sops.secrets.${s.password}.path;
      environmentFile = config.sops.templates.${s.env}.path;
      initialize = false; # see modules/restic-verified.nix
      timerConfig = {
        OnCalendar = job.time;
        RandomizedDelaySec = job.randomizedDelay;
        Persistent = true;
      };
      # One group per host, not per host and path list (restic's default):
      # each job has a repository of its own, and a changed path list (#81)
      # would otherwise start a new group and leave the old one's snapshots
      # in place for good, since nothing new joins it.
      pruneOpts = [
        "--group-by host"
        "--keep-daily ${toString job.keepDaily}"
        "--keep-weekly ${toString job.keepWeekly}"
        "--keep-monthly ${toString job.keepMonthly}"
      ];
    }
    // lib.optionalAttrs ((steps job).prepare != null) { backupPrepareCommand = (steps job).prepare; }
    // lib.optionalAttrs ((steps job).cleanup != null) { backupCleanupCommand = (steps job).cleanup; };
in
{
  imports = [
    ./lab.nix
    ./loopback-v6-proxy.nix
    ./restic-verified.nix
  ];

  options.services.resticGarage = {
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = config.lab.s3.endpoint;
      defaultText = lib.literalExpression "config.lab.s3.endpoint";
      example = "https://s3.example.org";
      description = "URL of the Garage S3 endpoint, without a bucket.";
    };

    jobs = lib.mkOption {
      default = { };
      description = "restic jobs (services.restic.backups.<name>) to a bucket of their own in Garage.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            bucket = lib.mkOption {
              type = lib.types.str;
              description = "Bucket of the repository.";
            };
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "What restic stores, as services.restic.backups.<name>.paths.";
            };
            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "As services.restic.backups.<name>.exclude.";
            };
            snapshots = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options.from = lib.mkOption {
                    type = lib.types.str;
                    description = "btrfs subvolume to snapshot.";
                  };
                  options.to = lib.mkOption {
                    type = lib.types.str;
                    description = "Path of the read-only snapshot.";
                  };
                }
              );
              default = [ ];
              description = "Read-only btrfs snapshots taken before the backup and removed after it (modules/restic-btrfs-snapshots.nix); `paths` point into them.";
            };
            prepare = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Runs before the backup, after the snapshots, e.g. a database copy (backupPrepareCommand).";
            };
            cleanup = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Runs after the backup, failed ones too, before the snapshots are removed (backupCleanupCommand).";
            };
            time = lib.mkOption {
              type = lib.types.str;
              example = "02:30";
              description = "OnCalendar of the job's timer.";
            };
            randomizedDelay = lib.mkOption {
              type = lib.types.str;
              default = "20min";
              description = "RandomizedDelaySec of the job's timer.";
            };
            keepDaily = lib.mkOption {
              type = lib.types.ints.positive;
              default = 7;
              description = "--keep-daily of the prune policy.";
            };
            keepWeekly = lib.mkOption {
              type = lib.types.ints.positive;
              default = 4;
              description = "--keep-weekly of the prune policy.";
            };
            keepMonthly = lib.mkOption {
              type = lib.types.ints.positive;
              default = 6;
              description = "--keep-monthly of the prune policy.";
            };
            sopsFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "sops file with the job's secrets; null for sops.defaultSopsFile.";
            };
            hostSecrets = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Use the secret names from before this module, one set per host:
                restic_password, garage_backup_key_id, garage_backup_secret_key
                and the template restic-s3-env. Otherwise they are named after
                the job: restic_<name>_password, restic_<name>_key_id,
                restic_<name>_secret_key, restic-<name>-s3-env.
              '';
            };
          };
        }
      );
    };

    exporter.ownKey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Read the repository with a key of the exporter's own instead of the
        job's read/write key: the secrets restic_exporter_key_id and
        restic_exporter_secret_key, a key that may only read the job's
        bucket. restic is called with --no-lock throughout, so reading is
        enough, `restic check` included (tests/restic-exporter-readonly.nix).
        The job keeps its own key.
      '';
    };

    exporter.sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "sops file with the exporter's own key (exporter.ownKey); null for sops.defaultSopsFile.";
    };

    exporter.job = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The job whose repository the restic exporter watches, on loopback
        (both address families through modules/loopback-v6-proxy.nix). It is
        registered with modules/metrics-shipping.nix where that is enabled;
        a host that scrapes itself (grammi) registers it on its own.
      '';
    };
  };

  config = lib.mkMerge [
    {
      sops.secrets = perJob secrets;
      sops.templates = perJob template;
      services.restic.backups = lib.mapAttrs backup cfg.jobs;
      # Success is what modules/restic-verified.nix confirms, not the unit's
      # result. Hosts add the job's inputs and limits there.
      services.resticVerified.jobs = lib.mapAttrs (_: _: { }) cfg.jobs;
    }
    (lib.mkIf (cfg.exporter.job != null) {
      assertions = [
        {
          assertion = cfg.jobs ? ${cfg.exporter.job};
          message = "services.resticGarage.exporter.job: ${cfg.exporter.job} is not one of services.resticGarage.jobs.";
        }
      ];

      users.groups.restic-metrics = { };

      sops.secrets = lib.mkIf cfg.exporter.ownKey (
        lib.genAttrs [ exporterKey.keyId exporterKey.secretKey ] (
          _: lib.optionalAttrs (cfg.exporter.sopsFile != null) { inherit (cfg.exporter) sopsFile; }
        )
      );
      sops.templates = lib.mkIf cfg.exporter.ownKey {
        ${exporterKey.env} = {
          content = s3Env exporterKey;
          restartUnits = [ "prometheus-restic-exporter.service" ];
        };
      };

      services.prometheus.exporters.restic =
        let
          job = config.services.restic.backups.${cfg.exporter.job};
        in
        {
          enable = true;
          # Loopback only: the exporter holds the repository password and an S3 key.
          listenAddress = "127.0.0.1";
          inherit (job) repository passwordFile;
          environmentFile =
            if cfg.exporter.ownKey then config.sops.templates.${exporterKey.env}.path else job.environmentFile;
          # Every collection is a burst of S3 requests; hourly tells just as much.
          refreshInterval = 3600;
        };
      systemd.services.prometheus-restic-exporter.serviceConfig.SupplementaryGroups = [
        "restic-metrics"
      ];

      # [::1] is answered by the proxy, so the endpoint stays dual stack.
      services.loopbackV6Proxy.restic-exporter.port = config.services.prometheus.exporters.restic.port;
    })
    (lib.mkIf (cfg.exporter.job != null && config.services.metricsShipping.enable) {
      services.metricsShipping.exporterPorts.restic = config.services.prometheus.exporters.restic.port;
      services.metricsShipping.exporterAddresses.restic = "[::1]";
    })
  ];
}
