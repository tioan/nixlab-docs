# Conventions

- One git worktree per topic (`.worktrees/<topic>`), removed and its branch deleted when done. Tofu state always stays in the main checkout.
- Plan first, implement after approval.
- Subdomains by function (`rezepte`, not `mealie`).
- New web services on grammi use PostgreSQL instead of SQLite.
- Dual stack wherever possible.
- Code comments explain the *why*, including the mistakes that led to a decision, with a date.
- Code comments, commit messages and changelogs in English; the project documentation exists in German and English.
- The docs site loads nothing from third parties: the fonts and glightbox ship with the site (`docs/assets.nix`) instead of coming from Google Fonts or unpkg.com. Why: GDPR, and private docs that work without internet access.
- Infrastructure that mainly fills a role at one place (gateways, access points, switches) is named `<role>-<site>`: `gw-hq`, `ap-flur`. The role comes first so devices of the same role sit next to each other in lists and dashboards; the site is in the inventory anyway. The lab's own servers keep their Gummi Bears names.
- Interface names are limited to 15 characters on Linux. For `tun-<site>-uplink<n>` (`tun-hq-uplink1`) that means a site code of at most three characters.
- Diagrams in the docs are inline SVG in `<figure class="nx-diagram">` (viewBox 680 wide, no `width`/`height`), so boxes can link to sections of the page: `<a data-target="<heading id>" tabindex="0" role="link">` around the box, without `href` – the theme throws on SVG links with one, and `site/common/javascripts/diagram-links.js` does the jump (click and Enter). No markers for arrowheads, but paths in the line's colour, since WeasyPrint cannot do `context-stroke` in the PDF. Light colours sit in the SVG's own `<style>`, the dark scheme in `site/common/stylesheets/diagrams.css`, which only the site loads. Check with `just docs-serve` (both colour schemes) and in the PDF.
