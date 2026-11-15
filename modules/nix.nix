# Nix daemon and store housekeeping, shared by every host.
{ config, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Flakes only - no channels. Every host builds from its /etc/nixos flake,
  # pinned by flake.lock; a channel is a second, unpinned nixpkgs nobody
  # updates (nixos-install on ursalia left one registered in
  # /root/.nix-channels, never even downloaded). With channels off, legacy
  # `<nixpkgs>` / `nix-shell -p` still resolve: nixpkgs.lib.nixosSystem sets
  # nixpkgs.flake.source, so NIX_PATH and the `nixpkgs` registry entry point at
  # the flake's own pinned nixpkgs.
  nix.channel.enable = false;

  # Keep the last 10 system generations rather than everything from the last
  # N days. A test-heavy evening can easily produce fifteen generations, which
  # a time window happily keeps all of; a count gives a hard ceiling and still
  # leaves plenty of rollback targets.
  #
  # nix.gc.options is handed straight to nix-collect-garbage, which only knows
  # --delete-old / --delete-older-than / --max-freed - there is no count there.
  # Trimming by count is nix-env's job, so it runs as a pre-step and the GC
  # afterwards only has to sweep up what became unreachable.
  #
  # Worth knowing: store paths from testing that no generation references -
  # failed builds, `nix build` results without a GC root - were never held by
  # the time window in the first place. They are collected on every run.
  nix.gc = {
    automatic = true;
    dates = "03:15";
    options = "";
  };

  systemd.services.nix-gc.serviceConfig.ExecStartPre = [
    "${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +10"
  ];

  # Collect on demand as well, so the store cannot fill the disk between two
  # nightly runs: below min-free the daemon starts collecting, and it stops
  # once max-free is available again.
  nix.settings.min-free = 5 * 1024 * 1024 * 1024;
  nix.settings.max-free = 20 * 1024 * 1024 * 1024;

  # Hardlink identical files in the store. Deletes nothing, just stops paying
  # for the same file twice - which is most of what a series of near-identical
  # test builds produces.
  nix.optimise.automatic = true;
}
