# Shared firewall baseline for every homelab host.
#
# Public surface is deliberately tiny: SSH plus HTTP(S). Anything arriving over
# the tailnet is trusted wholesale via trustedInterfaces, so tailnet-only
# services (garage-ui behind `tailscale serve`, the admin APIs) need no port
# openings of their own.
#
# Note that several of these exist only because of Tailscale, but they live
# here rather than in tailscale.nix so that the whole networking.firewall
# namespace stays in one place.
{ config, ... }:
{
  # nftables rather than the legacy iptables backend, on every host and by
  # default for new ones. The option settings below are backend-agnostic, so
  # nothing here changes with the switch - but two things elsewhere do:
  #
  #  - services.crowdsec-firewall-bouncer picks its mode from this flag. In
  #    nftables mode the module declares the tables, sets and drop chain via
  #    networking.nftables.tables and the bouncer only fills the sets
  #    (set-only = true), instead of assembling its own chain imperatively
  #    through iptables calls at every start. Strictly more declarative.
  #  - checkReversePath is implemented with nftables' `fib` expression rather
  #    than the rpfilter match; "strict" behaves the same, but this is worth
  #    re-checking after the switch given how recently it was tuned.
  #
  # Note that switching leaves the old iptables CROWDSEC_CHAIN and its ipsets
  # behind on an already-running host; they are inert once nothing jumps to
  # them, and a reboot clears them.
  networking.nftables.enable = true;

  # 22 = SSH (root is restricted to the tailnet address, see modules/ssh.nix),
  # 80/443 = the web front (nginx; Traefik on grammi), incl. ACME challenges.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  # WireGuard/DERP handshake port for tailscaled.
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # NOTE on reverse-path filtering (networking.firewall.checkReversePath):
  # deliberately NOT set here, so NixOS' own default of "strict" applies.
  #
  # Both hosts carried "loose" from their original configs - the setting every
  # NixOS/Tailscale guide recommends. That advice targets subnet routers and
  # exit nodes, where foreign source addresses legitimately arrive on
  # tailscale0; these are plain client nodes (useRoutingFeatures unset,
  # AdvertiseRoutes/ExitNode empty per `tailscale debug prefs`).
  #
  # Trialled on zummi with logReversePathDrops: over 12h, strict dropped
  # exactly one packet, at the moment the rules were rebuilt - a self-addressed
  # TCP probe (SRC=DST=100.100.100.100, the MagicDNS resolver, TTL=0, ports 0).
  # MagicDNS resolution, tailnet ICMP, netcheck and DERP were all unaffected.

}
