# The QEMU guest agent on every host in this lab, with its RPC surface cut
# down to what the hypervisor legitimately needs.
#
# Why run it at all: the agent is the only way the hypervisor can quiesce our
# filesystems before a provider-side snapshot (guest-fsfreeze-*) - without it
# every such snapshot is crash-consistent and you find out how well that went
# at restore time. It also gives a clean shutdown/reboot from the panel
# instead of firing ACPI into the dark, and the IP display there. Costs a few
# MB of RSS, which even zummi's 1.8 GiB can spare.
#
# Why filter it: the virtio channel is unauthenticated by design - whoever
# sits on the host side is root in the guest. That is no protection against
# the hoster itself, who owns our RAM either way. It protects against the
# realistic case: someone takes over the provider account and thereby has a
# root shell on every host, with no SSH key, past CrowdSec, past Tailscale -
# and read access to /run/secrets, where sops-nix has already decrypted
# everything. guest-exec and guest-file-* ARE that shell; the rest of the list
# below is incidental.
{ config, lib, pkgs, ... }:

let
  # A deny list, not an allow list. With --allow-rpcs everything unlisted is
  # blocked, guest-sync/guest-sync-delimited included - and those are the
  # handshake the host side uses to resynchronise the channel. qemu-ga does
  # NOT exempt them (qga/main.c: its one built-in exemption list applies only
  # while the filesystems are frozen), so a single forgotten line disables the
  # agent outright, and you learn about it at the next backup. A deny list
  # fails the other way round: a new panel feature simply works instead of
  # silently breaking.
  blockedRpcs = [
    # The actual reason this file exists.
    "guest-exec"
    "guest-exec-status"
    "guest-file-open"
    "guest-file-close"
    "guest-file-read"
    "guest-file-write"
    "guest-file-seek"
    "guest-file-flush"

    # Access that outlives the channel being open.
    # guest-ssh-get-authorized-keys is read-only, but it still reports which
    # keys are on the host and no panel needs it.
    "guest-set-user-password"
    "guest-ssh-add-authorized-keys"
    "guest-ssh-remove-authorized-keys"
    "guest-ssh-get-authorized-keys"

    # Time comes from timesyncd (modules/base.nix). A clock set by the host
    # moves TLS validity windows and OIDC token lifetimes.
    "guest-set-time"

    # Denial of service with nothing in return - shutdown goes through
    # guest-shutdown.
    "guest-suspend-disk"
    "guest-suspend-ram"
    "guest-suspend-hybrid"

    # Nobody here uses CPU or memory hotplug.
    "guest-set-vcpus"
    "guest-set-memory-blocks"

    # Pure information leak, unused by the panel.
    "guest-get-users"
  ];
in
{
  # On a host without the channel this is a no-op: the module hangs the start
  # off a udev rule on /dev/virtio-ports/org.qemu.guest_agent.0 and sets no
  # wantedBy, so with no such port the unit simply never runs.
  #
  # zummi is exactly that case and stays in the list anyway. Its hypervisor
  # does not attach a virtio-serial device at all - checked 2026-08-23 via
  # /sys/bus/virtio/devices/*/device, which lists 0x0010 (GPU), 0x0004 (RNG),
  # 0x0002 (block) and 0x0001 (net), with virtio ID 3 (console/serial)
  # absent. Not a driver problem: virtio_console is loaded, it just has
  # nothing to bind to, so only the hoster could change this.
  #
  # Kept enabled there regardless, for two reasons. It arms itself the day
  # that port does appear - a hoster-side change or a migration to another
  # box - with no one having to remember this file exists. And the cost is
  # disk only: qemu-ga comes prebuilt from the binary cache (71.9 MiB total
  # closure measured on grammi, of which zummi already has most through
  # glib and friends), so it does not add to the build-time memory pressure
  # that gave zummi its nixos-upgrade OOM. One host configured differently
  # from the others would cost more, in the hour someone spends working out
  # why.
  services.qemuGuest.enable = true;

  systemd.services.qemu-guest-agent = {
    # guest-shutdown execs `shutdown` off PATH. Spelled out so it does not
    # depend on whatever the unit's default PATH happens to contain.
    path = [ pkgs.systemd ];

    serviceConfig = {
      # mkForce because the upstream module assigns ExecStart directly, not
      # through mkDefault.
      ExecStart = lib.mkForce (lib.concatStringsSep " " [
        "${config.services.qemuGuest.package}/bin/qemu-ga"
        "--statedir /run/qemu-ga"
        "--block-rpcs=${lib.concatStringsSep "," blockedRpcs}"
      ]);

      # CAP_SYS_ADMIN is mandatory: FIFREEZE and FITRIM check for exactly it.
      # CAP_SYS_BOOT covers the fallback path should guest-shutdown ever not
      # go through systemctl.
      CapabilityBoundingSet = [ "CAP_SYS_ADMIN" "CAP_SYS_BOOT" ];

      NoNewPrivileges = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      ProtectKernelModules = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
      UMask = "0077";

      # AF_INET/AF_INET6 have to stay: guest-network-get-interfaces reads the
      # MAC through a SIOCGIFHWADDR ioctl on a PF_INET socket, not only
      # through getifaddrs/netlink. AF_UNIX for the systemctl dbus path,
      # AF_NETLINK for getifaddrs itself. What this actually rules out is
      # AF_PACKET and the exotics - a thin win, but a free one.
      RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" "AF_INET" "AF_INET6" ];

      # Deliberately NOT set: ProtectSystem, ProtectHome, PrivateTmp,
      # PrivateDevices, ProtectKernelTunables, ProtectClock.
      #
      # The first four build a private mount namespace. qemu-ga walks
      # /proc/self/mounts to decide what to freeze, and every one of those
      # options changes that view. The failure mode is a snapshot that caught
      # aldrin's /data (Garage) unfrozen - which you discover at restore time,
      # not at rebuild time. PrivateDevices would additionally take away
      # /dev/virtio-ports/, i.e. the channel itself.
      #
      # ProtectClock implies a DeviceAllow and thereby flips the device policy
      # to closed, after which the agent reaches no block devices at all and
      # fsfreeze/fstrim are done for. guest-set-time is already blocked above
      # by RPC, which covers what ProtectClock was for.
      #
      # The attack surface here is the RPC catalogue, not the filesystem. The
      # filter is the hardening; the systemd block must not break anything.
    };
  };
}
