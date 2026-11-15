# Reusable module: an app's state as metrics, without changing the app. Each
# job runs a command on a timer that prints Prometheus text format to stdout,
# usually a read-only query against the app's own database; the result goes
# into node_exporter's textfile collector (modules/metrics.nix) and from there
# to grammi like every other node metric. admin/nixlab#268.
#
# For apps that have no metrics endpoint and will not get one (Chhoto URL:
# SinTan1729/chhoto-url#158), or whose interesting state is a timestamp in
# their database rather than anything they would export.
#
# Two steps per run, so the query does not need root:
#   1. ExecStart as the job's user, under ProtectSystem=strict and without a
#      network, writes to its RuntimeDirectory.
#   2. ExecStartPost with full privileges ("+") adds the job's own metrics and
#      moves the file into the textfile directory, which only root may write
#      (0755 root, see modules/metrics.nix). A failed query never reaches it,
#      so the previous file stays and the success timestamp ages.
#
# Every job exports
#   nixlab_state_metrics_last_success_timestamp_seconds{name}
#   nixlab_state_metrics_interval_seconds{name}
# and StateMetricsStale (hosts/grammi/alerting.nix) compares the two, so a
# query that starts failing - an upstream schema change, a lost GRANT - shows
# up without an alert per job.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.stateMetrics;
  textfileDir = config.services.metricsTextfile.directory;

  jobType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        description = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "What the job measures, for the unit's description.";
        };

        script = lib.mkOption {
          type = lib.types.lines;
          description = ''
            Shell script printing Prometheus text format to stdout. Runs with
            `set -euo pipefail`; any failure keeps the previous metrics file.
            The helpers sqliteQuery and pgQuery below are on PATH.
          '';
        };

        path = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Extra packages on the script's PATH.";
        };

        intervalSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Time between runs. Also exported, for the staleness alert.";
        };

        user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            User to query as. null: a DynamicUser. "root" only together with
            `capabilities`, for data under /var/lib/private (DynamicUser apps).
          '';
        };

        group = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Primary group; null keeps the user's own.";
        };

        supplementaryGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra groups, for reading an app's data through its group.";
        };

        capabilities = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "CAP_DAC_READ_SEARCH" ];
          description = "The only capabilities the query step keeps. Empty: none.";
        };
      };
    }
  );

  # Read-only SQLite query, tab-separated output. mode=ro opens a WAL
  # database as long as its -wal and -shm files exist, which they do while
  # the app runs; nothing here can write to it either way.
  sqliteQuery = pkgs.writeShellScriptBin "sqliteQuery" ''
    set -euo pipefail
    if [ $# -ne 2 ]; then
      echo "usage: sqliteQuery <file> <sql>" >&2
      exit 2
    fi
    exec ${lib.getExe pkgs.sqlite} -readonly -bail -batch -noheader -separator $'\t' \
      "file:$1?mode=ro" "$2"
  '';

  # PostgreSQL query over the local socket with peer auth: the job's user
  # needs a role of the same name with the GRANTs it needs and nothing more.
  pgQuery = pkgs.writeShellScriptBin "pgQuery" ''
    set -euo pipefail
    if [ $# -ne 2 ]; then
      echo "usage: pgQuery <database> <sql>" >&2
      exit 2
    fi
    exec ${config.services.postgresql.package}/bin/psql --no-psqlrc -X -v ON_ERROR_STOP=1 \
      -h /run/postgresql -d "$1" -At -F $'\t' -c "$2"
  '';

  unitName = name: "state-metrics-${name}";

  mkService =
    name: job:
    let
      unit = unitName name;
      query = pkgs.writeShellScript "${unit}-query" ''
        set -euo pipefail
        out="$RUNTIME_DIRECTORY/${name}.prom"
        {
        ${job.script}
        } > "$out.tmp"
        mv "$out.tmp" "$out"
      '';
      # Adds the job's own metrics and publishes the file. Runs as root
      # ("+" in ExecStartPost), outside the sandbox above.
      publish = pkgs.writeShellScript "${unit}-publish" ''
        set -euo pipefail
        src="$RUNTIME_DIRECTORY/${name}.prom"
        dst="${textfileDir}/state-${name}.prom"
        {
          cat "$src"
          echo "# HELP nixlab_state_metrics_last_success_timestamp_seconds Last successful run of a state metrics job."
          echo "# TYPE nixlab_state_metrics_last_success_timestamp_seconds gauge"
          echo "nixlab_state_metrics_last_success_timestamp_seconds{name=\"${name}\"} $(date +%s)"
          echo "# HELP nixlab_state_metrics_interval_seconds Configured interval of a state metrics job."
          echo "# TYPE nixlab_state_metrics_interval_seconds gauge"
          echo "nixlab_state_metrics_interval_seconds{name=\"${name}\"} ${toString job.intervalSeconds}"
        } > "$dst.tmp"
        chmod 0644 "$dst.tmp"
        mv "$dst.tmp" "$dst"
      '';
    in
    lib.nameValuePair unit {
      description = "State metrics: ${job.description}";
      path = [
        sqliteQuery
        pkgs.coreutils
      ]
      # Only where PostgreSQL runs: its package option has no value elsewhere.
      ++ lib.optional config.services.postgresql.enable pgQuery
      ++ job.path;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = query;
        ExecStartPost = "+${publish}";
        RuntimeDirectory = unit;
        RuntimeDirectoryMode = "0700";

        DynamicUser = job.user == null;
        User = lib.mkIf (job.user != null) job.user;
        Group = lib.mkIf (job.group != null) job.group;
        SupplementaryGroups = job.supplementaryGroups;
        # An empty assignment is the empty set: no capabilities at all.
        CapabilityBoundingSet = if job.capabilities == [ ] then "" else job.capabilities;
        AmbientCapabilities = lib.mkIf (job.user != "root") job.capabilities;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateNetwork = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };

  mkTimer =
    name: job:
    lib.nameValuePair (unitName name) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "${toString job.intervalSeconds}s";
      };
    };
in
{
  options.services.stateMetrics.jobs = lib.mkOption {
    type = lib.types.attrsOf jobType;
    default = { };
    description = "State metrics jobs, keyed by name; the name becomes the `name` label (`job` is the scrape job's).";
  };

  config = lib.mkIf (cfg.jobs != { }) {
    assertions = lib.mapAttrsToList (name: job: {
      assertion = job.user != "root" || job.capabilities != [ ];
      message = "services.stateMetrics.jobs.${name}: user root needs an explicit capabilities list.";
    }) cfg.jobs;

    systemd.services = lib.mapAttrs' mkService cfg.jobs;
    systemd.timers = lib.mapAttrs' mkTimer cfg.jobs;
  };
}
