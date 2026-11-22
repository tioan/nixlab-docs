# Reusable module: the ACME clients of a host, their accounts, and a check
# that the CAA records still let each account renew (admin/nixlab#411).
#
# Every public name is pinned by CAA (RFC 8657 accounturi +
# validationmethods, records in the DNSControl repo) to the Let's Encrypt
# account and method of the client that gets its certificate. The price:
# a new account - a lost state directory, a changed email in lego's account
# path - can no longer renew until the record is changed. Two things here
# keep that from happening quietly:
#
#   backupPaths  where each client keeps its account. Hosts add the list to
#                their restic paths, so a restored host comes back with the
#                same account instead of registering a new one.
#   the check    a textfile writer (modules/textfile-metrics-lab.nix) that
#                resolves the CAA records applying to each name the way
#                Let's Encrypt does (follow the CNAME, climb towards the
#                apex) and compares them with the account in use. Alerts:
#                hosts/grammi/alerting/security.nix (AcmeCaa*).
#
# A client says where its account is in one of three ways:
#   accountJson  a JSON file holding the URI (lego, Caddy), by glob - the
#                lego directory name contains a hash of email, key type and
#                server that the NixOS module does not expose
#   accountKey   the account key itself (NetBird proxy's autocert stores no
#                URI); the check derives the URI from Let's Encrypt with a
#                `newAccount` + `onlyReturnExisting` request signed with it
#   accountUri   the URI as a string, for an account on a device the lab
#                does not manage (Home Assistant's add-on)
#
# Root-only sources (account JSON, a 0700 state directory) are read by a
# root ExecStartPre step that writes only the URI and the names into the
# unit's runtime directory; a key reaches the sandboxed check as a
# credential, never through the filesystem.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.acmeCaa;
  unit = "acme-caa-check";
  runDir = "/run/${unit}";
  credDir = "/run/credentials/${unit}.service";
  pkg = pkgs.nixlab.acme-caa-check;

  hasRootSources = c: c.accountJson != null || c.namesDir != null;

  # For the root step: only what it resolves.
  extractConfig = pkgs.writeText "${unit}-extract.json" (
    builtins.toJSON {
      clients = lib.mapAttrs (
        _: c:
        lib.filterAttrs (_: v: v != null) {
          inherit (c) method accountJson namesDir;
        }
      ) (lib.filterAttrs (_: hasRootSources) cfg.clients);
    }
  );

  # For the sandboxed check: plain files from the root step, keys as
  # credentials.
  checkConfig = pkgs.writeText "${unit}.json" (
    builtins.toJSON {
      inherit (cfg) resolver directory;
      prefix = config.services.textfileMetrics.metricPrefix;
      clients = lib.mapAttrs (
        name: c:
        lib.filterAttrs (_: v: v != null) {
          inherit (c) method names accountUri;
          accountUriFile = if c.accountJson != null then "${runDir}/${name}.uri" else null;
          namesFile = if c.namesDir != null then "${runDir}/${name}.names" else null;
          accountKey = if c.accountKey != null then "${credDir}/${name}-key" else null;
        }
      ) cfg.clients;
    }
  );

  keyClients = lib.filterAttrs (_: c: c.accountKey != null) cfg.clients;
in
{
  # The options (clients, backupPaths, resolver, directory), shared with
  # modules/darwin/acme-caa.nix.
  imports = [ ./acme-caa-options.nix ];

  config = lib.mkIf (cfg.clients != { }) {
    services.textfileMetrics.writers.${unit} = {
      description = "CAA records against the ACME accounts in use";
      script = "${lib.getExe pkg} check ${checkConfig}";
      # DNS to the resolver, HTTPS to Let's Encrypt for a key-only account.
      hardening.network = "any";
      # Hourly: an account that changed is noticed long before its
      # certificates are due (renewal 30 days ahead). One newAccount
      # lookup per key and hour is far below Let's Encrypt's limits.
      timer = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1h";
      };
      unit.serviceConfig = {
        RuntimeDirectory = unit;
        # "-": a source that cannot be read leaves its file out, and the
        # check reports the client as unknown instead of failing the run.
        ExecStartPre = lib.optional (lib.any hasRootSources (lib.attrValues cfg.clients)) "-+${lib.getExe pkg} extract ${extractConfig} ${runDir}";
        LoadCredential = lib.mapAttrsToList (name: c: "${name}-key:${c.accountKey}") keyClients;
      };
    };
  };
}
