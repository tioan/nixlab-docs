# The private docs site (flake package docs-site, built from docs/) on the
# NetBird mesh under doku.homelab.example.
#
# Mesh-only like the other admin names: the name is a NetBird DNS zone with
# one A record per host that imports this module
# (terraform/netbird/mesh-services.tf), public DNS has no record, and the
# vhost admits only mesh addresses. Certificate via DNS-01 (modules/acme.nix)
# - each host gets its own; hosts whose deSEC token is limited to named
# records need "doku" in their acme_names (terraform/desec-tokens/main.tf).
#
# On more than one host on purpose: the docs are what you read when
# something is broken, so they must not depend on a single machine - least
# of all on grammi, which runs the NetBird server and the reverse proxy.
# Every host builds the site itself from its /etc/nixos checkout, so all of
# them serve the same commit after a deploy or the nightly upgrade.
{ config, lib, ... }:

let
  cfg = config.services.docsSite;
in
{
  options.services.docsSite = {
    enable = lib.mkEnableOption "the private docs site on the mesh";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The built site - the flake's docs-site package.";
    };

    fqdn = lib.mkOption {
      type = lib.types.str;
      default = "doku.homelab.example";
      description = "Name the site is served under (a mesh-only NetBird DNS zone).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      # Wildcard instead of the host's defaults: the mesh address is
      # NetBird's to assign and nb-mesh may come up after nginx, and a host
      # may bind its public vhosts to its public addresses only (aldrin).
      # The allow list below is what keeps it mesh-only. [::] already, for
      # when the mesh gets IPv6 (then its prefix goes into the allow list).
      virtualHosts.${cfg.fqdn} = {
        listenAddresses = [ "0.0.0.0" "[::]" ];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        root = cfg.package;
        extraConfig = ''
          allow 192.0.2.0/24;
          deny all;
        '';
      };
    };
  };
}
