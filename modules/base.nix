# Baseline every host in this lab shares: accounts, kernel hardening,
# locale, console, time, and the handful of tools that should exist on any machine you might have to debug
# from a VNC console at two in the morning.
{ config, pkgs, ... }:
{
  imports = [ ./no-redirects.nix ];

  # --- Accounts (admin/nixlab#310) ---
  # Only what the config declares exists, with only the passwords it
  # declares. With mutable users a user added by hand, or a password set
  # with passwd, survived every rebuild unseen - before this, root on five
  # hosts and admin on aldrin and grammi had passwords nobody could find in
  # the repo.
  #
  # root keeps exactly one password: for the console (the providers' VNC,
  # Proxmox, the physical one or the NanoKVM at home), the way in when SSH
  # and the mesh are gone. One per host, random, generated and hashed on the
  # workstation by `just root-password <host>`: the hash goes to
  # hosts/<host>/root-password.yaml (that host's key plus the recovery key),
  # the password to root-password-plain.yaml beside it (workstation and
  # recovery key only), for `just root-password-show <host>`. A host
  # without its file does not even evaluate, so it can never activate
  # without a console login - and since ursalia's prebuild builds every
  # host, a new host needs its file before it lands on main.
  #
  # admin has no password anywhere: it logs in by key, and root - not sudo -
  # is what deploys and debugging use (modules/ssh.nix). So sudo as admin
  # does not work, on purpose; neither did it on four of the hosts before.
  users.mutableUsers = false;
  sops.secrets.root_password_hash = {
    sopsFile = ../hosts/${config.networking.hostName}/root-password.yaml;
    neededForUsers = true;
  };
  users.users.root.hashedPasswordFile = config.sops.secrets.root_password_hash.path;

  # sudo executable for wheel only, so a service user cannot even reach a
  # bug in it (CVE-2021-3156, CVE-2025-32463). root runs it as the owner.
  # aldrin widens this to its btrbk user (hosts/aldrin/btrbk.nix).
  security.sudo.execWheelOnly = true;

  # --- Kernel (admin/nixlab#310) ---
  # No kexec into another kernel and no hibernation (nohibernate): nothing
  # here uses either - reboots, the nightly one included, are plain
  # `systemctl reboot` (modules/auto-upgrade-git.nix), kexec_loaded was 0
  # everywhere. The price: nixos-anywhere cannot reinstall a running host
  # by kexec, that now takes the provider's rescue system. Like
  # unprivileged_bpf_disabled below, kexec_load_disabled cannot be turned
  # off again at runtime, only by a reboot into a generation without it.
  security.protectKernelImage = true;

  # Rehearsed at runtime on zummi on 2026-11-15 (NetBird and its exit node,
  # nginx, SSH, a dry-build of the nightly upgrade).
  boot.kernel.sysctl = {
    # The kernel log to root only, and kernel addresses to nobody - not even
    # root (2): perf and bpftrace lose kernel symbols, nothing else.
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    # Unprivileged BPF was already off (2, the kernel default here); 1 makes
    # that final until the next reboot. Everything that loads BPF - NetBird,
    # systemd's IP filters - runs as root.
    "kernel.unprivileged_bpf_disabled" = 1;
    # Constant blinding in the JIT for every BPF program, root's included.
    "net.core.bpf_jit_harden" = 2;
    # ptrace only of one's own descendants - what the kernel already did,
    # written down. 2 (root only) was weighed and left: it adds little over
    # 1 and gets in the way of Chromium's crash handler (gotenberg, Grafana's
    # image renderer) and of strace in containers without CAP_SYS_PTRACE.
    "kernel.yama.ptrace_scope" = 1;
  };

  time.timeZone = "Europe/Berlin";
  services.timesyncd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  zramSwap.enable = true;

  # No multicast name resolution. systemd-resolved answers LLMNR (5355) and
  # mDNS (5353) by default, on every link; nothing here needs it - hosts find
  # each other via NetBird's DNS (peer.homelab.example), everything else via real
  # DNS. Off means
  # fewer listening sockets and no name announcements into the LAN (ursalia sits
  # on a home LAN). Only takes effect where resolved is enabled, which is every
  # host (modules/networking.nix, or the host's own config on ursalia).
  services.resolved.settings.Resolve = {
    LLMNR = "false";
    MulticastDNS = "false";
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    vim
    htop
    systemctl-tui
    bat
    jq
    eza
    tmux
    git
    # sops so secrets can be edited on the machine itself - the workstation
    # holds no key that can decrypt them (see `just secrets <host>`).
    sops
    sqlite
    # Ghostty (gusto) sends TERM=xterm-ghostty over SSH; without its terminfo
    # entry ncurses tools (htop, vim, tmux) refuse to start. Only the
    # terminfo output, not the app.
    ghostty.terminfo
  ];
}
