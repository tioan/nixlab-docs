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
PDF would depend on the machine it is built on.

## `just docs-serve`

Preview the private docs site - what doku.homelab.example serves (real values,
install guides) - from the working tree, uncommitted changes included, at
http://127.0.0.1:8000. Ctrl-C stops it. English at /, German at /de/.

## `just sync host`

Pull the latest config on a remote host, no rebuild

## `just rebuild host`

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

## `just sync-zorlock`

Pull the latest config on zorlock, no rebuild

## `just rebuild-zorlock`

Rebuild zorlock from its current /etc/nixos checkout

## `just check-zorlock`

Pull + build on zorlock without switching

## `just deploy-zorlock`

Pull + rebuild on zorlock in one go

## `just ship-zorlock message`

Commit, push, then deploy to zorlock

## `just gc host`

Manually trigger garbage collection on a remote host (nix.gc already runs nightly)

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

## `just netbird-pocketid-api-key`

Store a Pocket ID API key (Pocket ID admin UI -> Settings -> API Keys,
name "netbird-tofu") in terraform/netbird/secrets.yaml - used by
terraform/netbird/people.tf for the person groups. Pocket ID keys expire:
create a new one before the old one's date and run this again.

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
