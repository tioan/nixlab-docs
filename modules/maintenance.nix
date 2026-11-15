# Maintenance mode for the lab's web services, the same for nginx and
# Traefik: a flag file switches a name to a 503 page, and the proxy shows
# the same page (with 502/504) when the service behind it does not answer.
# Decided 2026-10-22 (idea from a blog post on an nginx toggle script);
# docs: docs/site/*/how-to/maintenance.md.
#
# The pieces:
#  - Flags: /var/lib/maintenance/<fqdn> or /var/lib/maintenance/all, the
#    file's content is the reason shown on the page. Persistent on purpose:
#    a reboot in the middle of maintenance keeps the service closed.
#    Set with `maintenance on|off|status` on the host, or
#    `just maintenance <name> ...` from the workstation.
#  - Responder (maintenance/responder.py): socket-activated, loopback only,
#    renders the page for both proxies - one place that decides between
#    maintenance and failure, instead of one nginx and one Traefik version.
#  - nginx (option nginx.vhosts): checks the flag on every request -
#    `if (-f ...)` is evaluated per request (no open_file_cache here), so
#    switching needs no reload. Its own 502/504 go to the same page; the
#    service's own error responses pass untouched (proxy_intercept_errors
#    stays off - S3's XML errors, OIDC's JSON).
#  - Traefik (option traefik.enable): has no file test, so a oneshot turns
#    the flags into routers in a watched directory (maintenance/
#    traefik-sync.py); Traefik picks them up without a restart.
#  - Bypass: whoever holds the cookie (token from sops, hosts/<host>/
#    maintenance.yaml, the same on every host) sees the service anyway.
#    A convenience for testing in the browser, not a security boundary: the
#    service's own login, the proxy's SSO and allow/deny all still apply.
#
# Caveat for nginx vhosts with allow/deny: the check is a rewrite-phase
# `return`, which runs before allow/deny (modules/docs-site.nix has the
# details), so the page would also reach clients the vhost otherwise
# refuses. Only list vhosts whose port only allowed clients reach anyway.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.maintenance;
  host = config.networking.hostName;

  flagDir = "/var/lib/maintenance";
  cookieName = "nixlab_maint_bypass";

  tokenFile = ../hosts + "/${host}/maintenance.yaml";
  hasToken = builtins.pathExists tokenFile;
  tokenPath = config.sops.secrets."maintenance_bypass_token".path;

  responderUrl = "http://127.0.0.1:${toString cfg.port}";

  python = pkgs.python3;

  nginxCfg = config.services.nginx;
  nginxNames = map (n: let v = nginxCfg.virtualHosts.${n}; in if v.serverName != null then v.serverName else n) cfg.nginx.vhosts;
  knownNames = lib.unique (nginxNames ++ cfg.traefik.names);

  # --- Traefik: own static config pointing at a directory ------------------
  # The NixOS module always sets providers.file.filename to its generated
  # dynamic config (recursiveUpdate, not overridable), and Traefik takes a
  # filename or a directory, not both. So the static config is generated
  # here instead, with the module's dynamic config linked into the
  # directory next to the maintenance routers.
  traefikCfg = config.services.traefik;
  toml = pkgs.formats.toml { };
  traefikDynamicFile = toml.generate "traefik-dynamic.toml" traefikCfg.dynamicConfigOptions;
  traefikStaticFile = toml.generate "traefik-static.toml" (
    lib.recursiveUpdate traefikCfg.staticConfigOptions {
      providers.file = {
        directory = cfg.traefik.dynamicDir;
        watch = true;
      };
    }
  );

  maintenanceCli = pkgs.writeShellApplication {
    name = "maintenance";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      dir=${flagDir}
      known=(${lib.escapeShellArgs knownNames})
      traefik=${lib.boolToString cfg.traefik.enable}

      usage() {
        echo "usage: maintenance on <fqdn|all> [reason ...]" >&2
        echo "       maintenance off <fqdn|all>" >&2
        echo "       maintenance status" >&2
        exit 1
      }

      check_name() {
        [[ "$1" =~ ^[a-z0-9][a-z0-9.-]*$ ]] || { echo "invalid name: $1" >&2; exit 1; }
        [ "$1" = all ] && return 0
        local k
        for k in "''${known[@]}"; do [ "$k" = "$1" ] && return 0; done
        echo "warning: $1 is not a maintenance name on $(hostname) (known: ''${known[*]:-none})" >&2
      }

      sync() {
        if [ "$traefik" = true ]; then systemctl start maintenance-traefik-sync.service; fi
      }

      case "''${1:-}" in
        on)
          [ $# -ge 2 ] || usage
          check_name "$2"
          name=$2; shift 2
          printf '%s\n' "$*" > "$dir/.$name.tmp"
          chmod 0644 "$dir/.$name.tmp"
          mv "$dir/.$name.tmp" "$dir/$name"
          sync
          echo "maintenance on: $name''${*:+ ($*)}"
          ;;
        off)
          [ $# -eq 2 ] || usage
          check_name "$2"
          rm -f "$dir/$2"
          sync
          echo "maintenance off: $2"
          ;;
        status)
          found=0
          for f in "$dir"/*; do
            [ -f "$f" ] || continue
            found=1
            printf '%s\t%s\t%s\n' "$(basename "$f")" "$(date -r "$f" '+%F %R')" "$(head -c 200 "$f")"
          done
          [ $found = 1 ] || echo "no maintenance on $(hostname)"
          ;;
        *) usage ;;
      esac
    '';
  };
in
{
  options.services.maintenance = {
    enable = lib.mkEnableOption "maintenance mode and error pages for the host's web front (nginx/Traefik)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8089;
      description = "Loopback port of the responder that renders the maintenance and error pages.";
    };

    retryAfter = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Retry-After (seconds) on the 503 maintenance page.";
    };

    cookieDomain = lib.mkOption {
      type = lib.types.str;
      default = "homelab.example";
      description = "Domain of the bypass cookie: one cookie for every service below it.";
    };

    cookieMaxAge = lib.mkOption {
      type = lib.types.ints.positive;
      default = 43200;
      description = "Lifetime of the bypass cookie in seconds (default 12 h).";
    };

    nginx = {
      vhosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "cloud.homelab.example" ];
        description = ''
          nginx virtualHosts (attribute names) that can be switched to
          maintenance and show the error page for nginx's own 502/504. The
          flag is looked up by the vhost's server name. Mind the allow/deny
          caveat in the module header.
        '';
      };

      errorPagesOnly = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "nginx virtualHosts that only get the 502/504 page, no maintenance switch.";
      };
    };

    traefik = {
      enable = lib.mkEnableOption "maintenance routers and the 502/504 page in Traefik";

      entryPoint = lib.mkOption {
        type = lib.types.str;
        default = "apps";
        description = ''
          The entrypoint the maintenance routers, the error middleware's
          users and the fallback router live on. Only that one: the NetBird
          control plane on websecure must never be put into maintenance.
        '';
      };

      names = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Names Traefik serves on the entrypoint - only for the `maintenance` command's sanity check.";
      };

      dynamicDir = lib.mkOption {
        type = lib.types.str;
        default = "/run/traefik-dynamic";
        description = "Directory Traefik's file provider watches.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = map (n: {
        # A typo would silently create a new vhost with only this module's
        # locations in it.
        assertion = nginxCfg.virtualHosts ? ${n} && nginxCfg.virtualHosts.${n}.locations ? "/";
        message = "services.maintenance.nginx: virtualHost ${n} does not exist (or has no location /)";
      }) (cfg.nginx.vhosts ++ cfg.nginx.errorPagesOnly);

      warnings = lib.optional (!hasToken)
        "maintenance: no hosts/${host}/maintenance.yaml - the bypass cookie is disabled; run `just maintenance-token`.";

      systemd.tmpfiles.rules = [ "d ${flagDir} 0755 root root -" ];

      environment.systemPackages = [ maintenanceCli ];

      sops.secrets."maintenance_bypass_token" = lib.mkIf hasToken {
        sopsFile = tokenFile;
        restartUnits = [ "maintenance-responder.service" ]
          ++ lib.optional cfg.traefik.enable "maintenance-traefik-sync.service";
      };

      systemd.sockets.maintenance-responder = {
        description = "Maintenance and error page responder";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ "127.0.0.1:${toString cfg.port}" ];
      };

      systemd.services.maintenance-responder = {
        description = "Maintenance and error page responder";
        requires = [ "maintenance-responder.socket" ];
        environment = {
          NIXLAB_MAINT_DIR = flagDir;
          NIXLAB_MAINT_PAGE = "${./maintenance/page.html}";
          NIXLAB_MAINT_COOKIE = cookieName;
          NIXLAB_MAINT_COOKIE_DOMAIN = cfg.cookieDomain;
          NIXLAB_MAINT_COOKIE_MAX_AGE = toString cfg.cookieMaxAge;
          NIXLAB_MAINT_RETRY_AFTER = toString cfg.retryAfter;
          PYTHONUNBUFFERED = "1";
        };
        serviceConfig = {
          ExecStart = "${python.interpreter} -I ${./maintenance/responder.py}";
          LoadCredential = lib.mkIf hasToken [ "bypass-token:${tokenPath}" ];
          DynamicUser = true;
          Restart = "on-failure";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          CapabilityBoundingSet = "";
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" "~@privileged" ];
          UMask = "0077";
        };
      };
    }

    # --- nginx ---------------------------------------------------------------
    (lib.mkIf (cfg.nginx.vhosts != [ ] || cfg.nginx.errorPagesOnly != [ ]) {
      # Who skips the check: the bypass endpoints themselves, and the
      # holder of the cookie. nginx's `if` has no "and"/"or", so the parts
      # are combined in maps; an empty value is false.
      services.nginx.appendHttpConfig = ''
        map $uri $nixlab_maint_path {
          ~^/_maintenance/ 1;
          default "";
        }
        ${if hasToken then "include ${config.sops.templates."nginx-maintenance-bypass.conf".path};" else ''
          map $cookie_${cookieName} $nixlab_maint_cookie {
            default "";
          }''}
        map "$nixlab_maint_path$nixlab_maint_cookie" $nixlab_maint_exempt {
          "" "";
          default 1;
        }
      '';

      # The token stays out of the world-readable store: a map rendered by
      # sops-nix at activation, included at runtime (nginx -t runs on the
      # host, where it exists).
      sops.templates."nginx-maintenance-bypass.conf" = lib.mkIf hasToken {
        owner = "nginx";
        content = ''
          map $cookie_${cookieName} $nixlab_maint_cookie {
            default "";
            "${config.sops.placeholder."maintenance_bypass_token"}" 1;
          }
        '';
        reloadUnits = [ "nginx.service" ];
      };

      services.nginx.virtualHosts = lib.mkMerge (
        map (n: {
          ${n} = {
            # $server_name rather than the name at build time: same flag for
            # every vhost of one name (dokumente: 443 and the proxy's 8092).
            extraConfig = lib.mkAfter ''
              set $nixlab_maint "";
              if (-f ${flagDir}/all) { set $nixlab_maint 1; }
              if (-f ${flagDir}/$server_name) { set $nixlab_maint 1; }
              if ($nixlab_maint_exempt) { set $nixlab_maint ""; }
              if ($nixlab_maint) { return 503; }
              error_page 502 503 504 @nixlab_maintenance;
            '';
            locations."^~ /_maintenance/" = {
              proxyPass = responderUrl;
              recommendedProxySettings = false;
              extraConfig = ''
                proxy_set_header Host $host;
              '';
            };
          };
        }) cfg.nginx.vhosts
        ++ map (n: {
          ${n}.extraConfig = lib.mkAfter ''
            error_page 502 504 @nixlab_maintenance;
          '';
        }) cfg.nginx.errorPagesOnly
        ++ map (n: {
          # The status goes along as a header: a named location's
          # proxy_pass cannot carry a path. GET without the body - an S3 PUT
          # that ran into a 502 has nothing to send to the page.
          ${n}.locations."@nixlab_maintenance" = {
            proxyPass = responderUrl;
            recommendedProxySettings = false;
            extraConfig = ''
              proxy_method GET;
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
              proxy_set_header Host $host;
              proxy_set_header X-Nixlab-Status $status;
            '';
          };
        }) (cfg.nginx.vhosts ++ cfg.nginx.errorPagesOnly)
      );
    })

    # --- Traefik -------------------------------------------------------------
    (lib.mkIf cfg.traefik.enable {
      services.traefik.staticConfigFile = traefikStaticFile;

      services.traefik.dynamicConfigOptions.http = {
        services.nixlab-maintenance.loadBalancer.servers = [ { url = responderUrl; } ];

        # Only 502/504: unlike nginx's error_page, this middleware also
        # replaces the service's own responses, and a 503 with JSON from
        # Grafana should stay JSON.
        middlewares.nixlab-errors.errors = {
          status = [ "502" "504" ];
          service = "nixlab-maintenance";
          query = "/_nixlab_status/{status}";
        };

        routers = {
          # The bypass form, always reachable, whatever else matches.
          nixlab-maintenance-path = {
            entryPoints = [ cfg.traefik.entryPoint ];
            rule = "PathPrefix(`/_maintenance/`)";
            priority = 20000;
            service = "nixlab-maintenance";
          };
          # Names nothing else serves get the maintenance page instead of a
          # bare 404 - which is also what the NetBird proxy reaches when a
          # service elsewhere is switched over here (terraform/netbird,
          # proxy-maintenance.json).
          nixlab-maintenance-fallback = {
            entryPoints = [ cfg.traefik.entryPoint ];
            rule = "PathPrefix(`/`)";
            priority = 1;
            service = "nixlab-maintenance";
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.traefik.dynamicDir} 0750 traefik traefik -"
        "L+ ${cfg.traefik.dynamicDir}/nixos.toml - - - - ${traefikDynamicFile}"
      ];

      systemd.services.maintenance-traefik-sync = {
        description = "Write Traefik's maintenance routers from the flag files";
        wantedBy = [ "traefik.service" ];
        before = [ "traefik.service" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.escapeShellArgs [
            python.interpreter "-I" "${./maintenance/traefik-sync.py}"
            flagDir "${cfg.traefik.dynamicDir}/maintenance.yml" "traefik"
            cfg.traefik.entryPoint "nixlab-maintenance" cookieName
            (if hasToken then tokenPath else "")
          ];
        };
      };

      # The directory is watched, but a changed dynamic config should not
      # depend on that: restart like the module does when its file changes.
      systemd.services.traefik.restartTriggers = [ traefikDynamicFile ];
    })
  ]);
}
