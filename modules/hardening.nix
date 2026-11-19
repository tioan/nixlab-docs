# Reusable module: one systemd sandbox profile for services, in graded
# levels, instead of a hand-copied block of directives per unit
# (admin/nixlab#18, #320).
#
#   systemd.services.foo.hardening = {
#     enable = true;
#     level = "standard";
#     network = "loopback";
#     capabilities = [ "CAP_DAC_READ_SEARCH" ];
#   };
#
# Every exception is an explicit argument, so `git grep hardening` shows
# what each unit was allowed and the comment next to it says why. The
# directives are set at normal priority: a unit that defines the same
# single-valued directive differently fails evaluation instead of silently
# winning or losing - pick one place.
#
# What each directive typically breaks, so an exception is deliberate:
#
#   level "base" - safe for nearly every daemon
#     NoNewPrivileges        setuid helpers (sudo, ping without caps, newuidmap)
#     ProtectSystem=strict   writes outside writablePaths and the unit's own
#                            State/Cache/Logs/RuntimeDirectory
#     ProtectHome            anything under /home, /root, /run/user
#     PrivateTmp             sharing files through /tmp with other units
#     PrivateDevices         raw devices: disks (smartctl), GPU, serial,
#                            /dev/virtio-ports; see `devices`
#     ProtectKernelTunables  writing /proc/sys, /sys (sysctl, nft does not care)
#     ProtectKernelModules   modprobe from the service
#     ProtectKernelLogs      dmesg / /dev/kmsg readers
#     ProtectControlGroups   cgroup writes (container managers); reads stay
#     ProtectClock           setting the clock; implies DevicePolicy=closed,
#                            which together with `devices` is fine
#     ProtectHostname        sethostname
#     RestrictNamespaces     user namespaces: podman, gVisor, bubblewrap,
#                            Chromium's sandbox
#     RestrictRealtime       audio/RT scheduling
#     RestrictSUIDSGID       creating setuid files
#     LockPersonality        old 32-bit personality tricks
#     SystemCallArchitectures=native  32-bit binaries on x86_64
#
#   level "standard" - base plus
#     CapabilityBoundingSet  everything not in `capabilities` (empty = none);
#                            root services that chown, bind < 1024 or read
#                            foreign files need theirs listed
#     SystemCallFilter       @system-service minus @privileged (chown, setuid,
#                            mount, raw I/O, ...) and @resources (setrlimit,
#                            sched_setaffinity, ...); add back with
#                            `systemCalls`; a violation is EPERM, not a kill
#     ProtectProc=invisible  seeing other users' processes (/proc/<pid>);
#     ProcSubset=pid           /proc/cpuinfo, /proc/meminfo, /proc/net -
#                            `seeProcesses` turns both off
#     UMask=0077             files other users are meant to read: set
#                            `umask` (e.g. "0022" for textfile metrics)
#
#   level "strict" - standard plus
#     MemoryDenyWriteExecute JIT runtimes: Node, Java, LuaJIT, PyPy, some
#                            regex engines; `writeExecute` keeps them working
#     PrivateIPC             SysV IPC / POSIX queues shared with other units
#     RemoveIPC              the same, for a static user's leftovers
#
#   network (independent of the level)
#     "none"      PrivateNetwork, AF_UNIX only: no sockets but local ones
#     "netlink"   host namespace, AF_UNIX + AF_NETLINK, no IP sockets: for
#                 kernel state such as nftables counters (with CAP_NET_ADMIN)
#                 or nl80211; cannot open a connection
#     "loopback"  IP sockets, but IPAddressDeny=any except localhost
#     "any"       IP sockets to anywhere
#   `addressFamilies` adds to the list (e.g. AF_NETLINK for getifaddrs).
{ lib, ... }:
let
  inherit (lib) mkOption types;

  hardeningOptions = {
    enable = lib.mkEnableOption "the shared systemd sandbox profile for this unit";

    level = mkOption {
      type = types.enum [
        "base"
        "standard"
        "strict"
      ];
      default = "standard";
      description = "How much of the profile applies; see the module header for what each level adds.";
    };

    network = mkOption {
      type = types.enum [
        "none"
        "netlink"
        "loopback"
        "any"
      ];
      default = "none";
      description = "Which sockets the unit may open.";
    };

    addressFamilies = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "AF_NETLINK" ];
      description = "Address families on top of what `network` allows.";
    };

    capabilities = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "CAP_NET_ADMIN" ];
      description = ''
        The bounding set from level "standard" on, also granted as ambient
        capabilities so a non-root User has them (a no-op for root).
      '';
    };

    ambientCapabilities = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Grant `capabilities` as ambient capabilities. Off for units whose
        capabilities are only meant for a root ExecStartPre or similar.
      '';
    };

    systemCalls = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "@chown"
        "perf_event_open"
      ];
      description = "System calls or groups added back after the deny list (level standard and up).";
    };

    writablePaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "ReadWritePaths: paths outside the unit's own directories it must write.";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "block-sd r"
        "char-nvme rw"
      ];
      description = ''
        DeviceAllow entries. Non-empty turns PrivateDevices off and the
        device policy to closed, so only these (and the pseudo devices)
        are reachable.
      '';
    };

    seeProcesses = mkOption {
      type = types.bool;
      default = false;
      description = "Keep other processes and all of /proc visible (no ProtectProc/ProcSubset).";
    };

    writeExecute = mkOption {
      type = types.bool;
      default = false;
      description = "Allow writable-executable memory at level strict (JIT runtimes).";
    };

    umask = mkOption {
      type = types.str;
      default = "0077";
      description = "UMask from level standard on.";
    };
  };

  atLeast =
    want: level:
    let
      rank = {
        base = 0;
        standard = 1;
        strict = 2;
      };
    in
    rank.${level} >= rank.${want};

  profile =
    h:
    let
      std = atLeast "standard" h.level;
      strict = atLeast "strict" h.level;
      families =
        {
          none = [ "AF_UNIX" ];
          netlink = [
            "AF_UNIX"
            "AF_NETLINK"
          ];
          loopback = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
          any = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];
        }
        .${h.network}
        ++ h.addressFamilies;
    in
    {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = h.devices == [ ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = lib.unique families;
      PrivateNetwork = h.network == "none";
    }
    // lib.optionalAttrs (h.network == "loopback") {
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
    }
    // lib.optionalAttrs (h.writablePaths != [ ]) { ReadWritePaths = h.writablePaths; }
    // lib.optionalAttrs (h.devices != [ ]) {
      DevicePolicy = "closed";
      DeviceAllow = h.devices;
    }
    // lib.optionalAttrs std {
      # An empty assignment is the empty set: no capabilities at all.
      CapabilityBoundingSet = if h.capabilities == [ ] then "" else h.capabilities;
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
        "~@resources"
      ]
      ++ h.systemCalls;
      SystemCallErrorNumber = "EPERM";
      UMask = h.umask;
    }
    // lib.optionalAttrs (std && !h.seeProcesses) {
      ProtectProc = "invisible";
      ProcSubset = "pid";
    }
    // lib.optionalAttrs (std && h.ambientCapabilities && h.capabilities != [ ]) {
      AmbientCapabilities = h.capabilities;
    }
    // lib.optionalAttrs strict {
      MemoryDenyWriteExecute = !h.writeExecute;
      PrivateIPC = true;
      RemoveIPC = true;
    };
in
{
  options.systemd.services = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.hardening = hardeningOptions;
          config.serviceConfig = lib.mkIf config.hardening.enable (profile config.hardening);
        }
      )
    );
  };
}
