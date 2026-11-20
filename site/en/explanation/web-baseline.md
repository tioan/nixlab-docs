# Web baseline: headers, default servers, vhosts

Every web front of the lab behaves the same way in three respects, set once in [`modules/web-baseline.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/web-baseline.nix) (nginx on aldrin, ursalia and zummi) and in `hosts/grammi/netbird.nix` (Traefik on grammi). Decided 2026-11-15 (issues #308, #12, #234, #319).

## Security headers

| Header | Value |
| --- | --- |
| `Strict-Transport-Security` | `max-age=31536000` (one year) |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `X-Frame-Options` | `SAMEORIGIN` |

The values are kept once, in the option `lab.web.securityHeaders`; nginx and Traefik both render them from there.

- **nginx** sets them at the `http` level, so every server and location inherits them: the vhosts, the docs site, the plain-HTTP listeners for the NetBird proxy (the proxy passes the headers on to the browser over HTTPS) and every vhost added later.
- **A header the application sends itself wins.** Each header goes through a `map` on `$upstream_http_<name>`; an empty value makes `add_header` skip it. OpenCloud, paperless and HealthLog send their own, partly stricter values (HealthLog: HSTS with `includeSubDomains; preload`, `X-Frame-Options: DENY`) – those stay as they are, without a second copy.
- **`always`**, so the maintenance page and nginx's own error pages carry them too.
- **nginx's inheritance:** a level with an `add_header` of its own inherits none from above. Such a location has to repeat the shared lines (`config.lab.web.nginx.headers`; today only paperless' `@share` page). Evaluation fails otherwise.
- **Traefik** on grammi (the `mesh.homelab.example` routers in `netbird.nix`, the apps entrypoint's routers in `traefik.nix`): a `headers` middleware, first in every chain so the rate limits' 429s and the error pages carry them too. Unlike nginx it replaces a header the backend sent. NetBird, Caddy, Mealie, Grist, logchef, VictoriaMetrics/-Logs and Alertmanager send none of these; Grafana (`metrics`, `dash`) sends `X-Frame-Options: deny` and `nosniff`, so its routers get a variant without those two (`security-headers-grafana`) – `SAMEORIGIN` would weaken its `deny`. The maintenance routers written at runtime have no headers.

**Why HSTS without `includeSubDomains` and `preload`:** on a service name like `cloud.homelab.example` the flag only covers names *below* it, of which there are none; only on `short.homelab.example` (an apex) would it cover future subdomains, which would then have to be HTTPS from their first day. `preload` is only accepted for apex domains. HSTS on `homelab.example` itself would be the step that matters (it closes cookie injection over plain HTTP from any `*.homelab.example`), but it would also hit the device pages under that name – a decision of its own. Way back for any name: send `max-age=0` over HTTPS, and every browser that visits again forgets it.

## Default servers

A request for a name no vhost serves used to land in the first vhost on that address – pocket-id on zummi and OpenCloud on aldrin answered it with a 200. Now each nginx has default servers on every address it serves 80 and 443 on (the wildcard plus, on aldrin and zummi, the public addresses – a wildcard default does not cover a specific address; evaluation fails if one is missing):

- **443:** the TLS handshake is refused for an unknown or missing SNI (`ssl_reject_handshake`, no certificate needed). A known SNI with an unknown `Host` header is closed without an answer (444).
- **80:** every `Host` gets a 301 to `https://$host` – port 80 does nothing else, whatever the name.

## Port 80 probes

Whether port 80 really only redirects is probed continuously (`modules/public-probes-targets.nix`): every web endpoint the lab serves itself – public and mesh ones on their own host, proxied ones on the proxy's host – by name, and once per host and kind of address with `Host: localhost` and an unknown name. Expected: 301 or 308 with a `Location` on `https://`, IPv4 and IPv6 apart. Mesh names are probed from grammi, the rest from the usual probers; a failure raises `PublicServiceDown` and shows on the *Public endpoints* dashboard.

## Appliances

Devices outside NixOS (LuCI on the OpenWrt devices, cameras, the modem, ESP-class devices) are measured against the same rule and recorded in `inventory.json` under `web` (nixlab#372). `redirect`: port 80 only redirects to https – LuCI gets `redirect_https` from `openwrt/luci.nix`, and ursalia probes these devices by address, IPv4 only, any redirect code with a `Location` on `https://` (*Appliances at home* on the *Public endpoints* dashboard); gruffi lets ursalia reach exactly their port 80 (`openwrt/web-probe-targets.nix`). `plain`: the firmware has no TLS or the device's API needs plain HTTP – an accepted gap, its reason in `web.gap`. No device can add security headers itself (uhttpd has no option for it); that gap is recorded the same way.

## The vhost helper

`lab.vhosts.<name>` for the shape that kept repeating: a DNS-01 certificate, `forceSSL`, a proxy to a loopback port, websockets, mesh-only `allow`/`deny`, maintenance and WAF registration.

```nix
lab.vhosts."health.homelab.example" = {
  port = 8000;          # location / -> http://127.0.0.1:8000
  websockets = true;
  meshOnly = true;      # allow lab.mesh (+ allow), deny all; wildcard listen
  extraConfig = "client_max_body_size 0;";
};
```

| Option | Meaning |
| --- | --- |
| `port` | Loopback port `location /` proxies to; leave it out when the vhost brings its own locations. |
| `websockets` | Upgrade websockets on `location /`. |
| `meshOnly`, `allow` | Admit only the mesh ranges (`lab.mesh`, from `inventory.json`) plus `allow`. An HTTPS vhost then listens on the wildcard address – the mesh address is NetBird's to assign. |
| `proxyListener` | Instead of HTTPS: a plain-HTTP listener on this port for a NetBird reverse proxy service; always mesh-only, relative redirects. |
| `realip` | Only with `proxyListener`: the visitor's address from the proxy's `X-Forwarded-For` (rightmost non-mesh entry) instead of the proxy's mesh address, for the WAF, CrowdSec, logs and the application. The mesh-only check then judges the peer before realip. |
| `maintenance` | `switch` (default), `errorPages` or `none` – registration in [maintenance mode](../how-to/maintenance.md). |
| `waf` | Send the requests through the [AppSec WAF](waf.md). |
| `serverName`, `extraConfig`, `nginx` | Server name when two vhosts share one; server-level directives; anything else, merged into `services.nginx.virtualHosts.<name>` unchanged. |

The mesh ranges themselves are in `inventory.json` under `overlays.mesh` and reach the hosts as `lab.mesh.ipv4`, `lab.mesh.ipv6` and `lab.mesh.networks` (`modules/lab.nix`). Other places still repeat them as literals (sshd, CrowdSec, Samba, Traefik's `trustedIPs`, AdGuard, zorlock's Caddy, `terraform/netbird/main.tf`); they follow one by one, the list is in #319.
