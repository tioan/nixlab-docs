# Shared sshd policy. The authorized keys themselves stay per host - each host
# has its own keypair on purpose - so this module only defines *who may log in
# from where*, never *with which key*.
{ ... }:
{
  services.openssh = {
    enable = true;

    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;

    # Port 22 stays open to the internet, but only for unprivileged users
    # (i.e. admin, by key). root is refused there entirely.
    settings.PermitRootLogin = "no";

    # ...and re-permitted only for connections that arrive on the host's own
    # Tailscale or NetBird address. LocalAddress rather than Address on
    # purpose: it keys on which local IP sshd accepted the connection on,
    # which a remote peer cannot spoof the way it could a source address.
    # Ranges are Tailscale's CGNAT v4 block and its ULA v6 prefix, and the
    # NetBird mesh (192.0.2.0/24, terraform/netbird). The Tailscale ranges
    # stay until Tailscale is removed from the hosts.
    #
    # Verified with `sshd -T -C ...`:
    #   laddr=<public>          -> permitrootlogin no
    #   laddr=100.x / fd7a:...  -> permitrootlogin without-password
    #   laddr=<public>, addr spoofed into 100.64/10 -> permitrootlogin no
    #
    # NOTE: this must stay in extraConfig, not settings - the NixOS module
    # appends extraConfig after the generated settings, which is where sshd
    # requires Match blocks to live. Deploys therefore go over the mesh; see
    # the host addresses in the justfile.
    extraConfig = ''
      Match LocalAddress 100.64.0.0/10,fd7a:115c:a1e0::/48,192.0.2.0/24
        PermitRootLogin prohibit-password
    '';
  };
}
