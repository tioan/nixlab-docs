# Log retention.
#
# File logs are already handled: NixOS enables logrotate by default and the
# nginx module ships its own rule (weekly, 26 rotations, compressed). That rule
# rotates by rename plus `kill -USR1`, not copytruncate, which matters here -
# CrowdSec tails /var/log/nginx/*.log and follows the new inode cleanly, and
# the rotated access.log.1 does not match the glob, so nothing is read twice.
#
# journald is the part nobody bounds: it rotates itself, not via logrotate, and
# defaults to 10% of the filesystem capped at 4G. On zummi that had grown to
# 2.6G, most of it the constant SSH bot noise on port 22.
#
# Deliberately capping the size rather than quieting sshd: that noise is
# exactly what CrowdSec parses into ssh-bruteforce scenarios, so turning down
# the log level would blind the detection to save disk that is not scarce.
{
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    SystemMaxFileSize=128M
    MaxRetentionSec=1month
  '';
}
