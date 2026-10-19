# How this lab ships and updates itself: every host keeps /etc/nixos as a
# checkout of the Codeberg repo, pulls from it on deploy, and upgrades itself
# nightly - committing the refreshed flake.lock back.
#
# Kept separate from modules/auto-upgrade-git.nix on purpose. That module
# documents itself as host-agnostic and reusable; hardcoding a git forge and a
# specific secret name into it would take that away. It stays the mechanism,
# this file is the lab's policy.
{ config, ... }:
{
  # Write-enabled deploy key for the repo, used both by a manual `git pull` on
  # the host and by the nightly flake.lock push. Add it on the machine itself
  # with `just secrets <host>` - this workstation holds no key that can decrypt
  # these files.
  sops.secrets."codeberg_deploy_key" = { };

  programs.ssh.extraConfig = ''
    Host codeberg.org
     User git
     IdentityFile ${config.sops.secrets."codeberg_deploy_key".path}
     IdentitiesOnly yes
  '';

  # Pinned rather than trusted on first use: the nightly upgrade runs
  # unattended, so there is nobody to eyeball a changed host key.
  programs.ssh.knownHosts."codeberg.org" = {
    hostNames = [ "codeberg.org" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
  };

  services.autoUpgradeGit = {
    enable = true;
    # nixpkgs-unstable is only evaluated by grammi (Grist), but bumping it
    # from any host's run is harmless - the others never read it - and
    # keeps Grist on current security fixes like everything else.
    updateInputs = [ "nixpkgs" "nixpkgs-unstable" "sops-nix" ];

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

    deployKeySecret = "codeberg_deploy_key";
  };
}
