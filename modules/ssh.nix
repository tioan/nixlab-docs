# Shared sshd policy. The authorized keys themselves stay per host - each host
# has its own keypair on purpose - so this module only defines *who may log in
# from where*, never *with which key*.
{ ... }:
{
  services.openssh = {
    enable = true;

    # Only the declared keys (/etc/ssh/authorized_keys.d) count, never
    # ~/.ssh/authorized_keys: the installer's key sat in /root/.ssh on ursalia
    # unnoticed until 2026-10-16, and hoster images often leave one behind.
    # Anything that should log in belongs in the host's
    # openssh.authorizedKeys.keys.
    authorizedKeysInHomedir = false;

    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;

    # Port 22 stays open to the internet, but only for unprivileged users
    # (i.e. admin, by key). root is refused for direct logins there.
    settings.PermitRootLogin = "no";

    # ...and re-permitted only for connections that arrive on the host's own
    # NetBird mesh address. LocalAddress rather than Address on purpose: it
    # keys on which local IP sshd accepted the connection on, which a remote
    # peer cannot spoof the way it could a source address. Ranges are the
    # mesh, 192.0.2.0/24 and its IPv6 overlay 2001:db8:203:0::/64
    # (terraform/netbird/main.tf).
    #
    # Verified with `sshd -T -C ...`:
    #   laddr=<public>          -> permitrootlogin no
    #   laddr=192.0.2.x / 2001:db8:203:0::… -> permitrootlogin without-password
    #   laddr=<public>, addr spoofed into 192.0.2.0/24 -> permitrootlogin no
    #
    # Break-glass while the mesh is down (grammi gone, gusto off the mesh),
    # kept on purpose (admin/nixlab#360, decision 2a): admin may forward TCP
    # on the public address (aldrin, grammi, zummi have one), so
    #   ssh -i ~/.ssh/pub/<host>.homelab.example.pub \
    #     -J admin@<host>.homelab.example root@<host's own nb-mesh address>
    # reaches this sshd from the host itself, on its mesh LocalAddress, and
    # root gets in by key - no working mesh needed, only the address still on
    # nb-mesh (not after a reboot during the outage; then the provider
    # console with the root password, `just root-password-show <host>`).
    # Rehearsed 2026-11-15 on aldrin, zummi and grammi. It also means admin's
    # key is effectively root's from the internet; closing it (2b,
    # AllowTcpForwarding no off the mesh) belongs to the SSH hardening.
    #
    # NOTE: this must stay in extraConfig, not settings - the NixOS module
    # appends extraConfig after the generated settings, which is where sshd
    # requires Match blocks to live. Deploys therefore go over the mesh; see
    # the host addresses in the justfile.
    extraConfig = ''
      Match LocalAddress 192.0.2.0/24,2001:db8:203:0::/64
        PermitRootLogin prohibit-password
    '';
  };
}
