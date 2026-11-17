# Reusable module: node_exporter's textfile collector, with every writer in
# a sandbox that can write its own files and nothing else
# (admin/nixlab#320).
#
# Layout under `directory`:
#
#   <directory>/*.prom                 root-owned; only for writers that are
#                                      root jobs anyway (an upgrade, a backup)
#   <directory>/writers/<name>/*.prom  one directory per writer, owned by the
#                                      writer's user, 0755
#
# node_exporter reads both: the textfile flag is repeatable and takes a glob
# (node_exporter >= 1.8). A writer's user owns only its own directory and
# its unit sees the filesystem read-only apart from it (ProtectSystem=strict
# via modules/hardening.nix), so a broken or compromised writer can neither
# fake another writer's metrics nor write anywhere else.
#
# Two ways in:
#
#   writers.<name>      a oneshot unit plus timer; the script prints the
#                       metrics to stdout, the module writes them atomically
#                       to writers/<name>/<file> - or, with file = null, the
#                       script writes its files itself with `write-prom`.
#   directories.<name>  just the directory, for a unit defined elsewhere (a
#                       long-running exporter bridge, several units sharing
#                       one user); that unit puts the path into its own
#                       ReadWritePaths.
#
# Files are written as "<dir>/.<file>.tmp" and renamed, because the collector
# reads whatever is there whenever it is scraped; a failing run keeps the
# previous file. Moving a writer here from the root directory removes its old
# file there (legacyFiles), so the two never export the same series twice.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.services.textfileMetrics;

  writersRoot = "${cfg.directory}/writers";

  # write-prom <file> <command...>: runs the command, writes its stdout to
  # <file> atomically - only if the command succeeded.
  writeProm = pkgs.writeShellScriptBin "write-prom" ''
    set -euo pipefail
    if [ $# -lt 2 ]; then
      echo "usage: write-prom <file.prom> <command...>" >&2
      exit 2
    fi
    out=$1
    shift
    tmp="$(dirname "$out")/.$(basename "$out").tmp"
    "$@" > "$tmp"
    chmod 0644 "$tmp"
    mv "$tmp" "$out"
  '';

  directoryType = types.submodule (
    { name, config, ... }:
    {
      options = {
        user = mkOption {
          type = types.str;
          default = name;
          description = "Owner of the directory.";
        };
        group = mkOption {
          type = types.str;
          default = config.user;
          description = "Group of the directory.";
        };
        legacyFiles = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "foo.prom" ];
          description = "Files in the root directory this writer used to write, removed by tmpfiles.";
        };
        path = mkOption {
          type = types.str;
          readOnly = true;
          default = "${writersRoot}/${name}";
          description = "The directory itself.";
        };
        execStartPre = mkOption {
          type = types.str;
          readOnly = true;
          default = "+${pkgs.writeShellScript "textfile-dir-${name}" ''
            ${pkgs.coreutils}/bin/install -d -m 0755 ${writersRoot}
            ${pkgs.coreutils}/bin/install -d -m 0755 -o ${config.user} -g ${config.group} ${writersRoot}/${name}
            # Files of a former owner (the writer changed its user, or a run
            # left its .tmp behind) would otherwise be in the way of a user
            # without CAP_DAC_OVERRIDE - root included (aldrin, 2026-11-16).
            ${pkgs.coreutils}/bin/chown -R ${config.user}:${config.group} ${writersRoot}/${name}
          ''}";
          description = ''
            ExecStartPre= entry that creates the directory as root and hands
            it and its files to the owner, for a
            unit that writes it: on the first switch with a new writer the
            unit can start before tmpfiles has created the directory (seen on
            tummi, 2026-11-16). Such a unit lists the directory as "-<path>"
            in ReadWritePaths=: a missing path fails the namespace setup even
            of a "+" command.
          '';
        };
      };
    }
  );

  writerType = types.submodule (
    { name, config, ... }:
    {
      options = {
        description = mkOption {
          type = types.str;
          default = "Textfile metrics: ${name}";
          description = "The unit's description.";
        };

        script = mkOption {
          type = types.lines;
          description = ''
            Shell script, run with `set -euo pipefail`. With `file` set it
            prints Prometheus text format to stdout; with `file = null` it
            writes into $TEXTFILE_DIR itself, with `write-prom`. Either way
            a failure keeps the previous files.
          '';
        };

        file = mkOption {
          type = types.nullOr types.str;
          default = "${name}.prom";
          description = "File the script's stdout goes to; null if the script writes its own files.";
        };

        path = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages on the script's PATH.";
        };

        user = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            User to run as. null: a static system user of the writer's name,
            created here. "root" only together with an explicit
            `hardening.capabilities` list, which is then all root keeps - for
            what a capability alone does not do as another user (SQLite
            opens a WAL database read-only only as root, see
            hosts/aldrin/shortener.nix).
          '';
        };

        group = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Primary group; null keeps the user's own.";
        };

        supplementaryGroups = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra groups, for reading an app's data through its group.";
        };

        hardening = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          example = {
            network = "netlink";
            capabilities = [ "CAP_NET_ADMIN" ];
          };
          description = ''
            Exceptions to the sandbox, as options of modules/hardening.nix
            (`systemd.services.<name>.hardening`). The defaults are level
            "strict", network "none", umask "0022".
          '';
        };

        timer = mkOption {
          type = types.nullOr (types.attrsOf types.str);
          default = {
            OnBootSec = "2min";
            OnUnitActiveSec = "5min";
          };
          description = "timerConfig of the writer's timer; null for a writer started by other units only.";
        };

        startOnActivation = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Also run at boot and whenever the unit changes on a switch, so a
            moved or changed writer does not leave a gap until its timer.
          '';
        };

        unit = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          example = {
            after = [ "fwupd.service" ];
            serviceConfig.LoadCredential = [ "token:/run/secrets/token" ];
          };
          description = "Merged into systemd.services.<name>: ordering, credentials, triggers.";
        };

        legacyFiles = mkOption {
          type = types.listOf types.str;
          default = lib.optional (config.file != null) config.file;
          defaultText = lib.literalExpression "[ file ]";
          description = "Files in the root directory this writer used to write, removed by tmpfiles.";
        };
      };
    }
  );

  userOf = name: w: if w.user == null then name else w.user;

  mkWriterService =
    name: w:
    let
      dir = cfg.directories.${name}.path;
      run = pkgs.writeShellScript "${name}-run" ''
        set -euo pipefail
        ${if w.file != null then ''
          tmp=${lib.escapeShellArg "${dir}/.${w.file}.tmp"}
          {
          ${w.script}
          } > "$tmp"
          chmod 0644 "$tmp"
          mv "$tmp" ${lib.escapeShellArg "${dir}/${w.file}"}
        '' else w.script}
      '';
    in
    lib.mkMerge [
      {
        inherit (w) description;
        path = [ writeProm pkgs.coreutils ] ++ w.path;
        environment.TEXTFILE_DIR = dir;
        wantedBy = lib.optional w.startOnActivation "multi-user.target";
        after = [ "systemd-tmpfiles-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = [ cfg.directories.${name}.execStartPre ];
          ExecStart = run;
          User = userOf name w;
          Group = lib.mkIf (w.group != null) w.group;
          SupplementaryGroups = w.supplementaryGroups;
        };
        hardening = {
          enable = true;
          level = lib.mkDefault "strict";
          network = lib.mkDefault "none";
          umask = lib.mkDefault "0022";
        } // w.hardening // {
          # "-": optional at namespace setup, so the root ExecStartPre can
          # still create a missing directory; ExecStart gets it writable.
          writablePaths = [ "-${dir}" ] ++ (w.hardening.writablePaths or [ ]);
        };
      }
      w.unit
    ];
in
{
  imports = [
    ./hardening.nix
    # The name the option had while it lived in modules/metrics.nix.
    (lib.mkAliasOptionModule
      [ "services" "metricsTextfile" "directory" ]
      [ "services" "textfileMetrics" "directory" ])
  ];

  options.services.textfileMetrics = {
    enable = lib.mkEnableOption "node_exporter's textfile collector with sandboxed writers";

    directory = mkOption {
      type = types.str;
      default = "/var/lib/prometheus-node-exporter-text-files";
      description = "Directory node_exporter's textfile collector reads; writers get subdirectories below it.";
    };

    metricPrefix = mkOption {
      type = types.str;
      default = "nixlab_";
      description = "Prefix of the metrics that modules built on this one add about themselves.";
    };

    writeProm = mkOption {
      type = types.package;
      readOnly = true;
      default = writeProm;
      description = "The `write-prom <file> <command...>` helper, for units defined elsewhere.";
    };

    directories = mkOption {
      type = types.attrsOf directoryType;
      default = { };
      description = "Writer directories, keyed by writer name.";
    };

    writers = mkOption {
      type = types.attrsOf writerType;
      default = { };
      description = "Sandboxed textfile writers, keyed by name; the name is also the unit's and, by default, the user's.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.prometheus.exporters.node.enabledCollectors = [ "textfile" ];
      services.prometheus.exporters.node.extraFlags = [
        "--collector.textfile.directory=${cfg.directory}"
        "--collector.textfile.directory=${writersRoot}/*"
      ];

      systemd.tmpfiles.settings."10-textfile-metrics" =
        {
          # Root-owned and world-readable: node_exporter reads it as its own
          # user; only root jobs write here directly.
          ${cfg.directory}.d = { user = "root"; group = "root"; mode = "0755"; };
          ${writersRoot}.d = { user = "root"; group = "root"; mode = "0755"; };
        }
        // lib.mapAttrs' (_: d: lib.nameValuePair d.path {
          d = { inherit (d) user group; mode = "0755"; };
        }) cfg.directories
        // lib.listToAttrs (lib.concatMap (d: map (f: lib.nameValuePair "${cfg.directory}/${f}" { r = { }; }) d.legacyFiles)
          (lib.attrValues cfg.directories));
    }

    (lib.mkIf (cfg.writers != { }) {
      assertions = lib.flatten (lib.mapAttrsToList (name: w: [
        {
          assertion = w.user != "root" || (w.hardening.capabilities or [ ]) != [ ];
          message = "services.textfileMetrics.writers.${name}: user root needs an explicit hardening.capabilities list.";
        }
        {
          assertion = w.user != null || lib.stringLength name <= 31;
          message = "services.textfileMetrics.writers.${name}: name too long for a user name - set `user`.";
        }
      ]) cfg.writers);

      services.textfileMetrics.directories = lib.mapAttrs (name: w: {
        user = userOf name w;
        group = if w.group != null then w.group
          else if w.user == null then name
          else config.users.users.${w.user}.group;
        inherit (w) legacyFiles;
      }) cfg.writers;

      users.users = lib.mapAttrs (name: _: {
        isSystemUser = true;
        group = name;
        description = "textfile metrics writer ${name}";
      }) (lib.filterAttrs (_: w: w.user == null) cfg.writers);
      users.groups = lib.mapAttrs (_: _: { }) (lib.filterAttrs (_: w: w.user == null) cfg.writers);

      systemd.services = lib.mapAttrs mkWriterService cfg.writers;

      systemd.timers = lib.mapAttrs (_: w: {
        wantedBy = [ "timers.target" ];
        timerConfig = w.timer;
      }) (lib.filterAttrs (_: w: w.timer != null) cfg.writers);
    })
  ]);
}
