# Wo ändere ich was?

Welche Datei für welche Änderung zuständig ist, wie oft das vorkommt und was danach zu tun ist.

| Was | Wo | Wie oft | Danach |
| --- | --- | --- | --- |
| Dienst, Paket oder Option auf einem Host | `hosts/<host>/*.nix` | häufig | `just ship <host> "…"` |
| Etwas für alle Hosts | `modules/*.nix` | gelegentlich | `just ship-all "…"`; neues Modul: öffentlich oder in `docs/modules-private.txt`? |
| Name hinter dem Reverse Proxy (grammi) | `hosts/grammi/proxy-services.json` | selten | CNAME in DNSControl, grammi deployen, `just netbird-apply` |
| Name nur im Mesh | `terraform/netbird/mesh-services.tf` | selten | `just netbird-apply` |
| Wer die private Doku lesen darf | Gruppe `admin-workstations` (`terraform/netbird/subraum.tf`, Peer-Namen) | selten | `just netbird-apply`, `admin-peers.json` committen, aldrin und ursalia deployen |
| NetBird-Policies, Gruppen, Personen, Routen | `terraform/netbird/*.tf` | selten | `just netbird-plan`, `just netbird-apply` |
| Öffentliche DNS-Records | DNSControl-Repo (`dnsconfig.js`) | selten | dort `dnscontrol preview`, `dnscontrol push`, committen |
| Was ein deSEC-Token darf | `terraform/desec-tokens/main.tf` | selten | `just desec-apply` |
| Repos, Deploy-Keys | `terraform/github/` | selten | `just github-plan`, `just github-apply` |
| Version eines automatisch aktualisierten Inputs | `flake.lock` | nachts automatisch | – |
| Version eines separat gepinnten Inputs | `flake.lock` (`nix flake update <input>`) | von Hand | Hosts deployen, die ihn nutzen |
| Eine Paketversion, die nixpkgs noch nicht hat (Sicherheitsfix) | `modules/hotfixes/` oder `hotfix` im Host-Modul | bei Bedarf | deployen; entfernen, sobald der Build warnt – [Paket per Hotfix fixen](../how-to/hotfix.md) |
| Grafana-Dashboard | `hosts/grammi/dashboards/*.json` | gelegentlich | grammi deployen |
| Topologie (neuer Host, Exporter, vHost) | `topology.nix` erzeugt sie | bei Bedarf | `just topology`, committen |
| Maschinendaten: Art, Hardware, Site, Uplink, Strom, Entsperren, Netze, Interfaces, Host-Keys | `inventory.json` | mit jedem neuen Gerät | `just inventory-collect`, `just inventory-test` ([Inventar](inventory.md)) |
| Eine App oder ein CLI-Tool auf der Workstation | `hosts/gusto/configuration.nix` (Cask) oder `hosts/gusto/home.nix` (CLI) | bei Bedarf | `just mac-diff`, `just mac-switch` |
| Homebrew-Richtlinie der Macs | `modules/darwin/homebrew.nix` | selten | `just mac-switch` auf jedem Mac mit Homebrew |
| Versionen der Casks | `flake.lock` (Homebrew-Inputs) | von Hand | `just mac-upgrade`, committen |
| Inventar-Format (Felder, Gerätearten) | `spec` in `inventory.nix` | selten | `just inventory-schema`, Testfall, Doku |
| Secrets eines Hosts | `hosts/<host>/secrets.yaml` | selten | [Secrets eintragen](../how-to/secrets.md) |
| Diese Dokumentation | `docs/site/{de,en}/` | mit jeder Änderung | `just docs` |
