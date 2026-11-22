# The lab's part of the restic jobs (#318): restic-s3 and restic-s3-sops from
# the input restic-verified (github.com/tioan/nixos-restic-verified, #327) are
# reusable and hold no lab values, this file fills them in for the lab. Like
# modules/waf.nix next to modules/waf-lab.nix.
#
#   - target: Garage on aldrin, the endpoint from inventory.json
#     (lab.s3.endpoint, profiles/lab-s3.nix), region `garage`
#   - secrets: `hostSecrets` keeps the names from before restic-s3,
#     one set per host (restic_password, garage_backup_key_id,
#     garage_backup_secret_key, template restic-s3-env); every Garage job
#     except the data jobs of modules/restic-data.nix uses them
#   - metrics: restic-verified writes into the textfile directory
#     of modules/textfile-metrics.nix, with its prefix, so the alerts in
#     hosts/grammi/alerting/backups.nix read the same series as always
#   - exporter: dual stack on loopback through modules/loopback-v6-proxy.nix,
#     registered with modules/metrics-shipping.nix where that is enabled; a
#     host that scrapes itself (grammi) registers it on its own
#
# Retries: restic-verified's default retryAt (05:15, 07:15) lies
# after the upgrade/reboot window at 04:00 (modules/deploy.nix).
#
# Setting up a job: bucket and key in terraform/garage, `just garage-apply`,
# the secrets into the job's sops file, deploy, then once `restic-<job> init`.
# The exporter's read-only key: terraform/garage/restic-exporter.tf, into sops
# with `just restic-exporter-secrets` (#312).
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.services.resticS3;
  textfile = config.services.textfileMetrics;
in
{
  imports = [
    ./lab.nix
    ./loopback-v6-proxy.nix
    ./restic-sqlite.nix
    ./textfile-metrics-lab.nix
    inputs.restic-verified.nixosModules.restic-verified
    inputs.restic-verified.nixosModules.restic-s3
    inputs.restic-verified.nixosModules.restic-s3-sops
  ];

  options.services.resticS3.jobs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options.hostSecrets = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Use the secret names from before restic-s3, one set per
              host: restic_password, garage_backup_key_id, garage_backup_secret_key
              and the template restic-s3-env. Otherwise they are named after the
              job (restic-s3-sops).
            '';
          };
          config.secretNames = lib.mkIf config.hostSecrets {
            password = "restic_password";
            keyId = "garage_backup_key_id";
            secretKey = "garage_backup_secret_key";
            environment = "restic-s3-env";
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      services.resticS3.endpoint = lib.mkDefault config.lab.s3.endpoint;
      services.resticS3.region = "garage";
      # The root directory of the textfile collector, not a writer directory of
      # its own: the backup job runs as root anyway (#320, decision 2a).
      services.resticVerified.textfileDir = textfile.directory;
      services.resticVerified.metricPrefix = textfile.metricPrefix;
    }
    (lib.mkIf (cfg.exporter.job != null) {
      # [::1] is answered by the proxy, so the endpoint stays dual stack.
      services.loopbackV6Proxy.restic-exporter.port = config.services.prometheus.exporters.restic.port;
    })
    (lib.mkIf (cfg.exporter.job != null && config.services.metricsShipping.enable) {
      services.metricsShipping.exporterPorts.restic = config.services.prometheus.exporters.restic.port;
      services.metricsShipping.exporterAddresses.restic = "[::1]";
    })
  ];
}
