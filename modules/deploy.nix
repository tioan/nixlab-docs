# How this lab ships and updates itself: every host keeps /etc/nixos as a
# checkout of the private GitHub repo admin/nixlab, pulls from it on deploy,
# and upgrades itself nightly - committing the refreshed flake.lock back.
#
# Kept separate from modules/auto-upgrade-git.nix on purpose. That module
# documents itself as host-agnostic and reusable; hardcoding a git forge and a
# specific secret name into it would take that away. It stays the mechanism,
# this file is the lab's policy.
{ config, ... }:
let
  signers = import ../git-signers.nix;
in
{
  # Deploy key for the repo, used by a manual `git pull` on the host and by
  # the nightly upgrade. Read-only everywhere except ursalia, whose
  # nix-cache-prebuild pushes flake.lock (terraform/github/main.tf).
  # Generated on the workstation by `just github-key <host>`: the private
  # half sops-encrypted for this host in hosts/<host>/github.yaml, the public
  # half registered on GitHub by terraform/github.
  sops.secrets."github_deploy_key" = {
    sopsFile = ../hosts + "/${config.networking.hostName}/github.yaml";
  };

  programs.ssh.extraConfig = ''
    Host github.com
     User git
     IdentityFile ${config.sops.secrets."github_deploy_key".path}
     IdentitiesOnly yes
  '';

  # Pinned rather than trusted on first use: the nightly upgrade runs
  # unattended, so there is nobody to eyeball a changed host key. GitHub's
  # published Ed25519 host key (docs.github.com, "GitHub's SSH key
  # fingerprints", SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU).
  programs.ssh.knownHosts."github.com" = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  # The inputs the nightly run updates. nixpkgs-unstable is evaluated
  # by grammi, ursalia, aldrin, zorlock and the docs site (flake.nix lists
  # what each takes from it); bumping it for everyone is harmless - the
  # others never read it - and keeps those on current security fixes like
  # everything else.
  #
  # Since 2026-10-31 one host updates them for the whole lab: ursalia's
  # nix-cache-prebuild (modules/nix-cache.nix) updates flake.lock, builds
  # every host, fills the nix cache and pushes the lock. The hosts' own
  # upgrade only pulls it and substitutes, instead of each one updating -
  # and possibly building from source - on its own.
  #
  # sops-nix is not in the list: its activation code runs as root with every
  # secret of the host, so it is bumped by hand, with the diff read first
  # (`nix flake update sops-nix`, #313).
  services.nixCache.prebuild.updateInputs = [
    "nixpkgs"
    "nixpkgs-unstable"
  ];

  services.autoUpgradeGit = {
    enable = true;
    updateInputs = [ ];
    pull = true;

    # These are rented VMs with out-of-band console access, so an unattended
    # reboot is recoverable - and the reboot window keeps it out of the way.
    #
    # Note what that means in practice: a configuration error that only shows
    # up on a cold boot takes the machine down at 04:00 with nobody watching.
    # That is not hypothetical; the ifstate routes in both hosts had exactly
    # that defect until it surfaced on 2026-08-11.
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };

    deployKeySecret = "github_deploy_key";

    # Pull only to commits signed per git-signers.nix (#304): a push to main
    # from a stolen GitHub session or a compromised host's key is not
    # enough to become root here at 04:00. A refused tip fails the run and
    # the host stays where it is; NixosUpgradeStale reports it after a while.
    verifySignatures = {
      enable = true;
      trustedSigners = signers.trusted;
      lockOnlySigners = signers.lockOnly;
    };

    # `just try` holds (modules/deploy-hold.nix). The check also lifts a hold
    # whose branch has been merged and pulled into /etc/nixos meanwhile.
    holdFile = "/etc/nixos-hold";
    holdCheck = "/run/current-system/sw/bin/nixos-hold merged /etc/nixos";
  };
}
