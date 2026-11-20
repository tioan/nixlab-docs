# just recipes (generated)

Generated from the `justfile`: every recipe with the comment above it – the counterpart of the [hand-written selection](recipes.md).

## `just commit message`

Commit all changes with a message. No-op on a clean tree, so that `ship` /
`ship-all` stay usable for re-deploying an already-committed state instead of
failing on git commit's exit 1.

## `just push`

Push to the origin remote (GitHub, admin/nixlab)

## `just merge branch`

Merge a PR branch (as pushed to origin) into main with a signed merge
commit and push. GitHub sees the PR's commits on main and marks it
merged; the branch itself is left alone.

## `just seal`

Put a signed empty commit on top of main and push - the way out when an
unsigned commit is the tip (a merge on github.com) and the hosts refuse
to upgrade. Signing it vouches for everything below it: look first.

## `just sync host`

Pull the latest config on a remote host, no rebuild. A modified flake.lock
there is always the leftover of a nightly upgrade that never finished
(modules/auto-upgrade-git.nix) - never built, never activated - and would
make `git pull` refuse; discard it first. The pull is the same signature-
checked one as the nightly upgrade (auto-upgrade-git-pull, #304): an
unsigned tip on main is refused here too - sign it with `just seal`.

## `just rebuild host`

Refuses while `just try` holds the host on a branch that /etc/nixos does
not contain yet; once it does (merged and pulled), the hold is lifted and
the rebuild runs. Every pull-deployed host has modules/deploy-hold.nix.
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

(no comment)

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

## `just maintenance-list`

Every active maintenance flag on every NixOS host.

## `just gc host`

Run the host's nightly garbage collection now (modules/nix.nix): keeps the
last 10 system generations, then collects everything they do not need.

## `just openinvento-image`

Build the OpenInvento test image on ursalia and switch to it, no deploy
needed. Merges upstream main with the refs listed one per line in
~/Projects/upstream/openinvento/testbuild.refs (outside every repo; origin/pr/N
means the current head of that upstream PR) in the local throwaway branch
test/ursalia, never pushed. Runs the backend tests, copies the database,
restarts, checks /api/health. Conflicts stop it; resolved ones are replayed by
rerere. Keeps the last 3 images and database copies.
OPENINVENTO_NO_RESTART=1 only builds and tags, for the first build before the
container exists.

## `just mac-upgrade`

Update the Homebrew pins (Homebrew itself and every tap: flake input
nix-homebrew plus every input from a github:<owner>/homebrew-<name>
repository - homebrew-core, homebrew-cask, netbirdio-tap and whatever
`apps` pinned since; read from flake.lock), switch, then
`brew upgrade` what is installed, list the formulae and casks new in the
taps since the last pins (what `brew update` would have printed) - and
print the NetBird client version here next to the mesh's
(nixpkgs-netbird; bump that one deliberately, server first, see
flake.nix). Only on the workstation: the result is a
flake.lock change to commit like any other update; zorlock has no
Homebrew. Nothing else in flake.lock moves.

## `just apps *args`

Search, add and remove software in one round, then switch and commit.
Optional start term; another Mac with --host <host>. Or a subcommand:
install, uninstall (remove, rm), list, search.

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

Start the weekly full run now (collect, Claude); log in /var/log/version-check.log

## `just version-check-fetch`

Copy every run from zorlock to .version-check/ in the checkout

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
docs/nixlab-documentation.private.{de,en}.pdf (local only, gitignored)
from the site pages in docs/site/, and the anonymised public version
(README.md, README.de.md, PDFs, site sources, modules/) into public-docs/,
the gitignored clone of the public repo admin/nixlab-docs in the main
checkout, whose workflow builds the site on GitHub Pages - see
docs/build.sh and docs/anonymize.sed. Aborts if any real value would slip
through, or if the public site does not build.

Publishes only from the current origin/main with a clean tree (nixlab#314):
from a branch, build for review with NIXLAB_DOCS_NO_PUSH=1.

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
main is pushed and nothing is uncommitted - otherwise the hosts would
build something other than this checkout, so the deploy is skipped with a
note. A host that fails does not stop the others; the recipe fails at the
end and names it. NIXLAB_DOCS_NO_DEPLOY=1 skips the deploy.

## `just docs-serve`

Preview the private docs site - what doku.homelab.example serves (real values,
install guides) - from the working tree, uncommitted changes included, at
http://127.0.0.1:8000. Ctrl-C stops it. English at /, German at /de/.

## `just flake-check`

Every check of this flake for this machine's system (nixlab#324). On the
Mac: the pure evaluations - every host's system derivation, inventory,
OpenWrt settings, generated files - and the small darwin builds, a couple
of minutes. The NixOS VM tests exist for x86_64-linux only: `just test-vm`.

## `just test-vm *names`

The NixOS VM tests under checks.x86_64-linux, built on ursalia: all of them,
or only the ones named. Which checks are VM tests is read from the flake
(lib.vmTests: x86_64-linux only, with a test driver), so a new test needs
no edit here.

```
just test-vm                  all, about 15 min
just test-vm forwarding       one
```

## `just forward-probe host`

Live check of the forward filter on a routing host (#311): a namespace on
the host plays an on-link neighbour and tries to reach the host's metrics
endpoint on grammi over the mesh. Must end "blocked" everywhere. The neighbour's address is one NetBird
would masquerade on that host: inside the routed network on ursalia (home
LAN, outside the DHCP pool) and cuckoosegg (a Subraum range), any address
on the exit nodes. Runtime only, cleans up after itself.

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

## `just tf-state-rekey`

Change the state passphrase (admin/nixlab#313): a new random one, every
module's state rewritten with it, then the swap in terraform/secrets.yaml -
states and secrets file in one commit. Run in the main checkout on main,
with no other tofu work in flight, then push.

Never loses a state: the new passphrase is stored first (as
tf_state_passphrase_next), each state is read with either passphrase and
written with the new one, and only checked with the new one alone before
the swap. Interrupted? Run it again - it picks up the stored next one.

What it cannot do: the old ciphertexts stay in git history, in every
host's checkout. If the old passphrase was weak, rotate what the states
hold as well (NetBird PAT and setup keys, Garage keys, deSEC tokens,
Pocket ID clients) - the new passphrase only protects what comes after.

## `just desec-migrate-state`

Once, 2026-10-18: copy the state from its old name (terraform.tfstate,
implicit default backend) to desec.tfstate, which the explicit backend
reads from now on. The old file stays as a backup. Refuses if the new one
already exists.

## `just desec-names`

Regenerate terraform/desec-tokens/acme-names.json - per host the names its
deSEC token may answer DNS-01 challenges for - from the flake
(lib.dns01Names). Run after adding a certificate name; `nix flake check`
fails until you do, and `just desec-apply` grants the new name. Via a temp
file, so a failed eval leaves the old JSON.

## `just desec-plan`

(no comment)

## `just desec-apply`

(no comment)

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

## `just desec-ddns-key`

Mint the home line's dyndns token (desec_token.ddns_home: may write only
the A and AAAA of uplinks.home.dyndnsName, admin/nixlab#444) and set it as
desec_ddns_token in openwrt/gruffi/secrets.yaml - from `tofu output` into
`sops set`, never printed, never on disk in plaintext. Replaces an existing
token (the old one stops working at once - run gruffi-ddns-install right
after). A plain apply, as with desec-key: the policies must never lag.

## `just desec-verify`

Verify each host's token actually enforces its scope - see
terraform/desec-tokens/verify-scope.sh. Needs no bootstrap token, only
the state; talks to deSEC from each host over the mesh.

## `just gruffi-ddns-install`

Put the home line's dyndns updater on the running gruffi without a new
image (decision 11a in admin/nixlab#444): the script, its hotplug script
and exporter collector, the node exporter's init script (it mounts the
state directory), the uci settings from uci.nix, the token from sops
(straight into a 0600 file over SSH, never printed) and the cron entry.
The next image carries all of it (gen-files.sh, 90-gruffi), so this is
for the time until then; running it again is harmless. Needs the LAN or
the mesh: run it from gusto in a terminal, not from Claude's pane.

## `just pocketid-plan`

(no comment)

## `just pocketid-apply`

(no comment)

## `just pocketid-api-key`

Store a Pocket ID API key (Pocket ID admin UI -> Settings -> API Keys) in
terraform/secrets.yaml, for terraform/pocket-id and terraform/netbird.
Pocket ID keys expire: create a new one before the old one's date and run
this again.

## `just pocketid-api-key-move`

Once, 2026-10-22: move the Pocket ID API key from terraform/netbird/
secrets.yaml, where it sat while netbird was its only user, to the shared
terraform/secrets.yaml. Refuses if the shared file already exists.

## `just garage-plan`

(no comment)

## `just garage-apply`

(no comment)

## `just garage-admin-token`

Copy Garage's admin token from aldrin (hosts/aldrin/secrets.yaml, which the
workstation key cannot read) into terraform/secrets.yaml - over SSH straight
into sops, never printed. Again after rotating garage_admin_token.

## `just github-plan`

(no comment)

## `just github-apply`

(no comment)

## `just github-key host`

New deploy key for a host's /etc/nixos checkout: generates an ed25519 key
pair in a temp dir, writes the private half sops-encrypted for the host
(and the admin key) to hosts/<host>/github.yaml and the public half to
hosts/<host>/github-deploy.pub, then registers it on GitHub - read-only or
not per terraform/github/main.tf. The temp dir is removed on exit. The old
key stops working with the apply, so commit and deploy right after.

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

(no comment)

## `just netbird-apply`

(no comment)

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
pocket-id's admin paths on zummi (hosts/zummi/pocket-id.nix). Runs
after every netbird-apply; when the file changed, commit it and deploy
aldrin, ursalia and zummi. Via a temp file, and refuses an empty list: an empty
allow list would lock every admin out (the module asserts it as well).

## `just netbird-group-sync-json`

Write what the group sync on grammi needs (terraform/netbird/group-sync.tf:
person groups in Tofu's order, people, grammi's mesh addresses) to
terraform/netbird/group-sync.json. Runs after every netbird-apply; when
the file changed, commit it and deploy grammi (the sync) and zummi (the
addresses nginx lets read Pocket ID's users).

## `just netbird-group-sync-pocketid-key`

The group sync's Pocket ID API key into hosts/grammi/
netbird-group-sync-pocketid.yaml. The key belongs to the Pocket ID admin
user netbird-group-sync (no passkey, nothing but this key); create it in
a browser session as that user (log in with a login code from the admin
UI), name "netbird-group-sync", expiry one year. Old keys of that user:
delete them, the expiry alert looks at the earliest. Encrypting needs
only the public keys.

## `just netbird-group-sync`

Run the group sync on grammi now instead of waiting for its timer (every minute),
and show what it did.

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

## `just netbird-debug-upload-secret`

Secret path segment for the public way in to the upload server
(https://mesh.homelab.example/debug-upload/<secret>/, hosts/grammi/
netbird-debug-upload.nix): random hex straight into hosts/grammi/
netbird-debug-upload.yaml, never printed. Commit it and deploy grammi;
only jobs running right then notice a change.
New secret path for NetBird debug bundle uploads.

## `just netbird-debug-bundle-list`

Stored bundles on grammi: key, size, upload time. Nothing else.

## `just netbird-debug-bundle-dns key`

The DNS-related lines of a bundle - resolved domains, the status' DNS
lines, and matching lines of the client and app logs. Runs on grammi; the
zip (with the peer's private key) never comes over.
Show only the DNS-related lines of a stored bundle.

## `just netbird-debug-bundle-rm key`

Delete a bundle before its 24 h are up.

## `just netbird-rotate-token`

Move the service user's token (netbird_token.terraform) from Tofu state
into terraform/netbird/secrets.yaml and drop the owner's setup token, so
the recipes stop depending on a personal account. Run once after the
first `just netbird-apply`, and again after replacing the token (yearly,
see main.tf). `tofu output -json` of a string is already the JSON string
`sops set` wants, so the value goes pipe to pipe. Refuses an empty value -
an imported token has none, its plaintext only exists at creation.

## `just netbird-renew-token`

Replace the service user's token (every 90 days, when NetbirdTokenExpiring fires) and
store the new one: the replace authenticates with the current token, then
netbird-rotate-token swaps it in secrets.yaml.

## `just netbird-key host`

Mint a fresh one-off setup key for one host and write it straight into
hosts/<host>/netbird.yaml, encrypted for that host (and the admin key)
per .sops.yaml - piped from `tofu output` into `sops encrypt`, never on
disk in plaintext. The key is valid for 24 h and single use; run this
right before deploying the host's NetBird client, and again whenever the
host has to re-register (reinstall, lost state). A targeted `tofu apply`
(#394): only this one key is replaced, and tofu shows the plan and asks
before it applies - none of the netbird-key* recipes passes -auto-approve.

## `just netbird-router-key`

Mint a fresh setup key for the home LAN's fallback routers (the two Apple
TVs, group home-routers - see terraform/netbird/home-lan.tf) and put it on
the Mac's clipboard: never printed, never on disk. Universal Clipboard
hands it to the iPhone, whose keyboard prompt for the Apple TV can paste
it (Settings > Change Server > https://mesh.homelab.example:443 > Add this
device with a setup key). Reusable for two registrations, valid for 24 h;
run it again when an Apple TV has to re-register. A targeted `tofu apply`
of that one key; tofu asks before it applies.

## `just netbird-key-homeassistant`

Setup key for Home Assistant's NetBird add-on (terraform/netbird/
home-assistant.tf): creates group and key only - the rest of the module
needs the registered peer - and puts the key on the Mac's clipboard.
One-off, valid for 24 h; run again if HA ever has to re-register.

## `just netbird-key-gruffi`

Setup key for gruffi (terraform/netbird/gruffi.tf), on the Mac's clipboard:
never printed, never on disk. The join command is in that file. One-off,
valid for 24 h; run again after every `sysupgrade -n`.

## `just netbird-key-mudi7`

Setup key for the Mudi 7 travel router (terraform/netbird/
travel-router.tf), on the Mac's clipboard: never printed, never on disk.
Paste it on the Mudi at the silent `read -s` prompt of the join command
in that file. One-off, valid for 24 h; run again if it has to re-register.

## `just netbird-key-nanokvm`

Setup key for the NanoKVM Go+ (terraform/netbird/nanokvm.tf), on the
Mac's clipboard: never printed, never on disk. Its web UI only knows
NetBird Cloud via SSO, so it joins from the web UI's terminal - the join
command is in that file. One-off, valid for 24 h; run again if it has to re-register.

## `just netbird-key-techo5`

Setup key for a TECHO5 device (Echo Show 8 on the TECHO5 firmware,
terraform/netbird/techo5.tf), on the Mac's clipboard: never printed,
never on disk. Paste it on the device's setup page (Network > NetBird) -
the steps are in that file. One-off, valid for 24 h; run again if it has
to re-register.

## `just netbird-proxy-smoke`

Smoke test of the proxy's per-path access (terraform/netbird/reverse-proxy.tf,
local.path_services) from the public side: every request goes to the
proxy's public address with --resolve, because this machine resolves the
service names through the mesh (to ursalia), which is not what a visitor
sees. Run it after every apply that touches a path service and during
proxy maintenance too (`just proxy-maintenance`): the statuses below hold
in both states, only the body differs (the maintenance page for bypass).

Expectations: sso = redirect to the login (mesh.homelab.example), open = past
the login (any status except sso and 403 - the backend decides), block =
403, bad = 400 (path traversal is refused by the proxy). The forged
X-NetBird-User header goes along on every request: bypass and block must
not let it turn a request into an SSO one, and the SSO paths must not
take it for a login.

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

## `just cuckoosegg-push-key`

Key for ursalia's nightly push deploy of cuckoosegg (hosts/ursalia/
push-cuckoosegg.nix): private half encrypted into
hosts/ursalia/push-cuckoosegg.yaml (ursalia + admin, see .sops.yaml),
public half into hosts/cuckoosegg/push-key.pub. ssh-keygen needs a file,
so the private key exists in plaintext only in a private temp dir for
the seconds this runs. Rotating = run it again, then deploy cuckoosegg
(new public key) before ursalia (new private key) - or the next night's
push fails.

## `just root-password host`

root's console password for a NixOS host (modules/base.nix, users are
immutable since admin/nixlab#310). A random one: 24 characters, letters
and digits without y/z (the console keymap is German, a VNC client's
often is not) and without 0/O/o/1/l/I - about 136 bits. Two files, both
encrypted here (encrypting needs only the public keys, see .sops.yaml):

```
hosts/<host>/root-password.yaml        yescrypt hash, host + admin -
what the host reads
hosts/<host>/root-password-plain.yaml  the password, workstation +
admin - for `just
root-password-show <host>`
```

The password goes from /dev/urandom through pipes into mkpasswd and sops
only: no argument (ps would show it), no file, no output. Changing it =
run this again, commit both files, deploy the host.

## `just root-password-show host`

Print root's console password for a host (from `just root-password`).
Needs the workstation key (SOPS_AGE_KEY_CMD, hosts/gusto/home.nix). Run
it yourself in Ghostty - not as a `!` command in the Claude app, whose
output goes into the conversation. The password is meant for a console,
not for a log or a chat.

## `just nanokvm-mcp-key`

Store the NanoKVM Go+'s MCP API key for the Claude Code bridge on ursalia
(hosts/ursalia/claude-remote.nix). The key is shown in the KVM's web UI
under Settings > MCP once MCP is on; it is read silently here and goes
straight into hosts/ursalia/nanokvm-mcp.yaml (sops, ursalia + admin -
encrypting needs only the public keys). Commit, then deploy ursalia.

## `just nanokvm-cert`

Fetch the NanoKVM Go+'s self-signed certificate as ursalia's nginx sees it
and pin it (hosts/ursalia/nanokvm-go.crt, claude-remote.nix). Shows the
pinned and the offered certificate side by side; only on "y" is the file
replaced. Compare the fingerprint with the device's web UI or a second
path first - a certificate taken over the network is only as good as
that check. Commit, then deploy ursalia.

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

Register the WAF's bouncer - nginx-appsec, or traefik-appsec on a host
with Traefik - with a host's CrowdSec LAPI and store its key in
hosts/<host>/waf.yaml (sops, host + admin - see modules/waf-lab.nix).
The key goes from cscli on the host straight into `sops encrypt` here,
never printed or on disk in plaintext. Refuses to overwrite: rotating
means `cscli bouncers delete <name>` on the host, `rm` the file, and
running this again. Commit, then deploy the host.

## `just docs-login-key`

New key for the private docs from the internet: the NetBird proxy sends it
to aldrin's login listener, which serves only requests that carry it
(modules/docs-site.nix, terraform/netbird/reverse-proxy.tf). Written to
both sides - aldrin's secrets.yaml only opens with aldrin's host key, so
that one is set on aldrin and copied back (as in `just secrets`). Then
commit both, just netbird-apply and deploy aldrin.

## `just gw-remote-pki`

OpenVPN keys for gw-remote (hosts/gw-remote/container.nix, issue #84): a CA of
its own, the server certificate, one client certificate per uplink
profile of the remote site's ER7206 and the tls-crypt key - encrypted
straight into hosts/gw-remote/secrets.yaml (server side, for aldrin) and
hosts/gw-remote/clients.yaml (workstation only), never on disk in plaintext.
The CA key is thrown away: a new client means a new CA and new profiles
for both uplinks, which is cheaper than keeping a CA key safe for years.
RSA, not EC: which OpenVPN the ER7206 runs is not documented. Refuses to
overwrite; delete both files to start over.

## `just gw-remote-ovpn uplink out`

The ER7206's OpenVPN client profile for one uplink (uplink1, uplink2 -
hosts/gw-remote/site.json), with certificate, key and the tls-auth key
inline, as the Omada controller imports it (VPN > VPN Client > OpenVPN,
bound to that uplink's WAN). Kept to what the ER7206 takes: its client
silently drops a profile with tls-crypt, the controller wants an IP as
the server (aldrin's, from DNS), and newer options are left out. Written to <out> with mode 600 - it is the client's
login, delete it after the import. Needs the workstation key (1Password).

## `just dns01proxy-key-homeassistant`

Password for Home Assistant's account on dns01proxy (hosts/grammi/
dns01proxy.nix): random, onto the Mac's clipboard for the Let's Encrypt
add-on (httpreq_password), its bcrypt hash into hosts/grammi/
dns01proxy.yaml. The old password stops working with the next deploy of
grammi. Needs no 1Password - encrypting only takes the public keys.

## `just alerting-webhook-key`

Webhook for Alertmanager on grammi (hosts/grammi/alerting.nix): a random
webhook ID onto the Mac's clipboard, for the trigger of HA's automation
"nixlab Alertmanager", and the full URL into hosts/grammi/alerting.yaml.
The ID is the only thing that keeps others from posting fake alerts, so
it never goes through a terminal. The old ID stops working once HA has
the new one; deploy grammi right after.

## `just healthchecks-ping-url check`

Ping URL of a healthchecks.io check (nixlab#169) from the Mac's clipboard
into hosts/grammi/healthchecks-<check>.yaml, then clears the clipboard; the
URL never shows in a terminal - whoever has it can ping and hide an
outage. Copy it from the check's page (healthchecks.io -> check -> "Ping
URL"), then run this:

```
watchdog  Alertmanager's Watchdog (hosts/grammi/alerting.nix)
probe     grammi's ping while Pocket ID answers (modules/public-probes.nix)
```

HA's own check is set up in HA, not here. Commit the file, deploy grammi.

Store a healthchecks.io ping URL from the clipboard in sops (watchdog|probe)

## `just ha-metrics-token`

Token for grammi's scrape of Home Assistant's metrics (hosts/grammi/
ha-metrics.nix): create a long-lived access token in HA (user profile ->
Security, name "grammi metrics"), copy it, then run this. It takes the
token from the clipboard into hosts/grammi/ha-metrics.yaml and clears the
clipboard; the token never shows in a terminal.

## `just grafana-shares-token`

Token for the list of public dashboards (hosts/grammi/grafana-shares.nix,
#320): in Grafana, Administration -> Users and access -> Service accounts,
add "public-shares" with role Viewer, add a token without expiry, copy it,
then run this. It takes the token from the clipboard into
hosts/grammi/grafana-shares.yaml and clears the clipboard; until that file
exists the writer uses the admin password.

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

## `just adguard-api-password user`

Password of one of AdGuard Home's API users on ursalia (apiUsers in
hosts/ursalia/adguardhome.nix: metrics for the exporter, intercept for
ph-intercept): random, known to the host only, so nothing goes to
1Password. Writes the password and its bcrypt hash to
hosts/ursalia/adguard-<user>.yaml. Also the rotation: run again, commit,
deploy ursalia.

## `just adguardhome-password`

AdGuard Home's admin password on ursalia (hosts/ursalia/adguardhome.nix):
random, onto the clipboard for 1Password - the only place the plaintext is
kept - and only its bcrypt hash into hosts/ursalia/adguardhome.yaml. Also
the rotation: run again, store the new one, commit, deploy ursalia.

## `just bambuddy-secrets`

Bambuddy's database password on ursalia (hosts/ursalia/bambuddy.nix):
random, into hosts/ursalia/bambuddy.yaml. Once only: the role would get a
new password on deploy, the running container would keep the old one.

## `just bambuddy-oidc-secret`

Bambuddy's OIDC client secret (terraform/pocket-id/bambuddy.tf) from Tofu
state into hosts/ursalia/bambuddy-oidc.yaml. Run after pocketid-apply has
created (or replaced) the client.

## `just openinvento-secrets`

OpenInvento's secrets on ursalia (hosts/ursalia/openinvento.nix): Django's
SECRET_KEY and the metrics API key, format <8 chars>.<32 chars> like the keys
OpenInvento generates itself. Once; rotating a value: `sops set`, deploy.

## `just openinvento-oidc-secret`

OpenInvento's OIDC client secret (terraform/pocket-id/openinvento.tf) from
Tofu state into hosts/ursalia/openinvento-oidc.yaml. Run after pocketid-apply
has created (or replaced) the client.

## `just immich-oidc-secret`

Immich's OIDC client secret (terraform/pocket-id/immich.tf) from Tofu state
into hosts/ursalia/immich-oidc.yaml. Until that file exists, Immich runs
with OAuth off (hosts/ursalia/immich.nix).

## `just shortener-secrets`

short.homelab.example's secrets on aldrin (hosts/aldrin/shortener.nix): Chhoto's API key and the
master key that keeps login sessions across restarts. Once; rotating a value:
`sops set`, deploy.

## `just shortener-oidc-secret`

short.homelab.example's OIDC client secret (terraform/pocket-id/shortener.tf) from Tofu state into
hosts/aldrin/shortener-oidc.yaml. Run after pocketid-apply has created (or replaced)
the client.

## `just healthlog-offhost`

HealthLog's off-host copies (hosts/ursalia/healthlog.nix): bucket
"healthlog-backups" in Garage on aldrin, a key "healthlog-backup" that may
read and write only that bucket, and a lifecycle rule expiring every object
after 30 days (HealthLog never expires anything itself). Through Garage's
admin API v2 on aldrin, with the token from terraform/secrets.yaml like
terraform/garage (terraform/lib.sh, garage_env); setting lifecycle needs
the owner flag, which the key holds only for that one call. Key and secret
go straight into hosts/ursalia/healthlog-offhost.yaml together with a new
random BACKUP_ENCRYPTION_KEY, which also lands on the clipboard for
1Password - without it the objects are unreadable. Once only: it refuses
when the file or the bucket exists. Ran on 2026-10-26; bucket, key and
permission are in terraform/garage since, the lifecycle rule is not (the
provider has none). Should it ever run again, import the new bucket and key
there (terraform/garage/README.md). New buckets go through terraform/garage.

## `just aldrin-backup-secrets`

The key of bucket aldrin-backups from Tofu state plus a new repository password
into hosts/aldrin/backup.yaml, straight into sops, never printed. Refuses to
overwrite: a new password would lock out the existing repository.

## `just data-backup-secrets host`

The key of bucket <host>-data-backups from Tofu state plus a new repository
password into hosts/<host>/backup-data.yaml (modules/restic-data.nix), straight
into sops, never printed. Refuses to overwrite: a new password would lock out
the existing repository.

## `just restic-exporter-secrets`

The restic exporters' read-only keys (terraform/garage/restic-exporter.tf,
output restic_exporter_keys) into hosts/<host>/restic-exporter.yaml for
services.resticGarage.exporter.ownKey - from `tofu output` straight into
sops, never printed. Encrypting needs only the public keys (.sops.yaml).
Refuses while any of the files exists; after rotating a key, remove that
host's file first.

## `just nix-cache-secrets`

The nix cache's secrets (modules/nix-cache.nix): both S3 keys from
terraform/garage (nix-cache.tf, output nix_cache_keys) and a new signing key

- from `tofu output` and `nix key generate-secret` straight into sops, never
  on disk in plain text. The read key goes to secrets/nix-cache.yaml (every
  substituting host), push key and signing key to hosts/ursalia/nix-cache.yaml.
  Once only: a new signing key invalidates everything already in the cache,
  so it refuses while either file exists. Prints the public key, which goes
  into modules/nix-cache.nix.

## `just prebuild-signing-key`

Key with which ursalia's nix-cache-prebuild signs its nightly flake.lock
commit (admin/nixlab#304, git-signers.nix: lock-only). Generated in a
temp dir, removed on exit: the private half goes sops-encrypted to
hosts/ursalia/git-signing.yaml, the public half to
hosts/ursalia/git-signing.pub. Rotating = run it again, commit, then
deploy every host before ursalia's next prebuild (02:30) - hosts with the
old list refuse the new signature until then.

## `just default`

List available recipes
