# Backs up a home host's whole data disk to Garage on aldrin, via restic. The
# same job on tummi and ursalia, next to whatever else the host backs up.
#
# Its own bucket and key instead of a path in the host's existing repository:
# data disks are measured in terabytes, and a nightly job for Paperless should
# not wait for their prune and check, or share their retention.
#
# Consistency: restic reads a read-only btrfs snapshot. It has to live on the
# data disk itself (a snapshot cannot cross filesystems), and restic does not
# descend from it into itself because a snapshot leaves nested subvolumes out.
# If the disk is not mounted, /data is a plain directory on the root volume,
# `btrfs subvolume snapshot` refuses it and the run fails - it cannot store an
# empty disk as a backup.
#
# Bandwidth: no --limit-upload, SQM cake on gruffi shapes uploads per host and
# measured all of them passing through it (nixlab#180).
#
# Verification (modules/restic-verified.nix), different from the other jobs:
#  - minPercent 1: on a box for sorting files, moving a disk image away is
#    normal. With the default every later run would fail, because the verified
#    size it compares against only moves on a verified run.
#  - checkSubset 1%: 5% of 3 TB would be 150 GB through the home line each Sunday.
#
# No restic exporter: the NixOS module runs one per host, and ursalia's watches
# its Paperless repository. The verified metrics and the receiving side
# (hosts/aldrin/s3-upload-metrics.nix) cover these jobs, see the alerts in
# hosts/grammi/alerting.nix.
#
# Setting up a host:
#   add the bucket to terraform/garage/buckets.tf, modules/crowdsec.nix and
#     hosts/aldrin/s3-upload-metrics.nix, and deploy aldrin first
#   just garage-apply
#   just data-backup-secrets <host>
#   deploy the host, then once: restic-data init
#
# Restoring: paths carry the snapshot's prefix. Use the snapshot ID from
# nixlab_backup_verified_snapshot_info rather than `latest`, and --sparse so that
# the holes of a sparse disk image stay holes:
#   restic-data restore <id> --sparse --target /root/restore --include /data/.restic-snapshot/<path>
{ config, lib, pkgs, ... }:
let
  cfg = config.services.resticData;
  btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
  host = config.networking.hostName;
  dataDir = config.disko.devices.disk.data.content.partitions.luks.content.content.subvolumes."/data".mountpoint;
  snapshot = "${dataDir}/${cfg.snapshotName}";
in
{
  options.services.resticData = {
    enable = lib.mkEnableOption "the restic backup of the data disk to Garage on aldrin";
    secretsFile = lib.mkOption {
      type = lib.types.path;
      description = "sops file from `just data-backup-secrets <host>`.";
    };
    snapshotName = lib.mkOption {
      type = lib.types.str;
      default = ".restic-snapshot";
      readOnly = true;
      description = "Name of the snapshot below the data disk's mount point, for a host's Samba share to hide.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."restic_data_password".sopsFile = cfg.secretsFile;
    sops.secrets."restic_data_key_id".sopsFile = cfg.secretsFile;
    sops.secrets."restic_data_secret_key".sopsFile = cfg.secretsFile;
    sops.templates."restic-data-s3-env".content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic_data_key_id"}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic_data_secret_key"}
      AWS_DEFAULT_REGION=garage
    '';

    services.restic.backups.data = {
      # A leftover from an aborted run would make `snapshot` fail, so it goes
      # first. Cleanup runs as ExecStopPost, i.e. after failures too.
      backupPrepareCommand = ''
        if [ -e ${snapshot} ]; then ${btrfs} subvolume delete ${snapshot}; fi
        ${btrfs} subvolume snapshot -r ${dataDir} ${snapshot}
      '';
      backupCleanupCommand = ''
        if [ -e ${snapshot} ]; then ${btrfs} subvolume delete ${snapshot}; fi
      '';

      paths = [ snapshot ];

      repository = "s3:https://s3.aldrin.homelab.example/${host}-data-backups";
      passwordFile = config.sops.secrets."restic_data_password".path;
      environmentFile = config.sops.templates."restic-data-s3-env".path;
      initialize = false; # see modules/restic-verified.nix

      # Ahead of the other jobs at 02:30 and the upgrade window at 04:00. A run
      # still active when the timer fires is simply left alone by systemd.
      timerConfig = {
        OnCalendar = "00:30";
        RandomizedDelaySec = "20min";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };

    services.resticVerified.jobs.data = {
      minPercent = 1;
      checkSubset = "1%";
    };
  };
}
