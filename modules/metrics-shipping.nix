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
{ config, lib, pkgs, ... }:
let
  cfg = config.services.metricsShipping;

  scrapeConfig = (pkgs.formats.yaml { }).generate "vmagent-scrape.yaml" {
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
          targets = [ "127.0.0.1:${toString port}" ];
          labels.instance = name;
        }) cfg.exporterPorts;
      }
    ]
    # Every host in this lab runs its own CrowdSec Security Engine (see
    # modules/crowdsec.nix) with Prometheus metrics on 6060 - mirror grammi's
    # own "grammi-crowdsec" job so this data actually reaches VictoriaMetrics
    # instead of only existing on loopback. Named "<host>-crowdsec" to match
    # grammi's local scrape_configs job naming (see hosts/grammi/configuration.nix).
    ++ lib.optional config.services.crowdsec.enable {
      job_name = "${config.networking.hostName}-crowdsec";
      static_configs = [{ targets = [ "127.0.0.1:6060" ]; labels.instance = "crowdsec"; }];
    };
  };
in
{
  options.services.metricsShipping = {
    enable = lib.mkEnableOption "ship this host's Prometheus exporters to grammi's VictoriaMetrics via vmagent";

    remoteWriteUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://grammi.peer.homelab.example:8428/api/v1/write";
      description = ''
        VictoriaMetrics remote_write endpoint, over the NetBird mesh. Mesh-only
        by design - see hosts/grammi/configuration.nix, the ingest port is not
        in networking.firewall.allowedTCPPorts, only reachable over the
        trusted mesh (and tailnet) interface.
      '';
    };

    exporterPorts = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
      example = { node = 9100; nginx = 9113; };
      description = ''
        Local ports to scrape, named - this host's own
        services.prometheus.exporters.<name>.port values. The name becomes
        this target's `instance` label in VictoriaMetrics, so vmui shows
        e.g. "node"/"nginx" instead of an undifferentiated "127.0.0.1:9113".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.vmagent = {
      description = "vmagent - ships local Prometheus metrics to ${cfg.remoteWriteUrl}";
      # The endpoint only resolves (peer.homelab.example via NetBird's DNS) and
      # routes over the mesh, so start after the client. Ordering only, no
      # Wants=: while the mesh is down vmagent keeps its queue on disk under
      # /var/lib/vmagent and sends it once grammi is reachable again.
      after = [ "network-online.target" "netbird-mesh.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
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
        ExecStart = ''
          ${pkgs.victoriametrics}/bin/vmagent \
            -promscrape.config=${scrapeConfig} \
            -remoteWrite.url=${cfg.remoteWriteUrl} \
            -remoteWrite.tmpDataPath=/var/lib/vmagent \
            -httpListenAddr=127.0.0.1:8429
        '';
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
