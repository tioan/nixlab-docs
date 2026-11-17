# Web application firewall: CrowdSec's AppSec component in front of public
# web vhosts, through nginx (OpenResty + CrowdSec's Lua bouncer) or Traefik
# (CrowdSec's Traefik plugin). Decided 2026-10-25 - until then CrowdSec only
# read the access logs after the fact (modules/crowdsec.nix), so it banned a
# scanner once it had shown itself, but the one request carrying an exploit
# still reached the service. AppSec judges each request before the proxy
# passes it on. Rolled out to every front door in admin/nixlab#4.
#
# Self-contained: no lab values in here. The host says which names go
# through AppSec, in which mode, with which exceptions, and where the
# bouncer's API key is at runtime (modules/waf-lab.nix does that from sops
# for this lab).
#
# Why AppSec and not ModSecurity: one engine for nginx and Traefik, and its
# matches become CrowdSec alerts and bans like everything else - no second
# log to wire up. The OWASP Core Rule Set still comes along, run by AppSec's
# Coraza engine, just out of band.
#
# The pieces:
#  - Rules, in band (decide before the request is let through):
#    crowdsecurity/appsec-virtual-patching (~200 rules for known CVEs),
#    crowdsecurity/appsec-generic-rules (.env, .git, SSTI, ...), and the
#    own ones below (homelab/*: script types and stacks nothing here runs).
#  - Rules, out of band (only evaluated, never block a request by
#    themselves): crowdsecurity/appsec-crs, the OWASP CRS. Its hits are
#    events; crowdsecurity/crowdsec-appsec-outofband bans an IP when its
#    bucket overflows: capacity 5, one token leaking every 30 s.
#  - Bans: every in-band match gets a 403; the IP is banned once two
#    *different* in-band rules hit within 60 s (crowdsecurity/appsec-vpatch:
#    capacity 1 with distinct rule_name). Enforced by whatever bouncers the
#    host runs - the firewall bouncer on every port, the Lua bouncer and the
#    Traefik plugin for requests that arrive through a proxy.
#
# Mode, per name (option `hosts`, default `mode`):
#  - block: in-band matches get a 403, matches feed the ban scenarios.
#  - detect: in-band matches are answered with "allow" and their events are
#    cancelled, so nothing is blocked and no ban scenario sees them; the
#    alerts stay (`cscli alerts list`, the console). Every new name starts
#    here for a week or two.
#  The log-based HTTP scenarios from modules/crowdsec.nix do not depend on
#  the mode.
#
# Failure: `failOpen` (default). If CrowdSec is down or slow, requests go
# through unchecked rather than the services going down with it. Neither the
# Lua bouncer nor the Traefik plugin can decide this per name, so it is one
# switch for the host; the metric `<prefix>waf_appsec_up` is what gets
# noticed.
#
# Docs: docs/site/*/explanation/waf.md.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.services.waf;

  yaml = pkgs.formats.yaml { };
  json = builtins.toJSON;

  lapiUrl = "http://${config.services.crowdsec.settings.general.api.server.listen_uri}";

  bouncer = cfg.luaBouncerPackage;
  luaHttp = pkgs.luajitPackages.lua-resty-http;
  traefikPlugin = cfg.traefikPluginPackage;

  # Written at nginx start from the key file (ExecStartPre below), so the
  # key never enters the store.
  nginxBouncerConf = "/run/crowdsec-waf/nginx-bouncer.conf";

  # --- Names and their effective settings ----------------------------------
  modeOf = h: if h.mode == null then cfg.mode else h.mode;
  namesIn = mode: lib.attrNames (lib.filterAttrs (_: h: modeOf h == mode) cfg.hosts);
  # A client may send the port along ("auth.example.org:443"); AppSec sees
  # the Host header as it came.
  hostVariants = names: lib.concatMap (n: [ n "${n}:443" ]) names;
  hostIn = names: "req.Host in ${json (hostVariants names)}";

  # Everything not explicitly in the other mode follows the default, so a
  # name nobody listed (a scanner's made-up Host) is judged like the rest.
  detectFilter =
    if cfg.mode == "block" then hostIn (namesIn "detect") else "!(${hostIn (namesIn "block")})";
  anyDetect = cfg.mode == "detect" || namesIn "detect" != [ ];

  # Conditions of one exclusion entry, as an expr fragment.
  exclusionFilter = name: e:
    lib.concatStringsSep " && " (
      [ (hostIn [ name ]) ]
      ++ lib.optional (e.paths != [ ]) "req.URL.Path in ${json e.paths}"
      ++ lib.optional (e.pathPrefixes != [ ])
        "(${lib.concatMapStringsSep " || " (p: "req.URL.Path startsWith ${json p}") e.pathPrefixes})"
      ++ lib.optional (e.methods != [ ]) "req.Method in ${json e.methods}"
    );

  # --- The own in-band rules -----------------------------------------------
  # Nothing behind these vhosts runs PHP, ASP, JSP or CGI, so a request for
  # one is a scan or an exploit by definition; every such request gets a
  # 403, a second, different rule the ban. This is the broad net under the
  # hub's per-CVE rules: a PHP webshell or the next PHP-CGI injection does
  # not need its own rule to be stopped. A service that keeps such paths
  # (OpenCloud: /remote.php, /status.php, /ocs/v*.php) gets an exclusion
  # for them.
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
    # next to every real match (both seen 2026-10-25). They detect nothing,
    # so dropping them loses nothing.
    on_load = [
      { apply = [ "RemoveOutBandRuleByID(980099)" "RemoveOutBandRuleByID(980170)" ]; }
    ];
    # pre_eval runs before any rule is evaluated; top-level hooks run in
    # both passes, hence IsInBand/IsOutBand.
    #  - exclusions: drop in-band rules (by name) or CRS rules (by ID) for
    #    the matching requests only.
    #  - allowedMethods: anything else is dropped in band, which counts like
    #    a rule match - alert, and in block mode a 403.
    pre_eval = lib.concatLists (
      lib.mapAttrsToList (
        name: h:
        lib.concatMap (
          e:
          lib.optional (e.rules != [ ]) {
            filter = "IsInBand && ${exclusionFilter name e}";
            apply = map (r: "RemoveInBandRuleByName(${json r})") e.rules;
          }
          ++ lib.optional (e.crsIds != [ ]) {
            filter = "IsOutBand && ${exclusionFilter name e}";
            apply = map (i: "RemoveOutBandRuleByID(${toString i})") e.crsIds;
          }
        ) h.exclusions
        ++ lib.optional (h.allowedMethods != null) {
          filter = "IsInBand && ${hostIn [ name ]} && req.Method not in ${json h.allowedMethods}";
          apply = [ "DropRequest(${json "method not allowed on ${name}"})" ];
        }
      ) cfg.hosts
    );
    # Detect: "allow" is the one remediation the bouncers let through; the
    # alert stays (SendAlert is untouched), the event that would feed the
    # ban scenarios goes. Out of band only events exist, so a detect name's
    # CRS matches show up in the rule metrics only.
    on_match = lib.optionals anyDetect [
      {
        filter = "IsInBand && ${detectFilter}";
        apply = [ "SetRemediation(\"allow\")" "CancelEvent()" ];
      }
      {
        filter = "IsOutBand && ${detectFilter}";
        apply = [ "CancelEvent()" ];
      }
    ];
  };

  ruleFiles = map (r: {
    name = "appsec-rules/${lib.replaceStrings [ "/" ] [ "-" ] r.name}.yaml";
    file = yaml.generate "appsec-rule.yaml" r;
  }) ownRules;
  configFiles = [
    {
      name = "appsec-configs/${lib.replaceStrings [ "/" ] [ "-" ] ownConfig.name}.yaml";
      file = yaml.generate "appsec-config.yaml" ownConfig;
    }
  ];

  # --- nginx ---------------------------------------------------------------
  # Requests AppSec does not inspect (bodies it cannot judge and should not
  # buffer); bans still apply. One map over "<host> <method> <uri>".
  skipEntries = lib.concatLists (
    lib.mapAttrsToList (
      name: h:
      map (
        s:
        let
          # nginx's $host carries no port.
          host = lib.escapeRegex name;
          methods = if s.methods == [ ] then "[A-Z]+" else "(${lib.concatStringsSep "|" s.methods})";
          prefixes = "(${lib.concatMapStringsSep "|" lib.escapeRegex s.pathPrefixes})";
        in
        "\"~^${host} ${methods} ${prefixes}\" 1;"
      ) h.skipInspection
    ) cfg.hosts
  );

  bouncerConfScript = pkgs.writeShellScript "crowdsec-waf-nginx-conf" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    umask 077
    install -d -m 0750 -o root -g ${config.services.nginx.group} /run/crowdsec-waf
    key=$(tr -d '\n' < ${lib.escapeShellArg (toString cfg.nginx.apiKeyFile)})
    tmp=$(mktemp /run/crowdsec-waf/.nginx-bouncer.XXXXXX)
    # The bouncer's own KEY=VALUE format (lua-cs-bouncer config_example.conf).
    cat > "$tmp" <<EOF
    ENABLED=true
    API_URL=${lapiUrl}
    API_KEY=$key
    MODE=stream
    UPDATE_FREQUENCY=10
    BOUNCING_ON_TYPE=all
    FALLBACK_REMEDIATION=ban
    BAN_TEMPLATE_PATH=${bouncer}/share/crowdsec-lua-bouncer/templates/ban.html
    CAPTCHA_TEMPLATE_PATH=${bouncer}/share/crowdsec-lua-bouncer/templates/captcha.html
    APPSEC_URL=http://${cfg.listen}
    APPSEC_FAILURE_ACTION=${if cfg.failOpen then "passthrough" else "deny"}
    APPSEC_CONNECT_TIMEOUT=100
    APPSEC_SEND_TIMEOUT=100
    APPSEC_PROCESS_TIMEOUT=500
    ALWAYS_SEND_TO_APPSEC=false
    EOF
    chgrp ${config.services.nginx.group} "$tmp"
    chmod 0640 "$tmp"
    mv "$tmp" ${nginxBouncerConf}
  '';

  metricsLua = ''
    local d = ngx.shared.crowdsec_waf_metrics
    local out = {
      "# HELP ${cfg.metricPrefix}waf_requests_total Requests of a WAF vhost by outcome at the bouncer step: refused (WAF match or ban) or passed.",
      "# TYPE ${cfg.metricPrefix}waf_requests_total counter",
    }
    for _, k in ipairs(d:get_keys(0)) do
      local vhost, result = k:match("^(.*)|(%a+)$")
      if vhost then
        out[#out + 1] = string.format('${cfg.metricPrefix}waf_requests_total{vhost="%s",result="%s"} %d', vhost, result, d:get(k) or 0)
      end
    end
    ngx.header["Content-Type"] = "text/plain; version=0.0.4"
    ngx.say(table.concat(out, "\n"))
  '';

  # --- Traefik ---------------------------------------------------------------
  traefikOn = cfg.traefik.enable;
in
{
  options.services.waf = {
    enable = lib.mkEnableOption "the CrowdSec AppSec WAF for this host's public web vhosts";

    # Packaged in this repo (pkgs/crowdsec-lua-bouncer.nix,
    # pkgs/crowdsec-traefik-plugin.nix), reached through the flake's
    # overlay; without it, set these.
    luaBouncerPackage = lib.mkPackageOption pkgs [ "nixlab" "crowdsec-lua-bouncer" ] {
      extraDescription = "CrowdSec's Lua bouncer for OpenResty (lua-cs-bouncer).";
    };

    traefikPluginPackage = lib.mkPackageOption pkgs [ "nixlab" "crowdsec-traefik-plugin" ] {
      extraDescription = "CrowdSec's bouncer plugin for Traefik, as a local plugin source tree.";
    };

    mode = mkOption {
      type = types.enum [ "detect" "block" ];
      default = "detect";
      description = ''
        Default for every name not given its own mode in `hosts`.
        `detect`: matches are alerted, nothing is blocked or banned by the
        WAF. `block`: in-band matches get a 403 and feed the ban scenarios.
      '';
    };

    listen = mkOption {
      type = types.str;
      default = "127.0.0.1:7422";
      description = "Address the AppSec component listens on, for the bouncers.";
    };

    failOpen = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Let requests through unchecked when AppSec cannot be reached or does
        not answer in time. false refuses them instead - for every name on
        the host; neither bouncer can decide this per name.
      '';
    };

    hubCollections = mkOption {
      type = types.listOf types.str;
      default = [
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
        "crowdsecurity/appsec-crs"
      ];
      description = "Hub collections with the AppSec rules and configs.";
    };

    hubAppsecConfigs = mkOption {
      type = types.listOf types.str;
      default = [
        "crowdsecurity/appsec-default"
        "crowdsecurity/crs"
      ];
      description = ''
        Hub AppSec configs, merged in this order before the module's own:
        appsec-default brings base-config, vpatch-* and generic-*, crs the
        out-of-band CRS.
      '';
    };

    metricPrefix = mkOption {
      type = types.str;
      default = "nixlab_";
      description = "Prefix of the module's own metric names.";
    };

    hosts = mkOption {
      default = { };
      description = ''
        Per name (the Host header a client sends, without port): mode and
        exceptions. Names that only need the default mode need no entry.
      '';
      example = lib.literalExpression ''
        {
          "cloud.example.org" = {
            mode = "detect";
            exclusions = [
              { rules = [ "homelab/no-server-side-scripts" ]; pathPrefixes = [ "/remote.php" ]; }
              { crsIds = [ 911100 ]; methods = [ "PROPFIND" "MOVE" ]; }
            ];
            skipInspection = [ { methods = [ "PUT" ]; pathPrefixes = [ "/remote.php/dav/" ]; } ];
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            mode = mkOption {
              type = types.nullOr (types.enum [ "detect" "block" ]);
              default = null;
              description = "Mode for this name; null follows `services.waf.mode`.";
            };

            exclusions = mkOption {
              default = [ ];
              description = ''
                Rules not applied to some requests for this name. Every
                condition given must hold; none given means all requests.
              '';
              type = types.listOf (
                types.submodule {
                  options = {
                    rules = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "In-band rules, by name.";
                    };
                    crsIds = mkOption {
                      type = types.listOf types.ints.positive;
                      default = [ ];
                      description = "Out-of-band (CRS) rules, by ID. They cannot block, but enough matches ban.";
                    };
                    paths = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Exact request paths.";
                    };
                    pathPrefixes = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Request path prefixes.";
                    };
                    methods = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "HTTP methods.";
                    };
                  };
                }
              );
            };

            allowedMethods = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              example = [ "GET" "HEAD" "POST" "PUT" "PATCH" "DELETE" "OPTIONS" ];
              description = ''
                HTTP methods this name accepts; any other one (TRACE,
                PROPFIND, CONNECT, made-up verbs) is treated like a rule
                match. null: no restriction (WebDAV services).
              '';
            };

            skipInspection = mkOption {
              default = [ ];
              description = ''
                nginx only: requests not sent to AppSec at all - large
                upload bodies the bouncer would otherwise buffer whole
                (its read_body undoes proxy_request_buffering off). Bans
                still apply.
              '';
              type = types.listOf (
                types.submodule {
                  options = {
                    pathPrefixes = mkOption {
                      type = types.nonEmptyListOf types.str;
                      description = "Request path prefixes.";
                    };
                    methods = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "HTTP methods; empty means all.";
                    };
                  };
                }
              );
            };
          };
        }
      );
    };

    nginx = {
      vhosts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "auth.example.org" ];
        description = ''
          nginx virtualHosts (attribute names) whose requests go through
          the bouncer and AppSec. Machine traffic with binary or signed
          bodies (S3, gRPC) does not belong here - there is nothing for the
          rules to find and plenty for them to misread.
        '';
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/run/secrets/crowdsec_nginx_bouncer_api_key";
        description = ''
          File holding the bouncer's LAPI key (`cscli bouncers add`), read
          as root at nginx start. null leaves nginx alone - the host can run
          the AppSec engine first and add the bouncer afterwards. Setting it
          switches the whole host to OpenResty.
        '';
      };

      metricsPort = mkOption {
        type = types.port;
        # Not in 9100-9300: OpenCloud's services and the usual Prometheus
        # exporters crowd that range (9146 clashed with OpenCloud on aldrin).
        default = 9932;
        description = "Loopback port of the per-vhost counters (/metrics).";
      };
    };

    traefik = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Load CrowdSec's Traefik plugin as a local plugin and define the
          middleware `middleware`; routers opt in by listing it.
        '';
      };

      middleware = mkOption {
        type = types.str;
        default = "waf";
        description = "Name of the middleware (reference it as \"<name>@file\").";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File with the bouncer's LAPI key, readable by the traefik user.";
      };

      trustedProxies = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Addresses whose X-Forwarded-For is believed (a reverse proxy in
          front of Traefik); everyone else is judged by the peer address.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions =
        map (n: {
          assertion = config.services.nginx.virtualHosts ? ${n};
          message = "services.waf.nginx.vhosts: virtualHost ${n} does not exist";
        }) cfg.nginx.vhosts
        ++ [
          {
            assertion = !traefikOn || cfg.traefik.apiKeyFile != null;
            message = "services.waf.traefik.enable needs services.waf.traefik.apiKeyFile";
          }
        ];

      warnings = lib.optional (cfg.nginx.apiKeyFile == null && cfg.nginx.vhosts != [ ])
        "waf: services.waf.nginx.apiKeyFile is not set - nginx does not consult AppSec yet.";

      services.crowdsec = {
        hub.collections = cfg.hubCollections;

        localConfig.acquisitions = [
          {
            source = "appsec";
            name = "appsec";
            listen_addr = cfg.listen;
            path = "/";
            appsec_configs = cfg.hubAppsecConfigs ++ map (c: c.name) [ ownConfig ];
            labels.type = "appsec";
          }
        ];
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

    # With the key, the whole host moves to OpenResty and the bouncer loads.
    (lib.mkIf (cfg.nginx.apiKeyFile != null) {
      # Unmodified pkgs.openresty on purpose: the nginx module only lifts
      # MemoryDenyWriteExecute (which LuaJIT's JIT needs) when the package
      # *is* pkgs.openresty, an override would fail that comparison.
      services.nginx.package = pkgs.openresty;

      # Adapted from CrowdSec's cs-nginx-bouncer, nginx/crowdsec_nginx.conf
      # (https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf,
      # MIT), with Nix paths and without the unix-socket map. The cache
      # holds stream-mode decisions, about 79,000 with the community lists
      # (2026-11-08). 10m was too small: it evicted entries with "cache is
      # full" tens of thousands of times a day (admin/nixlab#236). 32m
      # instead of upstream's 50m on small VMs - shared memory that only
      # grows with the ban list.
      #
      # Every start logs "error loading captcha plugin: no recaptcha site key
      # provided" at error level. Harmless: no captcha is configured.
      services.nginx.appendHttpConfig = ''
        lua_package_path '${bouncer}/lib/lua/?.lua;${luaHttp}/share/lua/5.1/?.lua;;';
        lua_shared_dict crowdsec_cache 32m;
        lua_shared_dict crowdsec_waf_metrics 1m;

        init_by_lua_block {
          cs = require "crowdsec"
          local ok, err = cs.init("${nginxBouncerConf}", "crowdsec-nginx-bouncer/v1.2.3")
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

        # The bouncer reads this per request (crowdsec.lua is_appsec_enabled).
        map "$host $request_method $uri" $crowdsec_disable_appsec {
          default 0;
          ${lib.concatStringsSep "\n  " skipEntries}
        }

        server {
          listen 127.0.0.1:${toString cfg.nginx.metricsPort};
          access_log off;
          location = /metrics {
            content_by_lua_block {
              ${metricsLua}
            }
          }
          location / {
            return 404;
          }
        }
      '';

      # The access phase asks the bouncer; the log phase counts what it did.
      # A request the bouncer refused ends in the access phase with a 403
      # and never reaches an upstream. Redirects that return earlier (in
      # rewrite) are not counted at all.
      services.nginx.virtualHosts = lib.genAttrs cfg.nginx.vhosts (_: {
        extraConfig = ''
          access_by_lua_block {
            ngx.ctx.crowdsec_waf = true
            require("crowdsec").Allow(ngx.var.remote_addr)
          }
          log_by_lua_block {
            if ngx.ctx.crowdsec_waf then
              local refused = ngx.status == 403 and (ngx.var.upstream_addr or "") == ""
              ngx.shared.crowdsec_waf_metrics:incr(ngx.var.server_name .. (refused and "|refused" or "|passed"), 1, 0)
            end
          }
        '';
      });

      # nginx must not start before the bouncer config exists, and should
      # find AppSec listening; failOpen covers the rest.
      systemd.services.nginx = {
        after = [ "crowdsec.service" ];
        wants = [ "crowdsec.service" ];
        serviceConfig.ExecStartPre = lib.mkBefore [ "+${bouncerConfScript}" ];
      };
    })

    (lib.mkIf traefikOn {
      services.traefik.staticConfigOptions.experimental.localPlugins.crowdsec.moduleName =
        traefikPlugin.moduleName;

      # Traefik looks for local plugins under ./plugins-local/src/<module>,
      # relative to its working directory, and its Go interpreter resolves
      # imports inside that tree - a symlink into the store leads out of it,
      # so the source is copied there on every start.

      services.traefik.dynamicConfigOptions.http.middlewares.${cfg.traefik.middleware}.plugin.crowdsec = {
        enabled = true;
        logLevel = "WARN";
        crowdsecMode = "stream";
        crowdsecLapiScheme = "http";
        crowdsecLapiHost = config.services.crowdsec.settings.general.api.server.listen_uri;
        crowdsecLapiKeyFile = cfg.traefik.apiKeyFile;
        crowdsecAppsecEnabled = true;
        crowdsecAppsecHost = cfg.listen;
        # The plugin's defaults refuse everything when AppSec or the LAPI
        # cannot be reached, and until the first decision pull.
        crowdsecAppsecFailureBlock = !cfg.failOpen;
        crowdsecAppsecUnreachableBlock = !cfg.failOpen;
        crowdsecAppsecUnreadableBodyBlock = !cfg.failOpen;
        streamStartupBlock = !cfg.failOpen;
        updateMaxFailure = if cfg.failOpen then -1 else 0;
        forwardedHeadersTrustedIps = cfg.traefik.trustedProxies;
      };

      systemd.services.traefik = {
        after = [ "crowdsec.service" ];
        wants = [ "crowdsec.service" ];
        serviceConfig.ExecStartPre = lib.mkBefore [
          "+${pkgs.writeShellScript "crowdsec-traefik-plugin" ''
            set -eu
            export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
            dir=${config.services.traefik.dataDir}/plugins-local/src/${traefikPlugin.moduleName}
            rm -rf "$dir"
            mkdir -p "$(dirname "$dir")"
            cp -r --no-preserve=mode,ownership ${traefikPlugin} "$dir"
            chown -R ${config.services.traefik.user or "traefik"}: ${config.services.traefik.dataDir}/plugins-local
          ''}"
        ];
      };
    })
  ]);
}
