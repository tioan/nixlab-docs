# The lab's own binary cache: bucket nix-cache in Garage on aldrin
# (terraform/garage/nix-cache.tf), filled every night by ursalia and read by
# every host next to cache.nixos.org.
#
# Why: the smaller hosts kept building what cache.nixos.org cannot have -
# anything built against this flake's own pins, sops-nix's
# sops-install-secrets above all, plus the hundreds of small configuration
# derivations. On zummi (2 vCPU, 1.8 GiB) that Go build thrashed inside the
# memory limits of nixos-upgrade and ran into its 2h timeout three nights in
# a row (2026-10-29 to -31). Now ursalia updates flake.lock, builds every
# host, uploads what it built and only then pushes the lock; the hosts pull
# it in their own nightly upgrade and substitute instead of building.
#
# Two halves, both here:
#   - every host: the substituter, its public key and the read-only S3 key
#     (secrets/nix-cache.yaml, one file for all hosts).
#   - prebuild.enable (ursalia): the nightly update + build + upload, with
#     the read-write key and the signing key (hosts/ursalia/nix-cache.yaml).
# Both files come from `just nix-cache-secrets`.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixCache;

  endpoint = "s3.aldrin.homelab.example";
  bucket = "nix-cache";
  publicKey = "nixlab-cache-1:35bg4nbWA0xHBwd46mt1cLsvzo33eA5bisTWFp2196s=";

  # Where nix (via the AWS SDK's profile provider) finds the S3 keys. root's
  # default location, so an interactive or SSH-run `nixos-rebuild` finds it
  # too: nix as root uses the store directly and substitutes itself, without
  # the daemon. Units get it through AWS_SHARED_CREDENTIALS_FILE instead,
  # since systemd sets no HOME for them.
  credentials = "/root/.aws/credentials";
  awsEnv.AWS_SHARED_CREDENTIALS_FILE = credentials;

  stateDir = "/var/lib/nix-cache-prebuild";

  # Priority 50: after cache.nixos.org (40), so the common case does not
  # depend on aldrin, and a path this cache lacks costs one fast 404.
  cacheInfo = pkgs.writeText "nix-cache-info" ''
    StoreDir: /nix/store
    WantMassQuery: 1
    Priority: 50
  '';

  upload = pkgs.writers.writePython3Bin "nix-cache-upload" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./nix-cache-upload.py);

  prebuild = pkgs.writeShellScript "nix-cache-prebuild" ''
    set -euo pipefail
    cd ${toString config.services.autoUpgradeGit.flakeDir}

    git checkout -- flake.lock
    git pull --ff-only
    nix flake update ${lib.escapeShellArgs cfg.prebuild.updateInputs}

    # Every NixOS host of the flake, so a new one is covered without an edit
    # here. The out-links double as GC roots: nix-gc must not collect
    # tonight's builds before the hosts have fetched them.
    hosts=$(nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]')
    mkdir -p ${stateDir}/systems ${stateDir}/stage
    failed=""
    for h in $hosts; do
      echo "nix-cache-prebuild: building $h"
      nix build -L --out-link ${stateDir}/systems/$h \
        ".#nixosConfigurations.$h.config.system.build.toplevel" || failed="$failed $h"
    done
    # One host that does not build holds the lock back for all of them: they
    # would only try to build the same failure themselves, from source.
    if [ -n "$failed" ]; then
      echo "nix-cache-prebuild: failed to build:$failed - flake.lock not pushed" >&2
      exit 1
    fi

    nix-cache-upload ${stateDir}/systems/*

    # Same commit + push as modules/auto-upgrade-git.nix, see there for the
    # rebase. Only after the upload: a host that pulls this lock finds the
    # cache already filled.
    if ! git diff --quiet -- flake.lock; then
      git add flake.lock
      git commit -m "flake.lock: nightly update, prebuilt on ${config.networking.hostName} ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
      if ! git push; then
        if git pull --rebase -X theirs && git push; then
          echo "nix-cache-prebuild: pushed after rebasing onto upstream"
        else
          git rebase --abort || true
          echo "nix-cache-prebuild: could not push flake.lock" >&2
          exit 1
        fi
      fi
    fi
  '';
in
{
  options.services.nixCache.prebuild = {
    enable = lib.mkEnableOption "the nightly flake.lock update, build of every host and upload to the nix cache";

    updateInputs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flake inputs the nightly run updates.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "02:30";
      description = ''
        When to run. Early enough to be done before the hosts' nixos-upgrade
        (04:00 plus up to 45 minutes); a host that starts before the new lock
        is pushed just pulls nothing new tonight.
      '';
    };
  };

  config = lib.mkMerge [
    {
      sops.secrets.nix_cache_read_key_id.sopsFile = ../secrets/nix-cache.yaml;
      sops.secrets.nix_cache_read_secret_key.sopsFile = ../secrets/nix-cache.yaml;

      sops.templates."nix-cache-aws-credentials" = {
        path = credentials;
        mode = "0400";
        content = ''
          [nix-cache]
          aws_access_key_id = ${config.sops.placeholder.nix_cache_read_key_id}
          aws_secret_access_key = ${config.sops.placeholder.nix_cache_read_secret_key}
        '';
      };

      nix.settings = {
        extra-substituters = [ "s3://${bucket}?endpoint=${endpoint}&region=garage&profile=nix-cache&priority=50" ];
        extra-trusted-public-keys = [ publicKey ];
        # aldrin down or in maintenance must not stall every build: give up
        # on a connection after 5s (default: curl's own, minutes), and build
        # locally when a substituter that listed a path fails to deliver it.
        connect-timeout = 5;
        fallback = true;
      };

      systemd.services.nix-daemon.environment = awsEnv;
      systemd.services.nixos-upgrade.environment = awsEnv;
    }

    (lib.mkIf cfg.prebuild.enable {
      sops.secrets.nix_cache_push_key_id.sopsFile = ../hosts/ursalia/nix-cache.yaml;
      sops.secrets.nix_cache_push_secret_key.sopsFile = ../hosts/ursalia/nix-cache.yaml;
      sops.secrets.nix_cache_signing_key.sopsFile = ../hosts/ursalia/nix-cache.yaml;

      # The rclone remote for the upload, as environment variables
      # (RCLONE_CONFIG_<NAME>_<OPTION>) rather than a config file.
      sops.templates."nix-cache-push.env".content = ''
        RCLONE_CONFIG_NIXCACHE_ACCESS_KEY_ID=${config.sops.placeholder.nix_cache_push_key_id}
        RCLONE_CONFIG_NIXCACHE_SECRET_ACCESS_KEY=${config.sops.placeholder.nix_cache_push_secret_key}
      '';

      systemd.services.nix-cache-prebuild = {
        description = "Update flake.lock, build every host and fill the nix cache";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        restartIfChanged = false;
        path = [ config.nix.package pkgs.git pkgs.openssh pkgs.jq pkgs.rclone upload ];
        environment = awsEnv // {
          inherit (config.systemd.services.nixos-upgrade.environment)
            GIT_SSH_COMMAND GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL;
          GIT_AUTHOR_NAME = "${config.networking.hostName} nix-cache-prebuild";
          GIT_COMMITTER_NAME = "${config.networking.hostName} nix-cache-prebuild";
          STAGE = "${stateDir}/stage";
          REMOTE = "nixcache:${bucket}";
          RCLONE_CONFIG_NIXCACHE_TYPE = "s3";
          RCLONE_CONFIG_NIXCACHE_PROVIDER = "Other";
          RCLONE_CONFIG_NIXCACHE_ENDPOINT = "https://${endpoint}";
          RCLONE_CONFIG_NIXCACHE_REGION = "garage";
          RCLONE_CONFIG_NIXCACHE_FORCE_PATH_STYLE = "true";
          SIGNING_KEY_FILE = config.sops.secrets.nix_cache_signing_key.path;
          CACHE_INFO = "${cacheInfo}";
          PRUNE_DAYS = "14";
        };
        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = config.sops.templates."nix-cache-push.env".path;
          # Like nixos-upgrade: a failed run must not leave flake.lock
          # modified, or the next pull in /etc/nixos refuses.
          ExecStopPost = "${pkgs.writeShellScript "nix-cache-prebuild-reset-lock" ''
            [ "$SERVICE_RESULT" = success ] && exit 0
            cd ${toString config.services.autoUpgradeGit.flakeDir} && ${pkgs.git}/bin/git checkout -- flake.lock || true
          ''}";
          ExecStart = prebuild;
          TimeoutStartSec = "90min";
          TimeoutStopSec = "10min";
          PrivateTmp = true;
          Nice = 10;
        };
      };

      # ursalia's own upgrade pulls what this pushes. Never both at once - its
      # reset of flake.lock would pull the rug from under this run - and with
      # After= it waits for a run still going, so it switches to tonight's
      # lock rather than yesterday's.
      systemd.services.nixos-upgrade.after = [ "nix-cache-prebuild.service" ];

      systemd.timers.nix-cache-prebuild = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.prebuild.dates;
          Persistent = true;
        };
      };
    })
  ];
}
