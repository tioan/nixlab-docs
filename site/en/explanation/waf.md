# Web application firewall

On every host CrowdSec reads the nginx and Traefik access logs and bans addresses that stand out (`modules/crowdsec.nix`). That happens after the fact: the one request carrying an exploit has already reached the service. The WAF (`modules/waf.nix`, since 2026-10-25) checks each request before the proxy passes it on – with CrowdSec's AppSec component, so the same engine, the same alerts and the same bans. Since #4 (2026-11-16) it runs on all three front doors.

## Layout

| Part | What it does |
| --- | --- |
| AppSec (part of CrowdSec) | evaluates the rules on `127.0.0.1:7422`, raises alerts |
| nginx: OpenResty + Lua bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | zummi, aldrin: sends each request of the listed vhosts to AppSec in the access phase and acts on the answer; OpenResty replaces nginx (same NixOS module, Lua built in) |
| Traefik: CrowdSec plugin (`pkgs/crowdsec-traefik-plugin.nix`) | grammi: middleware `waf` on the routers that list it, loaded as a local plugin |
| Firewall bouncer | enforces bans in nftables as before, on every port |

`modules/waf.nix` holds no lab values; the host says which names go through it and how. `modules/waf-lab.nix` adds the lab's part: the bouncer key from `hosts/<host>/waf.yaml` (sops) and the metric for "AppSec answers".

## Rules

| Rules | Phase | Effect (block) |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – about 200 rules for known CVEs | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Method allowlist per name (`allowedMethods`) | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | no block; ban when the bucket overflows (capacity 5, one token leaks every 30 s) |

The IP is banned once two *different* in-band rules hit within 60 s (`crowdsecurity/appsec-vpatch`). The two own rules are the coarse net under the CVE rules: no public service here runs PHP, ASP, JSP or CGI.

## Modes, per name

`services.waf.mode` is the default, `services.waf.hosts."<name>".mode` overrides it:

- **`block`**: in-band matches get a 403, matches feed the ban scenarios.
- **`detect`**: in-band matches are answered with "allow" and their events are cancelled – nothing is blocked, no ban scenario sees them; the alerts stay (`cscli alerts list`). Every new name starts here for a week.

The log-based HTTP scenarios from `modules/crowdsec.nix` do not depend on the mode.

## Exceptions

All per name, under `services.waf.hosts."<name>"`:

- `exclusions = [ { rules = [ … ]; crsIds = [ … ]; paths/pathPrefixes/methods = [ … ]; } ]` – drop in-band rules (by name) or CRS rules (by ID) for the matching requests only.
- `allowedMethods = [ … ]` – any other method counts as a rule match.
- `skipInspection = [ { pathPrefixes = [ … ]; methods = [ … ]; } ]` – nginx only: the request is not sent to AppSec at all (large upload bodies; the bouncer would otherwise buffer them whole). Bans still apply.

| Name / path | Treatment | Why |
| --- | --- | --- |
| `auth.homelab.example` (Pocket ID) | block; CRS 931100 off on `/authorize` and `/api/oidc/token`; method allowlist | native OIDC clients log in with `redirect_uri=http://127.0.0.1:<port>`; three weeks without a hit on a real client |
| `mesh.homelab.example` dashboard and `/oauth2/` (NetBird) | detect for a week from 2026-11-16, then block | a wrong ban cuts everyone behind that address off the mesh |
| NetBird API, gRPC, relay | never behind the WAF | authenticated machine traffic |
| `s3.aldrin.homelab.example` (S3, `/nix-cache/`), `s3-admin`, `doku` | not behind the WAF | signed or binary bodies, or mesh only; bucket whitelist from #307 |
| `cloud.homelab.example` (OpenCloud) | detect for a week, then block; `no-server-side-scripts` off on `/remote.php`, `/status.php`, `/ocs/`; CRS 911100 off for WebDAV methods; PUT/PATCH bodies on `/remote.php/dav/`, `/remote.php/webdav/`, `/dav/`, `/data/` not inspected | the sync clients use ownCloud's paths and WebDAV; uploads with `proxy_request_buffering off` |
| `tabs.homelab.example` (floccus) | detect for a week, then block; CRS 911100 off for WebDAV methods | WebDAV client |
| `short.homelab.example`, `fotos.homelab.example`, `dash.homelab.example` | block | public, no login, only scanners in the detect data |
| ACME, MQTT 8883, Home Assistant app | nothing to do | DNS-01 / tls-alpn, plain TCP, and HA goes through the NetBird proxy, not through these front doors |

## Home line

The home connection has a dynamic address and has been banned before: `http-crawl-non_statics` and `http-probing` caught a workstation running `tofu apply` and the first nightly prebuild. Since #444 (once deployed), CrowdSec drops the ban for those scenarios (and `homelab/http-malformed-request`) when the source is the resolved IPv4 address or in the resolved IPv6 prefix:

- gruffi keeps a dyndns name on the line's addresses (`uplinks.home.dyndnsName` in `inventory.json`; A the IPv4, AAAA gruffi's own address in the delegated prefix). The name sits in a zone of its own, `dyn.homelab.example`, delegated by DNSControl: deSEC's minimum TTL is per zone, 900 s for `homelab.example`, and the dyndns zone gets a lower one. The script `openwrt/gruffi/ddns-home.sh` runs when the line comes up and every 15 minutes; its deSEC token may write only those two records (`terraform/desec-tokens`).
- On the public hosts a postoverflow whitelist (`modules/crowdsec-dynamic-allow.nix`) resolves the name whenever a scenario overflows and drops the ban if the source is in the A address or the AAAA's prefix (`ipv6PrefixLength` from the inventory). A failed lookup means no exemption.
- The WAF still refuses bad requests from home with 403; only the ban is dropped. Brute force, CVE and WAF scenarios still ban the home line, so a compromised device at home is still caught. Not a LAPI allowlist: in CrowdSec 1.7.8 AppSec checks those too and would stop blocking the address in-band.
- Not covered: the community blocklist and bans added by hand.

Metrics: `cs_node_wl_hits_ok_total{name="homelab/home-line"}` (bans dropped), `nixlab_crowdsec_dynamic_allow_addresses{family}` per host, `gruffi_ddns_in_sync` and friends from gruffi. Alerts `CrowdsecHomeExemptionUnresolved`, `CrowdsecHomeExemptionStale`, `GruffiDyndnsOutOfSync`, `GruffiDyndnsNotRunning`. Dashboard: Web & Security, row "Home line exemption".

## Failure

`services.waf.failOpen = true` (default): if AppSec cannot be reached or does not answer in time, requests pass unchecked – Pocket ID, the NetBird login and the sync clients should not go down with CrowdSec. Neither bouncer can decide this per name. The Traefik plugin would block by default when AppSec or the LAPI is unreachable and until its first decision pull; the module switches all of that off.

How long "in time" is: `services.waf.appsecTimeout` (500 ms, the bouncer's `APPSEC_PROCESS_TIMEOUT`) for the nginx bouncer; the Traefik plugin waits `httpTimeoutSeconds` (10 s). That one is shared with its full decision pull, which failed every minute with 2 s on grammi (2026-11-19), so it stays at the plugin default; a crowdsec restart answers `connection refused` at once anyway. Traefik has no per-request counter; it logs `appsecQuery:unreachable` (no router named) for every request it let through unchecked, which a VictoriaLogs rule counts. A request AppSec gave no verdict for counts as `result="unchecked"` on nginx (#413): the module wraps the bouncer's AppSec call and takes its error return, which covers a timeout, AppSec not listening (`connection refused`) and AppSec closing the connection on an oversized body. A 401 or 5xx from AppSec returns no error and looks like a 200 when failing open; the probe covers those. With `failOpen = false` the same requests are refused and still count as unchecked. Measured 2026-11-05..19: almost all of them came while crowdsec restarted (nightly hub index update at 00:01, deploys) - mostly `connection refused`, so a longer timeout would not have helped; AppSec's own processing stayed under 25 ms at p99.9 on every host.

## Metrics and alerts

| Metric | Source |
| --- | --- |
| `nixlab_waf_requests_total{vhost, result="refused"\|"unchecked"\|"passed"}` | nginx, per vhost, counted in the log phase (`127.0.0.1:9932/metrics`, scraped by vmagent) |
| `nixlab_waf_appsec_duration_seconds` (histogram) | nginx, per host: how long the bouncer waited for AppSec, request body included; a timeout counts with its full wait |
| `traefik_router_requests_total{code="403"}` on `dash`, `mesh-oauth2`, `mesh-dashboard` | Traefik on grammi |
| `nixlab_waf_appsec_up` | textfile writer `waf-appsec-up`, once a minute: AppSec answers on its port |
| `nixlab_waf_appsec_probe_ok` | same writer: a harmless request with the bouncer key got a 200 |
| `cs_appsec_reqs_total`, `cs_appsec_block_total`, `cs_appsec_rule_hits` | CrowdSec itself |

The probe (`services.waf.probe.package`) sends its request from `127.0.0.2` (`services.waf.probe.address`) with the host's bouncer key, which the writer gets as a systemd credential. CrowdSec labels its AppSec counters with the connecting address (`source`), which is `127.0.0.1` for everything a bouncer forwards; vmagent drops the series with the probe's address (`services.waf.probe.metricRelabelConfigs`), so the counters show bouncer traffic only. The parsing-time histograms carry `source` too and are filtered the same way. Without a key (a host before `just waf-key`, or a key file that cannot be read) the probe only opens a TCP connection, so `nixlab_waf_appsec_up` then means "the port accepts connections", not "AppSec answers HTTP"; with an unreadable key `nixlab_waf_appsec_probe_ok` is 0. Until #452 the probe asked without key, and CrowdSec logged "missing API key" at error level once a minute.

Alerts (`hosts/grammi/alerting/security.nix`): `WafAppsecDown` (no answer for 5 minutes), `WafAppsecProbeFailed` (answers, but the request with key fails for 10 minutes: key revoked or rules broken), `WafBlocksHigh` (more than 100 refused requests an hour on one name), `WafUncheckedHigh` (more than 10 unchecked requests in 15 minutes on one name, for 30 minutes - a restart burst does not fire it; for Traefik per host, from the journal in `hosts/grammi/alerting/journal.nix`). Dashboard: Web & Security, row "AppSec WAF".

## Hosts

| Host | Names | Mode |
| --- | --- | --- |
| zummi | `auth.homelab.example` | block (since 2026-11-08) |
| aldrin | `short.homelab.example`, `fotos.homelab.example` | block (#4) |
| aldrin | `cloud.homelab.example`, `tabs.homelab.example` | detect, then block |
| grammi | `dash.homelab.example` | block (#4) |
| grammi | `mesh.homelab.example` (dashboard, `/oauth2/`) | detect, then block |

A Traefik plugin on grammi does not protect the services of other hosts: Traefik passes those names through as TCP to the NetBird proxy, which reaches its targets directly.

## Adding a host or a name

1. `services.waf.enable = true;` and `./modules/waf-lab.nix` in the host's modules in `flake.nix` (the public VMs have it through the `public-vm` profile); `waf` in the host's line in `.sops.yaml`. nginx: `lab.vhosts."<name>".waf = true;` (or `services.waf.nginx.vhosts`). Traefik: the router lists `config.services.waf.traefik.middleware`.
2. New names in `detect`: `services.waf.hosts."<name>".mode = "detect";`.
3. Deploy. The AppSec engine runs then; no proxy asks it yet.
4. `just waf-key <host>` – registers `nginx-appsec` or `traefik-appsec` with the host's LAPI and writes the key to `hosts/<host>/waf.yaml`. Commit, deploy.
5. Check: `cscli bouncers list` shows the bouncer with a recent pull; `curl -I https://<name>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` raises a test alert.
6. After a week without false positives: drop the `mode = "detect"`.

Test: `just test-vm waf` (`tests/waf.nix`) – known-bad request blocked through nginx and Traefik, exceptions pass, detect only alerts, fail open with CrowdSec stopped, and an AppSec that never answers: the request waits `appsecTimeout`, passes and counts as unchecked.

Sources: the nginx wiring follows CrowdSec's [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) from cs-nginx-bouncer v1.2.3 (MIT); the Lua library is CrowdSec's [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633) (MIT); the Traefik plugin is maxlerebourg's [crowdsec-bouncer-traefik-plugin v1.8.1](https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin/tree/f9c85b1472d618e9188a025c9b2308d0b27e5321) (Apache-2.0).
