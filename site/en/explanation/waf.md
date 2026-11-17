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

## Failure

`services.waf.failOpen = true` (default): if AppSec cannot be reached or does not answer in time, requests pass unchecked – Pocket ID, the NetBird login and the sync clients should not go down with CrowdSec. Neither bouncer can decide this per name. The Traefik plugin would block by default when AppSec or the LAPI is unreachable and until its first decision pull; the module switches all of that off.

## Metrics and alerts

| Metric | Source |
| --- | --- |
| `nixlab_waf_requests_total{vhost, result="refused"\|"passed"}` | nginx, per vhost, counted in the log phase (`127.0.0.1:9932/metrics`, scraped by vmagent) |
| `traefik_router_requests_total{code="403"}` on `dash`, `mesh-oauth2`, `mesh-dashboard` | Traefik on grammi |
| `nixlab_waf_appsec_up` | textfile writer `waf-appsec-up`, once a minute |
| `cs_appsec_reqs_total`, `cs_appsec_block_total`, `cs_appsec_rule_hits` | CrowdSec itself |

Alerts (`hosts/grammi/alerting.nix`): `WafAppsecDown` (no answer for 5 minutes), `WafBlocksHigh` (more than 100 refused requests an hour on one name). Dashboard: Web & Security, row "AppSec WAF".

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

1. `services.waf.enable = true;` and `./modules/waf-lab.nix` in the host's module list in `flake.nix`; `waf` in the host's line in `.sops.yaml`. nginx: `lab.vhosts."<name>".waf = true;` (or `services.waf.nginx.vhosts`). Traefik: the router lists `config.services.waf.traefik.middleware`.
2. New names in `detect`: `services.waf.hosts."<name>".mode = "detect";`.
3. Deploy. The AppSec engine runs then; no proxy asks it yet.
4. `just waf-key <host>` – registers `nginx-appsec` or `traefik-appsec` with the host's LAPI and writes the key to `hosts/<host>/waf.yaml`. Commit, deploy.
5. Check: `cscli bouncers list` shows the bouncer with a recent pull; `curl -I https://<name>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` raises a test alert.
6. After a week without false positives: drop the `mode = "detect"`.

Test: `just test-vm waf` (`tests/waf.nix`) – known-bad request blocked through nginx and Traefik, exceptions pass, detect only alerts, fail open with CrowdSec stopped.

Sources: the nginx wiring follows CrowdSec's [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) from cs-nginx-bouncer v1.2.3 (MIT); the Lua library is CrowdSec's [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633) (MIT); the Traefik plugin is maxlerebourg's [crowdsec-bouncer-traefik-plugin v1.8.1](https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin/tree/f9c85b1472d618e9188a025c9b2308d0b27e5321) (Apache-2.0).
