# Neuen Host aufnehmen

Ein Host steht an mehreren Stellen im Repo, weil NixOS und OpenTofu bewusst keine gemeinsame Host-Liste haben (siehe [Was bewusst nicht verdrahtet ist](../explanation/nixos-opentofu.md#was-bewusst-nicht-verdrahtet-ist)). Diese Anleitung geht sie der Reihe nach durch.

## 1. Maschine bereitstellen

Gemietete VMs werden beim Anbieter von Hand angelegt; Bare Metal und die Subraum-VM folgen den Installationsanleitungen unter `docs/install-*.md`. Am Ende steht ein NixOS mit SSH-Host-Key – aus dem entsteht gleich der age-Schlüssel des Hosts.

## 2. Konfiguration anlegen

- `hosts/<host>/configuration.nix` und `hardware-configuration.nix` anlegen.
- In `flake.nix` unter `nixosConfigurations` eintragen, mit expliziter Modulliste. Was bewusst fehlt, bekommt einen Kommentar mit Begründung daneben.

## 3. Überall eintragen, wo Hosts aufgezählt sind

| Datei | Eintrag |
| --- | --- |
| `flake.nix` | `nixosConfigurations.<host>` |
| `inventory.json` | `hosts.<host>` mit `"managed": true` – Art, Site, Owner, Entsperren (siehe [Inventar](../reference/inventory.md)) |
| `justfile` | `hosts := "…"` (nur Pull-Hosts, für `ship-all`) |
| `terraform/netbird/main.tf` | `local.hosts`: Host → Setup-Key-Gruppe (`servers` o. ä.) |
| `terraform/desec-tokens/main.tf` | `local.hosts`: erlaubte Quelladressen, `acme_names` |
| `terraform/github/main.tf` | `local.hosts`: Deploy-Key nur lesend oder mit Schreibrecht |

## 4. sops-Empfänger

Den age-Schlüssel aus dem SSH-Host-Key des neuen Hosts ableiten (`ssh-to-age` auf `/etc/ssh/ssh_host_ed25519_key.pub`) und in `.sops.yaml` eintragen: einen Anker unter `keys` und eine `creation_rule` für `hosts/<host>/(secrets|netbird|desec|github)\.yaml$` mit dem Host und `admin` als Empfängern. Der öffentliche Host-Key selbst kommt in `inventory.json` (`sshHostKeys`, oder später per `just inventory-collect`); `checks.inventory-sops` gleicht beides ab.

## 5. Schlüssel und Tokens erzeugen

| Rezept | Ergebnis | Hinweis |
| --- | --- | --- |
| `just netbird-key <host>` | `hosts/<host>/netbird.yaml` | Einmal-Setup-Key, **24 h gültig** – direkt danach deployen |
| `just desec-key <host>` | `hosts/<host>/desec.yaml` | nur für Hosts mit eigenen Zertifikaten |
| `just github-key <host>` | `hosts/<host>/github.yaml` + `github-deploy.pub` | nur für Pull-Hosts |

Rezepte, die auf dem MacBook sops brauchen, laufen mit der 1Password-Anmeldung davor (siehe [just-Rezepte](../reference/recipes.md)).

## 6. Deployen und prüfen

- Erster Deploy innerhalb von 24 h nach `netbird-key`. Der Host registriert sich beim Start selbst im Mesh; Tofu findet ihn über `data "netbird_peer"` am Namen.
- `just topology` ausführen und das Ergebnis committen – sonst schlägt `nix flake check` fehl.
- `just inventory-collect` (Host-Key, Interfaces), `network`/`ipv4` von Hand ergänzen, dann `just inventory-test`; auf dem MacBook `just known-hosts`.
- App-Secrets erst eintragen, wenn der Host läuft: [Secrets eintragen](secrets.md).
- Doku nachziehen: [Hosts & Rollen](../reference/hosts.md), [Services](../reference/services.md).
