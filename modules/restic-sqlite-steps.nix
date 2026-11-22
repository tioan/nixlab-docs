# The prepare/cleanup steps of modules/restic-sqlite.nix, on their own so
# tests/restic-sqlite.nix can run them without a restic job.
#
#   databases: { <name> = "/path/to/file.db"; ... }
#   dir:       where the copies go, <dir>/<name>/<file name of the database>
#
# prepare: a consistent copy of each database with SQLite's online backup
# (.backup), safe while the service writes - WAL mode included - and checked
# with PRAGMA quick_check; a missing database or a bad copy fails the step,
# so the backup run fails instead of saving a broken copy. Runs as root, so
# a -wal/-shm file sqlite3 had to create gets the database's owner back -
# otherwise a service that opens its database later could not.
# cleanup: removes the copies.
{ pkgs, lib }:
{ databases, dir }:
let
  sqlite = lib.getExe pkgs.sqlite;
  copies = lib.mapAttrsToList (name: db: {
    inherit name db;
    dir = "${dir}/${name}";
    copy = "${dir}/${name}/${baseNameOf db}";
  }) databases;
in
{
  prepare = lib.concatMapStrings (c: ''
    rm -rf ${lib.escapeShellArg c.dir}
    mkdir -p ${lib.escapeShellArg c.dir}
    test -f ${lib.escapeShellArg c.db} || { echo "restic-sqlite: ${c.db} does not exist" >&2; exit 1; }
    ${sqlite} -bail ${lib.escapeShellArg c.db} ${lib.escapeShellArg ".backup '${c.copy}'"}
    for f in ${lib.escapeShellArg c.db}-wal ${lib.escapeShellArg c.db}-shm; do
      [ ! -e "$f" ] || chown --reference=${lib.escapeShellArg c.db} "$f"
    done
    check=$(${sqlite} -bail ${lib.escapeShellArg c.copy} 'PRAGMA quick_check;')
    [ "$check" = ok ] || { echo "restic-sqlite: copy of ${c.db} failed quick_check: $check" >&2; exit 1; }
  '') copies;
  cleanup = lib.concatMapStrings (c: ''
    rm -rf ${lib.escapeShellArg c.dir}
  '') copies;
  paths = map (c: c.dir) copies;
}
