# Web-Grundlage: Header, Standard-Server, vHosts

Jede Web-Front des Labs verhält sich in drei Punkten gleich, einmal festgelegt in [`modules/web-baseline.nix`](https://github.com/tioan/nixlab-docs/blob/main/modules/web-baseline.nix) (nginx auf aldrin, ursalia und zummi) und in `hosts/grammi/netbird.nix` (Traefik auf grammi). Entschieden am 2026-11-15 (Issues #308, #12, #234, #319).

## Security-Header

| Header | Wert |
| --- | --- |
| `Strict-Transport-Security` | `max-age=31536000` (ein Jahr) |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `X-Frame-Options` | `SAMEORIGIN` |

Die Werte stehen einmal in der Option `lab.web.securityHeaders`; nginx und Traefik erzeugen sie beide daraus.

- **nginx** setzt sie auf `http`-Ebene, also erben sie jeder Server und jede Location: die vHosts, die Doku-Seite, die HTTP-Listener für den NetBird-Proxy (der Proxy reicht die Header über HTTPS an den Browser weiter) und jeder später hinzukommende vHost.
- **Sendet die Anwendung einen Header selbst, gilt ihrer.** Jeder Header läuft über eine `map` auf `$upstream_http_<name>`; ein leerer Wert lässt `add_header` ihn auslassen. OpenCloud, paperless und HealthLog senden eigene, teils strengere Werte (HealthLog: HSTS mit `includeSubDomains; preload`, `X-Frame-Options: DENY`) – die bleiben unverändert, ohne zweite Kopie daneben.
- **`always`**, damit auch die Wartungsseite und nginx' eigene Fehlerseiten sie tragen.
- **Vererbung in nginx:** Eine Ebene mit eigenem `add_header` erbt keinen von oben. Eine solche Location muss die gemeinsamen Zeilen wiederholen (`config.lab.web.nginx.headers`; heute nur die `@share`-Seite von paperless). Sonst schlägt die Evaluation fehl.
- **Traefik** auf grammi (die Router von `mesh.homelab.example` in `netbird.nix`, die Router des Apps-Entrypoints in `traefik.nix`): eine `headers`-Middleware, jeweils als erste in der Kette, damit auch die 429 der Rate-Limits und die Fehlerseiten sie tragen. Anders als nginx ersetzt sie einen Header, den das Backend gesendet hat. NetBird, Caddy, Mealie, Grist, logchef, VictoriaMetrics/-Logs und Alertmanager senden keinen davon; Grafana (`metrics`, `dash`) sendet `X-Frame-Options: deny` und `nosniff`, deshalb bekommen seine Router eine Variante ohne diese beiden (`security-headers-grafana`) – `SAMEORIGIN` würde sein `deny` abschwächen. Die zur Laufzeit geschriebenen Wartungs-Router haben keine Header.

**Warum HSTS ohne `includeSubDomains` und `preload`:** Auf einem Dienstnamen wie `cloud.homelab.example` gilt der Zusatz nur für Namen *darunter*, und davon gibt es keine; nur auf `short.homelab.example` (eine Apex-Domain) würde er künftige Unternamen erfassen, die dann vom ersten Tag an HTTPS haben müssten. `preload` wird nur für Apex-Domains angenommen. HSTS auf `homelab.example` selbst wäre der Schritt mit Wirkung (er schließt das Unterschieben von Cookies über unverschlüsseltes HTTP von jedem `*.homelab.example`), träfe aber auch die Geräteseiten unter diesem Namen – eine eigene Entscheidung. Rückweg für jeden Namen: `max-age=0` über HTTPS senden, dann vergisst jeder Browser den Eintrag beim nächsten Besuch.

## Standard-Server

Eine Anfrage für einen Namen, den kein vHost bedient, landete bisher im ersten vHost auf dieser Adresse – pocket-id auf zummi und OpenCloud auf aldrin antworteten darauf mit 200. Jetzt hat jedes nginx Standard-Server auf jeder Adresse, auf der es 80 und 443 bedient (die Wildcard-Adresse und auf aldrin und zummi zusätzlich die öffentlichen Adressen – ein Standard-Server auf der Wildcard deckt keine konkrete Adresse ab; fehlt einer, schlägt die Evaluation fehl):

- **443:** Der TLS-Handshake wird bei unbekanntem oder fehlendem SNI abgelehnt (`ssl_reject_handshake`, ohne Zertifikat). Ein bekannter SNI mit unbekanntem `Host`-Header wird ohne Antwort geschlossen (444).
- **80:** Jeder `Host` bekommt ein 301 auf `https://$host` – Port 80 tut nichts anderes, egal welcher Name.

## Port-80-Proben

Ob Port 80 wirklich nur umleitet, wird laufend geprüft (`modules/public-probes-targets.nix`): jeder Web-Endpoint, den das Lab selbst bedient – öffentliche und Mesh-Endpoints auf ihrem eigenen Host, solche hinter dem Proxy auf dessen Host –, mit seinem Namen, und einmal pro Host und Adressart mit `Host: localhost` und einem unbekannten Namen. Erwartet wird 301 oder 308 mit einem `Location` auf `https://`, IPv4 und IPv6 getrennt. Mesh-Namen prüft grammi, den Rest die üblichen Prober; ein Fehlschlag löst `PublicServiceDown` aus und erscheint im Dashboard *Public endpoints*.

## Appliances

Geräte außerhalb von NixOS (LuCI auf den OpenWrt-Geräten, Kameras, das Modem, Geräte der ESP-Klasse) werden an derselben Regel gemessen und in `inventory.json` unter `web` festgehalten (nixlab#372). `redirect`: Port 80 leitet nur auf https um – LuCI bekommt `redirect_https` aus `openwrt/luci.nix`, und ursalia prüft diese Geräte per Adresse, nur IPv4, jeder Umleitungscode mit einem `Location` auf `https://` (*Appliances at home* im Dashboard *Public endpoints*); gruffi lässt ursalia genau an ihren Port 80 (`openwrt/web-probe-targets.nix`). `plain`: Die Firmware kann kein TLS oder die API des Geräts braucht reines HTTP – eine akzeptierte Lücke, die Begründung steht in `web.gap`. Security-Header kann kein Gerät selbst setzen (uhttpd hat keine Option dafür); diese Lücke steht genauso dort.

## Der vHost-Helfer

`lab.vhosts.<name>` für die Form, die sich immer wiederholte: DNS-01-Zertifikat, `forceSSL`, Proxy auf einen Loopback-Port, Websockets, `allow`/`deny` nur fürs Mesh, Eintrag in Wartungsmodus und WAF.

```nix
lab.vhosts."health.homelab.example" = {
  port = 8000;          # location / -> http://127.0.0.1:8000
  websockets = true;
  meshOnly = true;      # allow lab.mesh (+ allow), deny all; Wildcard-Listen
  extraConfig = "client_max_body_size 0;";
};
```

| Option | Bedeutung |
| --- | --- |
| `port` | Loopback-Port, auf den `location /` weiterleitet; weglassen, wenn der vHost eigene Locations mitbringt. |
| `websockets` | Websockets auf `location /` durchreichen. |
| `meshOnly`, `allow` | Nur die Mesh-Netze (`lab.mesh`, aus `inventory.json`) plus `allow` zulassen. Ein HTTPS-vHost lauscht dann auf der Wildcard-Adresse – die Mesh-Adresse vergibt NetBird. |
| `proxyListener` | Statt HTTPS: ein HTTP-Listener auf diesem Port für einen Reverse-Proxy-Dienst von NetBird; immer nur Mesh, relative Weiterleitungen. |
| `maintenance` | `switch` (Standard), `errorPages` oder `none` – Eintrag im [Wartungsmodus](../how-to/maintenance.md). |
| `waf` | Anfragen durch die [AppSec-WAF](waf.md) schicken. |
| `serverName`, `extraConfig`, `nginx` | Servername, wenn zwei vHosts sich einen teilen; Direktiven auf Server-Ebene; alles Weitere, unverändert in `services.nginx.virtualHosts.<name>` übernommen. |

Die Mesh-Netze selbst stehen in `inventory.json` unter `overlays.mesh` und kommen als `lab.mesh.ipv4`, `lab.mesh.ipv6` und `lab.mesh.networks` auf die Hosts (`modules/lab.nix`). Andere Stellen wiederholen sie noch als Literal (sshd, CrowdSec, Samba, Traefiks `trustedIPs`, AdGuard, Caddy auf zorlock, `terraform/netbird/main.tf`); sie folgen nach und nach, die Liste steht in #319.
