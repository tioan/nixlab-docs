# Reusable module: scrape this host's own Prometheus exporters with vmagent
# and remote_write them to a central VictoriaMetrics instance (grammi). Meant
# to be dropped into any host's `modules` list unchanged and switched on per
# host with services.metricsShipping.enable (see hosts/aldrin, hosts/zummi).
#
# vmagent ships as part of the same `victoriametrics` package that provides
# victoria-metrics/victoria-logs (nixpkgs builds all of VictoriaMetrics' Go
# binaries from one derivation) - no separate NixOS module exists for it
# upstream, hence the hand-rolled systemd unit below, in the same spirit as
# modules/auto-upgrade-git.nix.
{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.metricsShipping;
  # The AppSec WAF's per-vhost counters (modules/waf.nix), where nginx asks it.
  wafNginx =
    options.services ? waf
    && config.services.waf.enable
    && config.services.waf.nginx.apiKeyFile != null;
  # Drops the AppSec series the WAF's own probe causes (modules/waf.nix,
  # probe.metricRelabelConfigs), so the counters only show bouncer traffic.
  wafProbeRelabel = lib.optionals (
    options.services ? waf && config.services.waf.enable
  ) config.services.waf.probe.metricRelabelConfigs;

  scrapeConfig = (pkgs.formats.yaml { }).generate "vmagent-scrape.yaml" {
    # Every series carries the host it comes from as `host`. Until
    # 2026-11-02 alert rules took it from the job name, everything up to the
    # first dash ("grammi-restic" -> grammi) - which a host named gw-remote
    # breaks. Same label on zorlock (hosts/zorlock/monitoring.nix) and
    # grammi (hosts/grammi/victoria.nix).
    global.external_labels.host = config.networking.hostName;
    scrape_configs = [
      {
        job_name = config.networking.hostName;
        # One static_config per exporter (rather than one config with all
        # targets) so each can carry its own `instance` label override -
        # Prometheus only fills in `instance` from the target address when
        # the label isn't already present, so setting it here beats vmui
        # showing an undifferentiated "127.0.0.1:9113" in the Instance
        # dropdown with nothing indicating which exporter that even is.
        static_configs = lib.mapAttrsToList (name: port: {
          targets = [ "${cfg.exporterAddresses.${name} or "127.0.0.1"}:${toString port}" ];
          labels.instance = name;
        }) cfg.exporterPorts;
      }
    ]
    # Every host in this lab runs its own CrowdSec Security Engine (see
    # modules/crowdsec.nix) with Prometheus metrics on 6060 - mirror grammi's
    # own "grammi-crowdsec" job so this data actually reaches VictoriaMetrics
    # instead of only existing on loopback. Named "<host>-crowdsec" to match
    # grammi's local scrape_configs job naming (see hosts/grammi/victoria.nix).
    ++ lib.optional config.services.crowdsec.enable {
      job_name = "${config.networking.hostName}-crowdsec";
      static_configs = [
        {
          targets = [ "127.0.0.1:6060" ];
          labels.instance = "crowdsec";
        }
      ];
      metric_relabel_configs = wafProbeRelabel;
    }
    ++ lib.optional wafNginx {
      job_name = "${config.networking.hostName}-waf";
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString config.services.waf.nginx.metricsPort}" ];
          labels.instance = "waf";
        }
      ];
    }
    ++ cfg.extraScrapeConfigs;
  };
in
{
  imports = [ ./textfile-metrics-lab.nix ];

  options.services.metricsShipping = {
    enable = lib.mkEnableOption "ship this host's Prometheus exporters to grammi's VictoriaMetrics via vmagent";

    remoteWriteUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://grammi.peer.homelab.example:8428/api/v1/write";
      description = ''
        VictoriaMetrics remote_write endpoint, over the NetBird mesh. Mesh-only
        by design - see hosts/grammi/telemetry-ingest.nix, the ingest port is not
        in networking.firewall.allowedTCPPorts, only reachable over the
        trusted mesh interface.
      '';
    };

    basicAuth = {
      username = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          User at the receiving end (vmauth on grammi, modules/
          telemetry-ingest.nix); null sends without credentials.
        '';
      };
      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/telemetry-ingest";
        description = ''
          File holding that user's password, read at start. Any owner:
          systemd hands it to vmagent as a credential.
        '';
      };
    };

    exporterPorts = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
      example = {
        node = 9100;
        nginx = 9113;
      };
      description = ''
        Local ports to scrape, named - this host's own
        services.prometheus.exporters.<name>.port values. The name becomes
        this target's `instance` label in VictoriaMetrics, so vmui shows
        e.g. "node"/"nginx" instead of an undifferentiated "127.0.0.1:9113".
      '';
    };

    defaultExporters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "node"
        "node-cert"
        "nginx"
        "nginxlog"
        # disk-health.nix in textfile-metrics, on hosts with SMART disks.
        "smartctl"
      ];
      description = ''
        services.prometheus.exporters.<name> registered in exporterPorts
        automatically wherever they are enabled, so hosts list only their
        own extra exporters.
      '';
    };

    exporterAddresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        restic = "[::1]";
      };
      description = ''
        Loopback address to scrape per exporterPorts name, "127.0.0.1" where
        absent. For exporters that also answer on [::1] through
        modules/loopback-v6-proxy.nix: the lab prefers IPv6, so those are
        scraped there. IPv6 literals need their brackets.
      '';
    };

    extraScrapeConfigs = lib.mkOption {
      type = lib.types.listOf (pkgs.formats.yaml { }).type;
      default = [ ];
      example = [
        {
          job_name = "myhost-gotenberg";
          metrics_path = "/prometheus/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:3000" ];
              labels.instance = "gotenberg";
            }
          ];
        }
      ];
      description = ''
        Additional vmagent scrape_configs, for targets exporterPorts cannot
        express - metrics_path is per job, so anything not on /metrics needs
        a job of its own. Named "<host>-<service>" like the crowdsec job.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.metricsShipping.exporterPorts = lib.mapAttrs (_: e: e.port) (
      lib.filterAttrs (name: e: builtins.elem name cfg.defaultExporters && e.enable) (
        lib.getAttrs (builtins.filter (
          n: config.services.prometheus.exporters ? ${n}
        ) cfg.defaultExporters) config.services.prometheus.exporters
      )
    );

    assertions = [
      {
        assertion = (cfg.basicAuth.username == null) == (cfg.basicAuth.passwordFile == null);
        message = "services.metricsShipping.basicAuth: set username and passwordFile together.";
      }
    ];

    systemd.services.vmagent = {
      description = "vmagent - ships local Prometheus metrics to ${cfg.remoteWriteUrl}";
      # The endpoint only resolves (peer.homelab.example via NetBird's DNS) and
      # routes over the mesh, so start after the client. Ordering only, no
      # Wants=: while the mesh is down vmagent keeps its queue on disk under
      # /var/lib/vmagent and sends it once grammi is reachable again.
      after = [
        "network-online.target"
        "netbird-mesh.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # The shared sandbox (hardening.nix in textfile-metrics, #18): scrapes loopback,
      # ships over the mesh, writes only its queue.
      hardening = {
        enable = true;
        level = "strict";
        network = "any";
      };
      serviceConfig = {
        DynamicUser = true;
        # vmagent's remote-write component persists an on-disk queue and
        # defaults to a path relative to its cwd ("vmagent-remotewrite-data").
        # DynamicUser gets no writable cwd (ProtectSystem defaults to "strict"
        # under DynamicUser, / read-only) - it crash-looped with "cannot
        # create directory: mkdir vmagent-remotewrite-data: read-only file
        # system" until pointed at an explicit, writable path. StateDirectory
        # creates and owns /var/lib/vmagent for the dynamic user.
        StateDirectory = "vmagent";
        # -enableTCP6: without it vmagent dials IPv4 only and fails every
        # target written as "[::1]:port" ("no suitable address found"), see
        # exporterAddresses.
        ExecStart = lib.concatStringsSep " " (
          [
            "${pkgs.victoriametrics}/bin/vmagent"
            "-promscrape.config=${scrapeConfig}"
            "-remoteWrite.url=${cfg.remoteWriteUrl}"
            "-remoteWrite.tmpDataPath=/var/lib/vmagent"
            "-enableTCP6"
            "-httpListenAddr=127.0.0.1:8429"
          ]
          ++ lib.optionals (cfg.basicAuth.username != null) [
            "-remoteWrite.basicAuth.username=${cfg.basicAuth.username}"
            "-remoteWrite.basicAuth.passwordFile=/run/credentials/vmagent.service/ingest-password"
          ]
        );
        LoadCredential = lib.mkIf (cfg.basicAuth.passwordFile != null) [
          "ingest-password:${cfg.basicAuth.passwordFile}"
        ];
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
