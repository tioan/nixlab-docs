# Networking baseline every host in this lab shares. The host-specific part -
# which interface, which addresses, which routes - stays in each host's own
# configuration.nix under networking.ifstate.settings; only the shape of the
# setup lives here, so a new machine inherits it by importing this module.
{
  # ifstate rather than the NixOS defaults or systemd-networkd: these are
  # rented VMs with static addressing handed out by the provider, often with
  # unusual routing (/32 addresses, onlink gateways, link-local v6 next-hops),
  # which ifstate expresses directly.
  #
  # Careful when adding a host: ifstate reconciles the *entire* link and
  # routing state and removes whatever the config does not declare. Anything
  # another daemon installs behind its back gets torn down on every
  # activation - see modules/tailscale.nix for the ignore rules that keep it
  # off Tailscale's interface and policy rules.
  networking.ifstate.enable = true;
  networking.useDHCP = false;

  # ifstate is the single source of truth for routing (see the comment
  # above), but the kernel's own IPv6 stack is a second, uncontrolled path to
  # the same routing table: with forwarding off, accept_ra defaults to 1, so
  # any router advertisement the provider's network still emits makes the
  # kernel try to install its own default route alongside the static one
  # ifstate already configured - racing/duplicating it. Seen on zummi as a
  # kernel log line ("ICMPv6: RA: ndisc_router_discovery failed to add
  # default route") the moment the provider's RA collided with the static
  # ::/0 via fe80::1 route. Disabling RA/autoconf here removes that second
  # path entirely, consistent with routing being fully static everywhere.
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.default.autoconf" = 0;
  };

  # DNS resolution goes through systemd-resolved, encrypted with DNS-over-TLS
  # to Freifunk München. DoT rather than DoH because resolved speaks it
  # natively - DoH would mean running a second daemon (blocky, cloudflared,
  # adguardhome) that resolution then depends on.
  #
  # The `#dot.ffmuc.net` suffix is not decoration: it is the name resolved
  # validates the server certificate against. Without it there is a TLS
  # connection but no proof of who is on the other end.
  #
  # DNSOverTLS = "true" is strict on purpose. The "opportunistic" setting falls
  # back to plaintext whenever port 853 is unreachable, which means it protects
  # against a passive observer and not at all against anyone able to interfere
  # - the case actually worth defending against. The price is a real failure
  # mode: if 853 is blocked, name resolution stops rather than degrades, and
  # that takes ACME, restic and nix's substituters with it.
  #
  # DNSSEC stays off (the module default). The upstream resolver validates, and
  # the DoT connection already authenticates the path; local validation would
  # mostly add another way for resolution to fail.
  #
  # networking.nameservers is deliberately gone: settings.Resolve.DNS defaults
  # to it, and having both would leave two places claiming to define the
  # resolvers with only one of them in effect.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "5.1.66.255#dot.ffmuc.net"
        "185.150.99.255#dot.ffmuc.net"
        "2001:678:e68:f000::#dot.ffmuc.net"
        "2001:678:ed0:f000::#dot.ffmuc.net"
      ];
      DNSOverTLS = "true";

      # systemd ships compiled-in fallbacks (Cloudflare, Google, Quad9) that
      # apply when no DNS server is configured. They should never be reached
      # here, but leaving them in place means a configuration that fails to
      # apply resolves via Google instead of failing - quietly undoing both the
      # encryption and the choice of provider. Empty disables them.
      FallbackDNS = [ ];
    };
  };
}
