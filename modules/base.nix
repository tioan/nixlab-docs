# Baseline every host in this lab shares: locale, console, time, and the
# handful of tools that should exist on any machine you might have to debug
# from a VNC console at two in the morning.
{ pkgs, ... }:
{
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
  # each other via Tailscale MagicDNS, everything else via real DNS. Off means
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
  ];
}
