# SMART health of a physical host's disks: smartd runs the drives' own
# self-tests and watches their attributes, smartctl_exporter publishes the
# values, vmagent ships them to grammi - dashboard
# hosts/grammi/dashboards/disk-health.json. For bare-metal hosts only; the
# VMs have no SMART to speak of. Switched on by listing the disks:
#
#   services.diskHealth.devices = [
#     "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENX0RA37472W"
#     "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0T503666T"
#   ];
#
# Listed, not autodiscovered: behind the ArkKVM a host also sees the KVM's
# virtual USB drive and virtual media, which are not worth polling. By-id
# paths with model and serial rather than kernel names, because /dev/sdX
# moves with whatever USB devices are plugged in, and the path ends up in
# the exporter's `device` label - it should say which disk it is.
#
# Schedule, staggered by position in the list so no two tests of one host
# run at the same time (a long test reads the whole disk - 640 min on the
# 8 TB QVO - and slows its I/O while it runs):
#   short     every Sunday, 03:00 for the first disk, 04:00 for the second, ...
#   extended  monthly at 01:00, on the 1st for the first disk, the 2nd for
#             the second, ...
# smartd's -a additionally checks health and attributes every 30 minutes and
# logs every change and every failed test to the journal, which log
# shipping forwards to VictoriaLogs on grammi.
#
# smartctl_exporter 0.14 does not export the self-test log, so the outcome
# of the tests goes through node_exporter's textfile collector instead
# (hourly, same `device` label as the exporter - the by-id basename):
#
#   smart_selftest_running{device}                      1 while a test runs
#   smart_selftest_last_passed{device,test}             1 = completed without error
#   smart_selftest_last_power_on_hours{device,test}     power-on hours of that test
#
# test is short/extended/other. last_passed is 0 for aborted tests too (a
# reboot during the 11 h QVO test, for instance) - the journal says which.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.diskHealth;
  pad = n: lib.fixedWidthString 2 "0" (toString n);
in
{
  options.services.diskHealth.devices = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5SSNF0T503666T" ];
    description = ''
      Physical disks to self-test and monitor, as /dev/disk/by-id paths. The
      position in the list decides the test slot (see the module header).
      Empty: the module does nothing.
    '';
  };

  config = lib.mkIf (cfg.devices != [ ]) {
    # Long tests on day 1..n of the month; 21 keeps the short-test hours
    # (03 + index) inside the day as well.
    assertions = [{
      assertion = lib.length cfg.devices <= 21;
      message = "services.diskHealth: at most 21 disks per host (one test slot each).";
    }];

    services.smartd = {
      enable = true;
      autodetect = false;
      devices = lib.imap0 (i: device: {
        inherit device;
        options = "-a -s (S/../../7/${pad (3 + i)}|L/../${pad (1 + i)}/./01)";
      }) cfg.devices;
    };

    # Loopback only: vmagent scrapes it locally, nothing else needs it.
    services.prometheus.exporters.smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
      inherit (cfg) devices;
    };

    services.metricsShipping.exporterPorts.smartctl =
      config.services.prometheus.exporters.smartctl.port;

    # ATA: ata_smart_data.self_test.status 241-255 = in progress, the log's
    # type 1/129 short, 2/130 extended (offline/captive). NVMe:
    # current_self_test_operation != 0 = in progress, self_test_code 1
    # short, 2 extended, self_test_result 0 = completed without error.
    # Newest entry first in both logs.
    systemd.services.smart-selftest-metric = {
      description = "SMART self-test results for node_exporter's textfile collector";
      path = [ pkgs.smartmontools pkgs.jq pkgs.coreutils ];
      serviceConfig.Type = "oneshot";
      script = ''
        dir=/var/lib/prometheus-node-exporter-text-files
        {
          echo "# HELP smart_selftest_running 1 while a SMART self-test runs on the disk."
          echo "# TYPE smart_selftest_running gauge"
          echo "# HELP smart_selftest_last_passed 1 if the newest self-test of this type completed without error."
          echo "# TYPE smart_selftest_last_passed gauge"
          echo "# HELP smart_selftest_last_power_on_hours Power-on hours at the newest self-test of this type."
          echo "# TYPE smart_selftest_last_power_on_hours gauge"
          for dev in ${lib.escapeShellArgs cfg.devices}; do
            smartctl -j -c -l selftest "$dev" 2>/dev/null | jq -r --arg d "$(basename "$dev")" '
              def kind: if . % 128 == 1 then "short" elif . % 128 == 2 then "extended" else "other" end;
              def lbl($t): "{device=\"\($d)\",test=\"\($t)\"}";
              if .nvme_self_test_log then
                (.nvme_self_test_log as $l
                  | "smart_selftest_running{device=\"\($d)\"} \(if $l.current_self_test_operation.value != 0 then 1 else 0 end)",
                    ($l.table // [] | group_by(.self_test_code.value | kind)[] | .[0]
                      | (.self_test_code.value | kind) as $t
                      | "smart_selftest_last_passed\(lbl($t)) \(if .self_test_result.value == 0 then 1 else 0 end)",
                        "smart_selftest_last_power_on_hours\(lbl($t)) \(.power_on_hours)"))
              else
                "smart_selftest_running{device=\"\($d)\"} \(if (.ata_smart_data.self_test.status.value // 0) >= 241 then 1 else 0 end)",
                (.ata_smart_self_test_log.standard.table // [] | group_by(.type.value | kind)[] | .[0]
                  | (.type.value | kind) as $t
                  | "smart_selftest_last_passed\(lbl($t)) \(if .status.passed then 1 else 0 end)",
                    "smart_selftest_last_power_on_hours\(lbl($t)) \(.lifetime_hours)")
              end'
          done
        } > "$dir/smart-selftest.prom.tmp"
        chmod 0644 "$dir/smart-selftest.prom.tmp"
        mv "$dir/smart-selftest.prom.tmp" "$dir/smart-selftest.prom"
      '';
    };
    systemd.timers.smart-selftest-metric = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1h";
      };
    };
  };
}
