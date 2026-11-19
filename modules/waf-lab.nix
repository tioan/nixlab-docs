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
# Plus the metrics for "AppSec unreachable" and "AppSec refuses the key": a
# textfile writer (modules/textfile-metrics.nix) runs the WAF module's probe
# once a minute with the bouncer's key. Both bouncers fail open
# (services.waf.failOpen), so without it an AppSec that is down would only
# show as a WAF that never blocks. The alerts are WafAppsecDown and
# WafAppsecProbeFailed in hosts/grammi/alerting/security.nix.
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.waf;
  keyFile = ../hosts + "/${config.networking.hostName}/waf.yaml";
  hasKey = builtins.pathExists keyFile;
  onTraefik = config.services.traefik.enable;
  # The key of whichever bouncer this host runs; null until `just waf-key`.
  bouncerKey = if onTraefik then cfg.traefik.apiKeyFile else cfg.nginx.apiKeyFile;
in
{
  imports = [ ./waf.nix ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.textfileMetrics.writers.waf-appsec-up = {
          description = "Whether the AppSec WAF answers and accepts the bouncer key";
          hardening.network = "loopback";
          timer = {
            OnBootSec = "1min";
            OnUnitActiveSec = "1min";
          };
          # With the key the probe sends a full request and checks for a 200;
          # without one it only opens a connection (modules/waf.nix,
          # probe.package). The key comes in as a credential: the sops file
          # stays readable by its owner only.
          # A plain string on purpose: as an indented string the leading space
          # counts as indentation and is stripped, which glued the argument
          # onto the program path (admin/nixlab#452).
          script =
            lib.escapeShellArgs [ (lib.getExe cfg.probe.package) ]
            + lib.optionalString (bouncerKey != null) " \"$CREDENTIALS_DIRECTORY/bouncer-key\"";
          unit.serviceConfig.LoadCredential = lib.optional (bouncerKey != null) "bouncer-key:${bouncerKey}";
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
    ]
  );
}
