# Per-node metrics exporters.
#
# Every exporter here listens on 127.0.0.1 only (nixlab#15, decision 3b of
# 2026-11-01): each host's own vmagent scrapes them locally
# (modules/metrics-shipping.nix) and no host scrapes another, so nothing
# needs them on the mesh. Until 2026-11 they bound 0.0.0.0 and the firewall
# kept them off the internet - which left them open to every mesh peer the
# NetBird policies let through.
{ config, lib, ... }:
let
  nginxStatusPort = 8079;
  # The S3 vhost's own access log (modules/crowdsec.nix), where it exists.
  bucketLog = lib.attrByPath [ "services" "crowdsecBuckets" "logFile" ] null config;
in
{
  imports = [ ./textfile-metrics-lab.nix ];

  # The textfile directory and its writers: modules/textfile-metrics-lab.nix.
  services.textfileMetrics.enable = true;

  services.prometheus.exporters = {
    # Host basics: CPU, memory, load, filesystem fill, disk I/O, network,
    # uptime. The systemd collector is the reason this is first on the list -
    # it exports the state of every unit, which is what turns "crowdsec has
    # been restart-looping for ten minutes" from something you notice by
    # chance into something that pages you.
    node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [
        "systemd"
        "processes"
      ];
      extraFlags = [
        # node_network_address_info: the IPs per device. The MAC is already
        # in node_network_info. Compared with inventory.json by the
        # AddressNotInInventory rule (hosts/grammi/alerting/inventory.nix).
        "--collector.netdev.address-info"
      ];
    };

    # Certificate expiry read off disk. ACME renews on its own until the day it
    # does not - a DNS-01 failure against deSEC is silent, and the cert is
    # simply not replaced. 90 days is plenty of time to notice, but only if
    # something is looking.
    node-cert = {
      enable = true;
      listenAddress = "127.0.0.1";
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
    listenAddress = "127.0.0.1";
    scrapeUri = "http://127.0.0.1:${toString nginxStatusPort}/nginx_status";
  };

  # nginx's stub_status, which the exporter above reads; only the exporter
  # needs it. The nginx module would put this vhost on :80 on all addresses
  # without forceSSL, so `Host: localhost` got nginx's default page in plain
  # HTTP, from the internet on zummi. :80 only ever redirects (admin/nixlab#234),
  # hence a loopback-only port of its own.
  services.nginx = lib.mkIf config.services.nginx.enable {
    statusPage = true;
    virtualHosts.localhost.listen = [
      {
        addr = "127.0.0.1";
        port = nginxStatusPort;
      }
      {
        addr = "[::1]";
        port = nginxStatusPort;
      }
    ];
  };

  # Status codes and request rates per vhost, parsed from the access log. The
  # nginx exporter above only reports connection counts; this is the one that
  # would have shown a wall of 429s the moment the rate limit started eating
  # pocket-id's asset requests.
  services.prometheus.exporters.nginxlog = lib.mkIf config.services.nginx.enable {
    enable = true;
    listenAddress = "127.0.0.1";
    settings.namespaces = [
      {
        name = "nginx";
        # NixOS' nginx writes the standard combined format.
        format = ''$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'';
        source.files = [ "/var/log/nginx/access.log" ] ++ lib.optional (bucketLog != null) bucketLog;
      }
    ];
  };

  # /var/log/nginx is drwxr-x--- nginx:nginx, so the exporter needs the group
  # to read the log at all - the same obstacle CrowdSec hit, with the same
  # silent failure mode: the service runs, it just never sees a line.
  systemd.services.prometheus-nginxlog-exporter.serviceConfig.SupplementaryGroups =
    lib.mkIf config.services.nginx.enable
      [ "nginx" ];

  # CPU and memory per systemd service from its cgroup, every 15 s
  # (unit-cgroup-metrics.nix of the textfile-metrics input). Feeds the
  # "Homelab / ESPHome builds" dashboard; the same per-unit view for any
  # service on any host. Podman units count their containers as long as
  # they run with --cgroups=split (hosts/ursalia/esphome-builder.nix).
  services.unitCgroupMetrics.enable = true;
}
