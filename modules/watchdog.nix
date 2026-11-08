# The hardware watchdog, held by systemd (issue #117).
#
# With RuntimeWatchdogSec set, PID 1 opens the watchdog device at boot and
# pings it every half timeout. If PID 1 hangs (a crash freezes it, see
# CrashAction= in systemd-system.conf(5)) or the kernel locks up, the pings
# stop and the hardware resets the host. RebootWatchdogSec (systemd's 10 min
# default) already covered a hanging shutdown; this adds the running system.
#
# Holding the device is also a guard: a watchdog device can only be open
# once, so nothing else gets it (EBUSY). That is how ursalia was reset four
# times on 2026-11-02/03: procd, PID 1 of gruffi's OpenWrt dry-run container
# (openwrt/gruffi/dryrun.sh, a VM since #181), opened /dev/watchdog, armed intel_oc_wdt and
# let go without the magic close when the container was removed - the
# hardware reset the host a minute later.
#
# The timeout stays the device's own ("default" - 60 s for intel_oc_wdt on
# the NUCs, 30 s for the ICH9 iTCO that QEMU emulates on the VMs). TCO v2
# cannot go much beyond that anyway.
#
# A host with more than one watchdog lists the others in blacklistedModules:
# the kernel numbers watchdogs in probe order, so with two drivers loading
# in parallel watchdog0 is not fixed, and the one systemd does not hold
# would be free for a container to arm.
#
# Hosts without any watchdog device (zummi on IONOS) get softdog, the
# kernel's software watchdog - see the softdog option.
#
# Test: `kill -SEGV 1` freezes systemd; the host has to reset within one
# timeout. `kill -STOP 1` does nothing (the kernel ignores SIGSTOP for
# init), and `echo c > /proc/sysrq-trigger` tests the panic path, not the
# watchdog.
{ config, lib, ... }:
let
  cfg = config.services.hardwareWatchdog;
  # Same directory modules/metrics.nix points node_exporter's textfile
  # collector at.
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";
in
{
  options.services.hardwareWatchdog = {
    enable = lib.mkEnableOption "the hardware watchdog, held and pinged by systemd";
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/watchdog0";
      description = "The watchdog device systemd opens (WatchdogDevice=).";
    };
    softdog = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Load the kernel's software watchdog, for hosts without a hardware one.
        It catches a hung PID 1, but not a kernel that stops running timers.
      '';
    };
    blacklistedModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "iTCO_wdt" ];
      description = "Other watchdog drivers to keep from loading, so the host has exactly one watchdog.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "default";
      WatchdogDevice = cfg.device;
    };

    boot.blacklistedKernelModules = cfg.blacklistedModules;

    # softdog is a kernel timer: a panicked kernel never fires it, and with
    # NixOS's kernel.panic=0 a panic hangs for good. So the kernel reboots on
    # its own after a panic, and a detected soft lockup becomes one. A hard
    # lockup (all CPUs with interrupts off) stays uncovered - the NMI
    # watchdog is unavailable in these VMs.
    boot.kernelModules = lib.mkIf cfg.softdog [ "softdog" ];
    boot.kernel.sysctl = lib.mkIf cfg.softdog {
      "kernel.panic" = 10;
      "kernel.softlockup_panic" = 1;
    };

    # Marker for the HardwareWatchdogInactive alert on grammi
    # (hosts/grammi/alerting.nix): node_exporter's watchdog collector shows
    # every device, this says which one systemd is supposed to hold.
    systemd.tmpfiles.rules = [
      ''f+ ${textfileDir}/hardware-watchdog.prom 0644 root root - nixlab_hardware_watchdog_enabled{name="${baseNameOf cfg.device}"} 1\n''
    ];
  };
}
