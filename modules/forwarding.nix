# IP forwarding with a default-drop filter, for hosts that route between
# their interfaces: VPN exit nodes, routing peers into a LAN, hosts with
# containers on a bridge.
#
# Why a filter at all: overlay clients (NetBird, Tailscale) put their own
# chains on the forward hook, but those only judge traffic that comes *out*
# of the overlay. Traffic from any other interface into the overlay passes
# them untouched - and NetBird even masquerades it as the routing host
# (its 0x1bd22 mark), so an on-link neighbour that routes the overlay's
# range via this host reaches the overlay peers with the host's identity.
# Shown on four hosts with a network-namespace neighbour (admin/nixlab#311).
#
# What this module does:
#  - turns forwarding on (IPv4, optionally IPv6),
#  - switches on the NixOS firewall's forward chain (policy drop; replies
#    and port forwards (ct status dnat) pass on their own) and accepts new
#    connections only for the `allow` pairs,
#  - a guard chain of its own that drops new connections into an overlay
#    interface from anywhere else, unless an `allow` pair names that way.
#    Needed because the firewall's forward-allow chain accepts all ICMPv6
#    before any extraForwardRules run - without the guard, ping6 into the
#    overlay still passes.
#
# A drop in any base chain is final, so the guard cannot let through what
# the firewall's chain drops, and the other way round.
{ config, lib, ... }:
let
  cfg = config.networking.forwardFilter;

  quote = s: ''"${s}"'';
  nftSet = l: "{ ${lib.concatMapStringsSep ", " quote l} }";

  match = a:
    "iifname ${quote a.from}" + lib.optionalString (a.to != null) " oifname ${quote a.to}";

  # `allow` pairs that open connections into an overlay from outside it:
  # let through by the guard.
  intoOverlay = a:
    !(lib.elem a.from cfg.overlayInterfaces)
    && (a.to == null || lib.elem a.to cfg.overlayInterfaces);
in
{
  options.networking.forwardFilter = {
    enable = lib.mkEnableOption "IP forwarding, filtered: new connections only along the allowed interface pairs";

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also forward IPv6 (net.ipv6.conf.all.forwarding). The filter covers both families either way.";
    };

    allow = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          from = lib.mkOption {
            type = lib.types.str;
            example = "wg0";
            description = "Interface the connection comes in on.";
          };
          to = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "eth0";
            description = "Interface it goes out on; null for any.";
          };
        };
      });
      default = [ ];
      example = [
        { from = "wg0"; to = "eth0"; }
        { from = "br-containers"; }
      ];
      description = ''
        Interface pairs along which new connections are forwarded. Replies
        (established/related) and destination-NATed port forwards need no
        entry. Whatever filtering the overlay client does on top stays in
        force.
      '';
    };

    overlayInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "wg0" "tailscale0" ];
      description = ''
        Overlay interfaces (VPN meshes). New connections into them from any
        other interface are dropped by a guard chain unless an `allow` pair
        names that way, ICMPv6 included.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.networking.firewall.enable && config.networking.nftables.enable;
      message = "networking.forwardFilter needs the NixOS firewall on its nftables backend.";
    }];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    } // lib.optionalAttrs cfg.ipv6 {
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.firewall.filterForward = true;
    networking.firewall.extraForwardRules =
      lib.concatMapStringsSep "\n" (a: "${match a} accept") cfg.allow;

    # Counters on the drop: `nft list table inet forward-guard` shows what
    # tried to get in.
    networking.nftables.tables.forward-guard = lib.mkIf (cfg.overlayInterfaces != [ ]) {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter - 2; policy accept;
          ${lib.concatStringsSep "\n          " (
            map (a: "ct state new ${match a} accept") (lib.filter intoOverlay cfg.allow)
            ++ [ "ct state new iifname != ${nftSet cfg.overlayInterfaces} oifname ${nftSet cfg.overlayInterfaces} counter drop" ]
          )}
        }
      '';
    };
  };
}
