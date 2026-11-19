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
# Each job is a writer of modules/textfile-metrics.nix: it runs as its own
# user (or the one given, e.g. for PostgreSQL peer auth) in that module's
# sandbox, without a network, and can write nothing but its own directory.
# A failed query keeps the previous file, so the success timestamp ages.
#
# Every job exports
#   nixlab_state_metrics_last_success_timestamp_seconds{name}
#   nixlab_state_metrics_interval_seconds{name}
# and StateMetricsStale (hosts/grammi/alerting/backups.nix) compares the two, so a
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
  prefix = config.services.textfileMetrics.metricPrefix;

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
            User to query as. null: a static user "state-<name>" created
            here. For data under /var/lib/private (DynamicUser apps)
            `capabilities = [ "CAP_DAC_READ_SEARCH" ]` is usually enough;
            "root" only together with `capabilities`, which are then all it
            keeps (a WAL-mode SQLite database opens read-only only as root).
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
          description = "The only capabilities the job keeps, granted ambiently. Empty: none.";
        };

        hostNetwork = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Run the query in the host's network namespace with netlink
            sockets allowed, instead of a private network: for state that
            lives in the kernel, such as nftables counters (together with
            `capabilities = [ "CAP_NET_ADMIN" ]`, which reading them takes).
            No AF_INET/AF_INET6 either way, so the job still cannot open a
            connection.
          '';
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
  userOf = name: job: if job.user == null then "state-${name}" else job.user;

  mkWriter =
    name: job:
    lib.nameValuePair (unitName name) {
      description = "State metrics: ${job.description}";
      file = "state-${name}.prom";
      user = userOf name job;
      inherit (job) group supplementaryGroups;
      path = [
        sqliteQuery
      ]
      # Only where PostgreSQL runs: its package option has no value elsewhere.
      ++ lib.optional config.services.postgresql.enable pgQuery
      ++ job.path;
      # The job's own metrics after its output; a failing script never
      # gets here, so the file is not replaced.
      script = ''
        ${job.script}
        echo "# HELP ${prefix}state_metrics_last_success_timestamp_seconds Last successful run of a state metrics job."
        echo "# TYPE ${prefix}state_metrics_last_success_timestamp_seconds gauge"
        echo "${prefix}state_metrics_last_success_timestamp_seconds{name=\"${name}\"} $(date +%s)"
        echo "# HELP ${prefix}state_metrics_interval_seconds Configured interval of a state metrics job."
        echo "# TYPE ${prefix}state_metrics_interval_seconds gauge"
        echo "${prefix}state_metrics_interval_seconds{name=\"${name}\"} ${toString job.intervalSeconds}"
      '';
      hardening = {
        network = if job.hostNetwork then "netlink" else "none";
        inherit (job) capabilities;
      };
      timer = {
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

  imports = [ ./textfile-metrics.nix ];

  config = lib.mkIf (cfg.jobs != { }) {
    assertions = lib.mapAttrsToList (name: job: {
      assertion = job.user != "root" || job.capabilities != [ ];
      message = "services.stateMetrics.jobs.${name}: user root needs an explicit capabilities list.";
    }) cfg.jobs;

    services.textfileMetrics.writers = lib.mapAttrs' mkWriter cfg.jobs;

    users.users = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "state-${name}" {
        isSystemUser = true;
        group = "state-${name}";
        description = "state metrics job ${name}";
      }
    ) (lib.filterAttrs (_: job: job.user == null) cfg.jobs);
    users.groups = lib.mapAttrs' (name: _: lib.nameValuePair "state-${name}" { }) (
      lib.filterAttrs (_: job: job.user == null) cfg.jobs
    );
  };
}
