# Reusable module: ship this host's journald log and nginx's access log to a
# central VictoriaLogs instance (grammi) via Vector. Switched on per host with
# services.logShipping.enable (see hosts/aldrin, hosts/zummi).
#
# nginx access log: /var/log/nginx is drwxr-x--- nginx:nginx, same obstacle
# CrowdSec and the nginxlog Prometheus exporter hit (see modules/crowdsec.nix,
# modules/metrics.nix) - both already prove SupplementaryGroups = [ "nginx" ]
# works fine under DynamicUser in this nixpkgs, so Vector gets the same
# treatment below rather than the "not attempted yet" this module used to say.
#
# Field mapping verified against a real payload (query against
# /select/logsql/query): Vector's `journald` source renames journald's
# MESSAGE field to its own lowercase `message` on the way in - the raw
# uppercase journald field names (_SYSTEMD_UNIT, __REALTIME_TIMESTAMP, etc.)
# survive untouched, but the message text itself does not, so _msg_field has
# to point at the renamed field or VictoriaLogs can't find any content
# ("missing _msg field" for every entry). `timestamp` and `host` matched
# already and needed no change. Vector's `file` source uses the same
# `message`/`timestamp` field names for the raw log line and its own read
# time, and stamps `.host` with the local hostname same as every other
# source, so the nginx access log needs no separate _msg_field/_time_field -
# it rides the same sink as journald.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.logShipping;
  nginx = config.services.nginx.enable;
  traefik = config.services.traefik.enable;
  # Log directories Vector reads through their group: /var/log/nginx and
  # /var/log/traefik (hosts/grammi/traefik.nix), both 0750.
  logGroups = lib.optional nginx "nginx" ++ lib.optional traefik "traefik";
in
{
  options.services.logShipping = {
    enable = lib.mkEnableOption "ship this host's journald log to grammi's VictoriaLogs via Vector";

    victoriaLogsUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://grammi.peer.homelab.example:9428";
      description = ''
        Base URL of the VictoriaLogs instance to ship to. Over the NetBird
        mesh, same reasoning as services.metricsShipping.remoteWriteUrl.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.vector = {
      enable = true;
      journaldAccess = true;
      settings = {
        sources.journald.type = "journald";

        sources.nginx_access = lib.mkIf nginx {
          type = "file";
          include = [ "/var/log/nginx/access.log" ];
        };

        # Traefik's JSON access log (grammi), same treatment: own
        # _SYSTEMD_UNIT, level from the HTTP status.
        sources.traefik_access = lib.mkIf traefik {
          type = "file";
          include = [ "/var/log/traefik/access.log" ];
        };

        # journald's PRIORITY is a numeric syslog level (0-7), not a field
        # named "level" with a text value - VictoriaLogs' vmui only
        # colour-codes/labels rows when it finds the latter, so without this
        # every row shows as "OTHER" regardless of actual severity. Map it
        # once here rather than relying on any per-app convention (most units
        # don't emit their own textual level field at all).
        #
        # nginx access log lines have no PRIORITY field, so they get their own
        # branch: parse_nginx_log (VRL builtin, understands the standard
        # combined format nginx writes - see modules/metrics.nix's nginxlog
        # exporter, same format string) pulls out the numeric HTTP status and
        # maps it the conventional way (5xx -> error, 4xx -> warning, else
        # info). A line that fails to parse still gets shipped, just tagged
        # "other" (VictoriaLogs' own bucket for anything it can't classify)
        # rather than being dropped or silently mislabelled as "info" - that
        # keeps unparsable lines visible instead of hiding among normal
        # traffic. Also stamps _SYSTEMD_UNIT on the file source's events so
        # the sink's _stream_fields grouping (see below) has something to
        # group nginx access lines by, same as journald units.
        #
        # parsed.status straight out of parse_nginx_log is typed `any` by the
        # VRL compiler once destructured via the two-value err-handling form,
        # so comparing it directly with >= is a "fallible predicate" at
        # compile time - Vector refuses to even start with that (error
        # E100, all three hosts down simultaneously since this module is
        # shared - learned the hard way). Routing it through to_int fixes
        # that BUT to_int(parsed.status) must be a single-value assignment,
        # not the two-value err form - the compiler already proves
        # parse_nginx_log's status field converts cleanly, so `status, err2 =
        # to_int(...)` is itself rejected as an "unnecessary error
        # assignment" (error E104). Single-value assignment is what it wants.
        transforms.add_level = {
          type = "remap";
          inputs = [ "journald" ]
            ++ lib.optional nginx "nginx_access"
            ++ lib.optional traefik "traefik_access";
          source = ''
            if .source_type == "file" && starts_with(string(.file) ?? "", "/var/log/traefik/") {
              ._SYSTEMD_UNIT = "traefik-access.log"
              parsed, err = parse_json(.message)
              status, err2 = to_int(parsed.DownstreamStatus)
              if err != null || err2 != null {
                .level = "other"
              } else {
                .level = if status >= 500 {
                  "error"
                } else if status >= 400 {
                  "warning"
                } else {
                  "info"
                }
              }
            } else if .source_type == "file" {
              ._SYSTEMD_UNIT = "nginx-access.log"
              parsed, err = parse_nginx_log(.message, "combined")
              if err != null {
                .level = "other"
              } else {
                status = to_int(parsed.status)
                .level = if status >= 500 {
                  "error"
                } else if status >= 400 {
                  "warning"
                } else {
                  "info"
                }
              }
            } else {
              p, err = to_int(.PRIORITY)
              if err != null { p = 6 }
              .level = if p <= 3 {
                "error"
              } else if p == 4 {
                "warning"
              } else if p == 5 {
                "notice"
              } else if p == 6 {
                "info"
              } else {
                "debug"
              }
            }
          '';
        };

        sinks.vlogs = {
          type = "http";
          inputs = [ "add_level" ];
          uri = "${cfg.victoriaLogsUrl}/insert/jsonline"
            + "?_stream_fields=host,_SYSTEMD_UNIT&_msg_field=message&_time_field=timestamp";
          encoding.codec = "json";
          framing.method = "newline_delimited";
          compression = "gzip";
          healthcheck.enabled = false;
        };
      };
    };

    # Same obstacle CrowdSec and the nginxlog Prometheus exporter hit (see
    # modules/crowdsec.nix, modules/metrics.nix): /var/log/nginx is group
    # "nginx"-readable only, and Vector's DynamicUser needs that group to
    # read access.log at all - without it the file source just silently
    # never sees any lines.
    systemd.services.vector.serviceConfig.SupplementaryGroups =
      lib.mkIf (logGroups != [ ]) logGroups;

    # grammi.peer.homelab.example only resolves and routes over the NetBird mesh,
    # so start after its client (ordering only). While the mesh is down the
    # http sink keeps retrying; once its buffer is full, backpressure stops
    # the journald and file sources, which pick up again from their
    # checkpoints - delayed, not lost, as long as the journal still has it.
    systemd.services.vector.after = [ "netbird-mesh.service" ];
  };
}
