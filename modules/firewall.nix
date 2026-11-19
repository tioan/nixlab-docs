# Shared firewall baseline for every homelab host.
#
# Public surface is deliberately tiny: SSH plus HTTP(S). The NetBird mesh
# interface is trusted by modules/netbird.nix; NetBird's own UDP port is
# opened there too.
{ ... }:
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

  # 22 = SSH (root is restricted to the mesh address, see modules/ssh.nix),
  # 80/443 = the web front (nginx; Traefik on grammi), incl. ACME challenges.
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  # NOTE on reverse-path filtering (networking.firewall.checkReversePath):
  # deliberately NOT set here, so NixOS' own default of "strict" applies.
  #
  # Both hosts carried "loose" from their original configs - the setting every
  # NixOS/Tailscale guide recommends for subnet routers and exit nodes. While
  # Tailscale still ran here (removed 2026-11, admin/nixlab#360) "strict" was
  # trialled on zummi with logReversePathDrops and dropped nothing that
  # mattered. Why strict also suits the NetBird exit nodes:
  # modules/netbird-exit-node.nix.

}
