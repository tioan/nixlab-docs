# No ICMP redirects, in either direction (admin/nixlab#310). Imported by
# modules/base.nix for every host and by the gw-remote container
# (hosts/gw-remote/container.nix), whose network namespace has values of its
# own - the host's never reach it. Only net.* keys, so it works inside a
# container, where the rest of /proc/sys is read-only.
#
# Nothing here learns its routes from redirects: routing is static
# (ifstate, modules/networking.nix) or NetBird's. Accepting them only lets
# whoever shares a link rewrite a route; sending them tells the other side
# of a tunnel about this host's routing, and on the forwarding hosts
# (exit nodes, routing peers, gw-remote) every client sits behind a WireGuard
# or OpenVPN link where a redirect has nothing to point to.
#
# Globs, not just "all" and "default": for IPv4 the kernel combines "all"
# with the interface's own value (OR for send_redirects, and for
# accept_redirects on a host that does not forward), so an interface that
# exists before systemd-sysctl runs keeps its 1 - seen on zummi, where
# ens6/send_redirects was 1 under all=0. systemd-sysctl applies the glob to
# every existing interface, "default" covers interfaces created later (the
# tunnels, nb-mesh), and on hosts with udev its 99-systemd.rules reapplies
# the glob to every new one as well.
#
# rp_filter, forwarding and accept_ra are not set here: modules/firewall.nix,
# modules/netbird-exit-node.nix / the hosts, and modules/networking.nix own
# them.
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.*.accept_redirects" = 0;
    "net.ipv4.conf.*.secure_redirects" = 0;
    "net.ipv4.conf.*.send_redirects" = 0;
    "net.ipv6.conf.*.accept_redirects" = 0;
  };
}
