# The lab side of the textfile-metrics collection, the input
# textfile-metrics (github.com/tioan/nixos-textfile-metrics, #327, item 3):
# the sandbox profile, the textfile collector with its sandboxed writers, the
# state-metrics jobs and the single writers. Every module that writes
# textfile metrics or uses the sandbox profile imports this file, so the
# lab's prefix is set wherever the options exist.
#
# The lab's own metrics keep the prefix nixlab_, which the alert rules on
# grammi (hosts/grammi/alerting/) and the dashboards read.
{ inputs, ... }:
{
  imports = [ inputs.textfile-metrics.nixosModules.default ];

  services.textfileMetrics.metricPrefix = "nixlab_";
}
