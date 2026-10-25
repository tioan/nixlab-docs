# This host as a NetBird exit node (terraform/netbird/exit-nodes.tf: which
# hosts, who may use them, IPv4 and IPv6 routes). Imported by aldrin and
# zummi, each naming its public interface.
#
# Routing and NAT are NetBird's: with masquerade on the route, the client
# puts its own masquerade rules (v4 and v6) and the policy's forward ACL
# into its nftables tables. What this module adds:
#  - forwarding for both families, set here so it does not depend on the
#    client switching it on and is visible in the config (same reasoning as
#    on ursalia),
#  - counters of the forwarded traffic per family and direction, for the
#    "Exit nodes" panels in hosts/grammi/dashboards/netbird.json.
#
# Reverse-path filtering stays at modules/firewall.nix' "strict": client
# packets arrive on nb-mesh from the overlay ranges (connected routes on
# nb-mesh), the internet's replies on the public interface, whose default
# routes cover them. Forwarding is not filtered by the NixOS firewall
# (filterForward stays off, as on every host).
{ config, lib, pkgs, ... }:
let
  cfg = config.services.netbirdExitNode;
  mesh = config.services.netbird.clients.mesh.interface;
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";
  table = "netbird-exit-node";

  # Named counters, one per family and direction: "out" is client ->
  # internet (counted before masquerade, which runs in postrouting), "in"
  # the internet's replies.
  counters = lib.cartesianProduct { family = [ "ipv4" "ipv6" ]; direction = [ "out" "in" ]; };
  counterName = c: "${c.family}_${c.direction}";
  counterRule = c:
    let
      iif = if c.direction == "out" then mesh else cfg.wanInterface;
      oif = if c.direction == "out" then cfg.wanInterface else mesh;
    in
    ''iifname "${iif}" oifname "${oif}" meta nfproto ${c.family} counter name "${counterName c}"'';
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

  config = lib.mkIf cfg.enable {
    # IPv6 forwarding turns off accepting router advertisements (accept_ra
    # 1 only works while not forwarding). Harmless here: both hosts set
    # their v6 address and default route statically through ifstate.
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
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
    # (NetBird's, CrowdSec's) let through gets this far.
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

    # Into node_exporter's textfile collector (modules/metrics.nix), same
    # pattern as tailscale-metrics there: a timer, a temporary file and an
    # atomic rename.
    systemd.services.netbird-exit-node-metrics = {
      description = "NetBird exit node traffic counters for node_exporter's textfile collector";
      after = [ "nftables.service" ];
      path = [ pkgs.nftables pkgs.jq ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail
        out=${textfileDir}/netbird-exit-node.prom
        nft -j list counters table inet ${table} | jq -r '
          [.nftables[] | select(.counter) | .counter | (.name | split("_")) as [$f, $d] | {f: $f, d: $d, bytes, packets}] as $c
          | "# HELP netbird_exit_node_bytes_total Bytes forwarded between nb-mesh and the public interface.",
            "# TYPE netbird_exit_node_bytes_total counter",
            ($c[] | "netbird_exit_node_bytes_total{family=\"\(.f)\",direction=\"\(.d)\"} \(.bytes)"),
            "# HELP netbird_exit_node_packets_total Packets forwarded between nb-mesh and the public interface.",
            "# TYPE netbird_exit_node_packets_total counter",
            ($c[] | "netbird_exit_node_packets_total{family=\"\(.f)\",direction=\"\(.d)\"} \(.packets)")
        ' > "$out.tmp"
        chmod 0644 "$out.tmp"
        mv "$out.tmp" "$out"
      '';
    };

    systemd.timers.netbird-exit-node-metrics = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "30s";
      };
    };
  };
}
