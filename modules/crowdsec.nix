# Known issues with the nixpkgs modules, all found the hard way:
#   - services.crowdsec-firewall-bouncer with registerBouncer.enable destroys
#     the engine's state directory (see the disabled block below). Do not
#     re-enable it; use secrets.apiKeyPath with a hand-registered bouncer.
#   - Console enrolment is broken twice over: the setup script's enrolment step
#     never runs (inverted condition, see the note below), and console_path
#     defaults to a Nix store path, so doing it by hand fails too until that is
#     redirected somewhere writable.
#   - The generated config sets api.server.listen_uri to 127.0.0.1:8080 by
#     default, which collides with anything else on that port - garage-ui here.
#   - Changing listen_uri does not update an already written
#     local_api_credentials.yaml; delete it (and the machine) to have the setup
#     script regenerate it, or the agent keeps dialling the old port.
#   - Setting capi.credentialsFile creates a chicken-and-egg: `cscli machine
#     add` runs before `cscli capi register` in the setup script but needs the
#     file the latter creates. Bootstrap once with `cscli capi register`.
#   - settings.general.api.server.enable defaults to false and both credential
#     paths default to null; all three must be set or the agent dies with
#     "no API client section in configuration".
#   - The module creates its directories via systemd.tmpfiles, not
#     StateDirectory=. Removing /var/lib/crowdsec by hand breaks the unit's
#     mount namespace until `systemd-tmpfiles --create` re-creates them.
#
# ---------------------------------------------------------------------------
# CrowdSec, one self-contained Security Engine per host.
#
# Each host runs all three parts locally: the agent (parses logs, applies
# scenarios), the Local API on 127.0.0.1:8080 (holds decisions, pulls the
# community blocklist), and the firewall bouncer (enforces them as nftables
# rules). No host depends on the other - a deliberate choice for a two-host
# setup, where a central LAPI would buy little beyond what the shared
# community blocklist already covers, at the price of coupling both hosts to
# one machine and to the mesh being up.
#
# What this is actually for: SSH here is key-only with root confined to the
# mesh (modules/ssh.nix), so the constant bot noise on port 22 cannot
# succeed and CrowdSec mostly quiets the logs. The real target is port 443 -
# pocket-id on zummi is an OIDC provider and the one place where credentials
# can be guessed, and aldrin exposes Garage's S3 API.
{
  config,
  lib,
  pkgs,
  inventory,
  ...
}:
let
  # Groups whose log directories CrowdSec reads (see the bottom of the file).
  logGroups =
    lib.optional config.services.nginx.enable "nginx"
    ++ lib.optional config.services.traefik.enable "traefik";

  buckets = config.services.crowdsecBuckets;

  # The home line: its dyndns name (kept current by gruffi,
  # openwrt/gruffi/ddns-home.sh) and the prefix it delegates.
  home = inventory.uplinks.home;

  # For the nightly hub upgrade (see crowdsec-update-hub below), all read from
  # the nixpkgs module instead of repeated here. The cscli wrapper is the one
  # it puts on the system path, with the generated config baked in; the config
  # test is crowdsec.service's own `crowdsec -c <config> -t` start step.
  findOrThrow =
    what: pred: list:
    lib.findFirst pred (throw "modules/crowdsec.nix: no ${what} in the nixpkgs crowdsec module") list;
  cscli = findOrThrow "cscli wrapper" (p: lib.getName p == "cscli") config.environment.systemPackages;
  configTest =
    findOrThrow "config test step" (lib.hasSuffix " -t -error")
      config.systemd.services.crowdsec.serviceConfig.ExecStartPre;
  csPaths = config.services.crowdsec.settings.general.config_paths;
  hubDirs = lib.unique [
    csPaths.hub_dir
    csPaths.data_dir
  ];
  dbPath = config.services.crowdsec.settings.general.db_config.db_path;
in
{
  imports = [ ./crowdsec-dynamic-allow.nix ];

  # S3 clients look like scanners to the HTTP scenarios (see the whitelist
  # below), so their bucket traffic is exempted - but only on the vhost that
  # serves the buckets, recognised by its own access log.
  options.services.crowdsecBuckets = {
    vhost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "s3.example.org";
      description = ''
        nginx virtualHost (attribute name) that serves the S3 API. It gets
        its own access log, and only lines from that log can be exempted.
        null: no bucket whitelist on this host.
      '';
    };

    buckets = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[a-z0-9][a-z0-9-]*");
      default = [ ];
      example = [
        "backups"
        "nix-cache"
      ];
      description = "Bucket names (path-style) whose ordinary traffic is not counted.";
    };

    logFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      default =
        if config.services.crowdsecBuckets.vhost == null then
          null
        else
          "/var/log/nginx/${config.services.crowdsecBuckets.vhost}.log";
      defaultText = lib.literalExpression ''"/var/log/nginx/''${vhost}.log"'';
      description = ''
        The vhost's access log, in nginx's combined format, for anything else
        that reads nginx's access logs. Matches /var/log/nginx/*.log, so
        CrowdSec and logrotate pick it up without further configuration.
      '';
    };
  };

  config = {
    # Never ban the home line for noise (admin/nixlab#444). Its address is
    # dynamic, so it cannot go into homelab/lab-hosts below; the dyndns name
    # is resolved when a scenario overflows (modules/crowdsec-dynamic-allow.nix).
    # Only the scenarios that banned it before - a workstation running
    # `tofu apply`, a load test of the public path, a client sending junk -
    # so brute force, CVE probes and the WAF's own scenarios still ban a
    # compromised device or a guest at home. If that turns out too narrow,
    # the fallback is scenarios = [ ] (all of them).
    services.crowdsecDynamicAllow = {
      name = home.dyndnsName or null;
      whitelistName = "homelab/home-line";
      ipv6PrefixLength = home.ipv6PrefixLength;
      scenarios = [
        "crowdsecurity/http-crawl-non_statics"
        "crowdsecurity/http-probing"
      ]
      ++ lib.optional config.services.nginx.enable "homelab/http-malformed-request";
    };

    services.crowdsec = {
      enable = true;

      # Console enrollment. This is what separates CrowdSec from fail2ban: the
      # host reports its own alerts (attacker IP, scenario, timestamp) and in
      # return receives the community blocklist, i.e. addresses that already
      # misbehaved elsewhere - blocking them before they ever reach us.
      #
      # The token is an account-level enrolment key from app.crowdsec.net; the
      # same value goes into both hosts' secrets.yaml.
      settings.console.tokenFile = config.sops.secrets."crowdsec_enroll_token".path;

      # Each host runs its own Local API. The module defaults this to false, and
      # without it the agent has nothing to talk to: the setup script's
      # `cscli machine add --auto` step is itself gated on api.server.enable, so
      # no local credentials get created and crowdsec dies at startup with
      # "loading api client: no API client section in configuration".
      settings.general.api.server.enable = true;

      # Off CrowdSec's default 127.0.0.1:8080, which collides with garage-ui on
      # aldrin - that listens on 8080 (served on the mesh by nginx).
      # Kept identical on both hosts so the two stay comparable, and so a
      # bouncer's api_url does not have to differ per host.
      settings.general.api.server.listen_uri = "127.0.0.1:8081";

      # CrowdSec's own Prometheus metrics (parsed lines per source, bucket
      # overflows, alerts, active decisions per origin), on loopback like
      # every exporter (modules/metrics.nix, nixlab#15): the host's own
      # vmagent scrapes them there (modules/metrics-shipping.nix).
      settings.general.prometheus.listen_addr = "127.0.0.1";

      # `cscli console enroll` rewrites the console config in place, so it cannot
      # live in the Nix store where the module puts it by default - enrolment
      # fails with "read-only file system". Point it at the state directory,
      # which is writable by the crowdsec user, and let cscli create it.
      settings.general.api.server.console_path = "/var/lib/crowdsec/state/console.yaml";

      # Both credential paths default to null, which leaves api.client without a
      # credentials_path - the other half of the same failure. These files are
      # generated at runtime (machine add / capi register), so they need a
      # directory the crowdsec user may write to.
      #
      # That means below stateDir, not next to it. The module creates its
      # directories via systemd.tmpfiles with owner crowdsec, but the list covers
      # the subdirectories - /var/lib/crowdsec itself ends up created implicitly
      # as root:root. ReadWritePaths=/var/lib/crowdsec only lifts the namespace
      # restriction, it does not change POSIX permissions, so writing straight
      # into the root directory fails with "permission denied" even though the
      # unit is allowed to write there.
      settings.lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
      settings.capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";

      # Refreshes the hub index daily; the override further down upgrades the
      # installed items against it and reloads the engine only when that
      # changed something (#487).
      autoUpdateService = true;

      # NOTE: setting console.tokenFile above does NOT actually enrol the host.
      # The module's setup script guards the enrolment with
      #   if [ ! -e "${tokenFile}" ]; then cscli console enroll "$(cat tokenFile)"
      # i.e. it only runs when the token file is absent, and then reads the file
      # it just established does not exist. The condition is inverted, so with a
      # token present the step is silently skipped. Enrol once by hand instead:
      #   cscli console enroll <key> --name <hostname>
      # and confirm the machine in the CrowdSec console.

      hub.collections = [
        # sshd parsers + brute-force scenarios, plus the base linux set.
        "crowdsecurity/linux"
      ]
      ++ lib.optional config.services.nginx.enable "crowdsecurity/nginx"
      ++ lib.optional config.services.traefik.enable "crowdsecurity/traefik";

      # Never ban the lab's own machines.
      #
      # This is not cosmetic: zummi's restic job backs up to
      # s3:https://s3.aldrin.homelab.example nightly at 02:30, over aldrin's *public*
      # address and therefore straight through nginx and into CrowdSec. A backup
      # run is an S3 client issuing a large burst of requests, which is exactly
      # the shape of crowdsecurity's http-dos / http-crawl scenarios. Without
      # this whitelist CrowdSec would eventually ban zummi on aldrin and the
      # backups would fail quietly - services.restic simply errors and nobody
      # looks.
      #
      # The addresses are listed for the whole lab rather than per host, so each
      # machine also refuses to ban the other. The mesh ranges cover anything
      # arriving over NetBird, which is trusted at the firewall anyway.
      localConfig.parsers.s02Enrich = [
        {
          name = "homelab/lab-hosts";
          description = "Never ban the lab's own machines";
          whitelist = {
            reason = "own infrastructure";
            ip = [
              "203.0.113.10" # zummi v4
              "2001:db8:10::1" # zummi v6
              "203.0.113.11" # aldrin v4
              "2001:db8:11::2" # aldrin v6
              "203.0.113.12" # grammi v4
              "2001:db8:12::2" # grammi v6
            ];
            cidr = config.lab.mesh.networks; # the NetBird mesh, both ranges
          };
        }
      ]
      # S3 buckets (services.crowdsecBuckets), by path rather than by IP,
      # because a client's address may be dynamic. Every S3 client looks like
      # a scanner:
      #  - A Nix binary cache: a substituter asks for one narinfo per store
      #    path it might need, and most of them are 404 by design.
      #    crowdsecurity/http-probing banned a whole home network on
      #    2026-10-31, minutes into the first nightly prebuild.
      #  - restic: its GETs for many distinct objects are
      #    http-crawl-non_statics to the letter. Bans every 4 h from 2026-11-07
      #    made a nightly backup fail and lost another client's uploads.
      # Three conditions, all of them needed:
      #  - The line comes from the S3 vhost's own log (evt.Line.Src is the
      #    file, nothing a client can influence). With one access log for all
      #    vhosts, a scanner prefixing its probes with a bucket path was exempt
      #    on every vhost of the host (#307).
      #  - The path is one of the buckets.
      #  - The status is one ordinary bucket traffic produces: 2xx/3xx, 404
      #    for a cache miss, 5xx when the backend is down and clients retry
      #    (restic, nix-cache, an S3 SDK, two weeks of aldrin's log). 400,
      #    401, 403 and 405 - wrong keys, unsigned probes - still count.
      ++ lib.optional (buckets.vhost != null && buckets.buckets != [ ]) {
        name = "homelab/s3-buckets";
        description = "Ordinary S3 client traffic against the buckets";
        whitelist = {
          reason = "S3 bucket traffic";
          expression = [
            "evt.Line.Src == '${buckets.logFile}' && evt.Meta.log_type == 'http_access-log' && evt.Parsed.request matches '^/(${lib.concatStringsSep "|" buckets.buckets})([/?]|$)' && evt.Meta.http_status matches '^([235][0-9][0-9]|404)$'"
          ];
        };
      }
      # NetBird's machine traffic on grammi - REST API, gRPC (signal/
      # management), relay and WebSocket proxy, by Traefik router name
      # (hosts/grammi/netbird.nix). All of it is authenticated (API token,
      # WireGuard keys), there is nothing to guess - but `tofu apply` alone
      # fetches dozens of distinct /api/... paths within seconds, exactly the
      # shape of crowdsecurity/http-crawl-non_statics. It banned the home IP on
      # 2026-10-18 (and the day before), which locked the workstation out of
      # the mesh. The login (/oauth2/), the dashboard and /api/setup stay
      # under CrowdSec. (With nginx this was a separate log CrowdSec skipped.)
      ++ lib.optional config.services.traefik.enable {
        name = "homelab/netbird-machine-traffic";
        description = "NetBird API/gRPC/relay through Traefik - authenticated machine traffic";
        whitelist = {
          reason = "NetBird machine traffic";
          expression = [
            "evt.Meta.log_type == 'http_access-log' && evt.Parsed.traefik_router_name matches '^mesh-(grpc|relay|api)@'"
          ];
        };
      };

      # Clients whose request line is not HTTP at all - a TLS handshake on a
      # plain port, binary junk - get a 400 from nginx and nothing else.
      # crowdsecurity/nginx-logs parses such lines through a fallback pattern
      # without a verb. crowdsecurity/http-probing counts them, but only past
      # 10 distinct paths within about 10 s (replayed on aldrin); real
      # scanners send a handful at a time, so they never filled its bucket
      # (#13). Only nginx: Traefik's parser has no such fallback, and
      # well-formed 400s are left alone on purpose - API clients produce
      # plenty of them (NetBird's on grammi, OIDC token errors).
      #
      # 4 within about 30 min. Replayed against two weeks of aldrin's and
      # zummi's logs this caught 13 and 31 sources, none of them our own; a
      # threshold of 6 per minute caught 5 and 25, and on aldrin only sources
      # other scenarios had already caught. Custom scenarios are not shared
      # with the community blocklist, so a wrong ban stays local.
      localConfig.scenarios = lib.optional config.services.nginx.enable {
        type = "leaky";
        name = "homelab/http-malformed-request";
        description = "Requests that are not HTTP at all (nginx 400 without a request line)";
        filter = "evt.Meta.log_type == 'http_access-log' && evt.Parsed.program == 'nginx' && evt.Meta.http_status == '400' && evt.Parsed.verb == ''";
        groupby = "evt.Meta.source_ip";
        capacity = 3;
        leakspeed = "10m";
        blackhole = "5m";
        labels = {
          service = "http";
          confidence = 2;
          spoofable = 0;
          classification = [ "attack.T1595" ];
          behavior = "http:scan";
          label = "Malformed HTTP requests";
          remediation = true;
        };
      };

      localConfig.acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
      ]
      ++ lib.optional config.services.nginx.enable {
        source = "file";
        filenames = [ "/var/log/nginx/*.log" ];
        # Logs a vhost deliberately keeps away from CrowdSec: authenticated
        # machine traffic whose request pattern trips the HTTP scenarios (first
        # case: NetBird's API/gRPC on grammi, see hosts/grammi/netbird.nix).
        # Still in the glob for logrotate, which only knows /var/log/nginx/*.log.
        exclude_regexps = [ "\\.no-crowdsec\\.log$" ];
        labels.type = "nginx";
      }
      # Traefik's JSON access log (hosts/grammi/traefik.nix): only what Traefik
      # itself terminates - mesh.homelab.example and the "apps" entrypoint.
      ++ lib.optional config.services.traefik.enable {
        source = "file";
        filenames = [ "/var/log/traefik/access.log" ];
        labels.type = "traefik";
      };
    };

    # A server-level access_log replaces the inherited one, so the bucket
    # vhost's lines leave the shared access log for its own file.
    services.nginx.virtualHosts = lib.mkIf (buckets.vhost != null) {
      ${buckets.vhost}.extraConfig = ''
        access_log ${buckets.logFile} combined;
      '';
    };

    # Setting extraConfig above would silently create a mistyped vhost.
    assertions = lib.optional (buckets.vhost != null) {
      assertion = config.services.nginx.virtualHosts.${buckets.vhost}.locations != { };
      message = "services.crowdsecBuckets.vhost: no nginx virtualHost \"${buckets.vhost}\" with locations on this host";
    };

    # DISABLED - services.crowdsec-firewall-bouncer with registerBouncer.enable
    # is broken against services.crowdsec in this nixpkgs (crowdsec 1.7.7,
    # bouncer 0.0.34). Two separate faults, both upstream:
    #
    #  1. The register unit invokes the raw `cscli` from the package
    #     (lib.getExe' config.services.crowdsec.package "cscli") instead of the
    #     wrapper the crowdsec module builds. The raw binary insists on
    #     /etc/crowdsec/config.yaml, which the module never creates - the
    #     directory holds only subdirectories. Registration therefore always
    #     fails with "while reading yaml file: open /etc/crowdsec/config.yaml:
    #     no such file or directory", no API key is written, and the bouncer
    #     itself then dies at 243/CREDENTIALS looking for that key.
    #
    #  2. Worse, the register unit declares
    #     StateDirectory = "crowdsec-firewall-bouncer-register crowdsec"
    #     together with DynamicUser = true, while crowdsec.service uses the same
    #     `crowdsec` state directory without DynamicUser. systemd migrates
    #     /var/lib/crowdsec to /var/lib/private/crowdsec and leaves a symlink,
    #     after which crowdsec cannot start at all ("mkdir /var/lib/crowdsec:
    #     file exists"). Merely enabling the bouncer breaks the engine.
    #
    # Hence: register the bouncer by hand with `cscli bouncers add`, keep the key
    # in sops, and hand it over via secrets.apiKeyPath. That avoids both faults -
    # the register unit is only generated when registerBouncer.enable is set, and
    # the bouncer's own unit carries no StateDirectory that could collide.
    #
    # api_url needs no setting: it derives from
    # services.crowdsec.settings.general.api.server.listen_uri, so it follows the
    # move to :8081 automatically.
    #
    # The key differs per host - each host runs its own LAPI - so each
    # secrets.yaml carries its own value under the same name.
    services.crowdsec-firewall-bouncer = {
      enable = true;

      # Not a mkEnableOption - this defaults to true, and the module asserts that
      # it is mutually exclusive with secrets.apiKeyPath. Turning it off is what
      # keeps the destructive register unit from being generated at all.
      registerBouncer.enable = false;

      secrets.apiKeyPath = config.sops.secrets."crowdsec_bouncer_api_key".path;
    };

    sops.secrets."crowdsec_bouncer_api_key" = { };

    # crowdsec needs to read nginx's logs. /var/log/nginx is drwxr-x--- nginx
    # nginx, so without membership in that group the glob cannot even list the
    # directory and crowdsec reports "No matching files for pattern
    # /var/log/nginx/*.log" while the files are plainly there. The logs
    # themselves are 0640 nginx:nginx, i.e. group-readable, so membership is
    # enough - no permission changes on nginx's side.
    #
    # Both are set on purpose: extraGroups covers the NSS side, and
    # SupplementaryGroups the unit, because crowdsec.service runs with
    # DynamicUser=true where systemd does not necessarily honour /etc/group.
    #
    # The alternative would be to have nginx log to journald and read it with a
    # journalctl filter, which sidesteps file permissions entirely - worth
    # revisiting if the log paths ever move.
    # Same for Traefik's access log: /var/log/traefik is 0750 traefik:traefik
    # (hosts/grammi/traefik.nix).
    #
    # mkIf, not an empty list: defining users.users.crowdsec at all on a host
    # without either would create a half-declared user and fail evaluation.
    users.users.crowdsec.extraGroups = lib.mkIf (logGroups != [ ]) logGroups;
    systemd.services.crowdsec.serviceConfig.SupplementaryGroups = lib.mkIf (logGroups != [ ]) logGroups;

    # The nixpkgs module links local parsers under a name with the store hash
    # and never removes the old link, so every change to one leaves the previous
    # version in /etc/crowdsec until the store path is collected. The name inside
    # stays the same, and the old file went on shadowing the new one: grammi's
    # addresses were in homelab/lab-hosts on zummi and it was banned anyway
    # (2026-11-08). So before the start, drop every store link no tmpfiles rule
    # asks for. The same goes for homelab/detect-only after a switch to block.
    # After the module's own steps, which clear the list first; `+` for root,
    # the unit runs as crowdsec.
    systemd.services.crowdsec.serviceConfig.ExecStartPre = lib.mkAfter [
      "+${pkgs.writeShellScript "crowdsec-prune-links" ''
        set -eu
        ${config.systemd.package}/bin/systemd-tmpfiles --create --prefix=/etc/crowdsec
        ${pkgs.findutils}/bin/find /etc/crowdsec -type l -lname '/nix/store/*' -print |
          while read -r link; do
            ${pkgs.gnugrep}/bin/grep -qFs -- "$link" /etc/tmpfiles.d/*.conf || ${pkgs.coreutils}/bin/rm -v -- "$link"
          done
      ''}"
    ];

    # Nightly hub refresh: upgrade, then reload only if that changed anything
    # (#487).
    #
    # nixpkgs' crowdsec-update-hub.service runs `cscli hub update`, which only
    # fetches .index.json; installed items stay as they are. Its own
    # ExecStartPost (`systemctl reload crowdsec`) never worked: first "Access
    # denied" (the unit does not run as root - hence `+` below), then "Job type
    # reload is not applicable", because nixpkgs clears the ExecReload of
    # upstream's unit and sets none. Until #487 we restarted instead, and that
    # restart was the real upgrade: crowdsec.service's setup script runs
    # `cscli collections install`, which re-downloads installed items the new
    # index marks as outdated. But a restart leaves the AppSec listener
    # (127.0.0.1:7422) down for 10-40 s - setup script, `crowdsec -t` with the
    # CRS, start - and the bouncers pass everything unchecked meanwhile. Up to
    # 2026-11-19 that was 38 of 50 nginx "AppSec check: connection refused"
    # lines in 30 days, while only ~4 of 19 nights actually changed anything.
    #
    # Now the unit runs `cscli hub upgrade` itself (items and data files), and
    # reloads the engine only if the content of a file in the hub or data
    # directory changed. A reload is SIGHUP: crowdsec 1.7.8
    # handles it (cmd/crowdsec/serve.go, HandleSignals -> shutdown +
    # reloadHandler), skipping setup script and process start, so the listener
    # is down for the engine's own re-init only. It still drops it, and the
    # in-memory buckets go too, same as a restart.
    #
    # The upgrade runs as the unit's user, not as root, so no file under the
    # state directory ends up root-owned. Only the systemctl call needs `+`;
    # the two steps talk through a flag file in the unit's RuntimeDirectory.
    systemd.services.crowdsec-update-hub.serviceConfig = {
      RuntimeDirectory = "crowdsec-update-hub";
      ExecStartPost = lib.mkForce [
        "${pkgs.writeShellScript "crowdsec-hub-upgrade" ''
          set -eu
          # Content, not timestamps: for a data file past its 7-day shelf life
          # the downloader fetches it again and, if the content is the same,
          # still bumps its times (go-cs-lib downloader, os.Chtimes), so mtime
          # and ctime both claim a change that is not there.
          # The LAPI database lives in the data directory and changes all the
          # time; *.etag files are the downloader's cache validators.
          snapshot() {
            ${pkgs.findutils}/bin/find ${lib.escapeShellArgs hubDirs} -type f \
              ! -path ${lib.escapeShellArg dbPath} ! -path ${lib.escapeShellArg "${dbPath}-*"} ! -name '*.etag' -print0 |
              ${pkgs.coreutils}/bin/sort -zu | ${pkgs.findutils}/bin/xargs -0r ${pkgs.coreutils}/bin/sha256sum
          }
          snapshot >"$RUNTIME_DIRECTORY/before"
          ${lib.getExe cscli} --error hub upgrade
          snapshot >"$RUNTIME_DIRECTORY/after"
          if changed=$(${pkgs.diffutils}/bin/diff "$RUNTIME_DIRECTORY/before" "$RUNTIME_DIRECTORY/after"); then
            echo "hub upgrade changed nothing, no reload"
          else
            echo "hub upgrade changed:"
            echo "$changed" | ${pkgs.gnused}/bin/sed -n 's/^> [0-9a-f]*  //p'
            ${pkgs.coreutils}/bin/touch "$RUNTIME_DIRECTORY/reload"
          fi
        ''}"
        # try-reload-or-restart: a deliberately stopped engine stays stopped.
        "+${pkgs.writeShellScript "crowdsec-hub-reload" ''
          set -eu
          if [ -e "$RUNTIME_DIRECTORY/reload" ]; then
            ${config.systemd.package}/bin/systemctl try-reload-or-restart crowdsec.service
          fi
        ''}"
      ];
    };

    # Upstream's unit reloads with a config test first, then SIGHUP; nixpkgs
    # clears both. Same here: a config that fails the test never reaches the
    # running engine, the reload job fails and so does crowdsec-update-hub. A
    # SIGHUP that fails inside crowdsec makes it exit, and Restart=always with
    # RestartSec=60 then costs a minute - the test is what keeps that rare.
    # The test command is the module's own ExecStartPre step.
    systemd.services.crowdsec.serviceConfig.ExecReload = lib.mkAfter [
      configTest
      "${pkgs.coreutils}/bin/kill -HUP $MAINPID"
    ];

    # Must exist in *each* host's secrets.yaml before the first rebuild, or
    # activation fails. Note that this machine's own SSH host key is the only
    # thing that can decrypt it locally - so the secret has to be added with
    # `sops` on the host itself and the result committed back to the repo. That
    # step is easy to forget; garage_ui_oidc_client_secret sat uncommitted on
    # aldrin for a day for exactly this reason.
    sops.secrets."crowdsec_enroll_token" = { };
  };
}
