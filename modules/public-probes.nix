# Reusable module: probe the lab's public endpoints from outside, with
# Prometheus' blackbox exporter. admin/nixlab#169.
#
# What is probed and from which host comes from modules/public-probes-targets.nix
# (the endpoints in inventory.json); each host probes the ones assigned to it.
# The exporter listens on loopback only, and the probes are scraped by this
# host's own scraper - vmagent (modules/metrics-shipping.nix) or, on grammi,
# VictoriaMetrics itself - as one job, `<host>-public-probes`, with the labels
#   target     the endpoint's name, e.g. short.homelab.example
#   path       what was requested, e.g. /healthz
#   ip_family  4 or 6
#   service    the service id in inventory.json
# on probe_success, probe_duration_seconds, probe_http_status_code and
# probe_ssl_earliest_cert_expiry. Alerts PublicServiceDown,
# PublicProbeMissing and ServedCertExpiring in hosts/grammi/alerting.nix,
# dashboard Homelab / Public endpoints.
#
# Heartbeat (optional, `heartbeat.sopsFile`): every 5 minutes, if all of this
# host's probes succeed, a ping to an external dead man's switch
# (healthchecks.io). The ping asks the exporter directly, not
# VictoriaMetrics, and needs neither grammi's alerting nor Home Assistant: a
# failing endpoint, a dead exporter or a dead host all end in no ping, and
# healthchecks.io notifies on its own channels.
{
  config,
  lib,
  pkgs,
  inventory,
  ...
}:
let
  cfg = config.services.publicProbes;
  host = config.networking.hostName;
  port = config.services.prometheus.exporters.blackbox.port;

  probes = lib.filter (p: p.prober == host) (import ./public-probes-targets.nix { inherit lib inventory; }).probes;

  blackboxConfig = (pkgs.formats.yaml { }).generate "blackbox.yaml" {
    modules = lib.listToAttrs (
      map (
        p:
        lib.nameValuePair p.module {
          prober = "http";
          timeout = "10s";
          http = {
            method = "GET";
            valid_status_codes = p.status;
            preferred_ip_protocol = "ip${p.family}";
            ip_protocol_fallback = false;
            # The answer of the endpoint itself, not of wherever it points.
            follow_redirects = false;
          }
          // lib.optionalAttrs (p.body != [ ]) { fail_if_body_not_matches_regexp = p.body; }
          // lib.optionalAttrs (p.hostHeader != null) { headers.Host = p.hostHeader; }
          // lib.optionalAttrs (p.location != null) {
            fail_if_header_not_matches = [ { header = "Location"; regexp = p.location; } ];
          };
        }
      ) probes
    );
  };

  # One target per probe; the __param_ labels become the query of
  # /probe?module=...&target=..., so no relabeling is needed.
  scrapeConfig = {
    job_name = "${host}-public-probes";
    metrics_path = "/probe";
    scrape_interval = "1m";
    # Above the modules' 10 s, so a timeout shows as probe_success 0 and not
    # as a failed scrape.
    scrape_timeout = "15s";
    static_configs = map (p: {
      targets = [ "127.0.0.1:${toString port}" ];
      labels = {
        __param_module = p.module;
        __param_target = p.url;
        instance = "${p.fqdn}${p.path} IPv${p.family}";
        target = p.fqdn;
        inherit (p) path;
        ip_family = p.family;
        service = p.id;
      };
    }) probes;
  };

  hasHeartbeat = cfg.heartbeat.sopsFile != null && builtins.pathExists cfg.heartbeat.sopsFile;
  secretName = "healthchecks_probe_url";

  heartbeat = pkgs.writeShellScript "public-probes-heartbeat" ''
    set -u
    curl=${pkgs.curl}/bin/curl
    ok=1
    ${lib.concatMapStrings (p: ''
      if ! "$curl" -sS --max-time 20 --get http://127.0.0.1:${toString port}/probe \
          --data-urlencode module=${p.module} --data-urlencode target=${p.url} \
          | ${pkgs.gnugrep}/bin/grep -qx 'probe_success 1'; then
        echo "${p.url} over IPv${p.family} failed" >&2
        ok=0
      fi
    '') probes}
    if [ "$ok" = 1 ]; then
      # A failed ping is not this unit's failure: healthchecks.io notifies
      # once pings stay away, an extra UnitFailed would only repeat it.
      "$curl" -fsS --max-time 10 --retry 3 -o /dev/null "$(cat "$CREDENTIALS_DIRECTORY/ping-url")" \
        || echo "ping to the dead man's switch failed" >&2
    fi
  '';
in
{
  options.services.publicProbes = {
    enable = lib.mkEnableOption "probes of the public endpoints assigned to this host (modules/public-probes-targets.nix)";

    heartbeat.sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./healthchecks-probe.yaml";
      description = ''
        sops file with the ping URL of an external dead man's switch under
        `${secretName}`, written by `just healthchecks-ping-url probe`. Until
        the file exists, no heartbeat runs.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [{
        assertion = probes != [ ];
        message = "services.publicProbes: no public endpoint is assigned to ${host} in modules/public-probes-targets.nix";
      }];

      services.prometheus.exporters.blackbox = {
        enable = true;
        listenAddress = "127.0.0.1";
        configFile = blackboxConfig;
      };

      services.metricsShipping.extraScrapeConfigs = lib.mkIf config.services.metricsShipping.enable [ scrapeConfig ];
      services.victoriametrics.prometheusConfig.scrape_configs = lib.mkIf (!config.services.metricsShipping.enable) [ scrapeConfig ];
    }

    (lib.mkIf hasHeartbeat {
      sops.secrets.${secretName}.sopsFile = cfg.heartbeat.sopsFile;

      systemd.services.public-probes-heartbeat = {
        description = "Ping the external dead man's switch while all public probes of ${host} succeed";
        after = [ "network-online.target" "prometheus-blackbox-exporter.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          LoadCredential = [ "ping-url:${config.sops.secrets.${secretName}.path}" ];
          ExecStart = heartbeat;
        };
      };

      systemd.timers.public-probes-heartbeat = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
        };
      };
    })
  ]);
}
