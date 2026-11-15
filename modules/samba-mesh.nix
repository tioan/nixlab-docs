# Samba for the NetBird mesh: the lab's SMB policy (SMB3 only, macOS
# friendly, no guests, no NetBIOS, mesh clients only) and the passwords of
# the Samba-only accounts from sops. Shares, the accounts themselves and
# their file permissions stay with the host - ursalia's Paperless consume
# share (hosts/ursalia/samba.nix), tummi's /data. Taken out of
# hosts/ursalia/samba.nix when tummi got a share (2026-11-01).
#
# Accounts are Samba-only (no shell, no login, no home); SMB authenticates
# with NTLMv2 against a password hash, which Pocket ID (passkeys, no LDAP)
# cannot serve. Their passwords: smb_password_<user> in the host's default
# sops file, entered with `just secrets <host>`.
#
# Reachable over the NetBird mesh only: smbd listens everywhere, the firewall
# admits 445 only on the trusted nb-mesh (openFirewall stays off, the LAN
# side has no 445), and "hosts allow" limits clients to the mesh.
{ config, lib, ... }:
let
  cfg = config.services.sambaMesh;
in
{
  options.services.sambaMesh = {
    enable = lib.mkEnableOption "Samba for the NetBird mesh";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Samba-only accounts whose SMB password is set from sops
        (smb_password_<user>) on every boot and switch. The system users
        themselves are declared by the host.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = false; # nb-mesh is a trusted interface anyway
      nmbd.enable = false; # no NetBIOS
      winbindd.enable = false;
      settings.global = {
        "server string" = config.networking.hostName;
        # No "interfaces"/"bind interfaces only": tailscale0 carried /32 and
        # /128 addresses, which Samba skips - it then listened on loopback
        # only (seen on ursalia 2026-10-16). smbd listens everywhere instead;
        # the firewall admits 445 only on the trusted nb-mesh and hosts allow
        # limits clients to the mesh.
        "hosts allow" = "127.0.0.1 ::1 192.0.2.0/24 2001:db8:203:0::/64";
        "hosts deny" = "ALL";
        "disable netbios" = "yes";
        "smb ports" = "445";
        # The iX1600 speaks SMB up to 3.0.2/3.1.1; macOS anyway.
        "server min protocol" = "SMB3";
        "server smb encrypt" = "desired";
        "ntlm auth" = "ntlmv2-only";
        "map to guest" = "never";
        "restrict anonymous" = "2";
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "unix charset" = "UTF-8";
        # macOS: keep Finder metadata as xattrs instead of ._ files.
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "yes";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        # Finder sends the Mac file mode along (often 0700) as NFS ACEs, and
        # Samba applied it - the ACL mask dropped to rw for the owner only and
        # paperless' consumer got "Permission denied" (seen 2026-10-16).
        # Ignore them; the shares' modes decide.
        "fruit:nfs_aces" = "no";
      };
    };

    # smbpasswd -a both creates and updates.
    sops.secrets = lib.genAttrs (map (u: "smb_password_${u}") cfg.users) (_: { });

    systemd.services.samba-passwords = lib.mkIf (cfg.users != [ ]) {
      description = "Set Samba passwords for the share users";
      after = [ "samba-smbd.service" ];
      wants = [ "samba-smbd.service" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = map (u: config.sops.secrets."smb_password_${u}".sopsFile) cfg.users;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = lib.concatMapStrings (u: ''
        pw="$(< ${config.sops.secrets."smb_password_${u}".path})"
        printf '%s\n%s\n' "$pw" "$pw" | ${config.services.samba.package}/bin/smbpasswd -s -a ${u} >/dev/null
        echo "samba password set for ${u}"
      '') cfg.users;
    };
  };
}
