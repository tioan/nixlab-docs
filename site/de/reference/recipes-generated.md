# just-Rezepte (generiert)

Automatisch erzeugt aus dem `justfile`: jedes Rezept mit dem Kommentar darüber – Gegenstück zur [handgeschriebenen Auswahl](recipes.md). Die Kommentare sind englisch.

## `just default`

List available recipes

## `just commit message`

Commit all changes with a message. No-op on a clean tree, so that `ship` /
`ship-all` stay usable for re-deploying an already-committed state instead of
failing on git commit's exit 1.

## `just push`

Push to the origin remote (GitHub, admin/nixlab)

## `just secrets host`

Edit a host's sops secrets, then bring the result back into the repo.

Secrets have to be edited *on the host*: each secrets.yaml is encrypted to
that machine's SSH host key plus the offline recovery key, neither of which
lives on this workstation. `ssh -t` is required, otherwise sops gets no TTY
and the editor never opens.

## `just pull-secrets host`

Copy a host's secrets.yaml back into the repo and clean the host's checkout.

Without this the edit only ever exists on the machine, the repo drifts, and
`just sync` later refuses to pull over the local modification. That is
exactly how garage_ui_oidc_client_secret ended up uncommitted on aldrin.

## `just topology`

Regenerate hosts/grammi/dashboards/topology.json from the flake (see
topology.nix). Run after adding a host, exporter or vhost; `nix flake check`
fails until you do. Via a temp file, so a failed eval leaves the old JSON.

## `just inventory`

Show the validated lab inventory (inventory.json) with everything derived
from it - effective sites, reverse relations, upstream, unattended boot,
service dependencies, costs.
Fails with the list of all errors if inventory.json is invalid.

## `just inventory-test`

Check inventory.json, run the validator's tests (tests/inventory.nix) and
compare the host keys with .sops.yaml - the inventory part of
`nix flake check`, without evaluating any host.

## `just services *args`

What the inventory's services run, read from the host configurations
(software.nix): per service name, version, license and language, as a
table; `just services --json` gives everything, the direct dependencies
included. Evaluates every host with a service that has a package path,
so it takes a while; fails if one of those paths leads nowhere.

## `just sbom *hosts`

SBOM of what runs on a host: CycloneDX, SPDX and CSV of the runtime
closure of /run/current-system, by sbomnix, into sbom/<host>.* (ignored
by git). Without hosts: every managed host. sbomnix runs where the system
is - on gusto itself, on the others over the mesh (root, zorlock as
admin) - pinned to the host's own nixpkgs, so the first run there
fetches it (~180 MB, collected by the next GC). Nixpkgs metadata
(licenses, descriptions) is left out: it is only there for a flake
reference, not for a running system; `just services` has the licenses of
the services. Go and Rust modules inside a package are not in the SBOM -
Nix fetches them in one piece.

## `just inventory-schema`

Regenerate inventory.schema.json (editor completion/hover for
inventory.json) from the spec in inventory.nix. Run after changing a field
there; `nix flake check` fails until you do. Via a temp file, like topology.

## `just inventory-diagram`

Render the inventory's format as a diagram - every section with its
fields, an arrow per reference - into
docs/site/common/diagrams/inventory-schema.svg, for the docs page
reference/inventory-schema.md. The Graphviz source comes from the spec in
inventory.nix; its hash is stamped into the SVG, and
checks.inventory-diagram fails until you rerun this after a format change.

## `just inventory-collect *args`

Collect what the devices can tell about themselves into inventory.json:
SSH host keys, interfaces (name, MAC, wifi/ethernet, link-local) and, for
hardware that is not virtual, vendor, model, product id and serial.
Managed hosts over the mesh (root, zorlock as admin); unmanaged devices
only their host keys, at their first fixed IPv4 address.

```
just inventory-collect                  all devices, fill in what is missing
just inventory-collect ursalia beryl    only these
just inventory-collect --force ursalia  overwrite with what the device reports
```

Without --force a value that differs is only printed - a changed host key
should be a decision. Values the device does not report (network, ipv4,
notes, interfaces it no longer has) are never touched, not even with
--force.

## `just known-hosts`

Write the SSH host keys from inventory.json to ~/.ssh/known_hosts.nixlab
for the workstation (the hosts get them via flake.nix). ssh reads the file
once ~/.ssh/config has, under "Host *":

```
UserKnownHostsFile ~/.ssh/known_hosts ~/.ssh/known_hosts.nixlab
```

## `just docs`

Build the project documentation in German and English: the private PDFs
docs/nixlab-documentation.private.{de,en}.pdf from the site pages in
docs/site/, and the anonymised public version (README.md, README.de.md,
PDFs, site sources, modules/) into public-docs/, the gitignored clone of
the public repo admin/nixlab-docs in the main checkout, whose workflow
builds the site on GitHub Pages - see docs/build.sh and
docs/anonymize.sed. Aborts if any real value would slip through, or if
the public site does not build.

Zensical from nixpkgs-unstable, like the docs-site package (26.05 has a
much older pre-1.0 version).

WeasyPrint without its test suite: it is not in the binary cache for
aarch64-darwin, and building it locally segfaults in pytest (2026-10-19);
the runtime itself is not affected.

Fonts pinned from the flake (DejaVu Sans, Bold, Mono) through a dedicated
FONTCONFIG_FILE: without it WeasyPrint on the Mac saw only regular DejaVu
Sans - no bold headings, no monospace code - and with macOS' own fonts the
PDF would depend on the machine it is built on. Liberation Sans for the
inventory schema diagram: Graphviz measures its cells with Helvetica,
and Liberation Sans has the same widths - with DejaVu long field names
ran over their cells.

Then the private site doku.homelab.example: its hosts (services.docs-site in
inventory.json - aldrin for the mesh, ursalia for the home LAN) build it
from their own checkout, so they are deployed (`just deploy`: git pull and
a full rebuild - whatever else is new on main goes out too). Only when
main is pushed and nothing but the two private PDFs this recipe rebuilds
is uncommitted - otherwise the hosts would build something other than
this checkout, so the deploy is skipped with a note. A host that fails
does not stop the others; the recipe fails at the end and names it.
NIXLAB_DOCS_NO_DEPLOY=1 skips the deploy.

## `just docs-serve`

Preview the private docs site - what doku.homelab.example serves (real values,
install guides) - from the working tree, uncommitted changes included, at
http://127.0.0.1:8000. Ctrl-C stops it. English at /, German at /de/.

## `just sync host`

Pull the latest config on a remote host, no rebuild

## `just rebuild host`

Refuses while `just try` holds the host on a branch that /etc/nixos does
not contain yet; once it does (merged and pulled), the hold is lifted and
the rebuild runs. `command -v`: hosts from before modules/deploy-hold.nix
have no holds.
Rebuild a remote host from its current /etc/nixos checkout

## `just check host`

Pull + dry-activate on a remote host without changing anything

## `just deploy host`

Pull + rebuild on a remote host in one go

## `just ship host message`

Commit, push, then deploy to one host

## `just ship-all message`

Commit, push, then deploy to every host

## `just deploy-all`

(ohne Kommentar)

## `just try host`

Builds and switches it like deploy-push, then holds the host there
(modules/deploy-hold.nix) - the nightly upgrade, `just deploy` from main
and ursalia's push to cuckoosegg leave it alone until the branch is
merged. Run it from the topic's worktree. Requires a committed tree (the
hold names a commit) based on the current origin/main, since anything
older would roll back what others merged meanwhile. Refuses while another
branch holds the host. After merging, `just deploy <host>` lifts the hold
(cuckoosegg: ursalia's nightly push once its checkout has the merge).
Tofu (netbird-apply & co.) is not covered: one state, applied from main.
Try the current topic branch on a host before merging it to main

## `just release host`

E.g. when the attempt is abandoned. Does not switch anything back - run
`just deploy <host>` (or `just deploy-push cuckoosegg` from main) for that.
Drop a host's `just try` hold without merging

## `just holds`

Every `just try` hold on every NixOS host.

## `just pve-image host pve`

Build a host's Proxmox image (vzdump .vma.zst) on ursalia and copy it
into the dump directory of a Proxmox host, ready for qmrestore - see
docs/install-cuckoosegg.md. The image stays only in ursalia's store
(unrooted, the nightly GC takes it). Copied in two hops through a temp
file here rather than `scp -3`: the Proxmox host may ask for a password,
and scp -3 cannot prompt for one (seen with vogon2, 2026-10-18).

## `just cuckoosegg-push-key`

Key for ursalia's nightly push deploy of cuckoosegg (hosts/ursalia/
push-cuckoosegg.nix): private half encrypted into
hosts/ursalia/push-cuckoosegg.yaml (ursalia + admin, see .sops.yaml),
public half into hosts/cuckoosegg/push-key.pub. ssh-keygen needs a file,
so the private key exists in plaintext only in a private temp dir for
the seconds this runs. Rotating = run it again, then deploy cuckoosegg
(new public key) before ursalia (new private key) - or the next night's
push fails.

## `just nanokvm-mcp-key`

Store the NanoKVM Go+'s MCP API key for the Claude Code bridge on ursalia
(hosts/ursalia/claude-remote.nix). The key is shown in the KVM's web UI
under Settings > MCP once MCP is on; it is read silently here and goes
straight into hosts/ursalia/nanokvm-mcp.yaml (sops, ursalia + admin -
encrypting needs only the public keys). Commit, then deploy ursalia.

## `just maintenance-list`

Every active maintenance flag on every NixOS host.

## `just maintenance-key`

Copy the bypass token to the clipboard - never printed. Taken from grammi's
decrypted secret over SSH: the workstation has no key for the hosts' sops
files. Paste it at https://<name>/_maintenance/bypass; the cookie then
holds for every name under homelab.example for 12 h.

## `just maintenance-token`

Create the bypass token once and write it to every host that runs the
module (hosts/<host>/maintenance.yaml, sops). The same token everywhere,
since the cookie covers all of homelab.example. Refuses to overwrite: rotating
means `rm hosts/*/maintenance.yaml`, running this again, and deploying all
four hosts. Commit, then deploy.

## `just waf-key host`

Register the WAF's nginx bouncer with a host's CrowdSec LAPI and store its
key in hosts/<host>/waf.yaml (sops, host + admin - see modules/waf.nix).
The key goes from cscli on the host straight into `sops encrypt` here,
never printed or on disk in plaintext. Refuses to overwrite: rotating
means `cscli bouncers delete nginx-appsec` on the host, `rm` the file, and
running this again. Commit, then deploy the host.

## `just mac-upgrade`

Update the Homebrew pins (Homebrew itself and every tap: flake input
nix-homebrew plus every input from a github:<owner>/homebrew-<name>
repository - homebrew-core, homebrew-cask, netbirdio-tap and whatever
`apps` pinned since; read from flake.lock), switch, then
`brew upgrade` what is installed - and print the NetBird client version
here next to the mesh's (nixpkgs-netbird; bump that one deliberately,
server first, see flake.nix). Only on the workstation: the result is a
flake.lock change to commit like any other update; zorlock has no
Homebrew. Nothing else in flake.lock moves.

## `just apps *args`

Search, add and remove software in one round, then switch and commit.
Optional start term; another Mac with --host <host>.

## `just sync-zorlock`

Pull the latest config on zorlock, no rebuild

## `just rebuild-zorlock`

Rebuild zorlock from its current /etc/nixos checkout (no pull, no summary)

## `just check-zorlock`

Pull + show what a switch would change on zorlock

## `just deploy-zorlock`

Pull + switch zorlock, with the summary

## `just ship-zorlock message`

Commit, push, then deploy to zorlock

## `just claude-token-zorlock`

Write hosts/zorlock/claude.yaml from a token of `claude setup-token`
(run that first; it needs the browser login). Asked for here without
echo, never an argument. Commit it and deploy zorlock.

## `just version-check-run`

Start tonight's run now (collect, Ollama, Claude); log in /var/log/version-check.log

## `just version-check-fetch`

Copy every run from zorlock to .version-check/ in the checkout

## `just gc host`

Manually trigger garbage collection on a remote host (nix.gc already runs nightly)

## `just tf-state-passphrase`

Generate the state passphrase into terraform/secrets.yaml (sops, never on
disk in plaintext). Refuses to overwrite: without the old passphrase the
committed states cannot be read any more.

## `just tf-encrypt-states`

Once, 2026-10-24: rewrite every module's plaintext state encrypted and
commit the four of them. Reads plaintext through the unencrypted fallback
(TF_ENCRYPTION_MIGRATE); the plaintext only passes through the pipe.
Each old state stays next to it as <state>.pre-encryption (gitignored) -
delete those once every plan shows no changes. Skips states that are
already encrypted.

## `just desec-migrate-state`

Once, 2026-10-18: copy the state from its old name (terraform.tfstate,
implicit default backend) to desec.tfstate, which the explicit backend
reads from now on. The old file stays as a backup. Refuses if the new one
already exists.

## `just desec-plan`

(ohne Kommentar)

## `just desec-apply`

(ohne Kommentar)

## `just desec-key host`

Mint a fresh ACME token for one host and write it straight into
hosts/<host>/desec.yaml, encrypted for that host (and the admin key) per
.sops.yaml - from `tofu output` into `sops encrypt`, never on disk in
plaintext, no SSH. Same pattern as netbird-key. Replaces the host's
existing token (the old one stops working at once - deploy the host right
after) or creates it if the host is new. A plain apply rather than
-target: replacing a token replaces its policies too, and a deSEC token
without policies has full write access to the account - the policies must
never lag behind. tofu shows the whole plan and asks first.

## `just desec-verify`

Verify each host's token actually enforces its scope - see
terraform/desec-tokens/verify-scope.sh. Needs no bootstrap token, only
the state; talks to deSEC from each host over the mesh.

## `just netbird-server-secrets`

Generate the NetBird server's three secrets and encrypt them straight into
hosts/grammi/netbird-server.yaml. Encrypting only needs the public keys in
.sops.yaml, so this runs here, without SSH, and nothing plaintext touches
the disk: the values exist only inside this pipe (printf is a shell
builtin, so they never show up in another process's argv either).
Refuses to overwrite - losing netbird_store_encryption_key means
recreating every setup key and API token, so rotating is a deliberate
`rm` first, never a side effect.

## `just netbird-setup-owner`

Create the NetBird owner account, once, right after the first deploy.

/api/setup is open to anyone until the first account exists, so nginx
never forwards it (see netbird.nix); this goes over SSH to the loopback
listener instead. The server is started with NB_SETUP_PAT_ENABLED=true, so
the same call also returns a Personal Access Token for the owner - it goes
straight into terraform/netbird/secrets.yaml (workstation key, like the
deSEC bootstrap token) and is never printed. terraform/netbird uses it to
bootstrap; it expires after 30 days.

## `just netbird-proxy-token`

Create the access token netbird-proxy registers with (hosts/grammi/
netbird-proxy.nix) and encrypt it straight into
hosts/grammi/netbird-proxy.yaml - from the server's stdout through this
pipe into sops, never on disk in plaintext. `admin token create` prints
the plain token only once; the server keeps a hash. Refuses to overwrite:
rotating means revoking the old one first
(ssh root@grammi... netbird-server-admin token list / token revoke <id>),
then `rm` the file and run this again.

## `just netbird-plan`

(ohne Kommentar)

## `just netbird-apply`

(ohne Kommentar)

## `just netbird-expected-peers`

Write the expected peers per host (terraform/netbird/expected-peers.tf)
to terraform/netbird/expected-peers.json, which grammi exposes as the
metric netbird_expected_peers. Runs after every netbird-apply; commit the
file and deploy grammi when it changed. Via a temp file, so a failed
`tofu output` leaves the old JSON in place.

## `just netbird-admin-peers`

Write the mesh addresses of the admin devices - the group
admin-workstations (terraform/netbird/admin-peers.tf) to terraform/netbird/admin-peers.json - the allow list of
the private docs site on aldrin and ursalia (flake.nix, docs-site) and of
pocket-id's admin paths on zummi (hosts/zummi/configuration.nix). Runs
after every netbird-apply; when the file changed, commit it and deploy
aldrin, ursalia and zummi. Via a temp file, and refuses an empty list: an empty
allow list would lock every admin out (the module asserts it as well).

## `just netbird-import`

Adopt what the NetBird account already has into Tofu state: looks each
resource up through the API by name and runs `tofu import` for it,
skipping whatever the state already knows (safe to re-run). For a lost or
fresh state against an existing account; the Default policy imports
itself through the import block in main.tf. The setup keys' plaintext
cannot be recovered (NetBird only returns it on creation) - the keys are
adopted so `netbird-key` replaces them properly, and simply have no value
in `setup_keys` until then. Afterwards run `just netbird-plan`.

## `just netbird-pocketid-client`

Store the Pocket ID OIDC client for NetBird (created by hand in Pocket ID,
callback https://mesh.homelab.example/oauth2/callback) in
terraform/netbird/secrets.yaml. `sops set --value-stdin` keeps both values
out of every process's argv; the workstation key decrypts the file, so
this needs no SSH.

## `just netbird-proxy-validate`

Have NetBird validate the reverse proxy's custom domains - one per zone,
terraform/netbird/reverse-proxy.tf: it resolves validation.<zone>, which
must be a CNAME to proxy.homelab.example (DNSControl), within 48 h of the
domain's creation. The check runs in the background on grammi, through
grammi's resolvers (ffmuc) - a name asked for before deSEC served it is
cached there as missing for up to an hour (SOA minimum 3600). So: push
DNS a few minutes ahead; this re-triggers every 30 s for up to 15 min and
stops once every custom domain is validated. Then `just netbird-apply`.

## `just netbird-proxy-certs`

Get every NetBird reverse proxy service its certificate and make the
dashboard show it. Works around netbird discussion #7118, hit for every
new service so far (the grammi names 2026-10-19, doku 2026-10-20): the
proxy only fetches a new name's certificate (ACME tls-alpn-01) on the
first request from outside, and even then never reports it to the
management server - the dashboard hangs at "Issuing certificate..."
until netbird-proxy restarts, finds the certificate on disk and reports
it. So: for every service without certificate_issued_at, request it once
through the proxy's public address (retrying while the certificate is
being issued - the first requests fail the TLS handshake), then restart
netbird-proxy on grammi once and check again. Does nothing when every
service has its certificate; runs at the end of `just netbird-apply`.
A new name has to be in public DNS first (DNSControl, a few minutes
ahead), or Let's Encrypt cannot reach the proxy for it.

## `just dokumente-share-pin`

The NetBird reverse proxy service dokumente (terraform/netbird/
reverse-proxy.tf) asks for this PIN before it serves a share link: 6
digits, the only format NetBird accepts. Stored in
terraform/netbird/secrets.yaml and printed once; takes effect with the
next `just netbird-apply`. Changing it locks out everyone who only knows
the old one - share links themselves stay valid.
New random PIN for Paperless' share links from outside the mesh.

## `just docs-login-key`

New key for the private docs from the internet: the NetBird proxy sends it
to aldrin's login listener, which serves only requests that carry it
(modules/docs-site.nix, terraform/netbird/reverse-proxy.tf). Written to
both sides - aldrin's secrets.yaml only opens with aldrin's host key, so
that one is set on aldrin and copied back (as in `just secrets`). Then
commit both, just netbird-apply and deploy aldrin.

## `just dokumente-share-pin-show`

Show the current share-link PIN, to pass on with a link.

## `just netbird-rotate-token`

Move the service user's token (netbird_token.terraform) from Tofu state
into terraform/netbird/secrets.yaml and drop the owner's setup token, so
the recipes stop depending on a personal account. Run once after the
first `just netbird-apply`, and again after replacing the token (yearly,
see main.tf). `tofu output -json` of a string is already the JSON string
`sops set` wants, so the value goes pipe to pipe. Refuses an empty value -
an imported token has none, its plaintext only exists at creation.

## `just netbird-renew-token`

Replace the service user's token (yearly, it expires after 365 days) and
store the new one: the replace authenticates with the current token, then
netbird-rotate-token swaps it in secrets.yaml.

## `just netbird-key host`

Mint a fresh one-off setup key for one host and write it straight into
hosts/<host>/netbird.yaml, encrypted for that host (and the admin key)
per .sops.yaml - piped from `tofu output` into `sops encrypt`, never on
disk in plaintext. The key is valid for 24 h and single use; run this
right before deploying the host's NetBird client, and again whenever the
host has to re-register (reinstall, lost state). Only this one key is
targeted, and tofu asks before replacing it.

## `just netbird-router-key`

Mint a fresh setup key for the home LAN's fallback routers (the two Apple
TVs, group home-routers - see terraform/netbird/home-lan.tf) and put it on
the Mac's clipboard: never printed, never on disk. Universal Clipboard
hands it to the iPhone, whose keyboard prompt for the Apple TV can paste
it (Settings > Change Server > https://mesh.homelab.example:443 > Add this
device with a setup key). Reusable for two registrations, valid for 24 h;
run it again when an Apple TV has to re-register.

## `just netbird-key-homeassistant`

Setup key for Home Assistant's NetBird add-on (terraform/netbird/
home-assistant.tf): creates group and key only - the rest of the module
needs the registered peer - and puts the key on the Mac's clipboard.
One-off, valid for 24 h; run again if HA ever has to re-register.

## `just dns01proxy-key-homeassistant`

Password for Home Assistant's account on dns01proxy (hosts/grammi/
dns01proxy.nix): random, onto the Mac's clipboard for the Let's Encrypt
add-on (httpreq_password), its bcrypt hash into hosts/grammi/
dns01proxy.yaml. The old password stops working with the next deploy of
grammi. Needs no 1Password - encrypting only takes the public keys.

## `just floccus-password`

Password for floccus' account on tabs.homelab.example (hosts/aldrin/
floccus.nix): random, onto the Mac's clipboard for floccus, its bcrypt hash
into hosts/aldrin/floccus.yaml. The old password stops working with the
next deploy of aldrin. Needs no 1Password - encrypting only takes the
public keys.

## `just healthlog-secrets`

HealthLog's own secrets on ursalia (hosts/ursalia/healthlog.nix): random
ENCRYPTION_KEY, API_TOKEN_HMAC_KEY and database password into
hosts/ursalia/healthlog.yaml. Once only - a new ENCRYPTION_KEY makes every
encrypted field in the database unreadable (rotation is HealthLog's
ENCRYPTION_KEYS keyring, not this). The encryption key goes onto the
clipboard for 1Password; it is the one value a database backup cannot
replace.

## `just healthlog-oidc-secret`

HealthLog's OIDC client secret (terraform/pocket-id/healthlog.tf) from Tofu
state into hosts/ursalia/healthlog-oidc.yaml. Run after pocketid-apply has
created (or replaced) the client.

## `just healthlog-offhost`

HealthLog's off-host copies (hosts/ursalia/healthlog.nix): bucket
"healthlog-backups" in Garage on aldrin, a key "healthlog-backup" that may
read and write only that bucket, and a lifecycle rule expiring every object
after 30 days (HealthLog never expires anything itself). Through Garage's
admin API v2 on aldrin; setting lifecycle needs the owner flag, which the
key holds only for that one call. Key and secret go straight into
hosts/ursalia/healthlog-offhost.yaml together with a new random
BACKUP_ENCRYPTION_KEY, which also lands on the clipboard for 1Password -
without it the objects are unreadable. Once only: it refuses when the file
or the bucket exists.

## `just pocketid-plan`

(ohne Kommentar)

## `just pocketid-apply`

(ohne Kommentar)

## `just pocketid-api-key`

Store a Pocket ID API key (Pocket ID admin UI -> Settings -> API Keys) in
terraform/secrets.yaml, for terraform/pocket-id and terraform/netbird.
Pocket ID keys expire: create a new one before the old one's date and run
this again.

## `just pocketid-api-key-move`

Once, 2026-10-22: move the Pocket ID API key from terraform/netbird/
secrets.yaml, where it sat while netbird was its only user, to the shared
terraform/secrets.yaml. Refuses if the shared file already exists.

## `just github-plan`

(ohne Kommentar)

## `just github-apply`

(ohne Kommentar)

## `just github-key host`

New deploy key for a host's /etc/nixos checkout: generates an ed25519 key
pair in a temp dir, writes the private half sops-encrypted for the host
(and the admin key) to hosts/<host>/github.yaml and the public half to
hosts/<host>/github-deploy.pub, then registers it on GitHub - read-only or
not per terraform/github/main.tf. The temp dir is removed on exit. The old
key stops working with the apply, so commit and deploy right after.
