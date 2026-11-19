# Lab-wide constants that several modules and hosts need, declared once.
# The values are set from inventory.json by profiles/common.nix and
# profiles/pulled.nix;
# this file only declares them, so the modules that read them stay free of
# lab values.
#
# The mesh ranges and the OIDC issuer (admin/nixlab#319) and the S3 endpoint
# of the restic jobs (modules/restic-garage.nix, #318).
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

  options.lab.oidc.issuer = lib.mkOption {
    type = lib.types.str;
    example = "https://auth.example.org";
    description = ''
      Issuer URL of the lab's OIDC provider (Pocket ID), without a trailing
      slash. Discovery, authorize and token endpoints hang off it.
    '';
  };

  options.lab.s3.endpoint = lib.mkOption {
    type = lib.types.str;
    example = "https://s3.example.org";
    description = "URL of the lab's S3 store (Garage), without a bucket.";
  };
}
