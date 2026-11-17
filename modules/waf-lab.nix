# The lab's glue for modules/waf.nix: where the bouncer key lives. The WAF
# module itself takes the key as a runtime path and knows nothing of sops or
# this repository's layout (admin/nixlab#327).
#
# `just waf-key <host>` registers the bouncer with the host's LAPI and writes
# its key to hosts/<host>/waf.yaml (sops): crowdsec_nginx_bouncer_api_key on
# an nginx host, crowdsec_traefik_bouncer_api_key on a Traefik host. Until
# that file exists the AppSec engine runs, but no proxy asks it.
#
# The Traefik plugin judges the client by X-Forwarded-For only when the peer
# is the mesh: the NetBird reverse proxy reaches Traefik's apps entrypoint
# from there (hosts/grammi/traefik.nix).
#
# Plus the metric for "AppSec unreachable": a textfile writer
# (modules/textfile-metrics.nix) asks the AppSec port once a minute. Both
# bouncers fail open (services.waf.failOpen), so without it an AppSec that
# is down would only show as a WAF that never blocks. The alert is
# WafAppsecDown in hosts/grammi/alerting.nix.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.waf;
  keyFile = ../hosts + "/${config.networking.hostName}/waf.yaml";
  hasKey = builtins.pathExists keyFile;
  onTraefik = config.services.traefik.enable;
in
{
  imports = [ ./waf.nix ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      services.textfileMetrics.writers.waf-appsec-up = {
        description = "Whether the AppSec WAF answers on its port";
        path = [ pkgs.curl ];
        hardening.network = "loopback";
        timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
        };
        script = ''
          # Without the bouncer key AppSec answers 401; any HTTP answer means up.
          code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 http://${cfg.listen}/ || true)
          up=0
          case "$code" in [1-5][0-9][0-9]) up=1 ;; esac
          echo "# HELP ${cfg.metricPrefix}waf_appsec_up 1 if CrowdSec's AppSec component answered HTTP on its port."
          echo "# TYPE ${cfg.metricPrefix}waf_appsec_up gauge"
          echo "${cfg.metricPrefix}waf_appsec_up $up"
        '';
      };
    }

    (lib.mkIf (hasKey && !onTraefik) {
      sops.secrets.crowdsec_nginx_bouncer_api_key = {
        sopsFile = keyFile;
        restartUnits = [ "nginx.service" ];
      };
      services.waf.nginx.apiKeyFile = config.sops.secrets.crowdsec_nginx_bouncer_api_key.path;
    })
    (lib.mkIf (hasKey && onTraefik) {
      sops.secrets.crowdsec_traefik_bouncer_api_key = {
        sopsFile = keyFile;
        owner = config.services.traefik.user or "traefik";
        restartUnits = [ "traefik.service" ];
      };
      services.waf.traefik = {
        enable = true;
        apiKeyFile = config.sops.secrets.crowdsec_traefik_bouncer_api_key.path;
        trustedProxies = config.lab.mesh.networks;
      };
    })
  ]);
}
