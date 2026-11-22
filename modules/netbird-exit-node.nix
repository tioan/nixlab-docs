# This host as a NetBird exit node (terraform/netbird/exit-nodes.tf: which
# hosts, who may use them, IPv4 and IPv6 routes). Imported by aldrin and
# zummi, each naming its public interface.
#
# Routing and NAT are NetBird's: with masquerade on the route, the client
# puts its own masquerade rules (v4 and v6) and the policy's forward ACL
# into its nftables tables. What this module adds:
#  - forwarding for both families through modules/forwarding.nix, set here
#    so it does not depend on the client switching it on and is visible in
#    the config: new connections only from nb-mesh out of the public
#    interface, nothing from the public side into the mesh
#    (admin/nixlab#311),
#  - counters of the forwarded traffic per family and direction, for the
#    "Exit nodes" panels in hosts/grammi/dashboards/netbird.json.
#
# Reverse-path filtering stays at modules/firewall.nix' "strict": client
# packets arrive on nb-mesh from the overlay ranges (connected routes on
# nb-mesh), the internet's replies on the public interface, whose default
# routes cover them.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.netbirdExitNode;
  mesh = config.services.netbird.clients.mesh.interface;
  table = "netbird-exit-node";

  # Named counters, one per family and direction: "out" is client ->
  # internet (counted before masquerade, which runs in postrouting), "in"
  # the internet's replies.
  #
  # "out" also requires a source address that is not the host's own. The
  # kernel's WireGuard sends its encrypted outer packets on the skb of the
  # plaintext packet, so postrouting sees them with iifname nb-mesh as
  # well, and "iifname nb-mesh oifname <wan>" alone counted everything the
  # host itself sends into the mesh (admin/nixlab#367). Those packets carry
  # the host's own address; forwarded client packets still carry the
  # client's overlay address, as masquerade runs later. "in" needs no such
  # condition: locally generated packets have no input interface on the
  # way out through nb-mesh, and inbound WireGuard packets never reach
  # postrouting.
  counters = lib.cartesianProduct {
    family = [
      "ipv4"
      "ipv6"
    ];
    direction = [
      "out"
      "in"
    ];
  };
  counterName = c: "${c.family}_${c.direction}";
  counterRule =
    c:
    let
      iif = if c.direction == "out" then mesh else cfg.wanInterface;
      oif = if c.direction == "out" then cfg.wanInterface else mesh;
      notLocal = lib.optionalString (c.direction == "out") " fib saddr type != local";
    in
    ''iifname "${iif}" oifname "${oif}" meta nfproto ${c.family}${notLocal} counter name "${counterName c}"'';
in
{
  options.services.netbirdExitNode = {
    enable = lib.mkEnableOption "this host as a NetBird exit node";
    wanInterface = lib.mkOption {
      type = lib.types.str;
      example = "ens18";
      description = "The public interface exit traffic leaves through.";
    };
  };

  imports = [
    ./forwarding.nix
    ./textfile-metrics-lab.nix
  ];

  config = lib.mkIf cfg.enable {
    networking.forwardFilter = {
      enable = true;
      allow = [
        {
          from = mesh;
          to = cfg.wanInterface;
        }
      ];
    };

    # Both hosts set their v6 address and default route statically through
    # ifstate, so the public interface must ignore router advertisements.
    # modules/networking.nix sets accept_ra = 0 for "all" and "default",
    # but neither reaches an interface that already exists. Seen on zummi:
    # ens6 at 2, and the kernel logging "ICMPv6: RA: ndisc_router_discovery
    # failed to add default route" on every RA (216 a day) as the provider's
    # route collided with ifstate's ::/0 via fe80::1. Pinned per interface
    # here, where ifstate owns it.
    networking.ifstate.settings.interfaces.${cfg.wanInterface}.sysctl.ipv6.accept_ra = 0;

    # The pin alone does not survive a client restart. When routing starts,
    # the client raises every accept_ra that is 1 to 2 (2 accepts RAs despite
    # forwarding) and remembers the 1; when it stops, it writes the
    # remembered value back unconditionally - EnableV6IPForwarding and
    # DisableV6IPForwarding in
    # client/internal/routemanager/systemops/v6forwarding_linux.go
    # (netbirdio/netbird v0.81.0). Once ens6 had been 1 at a start, every
    # restart turned ifstate's 0 into 1 on stop and 2 on start again. Set
    # back to 0 right before each start, so the client finds 0, leaves it
    # alone and remembers nothing, and after each stop, so a plain stop does
    # not leave its restored 1 behind either.
    systemd.services.netbird-mesh.serviceConfig =
      let
        acceptRaOff = "${pkgs.procps}/bin/sysctl -w net.ipv6.conf.${cfg.wanInterface}.accept_ra=0";
      in
      {
        ExecStartPre = lib.mkAfter [ acceptRaOff ];
        ExecStopPost = [ acceptRaOff ];
      };

    # A table of its own that only counts: its chain accepts everything, so
    # it cannot let through what NetBird's chains drop - a drop in any base
    # chain is final.
    #
    # Postrouting, not forward: the client puts "iifname nb-mesh accept"
    # (and an established rule for oifname nb-mesh) at the top of every
    # foreign filter chain on the forward and input hooks - its external
    # chain monitor, applyExternalChainAccept in
    # client/firewall/nftables/chains_linux.go (netbirdio/netbird) - and an
    # accept ends that chain before any counter below it. Seen on aldrin
    # on 2026-10-25: all four counters at 0 after a test through the exit
    # node. Postrouting chains are left alone; forwarded packets still
    # carry their input interface there, and only what the forward chains
    # (NetBird's, the firewall's, CrowdSec's) let through gets this far.
    #
    # Tables declared here are recreated on firewall reloads, which resets
    # the counters; rate()/increase() take that as a counter reset.
    networking.nftables.tables.${table} = {
      family = "inet";
      content = ''
        ${lib.concatMapStringsSep "\n        " (c: "counter ${counterName c} { }") counters}
        chain postrouting {
          type filter hook postrouting priority 0; policy accept;
          ${lib.concatMapStringsSep "\n          " counterRule counters}
        }
      '';
    };

    # Into node_exporter's textfile collector (modules/textfile-metrics-lab.nix):
    # reading the counters takes CAP_NET_ADMIN and a netlink socket, nothing
    # else.
    services.textfileMetrics.writers.netbird-exit-node-metrics = {
      description = "NetBird exit node traffic counters for node_exporter's textfile collector";
      file = "netbird-exit-node.prom";
      path = [
        pkgs.nftables
        pkgs.jq
      ];
      unit.after = [ "nftables.service" ];
      hardening = {
        network = "netlink";
        capabilities = [ "CAP_NET_ADMIN" ];
      };
      script = ''
        nft -j list counters table inet ${table} | jq -r '
          [.nftables[] | select(.counter) | .counter | (.name | split("_")) as [$f, $d] | {f: $f, d: $d, bytes, packets}] as $c
          | "# HELP netbird_exit_node_bytes_total Bytes forwarded between nb-mesh and the public interface.",
            "# TYPE netbird_exit_node_bytes_total counter",
            ($c[] | "netbird_exit_node_bytes_total{family=\"\(.f)\",direction=\"\(.d)\"} \(.bytes)"),
            "# HELP netbird_exit_node_packets_total Packets forwarded between nb-mesh and the public interface.",
            "# TYPE netbird_exit_node_packets_total counter",
            ($c[] | "netbird_exit_node_packets_total{family=\"\(.f)\",direction=\"\(.d)\"} \(.packets)")
        '
      '';
      timer = {
        OnBootSec = "1min";
        OnUnitActiveSec = "30s";
      };
    };
  };
}
