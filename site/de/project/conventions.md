# Konventionen

- Pro Thema ein eigener Git-Worktree (`.worktrees/<thema>`), nach Abschluss entfernen und Branch löschen. Tofu-State bleibt dabei immer im Haupt-Checkout.
- Erst planen, dann nach Freigabe umsetzen.
- Subdomains nach Funktion (`rezepte`, nicht `mealie`).
- Neue Webdienste auf grammi nutzen PostgreSQL statt SQLite.
- Dual-Stack, wo immer möglich.
- Kommentare im Code erklären das *Warum*, inklusive der Fehler, die zu einer Entscheidung geführt haben, mit Datum.
- Code-Kommentare, Commit-Messages und Changelogs auf Englisch; die Projektdoku gibt es auf Deutsch und Englisch.
- Die Doku-Site lädt nichts von Dritten: Schriften und glightbox liegen in der Site selbst (`docs/assets.nix`), statt von Google Fonts bzw. unpkg.com zu kommen. Grund: DSGVO und eine private Doku, die ohne Internet funktioniert.
- Infrastruktur, die vor allem eine Rolle an einem Ort erfüllt (Gateways, Access Points, Switches), heißt `<aufgabe>-<standort>`: `gw-hq`, `ap-flur`. Die Aufgabe steht vorn, damit Geräte gleicher Rolle in Listen und Dashboards nebeneinander stehen; der Standort steht ohnehin im Inventar. Eigene Server behalten ihre Gummibären-Namen.
- Interface-Namen haben unter Linux höchstens 15 Zeichen. Bei `tun-<standort>-uplink<n>` (`tun-hq-uplink1`) heißt das: Standortkürzel mit höchstens drei Zeichen.
- Wann immer ein Ablauf, ein Aufbau oder ein Zusammenhang sich als Bild schneller erfassen lässt als als Text (Trafficflüsse, Abhängigkeiten, Schichten), bekommt die Seite ein Diagramm, und zwar immer zoom- und klickbar wie das Inventar-Schema: Kästen springen zu ihrem Abschnitt, ein Klick anderswo vergrößert. Kein Diagramm als `<img>` oder als reines Bild ohne Sprünge, wenn die Seite Abschnitte hat, auf die es zeigen kann.
- Diagramme in der Doku sind Inline-SVG in `<figure class="nx-diagram">` (viewBox 680 breit, ohne `width`/`height`), damit Kästen auf Abschnitte der Seite verlinken können und ein Klick anderswo auf das Diagramm es vergrößert (in der Lightbox der Website): `<a data-target="<Überschrift-ID>" tabindex="0" role="link">` um den Kasten, ohne `href` – mit `href` wirft das Theme bei SVG-Links einen Fehler, und `site/common/javascripts/diagrams.js` übernimmt den Sprung (Klick und Enter). Keine Marker für Pfeilspitzen, sondern Pfade in der Linienfarbe, weil WeasyPrint `context-stroke` im PDF nicht kann. Helle Farben stehen im `<style>` des SVG, das Dunkel-Schema in `site/common/stylesheets/diagrams.css`, das nur die Website lädt. Prüfen mit `just docs-serve` (beide Farbschemata) und im PDF.
- Ausnahme ist die [Lagekarte](../reference/lab-map.md): HTML statt SVG, erzeugt aus `inventory.json` (`docs/gen-lab-map.py`), weil sie jeden Host und Dienst zeigt und nicht veralten darf. Klickbar heißt dort: Ein Klick auf einen Dienst oder Host wählt ihn aus und zeichnet seine Beziehungen ein (`site/common/javascripts/lab-map.js`); ein Klick auf eine freie Stelle vergrößert sie in der Lightbox. Im PDF steht sie ohne Linien (`doc.css`).
