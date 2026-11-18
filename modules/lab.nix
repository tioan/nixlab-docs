# Lab-wide constants that several modules and hosts need, declared once.
# The values are set from inventory.json by profiles/services.nix;
# this file only declares them, so the modules that read them stay free of
# lab values.
#
# Only the mesh ranges for now (admin/nixlab#319). Their other literal uses
# (sshd's Match, CrowdSec's whitelist, Samba, Traefik's trustedIPs, ...)
# move over one by one - the list is in that issue.
{ config, lib, ... }:
let
  cfg = config.lab;
in
{
  options.lab.mesh = {
    ipv4 = lib.mkOption {
      type = lib.types.str;
      example = "100.64.0.0/10";
      description = "IPv4 range of the mesh overlay every peer gets its address from.";
    };

    ipv6 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "fd12:3456:789a:1::/64";
      description = "IPv6 range of the mesh overlay; null when it has none.";
    };

    networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = [ cfg.mesh.ipv4 ] ++ lib.optional (cfg.mesh.ipv6 != null) cfg.mesh.ipv6;
      defaultText = lib.literalExpression "[ config.lab.mesh.ipv4 config.lab.mesh.ipv6 ]";
      description = "Both ranges as a list, for allow lists.";
    };
  };
}
