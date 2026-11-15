# Shared Tailscale setup. Per-host `tailscale serve` definitions stay in the
# host's own configuration.nix - only the node agent itself is common.
{ config, pkgs, ... }:
{
  services.tailscale.enable = true;

  systemd.services.tailscaled = {
    # tailscaled registers MagicDNS with systemd-resolved at startup, over
    # D-Bus, and that registration lives only in the running process. Change
    # resolved's configuration and tailscale0 loses its DNS scope - tailnet
    # names stop resolving, silently, because nothing on the host fails loudly
    # for it. Restarting tailscaled re-registers it.
    restartTriggers = [ config.environment.etc."systemd/resolved.conf".source ];

    # NOTE for whoever reads the git history and wonders where two workarounds
    # went. This unit briefly carried both `Restart = always` and
    # `restartIfChanged = false`; both are gone, and deliberately so.
    #
    # The symptom was tailscaled ending up stopped after a nixos-rebuild switch
    # with a clean exit 0, taking every connection over tailscale0 with it -
    # including the SSH session driving the deploy. Restart=always caught the
    # exit, restartIfChanged=false was aimed at switch-to-configuration.
    #
    # Neither was the cause. ifstate was deleting tailscale0 and Tailscale's
    # routing rules on every activation (see parameters.ignore below);
    # tailscaled noticed its TUN device had vanished and shut itself down. With
    # that fixed, Restart=always would only paper over a genuine failure the
    # way it papered over this one for months, and restartIfChanged=false only
    # suppresses the one restart that is actually correct: the one after the
    # unit changes, i.e. after a tailscale package update. It also suppressed
    # restartTriggers, which is what makes the line above work at all.
    #
    # A separate `tailscaled-restart-on-upgrade` oneshot used to reimplement
    # that package-update restart by hand. Unnecessary: ExecStart references
    # ${pkgs.tailscale}/bin/tailscaled, so a package change rewrites the unit
    # and the ordinary mechanism restarts it.
  };

  # THE actual root cause behind those workarounds.
  #
  # ifstate reconciles the entire link and routing state on every activation
  # and removes whatever its config does not declare. Tailscale's state is not
  # declared there, so every `nixos-rebuild switch` deleted the policy routing
  # rules tailscaled installs at priorities 5210/5230/5250/5270 (v4 and v6 -
  # visible as "#5210 (inet) del" in `journalctl -u ifstate`) along with the
  # tailscale0 link. tailscaled then loses its TUN device
  # ("failed to get MTU of TUN device: no such device") and shuts itself down.
  #
  # Lives under `parameters`, not at the top level - the schema's top level
  # only allows parameters/bpf/interfaces/mac_seed/routing/sysctl/namespaces.
  #
  # Additive, not replacing: ifstate keeps its own defaults in the parallel
  # `ifname_builtin` / `rules_builtin` keys, so the built-in exceptions for lo
  # and friends stay intact.
  #
  # The rules are matched by priority alone so this does not encode more
  # Tailscale internals than necessary. Verify after deploying with
  #   ifstatecli -c $(systemctl cat ifstate.service | sed -n 's/.*--config \([^ ]*\).*/\1/p') check
  # which must no longer list any "#52x0 ... del".
  networking.ifstate.settings.parameters.ignore = {
    ifname = [ "^tailscale\\d+$" ];
    rules = [
      { priority = 5210; }
      { priority = 5230; }
      { priority = 5250; }
      { priority = 5270; }
    ];
  };

  # Tailscale SSH had been enabled imperatively on aldrin (`RunSSH: true`),
  # which meant tailscaled - not sshd - answered port 22 on the Tailscale
  # address, and root access there was authorised by tailnet ACLs rather than
  # by root's authorized_keys. That bypassed the Match block in modules/ssh.nix
  # and made the two hosts behave differently. Pin it off everywhere so a
  # `tailscale up` re-auth cannot silently bring it back.
  systemd.services.tailscale-ssh-off = {
    description = "keep Tailscale SSH disabled (sshd owns port 22)";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale set --ssh=false";
    };
  };
}
