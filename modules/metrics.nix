# Per-node metrics exporters.
#
# Everything here binds 0.0.0.0 and stays off the public internet through the
# firewall rather than through bind addresses: modules/firewall.nix opens only
# 22/80/443 to the world and trusts tailscale0 wholesale, so an exporter that
# is not in allowedTCPPorts is reachable over the tailnet and nowhere else.
#
# Binding the Tailscale address directly would be tighter, but tailscale0 does
# not exist yet when these units start at boot, and a listener cannot bind an
# address that is not there. The firewall is the more robust guard.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";
in
{
  services.prometheus.exporters = {
    # Host basics: CPU, memory, load, filesystem fill, disk I/O, network,
    # uptime. The systemd collector is the reason this is first on the list -
    # it exports the state of every unit, which is what turns "crowdsec has
    # been restart-looping for ten minutes" from something you notice by
    # chance into something that pages you.
    node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "processes"
        "textfile"
      ];
      extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
    };

    # Certificate expiry read off disk. ACME renews on its own until the day it
    # does not - a DNS-01 failure against deSEC is silent, and the cert is
    # simply not replaced. 90 days is plenty of time to notice, but only if
    # something is looking.
    node-cert = {
      enable = true;
      paths = [ "/var/lib/acme" ];
    };
  };

  # node-cert-exporter (amimof/node-cert-exporter) apparently walks
  # /var/lib/acme once and keeps serving that result - confirmed live on
  # grammi on 2026-08-17: a process running 2 days straight kept reporting
  # zero certificates for 5 vhosts whose ACME directories were only a few
  # hours old, until a plain `systemctl restart` picked them up instantly.
  # No documented rescan-interval flag exists upstream (checked), so two
  # independent fixes instead of relying on one:
  #
  # 1. Event-driven: restart it every time ANY cert on this host is newly
  #    issued or renewed. reloadServices runs `systemctl try-reload-or-restart`
  #    after ACME succeeds - the exporter has no ExecReload, so that's a full
  #    restart, which is exactly what fixed this manually just now.
  security.acme.defaults.reloadServices = [ "prometheus-node-cert-exporter.service" ];

  # 2. Backstop: in case reloadServices ever misses a run (e.g. the very
  #    first issuance of a brand new vhost, before this hook existed, is
  #    exactly what happened today), force a restart daily regardless. Cheap
  #    insurance - a few seconds of scrape gap once a day beats a silently
  #    stale certificate-expiry dashboard for however long nobody notices.
  systemd.services.prometheus-node-cert-exporter.serviceConfig = {
    RuntimeMaxSec = "1d";
    Restart = lib.mkForce "always";
    RestartSec = "5s";
  };

  services.prometheus.exporters.nginx = lib.mkIf config.services.nginx.enable {
    enable = true;
  };

  # nginx's stub_status, which the exporter above reads. Bound to localhost by
  # the nginx module; only the exporter needs it.
  services.nginx.statusPage = lib.mkIf config.services.nginx.enable true;

  # Status codes and request rates per vhost, parsed from the access log. The
  # nginx exporter above only reports connection counts; this is the one that
  # would have shown a wall of 429s the moment the rate limit started eating
  # pocket-id's asset requests.
  services.prometheus.exporters.nginxlog = lib.mkIf config.services.nginx.enable {
    enable = true;
    settings.namespaces = [
      {
        name = "nginx";
        # NixOS' nginx writes the standard combined format.
        format = ''$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'';
        source.files = [ "/var/log/nginx/access.log" ];
      }
    ];
  };

  # /var/log/nginx is drwxr-x--- nginx:nginx, so the exporter needs the group
  # to read the log at all - the same obstacle CrowdSec hit, with the same
  # silent failure mode: the service runs, it just never sees a line.
  systemd.services.prometheus-nginxlog-exporter.serviceConfig.SupplementaryGroups =
    lib.mkIf config.services.nginx.enable [ "nginx" ];

  # tailscaled has no scrapeable endpoint - `tailscale metrics` only offers
  # `print` and `write`, both producing Prometheus text format. That is exactly
  # what node_exporter's textfile collector consumes, so the bridge is a timer
  # writing a file rather than another listener.
  #
  # Written to a temporary name and renamed, because the collector reads
  # whatever is in the directory whenever it is scraped: without the atomic
  # rename it would eventually parse a half-written file and report an error
  # instead of the metrics.
  systemd.tmpfiles.settings."10-node-exporter-textfile".${textfileDir}.d = {
    user = "root";
    group = "root";
    # World-readable on purpose: the writer is this root oneshot, the reader is
    # node_exporter under a DynamicUser that shares no group with it.
    mode = "0755";
  };

  # Only where tailscaled runs: cuckoosegg (NetBird only) does not import
  # modules/tailscale.nix, and the timer would fail there every 30 s.
  systemd.services.tailscale-metrics = lib.mkIf config.services.tailscale.enable {
    description = "Tailscale client metrics for node_exporter's textfile collector";
    after = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "tailscale-metrics-write" ''
        set -euo pipefail
        ${pkgs.tailscale}/bin/tailscale metrics write ${textfileDir}/tailscale.prom.tmp
        chmod 0644 ${textfileDir}/tailscale.prom.tmp
        mv ${textfileDir}/tailscale.prom.tmp ${textfileDir}/tailscale.prom
      '';
    };
  };

  systemd.timers.tailscale-metrics = lib.mkIf config.services.tailscale.enable {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
    };
  };
}
