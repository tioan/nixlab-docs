# Offene Punkte

- [ ] NetBird-Provider: den Build aus PR #215 (IPv6-Overlay) wieder durch die Registry-Version ersetzen, sobald er veröffentlicht ist ([Exit-Nodes & IPv6](../explanation/secrets-network-access.md#netbird-provider-pr215))
- [ ] Home Assistant: prüfen, ob `trusted_proxies`/`trusted_networks` nur `192.0.2.0/24` kennen, und `2001:db8:203:0::/64` ergänzen (liegt nicht im Repo)
- [ ] Upstream-PRs im NetBird-Provider (#247 `direct_upstream`/Cluster-Targets, #248 `crowdsec_mode`); danach Proxy-Targets auf grammi auf `localhost` umstellen
- [ ] NetBird: `servers-to-servers` auf die genutzten Ports einschränken (Ingest 8428/9428, Garage 443, dns01proxy 8446, Exporter, SSH für Deploys, llm) – heute alle Ports ([Wer erreicht die Server](../explanation/secrets-network-access.md#to-servers))
- [ ] NetBird: Feature-Request für ICMP-Typen in Policies ([netbird#8447](https://github.com/netbirdio/netbird/discussions/8447)); bis dahin erlaubt `to-servers-icmp` alle ICMP-Typen statt nur Ping ([Wer erreicht die Server](../explanation/secrets-network-access.md#to-servers))
- [ ] Tailscale von den Servern entfernen, sobald nichts mehr darauf angewiesen ist
- [ ] Grafana-Alerting (Kontaktpunkt fehlt noch) für SMART, fwupd, Paperless, NetBird Soll ≠ known, WLAN von ursalia (nicht verbunden, hängt auf 2,4 GHz, schwaches Signal)
- [ ] Update-Benachrichtigung für die von Hand gepinnten Inputs (NetBird, Pocket ID)
- [ ] Root-Passwörter deklarativ über sops
- [ ] Host-Liste an einer Stelle führen statt in `flake.nix`, den Tofu-Modulen und `justfile`
- [ ] gusto: nach dem ersten Switch prüfen, ob sich die NetBird-App selbst aktualisiert (oder dem Auto-Update im Dashboard folgt), und das abschalten, damit die Version nur aus `netbirdio-tap` kommt
- [ ] gusto: Standard-Git-Adresse `admin@homelab.example` statt `mail@admin.org`, zusammen mit einer neuen Ordnung von `~/Projects`
- [ ] Inventar: ein Feld für den DNS-Namen eines Geräts (arkkvm antwortet als `arkkvm01`, heute nur in seiner Notiz) und öffentliche Adressen der verwalteten Hosts – dann leitet `hosts/gusto/ssh.nix` seine Ausweichnamen daraus ab
- [ ] Doku-Site: `<link rel="alternate" type="text/markdown">` in jeder HTML-Seite, das auf ihre Markdown-Fassung zeigt (`docs/gen-llms.py`) – braucht einen Theme-Override, deshalb erst, wenn Zensical bei 1.0 ist
