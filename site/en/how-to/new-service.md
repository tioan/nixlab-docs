# Publish a new service

Services are named by function (`rezepte`, not `mealie`); new web services on grammi use PostgreSQL. First decide how the service should be reachable – that decides which files change.

| Reachability | For | Examples |
| --- | --- | --- |
| Mesh only | admin UIs, services for your own devices | `s3-admin`, `ollama` |
| Public behind the reverse proxy with SSO | web apps that should work on the road without the NetBird app | `rezepte`, `grist`, `metrics`, `dokumente` |
| Directly public | services with their own login, for machines or everyone | `auth`, `s3.aldrin` |

## Mesh only

1. One line under `local.mesh_services` in `terraform/netbird/mesh-services.tf`: name → host(s). This creates a NetBird DNS zone of its own with A record(s) on the mesh address(es); public DNS does not know the name.
2. `just netbird-apply` – since NetBird 0.81 new zones reach the clients without a restart.
3. On the host a vhost with `lab.vhosts.<name> = { port = …; meshOnly = true; }` – certificate via DNS-01 (deSEC), mesh-only allow list, security headers and the maintenance switch come with it ([web baseline](../explanation/web-baseline.md#the-vhost-helper)).
4. If the service gets a certificate via DNS-01: `just desec-names` and `just desec-apply` – every deSEC token may only write the `_acme-challenge` records of its host's names (`terraform/desec-tokens/acme-names.json`, derived from `security.acme.certs`). `nix flake check` fails until the file is up to date.
5. Deploy the host, `just topology` (new vhost).

## Public behind the reverse proxy

For services on grammi:

1. An entry in `hosts/grammi/proxy-services.json`: name → app, port, Pocket ID groups, optionally `start` (where `/` redirects to). Tofu (`reverse-proxy.tf`), Traefik and `topology.nix` read the same file; the proxy reaches every app through Traefik `:8090`.
2. The service listens on `127.0.0.1` only – Traefik connects over loopback, nothing more is needed ([apps on grammi](../explanation/secrets-network-access.md#apps-on-grammi-only-through-traefik-8090)).
3. Push a CNAME `<name>` → `proxy.homelab.example` in DNSControl – a few minutes before the apply, otherwise the resolver caches NXDOMAIN.
4. Deploy grammi first, then `just netbird-apply`. At the end it runs `just netbird-proxy-certs`: it requests every new name once from outside so the proxy fetches its certificate, then restarts `netbird-proxy` once – otherwise the dashboard hangs at "Issuing certificate…" (NetBird discussion #7118).

Services on other hosts get a resource of their own in `terraform/netbird/reverse-proxy.tf` with the host as peer target (examples: `dokumente` on ursalia – SSO for the app, share links under `/share/` without login –, `doku` on aldrin). Here too: push the CNAME first, `just netbird-apply` takes care of the certificates.

**One name, several paths** (public and SSO side by side, or a path blocked): list the service in `local.path_services` in `reverse-proxy.tf` – path, `access_action` (`inherit` = SSO, `bypass` = no login, `block` = 403), options – and take its targets from `local.path_targets`. The helper builds one target per path, switches them all to the maintenance page together and checks the rules at plan time: bypass/block paths end in `/`, the catch-all `/` is `inherit`, a target with a secret header stays `inherit`. Then add the paths to `just netbird-proxy-smoke` (public-side check with `curl --resolve`) and run it after the apply, in maintenance mode too.

## Directly public

nginx vhost on the host (ACME via DNS-01), A/AAAA records in DNSControl, CrowdSec reads the nginx logs. Only for services that have a login of their own anyway.

## Afterwards

- Docs: [Services](../reference/services.md), and [Contents of hosts/&lt;host&gt;/](../reference/host-directory.md) if new files appear there.
- Dual stack wherever possible (A and AAAA).
- Maintenance switch and error pages: [maintenance mode](maintenance.md#new-service) – automatic on grammi, one entry in the host elsewhere.
