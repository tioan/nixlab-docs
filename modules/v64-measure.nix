# Measures what ipv64.net's v64 blocklist would add on top of CrowdSec,
# without blocking anything (admin/nixlab#171). Run for about 30 days, then
# decide: block with guardrails, or drop this module.
#
# The list: Honeypot64 by IPv64.net, CC BY 4.0, daily version without account
#   https://ipv64.net/blocklists/ipv64_blocklist_v64.txt
#   https://github.com/ipv64net/node64/blob/68b0c62fe986b490168e5ea9bc990d71f72022cc/docs/HONEYPOT64.md
# Attribution is required if it is ever used for blocking.
#
# Two counting points in the input hook, rules with `counter` and no verdict:
#   pre   priority filter - 10, before CrowdSec's bouncer and the firewall:
#         every packet from a listed source.
#   post  priority filter + 10, after both: what CrowdSec and nixos-fw let
#         through - the traffic v64 would actually have stopped in addition.
#
# NetBird's client watches for foreign input chains and puts an
# `iifname "nb-mesh" accept` at the top of each, these two included (seen on
# zummi 2026-11-15). Harmless here: accept only ends that base chain, CrowdSec
# and nixos-fw still see the packet, and mesh sources are never on the list.
#
# The table is this module's own, not in networking.nftables.tables: the
# nftables service deletes and re-creates its declared tables on every
# reload, which would empty the sets and reset the counters on each switch.
# v64-table creates the skeleton when it is missing; loading a list only
# replaces the set contents, in one nft transaction. Stopping v64-table (or
# removing this module) deletes the table.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.v64Measure;
  # Its own writer directory (modules/textfile-metrics.nix), shared by the
  # four units below, which all run as this user.
  user = "v64-measure";
  textfileDir = config.services.textfileMetrics.directories.${user}.path;
  # Creates that directory before the sandbox needs it (see the option).
  prepareDir = config.services.textfileMetrics.directories.${user}.execStartPre;
  # nft needs CAP_NET_ADMIN and a netlink socket; nothing here needs more.
  sandbox =
    extra:
    lib.recursiveUpdate {
      enable = true;
      level = "strict";
      network = "netlink";
      capabilities = [ "CAP_NET_ADMIN" ];
      umask = "0022";
      writablePaths = [ "-${textfileDir}" ];
    } extra;
  bouncer = config.services.crowdsec-firewall-bouncer.settings;
  stateDir = "/var/lib/v64-measure";
  url = "https://ipv64.net/blocklists/ipv64_blocklist_v64.txt";
  helper = "${pkgs.python3}/bin/python3 -I ${./v64-measure.py}";

  points = [
    {
      name = "pre";
      priority = "filter - 10";
    }
    {
      name = "post";
      priority = "filter + 10";
    }
  ];
  families = [
    {
      name = "ipv4";
      match = "ip saddr @v4";
    }
    {
      name = "ipv6";
      match = "ip6 saddr @v6";
    }
  ];

  overlapCmd = lib.concatStringsSep " " [
    helper
    "overlap"
    "${stateDir}/list.txt"
    "${textfileDir}/v64-overlap.prom"
    "ip"
    bouncer.nftables.ipv4.table
    bouncer.blacklists_ipv4
    "ip6"
    bouncer.nftables.ipv6.table
    bouncer.blacklists_ipv6
  ];

  # Replaces the set contents in one transaction; counters keep running.
  load = ''
    if [ -s ${stateDir}/list.txt ]; then
      ${helper} render ${stateDir}/list.txt ${stateDir}/load.nft ${textfileDir}/v64-list.prom
      nft -f ${stateDir}/load.nft
      ${overlapCmd} || echo "overlap failed, list loaded anyway"
    fi
  '';

  skeleton = pkgs.writeText "v64-skeleton.nft" ''
    table inet v64 {
      set v4 { type ipv4_addr; flags interval; auto-merge; }
      set v6 { type ipv6_addr; flags interval; auto-merge; }
    ${lib.concatMapStrings (
      p:
      lib.concatMapStrings (f: ''
        counter ${p.name}_${f.name} { }
      '') families
    ) points}
    ${
      lib.concatMapStrings (p: ''
          chain ${p.name} {
            type filter hook input priority ${p.priority}; policy accept;
        ${
          lib.concatMapStrings (f: ''
            ${f.match} counter name "${p.name}_${f.name}"
          '') families
        }  }
      '') points
    }}
  '';
in
{
  imports = [ ./textfile-metrics.nix ];

  options.services.v64Measure.enable = lib.mkEnableOption "counting traffic from ipv64.net's v64 blocklist";

  config = lib.mkIf cfg.enable {
    users.users.${user} = {
      isSystemUser = true;
      group = user;
      description = "v64 blocklist measurement";
    };
    users.groups.${user} = { };

    services.textfileMetrics.directories.${user}.legacyFiles = [
      "v64-counters.prom"
      "v64-list.prom"
      "v64-overlap.prom"
    ];

    # The table itself. Started before anything that uses it, loads the
    # cached list right away (a reboot or restart needs no download), and
    # deletes the table when stopped - removing this module removes it.
    systemd.services.v64-table = {
      description = "nftables table for counting ipv64's v64 blocklist";
      after = [ "nftables.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.nftables ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = user;
        ExecStartPre = [ prepareDir ];
        StateDirectory = "v64-measure";
        ExecStop = "${pkgs.nftables}/bin/nft delete table inet v64";
      };
      hardening = sandbox { };
      script = ''
        set -euo pipefail
        nft list table inet v64 > /dev/null 2>&1 || nft -f ${skeleton}
        ${load}
      '';
    };

    # Fetch (conditional, keeps the last good list), validate, load.
    systemd.services.v64-update = {
      description = "Fetch ipv64's v64 blocklist and load it, count only";
      requires = [ "v64-table.service" ];
      after = [
        "v64-table.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      path = [
        pkgs.nftables
        pkgs.curl
      ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStartPre = [ prepareDir ];
        StateDirectory = "v64-measure";
      };
      # The download: IP sockets to anywhere, on top of the netlink one.
      hardening = sandbox {
        network = "any";
        addressFamilies = [ "AF_NETLINK" ];
      };
      script = ''
        set -euo pipefail
        cd ${stateDir}

        # A failed download is not a failed run: the last good list stays.
        args=(--fail --silent --show-error --max-time 60 --remote-time
              --etag-save etag.new --output list.new --write-out '%{http_code}')
        if [ -s list.txt ]; then args+=(--time-cond list.txt); fi
        if [ -s etag ]; then args+=(--etag-compare etag); fi
        rm -f list.new etag.new
        if code=$(curl "''${args[@]}" ${url}); then
          if [ "$code" = 200 ] && ${helper} validate list.new; then
            mv list.new list.txt
            mv etag.new etag
          else
            echo "keeping the previous list (HTTP $code)"
          fi
        else
          echo "download failed, keeping the previous list"
        fi
        rm -f list.new etag.new

        if [ ! -s list.txt ]; then
          echo "no list yet"
          exit 1
        fi
        ${load}
      '';
    };

    systemd.timers.v64-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 04:00";
        RandomizedDelaySec = "1h";
        Persistent = true;
        # Also shortly after boot or first deploy, for the initial download.
        OnActiveSec = "1min";
      };
    };

    # Counters every minute (cheap: no set elements listed), the CrowdSec
    # overlap every 15 minutes (lists the bouncer's ~75k elements).
    systemd.services.v64-metrics = {
      description = "v64 blocklist counters for node_exporter's textfile collector";
      after = [ "v64-table.service" ];
      requisite = [ "v64-table.service" ];
      path = [
        pkgs.nftables
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStartPre = [ prepareDir ];
      };
      hardening = sandbox { };
      script = ''
        set -euo pipefail
        out=${textfileDir}/v64-counters.prom
        nft -j list counters table inet v64 | jq -r '
          [.nftables[] | select(.counter) | .counter | (.name | split("_")) as [$p, $f] | {p: $p, f: $f, bytes, packets}] as $c
          | "# HELP nixlab_v64_packets_total Packets from sources on the v64 list, by counting point.",
            "# TYPE nixlab_v64_packets_total counter",
            ($c[] | "nixlab_v64_packets_total{point=\"\(.p)\",family=\"\(.f)\"} \(.packets)"),
            "# HELP nixlab_v64_bytes_total Bytes from sources on the v64 list, by counting point.",
            "# TYPE nixlab_v64_bytes_total counter",
            ($c[] | "nixlab_v64_bytes_total{point=\"\(.p)\",family=\"\(.f)\"} \(.bytes)")
        ' > "$out.tmp"
        chmod 0644 "$out.tmp"
        mv "$out.tmp" "$out"
      '';
    };

    systemd.timers.v64-metrics = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "1min";
      };
    };

    systemd.services.v64-overlap = {
      description = "Overlap of the v64 blocklist with CrowdSec's decisions";
      # Nothing to compare before the first download: on the first deploy the
      # timer fired before v64-update had fetched a list, and the switch
      # reported the unit as failed.
      unitConfig.ConditionPathExists = "${stateDir}/list.txt";
      after = [ "v64-table.service" ];
      requisite = [ "v64-table.service" ];
      path = [ pkgs.nftables ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStartPre = [ prepareDir ];
      };
      hardening = sandbox { };
      script = overlapCmd;
    };

    systemd.timers.v64-overlap = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
      };
    };
  };
}
