# What every web front of the lab does the same way: security headers, a
# default server for names nobody serves, and the shape of a vhost.
# admin/nixlab#308, #12, #234 and #319; docs: docs/site/*/explanation/
# web-baseline.md.
#
# Security headers (option lab.web.securityHeaders). The values are kept
# once here; nginx renders them below, Traefik on grammi reads the same
# attribute set (hosts/grammi/netbird.nix).
#  - nginx sets them at the http level, so every server and location
#    inherits them - the vhosts of this module, the docs site, the proxy
#    listeners and whatever comes next.
#  - A header the application sends itself wins: each one goes through a map
#    on $upstream_http_<name>, and an empty value makes add_header skip it.
#    OpenCloud's, paperless' and HealthLog's own (stricter) values stay as
#    they are, without a second copy next to them.
#  - `always`, so the 503 maintenance page and nginx's own errors carry them
#    too.
#  - nginx's add_header inheritance: a level that has an add_header of its
#    own inherits none from above. Such a location has to repeat them
#    (lab.web.nginx.headers); evaluation fails otherwise.
#
# Default servers (#12, #234 decision 4a). A request for a name no vhost
# serves used to land in the first vhost on that address - pocket-id on
# zummi, OpenCloud on aldrin, with a 200. Now:
#  - 443: the TLS handshake is refused for an unknown or missing SNI
#    (ssl_reject_handshake, no certificate needed); a known SNI with an
#    unknown Host header is closed without an answer (444).
#  - 80: every Host is redirected to https://$host - port 80 does nothing
#    else, whatever the name. What #234's port-80 probes check.
#
# The vhost helper (option lab.vhosts) for the recurring shape: certificate
# by DNS-01, forceSSL, proxy to a loopback port, websockets, mesh-only
# allow/deny, maintenance and WAF registration. Or, with proxyListener, the
# plain-HTTP listener a NetBird reverse proxy service points at. Anything
# else of the vhost goes into `nginx`, merged into services.nginx.
# virtualHosts as it is.
{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.lab.web;
  nginx = config.services.nginx;

  # --- Headers ---------------------------------------------------------------
  varOf = name: "nixlab_hdr_" + lib.replaceStrings [ "-" ] [ "_" ] (lib.toLower name);
  upstreamVar = name: "upstream_http_" + lib.replaceStrings [ "-" ] [ "_" ] (lib.toLower name);

  headerMaps = lib.concatStrings (
    lib.mapAttrsToList (name: value: ''
      map ''$${upstreamVar name} ''$${varOf name} {
        "" ${builtins.toJSON value};
        default "";
      }
    '') cfg.securityHeaders
  );
  addHeaders = lib.concatStrings (
    lib.mapAttrsToList (name: _: "add_header ${name} \$${varOf name} always;\n") cfg.securityHeaders
  );
  # Server and location bodies with an add_header of their own that do not
  # repeat the shared ones. Repeated as lines, not as an include: gixy (the
  # build-time check of nixpkgs' nginx module) does not follow includes and
  # would report the dropped headers anyway.
  ownHeaders = s: s != null && lib.hasInfix "add_header" s && !lib.hasInfix addHeaders s;
  headerLeaks = lib.concatLists (
    lib.mapAttrsToList (
      vn: v:
      lib.optional (ownHeaders v.extraConfig) "services.nginx.virtualHosts.\"${vn}\".extraConfig"
      ++ lib.concatLists (
        lib.mapAttrsToList (
          ln: l:
          lib.optional (ownHeaders l.extraConfig) "services.nginx.virtualHosts.\"${vn}\".locations.\"${ln}\".extraConfig"
        ) v.locations
      )
    ) nginx.virtualHosts
  );

  # --- Default servers -------------------------------------------------------
  defaultNames = [
    "_default-http"
    "_default-https"
  ];
  # nginx reads [::] and [::0] as the same address; one spelling, or the
  # default server would be declared twice.
  normalise = a: if a == "[::0]" then "[::]" else a;
  wildcard = [ "0.0.0.0" ] ++ lib.optional config.networking.enableIPv6 "[::]";

  # Every address another vhost listens on with port 80 or 443 - each needs
  # its own default server, a wildcard one does not cover a specific address.
  webAddresses = lib.unique (
    lib.concatLists (
      lib.mapAttrsToList (
        _vn: v:
        map normalise (
          if v.listen != [ ] then
            map (l: l.addr) (
              lib.filter (
                l:
                lib.elem (l.port or null) [
                  80
                  443
                  null
                ]
              ) v.listen
            )
          else if v.listenAddresses != [ ] then
            v.listenAddresses
          else
            nginx.defaultListenAddresses
        )
      ) (lib.removeAttrs nginx.virtualHosts (defaultNames ++ [ "localhost" ]))
    )
  );
  # Only addresses some vhost really listens on. A default server on a
  # specific address nobody else binds takes that address over: nginx then
  # matches connections to it against the servers bound to it alone, and a
  # wildcard vhost is no longer among them. zummi's public address did that
  # to auth.homelab.example on 2026-11-15 - every handshake from the internet was
  # refused (admin/nixlab#12).
  defaultAddresses = lib.unique (wildcard ++ webAddresses);
  uncovered = lib.subtractLists defaultAddresses webAddresses;

  # --- vhost helper ----------------------------------------------------------
  vhostModule =
    { ... }:
    {
      options = {
        serverName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Server name; null: the attribute name. Needed when two vhosts serve one name on different ports.";
        };

        port = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          example = 8080;
          description = "Loopback port `location /` proxies to; null: no such location, the vhost brings its own.";
        };

        websockets = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Upgrade websockets on `location /` (only with port).";
        };

        meshOnly = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Admit only the mesh (lab.mesh.networks) plus `allow`; everyone
            else gets 403. An HTTPS vhost then listens on the wildcard
            address: the mesh address is NetBird's to assign, and nb-mesh may
            come up after nginx.
          '';
        };

        allow = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Addresses or networks admitted on top of the mesh (with meshOnly).";
        };

        proxyListener = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          example = 8095;
          description = ''
            Instead of HTTPS on 443: a plain-HTTP listener on this port on all
            addresses, for a NetBird reverse proxy service that terminates TLS
            and reaches it through its tunnel. Always mesh-only, and nginx's
            own redirects stay relative (an absolute one would name this
            listener's side of the proxy).
          '';
        };

        maintenance = lib.mkOption {
          type = lib.types.enum [
            "switch"
            "errorPages"
            "none"
          ];
          default = "switch";
          description = ''
            Registration in modules/maintenance.nix: the maintenance switch
            plus error pages, only the 502/504 page, or nothing. Mind that
            module's allow/deny caveat for mesh-only vhosts on a public port.
          '';
        };

        waf = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Send the vhost's requests through the AppSec WAF (modules/waf.nix).";
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Server-level nginx directives, after the allow/deny block.";
        };

        nginx = lib.mkOption {
          type = lib.types.deferredModule;
          default = { };
          description = "Anything else of the vhost, merged into services.nginx.virtualHosts.<name> unchanged.";
        };
      };
    };

  namesWhere = pred: lib.attrNames (lib.filterAttrs (_: pred) config.lab.vhosts);

  allowBlock =
    v:
    lib.optionalString (v.meshOnly || v.proxyListener != null) (
      lib.concatMapStrings (a: "allow ${a};\n") (config.lab.mesh.networks ++ v.allow) + "deny all;\n"
    );

  # A function, not an attribute set: the vhost submodule reads a bare
  # attribute set as config only, which would make `imports` an option.
  toNginx =
    _name: v:
    { ... }:
    {
      imports = [ v.nginx ];
      serverName = lib.mkIf (v.serverName != null) v.serverName;
      extraConfig =
        allowBlock v
        + v.extraConfig
        + lib.optionalString (v.proxyListener != null) "absolute_redirect off;\n";
      locations = lib.mkIf (v.port != null) {
        "/" = {
          proxyPass = "http://127.0.0.1:${toString v.port}";
          proxyWebsockets = lib.mkIf v.websockets true;
        };
      };
    }
    // (
      if v.proxyListener != null then
        {
          listen =
            map
              (addr: {
                inherit addr;
                port = v.proxyListener;
              })
              [
                "0.0.0.0"
                "[::]"
              ];
        }
      else
        {
          enableACME = true;
          acmeRoot = null;
          forceSSL = true;
          # The nixpkgs default spelling, so a host whose defaults are the
          # wildcard renders the same.
          listenAddresses = lib.mkIf v.meshOnly (
            [ "0.0.0.0" ] ++ lib.optional config.networking.enableIPv6 "[::0]"
          );
        }
    );
in
{
  imports = [ ./lab.nix ];

  options.lab.web = {
    securityHeaders = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        # One year, without includeSubDomains/preload (decided 2026-11-15,
        # #308 3a): on a single service name includeSubDomains covers only
        # names below it, and preload is for apex domains.
        "Strict-Transport-Security" = "max-age=31536000";
        "X-Content-Type-Options" = "nosniff";
        "Referrer-Policy" = "strict-origin-when-cross-origin";
        # SAMEORIGIN, not DENY: paperless and OpenCloud frame their own pages.
        "X-Frame-Options" = "SAMEORIGIN";
      };
      description = "Response headers every web front adds unless the application sent them itself.";
    };

    nginx = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = nginx.enable;
        defaultText = lib.literalExpression "config.services.nginx.enable";
        description = "Security headers and default servers in this host's nginx.";
      };

      headers = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = addHeaders;
        description = "The add_header lines, for a location with add_header of its own - it inherits none of the shared ones otherwise.";
      };
    };
  };

  options.lab.vhosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule vhostModule);
    default = { };
    description = "nginx vhosts in the lab's usual shape; the attribute name is the nginx virtualHost name.";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.nginx.enable {
      assertions = [
        {
          assertion = headerLeaks == [ ];
          message = "web-baseline: add_header without `config.lab.web.nginx.headers` drops the security headers in: ${lib.concatStringsSep ", " headerLeaks}";
        }
        {
          assertion = uncovered == [ ];
          message = "web-baseline: no default server on ${lib.concatStringsSep ", " uncovered} - add them to services.nginx.defaultListenAddresses";
        }
      ];

      services.nginx.commonHttpConfig = headerMaps;
      services.nginx.appendHttpConfig = addHeaders;

      services.nginx.virtualHosts = {
        "_default-https" = {
          serverName = "_";
          default = true;
          rejectSSL = true;
          listen = map (addr: {
            inherit addr;
            port = 443;
            ssl = true;
          }) defaultAddresses;
          extraConfig = "return 444;\n";
        };
        "_default-http" = {
          serverName = "_";
          default = true;
          listen = map (addr: {
            inherit addr;
            port = 80;
            ssl = false;
          }) defaultAddresses;
          locations."/".return = "301 https://$host$request_uri";
        };
      };
    })

    {
      services.nginx.virtualHosts = lib.mapAttrs toNginx config.lab.vhosts;
    }

    # Only where the host imports those modules; a vhost asking for one that
    # is not there fails below.
    (lib.optionalAttrs (options.services ? maintenance) {
      services.maintenance.nginx = {
        vhosts = namesWhere (v: v.maintenance == "switch");
        errorPagesOnly = namesWhere (v: v.maintenance == "errorPages");
      };
    })

    (lib.optionalAttrs (options.services ? waf) {
      services.waf.nginx.vhosts = namesWhere (v: v.waf);
    })

    {
      assertions = [
        {
          assertion = options.services ? maintenance || namesWhere (v: v.maintenance != "none") == [ ];
          message = "lab.vhosts: ${
            lib.concatStringsSep ", " (namesWhere (v: v.maintenance != "none"))
          } want maintenance, but modules/maintenance.nix is not imported";
        }
        {
          assertion = options.services ? waf || namesWhere (v: v.waf) == [ ];
          message = "lab.vhosts: ${
            lib.concatStringsSep ", " (namesWhere (v: v.waf))
          } want the WAF, but modules/waf.nix is not imported";
        }
      ];
    }
  ];
}
