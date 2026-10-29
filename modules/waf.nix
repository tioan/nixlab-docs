# Web application firewall: CrowdSec's AppSec component in front of the
# public nginx vhosts. Decided 2026-10-25 - until then CrowdSec only read the
# access logs after the fact (modules/crowdsec.nix), so it banned a scanner
# once it had shown itself, but the one request carrying an exploit still
# reached the service. AppSec judges each request before nginx proxies it.
#
# Why AppSec and not ModSecurity: one engine for nginx and Traefik (grammi
# gets the Traefik plugin later), and its matches become CrowdSec alerts and
# bans like everything else - no second log to wire up. The OWASP Core Rule
# Set still comes along, run by AppSec's Coraza engine, just out of band.
#
# The pieces:
#  - Rules, in band (decide before the request is let through):
#    crowdsecurity/appsec-virtual-patching (~200 rules for known CVEs:
#    PHP-CGI, Spring4Shell, Grafana file read, ...),
#    crowdsecurity/appsec-generic-rules (.env, .git, SSTI, ...), and the
#    lab's own below (homelab/*: script types and stacks nothing here runs).
#  - Rules, out of band (only evaluated, never block a request by
#    themselves): crowdsecurity/appsec-crs, the OWASP CRS. Its hits are
#    events; crowdsecurity/crowdsec-appsec-outofband bans an IP after more
#    than 5 within 30 s. That keeps the broad, false-positive-prone CRS
#    useful without one stray match locking out a legitimate user.
#  - Bans: every in-band match gets a 403; the IP is banned once two
#    *different* in-band rules hit within 60 s (crowdsecurity/appsec-vpatch:
#    capacity 1 with distinct rule_name, so one rule repeated never fills
#    it). Enforced by the existing
#    firewall bouncer on every port, not just 443.
#  - nginx: OpenResty instead of plain nginx (same NixOS module, Lua built
#    in), with CrowdSec's Lua bouncer (pkgs/crowdsec-lua-bouncer.nix) in the
#    access phase of each listed vhost. It forwards the request (headers and
#    body) to AppSec on 127.0.0.1:7422 and acts on the answer.
#  - Failure: APPSEC_FAILURE_ACTION=passthrough. If CrowdSec is down or
#    slow, requests go through unchecked rather than pocket-id going down
#    with it; the crowdsec unit failing is what gets noticed.
#
# mode = "detect" (the default, for every new host): in-band matches are
# answered with "allow" (homelab/detect-only below) and the AppSec ban
# scenarios run in simulation, so alerts show up in `cscli alerts list` and
# the console - marked "(simul)" - but nothing is blocked or banned by the
# WAF. Switch a host to "block" after a week or two without false
# positives. The log-based HTTP scenarios from modules/crowdsec.nix are not
# affected by the mode; they ban as before.
#
# Bootstrap per host: `just waf-key <host>` registers the bouncer with the
# host's LAPI and writes its key to hosts/<host>/waf.yaml (sops). Without
# that file the nginx side stays off and evaluation warns - the AppSec
# engine itself runs regardless.
#
# Docs: docs/site/*/explanation/waf.md.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.waf;
  host = config.networking.hostName;

  yaml = pkgs.formats.yaml { };

  appsecListen = "127.0.0.1:7422";
  lapiUrl = "http://${config.services.crowdsec.settings.general.api.server.listen_uri}";

  keyFile = ../hosts + "/${host}/waf.yaml";
  hasKey = builtins.pathExists keyFile;

  bouncer = pkgs.callPackage ../pkgs/crowdsec-lua-bouncer.nix { };
  luaHttp = pkgs.luajitPackages.lua-resty-http;
  bouncerConf = config.sops.templates."crowdsec-nginx-bouncer.conf".path;

  # --- The lab's own in-band rules -----------------------------------------
  # Nothing on the public vhosts runs PHP, ASP, JSP or CGI, so a request for
  # one is a scan or an exploit by definition - no false positives to tune
  # away; every such request gets a 403, a second, different rule the ban. This is
  # the broad net under the hub's per-CVE rules: a PHP webshell or the next
  # PHP-CGI injection does not need its own rule to be stopped here.
  # Careful with OpenCloud when aldrin joins: it keeps ownCloud's
  # /remote.php, /status.php and /ocs/v*.php for the desktop clients - list
  # this rule under ruleExclusions for that name.
  ownRules = [
    {
      name = "homelab/no-server-side-scripts";
      description = "Request for a script type no service here runs (PHP, ASP, JSP, CGI)";
      rules = [
        {
          or = [
            {
              zones = [ "URI" ];
              transform = [ "urldecode" "lowercase" ];
              match = {
                type = "regex";
                value = "\\.(php[0-9]?|phtml|phar|aspx?|ashx|asmx|jspx?|cgi|cfm)$";
              };
            }
            {
              zones = [ "URI" ];
              transform = [ "urldecode" "lowercase" ];
              match = {
                type = "contains";
                value = "/cgi-bin/";
              };
            }
          ];
        }
      ];
      labels = {
        type = "scan";
        service = "http";
        confidence = 3;
        spoofable = 0;
        behavior = "http:scan";
        label = "Server-side script probing";
        classification = [ "attack.T1595" "attack.T1190" ];
      };
    }
    # Admin panels and frameworks of stacks that are not here: WordPress,
    # phpMyAdmin, Spring Boot actuator, Solr, Exchange/OWA, router firmware.
    # Plus dot-directories with credentials (.env and .git have their own
    # hub rules). .well-known is untouched - ACME and OIDC discovery live
    # there.
    {
      name = "homelab/foreign-stack-probing";
      description = "Probe for an admin panel, framework or credential file of a stack not run here";
      rules = [
        {
          or = [
            {
              zones = [ "URI" ];
              transform = [ "urldecode" "lowercase" "normalize_path" ];
              match = {
                type = "regex";
                value = "^/(wp-(admin|content|includes|json|login)|wordpress|phpmyadmin|pma|myadmin|actuator|solr|owa|ecp|autodiscover|boaform|hnap1|vendor/phpunit)(/|$)";
              };
            }
            {
              zones = [ "URI" ];
              transform = [ "urldecode" "lowercase" "normalize_path" ];
              match = {
                type = "regex";
                value = "/\\.(aws|ssh|svn|hg|docker|kube|htpasswd|htaccess|npmrc|ds_store)(/|$)";
              };
            }
          ];
        }
      ];
      labels = {
        type = "scan";
        service = "http";
        confidence = 3;
        spoofable = 0;
        behavior = "http:scan";
        label = "Foreign stack probing";
        classification = [ "attack.T1595" ];
      };
    }
  ];

  ownConfig = {
    name = "homelab/appsec";
    default_remediation = "ban";
    inband_rules = [ "homelab/*" ];
    # CRS 980099 and 980170 only report the anomaly scores. Under AppSec
    # the score variables are not expanded: 980099 logs a strconv.Atoi
    # error, 980170 raises an alert "Anomaly Scores: ... blocking=tx...."
    # next to every real match (both seen on zummi 2026-10-25). They detect
    # nothing, so dropping them loses nothing.
    on_load = [
      { apply = [ "RemoveOutBandRuleByID(980099)" "RemoveOutBandRuleByID(980170)" ]; }
    ];
    # pre_eval runs before any rule is evaluated.
    #  - Per-name exceptions (option ruleExclusions): drop the rule for that
    #    request only.
    #  - Method allowlists (option allowedMethods): anything else is dropped
    #    in band, which counts like a rule match - alert, and in block mode
    #    a 403. IsInBand because top-level hooks run in both passes; without
    #    it every such request raised two alerts.
    pre_eval =
      lib.mapAttrsToList (name: rules: {
        filter = "req.Host == ${builtins.toJSON name}";
        apply = map (r: "RemoveInBandRuleByName(${builtins.toJSON r})") rules;
      }) cfg.ruleExclusions
      ++ lib.mapAttrsToList (name: methods: {
        filter = "IsInBand && req.Host == ${builtins.toJSON name} && req.Method not in ${builtins.toJSON methods}";
        apply = [ "DropRequest(${builtins.toJSON "method not allowed on ${name}"})" ];
      }) cfg.allowedMethods;
  };

  # "allow" is the one remediation the bouncer lets through. Alerts and
  # events are still generated (crowdsec's handleInBandInterrupt only reads
  # SendAlert/SendEvent, which this leaves alone), so the matches stay
  # visible - only the answer to nginx changes.
  detectConfig = {
    name = "homelab/detect-only";
    on_match = [
      {
        filter = "IsInBand == true";
        apply = [ "SetRemediation(\"allow\")" ];
      }
    ];
  };

  # The scenarios that turn AppSec matches into bans. In detect mode they
  # run in simulation: the decision is recorded, not enforced.
  appsecScenarios = [
    "crowdsecurity/appsec-vpatch"
    "crowdsecurity/appsec-native"
    "crowdsecurity/appsec-generic-test"
    "crowdsecurity/crowdsec-appsec-outofband"
  ];

  ruleFiles = map (r: {
    name = "appsec-rules/${lib.replaceStrings [ "/" ] [ "-" ] r.name}.yaml";
    file = yaml.generate "appsec-rule.yaml" r;
  }) ownRules;
  configFiles = map (c: {
    name = "appsec-configs/${lib.replaceStrings [ "/" ] [ "-" ] c.name}.yaml";
    file = yaml.generate "appsec-config.yaml" c;
  }) ([ ownConfig ] ++ lib.optional (cfg.mode == "detect") detectConfig);
in
{
  options.services.waf = {
    enable = lib.mkEnableOption "the CrowdSec AppSec WAF for this host's public nginx vhosts";

    mode = lib.mkOption {
      type = lib.types.enum [ "detect" "block" ];
      default = "detect";
      description = ''
        `detect`: matches are alerted, nothing is blocked or banned by the
        WAF. `block`: in-band matches get a 403 and the IP banned.
      '';
    };

    nginx.vhosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "auth.homelab.example" ];
      description = ''
        nginx virtualHosts (attribute names) whose requests go through
        AppSec. Machine traffic with binary or signed bodies (S3, gRPC)
        does not belong here - there is nothing for the rules to find and
        plenty for them to misread.
      '';
    };

    ruleExclusions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = {
        "cloud.homelab.example" = [ "homelab/no-server-side-scripts" ];
      };
      description = "In-band rules (by name) not applied to requests for that Host.";
    };

    allowedMethods = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      example = {
        "auth.homelab.example" = [ "GET" "HEAD" "POST" "PUT" "PATCH" "DELETE" "OPTIONS" ];
      };
      description = ''
        HTTP methods a Host accepts; any other one (TRACE, PROPFIND, CONNECT,
        made-up verbs) is treated like a rule match. Leave a name out for
        services that need WebDAV (OpenCloud).
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = map (n: {
        assertion = config.services.nginx.virtualHosts ? ${n};
        message = "services.waf.nginx.vhosts: virtualHost ${n} does not exist";
      }) cfg.nginx.vhosts;

      warnings = lib.optional (!hasKey && cfg.nginx.vhosts != [ ])
        "waf: no hosts/${host}/waf.yaml - nginx does not consult AppSec yet; run `just waf-key ${host}`.";

      services.crowdsec = {
        hub.collections = [
          "crowdsecurity/appsec-virtual-patching"
          "crowdsecurity/appsec-generic-rules"
          "crowdsecurity/appsec-crs"
        ];

        localConfig.acquisitions = [
          {
            source = "appsec";
            name = "appsec";
            listen_addr = appsecListen;
            path = "/";
            # Merged in order; the hub's appsec-default brings base-config,
            # vpatch-* and generic-*, crs the out-of-band CRS.
            appsec_configs = [
              "crowdsecurity/appsec-default"
              "crowdsecurity/crs"
            ]
            ++ map (c: c.name) ([ ownConfig ] ++ lib.optional (cfg.mode == "detect") detectConfig);
            labels.type = "appsec";
          }
        ];

        settings.simulation = lib.mkIf (cfg.mode == "detect") {
          simulation = false;
          exclusions = appsecScenarios;
        };
      };

      # Local hub items, linked the way the crowdsec module links its own
      # localConfig files: crowdsec treats a symlink that does not point into
      # the hub as a local item. The module creates neither directory.
      systemd.tmpfiles.settings."11-crowdsec-appsec" =
        {
          "/etc/crowdsec/appsec-rules".d = {
            user = config.services.crowdsec.user;
            group = config.services.crowdsec.group;
            mode = "0750";
          };
          "/etc/crowdsec/appsec-configs".d = {
            user = config.services.crowdsec.user;
            group = config.services.crowdsec.group;
            mode = "0750";
          };
        }
        // lib.listToAttrs (
          map (f: {
            name = "/etc/crowdsec/${f.name}";
            value."L+".argument = "${f.file}";
          }) (ruleFiles ++ configFiles)
        );

      # A changed rule or config only takes effect on restart.
      systemd.services.crowdsec.restartTriggers = map (f: f.file) (ruleFiles ++ configFiles);
    }

    (lib.mkIf (hasKey && cfg.nginx.vhosts != [ ]) {
      sops.secrets."crowdsec_nginx_bouncer_api_key" = {
        sopsFile = keyFile;
      };

      # The bouncer's own KEY=VALUE format (lua-cs-bouncer config_example.conf).
      # Read once by nginx at start and reload - by the nginx user, since
      # the NixOS unit runs the master unprivileged.
      sops.templates."crowdsec-nginx-bouncer.conf" = {
        owner = config.services.nginx.user;
        restartUnits = [ "nginx.service" ];
        content = ''
          ENABLED=true
          API_URL=${lapiUrl}
          API_KEY=${config.sops.placeholder."crowdsec_nginx_bouncer_api_key"}
          MODE=stream
          UPDATE_FREQUENCY=10
          BOUNCING_ON_TYPE=all
          FALLBACK_REMEDIATION=ban
          BAN_TEMPLATE_PATH=${bouncer}/share/crowdsec-lua-bouncer/templates/ban.html
          CAPTCHA_TEMPLATE_PATH=${bouncer}/share/crowdsec-lua-bouncer/templates/captcha.html
          APPSEC_URL=http://${appsecListen}
          APPSEC_FAILURE_ACTION=passthrough
          APPSEC_CONNECT_TIMEOUT=100
          APPSEC_SEND_TIMEOUT=100
          APPSEC_PROCESS_TIMEOUT=500
          ALWAYS_SEND_TO_APPSEC=false
        '';
      };

      # Unmodified pkgs.openresty on purpose: the nginx module only lifts
      # MemoryDenyWriteExecute (which LuaJIT's JIT needs) when the package
      # *is* pkgs.openresty, an override would fail that comparison.
      services.nginx.package = pkgs.openresty;

      # Adapted from CrowdSec's cs-nginx-bouncer, nginx/crowdsec_nginx.conf
      # (https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf),
      # with Nix paths and without the unix-socket map (no vhost here listens
      # on one). The cache holds stream-mode decisions; 10m instead of
      # upstream's 50m on these small VMs - it is shared memory and only
      # grows with the ban list.
      #
      # Every start logs "error loading captcha plugin: no recaptcha site key
      # provided" at error level. Harmless: no captcha is configured, and
      # the bouncer carries on without that plugin.
      services.nginx.appendHttpConfig = ''
        lua_package_path '${bouncer}/lib/lua/?.lua;${luaHttp}/share/lua/5.1/?.lua;;';
        lua_shared_dict crowdsec_cache 10m;

        init_by_lua_block {
          cs = require "crowdsec"
          local ok, err = cs.init("${bouncerConf}", "crowdsec-nginx-bouncer/v1.2.3")
          if ok == nil then
            ngx.log(ngx.ERR, "[Crowdsec] " .. err)
            error()
          end
        }

        init_worker_by_lua_block {
          cs = require "crowdsec"
          if string.lower(cs.get_mode()) == "stream" then
            cs.SetupStream()
          end
          if ngx.worker.id() == 0 then
            cs.SetupMetrics()
          end
        }
      '';

      services.nginx.virtualHosts = lib.genAttrs cfg.nginx.vhosts (_: {
        extraConfig = ''
          access_by_lua_block {
            require("crowdsec").Allow(ngx.var.remote_addr)
          }
        '';
      });

      # nginx must not start before the bouncer config exists, and should
      # find AppSec listening; passthrough covers the rest.
      systemd.services.nginx = {
        after = [ "crowdsec.service" ];
        wants = [ "crowdsec.service" ];
      };
    })
  ]);
}
