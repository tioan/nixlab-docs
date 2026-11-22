# ACME defaults for every host that serves TLS.
#
# DNS-01 against deSEC rather than HTTP-01: it needs no inbound port 80 for the
# challenge and can issue for names that never resolve publicly.
{ config, lib, ... }:
let
  desecFile = ../hosts + "/${config.networking.hostName}/desec.yaml";
  acmeDefaults = config.security.acme.defaults;
  certs = lib.attrValues config.security.acme.certs;
in
{
  # dns01.extraNames, for names this host answers challenges for outside of
  # security.acme.certs (grammi's dns01proxy). Together with the certificates
  # it decides what this host's token may write - see lib.dns01Names in
  # flake.nix and terraform/desec-tokens.
  # acme-caa.nix: the account's backup path and the CAA check, see
  # services.acmeCaa.clients.lego below.
  imports = [
    ./dns01-names.nix
    ./acme-caa.nix
  ];

  # The secret holds the bare token and nothing else.
  #
  # Token scoping (allowed_subnets, write access only to the
  # _acme-challenge TXT records of this host's certificate names instead of
  # deSEC's default full-account access) is managed declaratively via
  # terraform/desec-tokens/ - see that module's README for how a new value
  # gets rotated in and how a new name gets granted. This file just
  # consumes whatever value sops.secrets."desec_token" holds; it doesn't
  # care whether that token is scoped or not.
  #
  # It used to differ per host under the same name: aldrin stored the plain
  # value and wrapped it in a template, zummi stored the literal string
  # "DESEC_TOKEN=<token>" and pointed environmentFile straight at the file.
  # Both worked, which is why it went unnoticed - but a secret should be a
  # value, not half a line of shell, and the two shapes made a shared module
  # impossible. Normalised to the plain value on both hosts.
  #
  # Where it comes from: hosts/<host>/desec.yaml, written on the workstation
  # by `just desec-key <host>` straight from Tofu state. Hosts that have not
  # been moved over yet still read it from their secrets.yaml (the old,
  # hand-copied way); drop the desec_token key there once desec.yaml exists.
  sops.secrets."desec_token" = lib.optionalAttrs (builtins.pathExists desecFile) {
    sopsFile = desecFile;
  };

  # lego reads the credential from the DESEC_TOKEN environment variable, so it
  # needs a KEY=value file. That shape belongs here rather than inside the
  # encrypted secret.
  sops.templates."desec-env".content = ''
    DESEC_TOKEN=${config.sops.placeholder."desec_token"}
  '';

  security.acme = {
    acceptTerms = true;
    defaults = {
      # Part of lego's account directory name (with key type and server):
      # a different email - or a lost /var/lib/acme - registers a new Let's
      # Encrypt account. Each host's account is pinned by CAA accounturi
      # (DNSControl), so update that record first, or the host's names stop
      # renewing (admin/nixlab#68, #411).
      #
      # Every host's account is pinned that way since admin/nixlab#411; the
      # check in modules/acme-caa.nix (alert AcmeCaaRefusesAccount) says so
      # within the hour if account and record drift apart.
      email = "admin@homelab.example";
      dnsProvider = "desec";
      environmentFile = config.sops.templates."desec-env".path;

      # Force lego's DNS-01 propagation check to query a fixed resolver
      # directly instead of going through the local systemd-resolved chain
      # (DoT to Freifunk, both v4 and v6 - see modules/networking.nix). Hit a
      # known lego/deSEC bug without this: the propagation check picks the
      # wrong network stack and reports NXDOMAIN for a record that
      # demonstrably exists (`dig ... @ns1.desec.io` shows it immediately).
      # Fixed upstream in lego 5.0 (go-acme/lego#1406 / #2832), but nixpkgs
      # currently ships 4.35.2 - this sidesteps the bug rather than waiting
      # for the package to catch up. Revisit once nixpkgs's lego is >= 5.0.
      dnsResolver = "1.1.1.1:53";

      # deSEC takes a while to publish a new RRset on all of its anycast
      # frontends, and Let's Encrypt validates from several vantage points
      # at once - a propagation check that sees the record at one resolver
      # says little about the others. Skip the check, just wait. Surfaced
      # 2026-09-29 with grist.homelab.example: lego's check against 1.1.1.1
      # passed, Let's Encrypt still got NXDOMAIN for the TXT record.
      # Costs every order/renewal a flat 2 minutes.
      extraLegoFlags = [
        "--dns.propagation-wait"
        "120s"
      ];
    };
  };

  # DNS-01 against deSEC sometimes fails on the first order for a brand-new
  # name: Let's Encrypt gets NXDOMAIN for the TXT record despite the 120s
  # wait (grist 2026-09-29, mealie 2026-10-15 - both succeeded on a plain
  # second run). deSEC's anycast frontends pick up a new RRset at different
  # speeds - during mealie's successful retry the record never showed up at
  # ns1/ns2 as seen from Germany, yet Let's Encrypt found it - so a longer
  # fixed wait is guesswork; retrying is not. Without this a failed order
  # just sits on the minica placeholder until the renew timer fires, up to
  # a day later.
  #
  # The NixOS acme module already sets RestartSec = 15 min on these units
  # (to stay within Let's Encrypt's 5 failed validations per hour) but no
  # Restart=, so that delay never comes into play. Only Restart= is added
  # here; setting RestartSec again conflicts with the module's definition.
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "acme-order-renew-${name}" {
      serviceConfig.Restart = "on-failure";
      # At most 3 starts per hour (first try + 2 retries 15 min apart), then
      # give up until the timer.
      unitConfig = {
        StartLimitIntervalSec = "1h";
        StartLimitBurst = 3;
      };
    }
  ) config.security.acme.certs;

  # lego's account and names for the CAA check and the backup
  # (modules/acme-caa.nix). The account directory is
  # accounts/<hash of email, key type and server>/<server host>/<email>/;
  # the NixOS module does not expose the hash, hence the glob.
  services.acmeCaa.clients.lego = lib.mkIf (certs != [ ]) {
    method = if acmeDefaults.dnsProvider != null then "dns-01" else "http-01";
    names = lib.unique (lib.concatMap (c: [ c.domain ] ++ c.extraDomainNames) certs);
    accountJson.glob = "/var/lib/acme/.lego/accounts/*/${lib.elemAt (lib.splitString "/" acmeDefaults.server) 2}/${acmeDefaults.email}/account.json";
    # Key and account.json. Only the account: certificates are simply
    # fetched again. Restore as root so owner and mode come back with it.
    backupPaths = [ "/var/lib/acme/.lego/accounts" ];
  };
}
