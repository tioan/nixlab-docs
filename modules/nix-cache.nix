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
{
  config,
  lib,
  pkgs,
  ...
}:

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

  # The same verifying pull as the hosts' nightly upgrade (modules/
  # auto-upgrade-git.nix, signers from git-signers.nix via deploy.nix).
  pullCmd = lib.getExe config.services.autoUpgradeGit.verifySignatures.package;

  substituter = "s3://${bucket}?endpoint=${endpoint}&region=garage&profile=nix-cache&priority=50";

  # Before the nightly rebuild: if aldrin's S3 does not answer, run the
  # rebuild without this cache (admin/nixlab#460). Nix itself copes - one
  # lookup fails after download-attempts x connect-timeout (~30 s), then it
  # disables the cache for 60 s - but every later lookup after those 60 s
  # starts the wait again, and on a lock-bump night there are hundreds. Any
  # HTTP answer below 500 counts as up: unauthenticated, Garage answers 403;
  # 5xx (the proxy without Garage behind it) and no answer count as down.
  # Only the substituter list changes, never the trusted keys or
  # require-sigs. NIX_CONFIG is read after nix.conf, so this replaces the
  # list (with its extra-substituters) for nixos-rebuild and the nix it runs.
  otherSubstituters = lib.remove substituter (
    (config.nix.settings.substituters or [ ]) ++ (config.nix.settings.extra-substituters or [ ])
  );
  reachabilityCheck = ''
    code=$(${lib.getExe pkgs.curl} -s -o /dev/null -w '%{http_code}' --connect-timeout 5 \
      --max-time 10 --retry 1 --retry-delay 2 https://${endpoint}/${bucket}/nix-cache-info || true)
    if [ "$code" -lt 100 ] || [ "$code" -ge 500 ]; then
      echo "nix-cache: https://${endpoint} unreachable (HTTP $code), upgrading without the lab cache" >&2
      export NIX_CONFIG="substituters = ${toString otherSubstituters}"
    fi
  '';

  # Priority 50: after cache.nixos.org (40), so the common case does not
  # depend on aldrin, and a path this cache lacks costs one fast 404.
  cacheInfo = pkgs.writeText "nix-cache-info" ''
    StoreDir: /nix/store
    WantMassQuery: 1
    Priority: 50
  '';

  fc = cfg.prebuild.flakeCheck;
  inherit (pkgs.stdenv.hostPlatform) system;
  flakeDir = toString config.services.autoUpgradeGit.flakeDir;
  textfileDir = config.services.textfileMetrics.directory;
  prefix = config.services.textfileMetrics.metricPrefix;
  writeProm = lib.getExe config.services.textfileMetrics.writeProm;

  # The names of the checks that run after the push instead of before it,
  # as a JSON list, evaluated from the given flake reference.
  vmTestsJson =
    flake:
    if fc.vmTestsAttr == null then "'[]'" else ''"$(nix eval --json "${flake}#${fc.vmTestsAttr}")"'';

  # flake-check-metrics <part> <started> <failed>: one run of the flake
  # check (part "gate": before the push, "vm": after it) into the textfile
  # collector's root directory - both units are root jobs anyway, like
  # nixos-upgrade (modules/textfile-metrics-lab.nix). Written after every run,
  # passed or failed, so FlakeCheckFailed and FlakeCheckStale
  # (hosts/grammi/alerting/units-updates.nix) see both.
  flakeCheckMetrics = pkgs.writeShellScript "flake-check-metrics" ''
    set -eu
    part=$1 started=$2 failed=$3
    now=$(${pkgs.coreutils}/bin/date +%s)
    ${writeProm} ${textfileDir}/flake-check-$part.prom ${pkgs.coreutils}/bin/printf '%s\n' \
      "# HELP ${prefix}flake_check_last_run_timestamp_seconds Unix time the nightly flake check (part: gate before the lock push, vm after it) last finished." \
      "# TYPE ${prefix}flake_check_last_run_timestamp_seconds gauge" \
      "${prefix}flake_check_last_run_timestamp_seconds{part=\"$part\"} $now" \
      "# HELP ${prefix}flake_check_failed_checks Checks that failed in the last nightly flake check run." \
      "# TYPE ${prefix}flake_check_failed_checks gauge" \
      "${prefix}flake_check_failed_checks{part=\"$part\"} $failed" \
      "# HELP ${prefix}flake_check_duration_seconds Duration of the last nightly flake check run." \
      "# TYPE ${prefix}flake_check_duration_seconds gauge" \
      "${prefix}flake_check_duration_seconds{part=\"$part\"} $((now - started))"
  '';

  # Only after a run that got through to the end (built, checked, uploaded,
  # lock pushed or nothing to push). The unit's failed state is no record:
  # the next switch clears it.
  prebuildMetrics = pkgs.writeShellScript "nix-cache-prebuild-metrics" ''
    set -eu
    started=$1
    now=$(${pkgs.coreutils}/bin/date +%s)
    ${writeProm} ${textfileDir}/nix-cache-prebuild.prom ${pkgs.coreutils}/bin/printf '%s\n' \
      "# HELP ${prefix}nix_cache_prebuild_last_success_timestamp_seconds Unix time of the last successful nightly prebuild (lock updated, hosts built, uploaded, pushed)." \
      "# TYPE ${prefix}nix_cache_prebuild_last_success_timestamp_seconds gauge" \
      "${prefix}nix_cache_prebuild_last_success_timestamp_seconds $now" \
      "# HELP ${prefix}nix_cache_prebuild_duration_seconds Duration of the last successful nightly prebuild." \
      "# TYPE ${prefix}nix_cache_prebuild_duration_seconds gauge" \
      "${prefix}nix_cache_prebuild_duration_seconds $((now - started))"
  '';

  # The checks that run after the lock push (vmTestsAttr, admin/nixlab#391):
  # tests too slow or too flaky to hold back every host's updates on - so a
  # failure here only alerts, the next night tries again. With an empty
  # list it runs nothing and reports 0, so the alerts on part "vm" stay
  # valid. From the commit the prebuild just pushed, by rev, so a pull into
  # the checkout meanwhile changes nothing under it.
  vmCheck = pkgs.writeShellScript "nix-flake-check-vm" ''
    set -euo pipefail
    started=$(date +%s)
    flake="git+file://${flakeDir}?rev=$(git -C ${flakeDir} rev-parse HEAD)"
    failed=""
    for t in $(jq -r '.[]' <<<${vmTestsJson "$flake"}); do
      echo "nix-flake-check-vm: $t"
      nix build --no-link -L "$flake#checks.${system}.$t" || failed="$failed $t"
    done
    ${flakeCheckMetrics} vm "$started" "$(wc -w <<<"$failed")"
    if [ -n "$failed" ]; then
      echo "nix-flake-check-vm: failed:$failed" >&2
      exit 1
    fi
  '';

  upload = pkgs.writers.writePython3Bin "nix-cache-upload" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./nix-cache-upload.py);

  prebuild = pkgs.writeShellScript "nix-cache-prebuild" ''
    set -euo pipefail
    started=$(date +%s)
    cd ${flakeDir}

    git checkout -- flake.lock
    # Build and sign only on top of a verified main: the lock commit below
    # is signed with a key the hosts accept, and must never end up on a
    # commit they would refuse on its own.
    ${pullCmd} .
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
    ${lib.optionalString fc.enable ''

      # Every check of the flake on the new lock, except the ones that run
      # after the push (vmTestsAttr): a failure means the new lock breaks
      # something, and it holds the lock back like a host build
      # (admin/nixlab#391, #563). First every output evaluated
      # (`nix flake check` without building; a failure there counts as the
      # one check "flake-outputs"), then the checks built in one
      # go; only when that fails one by one, for the names - which also
      # gives a VM test that failed on timing a second run, alone.
      checkStarted=$(date +%s)
      checkFailed=""
      nix flake check --no-build || checkFailed=" flake-outputs"
      gate=$(nix eval --json .#checks.${system} --apply builtins.attrNames \
        | jq -r --argjson vm ${vmTestsJson "."} '.[] | select(. as $n | $vm | index($n) | not)')
      if ! nix build --no-link -L --keep-going $(printf '.#checks.${system}.%s ' $gate); then
        for c in $gate; do
          nix build --no-link ".#checks.${system}.$c" || checkFailed="$checkFailed $c"
        done
      fi
      ${flakeCheckMetrics} gate "$checkStarted" "$(wc -w <<<"$checkFailed")"
      if [ -n "$checkFailed" ]; then
        echo "nix-cache-prebuild: checks failed:$checkFailed - flake.lock not pushed" >&2
        exit 1
      fi
    ''}

    nix-cache-upload ${stateDir}/systems/*

    # The only place that commits and pushes the lock; the hosts' own
    # upgrade (modules/auto-upgrade-git.nix) never does. Only after the upload: a host that pulls this lock finds the
    # cache already filled. Signed (commit.gpgsign in the unit's
    # environment, the rebase re-signs too) - and the rebase goes only onto
    # an upstream that passed the check, never a plain `git pull --rebase`.
    if ! git diff --quiet -- flake.lock; then
      git add flake.lock
      git commit -m "flake.lock: nightly update, prebuilt on ${config.networking.hostName} ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
      if ! git push; then
        if git fetch --quiet && up=$(git rev-parse '@{upstream}') && ${pullCmd} --verify "$up" \
          && git rebase -X theirs "$up" && git push; then
          echo "nix-cache-prebuild: pushed after rebasing onto upstream"
        else
          git rebase --abort || true
          echo "nix-cache-prebuild: could not push flake.lock" >&2
          exit 1
        fi
      fi
    fi

    ${prebuildMetrics} "$started"
    ${lib.optionalString (fc.enable && fc.vmTestsAttr != null) ''
      # Queued behind this unit (After=), so it starts once this one exits.
      systemctl start --no-block nix-flake-check-vm.service
    ''}
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

    flakeCheck = {
      enable = lib.mkEnableOption ''
        `nix flake check` on every nightly lock: all checks but the ones
        named by vmTestsAttr after the host builds, holding the lock back
        when one fails; those after the push, in nix-flake-check-vm, only
        alerting
      '';

      vmTestsAttr = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "lib.vmTestsAfterPush";
        description = ''
          Flake attribute that evaluates to a list of check names (of this
          system) to run after the lock push instead of before it: long or
          timing-sensitive tests that should not hold every host's updates
          back. null: every check runs before the push, and there is no
          nix-flake-check-vm unit.
        '';
      };
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
        extra-substituters = [ substituter ];
        extra-trusted-public-keys = [ publicKey ];
        # aldrin down or in maintenance must not stall every build: give up
        # on a connection after 5s (default: curl's own, minutes), and build
        # locally when a substituter that listed a path fails to deliver it.
        connect-timeout = 5;
        fallback = true;
        # Most of what ursalia uploads are small configuration derivations
        # (units, etc files, runCommandLocal/writeText) marked
        # allowSubstitutes = false, which Nix by default never looks up in
        # any substituter - so the hosts built them all again: 349-507 per
        # host on the nixpkgs bump of 2026-11-17 (aldrin 13 min, 1.3 GiB
        # swap). This makes Nix fetch them like anything else; measured on
        # zummi (aldrin's toplevel, admin/nixlab#326): 283 local builds down
        # to 18, a few MB from the cache. It only changes where a path may
        # come from, not which signatures are accepted.
        # With aldrin's S3 unreachable the lookups cost little: Nix 2.34's S3
        # store is its curl download (download-attempts, connect-timeout
        # above), one lookup fails after ~30 s and the cache is disabled for
        # 60 s - aldrin's toplevel on zummi with the cache unreachable: dry
        # run 34 s with, 31 s without this option; real build 23 min 54 s,
        # against 22 min 38 s with no lab cache at all. The nightly upgrade
        # skips the cache outright when it does not answer
        # (reachabilityCheck, admin/nixlab#460).
        always-allow-substitutes = true;
      };

      systemd.services.nix-daemon.environment = awsEnv;
      systemd.services.nixos-upgrade.environment = awsEnv;
      # Ahead of system.autoUpgrade's own script, in the same shell, so the
      # export reaches nixos-rebuild.
      systemd.services.nixos-upgrade.script = lib.mkIf config.system.autoUpgrade.enable (
        lib.mkBefore reachabilityCheck
      );
    }

    (lib.mkIf cfg.prebuild.enable {
      sops.secrets.nix_cache_push_key_id.sopsFile = ../hosts/ursalia/nix-cache.yaml;
      sops.secrets.nix_cache_push_secret_key.sopsFile = ../hosts/ursalia/nix-cache.yaml;
      sops.secrets.nix_cache_signing_key.sopsFile = ../hosts/ursalia/nix-cache.yaml;
      # SSH key for the flake.lock commit (`just prebuild-signing-key`),
      # lock-only in git-signers.nix. root-only, like the deploy key.
      sops.secrets.git_signing_key = {
        sopsFile = ../hosts/ursalia/git-signing.yaml;
        mode = "0400";
        owner = "root";
      };

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
        path = [
          config.nix.package
          pkgs.git
          pkgs.openssh
          pkgs.jq
          pkgs.rclone
          upload
          config.systemd.package
        ];
        environment = awsEnv // {
          inherit (config.systemd.services.nixos-upgrade.environment)
            GIT_SSH_COMMAND
            GIT_AUTHOR_EMAIL
            GIT_COMMITTER_EMAIL
            ;
          GIT_AUTHOR_NAME = "${config.networking.hostName} nix-cache-prebuild";
          GIT_COMMITTER_NAME = "${config.networking.hostName} nix-cache-prebuild";
          # Sign every commit this unit makes (the lock commit and its
          # rebase) - git config from the environment, so the checkout's
          # own config stays untouched.
          GIT_CONFIG_COUNT = "3";
          GIT_CONFIG_KEY_0 = "gpg.format";
          GIT_CONFIG_VALUE_0 = "ssh";
          GIT_CONFIG_KEY_1 = "user.signingkey";
          GIT_CONFIG_VALUE_1 = config.sops.secrets.git_signing_key.path;
          GIT_CONFIG_KEY_2 = "commit.gpgsign";
          GIT_CONFIG_VALUE_2 = "true";
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
      # The VM tests too: they keep the CPU busy, and their outputs have no
      # GC root either.
      systemd.services.nixos-upgrade.after = [
        "nix-cache-prebuild.service"
      ]
      ++ lib.optional (fc.enable && fc.vmTestsAttr != null) "nix-flake-check-vm.service";

      # The same for the nightly GC (03:15): the prebuild keeps its results
      # as out-links under ${stateDir}/systems, but a build still running
      # has no link yet, and its fresh outputs would be swept. The prebuild
      # is Type=oneshot, so its start job stays queued until the script
      # exits, and a start job for nix-gc queued meanwhile waits behind it
      # (After= delays a job while the other unit still has a job, not only
      # inside one transaction). Nothing changes on quiet nights.
      systemd.services.nix-gc.after = [
        "nix-cache-prebuild.service"
      ]
      ++ lib.optional (fc.enable && fc.vmTestsAttr != null) "nix-flake-check-vm.service";

      systemd.services.nix-flake-check-vm = lib.mkIf (fc.enable && fc.vmTestsAttr != null) {
        description = "Run the flake's VM tests on the lock the nightly prebuild pushed";
        # Started by the prebuild; after it also when started by hand.
        after = [ "nix-cache-prebuild.service" ];
        restartIfChanged = false;
        path = [
          config.nix.package
          pkgs.git
          pkgs.jq
          pkgs.coreutils
        ];
        # root's nix substitutes itself (see credentials above).
        environment = awsEnv;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = vmCheck;
          TimeoutStartSec = "60min";
          PrivateTmp = true;
          Nice = 10;
        };
      };

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
