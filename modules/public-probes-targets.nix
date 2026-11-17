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
#
# Port 80 (admin/nixlab#234): it does nothing but redirect to https, for
# every name. Probed for every web endpoint the lab serves itself - public
# and mesh ones on their own host, proxy ones on the reverse proxy's host -
# by name, and once per host and kind of address also with `Host:
# localhost` and an unknown name, the two cases that once got a page
# instead (modules/web-baseline.nix has the default servers). Mesh names
# are probed from grammi, the rest as above. The appliances' own web
# interfaces (LuCI, cameras) are probed from ursalia, see applianceProbes.
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

  # --- Port 80 ----------------------------------------------------------------
  services = inventory.services;
  hostsOf = id: if services ? ${id} then services.${id}.hosts or null else null;

  # Where a request for the endpoint lands: its own hosts, or for a proxied
  # one the hosts of what it goes through. Endpoints with a port of their
  # own are not web on 80/443; ones that land outside the lab (a provider's
  # proxy) are not the lab's to probe.
  webEndpoints = lib.concatLists (
    lib.mapAttrsToList (
      id: s:
      map (e: {
        inherit id;
        inherit (e) fqdn exposure;
        lands = if e.exposure == "proxy" then hostsOf e.via else s.hosts or null;
      }) (lib.filter (e: (e.fqdn or null) != null && (e.port or null) == null && lib.elem e.exposure [ "public" "mesh" "proxy" ]) (s.endpoints or [ ]))
    ) services
  );
  web = lib.filter (ep: ep.lands != null && ep.lands != [ ]) webEndpoints;

  redirectProber = ep:
    if ep.exposure == "mesh" then (if lib.elem "grammi" ep.lands then "zummi" else "grammi")
    else proberFor { hosts = ep.lands; };

  # One endpoint per host and kind of address carries the Host-header
  # variants: a host's public and mesh addresses can have different default
  # servers (aldrin binds its public vhosts to the public address).
  key = ep: "${lib.concatStringsSep "+" ep.lands} ${if ep.exposure == "mesh" then "mesh" else "public"}";
  representatives = lib.attrValues (
    lib.foldl' (acc: ep: if acc ? ${key ep} then acc else acc // { ${key ep} = ep; }) { } (
      lib.sort (a: b: a.fqdn < b.fqdn) web
    )
  );

  redirectVariants = [
    { name = "name"; host = null; }
    { name = "localhost"; host = "localhost"; }
    { name = "unknown"; host = "nonexistent.invalid"; }
  ];

  redirectProbesOf =
    ep: variants:
    lib.concatMap (
      v:
      map (family: {
        inherit (ep) id fqdn;
        path = "/ (port 80${lib.optionalString (v.host != null) ", Host: ${v.host}"})";
        status = [ 301 308 ];
        inherit family;
        body = [ ];
        hostHeader = v.host;
        location = "^https://";
        prober = redirectProber ep;
        url = "http://${ep.fqdn}/";
        module = "${ep.id}-${lib.replaceStrings [ "." ] [ "-" ] ep.fqdn}-http-${v.name}-ip${family}";
      }) [ "4" "6" ]
    ) variants;

  redirectProbes =
    lib.concatMap (ep: redirectProbesOf ep (lib.take 1 redirectVariants)) web
    ++ lib.concatMap (ep: redirectProbesOf ep (lib.drop 1 redirectVariants)) representatives;

  # --- Appliances (nixlab#372) ------------------------------------------------
  # Home devices with `web.http` "redirect" in inventory.json: port 80 by
  # address, IPv4 only, from ursalia - the one prober inside the home
  # network; gruffi lets it reach port 80 of exactly these
  # (openwrt/web-probe-targets.nix feeds both). A device's own firmware picks
  # the redirect code (Reolink answers 302, NanoKVM 307), so any
  # redirect counts as long as it points at https.
  applianceProbes = map (t: {
    id = t.name;
    fqdn = t.name;
    path = "/ (port 80)";
    status = [ 301 302 307 308 ];
    family = "4";
    body = [ ];
    hostHeader = null;
    location = "^https://";
    prober = "ursalia";
    url = "http://${t.address}/";
    module = "appliance-${t.name}-http-ip4";
  }) (import ../openwrt/web-probe-targets.nix { inherit lib; inherit (inventory) hosts; });

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
          inherit (c) path;
          status = [ c.status ];
          inherit family;
          body = c.body ep.fqdn;
          hostHeader = null;
          location = null;
          prober = proberFor ep.service;
          url = "https://${ep.fqdn}${c.path}";
          # The blackbox module this probe uses, unique per check and family.
          module = "${ep.id}-${toString i}-ip${family}";
        }) [ "4" "6" ]
      ) list
    );
in
{
  probes = lib.concatMap probesOf publicEndpoints ++ redirectProbes ++ applianceProbes;
}
