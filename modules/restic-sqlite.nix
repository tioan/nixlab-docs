# Reusable module: SQLite databases a restic job backs up as consistent
# copies instead of the live files.
#
#   services.resticS3.jobs.aldrin.sqlite.readeck = "/var/lib/readeck/data/db.sqlite3";
#
# Before the job reads, each database is copied with SQLite's online backup
# into the job's runtime directory, /run/restic-backups-<job>/<name>/<file>,
# which joins the job's paths; afterwards the copies are removed. A copy of
# the live file - in a btrfs snapshot or not - can miss what is still in the
# -wal file or catch a write halfway; .backup cannot. The steps are
# modules/restic-sqlite-steps.nix, tested by tests/restic-sqlite.nix.
#
# Restoring: take <name>/<file> from the snapshot, stop the service, put it
# in place of the database, remove a stale -wal/-shm next to it, give it the
# service's owner, start the service.
#
# The service's other files (attachments, assets) stay the job's own `paths`;
# the live database among them does no harm but is not the one to restore.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  steps = import ./restic-sqlite-steps.nix { inherit pkgs lib; };
in
{
  options.services.resticS3.jobs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        let
          s = steps {
            databases = config.sqlite;
            # The restic unit's RuntimeDirectory (nixpkgs' restic module).
            dir = "/run/restic-backups-${name}";
          };
        in
        {
          options.sqlite = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              readeck = "/var/lib/readeck/data/db.sqlite3";
            };
            description = ''
              SQLite databases backed up as consistent copies (.backup), by a
              name of their own: the copy is <name>/<file name> in the job's
              runtime directory.
            '';
          };
          config = lib.mkIf (config.sqlite != { }) {
            inherit (s) prepare cleanup paths;
          };
        }
      )
    );
  };

  config.assertions = lib.flatten (
    lib.mapAttrsToList (
      job: j:
      map (n: {
        assertion = builtins.match "[A-Za-z0-9_-]+" n != null && lib.hasPrefix "/" j.sqlite.${n};
        message = "services.resticS3.jobs.${job}.sqlite.${n}: the name must be [A-Za-z0-9_-]+ and the database an absolute path.";
      }) (lib.attrNames j.sqlite)
    ) config.services.resticS3.jobs
  );
}
