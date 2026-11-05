# Troubleshooting

- Nach einem `nixos-rebuild` sagt `systemctl --failed` nichts über die Vergangenheit – der Switch räumt Failed-States ab. Stattdessen `journalctl -u <unit>`.
- NetBird down, Tailscale noch da: `NIXLAB_DOMAIN=example-tailnet.ts.net` vor das Rezept setzen.
- Tofu-Rezepte verweigern den Lauf gegen leeren State, damit keine zweite `servers`-Gruppe oder Token-Garnitur entsteht.
- WLAN auf tummi: `iw dev wlo1 link` zeigt Band, Signal und PHY-Modus. Das 5-GHz-Netz des Routers liegt auf Kanal 36–48 ohne DFS mit 100 TU Beacon-Intervall; Band, Signal, Raten und PHY-Modus gehen auch an VictoriaMetrics (node_exporter-Collector `wifi` plus `wifi_link_*`), Grafana-Dashboard „Homelab / WLAN“.
- Nach einem Netzwechsel kann NetBird minutenlang an einem toten P2P-Weg festhalten und trotzdem `Connected` zeigen (gesehen auf ursalia, 2026-10-19). Abhilfe: `systemctl restart netbird-mesh` auf dem Host, notfalls über Tailscale.
- Ein Proxy-Dienst hängt im NetBird-Dashboard bei „Issuing certificate…“ oder liefert von außen einen TLS-Fehler („internal error“): `just netbird-proxy-certs` – fragt die Namen ohne Zertifikat von außen ab und startet `netbird-proxy` auf grammi neu (NetBird-Diskussion #7118). Läuft auch am Ende von `just netbird-apply`.
- Ein Host ist ohne Shutdown im Journal neu gestartet: im vorigen Boot nach dem Hardware-Watchdog suchen, `journalctl -b -1 -k | grep -i watchdog` („watchdog did not stop!“ heißt, ein Prozess hat ihn scharf geschaltet und ohne Magic Close losgelassen). Wo `services.hardwareWatchdog` an ist, hält systemd das Gerät, jeder andere Prozess bekommt EBUSY; `fuser -v /dev/watchdog0` zeigt den Halter, `wdctl` den Timeout. Test: `kill -SEGV 1` muss den Host innerhalb eines Timeouts zurücksetzen (#117).
