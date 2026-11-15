# Failure modes

What actually happens when a part of the lab fails: who notices and how fast, the way the alert takes, what stops working, and how it comes back. Rows describe the configuration as it is, not as it should be. Where nothing has been rehearsed, the row says "not tested". The idea of such a matrix comes from Node64 by Dennis Schröder (Apache-2.0, [AUSFALLVERHALTEN.md at 68b0c62](https://github.com/ipv64net/node64/blob/68b0c62fe986b490168e5ea9bc990d71f72022cc/docs/AUSFALLVERHALTEN.md)); only the idea is adopted (#170).

## How alerts travel { #alert-path }

vmalert and Alertmanager on **grammi** → webhook over the **NetBird mesh** → **Home Assistant** at home → push to the iPhone. Every link in that chain is also a row below. Times add up: a rule's `for`, then Alertmanager's `group_wait` of 1 min. Between 04:00 and 06:00 everything but the Watchdog is muted and arrives at 06:00 if it still fires. HostGone suppresses the other alerts of the same host. Details: [Monitoring](monitoring.md#alerting).

Two independent ways notice when that chain itself breaks:

- **HA's timer** (`timer.nixlab_alerting_heartbeat`, 20 min), restarted by the Watchdog every 5 min. Covers grammi, vmalert, Alertmanager and the mesh path to HA.
- **healthchecks.io** (#169), outside the lab, with its own email and push: the Watchdog, grammi's ping while Pocket ID's probes pass, and HA's own ping. Covers what the timer cannot: HA itself, and the home connection.

## Matrix { #matrix }

| Case | Who notices, how fast | Alert path | Effect | Recovery | Last tested |
| --- | --- | --- | --- | --- | --- |
| **grammi down** | HA timer after ≤ 20 min ("nixlab Alerting stumm"); healthchecks.io (Watchdog and probe ping stop, after its grace time) | HA push; healthchecks.io email/push | No alerting, no Grafana/metrics/logs view; NetBird management, Traefik, the NetBird proxy (mesh services on the internet) and the group sync are down. Existing tunnels keep working, new peers and logins fail. Metrics and logs queue on the hosts (vmagent disk queue, Vector backpressure) | Restore from restic onto a new machine, `docs/site/*/how-to/restore-test.md`. Hardware watchdog resets a hung kernel or PID 1 (30 s, VM) | Restore 2026-11-02, RTO 38 s once a machine exists. Outage of the alert path itself: not tested |
| **Home Assistant down** | healthchecks.io (HA's ping stops) | healthchecks.io only – the push path is HA itself | No push for any alert; Alertmanager keeps retrying and delivers what still fires once HA is back. Home automation stops | HA OS backups (daily, Nabu Casa) | not tested |
| **Home internet or gruffi down** | healthchecks.io (HA's ping stops); grammi raises HostGone for the home hosts, but cannot deliver it | healthchecks.io only | Everything at home is unreachable from outside: ursalia, tummi, zorlock, HA. The push path is gone, alerts arrive afterwards. Public services on aldrin and zummi stay up | On site: power-cycle gruffi; the strip's button if it has no Wi-Fi. The power watchdog on ursalia is a **dry run** and does not switch (nixlab#177). First boot after power loss: PPPoE needs 1–2 × 35 s | not tested; gruffi Wi-Fi recovered by a power cut on 2026-11-06 (incident) |
| **gruffi up, Wi-Fi module missing** | GruffiWifiMissing after 5 min; HA push when the strip is out of reach for 5 min | grammi → HA, and HA alone | No Wi-Fi at home; the strip is unreachable, so no remote cold boot | On site: save `dmesg`, 30 s without power, or plug in ap-og (nixlab#93) | incident 2026-11-02 to -06 |
| **NetBird mesh broken** (management or path grammi → HA) | HA timer after ≤ 20 min; healthchecks.io only if grammi's ping also fails | HA push (from HA's own timer) | Alerts do not reach HA. No dedicated alert for the management server; TargetDown/HostGone see it only indirectly | admin jump to the host's own mesh address (`modules/ssh.nix`), provider console with the root password | rehearsed 2026-11-15 |
| **zummi down** | healthchecks.io (grammi's ping stops with Pocket ID); HostGone after 10 min | healthchecks.io; HA push | Pocket ID down: no new login anywhere (services, NetBird). Probes of aldrin stop (PublicProbeMissing) | Restore, RTO 48 s once a machine exists; softdog resets a hung kernel | Restore 2026-11-02; softdog reset 2026-11-03 (login down ~9 min) |
| **aldrin down** | PublicServiceDown from zummi after 5 min; HostGone after 10 min | HA push | Garage S3 (restic target of every host, nix cache), OpenCloud, floccus, shortener, gw-remote and the remote site, an exit node. Backups fail to upload until it is back | Provider console; aldrin has no provider backup, btrbk is local (nixlab#22) | not tested |
| **ursalia down** | HostGone after 10 min (for gruffi's metrics too, scraped from ursalia) | HA push | paperless, Immich, HealthLog, docs, AdGuard (mesh clients fall back to their own DNS, the LAN has none), the nightly prebuild and flake.lock update, the gruffi power watchdog | Hardware watchdog (60 s) for a hung kernel; otherwise on site | AdGuard fallback 2026-11-01; watchdog resets 2026-11-02/03 (incident, not a test) |
| **tummi down** | HostGone after 10 min | HA push | Samba share "Daten" and its restic job | On site | not tested |
| **One Remote uplink down** | RemoteUplinkDown after 30 min | HA push | Traffic moves to the other uplink after ~20 s (`keepalive 2 10`); no failover left | Usually by itself; uplink1 drops every night 22:53–03:03 (#145) | failover 2026-11-02 |
| **Both Remote uplinks down** | RemoteSiteUnreachable after 10 min | HA push | The remote site is unreachable | At the site (ER7206) | isolation test 2026-11-02; total outage not tested |
| **Remote uplink flapping** | RemoteUplinkFlapping at 4 new sessions in 30 min, stays 15 min after | HA push | Repeated short drops of a few seconds each | Look at the provider line or the ER7206 | backtest against 2026-11-02 to -15: never fired |
| **Exporter down / flapping** | TargetDown after 15 min; TargetFlapping at 3 drops in an hour | HA push | Missing metrics for that exporter; the service itself may be fine | Restart the exporter or the scrape | backtest: TargetFlapping would have fired twice in two weeks, both during network work |
| **Host stops sending** | HostGone after 10 min | HA push | All metrics of the host; other alerts of the host are suppressed | Depends on the host, see its row | not tested |
| **Kernel or PID 1 hangs** | nobody: the hardware watchdog resets the host (60 s NUCs, 30 s VMs, softdog on zummi) | – then HostGone if it does not come back | Short outage, reboot | Automatic; HardwareWatchdogInactive if systemd does not hold the device | zummi 2026-11-03; `kill -SEGV 1` procedure not run |
| **Unit fails** | UnitFailed within ~5 min (journal), also between switches | HA push | That service | Fix and deploy; the alert clears once the failure leaves the 30-min window | selftest procedure exists, date not recorded |
| **Nightly upgrade fails** | NixosUpgradeStale after 26 h (not under a deploy hold) | HA push | Host stays on the old generation; a broken boot takes the host down at 04:00 | Provider console or on site; rollback to the previous generation | not tested |
| **Backup fails** | BackupRunFailed after 5 min, BackupNotVerified after 26 h, BackupBucketNoNewObject (aldrin's view) | HA push (after 06:00 if at night) | No new verified snapshot | restic-verified retries at 05:15 and 07:15 | `just test-restic-verified`, date not recorded |
| **Disk full** | DiskFull above 85 % for 15 min | HA push | Depends on the mount | Free space | not tested |
| **Certificate not renewed** | CertExpiring below 21 days (file), ServedCertExpiring below 14 days (served) | HA push | Nothing yet – renewal starts at 30 days | Check ACME/deSEC; reload the listener | not tested |
| **Matter reports dropped** | MatterReportsRejected after 5 min; MatterDevicesUnavailable after 30 min | HA push (via HA, so not if HA is down) | Motion and door reports do not reach HA | Fix the address in gruffi's Matter rules (nixlab#46) | incident 2026-11-14 |

## Gaps { #gaps }

- Home Assistant and the home connection are covered only by healthchecks.io. Its grace time is set there, not in this repository.
- None of the alert path rows (grammi, HA, mesh, internet) has been rehearsed end to end.
- The gruffi power watchdog does not switch yet; going live needs a week of dry run and a rehearsal (nixlab#177).
- There is no alert of its own for the NetBird management server.
