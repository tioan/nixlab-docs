# Hotfix a package

When nixpkgs ships a version with a security hole or a bug and the fix is not in our pin yet, we pin the package ourselves – but through `hotfix` from [`modules/hotfixes.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/hotfixes.nix), not with a bare `overrideAttrs`. `hotfix` applies the override only while nixpkgs still needs it, and warns once it no longer does.

Why: the nightly auto-upgrade moves `nixpkgs` and `nixpkgs-unstable` on its own. A hand-written pin goes stale unnoticed, and as soon as nixpkgs is past it, it pins an *older* version. That is what happened to the paperless 3.3.2 bump on ursalia: unstable had shipped 3.3.2 for a while before anyone noticed. The warning is our addition; the rest is snowball's work, see [Credits](#credits).

## When the hotfix switches itself off { #off }

`hotfix` returns the nixpkgs package unchanged and warns as soon as either holds:

- `pkg.version` ≥ `fixedVersion` – nixpkgs has updated, or
- one of `pkg.patches` has `fixPatch` in its file name – stable has backported the fix as a patch without raising the version (the usual case for CVEs on a stable release).

The override itself, src hash included, is no longer evaluated after that.

## Package from the host's nixpkgs: overlay in `modules/hotfixes/` { #overlay }

For packages from the normal `pkgs` of a NixOS host (sudo, openssh, nginx …). Every file in `modules/hotfixes/` is loaded as an overlay on **every** NixOS host – but not on the Macs, which do not get `modules/*.nix`.

```nix
# modules/hotfixes/sudo.nix
# CVE-2025-32463: chroot option lets local users run code as root.
hotfix: final: prev: {
  sudo = hotfix {
    name = "sudo CVE-2025-32463";
    pkg = prev.sudo;
    fixedVersion = "1.9.17p1";
    fixPatch = "CVE-2025-32463";
    override = pkg: pkg.overrideAttrs (old: rec {
      version = "1.9.17p1";
      src = final.fetchurl {
        url = "https://www.sudo.ws/dist/sudo-${version}.tar.gz";
        hash = "sha256-…";
      };
    });
  };
}
```

`fixPatch` is optional; it only makes sense where the nixpkgs patch will have a recognisable name (CVE number). Fill in the hash: first leave `lib.fakeHash`, then copy the right value from the build error.

## Package from a different nixpkgs: `hotfix` in the host module { #host-module }

Packages from `import nixpkgs-unstable { … }` (paperless, Grist, …) do not see the overlays. There, `hotfix` is used as a module argument:

```nix
{ pkgs, nixpkgs-unstable, hotfix, ... }:
let
  unstable = import nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  paperless = hotfix {
    name = "paperless-ngx GHSA-…";
    pkg = unstable.paperless-ngx;
    fixedVersion = "3.4.1";
    override = pkg: pkg.overrideAttrs (finalAttrs: prev: { version = "3.4.1"; src = …; });
  };
in
```

Changes that do *not* depend on a version – a patch for an open upstream issue, tests switched off – stay outside `hotfix` as a plain `overrideAttrs` on top of the result.

## Where the warning shows up { #warning }

It is an evaluation warning:

```
evaluation warning: hotfix "sudo CVE-2025-32463" is no longer needed: nixpkgs' sudo has version 1.9.17p1 (fix in 1.9.17p1) - remove it
```

It appears with every `just ship`, `nixos-rebuild` and `nix eval` of the host – and on the pull hosts in the nightly upgrade's journal, where nobody reads it:

```bash
journalctl -u nixos-upgrade --since today | grep 'hotfix "'
```

Then delete the file in `modules/hotfixes/`, or remove the `hotfix { … }` from the host module, and deploy.

## Credits { #credits }

The pattern – version comparison, detection of a backported CVE patch, one overlay per file that is loaded automatically – is by snowball ([BBBSnowball](https://github.com/BBBSnowball)), who offered it for reuse: [`hotfixes/` in BBBSnowball/nixcfg](https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes). Our version adds the warning and the `hotfix` module argument for packages from another nixpkgs.
