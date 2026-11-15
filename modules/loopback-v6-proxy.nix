# Reusable module: answer on [::1] for a service that only listens on
# 127.0.0.1, so a loopback-only endpoint is dual stack like the rest of the lab.
#
# Why a proxy: most exporters (prometheus_client, node-style Go exporters)
# take exactly one listen address, and the family follows from it. Binding
# "::" would cover both families but also the mesh interface, which is
# trusted (modules/netbird.nix). systemd owns the
# [::1] socket and starts systemd-socket-proxyd on the first connection, so
# an idle endpoint costs nothing and the service itself stays untouched.
#
# Scrapers keep using 127.0.0.1 (modules/metrics-shipping.nix): one scrape per
# exporter, otherwise every series would arrive twice.
{ config, lib, ... }:
let
  cfg = config.services.loopbackV6Proxy;
  proxyd = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd";
in
{
  options.services.loopbackV6Proxy = lib.mkOption {
    default = { };
    example = { restic-exporter.port = 9753; };
    description = ''
      One proxy per name: [::1]:<port> forwards to 127.0.0.1:<port>. The name
      only labels the units (loopback-v6-proxy-<name>.{socket,service}).
    '';
    type = lib.types.attrsOf (lib.types.submodule {
      options.port = lib.mkOption {
        type = lib.types.port;
        description = "Port the service listens on at 127.0.0.1, and the one answered on [::1].";
      };
    });
  };

  config = lib.mkIf (cfg != { }) {
    systemd.sockets = lib.mapAttrs' (name: p: lib.nameValuePair "loopback-v6-proxy-${name}" {
      description = "[::1]:${toString p.port} for ${name}";
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "[::1]:${toString p.port}" ];
      # Without this a v6 socket on [::1] is v6-only anyway; stated for the reader.
      socketConfig.BindIPv6Only = "ipv6-only";
    }) cfg;

    systemd.services = lib.mapAttrs' (name: p: lib.nameValuePair "loopback-v6-proxy-${name}" {
      description = "Forward [::1]:${toString p.port} to 127.0.0.1:${toString p.port} (${name})";
      serviceConfig = {
        ExecStart = "${proxyd} 127.0.0.1:${toString p.port}";
        DynamicUser = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        # Loopback only, in both directions.
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
      };
    }) cfg;
  };
}
