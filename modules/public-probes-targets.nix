# What every public endpoint must answer, and from where it is probed - the
# data behind modules/public-probes.nix (the probes on zummi and grammi) and
# the PublicProbeMissing series in hosts/grammi/alerting.nix. admin/nixlab#169.
#
# The endpoints come from inventory.json: every endpoint with exposure
# "public" of a service that runs on a lab host. A new public endpoint
# without an entry in `checks` below stops the evaluation, so nothing goes
# public unprobed. Services without hosts (public-docs on GitHub Pages) are
# not the lab's to watch.
#
# Each check is probed twice, over IPv4 and over IPv6, without falling back
# from one to the other: a broken AAAA record or IPv6 route shows as its own
# failure instead of hiding behind a working IPv4.
{ lib, inventory }:
let
  # path: what to request. status: the one status code that counts as
  # success. body: regular expressions the body must all match (Go RE2,
  # multi-line), given the endpoint's fqdn.
  #
  # A 401 or 403 is the expected answer where the service itself answers it:
  # it proves the request reached the service and not an error page of nginx
  # in front of it.
  checks = {
    pocket-id = [
      {
        path = "/.well-known/openid-configuration";
        status = 200;
        body = fqdn: [ ''"issuer": *"https://${lib.escapeRegex fqdn}"'' ];
      }
    ];
    garage = [
      {
        path = "/";
        status = 403;
        body = _: [ "<Code>AccessDenied</Code>" ];
      }
    ];
    opencloud = [
      {
        path = "/status.php";
        status = 200;
        body = _: [ ''"installed": *true'' ''"maintenance": *false'' ];
      }
    ];
    floccus-dav = [
      {
        path = "/";
        status = 401;
        body = _: [ ];
      }
    ];
    # /healthz covers Chhoto's database on its health port, / its main port.
    # systemd cannot see either failure: Chhoto hung with its unit active and
    # nginx answered 502 to everything (nixlab#237).
    shortener = [
      {
        path = "/healthz";
        status = 200;
        body = _: [ "^healthy\\s*$" ];
      }
      {
        path = "/";
        status = 200;
        body = _: [ ];
      }
    ];
  };

  # From another provider than the service: zummi (IONOS, Berlin) probes
  # everything on aldrin (Realtox, Düsseldorf), and grammi, at Realtox too,
  # probes what runs on zummi.
  proberFor = service: if lib.elem "zummi" service.hosts then "grammi" else "zummi";

  publicEndpoints = lib.concatLists (
    lib.mapAttrsToList (
      id: s:
      map (e: {
        inherit id;
        service = s;
        inherit (e) fqdn;
      }) (lib.filter (e: e.exposure == "public" && e ? fqdn) (s.endpoints or [ ]))
    ) (lib.filterAttrs (_: s: (s.hosts or null) != null && s.hosts != [ ]) inventory.services)
  );

  probesOf =
    ep:
    let
      list =
        checks.${ep.id}
          or (throw "modules/public-probes-targets.nix: ${ep.fqdn} (service ${ep.id}) is public in inventory.json but has no entry in `checks`");
    in
    lib.concatLists (
      lib.imap0 (
        i: c:
        map (family: {
          inherit (ep) id fqdn;
          inherit (c) path status;
          inherit family;
          body = c.body ep.fqdn;
          prober = proberFor ep.service;
          url = "https://${ep.fqdn}${c.path}";
          # The blackbox module this probe uses, unique per check and family.
          module = "${ep.id}-${toString i}-ip${family}";
        }) [ "4" "6" ]
      ) list
    );
in
{
  probes = lib.concatMap probesOf publicEndpoints;
}
