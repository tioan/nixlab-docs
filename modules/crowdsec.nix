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
# one machine and to the tailnet being up.
#
# What this is actually for: SSH here is key-only with root confined to the
# tailnet (modules/ssh.nix), so the constant bot noise on port 22 cannot
# succeed and CrowdSec mostly quiets the logs. The real target is port 443 -
# pocket-id on zummi is an OIDC provider and the one place where credentials
# can be guessed, and aldrin exposes Garage's S3 API.
{
  config,
  lib,
  ...
}:
let
  # Groups whose log directories CrowdSec reads (see the bottom of the file).
  logGroups =
    lib.optional config.services.nginx.enable "nginx"
    ++ lib.optional config.services.traefik.enable "traefik";
in
{
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
    # aldrin - that listens on 8080 and is what `tailscale serve` proxies to.
    # Kept identical on both hosts so the two stay comparable, and so a
    # bouncer's api_url does not have to differ per host.
    settings.general.api.server.listen_uri = "127.0.0.1:8081";

    # CrowdSec already exports Prometheus metrics (parsed lines per source,
    # bucket overflows, alerts, active decisions per origin) - they were just
    # bound to loopback, where a central Prometheus on another host cannot
    # reach them. Same reasoning as modules/metrics.nix: 6060 is not in
    # allowedTCPPorts and tailscale0 is trusted, so this stays tailnet-only.
    # Metrics carry no credentials, unlike the LAPI above, which stays local.
    settings.general.prometheus.listen_addr = "0.0.0.0";

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

    # Refreshes the hub index daily so new scenarios are picked up. Only the
    # index - it does not swap out parsers underneath a running system.
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
    # machine also refuses to ban the other. The CGNAT range covers anything
    # arriving over the tailnet, which is trusted at the firewall anyway.
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
          ];
          cidr = [
            "100.64.0.0/10" # tailnet
            "192.0.2.0/24" # NetBird mesh (terraform/netbird)
          ];
        };
      }
    ]
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
  systemd.services.crowdsec.serviceConfig.SupplementaryGroups =
    lib.mkIf (logGroups != [ ]) logGroups;

  # crowdsec-update-hub.service had failed every night since at least
  # 2026-08-13, and which step fails is the whole point: the
  # `cscli --error hub update` ExecStart exits 0, so the hub index really is
  # being refreshed. What fails is the unit's own ExecStartPost. It took two
  # rounds to see why, because the first fault hid the second:
  #
  #   1. As shipped it failed with "Access denied" (4/NOPERMISSION). The unit
  #      does not run as root, and asking the manager to act on a system unit
  #      needs an authorisation it does not have. systemd's `+` prefix runs
  #      that one command with full privileges, independently of
  #      User=/DynamicUser= and the unit's sandboxing - the manager checks
  #      authorisation before applicability, which is why this had to be
  #      cleared before the actual problem became visible.
  #   2. With that out of the way the real fault appeared: "Job type reload is
  #      not applicable for unit crowdsec.service" (3/NOTIMPLEMENTED). The
  #      module's crowdsec.service carries no ExecReload at all, so there is
  #      nothing to reload. Upstream's own unit has
  #      ExecReload=/bin/kill -HUP $MAINPID; nixpkgs dropped it.
  #
  # Restarting rather than re-adding that ExecReload: if this crowdsec build
  # does not install a SIGHUP handler, the default disposition terminates the
  # process, and discovering that at 00:04 unattended is not worth the saved
  # restart. `try-restart` and not `restart`, so a deliberately stopped engine
  # stays stopped instead of being started by a hub refresh. The cost is the
  # in-memory bucket state, once a day - a fair price for actually picking up
  # the index that was just downloaded.
  systemd.services.crowdsec-update-hub.serviceConfig.ExecStartPost =
    lib.mkForce "+${config.systemd.package}/bin/systemctl try-restart crowdsec.service";

  # Must exist in *each* host's secrets.yaml before the first rebuild, or
  # activation fails. Note that this machine's own SSH host key is the only
  # thing that can decrypt it locally - so the secret has to be added with
  # `sops` on the host itself and the result committed back to the repo. That
  # step is easy to forget; garage_ui_oidc_client_secret sat uncommitted on
  # aldrin for a day for exactly this reason.
  sops.secrets."crowdsec_enroll_token" = { };
}
