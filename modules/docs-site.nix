# The private docs site (flake package docs-site, built from docs/) on the
# NetBird mesh under doku.homelab.example.
#
# Who may read it is the allow list (option allow): the whole mesh by
# default, in this lab only the admins' devices - the docs carry every
# internal address and how the lab is run, which is more than everyone with
# a device in the mesh needs to see. Enforced here in nginx because the
# NetBird policies cannot tell this site apart from the other services on
# the same hosts (terraform/netbird/admin-peers.tf has the reasoning).
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

    allow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.0.2.0/24" ];
      description = ''
        Addresses or networks nginx serves the site to; everyone else gets
        403. Default: the whole mesh. The lab sets the admins' devices from
        terraform/netbird/admin-peers.json (flake.nix) - see the header of
        terraform/netbird/admin-peers.tf for why it is an address list.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # An empty list would only leave "deny all" - nobody could read the
    # docs, and nothing else would say why.
    assertions = [
      {
        assertion = cfg.allow != [ ];
        message = "services.docsSite.allow is empty - nobody could read the docs site";
      }
    ];

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      # Wildcard instead of the host's defaults: the mesh address is
      # NetBird's to assign and nb-mesh may come up after nginx, and a host
      # may bind its public vhosts to its public addresses only (aldrin).
      # The allow list (option allow) is what keeps it mesh-only, or
      # admins-only. [::] already, for when the mesh gets IPv6 (then the v6
      # addresses go into the allow list as well).
      virtualHosts.${cfg.fqdn} = {
        listenAddresses = [ "0.0.0.0" "[::]" ];
        enableACME = true;
        acmeRoot = null;
        forceSSL = true;
        root = cfg.package;
        extraConfig = lib.concatMapStrings (a: "allow ${a};\n") cfg.allow + "deny all;\n";
      };
    };
  };
}
