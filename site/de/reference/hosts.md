# Hosts & Rollen

Drei gemietete VMs tragen die öffentlichen Dienste, ursalia und zorlock stehen zu Hause, cuckoosegg im Subraum; gusto ist die Admin-Workstation (ein MacBook). Alle Server sind über `<host>.peer.homelab.example` im NetBird-Mesh erreichbar; root-SSH gibt es nur dort. Art, Site, Uplink und Entsperren jeder Maschine – auch der Router, des KVM und der Appliances – stehen im [Inventar](inventory.md).

| Host | Plattform | Rolle | Besonderheiten |
| --- | --- | --- | --- |
| grammi | NixOS, gemietete VM | NetBird-Server (`mesh.homelab.example`) + Reverse Proxy, Traefik, Monitoring (VictoriaMetrics/-Logs, Grafana, logchef), Mealie, Grist, PostgreSQL | Zentrale Senke für Metriken und Logs aller Hosts |
| zummi | NixOS, gemietete VM | Pocket ID (`auth.homelab.example`) – Login für alle Dienste und NetBird | pocket-id separat gepinnt |
| aldrin | NixOS, gemietete VM | Garage S3 (`s3.aldrin.homelab.example`), garage-ui (`s3-admin`), Backup-Ziel für restic, Doku-Site (`doku`) | Fork-Paket garage-ui mit Subpath-Support |
| ursalia | NixOS, Bare Metal (ThinkCentre M720q) | Paperless-ngx 3 + paperless-gpt (`dokumente`), Doku-Site (`doku`), Samba für den Scanner, Routing-Peer ins Heim-LAN, Build-Host für cuckoosegg, ESPHome-Build-Server für Home Assistant (nur Heim-LAN, Port 6055), Claude-Code-Brücke zum NanoKVM Go+ (nur bei Bedarf) | LUKS + btrfs via disko, TPM-Unlock, Secure Boot (lanzaboote), WLAN (Intel BE200), kein CrowdSec |
| cuckoosegg | NixOS, VM auf dem Subraum-Proxmox | NetBird-Routing-Peer in die Subraum-Netze | Gruppe `subraum-devices` statt `servers`, kein Repo/Deploy-Key, wird per Push deployed |
| zorlock | macOS + nix-darwin, Mac mini M4 | Ollama auf der Apple-GPU (`llm`), genutzt von paperless-gpt | Keins der `modules/*.nix`; FileVault-Unlock nach Reboot per LAN-SSH |
| gusto | macOS + nix-darwin + home-manager, MacBook Pro | Admin-Workstation: Deploys, Secrets, Tofu, Doku | Laptop, kein sshd, keine Secrets, nicht überwacht; Apps als Homebrew-Casks, NetBird als offizielle App – siehe [gusto](gusto.md) und [macOS-Hosts](../explanation/macos-hosts.md) |
