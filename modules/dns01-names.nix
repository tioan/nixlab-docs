# Names a host answers ACME DNS-01 challenges for outside of
# security.acme.certs: a Caddy of its own (nix-darwin has no security.acme),
# or a DNS-01 proxy that writes challenges for other clients with this
# host's DNS provider token.
#
# Only a declaration - nothing here acts on it. Whatever scopes the host's
# token reads it together with security.acme.certs; in this lab that is
# lib.dns01Names in flake.nix, which feeds terraform/desec-tokens.
# Plain option module, so it works on NixOS and nix-darwin alike.
{ lib, ... }:
{
  options.dns01.extraNames = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "app.example.org" ];
    description = ''
      Fully qualified names whose `_acme-challenge` TXT record this host
      writes besides the names of its `security.acme.certs`. Its DNS
      provider token needs write access to exactly these records.
    '';
  };
}
