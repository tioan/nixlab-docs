# Update a container image

The few services that run as Podman containers (on ursalia: Bambuddy, HealthLog, ph-intercept, the ESPHome builder) pull their images by digest, not by tag. A tag such as `latest` or `1.3.1` is whatever the registry says it is today; a digest is the content itself, just as a fetcher's hash is in Nix. Nothing updates on its own: there is no `podman auto-update` and no auto-update label. [`modules/container-pins.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/container-pins.nix) refuses to evaluate a host that has either (admin/nixlab#305).

## Where the pins are

`hosts/<host>/container-images.json`, one entry per container:

```json
"healthlog": {
  "image": "ghcr.io/mbombeck/healthlog",
  "tag": "v1.47.6",
  "digest": "sha256:2f88…",
  "source": "https://github.com/MBombeck/HealthLog"
}
```

`tag` only says which tag the digest was read from. What gets pulled is `image@digest`. `source` is where the version check looks for releases.

## How a new version shows up

The weekly version check on zorlock lists every pin as a target of kind `container`, with the tag as the pinned version, and compares it with the newest stable GitHub release of `source`. A newer release appears there as `update`, with its release notes.

## Bump { #bump }

```bash
just container-bump ursalia healthlog
```

It takes the newest release tag (`1.2.3` or `v1.2.3`: no betas, dev builds or per-architecture tags), reads its digest with skopeo and writes both into the JSON. It prints the old and new tag and where the release notes are. To pin a particular tag, give it as the third argument: `just container-bump ursalia bambuddy 1.3.0`. Nothing on the host changes yet.

Then read the release notes, commit and deploy:

```bash
just deploy ursalia
```

Per service, before deploying:

- **HealthLog**: migrations are forward-only. The container writes a pg_dump to `/var/lib/healthlog/backups` before migrating, so the way back is reverting the bump and restoring that dump.
- **Bambuddy**: also migrates on start; the way back is reverting the bump plus the nightly pg_dump.
- **ESPHome builder**: the Home Assistant add-on updates itself and runs ahead until the next bump. Its version-match policy has to stay at "release" (Settings > Send builds), which accepts any stable release on the builder's side.

## A new container

Add an entry to the host's `container-images.json` (the recipe needs `image` and `source` in it; take `tag` and `digest` from `just container-bump`), import `modules/container-pins.nix` in the container's file, and set `image = config.services.containerPins.images.<name>.ref`. An image built on the host itself sets `pull = "never"` instead (OpenInvento).
