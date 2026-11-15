# Firmware updates from LVFS on the physical host (ursalia).
# Nothing is ever installed automatically, and that has to stay so: a BIOS
# capsule moves PCR 0 and with it the TPM keyslot that unlocks the disk, and
# under Secure Boot without shim the firmware runs fwupdx64.efi only when it
# is signed with the host's own sbctl key - see docs/install-ursalia.md
# ("Firmware-Updates"). Updates are installed by hand, with somebody at the
# console or the ArkKVM.
{ config, pkgs, ... }:
{
  services.fwupd.enable = true;

  # fwupd-refresh.timer (shipped with the module) keeps the LVFS metadata
  # current, but on a headless box nobody ever sees what it found. After
  # every successful refresh - and once shortly after boot - write the
  # pending releases per device into node_exporter's textfile collector, so
  # Grafana on grammi can show/alert "firmware update available".
  #
  #   fwupd_updates_available{device,current,latest}  releases newer than installed
  #   fwupd_updates_check_timestamp_seconds            when this last ran
  #
  # fwupdmgr exits 2 for "no updates"; that is a normal result here, which is
  # why its exit status is ignored and the JSON alone decides.
  systemd.services.fwupd-updates-metric = {
    description = "Pending fwupd firmware updates for node_exporter's textfile collector";
    after = [ "fwupd.service" ];
    wants = [ "fwupd.service" ];
    path = [ config.services.fwupd.package pkgs.jq pkgs.coreutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      dir=/var/lib/prometheus-node-exporter-text-files
      out=$(fwupdmgr get-updates --json --no-unreported-check --no-metadata-check 2>/dev/null || true)
      case "$out" in "{"*) ;; *) out='{}' ;; esac
      {
        echo "# HELP fwupd_updates_available Firmware releases newer than the installed version, per device."
        echo "# TYPE fwupd_updates_available gauge"
        printf '%s' "$out" | jq -r '(.Devices // [])[]
          | "fwupd_updates_available{device=\"\(.Name | gsub("\""; ""))\",current=\"\(.Version // "")\",latest=\"\(.Releases[0].Version // "")\"} \(.Releases | length)"'
        echo "# HELP fwupd_updates_check_timestamp_seconds Last time pending firmware updates were checked."
        echo "# TYPE fwupd_updates_check_timestamp_seconds gauge"
        echo "fwupd_updates_check_timestamp_seconds $(date +%s)"
      } > "$dir/fwupd.prom.tmp"
      chmod 0644 "$dir/fwupd.prom.tmp"
      mv "$dir/fwupd.prom.tmp" "$dir/fwupd.prom"
    '';
  };
  systemd.services.fwupd-refresh.onSuccess = [ "fwupd-updates-metric.service" ];
  systemd.timers.fwupd-updates-metric = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnBootSec = "10min";
  };
}
