# Package hotfixes that switch themselves off.
#
# MANDATORY (rule of 2026-11-15, nixlab#321): every override that waits for
# nixpkgs - "drop this once nixpkgs has ..." - goes through `hotfix`, never
# a bare overrideAttrs with such a comment. Overrides that are meant to stay
# (a local patch, a build variant, tests switched off) are not hotfixes and
# stay plain overrides; their comment says so ("permanent, not a hotfix").
# The Macs do not load this module; there is no hotfix on them yet.
#
# A hotfix pins a package to a newer version (or adds a patch) until nixpkgs
# catches up. Written by hand, it has to be removed by hand too - and since
# the nightly auto-upgrade moves nixpkgs on its own, nobody notices the day
# it becomes dead weight, or worse, the day it starts pinning an OLDER
# version than nixpkgs ships. That happened with the paperless-ngx 3.3.2
# bump on ursalia: nixos-unstable had 3.3.2 by 2026-10-23, the override
# still said "drop me once it does" (found while adopting this module).
#
# `hotfix` (a module argument, usable by any host module) applies an
# override only while nixpkgs still needs it:
#
#   hotfix {
#     name = "sudo CVE-2025-32463";   # for the warning
#     pkg = prev.sudo;                # what nixpkgs ships
#     fixedVersion = "1.9.17p1";      # first version with the fix
#     fixPatch = "CVE-2025-32463";    # optional, see below
#     override = pkg: pkg.overrideAttrs (old: { ... });
#   }
#
# It returns `pkg` untouched once pkg.version >= fixedVersion, or once one of
# pkg.patches has `fixPatch` in its name - stable releases usually backport a
# CVE as a patch without bumping the version. In every case evaluation warns
# that the hotfix can go, so it does not linger; the override (and its src
# hash) is then not evaluated at all.
#
# A fix that no version number marks takes `fixedWhen` instead of (or next
# to) fixedVersion: a boolean that turns true once nixpkgs has it, e.g. "the
# package no longer takes the argument the override replaces"
# (hosts/ursalia/paperless-v3.nix). Pick a test that flips in the same
# nixpkgs commit as the fix, so it cannot switch the hotfix off early.
#
# Credits: the pattern is snowball's (BBBSnowball), offered for reuse on
# 2026-10-23 - version check plus CVE patch detection, one overlay per file:
# https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes
# Ours adds the warning: there the override goes quiet without telling anyone.
#
# Hotfixes for packages from the host's own pkgs go into modules/hotfixes/,
# one overlay per file, as `hotfix: final: prev: { <pkg> = hotfix { ... }; }`;
# every file there is loaded on every NixOS host. Packages taken from another
# nixpkgs (`inputs.<pin>.legacyPackages.${system}`) do not see these overlays - call
# `hotfix` on them in the host module instead.
{ lib, ... }:
let
  hotfix =
    {
      name,
      pkg,
      override,
      fixedVersion ? null,
      fixedWhen ? null,
      fixPatch ? null,
    }:
    assert lib.assertMsg (
      fixedVersion != null || fixedWhen != null
    ) "hotfix \"${name}\" needs fixedVersion or fixedWhen";
    let
      patched = fixPatch != null && lib.any (p: lib.hasInfix fixPatch (toString p)) (pkg.patches or [ ]);
      versionFixed = fixedVersion != null && lib.versionAtLeast pkg.version fixedVersion;
      conditionFixed = fixedWhen == true;
      fixed = versionFixed || patched || conditionFixed;
      why =
        if patched then
          "has a patch matching \"${fixPatch}\""
        else if versionFixed then
          "has version ${pkg.version}"
        else
          "meets the hotfix's fixedWhen condition";
      fixIn = lib.optionalString (fixedVersion != null) " (fix in ${fixedVersion})";
    in
    if fixed then
      lib.warn "hotfix \"${name}\" is no longer needed: nixpkgs' ${pkg.pname or pkg.name} ${why}${fixIn} - remove it" pkg
    else
      override pkg;

  dir = ./hotfixes;
  files = lib.optionals (builtins.pathExists dir) (
    lib.filter (f: lib.hasSuffix ".nix" f) (
      lib.attrNames (lib.filterAttrs (_: t: t == "regular") (builtins.readDir dir))
    )
  );
in
{
  _module.args.hotfix = hotfix;

  nixpkgs.overlays = map (f: import (dir + "/${f}") hotfix) files;
}
