# auto-upgrade-git-pull: fast-forward a checkout to its upstream, but only
# to a commit whose SSH signature checks out. Used by
# modules/auto-upgrade-git.nix (the nightly upgrade), by modules/
# nix-cache.nix (the prebuild) and by hand; tested by
# tests/auto-upgrade-git-pull.nix.
#
#   auto-upgrade-git-pull <dir>           fetch, verify @{upstream}, merge --ff-only
#   auto-upgrade-git-pull --verify <rev>  only verify <rev> (in the current directory)
#
# The rule, walked from the commit to be merged:
#   - signed by a trusted signer: accepted, and everything before it with it.
#     The signer vouches for the whole history it signed on top of.
#   - signed by a lock-only signer: accepted only if it has exactly one
#     parent and changes `lockFile` and nothing else; then its parent is
#     checked the same way. So a host that signs the nightly lock update
#     cannot launder anything else - not its own changes, and not an
#     unsigned commit someone slipped in underneath.
#   - anything else (unsigned, unknown key, bad signature): refused.
#
# `%G?` and `%GS` rather than `git verify-commit`: the latter would refuse
# an unknown key as well (git 2.54: `%G?` = U, exit 1), but the signer's
# name from the allowed-signers file is what picks one of the two rules.
#
# A merge made on github.com carries GitHub's PGP signature; git then tries
# gpg, which is deliberately not here ("cannot run gpg"), and `%G?` is N -
# refused like any other commit outside the list.
#
# Two layers: `core` reads its settings from the environment, so the test
# can run it against keys generated at build time; the package itself is a
# wrapper that fixes those settings to the signers given here.
{
  lib,
  writeShellApplication,
  writeText,
  git,
  openssh,
  coreutils,
}:

{
  trustedSigners,
  lockOnlySigners ? { },
  lockFile ? "flake.lock",
}:

let
  names = builtins.attrNames;

  core = writeShellApplication {
    name = "auto-upgrade-git-pull-core";
    runtimeInputs = [
      git
      openssh
      coreutils
    ];
    text = ''
      allowed=$AUTO_UPGRADE_GIT_ALLOWED_SIGNERS
      trusted=" $AUTO_UPGRADE_GIT_TRUSTED "
      lockonly=" $AUTO_UPGRADE_GIT_LOCK_ONLY "
      lockfile=$AUTO_UPGRADE_GIT_LOCK_FILE

      die() { echo "auto-upgrade-git-pull: $*" >&2; exit 1; }
      sig() { git -c gpg.format=ssh -c gpg.ssh.allowedSignersFile="$allowed" log -1 --format="$1" "$2"; }

      verify() {
        local rev status signer parents changed
        rev=$(git rev-parse --verify --quiet "$1^{commit}") || die "$1: no such commit"
        while :; do
          status=$(sig %G? "$rev")
          [ "$status" = G ] || die "$rev: no good signature from an allowed signer (git %G? = $status) - refusing"
          signer=$(sig %GS "$rev")
          case "$trusted" in *" $signer "*)
            echo "auto-upgrade-git-pull: $rev signed by $signer"
            return 0 ;;
          esac
          case "$lockonly" in *" $signer "*) ;; *)
            die "$rev: signer $signer is not allowed" ;;
          esac
          parents=$(git rev-list --parents -n 1 "$rev" | wc -w)
          [ "$parents" -eq 2 ] || die "$rev: signed by lock-only $signer but is not a plain commit with one parent"
          changed=$(git diff-tree --no-commit-id --name-only -r "$rev")
          [ "$changed" = "$lockfile" ] || die "$rev: signed by lock-only $signer but changes more than $lockfile: $(echo "$changed" | tr '\n' ' ')"
          echo "auto-upgrade-git-pull: $rev signed by $signer, $lockfile only"
          rev=$(git rev-parse "$rev^")
        done
      }

      if [ "''${1:-}" = --verify ]; then
        [ $# -eq 2 ] || die "usage: auto-upgrade-git-pull --verify <rev>"
        verify "$2"
        exit 0
      fi
      [ $# -eq 1 ] || die "usage: auto-upgrade-git-pull <dir> | --verify <rev>"

      cd "$1"
      git fetch --quiet
      upstream=$(git rev-parse --verify '@{upstream}^{commit}')
      # Nothing new: nothing to verify. Also keeps a checkout whose own HEAD
      # predates signing working until the first signed commit arrives.
      if git merge-base --is-ancestor "$upstream" HEAD; then
        echo "auto-upgrade-git-pull: up to date"
        exit 0
      fi
      verify "$upstream"
      # The commit just verified, by hash - not @{upstream}, which another
      # fetch could have moved meanwhile.
      git merge --ff-only --quiet "$upstream"
    '';
  };

  # ssh-keygen's allowed-signers format: one principal and key per line,
  # limited to git's signature namespace.
  line = principal: key: ''${principal} namespaces="git" ${lib.trim key}'';
  allowedSigners = writeText "auto-upgrade-git-allowed-signers" (
    lib.concatStrings (lib.mapAttrsToList (p: k: line p k + "\n") (trustedSigners // lockOnlySigners))
  );
in
assert lib.assertMsg (
  trustedSigners != { }
) "auto-upgrade-git-pull: trustedSigners must not be empty";
assert lib.assertMsg (builtins.all (p: builtins.match "[A-Za-z0-9._@-]+" p != null) (
  names (trustedSigners // lockOnlySigners)
)) "auto-upgrade-git-pull: signer names may only use letters, digits and ._@-";
assert lib.assertMsg (
  lib.intersectLists (names trustedSigners) (names lockOnlySigners) == [ ]
) "auto-upgrade-git-pull: a signer cannot be both trusted and lock-only";

(writeShellApplication {
  name = "auto-upgrade-git-pull";
  text = ''
    export AUTO_UPGRADE_GIT_ALLOWED_SIGNERS=${allowedSigners}
    export AUTO_UPGRADE_GIT_TRUSTED=${lib.escapeShellArg (toString (names trustedSigners))}
    export AUTO_UPGRADE_GIT_LOCK_ONLY=${lib.escapeShellArg (toString (names lockOnlySigners))}
    export AUTO_UPGRADE_GIT_LOCK_FILE=${lib.escapeShellArg lockFile}
    exec ${lib.getExe core} "$@"
  '';
}).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      inherit core allowedSigners;
    };
  })
