# Options of the CAA check (admin/nixlab#411): a host's ACME clients, where
# each keeps its account and which names it gets. Shared by the NixOS side
# (modules/acme-caa.nix, a sandboxed systemd writer) and the Mac side
# (modules/darwin/acme-caa.nix, a launchd job); see modules/acme-caa.nix for
# what the check does.
{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.services.acmeCaa;

  clientType = types.submodule {
    options = {
      method = mkOption {
        type = types.enum [
          "dns-01"
          "http-01"
          "tls-alpn-01"
        ];
        description = "The validation method the client uses; the CAA record must allow exactly this one.";
      };
      names = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Names the client gets certificates for.";
      };
      namesDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          An autocert cache directory whose entries are the names (the
          NetBird proxy's names come from NetBird, not from Nix). The cache
          keeps names of services that are gone; with tls-alpn-01/http-01
          the check skips a name without a public address, which could not
          be issued that way anyway.
        '';
      };
      accountJson = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              glob = mkOption {
                type = types.str;
                description = "Shell glob that must match exactly one file.";
              };
              field = mkOption {
                type = types.str;
                default = "registration.uri";
                description = "Dotted path of the URI in the JSON (lego: registration.uri, Caddy: location).";
              };
            };
          }
        );
        default = null;
        description = "The account file holding the URI.";
      };
      accountKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "PEM account key; the URI is derived from Let's Encrypt.";
      };
      accountUri = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The account URI itself, for an account kept outside the lab's hosts.";
      };
      backupPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "What holds the account (real paths, not /var/lib/<x> symlinks of DynamicUser services).";
      };
    };
  };

in
{
  options.services.acmeCaa = {
    clients = mkOption {
      type = types.attrsOf clientType;
      default = { };
      description = "This host's ACME clients, keyed by a short name (the `client` label).";
    };

    backupPaths = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = lib.unique (lib.concatMap (c: c.backupPaths) (lib.attrValues cfg.clients));
      description = "Every client's backupPaths, for the host's restic job.";
    };

    resolver = mkOption {
      type = types.str;
      # The resolver lego's propagation check uses (modules/acme.nix), so
      # both look at the same view of the zone.
      default =
        let
          # nix-darwin has no security.acme.
          r = lib.attrByPath [
            "security"
            "acme"
            "defaults"
            "dnsResolver"
          ] null config;
        in
        if r == null then "1.1.1.1" else lib.head (lib.splitString ":" r);
      defaultText = lib.literalExpression "the address of security.acme.defaults.dnsResolver, or 1.1.1.1";
      description = "Recursive resolver (IP) for the CAA lookups.";
    };

    directory = mkOption {
      type = types.str;
      default = "https://acme-v02.api.letsencrypt.org/directory";
      description = "ACME directory the accounts live in.";
    };
  };

  config = lib.mkIf (cfg.clients != { }) {
    assertions = lib.mapAttrsToList (name: c: {
      assertion =
        lib.length (
          lib.filter (x: x != null) [
            c.accountJson
            c.accountKey
            c.accountUri
          ]
        ) == 1;
      message = "services.acmeCaa.clients.${name}: set exactly one of accountJson, accountKey, accountUri.";
    }) cfg.clients;

  };
}
