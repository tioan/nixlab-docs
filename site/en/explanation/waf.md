# Web application firewall

On every host CrowdSec reads the nginx and Traefik access logs and bans addresses that stand out (`modules/crowdsec.nix`). That happens after the fact: the one request carrying an exploit has already reached the service. The WAF (`modules/waf.nix`, since 2026-10-25) checks each request before nginx passes it on – with CrowdSec's AppSec component, so the same engine, the same alerts and the same bans.

## Layout

| Part | What it does |
| --- | --- |
| OpenResty | replaces nginx (same NixOS module, Lua built in) |
| Lua bouncer (`pkgs/crowdsec-lua-bouncer.nix`) | in the access phase, sends each request of the listed vhosts to AppSec on `127.0.0.1:7422` and acts on the answer |
| AppSec (part of CrowdSec) | evaluates the rules, raises alerts |
| Firewall bouncer | enforces bans in nftables as before, on every port |

If CrowdSec cannot be reached, nginx lets requests through unchecked (`APPSEC_FAILURE_ACTION=passthrough`) – Pocket ID should not go down with CrowdSec.

## Rules

| Rules | Phase | Effect |
| --- | --- | --- |
| `crowdsecurity/appsec-virtual-patching` – about 200 rules for known CVEs (PHP-CGI, Spring4Shell, Grafana file read, …) | in-band | 403 |
| `crowdsecurity/appsec-generic-rules` – `.env`, `.git`, SSTI, … | in-band | 403 |
| `homelab/no-server-side-scripts` – `.php`, `.asp(x)`, `.jsp`, `.cgi`, `/cgi-bin/` | in-band | 403 |
| `homelab/foreign-stack-probing` – `/wp-admin`, `/phpmyadmin`, `/actuator`, `/owa`, `.aws`, `.ssh`, … | in-band | 403 |
| Method allowlist per name (`services.waf.allowedMethods`) – on `auth.homelab.example` only GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS | in-band | 403 |
| `crowdsecurity/appsec-crs` – OWASP Core Rule Set | out-of-band | no block; more than 5 hits in 30 s ban the IP |

Every in-band match gets a 403. The IP is banned once two *different* in-band rules hit within 60 s (`crowdsecurity/appsec-vpatch`: capacity 1 with `distinct: rule_name`) – the same rule repeated does not fill the bucket. Scanners usually hit several quickly.

The two own rules are the coarse net under the CVE rules: no public service here runs PHP, ASP, JSP or CGI, so any request for one is a scan or an exploit – including for a hole that has no rule of its own yet. The CRS runs out of band only, because it is broad and a single false positive should not lock out a legitimate user.

Exceptions per name: `services.waf.ruleExclusions."<fqdn>" = [ "<rule>" ];`. OpenCloud (aldrin) needs this for `homelab/no-server-side-scripts`, since it keeps ownCloud's `/remote.php`, `/status.php` and `/ocs/v*.php` for the desktop clients.

## Modes

- **`detect`** (default for every new host): in-band matches are answered with "allow", the WAF's ban scenarios run in simulation. Alerts show up in `cscli alerts list` and in the console marked "(simul)"; the WAF blocks nothing.
- **`block`**: in-band matches get a 403 and the IP is banned.

The log-based HTTP scenarios from `modules/crowdsec.nix` do not depend on the mode and ban as before.

## Hosts

| Host | vhosts | Mode |
| --- | --- | --- |
| zummi | `auth.homelab.example` (Pocket ID) | detect (pilot since 2026-10-25) |

Planned: grammi (Traefik plugin, only the dashboard, `/oauth2/` and the public Grafana paths), aldrin (garage-ui, OpenCloud). Never behind the WAF: Garage's S3 API and NetBird's gRPC/relay/API – signed or binary bodies, nothing for the rules to find and plenty to misread.

## Adding a host

1. `services.waf = { enable = true; nginx.vhosts = [ "<vhost>" ]; };` in the host's configuration, `./modules/waf.nix` in the host's module list in `flake.nix`, `waf` in the host's line in `.sops.yaml`.
2. Deploy. The AppSec engine is running then; nginx does not ask it yet (warning at evaluation).
3. `just waf-key <host>` – registers the bouncer `nginx-appsec` with the host's LAPI and writes its key to `hosts/<host>/waf.yaml`. Commit, deploy.
4. Check: `cscli bouncers list` shows `nginx-appsec` with a recent "Last API pull"; `curl -I https://<vhost>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl` raises a test alert (`cscli alerts list`).
5. After a week or two without false positives: `mode = "block";`.

Sources: the nginx wiring follows CrowdSec's [`crowdsec_nginx.conf`](https://github.com/crowdsecurity/cs-nginx-bouncer/blob/067541cdfff4b650182d819e92c04a207aa2fbb5/nginx/crowdsec_nginx.conf) from cs-nginx-bouncer v1.2.3; the Lua library is CrowdSec's [lua-cs-bouncer v1.0.19](https://github.com/crowdsecurity/lua-cs-bouncer/tree/ec94d512927cf70be865686e4eb928d128189633).
