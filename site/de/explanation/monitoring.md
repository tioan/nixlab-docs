# Monitoring

Alles landet auf grammi: **vmagent** auf jedem Host schickt Metriken an VictoriaMetrics (`:8428`), **Vector** journald- und nginx-Logs an VictoriaLogs (`:9428`), beides über das Mesh. Grafana (`metrics`) und logchef (`logs`) liegen hinter dem Reverse Proxy mit SSO. Die Exporter je Host kommen aus `modules/metrics.nix`; was keinen eigenen Endpunkt hat, geht über den textfile-Collector von node_exporter (`/var/lib/prometheus-node-exporter-text-files`), geschrieben von kleinen Timern oder Diensten:

| Textfile-Metrik | Host | Quelle |
| --- | --- | --- |
| `tailscale_*` | Hosts mit Tailscale | `tailscale metrics write`, alle 30 s |
| `fwupd_updates_*` | ursalia | `fwupdmgr get-updates` nach jedem Metadaten-Refresh |
| `smart_selftest_*` | ursalia | Selbsttest-Log jeder Disk aus `services.diskHealth.devices` (`smartctl -l selftest`), stündlich (`modules/disk-health.nix`) |
| `wifi_link_*` | tummi | `iw dev wlo1 link` (PHY-Modus, Breite, MCS, NSS), alle 30 s |
| `node_wifi_*`, `wifi_link_*` | zorlock | `system_profiler SPAirPortDataType -json` alle 60 s, dieselben Namen wie auf tummi (unter macOS ohne Empfangsrate, Retries und eigenen PHY-Modus für den Empfang; SSID/BSSID schwärzt macOS ohne Ortungsdienste auch für root, im Dashboard „n/a“), dazu `wifi_link_noise_dbm` |
| `unit_cgroup_*` | alle Linux-Hosts | CPU-Zeit und Speicher je systemd-Dienst aus seiner cgroup, alle 15 s (`unit-metrics` in `modules/metrics.nix`); zählt alle Prozesse der Unit, Container mit `--cgroups=split` eingeschlossen |
| `esphome_builder_data_bytes` | ursalia | Größe von `/var/lib/esphome-builder` (Toolchain-Cache), stündlich |
| `grafana_public_dashboard_info` | grammi | öffentliche Dashboards aus der Grafana-API mit ihrem `dash`-Link und den genutzten Template-Variablen, alle 10 s |
| `netbird_expected_peers` | grammi | `terraform/netbird/expected-peers.json`, beim Bauen ins System übernommen; Label `netbird_host` (der Host, um den es geht), denn `host` ist seit 2026-11-02 auf jeder Serie der sendende Host |
| `nixlab_remote_uplink_*` | gw-remote | Status-Datei von OpenVPN je Uplink: verbunden, seit wann, Bytes der laufenden Sitzung, alle 30 s ([Standort-Gateway](site-gateway.md#monitoring)) |
| `nixlab_netbird_group_sync_*` | grammi | Gruppensync Pocket ID → NetBird (`hosts/grammi/netbird-group-sync.nix`): letzter fehlerfreier Lauf, Ablauf von Token und Key, Pocket-ID-Nutzer außerhalb von `people.tf` |
| `nixlab_nixos_upgrade_last_success_seconds` | Hosts mit nächtlichem Upgrade | Zeitpunkt des letzten erfolgreichen `nixos-upgrade` (`modules/auto-upgrade-git.nix`), für den Alarm NixosUpgradeStale |

Die Dashboards liegen als JSON in `hosts/grammi/dashboards/` und werden aus dem Repo provisioniert (Änderungen nur per Commit + Deploy von grammi). `topology.json` erzeugt `just topology`. „Export als Bild“ rendert der Grafana Image Renderer auf grammi (Headless-Chromium, nur Loopback `127.0.0.1:8082`); Teilen nach außen siehe [Zugriff](secrets-network-access.md#grafana-offentliche-dashboards-uber-dash).

| Dashboard | Zeigt |
| --- | --- |
| Hosts Overview | Scrape-Ziele, CPU/RAM/Platte/Netz je Host, fehlgeschlagene Units, Zertifikate, Backups (btrbk, restic), ausstehende Firmware, WLAN-Band/-Signal |
| Topology | Hosts, Exporter und Datenflüsse als Graphviz-Diagramm |
| NetBird | Erreichbarkeit der Control Plane je Host; Peers je Host als Soll (Tofu) / known (Network Map) / connected P2P / connected Relay, dazu Abweichungen; Verlauf der Verbindungen, P2P-Latenz, Sync- und Aufbauzeiten; netbird-server (Signal, Relay, gRPC, API); Durchsatz und Volumen der Exit-Nodes aldrin/zummi je IP-Familie ([Exit-Nodes](secrets-network-access.md#exit-nodes-monitoring)) |
| WLAN | Band von ursalia und zorlock (2,4 / 5 / 6 GHz) über die Zeit, Kanal, Signal, PHY-Modus, Linkrate, Verkehr, MCS, Retries, Verbindungsdauer |
| Disk Health | SMART von NVMe und SATA-SSD auf ursalia: Status, kritische Warnungen, Verschleiß, Reserve, Temperatur, geschriebene Daten, ATA-Fehlerzähler, Ergebnis und Alter der letzten Selbsttests |
| Paperless | Zustand (Celery, Redis, DB, Index, Classifier), Dokumente, Inbox, fehlgeschlagene Tasks, Speicher, Log-Warnungen |
| paperless-gpt | OCR- und Vorschlags-Rückstau, OCR-Zeit je Seite, LLM-Anfragen, -Dauern, -Tokens, -Fehler; GPU und Speicher von zorlock |
| ESPHome builds | Build-Server auf ursalia: Zustand, ESPHome-Version, Builds und Erfolgsquote, Dauer je Build und Gerät, CPU und Speicher neben Paperless, Größe des Toolchain-Caches, Warnungen. Builds und Dauern kommen per LogsQL aus den Log-Zeilen „Starting job …“ / „Job … completed/failed“, device-builder hat keinen Metrik-Endpunkt |
| Shared dashboards | Alle öffentlichen Dashboards mit dem Link für Gäste (`dash.homelab.example`) ob sie pausiert sind und welche Variablen sie nutzen (deren Panels bleiben für Gäste leer); jedes Dashboard verlinkt oben rechts hierher |
| Web & Security | Anfragen an nginx und Traefik, Statuscodes, Dauern; CrowdSec-Bans, -Alerts, Parser-Treffer |
| Garage (S3 storage) | Garage auf aldrin: Cluster-Zustand, Platte, S3-Anfragen/-Fehler/-Dauer, Resync- und GC-Warteschlangen |
| VictoriaMetrics & VictoriaLogs | Ingest-Rate, Plattenbelegung, Abfragedauer, aktive Serien |
| zorlock (Mac mini) | mactop: Thermal State, CPU/GPU, Leistung, Temperaturen, Speicher, Lüfter; Ollama-Anfragen, -Geschwindigkeit, Ladezeiten der Modelle |

**Soll gegen known (NetBird):** „expected“ berechnet OpenTofu aus den Policies mit der Gruppenmitgliedschaft beim letzten `just netbird-apply` (Beispiel: aldrin 6, grammi 8, cuckoosegg 4). „known“ ist, was der Management-Server tatsächlich verteilt. Ein später hinzukommendes Gerät erhöht known sofort, das Soll erst nach dem nächsten Apply + Deploy von grammi – gewollt, damit ein neuer Peer auffällt. Das Modell ignoriert Posture Checks; siehe Kopf von `expected-peers.tf`.

**Log-Level:** Vector macht aus journalds `PRIORITY` das Feld `level`. Python-Dienste schreiben ihr Log nach stderr, journald stuft dann jede Zeile als Fehler ein. Zeilen im Format `<Datum> <Zeit> INFO|WARNING|ERROR …` bekommen deshalb das Level aus dem Text, ohne Farbcodes (`modules/log-shipping.nix`).

**Grafana-Falle:** State-Timelines mit `mergeValues` und Farbmodus „thresholds“ machen aus Zahlen Schwellwert-Stufen („1+“, „< 1“), bevor die Wert-Zuordnungen greifen. Farbmodus „fixed“ verwenden und Text und Farbe in die Zuordnungen legen.

## Alerting

**vmalert** auf grammi wertet Regeln aus, eine Instanz gegen VictoriaMetrics, eine gegen VictoriaLogs. **Alertmanager** gruppiert, schaltet stumm und wiederholt. **Home Assistant** macht aus jeder Gruppe eine Push-Meldung aufs iPhone und eine Benachrichtigung in der HA-Weboberfläche. Beide verschwinden wieder, sobald der Alarm behoben ist. Alles lauscht nur auf `127.0.0.1`. Der einzige Weg hinaus ist der Webhook zu HA über das Mesh (Policy `alerting-home-assistant`, nur grammi → HA:8123). Alertmanagers Weboberfläche (Alarme, Silences) liegt unter `alertmanager.homelab.example` bzw. `alerts.homelab.example` hinter dem Reverse Proxy mit SSO, nur für `homelab_admins`. Code: `hosts/grammi/alerting.nix`.

| Alarm | Grundlage | Auslöser |
| --- | --- | --- |
| UnitFailed | Journal: systemds „unit failed“ (`MESSAGE_ID d9b373ed…`) je Host und Unit in 30 min (Fehlschläge im Ruhefenster: 3 h), dazu `node_systemd_unit_state{state="failed"}` seit 10 min | ein Fehlschlag reicht, die Meldung nennt die Anzahl |
| NixosUpgradeStale | `nixlab_nixos_upgrade_last_success_seconds` | kein Erfolg seit 26 h, außer bei Deploy-Hold |
| ResticBackupStale, ResticCheckFailed | `restic_backup_timestamp`, `restic_check_success` | neuester Snapshot älter als 26 h, Check fehlgeschlagen |
| BtrbkSnapshotStale | `btrbk_last_snapshot_timestamp_seconds` | älter als 26 h |
| CertExpiring | `ssl_certificate_expiry_seconds`, nur `/var/lib/acme/<domain>/cert.pem` | weniger als 21 Tage |
| DiskFull | `node_filesystem_*` | über 85 % seit 15 min |
| HostGone, TargetDown | `up` | Host hat in den letzten 24 h geliefert, jetzt nicht mehr; Exporter seit 15 min down |
| NetbirdGroupSyncStale | `nixlab_netbird_group_sync_last_success_seconds` | kein fehlerfreier Lauf seit 1 h |
| SyncCredentialExpiring | `nixlab_netbird_group_sync_credential_expiry_seconds` | Token oder Key des Gruppensyncs laufen in weniger als 30 Tagen ab |
| PersonNotManaged | `nixlab_netbird_group_sync_unmanaged_person` | Pocket-ID-Nutzer in `homelab`/`homelab_admins`, der nicht in `people.tf` steht, seit 1 h |
| RemoteUplinkDown, RemoteSiteUnreachable | `nixlab_remote_uplink_connected` | ein Uplink des Remote-Standorts seit 30 min getrennt; keiner seit 10 min |
| Watchdog | `vector(1)` | immer, als Heartbeat |

**Warum das Journal:** Den Failed-State einer Unit löscht der nächste Switch. `systemctl --failed` und eine einzelne Abfrage zeigen danach nichts mehr. Die Crash-Loops von paperless-secret-key (Oktober 2026, ~33 000 Fehlstarts) und grist-core (~22 000 am Tag) tauchten nie als „failed“ auf, jeder Start hinterließ aber die systemd-Meldung im Journal.

**Ruhe:** Zwischen 04:00 und 06:00 (nächtliches Upgrade und Reboot-Fenster) ist alles außer dem Watchdog stumm. Was um 06:00 noch feuert, kommt danach an. Deshalb gilt für Fehlschläge zwischen 04:00 und 06:00 ein 3-h-Fenster, sonst 30 min, damit eine behobene Unit ihre Meldung bald wieder räumt. Gruppiert wird nach Alarm und Host, wiederholt alle 12 h. HostGone unterdrückt die übrigen Alarme desselben Hosts.

**Totmann-Schaltung:** Der Watchdog erreicht HA alle 5 min und startet dort den Timer `timer.nixlab_alerting_heartbeat` (20 min) neu. Läuft er ab, meldet die HA-Automation „nixlab Alerting stumm“: grammi, vmalert, Alertmanager oder der Weg zu HA ist ausgefallen. Ohne Internet zu Hause kommt nichts an. Alertmanager versucht es weiter, ein Alarm, der dann noch feuert, kommt danach an.

**In HA:** Automation „nixlab Alertmanager“ (Webhook, ein Ablauf je Gruppe; Tag `nixlab-<Alarm>-<Host>`, damit die Entwarnung Push und Weboberflächen-Benachrichtigung wieder entfernt), „nixlab Alerting stumm“ und der Timer. Die Push-Meldung geht über den alten Dienst `notify.mobile_app_…`, weil `notify.send_message` kein `data.tag` annimmt. Die Webhook-ID ist das einzige Geheimnis: `just alerting-webhook-key` legt eine neue in die Zwischenablage (für den Trigger der Automation) und die URL in `hosts/grammi/alerting.yaml`. Danach grammi deployen.

**Testen:** Einen künstlichen Alarm direkt an Alertmanager schicken: `ssh root@grammi.peer.homelab.example amtool --alertmanager.url=http://127.0.0.1:9093 alert add alertname=Test host=test --annotation=summary=Test`. Er verschwindet nach 5 min von selbst. Ende-zu-Ende: auf einem Host `systemd-run --unit=alerting-selftest false`, nach höchstens etwa 5 min kommt UnitFailed; die Entwarnung kommt, wenn der Fehlschlag aus dem 30-min-Fenster fällt.
