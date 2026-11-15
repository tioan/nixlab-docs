# Reusable module: vmauth as the one way in for metrics and logs from other
# hosts, in front of a VictoriaMetrics and a VictoriaLogs that listen on
# loopback only. Every sender is a user of its own (basic auth) and may
# reach only the write paths it needs:
#
#   /api/v1/write    -> VictoriaMetrics (vmagent's remote write)
#   /insert/jsonline -> VictoriaLogs    (Vector's http sink)
#   /api/v1/query    -> VictoriaMetrics (only for users with query = true)
#
# Everything else - other query APIs, vmui, delete_series, /metrics, /flags -
# is answered by vmauth itself with 400 (no route) or 401 (no or wrong
# credentials); its own internal endpoints listen on loopback only.
#
# forceHost puts the sender's identity on everything it writes: extra_label
# for VictoriaMetrics, extra_fields for VictoriaLogs. For logs the stream
# fields are fixed here as well (logStreamFields): without them a sender
# could send its own `_stream` field and keep a forged `host` in the stream
# identity while only the plain field is replaced. vmauth's own query
# arguments come first and VictoriaLogs reads the first, so a sender's
# _stream_fields or extra_fields are ignored. All checked against VM
# 1.156.0 / VL 1.52.1 on 2026-11-15. Leave forceHost null only for a sender
# that legitimately writes for other hosts (a scraper for devices that
# cannot ship themselves); it keeps its own stream fields.
#
# Passwords come from environmentFile, one variable per user
# (envName below); vmauth replaces %{VAR} in its config with them, so
# the config in the store holds no secret.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.telemetryIngest;

  # "gw-remote" -> "TELEMETRY_GW_Remote"
  envName = name: "TELEMETRY_" + lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] name);

  route = paths: target: {
    src_paths = paths;
    url_prefix = target;
  };

  withArg = url: arg: if arg == null then url else "${url}?${arg}";

  userConfig = name: u: {
    username = name;
    password = "%{${envName name}}";
    url_map =
      lib.optionals u.write [
        (route [ "/api/v1/write" ] (withArg cfg.metricsUrl
          (if u.forceHost == null then null else "extra_label=host=${u.forceHost}")))
        (route [ "/insert/jsonline" ] (withArg cfg.logsUrl
          (if u.forceHost == null then null
           else "extra_fields=host=${u.forceHost}&_stream_fields=${lib.concatStringsSep "," cfg.logStreamFields}")))
      ]
      ++ lib.optional u.query (route [ "/api/v1/query" ] cfg.metricsUrl);
  };

  authConfig = (pkgs.formats.yaml { }).generate "vmauth.yaml" {
    users = lib.mapAttrsToList userConfig cfg.users;
  };
in
{
  options.services.telemetryIngest = {
    enable = lib.mkEnableOption "vmauth as the authenticated ingest endpoint for VictoriaMetrics and VictoriaLogs";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = ":8427";
      description = "Where vmauth accepts senders (vmauth's default port).";
    };

    internalListenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8426";
      description = ''
        vmauth's own /metrics, /health and /-/reload. Kept off
        listenAddress so senders cannot reach them.
      '';
    };

    metricsUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8428";
      description = "VictoriaMetrics to forward to.";
    };

    logsUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:9428";
      description = "VictoriaLogs to forward to.";
    };

    logStreamFields = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "host" "_SYSTEMD_UNIT" ];
      description = ''
        VictoriaLogs stream fields forced for users with forceHost - the
        ones the senders use themselves (modules/log-shipping.nix).
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        KEY=VALUE file with one password per user, named
        TELEMETRY_<USER> (upper case, dashes as underscores). Read by
        systemd, so it may be root-only (a sops template).
      '';
    };

    envName = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      readOnly = true;
      default = envName;
      description = "User name -> its variable in environmentFile, for whoever writes that file.";
    };

    users = lib.mkOption {
      default = { };
      description = "One entry per sender; the name is the basic-auth user name.";
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          write = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "May write metrics (/api/v1/write) and logs (/insert/jsonline).";
          };
          query = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "May run instant queries (/api/v1/query) - reads every series.";
          };
          forceHost = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = name;
            description = ''
              `host` forced onto everything this user writes; null keeps the
              sender's own (for a sender that writes on behalf of others).
            '';
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.users == { } || cfg.environmentFile != null;
      message = "services.telemetryIngest: users need an environmentFile with their passwords.";
    }] ++ lib.mapAttrsToList (name: u: {
      # vmauth refuses to start with a user that has no url_map at all.
      assertion = u.write || u.query;
      message = "services.telemetryIngest.users.${name}: neither write nor query - remove the user instead.";
    }) cfg.users;

    systemd.services.vmauth = {
      description = "vmauth - authenticated ingest for VictoriaMetrics and VictoriaLogs";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.victoriametrics}/bin/vmauth"
          "-auth.config=${authConfig}"
          "-httpListenAddr=${cfg.listenAddress}"
          "-httpInternalListenAddr=${cfg.internalListenAddress}"
          # Not -logInvalidAuthTokens: it logs the whole Basic token, i.e. a
          # sender's password whenever its user name is mistyped. Rejections
          # are counted at vmauth_http_request_errors_total{reason=...}.
        ];
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        SystemCallFilter = [ "@system-service" "~@privileged" ];
      };
      # A changed password needs a restart (the environment is read at
      # start): restartUnits on whatever writes environmentFile. A changed
      # user list changes ExecStart and restarts anyway.
    };
  };
}
