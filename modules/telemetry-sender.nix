# This lab's senders of metrics and logs: once hosts/<host>/telemetry.yaml
# exists (`just telemetry-credentials`), vmagent and Vector ship to grammi's
# vmauth on :8427 (hosts/grammi/telemetry-ingest.nix, nixlab#15) as the user
# named after this host, instead of to VictoriaMetrics/-Logs directly.
# Without the file nothing changes.
#
# The password comes from sops; a host without sops of its own (the gw-remote
# container, whose secrets aldrin mounts in) sets fromSops = false and
# passwordFile instead.
{ config, lib, ... }:
let
  cfg = config.services.telemetrySender;
  name = config.networking.hostName;
  secretsFile = ../hosts + "/${name}/telemetry.yaml";
  hasSecrets = builtins.pathExists secretsFile;
  ships = config.services.metricsShipping.enable || config.services.logShipping.enable;
  ingest = lib.importJSON ../hosts/grammi/telemetry-ingest.json;
in
{
  options.services.telemetrySender = {
    url = lib.mkOption {
      type = lib.types.str;
      # vmauth on grammi, over the mesh; its port is grammi's
      # (hosts/grammi/telemetry-ingest.json).
      default = "http://grammi.peer.homelab.example:${toString ingest.port}";
      description = "grammi's ingest endpoint (vmauth).";
    };
    fromSops = lib.mkOption {
      type = lib.types.bool;
      default = hasSecrets && ships;
      description = "Take the password from hosts/<host>/telemetry.yaml via sops.";
    };
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if cfg.fromSops then config.sops.secrets."telemetry-ingest".path else null;
      defaultText = lib.literalMD "the sops secret from `hosts/<host>/telemetry.yaml`, if that exists";
      description = "This host's ingest password; null keeps shipping without one, to the old ports.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.fromSops {
      sops.secrets."telemetry-ingest" = {
        sopsFile = secretsFile;
        key = name;
        restartUnits =
          lib.optional config.services.metricsShipping.enable "vmagent.service"
          ++ lib.optional config.services.logShipping.enable "vector.service";
      };
    })
    (lib.mkIf (ships && cfg.passwordFile != null) {
      services.metricsShipping = {
        remoteWriteUrl = "${cfg.url}/api/v1/write";
        basicAuth = {
          username = name;
          inherit (cfg) passwordFile;
        };
      };
      services.logShipping = {
        victoriaLogsUrl = cfg.url;
        basicAuth = {
          username = name;
          inherit (cfg) passwordFile;
        };
      };
    })
  ];
}
