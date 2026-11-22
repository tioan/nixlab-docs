# Reusable module: never let CrowdSec ban a client whose address is dynamic
# but tracked by a DNS name (a dyndns name for a home line). admin/nixlab#444.
#
# A postoverflow whitelist, not a parser whitelist and not a LAPI allowlist:
#  - Static whitelists cannot resolve names. CrowdSec's expr helper
#    LookupHost() can, and in the postoverflow stage it only runs when a
#    scenario has already overflowed - rarely, so one lookup each time costs
#    nothing and is never stale beyond the record's TTL. No timer, no list
#    to keep in sync, no token on the host.
#  - A failed lookup returns an empty list (LookupHost logs and swallows the
#    error), so the exemption fails closed: the ban happens as before.
#  - The lookup runs inline in CrowdSec's output loop. With DNS down, an
#    overflow of a listed scenario waits for the resolver's timeout (a few
#    seconds through resolved), and overflows behind it - an attack
#    included - wait with it. The scenario filter comes first, so only the
#    listed scenarios ever look up, and only while DNS is down. Accepted:
#    a ban seconds late, not a ban lost.
#  - LAPI allowlists (`cscli allowlists`) are also checked by the AppSec
#    runner, which then skips the in-band block for that address entirely
#    (pkg/acquisition/modules/appsec/appsec_runner.go in 1.7.8). Here the
#    WAF still answers 403; only the ban that would follow is dropped.
#  - What this does not cover: the community blocklist and decisions added
#    by hand, which only a LAPI allowlist filters.
#
# IPv6: the name's AAAA is one address of the line; every device behind it
# has its own from the delegated prefix, so the AAAA is widened to
# ipv6PrefixLength. Likewise ipv4PrefixLength (32: just the address).
#
# A whitelisted overflow is counted by CrowdSec itself, as
# cs_node_wl_hits_ok_total{name="<whitelistName>"}. Whether the name
# resolves at all is exported by a textfile writer, so a name that stopped
# resolving - and with it the exemption - shows up before the next ban does.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.crowdsecDynamicAllow;
  prefix = config.services.textfileMetrics.metricPrefix;

  quote = s: "'${s}'";
  scenarioFilter =
    lib.optionalString (cfg.scenarios != [ ])
      "evt.Overflow.Alert.Scenario in [${lib.concatMapStringsSep ", " quote cfg.scenarios}] && ";
  expression =
    scenarioFilter
    + "any(LookupHost('${cfg.name}'), { IpInRange(evt.Overflow.Alert.Source.IP, "
    + "IpToRange(#, # contains ':' ? '/${toString cfg.ipv6PrefixLength}' : '/${toString cfg.ipv4PrefixLength}')) })";
in
{
  imports = [ ./textfile-metrics-lab.nix ];

  options.services.crowdsecDynamicAllow = {
    name = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}");
      default = null;
      example = "home-ip.example.org";
      description = ''
        DNS name whose A/AAAA records are never banned. null: no exemption.
        Resolved through the host's resolver whenever a scenario overflows.
      '';
    };

    whitelistName = lib.mkOption {
      type = lib.types.str;
      default = "nixlab/dynamic-allow";
      description = "Name of the postoverflow whitelist, also the `name` label of cs_node_wl_hits_ok_total.";
    };

    scenarios = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "crowdsecurity/http-crawl-non_statics" ];
      description = ''
        Scenarios whose overflows are dropped for the name's addresses.
        Empty: all of them. A list keeps the attack scenarios (brute force,
        CVEs, AppSec) banning, so a compromised device behind the line is
        still caught.
      '';
    };

    ipv4PrefixLength = lib.mkOption {
      type = lib.types.ints.between 0 32;
      default = 32;
      description = "Prefix length the A record is widened to.";
    };

    ipv6PrefixLength = lib.mkOption {
      type = lib.types.ints.between 0 128;
      default = 64;
      description = "Prefix length the AAAA record is widened to: the delegated prefix of the line.";
    };

    expression = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      readOnly = true;
      default = if cfg.name == null then null else expression;
      defaultText = lib.literalMD "the generated expression, null without `name`";
      description = "The whitelist expression, for tests and documentation; null without a name.";
    };
  };

  config = lib.mkIf (cfg.name != null) {
    services.crowdsec.localConfig.postOverflows.s01Whitelist = [
      {
        name = cfg.whitelistName;
        description = "Never ban the addresses behind ${cfg.name}";
        whitelist = {
          reason = "dynamic address of ${cfg.name}";
          expression = [ expression ];
        };
      }
    ];

    # Whether the name resolves, per address family, as the host's resolver
    # sees it - the same one CrowdSec's Go resolver asks (resolv.conf).
    services.textfileMetrics.enable = true;
    services.textfileMetrics.writers.crowdsec-dynamic-allow = {
      description = "Textfile metrics: does ${cfg.name} resolve";
      path = [
        pkgs.getent
        pkgs.gawk
      ];
      hardening.network = "any";
      timer = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
      script = ''
        name=${lib.escapeShellArg cfg.name}
        echo "# HELP ${prefix}crowdsec_dynamic_allow_addresses Addresses the exempted name resolves to, by family."
        echo "# TYPE ${prefix}crowdsec_dynamic_allow_addresses gauge"
        # ahostsv6 maps A records to ::ffff:a.b.c.d; those are not AAAA.
        # --no-addrconfig: count the answer even on a host without that
        # address family configured - this is about the name.
        for fam in 4 6; do
          n=$({ getent --no-addrconfig "ahostsv$fam" "$name" || true; } | awk '$2 == "STREAM" && $1 !~ /^::ffff:/ { print $1 }' | sort -u | wc -l)
          echo "${prefix}crowdsec_dynamic_allow_addresses{name=\"$name\",family=\"ipv$fam\"} $n"
        done
        echo "# HELP ${prefix}crowdsec_dynamic_allow_last_run_timestamp_seconds When the lookup last ran."
        echo "# TYPE ${prefix}crowdsec_dynamic_allow_last_run_timestamp_seconds gauge"
        echo "${prefix}crowdsec_dynamic_allow_last_run_timestamp_seconds{name=\"$name\"} $(date +%s)"
      '';
    };
  };
}
