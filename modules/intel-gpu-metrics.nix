# Load of an Intel iGPU for node_exporter's textfile collector, from
# intel_gpu_top (igt-gpu-tools). Shipped to grammi with the other node
# metrics; panels in hosts/grammi/dashboards/immich.json (ursalia's iGPU runs
# Immich's machine learning through OpenVINO and its video transcoding
# through Quick Sync).
#
# Neither node_exporter nor a packaged exporter covers i915 engine load. The
# one exporter around (onedr0p/intel-gpu-exporter) is archived, carries no
# license, and reads engine names with a "/0" suffix that current
# intel_gpu_top no longer prints - its busy values would stay 0. So a small
# bridge of our own: intel_gpu_top -J runs for good, one sample every 15 s,
# and modules/intel-gpu-metrics.py rewrites intel-gpu.prom after each one.
#
#   intel_gpu_engine_busy_percent{engine}          Render/3D, Video, VideoEnhance, Blitter, ...
#   intel_gpu_engine_wait_percent{engine}
#   intel_gpu_frequency_mhz{type}                  requested / actual
#   intel_gpu_rc6_percent                          time in the power-saving state
#   intel_gpu_power_watts{domain}                  gpu / package (RAPL)
#   intel_gpu_interrupts_per_second
#   intel_gpu_imc_bandwidth_mibps{direction}       only where the uncore PMU offers it
#   intel_gpu_client_busy_percent{name,engine}     per process name (gunicorn = Immich ML, ffmpeg)
#   intel_gpu_client_memory_resident_bytes{name}   GPU buffers in system RAM
#   intel_gpu_last_sample_timestamp_seconds        stale = the bridge is down
#
# Process names, not pids: a pid label would start new series on every
# restart. NixOS wrapper names (".gunicorn-wrapped", cut to 15 characters)
# are reduced to the program name.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.intelGpuMetrics;
  out = "${config.services.metricsTextfile.directory}/intel-gpu.prom";
in
{
  options.services.intelGpuMetrics = {
    enable = lib.mkEnableOption "Intel iGPU load metrics from intel_gpu_top";
    device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "drm:/dev/dri/card1";
      description = "intel_gpu_top -d filter; null takes the first Intel GPU.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.intel-gpu-metrics = {
      description = "Intel iGPU load for node_exporter's textfile collector";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      # One pipeline: intel_gpu_top's samples into the bridge. pipefail so
      # either side ending fails the unit and Restart picks it up again.
      script = ''
        set -o pipefail
        ${pkgs.intel-gpu-tools}/bin/intel_gpu_top -J -s 15000 \
          ${lib.optionalString (cfg.device != null) "-d ${lib.escapeShellArg cfg.device}"} \
          | ${pkgs.python3}/bin/python3 -u ${./intel-gpu-metrics.py} ${out}
      '';
      postStop = "rm -f ${out} ${out}.tmp";
      serviceConfig = {
        Restart = "always";
        RestartSec = "30s";
        # Root for the textfile directory (root-owned) and for the client
        # list, which reads other services' /proc/<pid>/fdinfo. Everything
        # else is taken away: i915's PMU needs CAP_PERFMON, fdinfo of other
        # users CAP_SYS_PTRACE (read access only, ptrace attach is blocked by
        # SystemCallFilter), CAP_DAC_READ_SEARCH for /proc/<pid>/fd.
        CapabilityBoundingSet = [ "CAP_PERFMON" "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH" ];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ config.services.metricsTextfile.directory ];
        ProtectHome = true;
        PrivateTmp = true;
        PrivateNetwork = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "perf_event_open" "~@privileged" ];
        DevicePolicy = "closed";
        DeviceAllow = [ "char-drm rw" ];
        Nice = 10;
      };
    };
  };
}
