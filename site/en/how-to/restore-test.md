# Test a restore

A backup is only as good as the last restore that worked. `just restore-test <host>` brings grammi or zummi back from its restic backup into a throwaway VM on ursalia and measures how long that takes – from an empty disk until the services answer. It needs nothing but this repository and the recovery key `admin`, the same as after losing the host for real.

## Run it { #run }

From a checkout, in a terminal where `op` is signed in (`op whoami`; otherwise `eval "$(op signin)"`):

```bash
just restore-test grammi isolation
just restore-test grammi
just restore-test zummi
```

- `isolation` is the rehearsal: the VM boots and has to prove it reaches nothing. No secret is involved. Run it first after changing [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix).
- Without a mode it is the restore. 1Password asks for the `admin` key right at the start (`op://<vault>/<item>/password`, other reference via `NIXLAB_ADMIN_AGE_KEY`).
- About two minutes per host. Repeat after changing a host's backup paths, its databases, or a service's data directory, and otherwise every few months.

## What happens { #flow }

1. **Build:** `lib.restoreTest.<host>` – the host's own configuration plus [`tests/restore/vm.nix`](https://github.com/admin/nixlab/blob/main/tests/restore/vm.nix) – is built on ursalia as a QEMU VM.
2. **T0:** the VM starts with an empty disk. Its services come up empty or fail on missing secrets, like after a reinstall.
3. **While it boots**, on ursalia: the `admin` key decrypts `restic_password` and the S3 key from the repository's `hosts/<host>/secrets.yaml`; restic restores the newest snapshot. The `admin` key is deleted again right after.
4. **Isolation:** the VM must reach neither ursalia, the internet nor aldrin's S3, and NetBird, Tailscale and the restic timers must not run – checked before any secret goes into the VM. The check proves itself on the VM's own sshd.
5. **Secrets:** the restored SSH host key must match `inventory.json`; in the VM, sops-nix then decrypts every secret of the host with it.
6. **Data:** grammi – fresh Postgres cluster, `pg_dumpall` dump loaded, mealie, Grist, Grafana, logchef and NetBird state in place. zummi – the pocket-id database from the consistent `.backup` copy and the Let's Encrypt account.
7. **Checks:** every service has to answer over HTTP; pocket-id's JWKS must hold a key (proves the encryption key fits the database). Then counts (users, peers, documents, OIDC clients) in the VM next to the same counts on the live host – read-only there.
8. **Cleanup:** VM and tmpfs are deleted. Should the recipe die halfway, the VM stops itself after 2 h and a timer deletes the tmpfs after 3 h.

## Isolation { #isolation }

The VM runs the host's real configuration with real secrets. That is safe only because it cannot send a single packet: QEMU's user network with `restrict=on` (`virtualisation.restrictNetwork`). The only way in is SSH on ursalia's loopback, with a key that exists only for this run. Its disk, the restored host key and every decrypted secret live under `/run/restore-test/<host>` on ursalia, a tmpfs – they never touch a disk. The hostname stays the real one, because the modules pick the sops files by it; without a network it shows up nowhere.

## Result 2026-11-02 { #result }

| | grammi | zummi |
| --- | --- | --- |
| Build (from the cache) | 17–24 s | 14–20 s |
| VM up | 12 s | 13 s |
| Backup fetched | 2 s (65.7 MiB) | 2 s (5.2 MiB) |
| Secrets decrypted | 22 s (29/29) | 19 s (13/13) |
| Data in place | 29 s | 48 s |
| **RTO: services answer** | **38 s** | **48 s** |
| Counts restored / live | NetBird peers 15/15, users 6/6; mealie users 3/3; Grafana users 3/3; Grist documents 6/6 | users 4/4, OIDC clients 13/13, ACME files 3/3 |

Not measured: renting a replacement machine, installing NixOS on it, pointing DNS to it. The RTO above is the part after that.

## What the test found { #gaps }

1. **zummi's backup held no pocket-id database** – in none of the 22 snapshots from 2026-08-10 to 2026-11-02. The unanchored `"*.db"` exclude also matched the `.backup` copy. Fixed the same day (anchored to the data directory).
2. **grist needs pocket-id to start** (OIDC discovery at `auth.homelab.example`): with grammi and zummi both gone, zummi comes back first.
3. **netbird-server needs `pkgs.netbird.io` to start** – it asks for the current GeoLite file every time, although the files are in the backup.
4. **Only numeric owners:** restic keeps uids, not names, and `/var/lib/nixos` (the uid map) is in no backup. A reinstalled host hands out uids anew, so a restore chowns each service's files by name (the test does).
5. **Where pocket-id's database goes** (`data/` in its working directory) is in no backup; the copy keeps its file name only.
