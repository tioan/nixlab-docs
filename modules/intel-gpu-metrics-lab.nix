# The lab side of the intel-gpu-metrics module from the input
# intel-gpu-metrics (github.com/tioan/nixos-intel-gpu-metrics, #327, item 2):
# the bridge writes into its own sandboxed writer directory of
# modules/textfile-metrics-lab.nix instead of the textfile root, root-owned
# because the unit stays root. Metric names keep the module's default prefix
# intel_gpu_ (not textfileMetrics.metricPrefix), which
# hosts/grammi/dashboards/immich.json reads.
{
  config,
  lib,
  inputs,
  ...
}:
let
  dir = config.services.textfileMetrics.directories.intel-gpu-metrics;
in
{
  imports = [
    inputs.intel-gpu-metrics.nixosModules.intel-gpu-metrics
    ./textfile-metrics-lab.nix
  ];

  config = lib.mkIf config.services.intelGpuMetrics.enable {
    services.textfileMetrics.directories.intel-gpu-metrics = {
      user = "root";
      # Written to the textfile root before the writer directories (#320).
      legacyFiles = [ "intel-gpu.prom" ];
    };
    services.intelGpuMetrics.directory = dir.path;
    # Creates the directory and hands it to its owner, also on the first
    # switch, before tmpfiles has run.
    systemd.services.intel-gpu-metrics.serviceConfig.ExecStartPre = [ dir.execStartPre ];
  };
}
