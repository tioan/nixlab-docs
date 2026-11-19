# Read-only btrfs snapshots for a restic job to read from, so that what it
# stores from each subvolume is one consistent instant (to SQLite a snapshot
# looks like a power cut, which it is built to survive). Several snapshots are
# taken one after another, not at the same instant. Used by
# modules/restic-garage.nix and by restic jobs with other targets (BorgBase on
# ursalia):
#
#   snap = import ./restic-btrfs-snapshots.nix { inherit pkgs; } [
#     { from = "/"; to = "/snapshots/restic-myjob"; }
#   ];
#   services.restic.backups.myjob.backupPrepareCommand = snap.prepare;
#   services.restic.backups.myjob.backupCleanupCommand = snap.cleanup;
#
# A snapshot lives on the filesystem of its source and leaves nested
# subvolumes out, so restic does not descend from it into itself. A leftover
# from an aborted run would make `snapshot` fail, so it is removed first;
# cleanup runs as ExecStopPost, i.e. after failed runs too. If the source is
# not a subvolume (a data disk that is not mounted leaves a plain directory),
# `snapshot` refuses and the run fails instead of storing an empty disk.
#
# Paths go into the scripts unquoted, so they are limited to characters that
# need no quoting, and must be absolute and canonical (no trailing or doubled
# slash, no . or ..) so that they can be compared as strings: `to` is
# deleted before each run, so it must not be `from` or lie above it.
{ pkgs }:
snapshots:
let
  btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
  plain =
    p:
    if
      p == "/"
      || (builtins.match "(/[A-Za-z0-9_.+-]+)+" p != null && builtins.match ".*/\\.\\.?(/.*)?" p == null)
    then
      p
    else
      throw "restic-btrfs-snapshots: not a canonical path without characters that need quoting: ${p}";
  above = a: b: a == b || a == "/" || builtins.substring 0 (builtins.stringLength a + 1) b == a + "/";
  check =
    s:
    let
      from = plain s.from;
      to = plain s.to;
    in
    if above to from then
      throw "restic-btrfs-snapshots: ${to} is ${from} or above it, and would be deleted before the snapshot"
    else
      { inherit from to; };
  checked = map check snapshots;
  concat = f: builtins.concatStringsSep "" (map f checked);
  drop = to: ''
    if [ -e ${to} ]; then ${btrfs} subvolume delete ${to}; fi
  '';
in
{
  prepare = concat (
    s:
    # The parent of a snapshot inside its own source exists by definition.
    (if dirOf s.to == s.from then "" else "mkdir -p ${dirOf s.to}\n")
    + drop s.to
    + "${btrfs} subvolume snapshot -r ${s.from} ${s.to}\n"
  );
  cleanup = concat (s: drop s.to);
}
