# Maintenance mode

A service can be closed for maintenance without stopping it: whoever opens it gets a page with status 503, the reason and `Retry-After`; the service itself keeps running and stays reachable for tests. The same page appears with 502 or 504 when the service does not answer – during a `switch`, say. Module: `modules/maintenance.nix`.

## How it works { #how-it-works }

Every HTTP path to a service ends at nginx or Traefik on the host the service runs on – the path through the NetBird reverse proxy too, which only passes requests on. That is where the maintenance switch and the error pages sit; which software it is, is a detail per host.

<figure class="nx-diagram">
<svg viewBox="0 0 680 530" role="img" aria-label="Paths to the services: every HTTP path ends at nginx or Traefik on the target host, where the maintenance switch and the error pages sit" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-teal rect{fill:#e1f5ee;stroke:#0f6e56}.nx-teal .nx-t{fill:#04342c}.nx-teal .nx-s{fill:#0f6e56}</style>
<text class="nx-s" x="62" y="30" text-anchor="middle">Source</text>
<text class="nx-s" x="172" y="30" text-anchor="middle">grammi entry</text>
<text class="nx-s" x="298" y="30" text-anchor="middle">Proxy</text>
<text class="nx-s" x="432" y="30" text-anchor="middle">Front at target</text>
<text class="nx-s" x="584" y="30" text-anchor="middle">Services</text>
<g class="nx-gray"><rect x="20" y="48" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="78" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 73 H368"/><path class="nx-line" d="M362 69 L368 73 L362 77"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="48" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="70" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="87" text-anchor="middle">aldrin, zummi</text></a>
<path class="nx-line" d="M494 73 H506"/><path class="nx-line" d="M500 69 L506 73 L500 77"/>
<g class="nx-gray"><rect x="508" y="48" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="69" text-anchor="middle">s3.aldrin, cloud,</text><text class="nx-s" x="584" y="85" text-anchor="middle">auth</text></g>
<g class="nx-gray"><rect x="20" y="110" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="140" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 135 H116"/><path class="nx-line" d="M110 131 L116 135 L110 139"/>
<g class="nx-gray"><rect x="118" y="110" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="140" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 135 H238"/><path class="nx-line" d="M232 131 L238 135 L232 139"/>
<g class="nx-gray"><rect x="240" y="110" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="140" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 135 H368"/><path class="nx-line" d="M362 131 L368 135 L362 139"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="110" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="132" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="149" text-anchor="middle">ursalia :8092</text></a>
<path class="nx-line" d="M494 135 H506"/><path class="nx-line" d="M500 131 L506 135 L500 139"/>
<g class="nx-gray"><rect x="508" y="110" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="140" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="172" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="202" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 197 H116"/><path class="nx-line" d="M110 193 L116 197 L110 201"/>
<g class="nx-gray"><rect x="118" y="172" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="202" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 197 H238"/><path class="nx-line" d="M232 193 L238 197 L232 201"/>
<g class="nx-gray"><rect x="240" y="172" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="202" text-anchor="middle">netbird-proxy</text></g>
<path class="nx-line" d="M356 197 H368"/><path class="nx-line" d="M362 193 L368 197 L362 201"/>
<a data-target="traefik" tabindex="0" role="link" class="nx-teal"><rect x="370" y="172" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="194" text-anchor="middle">Traefik :8090</text><text class="nx-s" x="432" y="211" text-anchor="middle">all grammi apps</text></a>
<path class="nx-line" d="M494 197 H506"/><path class="nx-line" d="M500 193 L506 197 L500 201"/>
<g class="nx-gray"><rect x="508" y="172" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="193" text-anchor="middle">vm, vl, rezepte,</text><text class="nx-s" x="584" y="209" text-anchor="middle">grist, logs, metrics</text></g>
<g class="nx-gray"><rect x="20" y="234" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="264" text-anchor="middle">Mesh</text></g>
<path class="nx-line" d="M104 259 H368"/><path class="nx-line" d="M362 255 L368 259 L362 263"/>
<a data-target="nginx" tabindex="0" role="link" class="nx-teal"><rect x="370" y="234" width="124" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="432" y="256" text-anchor="middle">nginx</text><text class="nx-s" x="432" y="273" text-anchor="middle">ursalia :443</text></a>
<path class="nx-line" d="M494 259 H506"/><path class="nx-line" d="M500 255 L506 259 L500 263"/>
<g class="nx-gray"><rect x="508" y="234" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="264" text-anchor="middle">dokumente</text></g>
<g class="nx-gray"><rect x="20" y="296" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="326" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 321 H238"/><path class="nx-line" d="M232 317 L238 321 L232 325"/>
<g class="nx-gray"><rect x="240" y="296" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="318" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="335" text-anchor="middle">:8883, TCP only</text></g>
<path class="nx-line" d="M356 321 H368"/><path class="nx-line" d="M362 317 L368 321 L362 325"/>
<g class="nx-gray"><rect x="370" y="296" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="326" text-anchor="middle">none</text></g>
<path class="nx-line" d="M494 321 H506"/><path class="nx-line" d="M500 317 L506 321 L500 325"/>
<g class="nx-gray"><rect x="508" y="296" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="326" text-anchor="middle">mqtt (Home Assistant)</text></g>
<g class="nx-gray"><rect x="20" y="358" width="84" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="62" y="388" text-anchor="middle">Internet</text></g>
<path class="nx-line" d="M104 383 H116"/><path class="nx-line" d="M110 379 L116 383 L110 387"/>
<g class="nx-gray"><rect x="118" y="358" width="108" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="172" y="388" text-anchor="middle">Traefik :443</text></g>
<path class="nx-line" d="M226 383 H238"/><path class="nx-line" d="M232 379 L238 383 L232 387"/>
<g class="nx-gray"><rect x="240" y="358" width="116" height="50" rx="8" stroke-width="1"/><text class="nx-t" x="298" y="380" text-anchor="middle">netbird-proxy</text><text class="nx-s" x="298" y="397" text-anchor="middle">target switched</text></g>
<path class="nx-line" d="M356 383 H368" stroke-dasharray="5 4"/><path class="nx-line" d="M362 379 L368 383 L362 387"/>
<a data-target="proxy-maintenance" tabindex="0" role="link" class="nx-teal"><rect x="370" y="358" width="124" height="50" rx="8" stroke-width="1" stroke-dasharray="5 4"/><text class="nx-t" x="432" y="380" text-anchor="middle">Maintenance page</text><text class="nx-s" x="432" y="397" text-anchor="middle">grammi :8090</text></a>
<g class="nx-gray"><rect x="508" y="358" width="152" height="50" rx="8" stroke-width="1"/><text class="nx-s" x="584" y="379" text-anchor="middle">when the target host</text><text class="nx-s" x="584" y="395" text-anchor="middle">is down entirely</text></g>
<a data-target="switching" tabindex="0" role="link" class="nx-teal"><rect x="20" y="430" width="640" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="453" text-anchor="middle">Shared on every host with a front</text><text class="nx-s" x="340" y="472" text-anchor="middle">Flag in /var/lib/maintenance · page 503/502/504 · bypass cookie</text></a>
<g class="nx-teal"><rect x="20" y="504" width="14" height="14" rx="3" stroke-width="1"/></g><text class="nx-s" x="42" y="515">maintenance check and error pages</text>
<g class="nx-gray"><rect x="340" y="504" width="14" height="14" rx="3" stroke-width="1" stroke-dasharray="3 2"/></g><text class="nx-s" x="362" y="515">dashed: proxy maintenance, only when needed</text>
</svg>
</figure>

- **Flag**: `/var/lib/maintenance/<fqdn>` (or `all` for the whole host). The file's content is the reason on the page. Flags survive a reboot – maintenance stays on until someone ends it.
- **Page**: a small program on every host (`maintenance-responder`, 127.0.0.1:8089 only, started on demand by systemd). It decides between maintenance (503) and failure (502/504) the same way for nginx and Traefik.
- **Bypass**: one cookie for every name under `homelab.example` that keeps the service reachable in the browser despite maintenance.

## Switching on and off { #switching }

From the workstation; the host is looked up in `inventory.json`:

```bash
just maintenance dokumente on "Paperless upgrade, until about 10 pm"
```

```bash
just maintenance dokumente off
```

```bash
just maintenance-list
```

A name without a dot gets `.homelab.example` appended. A whole host (every name with a maintenance switch there):

```bash
just maintenance all on "Moving to new hardware" aldrin
```

```bash
just maintenance all off "" aldrin
```

On the host itself the same works with `maintenance on|off|status`. Neither nginx nor Traefik needs a reload; nginx checks the flag on every request, Traefik picks the change up after two to four seconds.

Which names have a maintenance switch:

| Host | Names | Front |
| --- | --- | --- |
| aldrin | `s3.aldrin`, `cloud` | nginx |
| zummi | `auth` | nginx |
| ursalia | `dokumente` (443 and the proxy listener 8092) | nginx |
| grammi | every name in `hosts/grammi/proxy-services.json` | Traefik `:8090` |

Side effects: `s3.aldrin` in maintenance means every host's nightly restic backup fails; `auth` in maintenance means nobody can log in anew through Pocket ID. `s3-admin` (garage-ui) only has the error pages: its 443 is open publicly, and the maintenance check would run before its mesh-only `allow`/`deny`.

## Seeing the service anyway { #bypass }

1. Copy the token to the clipboard (it is never shown):

    ```bash
    just maintenance-key
    ```

2. Open `https://<name>/_maintenance/bypass`, e.g. `https://dokumente.homelab.example/_maintenance/bypass`, and paste the token.

The cookie holds for 12 hours for every name under `homelab.example`, including the way back after logging in at Pocket ID. To remove it: `https://<name>/_maintenance/clear`. The bypass is a convenience, not a security boundary – login, the proxy's SSO and mesh-only restrictions still apply. The token is in `hosts/<host>/maintenance.yaml` (sops, the same token on all four hosts); to rotate it: delete all four files, run `just maintenance-token`, commit, deploy the four hosts.

The key is sent through a form, not as `?key=` in the address: addresses end up in the access logs, and those are shipped to VictoriaLogs.

## Testing behind maintenance with ssh -L { #testing-behind }

For checks without a browser – health check, API, version – a tunnel straight to the service, past nginx and Traefik, is enough:

```bash
ssh -L 8000:127.0.0.1:8000 root@ursalia.peer.homelab.example
```

```bash
curl -sI http://localhost:8000/api/
```

More examples: Grafana `ssh -L 3000:127.0.0.1:3000 root@grammi.peer.homelab.example`, Garage S3 `ssh -L 3900:127.0.0.1:3900 root@aldrin.peer.homelab.example` (then an S3 client against `http://localhost:3900`).

For a test in the browser this rarely works: services that check their own address refuse `localhost`. paperless compares the `Origin` with `PAPERLESS_URL` on login (CSRF), OpenCloud and everything with OIDC send you back to their real address after the login – which is in maintenance. The [bypass](#bypass) is what the browser needs.

## When the host is down entirely { #proxy-maintenance }

When the target host itself is down (reboot, migration), its maintenance page is gone with it and the NetBird proxy shows its own error. For the services outside grammi (`dokumente`, `doku`) the proxy's target can therefore be switched to grammi, where Traefik answers every name it does not serve itself with the maintenance page:

```bash
just proxy-maintenance dokumente on "ursalia is being reinstalled"
```

```bash
just proxy-maintenance dokumente off
```

This writes `terraform/netbird/proxy-maintenance.json`, runs `just netbird-apply` and sets or removes the flag on grammi. Commit `proxy-maintenance.json` and `expected-peers.json` afterwards (while switched over, the host drops out of the proxy's targets). The login (SSO, PIN) stays in front; straight from the mesh the host is of course still unreachable.

## Error pages for 502 and 504 { #error-pages }

No switch involved: when the service does not answer (502) or too slowly (504), the front shows the same page with "currently unreachable" and the real status code.

### nginx { #nginx }

nginx replaces only its own errors (`error_page`). The service's own error responses pass unchanged – `proxy_intercept_errors` stays off, so S3 clients get their XML and OIDC clients their JSON.

### Traefik { #traefik }

Traefik also replaces the service's responses with its `errors` middleware, hence 502 and 504 only, not 503. The maintenance routers are written by `maintenance-traefik-sync` from the flags into `/run/traefik-dynamic/`, which Traefik watches. The control plane `mesh.homelab.example` never gets a maintenance switch.

## Adding a service { #new-service }

- **nginx**: add the vhost (attribute name) to the host's `services.maintenance.nginx.vhosts`, or to `nginx.errorPagesOnly` for the error pages only. Not for vhosts with `allow`/`deny` whose port refused clients can reach too – the maintenance check runs before `allow`/`deny`.
- **grammi**: every entry in `hosts/grammi/proxy-services.json` is in automatically.
- **New host**: import `./modules/maintenance.nix` in `flake.nix`, set `services.maintenance.enable = true`, add the host to `.sops.yaml` (`maintenance`) and to `just maintenance-token`, and create the token anew.
