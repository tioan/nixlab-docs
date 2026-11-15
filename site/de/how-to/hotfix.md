# Paket per Hotfix fixen

Wenn nixpkgs eine Version mit Sicherheitslücke oder Bug ausliefert und der Fix noch nicht in unserem Pin ist, pinnen wir das Paket selbst – aber über `hotfix` aus [`modules/hotfixes.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/hotfixes.nix), nicht mit einem nackten `overrideAttrs`. `hotfix` wendet das Override nur an, solange nixpkgs es noch braucht, und warnt, sobald es das nicht mehr tut.

Warum: Der nächtliche Auto-Upgrade bewegt `nixpkgs` und `nixpkgs-unstable` von selbst. Ein handgeschriebener Pin veraltet unbemerkt und pinnt, sobald nixpkgs weiter ist, eine *ältere* Version. So geschehen beim paperless-3.3.2-Bump auf ursalia: unstable hatte 3.3.2 schon eine Weile, bevor es jemand bemerkte. Die Warnung ist unsere Ergänzung, der Rest ist snowballs Arbeit, siehe [Credits](#credits).

## Wann sich der Hotfix abschaltet { #off }

`hotfix` gibt das nixpkgs-Paket unverändert zurück und warnt, sobald eins von beidem gilt:

- `pkg.version` ≥ `fixedVersion` – nixpkgs hat aktualisiert, oder
- einer von `pkg.patches` hat `fixPatch` im Dateinamen – stable hat den Fix als Patch zurückportiert, ohne die Version anzuheben (bei CVEs auf einem stable Release der Normalfall).

Das Override selbst samt src-Hash wird dann gar nicht mehr ausgewertet.

## Paket aus dem nixpkgs des Hosts: Overlay in `modules/hotfixes/` { #overlay }

Für Pakete aus dem normalen `pkgs` eines NixOS-Hosts (sudo, openssh, nginx …). Jede Datei in `modules/hotfixes/` wird auf **jedem** NixOS-Host als Overlay geladen – nicht aber auf den Macs, die `modules/*.nix` nicht bekommen.

```nix
# modules/hotfixes/sudo.nix
# CVE-2025-32463: chroot option lets local users run code as root.
hotfix: final: prev: {
  sudo = hotfix {
    name = "sudo CVE-2025-32463";
    pkg = prev.sudo;
    fixedVersion = "1.9.17p1";
    fixPatch = "CVE-2025-32463";
    override = pkg: pkg.overrideAttrs (old: rec {
      version = "1.9.17p1";
      src = final.fetchurl {
        url = "https://www.sudo.ws/dist/sudo-${version}.tar.gz";
        hash = "sha256-…";
      };
    });
  };
}
```

`fixPatch` ist optional und nur sinnvoll, wo der nixpkgs-Patch absehbar einen erkennbaren Namen hat (CVE-Nummer). Hash eintragen: erst `lib.fakeHash` stehen lassen, dann den richtigen Wert aus dem Build-Fehler übernehmen.

## Paket aus einem anderen nixpkgs: `hotfix` im Host-Modul { #host-module }

Pakete aus `import nixpkgs-unstable { … }` (paperless, Grist, …) sehen die Overlays nicht. Dort wird `hotfix` als Modul-Argument benutzt:

```nix
{ pkgs, nixpkgs-unstable, hotfix, ... }:
let
  unstable = import nixpkgs-unstable { inherit (pkgs.stdenv.hostPlatform) system; };
  paperless = hotfix {
    name = "paperless-ngx GHSA-…";
    pkg = unstable.paperless-ngx;
    fixedVersion = "3.4.1";
    override = pkg: pkg.overrideAttrs (finalAttrs: prev: { version = "3.4.1"; src = …; });
  };
in
```

Änderungen, die *nicht* an einer Version hängen – ein Patch für ein offenes Upstream-Issue, abgeschaltete Tests – bleiben außerhalb von `hotfix`, als normales `overrideAttrs` auf dem Ergebnis.

## Wo die Warnung erscheint { #warning }

Es ist eine Evaluation-Warnung:

```
evaluation warning: hotfix "sudo CVE-2025-32463" is no longer needed: nixpkgs' sudo has version 1.9.17p1 (fix in 1.9.17p1) - remove it
```

Sie erscheint bei jedem `just ship`, `nixos-rebuild` und `nix eval` des Hosts – und auf den Pull-Hosts im Journal des nächtlichen Upgrades, wo sie niemand liest:

```bash
journalctl -u nixos-upgrade --since today | grep 'hotfix "'
```

Dann die Datei in `modules/hotfixes/` löschen bzw. das `hotfix { … }` aus dem Host-Modul entfernen und deployen.

## Credits { #credits }

Das Muster – Versionsvergleich, Erkennung eines zurückportierten CVE-Patches, ein automatisch geladenes Overlay pro Datei – ist von snowball ([BBBSnowball](https://github.com/BBBSnowball)) und ausdrücklich zur Übernahme angeboten: [`hotfixes/` in BBBSnowball/nixcfg](https://github.com/BBBSnowball/nixcfg/tree/35264a74189686e8ce0231b4752f85225d0c9e00/hotfixes). Unsere Fassung ergänzt die Warnung und das Modul-Argument `hotfix` für Pakete aus einem anderen nixpkgs.
