# Inventar-Schema

`inventory.json` folgt einem festen Format: acht Abschnitte, jeder ein Objekt aus Einträgen mit ID als Schlüssel, jedes Feld mit einem Typ, manche davon Verweise in einen anderen Abschnitt. Diese Seite ist die vollständige Referenz dieses Formats – jedes Feld mit Typ, ob es Pflicht ist, seinem Standardwert und seiner Bedeutung, ein Beispiel pro Abschnitt und ein ganzes Beispiel-Inventar. *Wozu* das Inventar da ist, wie es geprüft wird und was daraus abgeleitet wird, steht unter [Inventar](inventory.md).

Das Format ist an genau einer Stelle definiert, in `spec` in `inventory.nix`. Alles auf dieser Seite, was ein Feld beschreibt, wird daraus erzeugt und kann deshalb nicht von dem abweichen, was die Prüfung tatsächlich prüft:

| Erzeugt | Aus | Aktuell gehalten durch |
| --- | --- | --- |
| `inventory.schema.json` – JSON Schema für den Editor | `spec` | `just inventory-schema`, `checks.inventory-schema` |
| Die Feldtabellen unten | `inventory.schema.json` | den Doku-Build (`docs/gen-reference.py`) |
| Das Diagramm aller Felder | `spec` | `just inventory-diagram`, `checks.inventory-diagram` |
| Die Beispiele unten | `docs/inventory-example.json` | den Doku-Build; ein Test (`tests/inventory.nix`) hält die Datei gültig |

Die Feldbeschreibungen in den Tabellen sind englisch – sie stehen so im Schema und erscheinen genauso als Hover-Hilfe im Editor.

## Überblick

Die Pfeile zeigen von dem Feld, das den Verweis enthält, auf den Abschnitt, den es nennt. Verweise eines Abschnitts auf sich selbst stehen in seinem Kasten (↺). Jeder Kasten führt zu seinem Abschnitt weiter unten.

<figure class="nx-diagram">
<svg viewBox="0 0 680 416" role="img" aria-label="Die acht Abschnitte von inventory.json und die Felder, die von einem auf einen anderen verweisen" xmlns="http://www.w3.org/2000/svg">
<style>.nx-t{font-family:'DejaVu Sans',sans-serif;font-size:14px;font-weight:bold;fill:#2c2c2a}.nx-s{font-family:'DejaVu Sans',sans-serif;font-size:11px;fill:#5f5e5a}.nx-line{fill:none;stroke:#888780;stroke-width:1.4}.nx-gray rect{fill:#f1efe8;stroke:#888780}.nx-gray .nx-t{fill:#2c2c2a}.nx-gray .nx-s{fill:#5f5e5a}.nx-purple rect{fill:#eeedfe;stroke:#534ab7}.nx-purple .nx-t{fill:#26215c}.nx-purple .nx-s{fill:#534ab7}.nx-coral rect{fill:#faece7;stroke:#993c1d}.nx-coral .nx-t{fill:#4a1b0c}.nx-coral .nx-s{fill:#993c1d}</style>
<path class="nx-line" d="M260 48 H180"/><path class="nx-line" d="M186 44 L180 48 L186 52"/>
<text class="nx-s" x="220" y="42" text-anchor="middle">owner</text>
<path class="nx-line" d="M500 40 H420"/><path class="nx-line" d="M426 36 L420 40 L426 44"/>
<text class="nx-s" x="460" y="34" text-anchor="middle">hosts[]</text>
<path class="nx-line" d="M420 66 H450 V198 H500"/><path class="nx-line" d="M494 194 L500 198 L494 202"/>
<text class="nx-s" x="456" y="130" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M340 76 V170"/><path class="nx-line" d="M336 164 L340 170 L344 164"/>
<text class="nx-s" x="346" y="128" text-anchor="start">site</text>
<path class="nx-line" d="M290 76 V130 H120 V170"/><path class="nx-line" d="M116 164 L120 170 L124 164"/>
<text class="nx-s" x="205" y="147" text-anchor="middle">interfaces.*.network</text>
<path class="nx-line" d="M80 170 V110 H275 V76"/><path class="nx-line" d="M271 82 L275 76 L279 82"/>
<text class="nx-s" x="178" y="104" text-anchor="middle">dhcpServer</text>
<path class="nx-line" d="M180 198 H260"/><path class="nx-line" d="M254 194 L260 198 L254 202"/>
<text class="nx-s" x="220" y="192" text-anchor="middle">site</text>
<path class="nx-line" d="M300 226 V270 H100 V320"/><path class="nx-line" d="M96 314 L100 320 L104 314"/>
<text class="nx-s" x="200" y="264" text-anchor="middle">uplinks[]</text>
<path class="nx-line" d="M340 226 V320"/><path class="nx-line" d="M336 314 L340 320 L344 314"/>
<text class="nx-s" x="346" y="290" text-anchor="start">provider</text>
<path class="nx-line" d="M180 348 H260"/><path class="nx-line" d="M254 344 L260 348 L254 352"/>
<text class="nx-s" x="220" y="342" text-anchor="middle">provider</text>
<path class="nx-line" d="M580 226 V348 H420"/><path class="nx-line" d="M426 344 L420 348 L426 352"/>
<text class="nx-s" x="574" y="290" text-anchor="end">provider</text>
<path class="nx-line" d="M560 76 V170"/><path class="nx-line" d="M556 164 L560 170 L564 164"/>
<text class="nx-s" x="566" y="128" text-anchor="start">contracts[]</text>
<path class="nx-line" d="M660 48 H670 V364 H420"/><path class="nx-line" d="M426 360 L420 364 L426 368"/>
<text class="nx-s" x="540" y="380" text-anchor="middle">provider</text>
<path class="nx-line" d="M100 376 V400 H610 V226"/><path class="nx-line" d="M606 232 L610 226 L614 232"/>
<text class="nx-s" x="360" y="395" text-anchor="middle">contracts[]</text>
<a data-target="owners" tabindex="0" role="link" class="nx-gray"><rect x="20" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="44" text-anchor="middle">owners</text><text class="nx-s" x="100" y="62" text-anchor="middle">wer administriert</text></a>
<a data-target="hosts" tabindex="0" role="link" class="nx-gray"><rect x="260" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="44" text-anchor="middle">hosts</text><text class="nx-s" x="340" y="62" text-anchor="middle">↺ runsOn, power …</text></a>
<a data-target="services" tabindex="0" role="link" class="nx-purple"><rect x="500" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="44" text-anchor="middle">services</text><text class="nx-s" x="580" y="62" text-anchor="middle">↺ dependsOn, uses …</text></a>
<a data-target="networks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="194" text-anchor="middle">networks</text><text class="nx-s" x="100" y="212" text-anchor="middle">Layer 2 + Präfix</text></a>
<a data-target="sites" tabindex="0" role="link" class="nx-gray"><rect x="260" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="194" text-anchor="middle">sites</text><text class="nx-s" x="340" y="212" text-anchor="middle">wo etwas steht</text></a>
<a data-target="contracts" tabindex="0" role="link" class="nx-coral"><rect x="500" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="194" text-anchor="middle">contracts</text><text class="nx-s" x="580" y="212" text-anchor="middle">was bezahlt wird</text></a>
<a data-target="uplinks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="344" text-anchor="middle">uplinks</text><text class="nx-s" x="100" y="362" text-anchor="middle">Internetanschlüsse</text></a>
<a data-target="providers" tabindex="0" role="link" class="nx-coral"><rect x="260" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="344" text-anchor="middle">providers</text><text class="nx-s" x="340" y="362" text-anchor="middle">Firmen, Vereine</text></a>
</svg>
</figure>

## Alle Felder auf einen Blick

Jeder Abschnitt mit allen Feldern – **fett** sind Pflichtfelder, verschachtelte Objekte ausgeschrieben (`unlock.methods`, `endpoints[].fqdn`, `interfaces.<name>.mac`), und jedes Verweisfeld hat seinen Pfeil (Verweise innerhalb eines Abschnitts nur in der Typspalte: `→ hosts`).

<figure class="nx-diagram nx-diagram-wide">
<svg
 viewBox="0.00 0.00 1389.00 1135.96" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 1131.96)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1243.75,-725.21 1110.75,-725.21 1110.75,-492.71 1243.75,-492.71 1243.75,-725.21"/>
<polygon fill="#f1efe8" stroke="none" points="1110.75,-492.71 1110.75,-725.21 1243.75,-725.21 1243.75,-492.71 1110.75,-492.71"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1110.75,-705.96 1110.75,-725.21 1243.75,-725.21 1243.75,-705.96 1110.75,-705.96"/>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-705.96 1110.75,-725.21 1243.75,-725.21 1243.75,-705.96 1110.75,-705.96"/>
<text text-anchor="start" x="1155.88" y="-712.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-686.71 1110.75,-705.96 1183.25,-705.96 1183.25,-686.71 1110.75,-686.71"/>
<text text-anchor="start" x="1114.75" y="-692.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-686.71 1183.25,-705.96 1243.75,-705.96 1243.75,-686.71 1183.25,-686.71"/>
<text text-anchor="start" x="1187.25" y="-692.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-667.46 1110.75,-686.71 1183.25,-686.71 1183.25,-667.46 1110.75,-667.46"/>
<text text-anchor="start" x="1114.75" y="-674.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-667.46 1183.25,-686.71 1243.75,-686.71 1243.75,-667.46 1183.25,-667.46"/>
<text text-anchor="start" x="1187.25" y="-673.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-648.21 1110.75,-667.46 1183.25,-667.46 1183.25,-648.21 1110.75,-648.21"/>
<text text-anchor="start" x="1114.75" y="-654.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-648.21 1183.25,-667.46 1243.75,-667.46 1243.75,-648.21 1183.25,-648.21"/>
<text text-anchor="start" x="1187.25" y="-653.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-628.96 1110.75,-648.21 1183.25,-648.21 1183.25,-628.96 1110.75,-628.96"/>
<text text-anchor="start" x="1114.75" y="-634.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-628.96 1183.25,-648.21 1243.75,-648.21 1243.75,-628.96 1183.25,-628.96"/>
<text text-anchor="start" x="1187.25" y="-634.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-609.71 1110.75,-628.96 1183.25,-628.96 1183.25,-609.71 1110.75,-609.71"/>
<text text-anchor="start" x="1114.75" y="-616.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-609.71 1183.25,-628.96 1243.75,-628.96 1243.75,-609.71 1183.25,-609.71"/>
<text text-anchor="start" x="1187.25" y="-615.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-590.46 1110.75,-609.71 1183.25,-609.71 1183.25,-590.46 1110.75,-590.46"/>
<text text-anchor="start" x="1114.75" y="-596.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-590.46 1183.25,-609.71 1243.75,-609.71 1243.75,-590.46 1183.25,-590.46"/>
<text text-anchor="start" x="1187.25" y="-596.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-571.21 1110.75,-590.46 1183.25,-590.46 1183.25,-571.21 1110.75,-571.21"/>
<text text-anchor="start" x="1114.75" y="-576.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-571.21 1183.25,-590.46 1243.75,-590.46 1243.75,-571.21 1183.25,-571.21"/>
<text text-anchor="start" x="1187.25" y="-576.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-551.96 1110.75,-571.21 1183.25,-571.21 1183.25,-551.96 1110.75,-551.96"/>
<text text-anchor="start" x="1114.75" y="-557.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-551.96 1183.25,-571.21 1243.75,-571.21 1243.75,-551.96 1183.25,-551.96"/>
<text text-anchor="start" x="1187.25" y="-557.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-531.21 1110.75,-551.96 1183.25,-551.96 1183.25,-531.21 1110.75,-531.21"/>
<text text-anchor="start" x="1114.75" y="-538.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-531.21 1183.25,-551.96 1243.75,-551.96 1243.75,-531.21 1183.25,-531.21"/>
<text text-anchor="start" x="1187.25" y="-538.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-511.96 1110.75,-531.21 1183.25,-531.21 1183.25,-511.96 1110.75,-511.96"/>
<text text-anchor="start" x="1114.75" y="-517.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-511.96 1183.25,-531.21 1243.75,-531.21 1243.75,-511.96 1183.25,-511.96"/>
<text text-anchor="start" x="1187.25" y="-517.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-492.71 1110.75,-511.96 1183.25,-511.96 1183.25,-492.71 1110.75,-492.71"/>
<text text-anchor="start" x="1114.75" y="-498.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-492.71 1183.25,-511.96 1243.75,-511.96 1243.75,-492.71 1183.25,-492.71"/>
<text text-anchor="start" x="1187.25" y="-498.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node5" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1381,-309.09 1308.75,-309.09 1308.75,-212.84 1381,-212.84 1381,-309.09"/>
<polygon fill="#f1efe8" stroke="none" points="1308.75,-212.84 1308.75,-309.09 1381,-309.09 1381,-212.84 1308.75,-212.84"/>
<g id="a_node5_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1308.75,-289.84 1308.75,-309.09 1381,-309.09 1381,-289.84 1308.75,-289.84"/>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-289.84 1308.75,-309.09 1381,-309.09 1381,-289.84 1308.75,-289.84"/>
<text text-anchor="start" x="1322.75" y="-296.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node5_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-270.59 1308.75,-289.84 1349,-289.84 1349,-270.59 1308.75,-270.59"/>
<text text-anchor="start" x="1312.75" y="-276.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-270.59 1349,-289.84 1381,-289.84 1381,-270.59 1349,-270.59"/>
<text text-anchor="start" x="1353" y="-276.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-251.34 1308.75,-270.59 1349,-270.59 1349,-251.34 1308.75,-251.34"/>
<text text-anchor="start" x="1312.75" y="-258.09" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-251.34 1349,-270.59 1381,-270.59 1381,-251.34 1349,-251.34"/>
<text text-anchor="start" x="1353" y="-257.09" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-232.09 1308.75,-251.34 1349,-251.34 1349,-232.09 1308.75,-232.09"/>
<text text-anchor="start" x="1312.75" y="-237.84" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-232.09 1349,-251.34 1381,-251.34 1381,-232.09 1349,-232.09"/>
<text text-anchor="start" x="1353" y="-237.84" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-212.84 1308.75,-232.09 1349,-232.09 1349,-212.84 1308.75,-212.84"/>
<text text-anchor="start" x="1312.75" y="-218.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node5_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-212.84 1349,-232.09 1381,-232.09 1381,-212.84 1349,-212.84"/>
<text text-anchor="start" x="1353" y="-218.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1243.75,-541.59C1352.56,-541.59 1204.58,-310.68 1301.35,-299.86"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.21,-301.97 1307.09,-299.55 1300.98,-297.77 1301.21,-301.97"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="474.25,-850.71 239.25,-850.71 239.25,-67.21 474.25,-67.21 474.25,-850.71"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-67.21 239.25,-850.71 474.25,-850.71 474.25,-67.21 239.25,-67.21"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-831.46 239.25,-850.71 474.25,-850.71 474.25,-831.46 239.25,-831.46"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-831.46 239.25,-850.71 474.25,-850.71 474.25,-831.46 239.25,-831.46"/>
<text text-anchor="start" x="344" y="-838.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-812.21 239.25,-831.46 404,-831.46 404,-812.21 239.25,-812.21"/>
<text text-anchor="start" x="243.25" y="-817.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-812.21 404,-831.46 474.25,-831.46 474.25,-812.21 404,-812.21"/>
<text text-anchor="start" x="408" y="-817.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-791.46 239.25,-812.21 404,-812.21 404,-791.46 239.25,-791.46"/>
<text text-anchor="start" x="243.25" y="-797.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-791.46 404,-812.21 474.25,-812.21 474.25,-791.46 404,-791.46"/>
<text text-anchor="start" x="408" y="-798.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-772.21 239.25,-791.46 404,-791.46 404,-772.21 239.25,-772.21"/>
<text text-anchor="start" x="243.25" y="-777.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-772.21 404,-791.46 474.25,-791.46 474.25,-772.21 404,-772.21"/>
<text text-anchor="start" x="408" y="-777.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-description" tabindex="0" role="link"><title>hosts.description</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-752.96 239.25,-772.21 404,-772.21 404,-752.96 239.25,-752.96"/>
<text text-anchor="start" x="243.25" y="-758.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">description</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-description" tabindex="0" role="link"><title>hosts.description</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-752.96 404,-772.21 474.25,-772.21 474.25,-752.96 404,-752.96"/>
<text text-anchor="start" x="408" y="-758.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-732.21 239.25,-752.96 404,-752.96 404,-732.21 239.25,-732.21"/>
<text text-anchor="start" x="243.25" y="-738.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-732.21 404,-752.96 474.25,-752.96 474.25,-732.21 404,-732.21"/>
<text text-anchor="start" x="408" y="-739.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-712.96 239.25,-732.21 404,-732.21 404,-712.96 239.25,-712.96"/>
<text text-anchor="start" x="243.25" y="-718.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-712.96 404,-732.21 474.25,-732.21 474.25,-712.96 404,-712.96"/>
<text text-anchor="start" x="408" y="-718.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-693.71 239.25,-712.96 404,-712.96 404,-693.71 239.25,-693.71"/>
<text text-anchor="start" x="243.25" y="-699.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.connector</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-693.71 404,-712.96 474.25,-712.96 474.25,-693.71 404,-693.71"/>
<text text-anchor="start" x="408" y="-699.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-674.46 239.25,-693.71 404,-693.71 404,-674.46 239.25,-674.46"/>
<text text-anchor="start" x="243.25" y="-680.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-674.46 404,-693.71 474.25,-693.71 474.25,-674.46 404,-674.46"/>
<text text-anchor="start" x="408" y="-680.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-655.21 239.25,-674.46 404,-674.46 404,-655.21 239.25,-655.21"/>
<text text-anchor="start" x="243.25" y="-660.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-655.21 404,-674.46 474.25,-674.46 474.25,-655.21 404,-655.21"/>
<text text-anchor="start" x="408" y="-660.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-635.96 239.25,-655.21 404,-655.21 404,-635.96 239.25,-635.96"/>
<text text-anchor="start" x="243.25" y="-642.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-635.96 404,-655.21 474.25,-655.21 474.25,-635.96 404,-635.96"/>
<text text-anchor="start" x="408" y="-641.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-616.71 239.25,-635.96 404,-635.96 404,-616.71 239.25,-616.71"/>
<text text-anchor="start" x="243.25" y="-622.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-616.71 404,-635.96 474.25,-635.96 474.25,-616.71 404,-616.71"/>
<text text-anchor="start" x="408" y="-622.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-597.46 239.25,-616.71 404,-616.71 404,-597.46 239.25,-597.46"/>
<text text-anchor="start" x="243.25" y="-603.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-597.46 404,-616.71 474.25,-616.71 474.25,-597.46 404,-597.46"/>
<text text-anchor="start" x="408" y="-603.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-578.21 239.25,-597.46 404,-597.46 404,-578.21 239.25,-578.21"/>
<text text-anchor="start" x="243.25" y="-583.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.macLocal</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-578.21 404,-597.46 474.25,-597.46 474.25,-578.21 404,-578.21"/>
<text text-anchor="start" x="408" y="-583.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-558.96 239.25,-578.21 404,-578.21 404,-558.96 239.25,-558.96"/>
<text text-anchor="start" x="243.25" y="-564.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-558.96 404,-578.21 474.25,-578.21 474.25,-558.96 404,-558.96"/>
<text text-anchor="start" x="408" y="-564.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-539.71 239.25,-558.96 404,-558.96 404,-539.71 239.25,-539.71"/>
<text text-anchor="start" x="243.25" y="-545.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-539.71 404,-558.96 474.25,-558.96 474.25,-539.71 404,-539.71"/>
<text text-anchor="start" x="408" y="-545.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-520.46 239.25,-539.71 404,-539.71 404,-520.46 239.25,-520.46"/>
<text text-anchor="start" x="243.25" y="-527.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.kind</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-520.46 404,-539.71 474.25,-539.71 474.25,-520.46 404,-520.46"/>
<text text-anchor="start" x="408" y="-526.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-501.21 239.25,-520.46 404,-520.46 404,-501.21 239.25,-501.21"/>
<text text-anchor="start" x="243.25" y="-506.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.standard</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-501.21 404,-520.46 474.25,-520.46 474.25,-501.21 404,-501.21"/>
<text text-anchor="start" x="408" y="-506.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-480.46 239.25,-501.21 404,-501.21 404,-480.46 239.25,-480.46"/>
<text text-anchor="start" x="243.25" y="-486.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-480.46 404,-501.21 474.25,-501.21 474.25,-480.46 404,-480.46"/>
<text text-anchor="start" x="408" y="-487.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-461.21 239.25,-480.46 404,-480.46 404,-461.21 239.25,-461.21"/>
<text text-anchor="start" x="243.25" y="-466.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-461.21 404,-480.46 474.25,-480.46 474.25,-461.21 404,-461.21"/>
<text text-anchor="start" x="408" y="-466.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-441.96 239.25,-461.21 404,-461.21 404,-441.96 239.25,-441.96"/>
<text text-anchor="start" x="243.25" y="-447.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.speed</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-441.96 404,-461.21 474.25,-461.21 474.25,-441.96 404,-441.96"/>
<text text-anchor="start" x="408" y="-447.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-422.71 239.25,-441.96 404,-441.96 404,-422.71 239.25,-422.71"/>
<text text-anchor="start" x="243.25" y="-428.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.wifiStandard</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-422.71 404,-441.96 474.25,-441.96 474.25,-422.71 404,-422.71"/>
<text text-anchor="start" x="408" y="-428.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-403.46 239.25,-422.71 404,-422.71 404,-403.46 239.25,-403.46"/>
<text text-anchor="start" x="243.25" y="-410.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-403.46 404,-422.71 474.25,-422.71 474.25,-403.46 404,-403.46"/>
<text text-anchor="start" x="408" y="-409.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-384.21 239.25,-403.46 404,-403.46 404,-384.21 239.25,-384.21"/>
<text text-anchor="start" x="243.25" y="-390.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-384.21 404,-403.46 474.25,-403.46 474.25,-384.21 404,-384.21"/>
<text text-anchor="start" x="408" y="-389.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-363.46 239.25,-384.21 404,-384.21 404,-363.46 239.25,-363.46"/>
<text text-anchor="start" x="243.25" y="-369.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-363.46 404,-384.21 474.25,-384.21 474.25,-363.46 404,-363.46"/>
<text text-anchor="start" x="408" y="-370.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-344.21 239.25,-363.46 404,-363.46 404,-344.21 239.25,-344.21"/>
<text text-anchor="start" x="243.25" y="-349.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-344.21 404,-363.46 474.25,-363.46 474.25,-344.21 404,-344.21"/>
<text text-anchor="start" x="408" y="-349.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-324.96 239.25,-344.21 404,-344.21 404,-324.96 239.25,-324.96"/>
<text text-anchor="start" x="243.25" y="-330.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-324.96 404,-344.21 474.25,-344.21 474.25,-324.96 404,-324.96"/>
<text text-anchor="start" x="408" y="-330.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-304.21 239.25,-324.96 404,-324.96 404,-304.21 239.25,-304.21"/>
<text text-anchor="start" x="243.25" y="-311.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-304.21 404,-324.96 474.25,-324.96 474.25,-304.21 404,-304.21"/>
<text text-anchor="start" x="408" y="-311.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-283.46 239.25,-304.21 404,-304.21 404,-283.46 239.25,-283.46"/>
<text text-anchor="start" x="243.25" y="-289.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-283.46 404,-304.21 474.25,-304.21 474.25,-283.46 404,-283.46"/>
<text text-anchor="start" x="408" y="-290.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-264.21 239.25,-283.46 404,-283.46 404,-264.21 239.25,-264.21"/>
<text text-anchor="start" x="243.25" y="-269.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-264.21 404,-283.46 474.25,-283.46 474.25,-264.21 404,-264.21"/>
<text text-anchor="start" x="408" y="-269.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-243.46 239.25,-264.21 404,-264.21 404,-243.46 239.25,-243.46"/>
<text text-anchor="start" x="243.25" y="-249.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-243.46 404,-264.21 474.25,-264.21 474.25,-243.46 404,-243.46"/>
<text text-anchor="start" x="408" y="-250.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-224.21 239.25,-243.46 404,-243.46 404,-224.21 239.25,-224.21"/>
<text text-anchor="start" x="243.25" y="-229.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-224.21 404,-243.46 474.25,-243.46 474.25,-224.21 404,-224.21"/>
<text text-anchor="start" x="408" y="-229.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_95"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-203.46 239.25,-224.21 404,-224.21 404,-203.46 239.25,-203.46"/>
<text text-anchor="start" x="243.25" y="-209.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_96"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-203.46 404,-224.21 474.25,-224.21 474.25,-203.46 404,-203.46"/>
<text text-anchor="start" x="408" y="-210.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_97"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-184.21 239.25,-203.46 404,-203.46 404,-184.21 239.25,-184.21"/>
<text text-anchor="start" x="243.25" y="-189.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_98"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-184.21 404,-203.46 474.25,-203.46 474.25,-184.21 404,-184.21"/>
<text text-anchor="start" x="408" y="-189.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_99"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-164.96 239.25,-184.21 404,-184.21 404,-164.96 239.25,-164.96"/>
<text text-anchor="start" x="243.25" y="-170.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_100"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-164.96 404,-184.21 474.25,-184.21 474.25,-164.96 404,-164.96"/>
<text text-anchor="start" x="408" y="-170.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_101"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-145.71 239.25,-164.96 404,-164.96 404,-145.71 239.25,-145.71"/>
<text text-anchor="start" x="243.25" y="-151.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_102"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-145.71 404,-164.96 474.25,-164.96 474.25,-145.71 404,-145.71"/>
<text text-anchor="start" x="408" y="-151.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_103"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-126.46 239.25,-145.71 404,-145.71 404,-126.46 239.25,-126.46"/>
<text text-anchor="start" x="243.25" y="-133.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_104"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-126.46 404,-145.71 474.25,-145.71 474.25,-126.46 404,-126.46"/>
<text text-anchor="start" x="408" y="-132.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_105"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-105.71 239.25,-126.46 404,-126.46 404,-105.71 239.25,-105.71"/>
<text text-anchor="start" x="243.25" y="-112.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_106"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-105.71 404,-126.46 474.25,-126.46 474.25,-105.71 404,-105.71"/>
<text text-anchor="start" x="408" y="-112.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_107"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-86.46 239.25,-105.71 404,-105.71 404,-86.46 239.25,-86.46"/>
<text text-anchor="start" x="243.25" y="-92.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_108"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-86.46 404,-105.71 474.25,-105.71 474.25,-86.46 404,-86.46"/>
<text text-anchor="start" x="408" y="-92.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_109"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-67.21 239.25,-86.46 404,-86.46 404,-67.21 239.25,-67.21"/>
<text text-anchor="start" x="243.25" y="-72.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_110"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-67.21 404,-86.46 474.25,-86.46 474.25,-67.21 404,-67.21"/>
<text text-anchor="start" x="408" y="-72.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-801.84C757.22,-801.84 824.11,-717.1 1103.27,-715.61"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.09,-717.71 1109.09,-715.59 1103.08,-713.51 1103.09,-717.71"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="660.25,-679.96 539.25,-679.96 539.25,-445.96 660.25,-445.96 660.25,-679.96"/>
<polygon fill="#f1efe8" stroke="none" points="539.25,-445.96 539.25,-679.96 660.25,-679.96 660.25,-445.96 539.25,-445.96"/>
<g id="a_node3_111"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="539.25,-660.71 539.25,-679.96 660.25,-679.96 660.25,-660.71 539.25,-660.71"/>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-660.71 539.25,-679.96 660.25,-679.96 660.25,-660.71 539.25,-660.71"/>
<text text-anchor="start" x="578.75" y="-667.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_112"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-641.46 539.25,-660.71 615.5,-660.71 615.5,-641.46 539.25,-641.46"/>
<text text-anchor="start" x="543.25" y="-647.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_113"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-641.46 615.5,-660.71 660.25,-660.71 660.25,-641.46 615.5,-641.46"/>
<text text-anchor="start" x="619.5" y="-647.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-622.21 539.25,-641.46 615.5,-641.46 615.5,-622.21 539.25,-622.21"/>
<text text-anchor="start" x="543.25" y="-628.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-622.21 615.5,-641.46 660.25,-641.46 660.25,-622.21 615.5,-622.21"/>
<text text-anchor="start" x="619.5" y="-627.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_116"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-602.96 539.25,-622.21 615.5,-622.21 615.5,-602.96 539.25,-602.96"/>
<text text-anchor="start" x="543.25" y="-609.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_117"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-602.96 615.5,-622.21 660.25,-622.21 660.25,-602.96 615.5,-602.96"/>
<text text-anchor="start" x="619.5" y="-608.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_118"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-582.21 539.25,-602.96 615.5,-602.96 615.5,-582.21 539.25,-582.21"/>
<text text-anchor="start" x="543.25" y="-588.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_119"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-582.21 615.5,-602.96 660.25,-602.96 660.25,-582.21 615.5,-582.21"/>
<text text-anchor="start" x="619.5" y="-589.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_120"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-562.96 539.25,-582.21 615.5,-582.21 615.5,-562.96 539.25,-562.96"/>
<text text-anchor="start" x="543.25" y="-568.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_121"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-562.96 615.5,-582.21 660.25,-582.21 660.25,-562.96 615.5,-562.96"/>
<text text-anchor="start" x="619.5" y="-568.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_122"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-543.71 539.25,-562.96 615.5,-562.96 615.5,-543.71 539.25,-543.71"/>
<text text-anchor="start" x="543.25" y="-549.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_123"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-543.71 615.5,-562.96 660.25,-562.96 660.25,-543.71 615.5,-543.71"/>
<text text-anchor="start" x="619.5" y="-549.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_124"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-524.46 539.25,-543.71 615.5,-543.71 615.5,-524.46 539.25,-524.46"/>
<text text-anchor="start" x="543.25" y="-530.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6SubnetId</text>
</a>
</g>
<g id="a_node3_125"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-524.46 615.5,-543.71 660.25,-543.71 660.25,-524.46 615.5,-524.46"/>
<text text-anchor="start" x="619.5" y="-530.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node3_126"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-505.21 539.25,-524.46 615.5,-524.46 615.5,-505.21 539.25,-505.21"/>
<text text-anchor="start" x="543.25" y="-511.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_127"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-505.21 615.5,-524.46 660.25,-524.46 660.25,-505.21 615.5,-505.21"/>
<text text-anchor="start" x="619.5" y="-510.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_128"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-485.96 539.25,-505.21 615.5,-505.21 615.5,-485.96 539.25,-485.96"/>
<text text-anchor="start" x="543.25" y="-491.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_129"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-485.96 615.5,-505.21 660.25,-505.21 660.25,-485.96 615.5,-485.96"/>
<text text-anchor="start" x="619.5" y="-491.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_130"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-465.21 539.25,-485.96 615.5,-485.96 615.5,-465.21 539.25,-465.21"/>
<text text-anchor="start" x="543.25" y="-472.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_131"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-465.21 615.5,-485.96 660.25,-485.96 660.25,-465.21 615.5,-465.21"/>
<text text-anchor="start" x="619.5" y="-472.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_132"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-445.96 539.25,-465.21 615.5,-465.21 615.5,-445.96 539.25,-445.96"/>
<text text-anchor="start" x="543.25" y="-451.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_133"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-445.96 615.5,-465.21 660.25,-465.21 660.25,-445.96 615.5,-445.96"/>
<text text-anchor="start" x="619.5" y="-451.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-490.84C556.45,-490.84 460.76,-659.3 531.84,-669.82"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="531.46,-671.9 537.59,-670.22 531.75,-667.71 531.46,-671.9"/>
</g>
<g id="node4" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="635.88,-325.46 563.62,-325.46 563.62,-248.46 635.88,-248.46 635.88,-325.46"/>
<polygon fill="#f1efe8" stroke="none" points="563.62,-248.46 563.62,-325.46 635.88,-325.46 635.88,-248.46 563.62,-248.46"/>
<g id="a_node4_134"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="563.62,-306.21 563.62,-325.46 635.88,-325.46 635.88,-306.21 563.62,-306.21"/>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-306.21 563.62,-325.46 635.88,-325.46 635.88,-306.21 563.62,-306.21"/>
<text text-anchor="start" x="582.88" y="-312.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node4_135"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-286.96 563.62,-306.21 603.88,-306.21 603.88,-286.96 563.62,-286.96"/>
<text text-anchor="start" x="567.62" y="-292.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node4_136"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-286.96 603.88,-306.21 635.88,-306.21 635.88,-286.96 603.88,-286.96"/>
<text text-anchor="start" x="607.88" y="-292.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_137"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-267.71 563.62,-286.96 603.88,-286.96 603.88,-267.71 563.62,-267.71"/>
<text text-anchor="start" x="567.62" y="-274.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_138"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-267.71 603.88,-286.96 635.88,-286.96 635.88,-267.71 603.88,-267.71"/>
<text text-anchor="start" x="607.88" y="-273.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_139"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-248.46 563.62,-267.71 603.88,-267.71 603.88,-248.46 563.62,-248.46"/>
<text text-anchor="start" x="567.62" y="-254.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_140"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-248.46 603.88,-267.71 635.88,-267.71 635.88,-248.46 603.88,-248.46"/>
<text text-anchor="start" x="607.88" y="-254.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-314.59C510.92,-314.59 521.91,-315.68 555.17,-315.82"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="554.96,-317.92 560.96,-315.84 554.96,-313.72 554.96,-317.92"/>
</g>
<g id="node7" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="828.25,-485.84 725.25,-485.84 725.25,-348.09 828.25,-348.09 828.25,-485.84"/>
<polygon fill="#f1efe8" stroke="none" points="725.25,-348.09 725.25,-485.84 828.25,-485.84 828.25,-348.09 725.25,-348.09"/>
<g id="a_node7_141"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="725.25,-466.59 725.25,-485.84 828.25,-485.84 828.25,-466.59 725.25,-466.59"/>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-466.59 725.25,-485.84 828.25,-485.84 828.25,-466.59 725.25,-466.59"/>
<text text-anchor="start" x="765.88" y="-473.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node7_142"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-447.34 725.25,-466.59 767.75,-466.59 767.75,-447.34 725.25,-447.34"/>
<text text-anchor="start" x="729.25" y="-454.09" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node7_143"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-447.34 767.75,-466.59 828.25,-466.59 828.25,-447.34 767.75,-447.34"/>
<text text-anchor="start" x="771.75" y="-453.09" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_144"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-428.09 725.25,-447.34 767.75,-447.34 767.75,-428.09 725.25,-428.09"/>
<text text-anchor="start" x="729.25" y="-433.84" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Ula</text>
</a>
</g>
<g id="a_node7_145"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-428.09 767.75,-447.34 828.25,-447.34 828.25,-428.09 767.75,-428.09"/>
<text text-anchor="start" x="771.75" y="-433.84" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_146"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-408.84 725.25,-428.09 767.75,-428.09 767.75,-408.84 725.25,-408.84"/>
<text text-anchor="start" x="729.25" y="-415.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node7_147"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-408.84 767.75,-428.09 828.25,-428.09 828.25,-408.84 767.75,-408.84"/>
<text text-anchor="start" x="771.75" y="-414.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_148"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-389.59 725.25,-408.84 767.75,-408.84 767.75,-389.59 725.25,-389.59"/>
<text text-anchor="start" x="729.25" y="-395.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_149"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-389.59 767.75,-408.84 828.25,-408.84 828.25,-389.59 767.75,-389.59"/>
<text text-anchor="start" x="771.75" y="-395.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_150"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-368.84 725.25,-389.59 767.75,-389.59 767.75,-368.84 725.25,-368.84"/>
<text text-anchor="start" x="729.25" y="-375.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_151"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-368.84 767.75,-389.59 828.25,-389.59 828.25,-368.84 767.75,-368.84"/>
<text text-anchor="start" x="771.75" y="-376.09" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_152"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-348.09 725.25,-368.84 767.75,-368.84 767.75,-348.09 725.25,-348.09"/>
<text text-anchor="start" x="729.25" y="-355.59" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node7_153"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-348.09 767.75,-368.84 828.25,-368.84 828.25,-348.09 767.75,-348.09"/>
<text text-anchor="start" x="771.75" y="-355.34" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-213.84C557.61,-213.84 597.4,-183.2 660.25,-237.96 740.98,-308.31 621.59,-468.16 717.63,-475.92"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.51,-478.02 723.59,-476.15 717.67,-473.82 717.51,-478.02"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M661.25,-592.59C700.09,-592.59 679.23,-646.08 660.25,-679.96 629.21,-735.37 586.16,-713.16 539.25,-755.96 506.01,-786.3 520.07,-835.35 481.49,-840.63"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="481.77,-838.5 475.91,-840.98 482.03,-842.7 481.77,-838.5"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M660.25,-475.59C686.43,-475.59 694.82,-476.1 717.66,-476.2"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.58,-478.3 723.59,-476.21 717.59,-474.1 717.58,-478.3"/>
</g>
<g id="node6" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-1127.96 0,-1127.96 0,-539.96 174.25,-539.96 174.25,-1127.96"/>
<polygon fill="#f1efe8" stroke="none" points="0,-539.96 0,-1127.96 174.25,-1127.96 174.25,-539.96 0,-539.96"/>
<g id="a_node6_154"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-1108.71 0,-1127.96 174.25,-1127.96 174.25,-1108.71 0,-1108.71"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-1108.71 0,-1127.96 174.25,-1127.96 174.25,-1108.71 0,-1108.71"/>
<text text-anchor="start" x="68" y="-1115.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node6_155"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1089.46 0,-1108.71 107,-1108.71 107,-1089.46 0,-1089.46"/>
<text text-anchor="start" x="4" y="-1095.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node6_156"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1089.46 107,-1108.71 174.25,-1108.71 174.25,-1089.46 107,-1089.46"/>
<text text-anchor="start" x="111" y="-1095.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_157"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1070.21 0,-1089.46 107,-1089.46 107,-1070.21 0,-1070.21"/>
<text text-anchor="start" x="4" y="-1075.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node6_158"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1070.21 107,-1089.46 174.25,-1089.46 174.25,-1070.21 107,-1070.21"/>
<text text-anchor="start" x="111" y="-1075.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_159"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1050.96 0,-1070.21 107,-1070.21 107,-1050.96 0,-1050.96"/>
<text text-anchor="start" x="4" y="-1056.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node6_160"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1050.96 107,-1070.21 174.25,-1070.21 174.25,-1050.96 107,-1050.96"/>
<text text-anchor="start" x="111" y="-1056.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node6_161"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1031.71 0,-1050.96 107,-1050.96 107,-1031.71 0,-1031.71"/>
<text text-anchor="start" x="4" y="-1037.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node6_162"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1031.71 107,-1050.96 174.25,-1050.96 174.25,-1031.71 107,-1031.71"/>
<text text-anchor="start" x="111" y="-1037.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node6_163"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1012.46 0,-1031.71 107,-1031.71 107,-1012.46 0,-1012.46"/>
<text text-anchor="start" x="4" y="-1018.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node6_164"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1012.46 107,-1031.71 174.25,-1031.71 174.25,-1012.46 107,-1012.46"/>
<text text-anchor="start" x="111" y="-1018.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_165"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-993.21 0,-1012.46 107,-1012.46 107,-993.21 0,-993.21"/>
<text text-anchor="start" x="4" y="-998.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node6_166"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-993.21 107,-1012.46 174.25,-1012.46 174.25,-993.21 107,-993.21"/>
<text text-anchor="start" x="111" y="-998.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_167"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-973.96 0,-993.21 107,-993.21 107,-973.96 0,-973.96"/>
<text text-anchor="start" x="4" y="-979.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node6_168"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-973.96 107,-993.21 174.25,-993.21 174.25,-973.96 107,-973.96"/>
<text text-anchor="start" x="111" y="-979.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_169"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-954.71 0,-973.96 107,-973.96 107,-954.71 0,-954.71"/>
<text text-anchor="start" x="4" y="-960.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node6_170"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-954.71 107,-973.96 174.25,-973.96 174.25,-954.71 107,-954.71"/>
<text text-anchor="start" x="111" y="-960.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_171"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-935.46 0,-954.71 107,-954.71 107,-935.46 0,-935.46"/>
<text text-anchor="start" x="4" y="-942.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node6_172"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-935.46 107,-954.71 174.25,-954.71 174.25,-935.46 107,-935.46"/>
<text text-anchor="start" x="111" y="-941.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_173"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-916.21 0,-935.46 107,-935.46 107,-916.21 0,-916.21"/>
<text text-anchor="start" x="4" y="-921.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node6_174"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-916.21 107,-935.46 174.25,-935.46 174.25,-916.21 107,-916.21"/>
<text text-anchor="start" x="111" y="-921.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_175"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-895.46 0,-916.21 107,-916.21 107,-895.46 0,-895.46"/>
<text text-anchor="start" x="4" y="-901.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node6_176"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-895.46 107,-916.21 174.25,-916.21 174.25,-895.46 107,-895.46"/>
<text text-anchor="start" x="111" y="-902.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_177"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-874.71 0,-895.46 107,-895.46 107,-874.71 0,-874.71"/>
<text text-anchor="start" x="4" y="-881.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node6_178"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-874.71 107,-895.46 174.25,-895.46 174.25,-874.71 107,-874.71"/>
<text text-anchor="start" x="111" y="-881.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node6_179"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-855.46 0,-874.71 107,-874.71 107,-855.46 0,-855.46"/>
<text text-anchor="start" x="4" y="-861.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node6_180"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-855.46 107,-874.71 174.25,-874.71 174.25,-855.46 107,-855.46"/>
<text text-anchor="start" x="111" y="-861.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_181"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-836.21 0,-855.46 107,-855.46 107,-836.21 0,-836.21"/>
<text text-anchor="start" x="4" y="-842.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node6_182"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-836.21 107,-855.46 174.25,-855.46 174.25,-836.21 107,-836.21"/>
<text text-anchor="start" x="111" y="-841.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_183"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-815.46 0,-836.21 107,-836.21 107,-815.46 0,-815.46"/>
<text text-anchor="start" x="4" y="-821.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node6_184"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-815.46 107,-836.21 174.25,-836.21 174.25,-815.46 107,-815.46"/>
<text text-anchor="start" x="111" y="-822.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_185"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-796.21 0,-815.46 107,-815.46 107,-796.21 0,-796.21"/>
<text text-anchor="start" x="4" y="-801.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node6_186"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-796.21 107,-815.46 174.25,-815.46 174.25,-796.21 107,-796.21"/>
<text text-anchor="start" x="111" y="-801.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_187"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-776.96 0,-796.21 107,-796.21 107,-776.96 0,-776.96"/>
<text text-anchor="start" x="4" y="-783.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node6_188"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-776.96 107,-796.21 174.25,-796.21 174.25,-776.96 107,-776.96"/>
<text text-anchor="start" x="111" y="-782.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_189"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-757.71 0,-776.96 107,-776.96 107,-757.71 0,-757.71"/>
<text text-anchor="start" x="4" y="-764.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node6_190"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-757.71 107,-776.96 174.25,-776.96 174.25,-757.71 107,-757.71"/>
<text text-anchor="start" x="111" y="-763.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_191"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-738.46 0,-757.71 107,-757.71 107,-738.46 0,-738.46"/>
<text text-anchor="start" x="4" y="-744.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node6_192"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-738.46 107,-757.71 174.25,-757.71 174.25,-738.46 107,-738.46"/>
<text text-anchor="start" x="111" y="-744.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_193"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-719.21 0,-738.46 107,-738.46 107,-719.21 0,-719.21"/>
<text text-anchor="start" x="4" y="-724.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node6_194"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-719.21 107,-738.46 174.25,-738.46 174.25,-719.21 107,-719.21"/>
<text text-anchor="start" x="111" y="-724.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_195"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-698.46 0,-719.21 107,-719.21 107,-698.46 0,-698.46"/>
<text text-anchor="start" x="4" y="-704.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node6_196"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-698.46 107,-719.21 174.25,-719.21 174.25,-698.46 107,-698.46"/>
<text text-anchor="start" x="111" y="-705.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_197"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-677.71 0,-698.46 107,-698.46 107,-677.71 0,-677.71"/>
<text text-anchor="start" x="4" y="-684.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node6_198"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-677.71 107,-698.46 174.25,-698.46 174.25,-677.71 107,-677.71"/>
<text text-anchor="start" x="111" y="-684.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node6_199"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-658.46 0,-677.71 107,-677.71 107,-658.46 0,-658.46"/>
<text text-anchor="start" x="4" y="-665.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_200"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-658.46 107,-677.71 174.25,-677.71 174.25,-658.46 107,-658.46"/>
<text text-anchor="start" x="111" y="-664.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_201"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-639.21 0,-658.46 107,-658.46 107,-639.21 0,-639.21"/>
<text text-anchor="start" x="4" y="-644.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_202"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-639.21 107,-658.46 174.25,-658.46 174.25,-639.21 107,-639.21"/>
<text text-anchor="start" x="111" y="-644.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_203"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-619.96 0,-639.21 107,-639.21 107,-619.96 0,-619.96"/>
<text text-anchor="start" x="4" y="-625.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node6_204"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-619.96 107,-639.21 174.25,-639.21 174.25,-619.96 107,-619.96"/>
<text text-anchor="start" x="111" y="-625.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_205"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-599.21 0,-619.96 107,-619.96 107,-599.21 0,-599.21"/>
<text text-anchor="start" x="4" y="-605.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node6_206"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-599.21 107,-619.96 174.25,-619.96 174.25,-599.21 107,-599.21"/>
<text text-anchor="start" x="111" y="-606.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node6_207"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-579.96 0,-599.21 107,-599.21 107,-579.96 0,-579.96"/>
<text text-anchor="start" x="4" y="-585.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node6_208"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-579.96 107,-599.21 174.25,-599.21 174.25,-579.96 107,-579.96"/>
<text text-anchor="start" x="111" y="-585.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_209"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-559.21 0,-579.96 107,-579.96 107,-559.21 0,-559.21"/>
<text text-anchor="start" x="4" y="-565.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node6_210"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-559.21 107,-579.96 174.25,-579.96 174.25,-559.21 107,-559.21"/>
<text text-anchor="start" x="111" y="-566.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_211"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-539.96 0,-559.21 107,-559.21 107,-539.96 0,-539.96"/>
<text text-anchor="start" x="4" y="-545.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node6_212"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-539.96 107,-559.21 174.25,-559.21 174.25,-539.96 107,-539.96"/>
<text text-anchor="start" x="111" y="-545.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-885.09C362.92,-885.09 410.08,-884.96 598.75,-884.96 598.75,-884.96 598.75,-884.96 777.75,-884.96 797.17,-884.96 1053.54,-736.72 1103.51,-717.61"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.93,-719.67 1109.15,-716.04 1102.8,-715.63 1103.93,-719.67"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-688.09C245.39,-688.09 171.29,-829.94 231.66,-840.47"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-842.56 237.59,-840.96 231.78,-838.38 231.44,-842.56"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-609.59C298.12,-609.59 149.37,-141.21 239.25,-55.96 355.42,54.21 438.65,-32.96 598.75,-32.96 598.75,-32.96 598.75,-32.96 970.5,-32.96 1098.09,-32.96 1151.85,-32.46 1243.75,-120.96 1302.66,-177.7 1229.2,-292.03 1301.31,-299.12"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301,-301.21 1307.09,-299.39 1301.19,-297.01 1301,-301.21"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-379.21C924.92,-379.21 950.13,-393.16 1045.75,-378.96 1164.06,-361.4 1185.77,-301.97 1301.36,-299.54"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.11,-301.64 1307.09,-299.48 1301.06,-297.44 1301.11,-301.64"/>
</g>
<g id="node8" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1045.75,-368.21 893.25,-368.21 893.25,-95.71 1045.75,-95.71 1045.75,-368.21"/>
<polygon fill="#f1efe8" stroke="none" points="893.25,-95.71 893.25,-368.21 1045.75,-368.21 1045.75,-95.71 893.25,-95.71"/>
<g id="a_node8_213"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="893.25,-348.96 893.25,-368.21 1045.75,-368.21 1045.75,-348.96 893.25,-348.96"/>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-348.96 893.25,-368.21 1045.75,-368.21 1045.75,-348.96 893.25,-348.96"/>
<text text-anchor="start" x="952.25" y="-355.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_214"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-329.71 893.25,-348.96 978.5,-348.96 978.5,-329.71 893.25,-329.71"/>
<text text-anchor="start" x="897.25" y="-335.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node8_215"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-329.71 978.5,-348.96 1045.75,-348.96 1045.75,-329.71 978.5,-329.71"/>
<text text-anchor="start" x="982.5" y="-335.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_216"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-310.46 893.25,-329.71 978.5,-329.71 978.5,-310.46 893.25,-310.46"/>
<text text-anchor="start" x="897.25" y="-316.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node8_217"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-310.46 978.5,-329.71 1045.75,-329.71 1045.75,-310.46 978.5,-310.46"/>
<text text-anchor="start" x="982.5" y="-316.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node8_218"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-291.21 893.25,-310.46 978.5,-310.46 978.5,-291.21 893.25,-291.21"/>
<text text-anchor="start" x="897.25" y="-297.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node8_219"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-291.21 978.5,-310.46 1045.75,-310.46 1045.75,-291.21 978.5,-291.21"/>
<text text-anchor="start" x="982.5" y="-296.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_220"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-271.96 893.25,-291.21 978.5,-291.21 978.5,-271.96 893.25,-271.96"/>
<text text-anchor="start" x="897.25" y="-278.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node8_221"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-271.96 978.5,-291.21 1045.75,-291.21 1045.75,-271.96 978.5,-271.96"/>
<text text-anchor="start" x="982.5" y="-277.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_222"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-251.21 893.25,-271.96 978.5,-271.96 978.5,-251.21 893.25,-251.21"/>
<text text-anchor="start" x="897.25" y="-257.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node8_223"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-251.21 978.5,-271.96 1045.75,-271.96 1045.75,-251.21 978.5,-251.21"/>
<text text-anchor="start" x="982.5" y="-258.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node8_224"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-231.96 893.25,-251.21 978.5,-251.21 978.5,-231.96 893.25,-231.96"/>
<text text-anchor="start" x="897.25" y="-237.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node8_225"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-231.96 978.5,-251.21 1045.75,-251.21 1045.75,-231.96 978.5,-231.96"/>
<text text-anchor="start" x="982.5" y="-237.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_226"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-212.71 893.25,-231.96 978.5,-231.96 978.5,-212.71 893.25,-212.71"/>
<text text-anchor="start" x="897.25" y="-218.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node8_227"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-212.71 978.5,-231.96 1045.75,-231.96 1045.75,-212.71 978.5,-212.71"/>
<text text-anchor="start" x="982.5" y="-218.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_228"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-193.46 893.25,-212.71 978.5,-212.71 978.5,-193.46 893.25,-193.46"/>
<text text-anchor="start" x="897.25" y="-199.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node8_229"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-193.46 978.5,-212.71 1045.75,-212.71 1045.75,-193.46 978.5,-193.46"/>
<text text-anchor="start" x="982.5" y="-199.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_230"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-174.21 893.25,-193.46 978.5,-193.46 978.5,-174.21 893.25,-174.21"/>
<text text-anchor="start" x="897.25" y="-179.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node8_231"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-174.21 978.5,-193.46 1045.75,-193.46 1045.75,-174.21 978.5,-174.21"/>
<text text-anchor="start" x="982.5" y="-179.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_232"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-154.96 893.25,-174.21 978.5,-174.21 978.5,-154.96 893.25,-154.96"/>
<text text-anchor="start" x="897.25" y="-160.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node8_233"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-154.96 978.5,-174.21 1045.75,-174.21 1045.75,-154.96 978.5,-154.96"/>
<text text-anchor="start" x="982.5" y="-160.71" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_234"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-135.71 893.25,-154.96 978.5,-154.96 978.5,-135.71 893.25,-135.71"/>
<text text-anchor="start" x="897.25" y="-141.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node8_235"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-135.71 978.5,-154.96 1045.75,-154.96 1045.75,-135.71 978.5,-135.71"/>
<text text-anchor="start" x="982.5" y="-141.46" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_236"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-116.46 893.25,-135.71 978.5,-135.71 978.5,-116.46 893.25,-116.46"/>
<text text-anchor="start" x="897.25" y="-122.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_237"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-116.46 978.5,-135.71 1045.75,-135.71 1045.75,-116.46 978.5,-116.46"/>
<text text-anchor="start" x="982.5" y="-122.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_238"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-95.71 893.25,-116.46 978.5,-116.46 978.5,-95.71 893.25,-95.71"/>
<text text-anchor="start" x="897.25" y="-102.21" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_239"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-95.71 978.5,-116.46 1045.75,-116.46 1045.75,-95.71 978.5,-95.71"/>
<text text-anchor="start" x="982.5" y="-102.96" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-358.46C854.43,-358.46 862.82,-358.57 885.66,-358.59"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="885.58,-360.69 891.59,-358.59 885.59,-356.49 885.58,-360.69"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-261.59C1247,-261.59 915.53,-704.14 1103.25,-715.37"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.03,-717.47 1109.09,-715.54 1103.15,-713.27 1103.03,-717.47"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-106.09C1188.28,-106.09 1164.57,-292.73 1301.26,-299.29"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.04,-301.38 1307.09,-299.43 1301.14,-297.18 1301.04,-301.38"/>
</g>
</g>
</svg>
</figure>

Ein Klick auf den Kopf eines Abschnitts führt zu seinem Abschnitt weiter unten, ein Klick auf ein Feld zu seiner Zeile in der Feldtabelle; anderswo öffnet sich das Diagramm vergrößert. Als Datei: [inventory-schema.svg](../assets/diagrams/inventory-schema.svg).

## Konventionen

**IDs.** Einträge haben eine ID als Schlüssel: Kleinbuchstaben, Ziffern und Bindestriche, am Anfang ein Buchstabe oder eine Ziffer (`grammi`, `realtox-dus`, `home-private`). Ein Verweisfeld enthält eine solche ID und muss einen vorhandenen Eintrag des richtigen Abschnitts nennen.

**Pflicht und optional.** Ein Feld ist optional, wenn die Tabelle nicht *Pflicht* sagt. Fehlende optionale Felder füllt die abgeleitete Sicht auf – mit dem Standardwert aus der Tabelle, sonst `null` oder `[]` –, damit ein Nutzer der Daten nie `or` schreiben muss.

**Unbekannte Felder sind Fehler.** Ein Tippfehler (`critcality`) wird mit der Liste der bekannten Felder gemeldet, im Editor sofort und in `nix flake check`.

**Eine Richtung.** Jede Beziehung steht dort, wo sie beginnt (`hosts.runsOn`, `services.dependsOn`, `hosts.contracts`); die Gegenrichtung (`guests`, `neededBy`, `covers`) wird abgeleitet.

**Formate.** Strings mit einem Format werden dagegen geprüft:

| Format | Beispiel | Verwendet von |
| --- | --- | --- |
| IPv4-Adresse | `192.0.2.10` | `interfaces.<name>.ipv4.address`, `dhcpPool` |
| IPv4-Präfix (ohne Host-Bits) | `192.0.2.0/24` | `networks.ipv4` |
| IPv6-Präfix | `2001:db8:1::/64` | `networks.ipv6` |
| ULA-/48 (in `fd00::/8`) | `fd12:3456:789a::/48` | `sites.ipv6Ula` |
| MAC-Adresse, Kleinbuchstaben | `52:54:00:12:34:56` | `interfaces.<name>.mac` |
| Link-Local | `eui64`, `stable-privacy`, `random` oder `fe80::1234` | `interfaces.<name>.linkLocal` |
| SSH-Public-Key ohne Kommentar | `ssh-ed25519 AAAAC3Nz…` | `hosts.sshHostKeys` |
| Datum | `2026-10-22` | `contracts.since`, `contracts.renews` |
| Domainname, Kleinbuchstaben | `cloud.example.org` | `services.endpoints[].fqdn` |
| Interface-Name | `eno1`, `eno1.20`, `wlp2s0f0` | Schlüssel von `hosts.interfaces` |

**Geld** steht in ganzen Cent (`899` = 8,99) – keine Kommazahlen, keine Rundung.

**Was das Schema nicht ausdrücken kann.** Ein JSON Schema prüft einen Eintrag für sich. Alles zwischen Einträgen – Verweise, Zyklen, Adressen innerhalb eines Präfixes, ein Vertrag mit dem richtigen Anbieter – prüft nur `inventory.nix`; jeder Abschnitt unten nennt diese Regeln kurz, [Prüfung](inventory.md#prufung) hat sie alle.

## owners { #owners }

Wer ein Gerät administriert – wen man anruft und was geändert werden darf.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="owners-contact"></span>`contact` | String |  | Who to talk to when this owner's devices are affected. |
| <span id="owners-name"></span>`name` | String | Pflicht | Display name. |
| <span id="owners-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  }
}
```

Regel über das Schema hinaus: Jeder Owner hat mindestens einen Host.

## providers { #providers }

Eine Firma oder ein Verein, von dem das Lab abhängt: Provider, Hoster, ein von außen eingekaufter Dienst, der Hackerspace.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="providers-contact"></span>`contact` | String |  | How to reach them (support address, phone, ticket system). |
| <span id="providers-name"></span>`name` | String | Pflicht | Display name of the company or club. |
| <span id="providers-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="providers-url"></span>`url` | String |  | Website or customer portal. |

```json
{
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  }
}
```

Regel über das Schema hinaus: Auf jeden Anbieter verweist etwas – eine Site, ein Anschluss, ein Dienst oder ein Vertrag.

## contracts { #contracts }

Was an einen Anbieter bezahlt wird. Ein Anbieter kann mehrere haben; ein Host, Anschluss oder Dienst nennt die, über die er bezahlt wird.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="contracts-cost"></span>`cost` | Objekt |  | What it costs. Leave it out until known - the contract is then listed in pending. |
| <span id="contracts-cost-amount"></span>`cost.amount` | Ganzzahl ≥ 0 | Pflicht | Amount per period in cents (899 = 8.99) - whole numbers only. |
| <span id="contracts-cost-currency"></span>`cost.currency` | eins von `EUR` `USD` `CHF` `GBP` | Pflicht | Currency of amount. Totals are kept per currency, never converted. |
| <span id="contracts-cost-duemonth"></span>`cost.dueMonth` | Ganzzahl 1–12 |  | Only with period year, and required there: the month (1-12) the yearly amount is charged in. |
| <span id="contracts-cost-period"></span>`cost.period` | eins von `month` `year` `once` | Pflicht | How often amount is charged. |
| <span id="contracts-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="contracts-notice"></span>`notice` | String |  | Notice period, as the contract words it. |
| <span id="contracts-product"></span>`product` | String |  | Product or plan name as the provider calls it. |
| <span id="contracts-provider"></span>`provider` | ID aus [providers](#providers) | Pflicht | Who the contract is with. |
| <span id="contracts-renews"></span>`renews` | String: a date like 2026-10-22 |  | Next date the contract renews or ends unless cancelled. |
| <span id="contracts-since"></span>`since` | String: a date like 2026-10-22 |  | Start of the contract. |

```json
{
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  }
}
```

Regeln über das Schema hinaus: `cost.dueMonth` genau bei `period` `year`; `renews` nicht vor `since`; ein Vertrag, den ein Host, Anschluss oder Dienst nennt, ist mit dessen Anbieter geschlossen (bei einem Host: dem Anbieter seiner Site). Ein Vertrag ohne `cost` steht unter `pending`, einer, den nichts nennt, unter `gaps`.

## uplinks { #uplinks }

Ein Internetanschluss. Alle Felder sind optional, damit ein Anschluss eingetragen werden kann, bevor seine Details bekannt sind.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="uplinks-asn"></span>`asn` | Ganzzahl ≥ 1 |  | Autonomous system number of the provider's network, without the AS prefix. |
| <span id="uplinks-bandwidth"></span>`bandwidth` | Objekt |  | Booked bandwidth in Mbit/s. |
| <span id="uplinks-bandwidth-down"></span>`bandwidth.down` | Ganzzahl ≥ 1 | Pflicht | Downstream in Mbit/s. |
| <span id="uplinks-bandwidth-up"></span>`bandwidth.up` | Ganzzahl ≥ 1 | Pflicht | Upstream in Mbit/s. |
| <span id="uplinks-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="uplinks-ipv4"></span>`ipv4` | eins von `public` `cgnat` `none` |  | What the line gives for IPv4. |
| <span id="uplinks-ipv4static"></span>`ipv4Static` | Boolean |  | Whether the public IPv4 address is fixed. Only meaningful with ipv4 = public. |
| <span id="uplinks-ipv6"></span>`ipv6` | Boolean |  | Whether the line has native IPv6. |
| <span id="uplinks-ipv6prefixlength"></span>`ipv6PrefixLength` | Ganzzahl 1–128 |  | Size of the IPv6 prefix the provider delegates (e.g. 56 for a /56). Only with ipv6. |
| <span id="uplinks-ipv6static"></span>`ipv6Static` | Boolean |  | Whether the delegated IPv6 prefix is fixed. Only with ipv6. |
| <span id="uplinks-medium"></span>`medium` | eins von `fiber` `dsl` `cable` `lte` `satellite` `datacenter` |  | Kind of line. |
| <span id="uplinks-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="uplinks-provider"></span>`provider` | ID aus [providers](#providers) |  | Internet provider (for a data centre: the hoster). |

```json
{
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  }
}
```

Regeln über das Schema hinaus: `ipv6PrefixLength` und `ipv6Static` nur mit `ipv6`; jeder Anschluss gehört zu einer Site; `contracts` sind mit dem `provider` des Anschlusses geschlossen.

## sites { #sites }

Ein Ort, an dem Geräte stehen.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="sites-city"></span>`city` | String | Pflicht | City the site is in. |
| <span id="sites-ipv6ula"></span>`ipv6Ula` | String: a ULA /48 like fd12:3456:789a::/48 |  | Unique local IPv6 prefix of the site (RFC 4193, random 40 bits). Only where the lab runs the network; its networks take their /64 by ipv6SubnetId. |
| <span id="sites-kind"></span>`kind` | eins von `residential` `hackerspace` `club` `datacenter` | Pflicht | Kind of place. club: a club's premises the lab connects to (Remote, issue #84). |
| <span id="sites-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="sites-provider"></span>`provider` | ID aus [providers](#providers) |  | Who runs the place (hoster, club); empty for a home. |
| <span id="sites-uplinks"></span>`uplinks` | Liste von ID aus [uplinks](#uplinks), ohne Duplikate | Pflicht | Internet lines of the site, the primary one first, backups after it. |

```json
{
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ],
      "ipv6Ula": "fd12:3456:789a::/48"
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  }
}
```

Regeln über das Schema hinaus: mindestens ein Anschluss, der primäre zuerst; an jeder Site steht etwas. `ipv6Ula` nur, wo das Lab das Netz selbst betreibt – einmal zufällig erzeugt (RFC 4193), danach nie geändert.

## networks { #networks }

Ein Layer-2-Netz mit seinem IPv4-Präfix.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="networks-dhcppool"></span>`dhcpPool` | Objekt |  | Range the DHCP server hands out dynamically; static addresses must lie outside it. |
| <span id="networks-dhcppool-end"></span>`dhcpPool.end` | String: an IPv4 address | Pflicht | Last address of the pool. |
| <span id="networks-dhcppool-start"></span>`dhcpPool.start` | String: an IPv4 address | Pflicht | First address of the pool. |
| <span id="networks-dhcpserver"></span>`dhcpServer` | ID aus [hosts](#hosts) |  | The host serving DHCP for IPv4 here; it needs an interface in this network. |
| <span id="networks-ipv4"></span>`ipv4` | String: an IPv4 prefix like 192.0.2.0/24 |  | IPv4 prefix. |
| <span id="networks-ipv6"></span>`ipv6` | String: an IPv6 prefix like 2001:db8::/64 |  | IPv6 prefix, when it is fixed (static GUA). A ULA from the site's ipv6Ula is derived, not entered. |
| <span id="networks-ipv6subnetid"></span>`ipv6SubnetId` | Ganzzahl 0–65535 |  | Subnet id of the network, decimal (192, often the VLAN id): its /64 inside the site's ipv6Ula and inside the prefix the primary uplink delegates. The hex form is derived. |
| <span id="networks-name"></span>`name` | String | Pflicht | Display name. |
| <span id="networks-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="networks-site"></span>`site` | ID aus [sites](#sites) | Pflicht | Where the network is. |
| <span id="networks-vlan"></span>`vlan` | Ganzzahl 1–4094 |  | 802.1Q VLAN id. Leave out for an untagged network. |

```json
{
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "vlan": 192,
      "ipv6": "2001:db8:1::/64",
      "ipv6SubnetId": 192,
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  }
}
```

Regeln über das Schema hinaus: Das Präfix hat keine Host-Bits; der Pool liegt darin, Start vor Ende, und braucht `ipv4` und `dhcpServer`; der DHCP-Server steht an der Site und hat ein Interface im Netz; eine VLAN-ID nur einmal pro Site; `ipv6SubnetId` nur einmal pro Site und klein genug für das Präfix, das der primäre Anschluss delegiert (0–255 bei einem /56). Sie ist dezimal; die abgeleitete Sicht ergänzt `ipv6SubnetHex` und das ULA-`/64` des Netzes.

## hosts { #hosts }

Jedes Gerät mit einer Adresse, die zählt – von diesem Flake verwaltet oder nicht.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="hosts-availability"></span>`availability` | eins von `always-on` `intermittent` | Standard `"always-on"` | intermittent: being offline is normal (a laptop) and is not an incident. |
| <span id="hosts-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="hosts-criticality"></span>`criticality` | eins von `core` `service` `lab` | Standard `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="hosts-description"></span>`description` | String |  | One short line (about 45 characters at most): what the device is for. Shown next to the host name in shell completion; anything longer goes in note. |
| <span id="hosts-inside"></span>`inside` | ID aus [hosts](#hosts) |  | Physically built into another device, e.g. a PCIe KVM card in its host. |
| <span id="hosts-interfaces"></span>`interfaces` | Objekt: Name → Objekt |  | Network interfaces by name (as the OS calls them; for an appliance any label like lan/wan). A VLAN interface (eno1.10) is an entry of its own. |
| <span id="hosts-interfaces-name-connector"></span>`interfaces.<name>.connector` | eins von `qsfp-plus` `qsfp28` `rj45` `sfp` `sfp-plus` `sfp28` |  | Only ethernet: the port - rj45 or an SFP/QSFP cage. |
| <span id="hosts-interfaces-name-dhcpv6duid"></span>`interfaces.<name>.dhcpv6Duid` | String: the DUID in lower-case hex, no separators |  | Only where the DHCPv6 client's DUID carries no MAC (type 4, DUID-UUID, as Home Assistant OS sends it): the DUID itself, so the router's reservation finds the host by it. Changes with a reinstall. |
| <span id="hosts-interfaces-name-ipv4"></span>`interfaces.<name>.ipv4` | Objekt |  | IPv4 addressing of this interface in its network. |
| <span id="hosts-interfaces-name-ipv4-address"></span>`interfaces.<name>.ipv4.address` | String: an IPv4 address |  | The address - required for reserved and static. |
| <span id="hosts-interfaces-name-ipv4-mode"></span>`interfaces.<name>.ipv4.mode` | eins von `reserved` `static` `dhcp` | Pflicht | reserved: fixed DHCP lease by MAC; static: configured on the device; dhcp: dynamic. |
| <span id="hosts-interfaces-name-linklocal"></span>`interfaces.<name>.linkLocal` | String: eui64, stable-privacy, random or an fe80:: address |  | How the IPv6 link-local address is formed: eui64 (computed from mac), stable-privacy (RFC 7217), random - or the fixed fe80:: address itself. |
| <span id="hosts-interfaces-name-mac"></span>`interfaces.<name>.mac` | String: a lower-case MAC address like aa:bb:cc:dd:ee:ff |  | Hardware address, lower case. |
| <span id="hosts-interfaces-name-maclocal"></span>`interfaces.<name>.macLocal` | Boolean |  | The mac is locally administered on purpose and expected to stay: a provider's VM NIC, or a device that ships with one. Required for such a mac, wrong for any other. Not for a private (random) Wi-Fi address, which does not belong in here at all. |
| <span id="hosts-interfaces-name-medium"></span>`interfaces.<name>.medium` | eins von `ethernet` `wifi` |  | Physical medium. |
| <span id="hosts-interfaces-name-module"></span>`interfaces.<name>.module` | Objekt |  | Only a cage (not rj45): what is plugged into it. |
| <span id="hosts-interfaces-name-module-kind"></span>`interfaces.<name>.module.kind` | eins von `dac` `aoc` `sm` `mm` `copper` | Pflicht | dac/aoc: a fixed cable; sm/mm: a transceiver for singlemode/multimode fibre; copper: an RJ45 transceiver. |
| <span id="hosts-interfaces-name-module-standard"></span>`interfaces.<name>.module.standard` | eins von `1000base-bx` `1000base-lx` `1000base-sx` `1000base-t` `10gbase-bx` `10gbase-er` `10gbase-lr` `10gbase-lrm` `10gbase-sr` `10gbase-t` `2.5gbase-t` `25gbase-lr` `25gbase-sr` |  | Only a transceiver (not dac/aoc): the standard printed on it, e.g. 10gbase-sr. |
| <span id="hosts-interfaces-name-network"></span>`interfaces.<name>.network` | ID aus [networks](#networks) |  | The network this interface is in. |
| <span id="hosts-interfaces-name-note"></span>`interfaces.<name>.note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-interfaces-name-speed"></span>`interfaces.<name>.speed` | eins von `10` `100` `1000` `2500` `5000` `10000` `25000` `40000` `100000` |  | Only ethernet: the most this interface can do, in Mbit/s (2500 = 2.5G) - with what sits in its cage, not what the link partner negotiates. |
| <span id="hosts-interfaces-name-wifistandard"></span>`interfaces.<name>.wifiStandard` | eins von `wifi4` `wifi5` `wifi6` `wifi6e` `wifi7` |  | Only wifi: the newest Wi-Fi generation the interface supports. |
| <span id="hosts-kind"></span>`kind` | eins von `server` `hypervisor` `vm` `container` `router` `switch` `ap` `pdu` `ups` `kvm` `nas` `workstation` `laptop` `phone` `tablet` `watch` `appliance` | Pflicht | What the device is. |
| <span id="hosts-managed"></span>`managed` | Boolean | Pflicht | Configured by this flake (nixosConfigurations/darwinConfigurations). Must match the flake. |
| <span id="hosts-manages"></span>`manages` | Liste von ID aus [hosts](#hosts), ohne Duplikate |  | Only kvm: the machines this KVM gives out-of-band access to. |
| <span id="hosts-model"></span>`model` | String |  | Hardware model without the vendor (ThinkCentre M720q), or for a VM the provider's product or plan name. |
| <span id="hosts-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-owner"></span>`owner` | ID aus [owners](#owners) | Pflicht | Who administers the device. |
| <span id="hosts-power"></span>`power` | ID aus [hosts](#hosts) |  | Where the power comes from: a PDU/UPS, a PoE switch, or the host a card sits in. |
| <span id="hosts-productid"></span>`productId` | String |  | The vendor's product id for drivers and firmware: Lenovo machine type (10T7...), Apple model identifier (Mac16,10). Not for vm/container. |
| <span id="hosts-runson"></span>`runsOn` | ID aus [hosts](#hosts) |  | Only vm/container: the machine it runs on. Optional - a rented VM's host is not in the inventory. |
| <span id="hosts-serial"></span>`serial` | String |  | Serial number. Unique lab-wide. Not for vm/container. |
| <span id="hosts-site"></span>`site` | ID aus [sites](#sites) |  | Where the device is. Optional for entries with runsOn or inside - they inherit it. |
| <span id="hosts-sshhostkeys"></span>`sshHostKeys` | Liste von String: an OpenSSH public key "<type> <base64>" without comment, ohne Duplikate |  | The device's SSH host public keys (/etc/ssh/ssh_host_*_key.pub without the comment). Feeds known_hosts and the sops check. |
| <span id="hosts-unlock"></span>`unlock` | Objekt |  | Disk unlock after a reboot. Leave it out for an unencrypted disk. |
| <span id="hosts-unlock-fallback"></span>`unlock.fallback` | eins von `remote-ssh` `console` |  | How a human unlocks when the methods fail: over SSH (initrd, FileVault) or at the console/KVM. |
| <span id="hosts-unlock-methods"></span>`unlock.methods` | Liste von eins von `tpm` `nbde`, ohne Duplikate | Pflicht | Automatic unlock methods. Empty when only a human can unlock. |
| <span id="hosts-unlock-tang"></span>`unlock.tang` | Liste von ID aus [hosts](#hosts), ohne Duplikate |  | Tang servers for nbde; any one of them is enough. |
| <span id="hosts-unlock-threshold"></span>`unlock.threshold` | Ganzzahl ≥ 1 | Standard `1` | How many of the methods must succeed (Clevis sss threshold). Defaults to 1. |
| <span id="hosts-vendor"></span>`vendor` | String |  | Hardware manufacturer (Lenovo, Apple, GL.iNet). Not for vm/container. |

```json
{
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "macLocal": true,
          "medium": "ethernet",
          "speed": 10000,
          "connector": "sfp-plus",
          "module": {
            "kind": "mm",
            "standard": "10gbase-sr"
          },
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "macLocal": true,
          "medium": "wifi",
          "wifiStandard": "wifi6",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  }
}
```

Regeln über das Schema hinaus (die wichtigsten – [Prüfung](inventory.md#prufung) hat alle):

- `site` ist Pflicht, außer sie lässt sich entlang `runsOn` oder `inside` erben, und eine angegebene stimmt mit der geerbten überein.
- `runsOn` nur bei `vm`/`container`, auf einer erlaubten Geräteart; `manages` nur bei `kvm`; `vendor`/`productId`/`serial` nicht bei `vm`/`container`.
- `runsOn`, `inside` und `power` ohne Zyklen; jeder Host mit `nbde` erreicht einen Tang-Server, der ohne Menschen hochkommt.
- `managed` stimmt in beide Richtungen mit `flake.nix` überein.
- Adressen: innerhalb des Präfixes des Netzes, passend zum Modus (`reserved` braucht `mac` und einen DHCP-Server, `static` liegt außerhalb des Pools), jede nur einmal pro Netz; MACs und Host-Keys nur einmal im ganzen Lab.

## services { #services }

Was die Hosts betreiben und was von außen eingekauft ist.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="services-backup"></span>`backup` | Liste von Objekt, ohne Duplikate |  | How its data is backed up. Only for stateful. |
| <span id="services-backup-interval"></span>`backup[].interval` | eins von `hourly` `daily` `weekly` `monthly` |  | How often it runs. |
| <span id="services-backup-keep"></span>`backup[].keep` | Objekt |  | Which versions are kept - at the target, or on the machine without to. Left out: unknown. |
| <span id="services-backup-keep-all"></span>`backup[].keep.all` | Boolean |  | Only true, and only alone: every version is kept, nothing is ever pruned. |
| <span id="services-backup-keep-daily"></span>`backup[].keep.daily` | Ganzzahl ≥ 1 |  | One per day for the last n days. |
| <span id="services-backup-keep-last"></span>`backup[].keep.last` | Ganzzahl ≥ 1 |  | The newest n versions. |
| <span id="services-backup-keep-monthly"></span>`backup[].keep.monthly` | Ganzzahl ≥ 1 |  | One per month for the last n months. |
| <span id="services-backup-keep-weekly"></span>`backup[].keep.weekly` | Ganzzahl ≥ 1 |  | One per week for the last n weeks. |
| <span id="services-backup-method"></span>`backup[].method` | eins von `restic` `arq` `btrbk` `pgdump` `provider-snapshot` `ha-backup` | Pflicht | restic/arq copy to another service (to); btrbk, pgdump and provider-snapshot stay on the same machine or provider; ha-backup (Home Assistant's own backup) stays on the machine without to, or goes to an upload target with to. |
| <span id="services-backup-note"></span>`backup[].note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-backup-to"></span>`backup[].to` | ID aus [services](#services) |  | The service the copy goes to - required with restic/arq, optional with ha-backup. |
| <span id="services-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="services-criticality"></span>`criticality` | eins von `core` `service` `lab` | Standard `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="services-data"></span>`data` | eins von `stateful` `stateless` | Pflicht | stateful: it keeps data that is lost with it; stateless: it can be rebuilt from the repository. |
| <span id="services-dependson"></span>`dependsOn` | Liste von ID aus [services](#services), ohne Duplikate |  | Services it cannot work without. |
| <span id="services-endpoints"></span>`endpoints` | Liste von Objekt, ohne Duplikate |  | How the service is reached. |
| <span id="services-endpoints-exposure"></span>`endpoints[].exposure` | eins von `public` `proxy` `mesh` `lan` `loopback` | Pflicht | public: open on the internet from its own host; proxy: through a reverse proxy (name it in via); mesh: only inside the overlay network; lan: only in a local network; loopback: only on the host itself. |
| <span id="services-endpoints-fqdn"></span>`endpoints[].fqdn` | String: a lower-case domain name like cloud.example.org | Pflicht | Name it is reached by. |
| <span id="services-endpoints-note"></span>`endpoints[].note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-endpoints-port"></span>`endpoints[].port` | Ganzzahl 1–65535 |  | Port, when it is not the protocol's default. |
| <span id="services-endpoints-via"></span>`endpoints[].via` | ID aus [services](#services) |  | The service it is reached through - the reverse proxy for exposure proxy (required there). Counts as a dependency. |
| <span id="services-hosts"></span>`hosts` | Liste von ID aus [hosts](#hosts), ohne Duplikate |  | The machines it runs on. Exactly one of hosts and provider. |
| <span id="services-name"></span>`name` | String | Pflicht | Display name. |
| <span id="services-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-package"></span>`package` | String |  | Only on managed hosts: option path of the package in the host's configuration (services.paperless.package) - version, license and language are read from there. |
| <span id="services-provider"></span>`provider` | ID aus [providers](#providers) |  | For a service bought from outside: who runs it. Exactly one of hosts and provider. |
| <span id="services-software"></span>`software` | String |  | The software it is (Paperless-ngx, Garage) - the version comes from package or version. |
| <span id="services-uses"></span>`uses` | Liste von ID aus [services](#services), ohne Duplikate |  | Services it works without, but degraded (new logins fail, one feature is missing). |
| <span id="services-version"></span>`version` | String |  | Version, by hand - only where there is no package to read it from. |

```json
{
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

Regeln über das Schema hinaus: genau eins von `hosts` und `provider`; `package` nur auf verwalteten Hosts und nicht zusammen mit `version`; kein `core`/`service`-Dienst auf einem `intermittent`-Host; keine harte Abhängigkeit (`dependsOn`, `via`) von einem weniger kritischen Dienst und keine im Kreis; `via` Pflicht bei `exposure` `proxy`; jeder `fqdn` nur einmal; `backup` nur bei `stateful`, `to` genau bei `restic`/`arq`. Ein `stateful`-Dienst, dessen Backups alle auf den eigenen Hosts bleiben – `storage` oben –, steht unter `gaps`.

## Ein vollständiges Beispiel

Ein gültiges Inventar mit allen Abschnitten – die Quelle der Beispiele oben, `docs/inventory-example.json`. Zum Kopieren als Anfang; `"$schema": "./inventory.schema.json"` ganz oben gibt dem Editor seine Vervollständigung.

```json
{
  "owners": {
    "lab": {
      "name": "Example lab",
      "contact": "admin@example.org"
    },
    "club": {
      "name": "Example hackerspace",
      "note": "Root on their hypervisor is root on our VM there."
    }
  },
  "providers": {
    "isp": {
      "name": "Example ISP",
      "url": "https://isp.example"
    },
    "hoster": {
      "name": "Example Hosting",
      "url": "https://hosting.example",
      "contact": "support@hosting.example"
    },
    "club": {
      "name": "Example hackerspace"
    },
    "mailco": {
      "name": "Example Mail"
    }
  },
  "contracts": {
    "fiber": {
      "provider": "isp",
      "product": "Fiber 600",
      "cost": {
        "amount": 4995,
        "currency": "EUR",
        "period": "month"
      },
      "since": "2024-05-01",
      "notice": "1 month"
    },
    "vps": {
      "provider": "hoster",
      "product": "VPS M",
      "cost": {
        "amount": 12000,
        "currency": "EUR",
        "period": "year",
        "dueMonth": 3
      },
      "since": "2025-03-01",
      "renews": "2027-03-01"
    },
    "vps-ipv4": {
      "provider": "hoster",
      "product": "Additional IPv4",
      "cost": {
        "amount": 150,
        "currency": "EUR",
        "period": "month"
      }
    },
    "mail": {
      "provider": "mailco",
      "cost": {
        "amount": 3000,
        "currency": "USD",
        "period": "year",
        "dueMonth": 11
      }
    }
  },
  "uplinks": {
    "home-fiber": {
      "provider": "isp",
      "contracts": [
        "fiber"
      ],
      "asn": 64496,
      "medium": "fiber",
      "bandwidth": {
        "down": 600,
        "up": 300
      },
      "ipv4": "public",
      "ipv4Static": false,
      "ipv6": true,
      "ipv6PrefixLength": 56,
      "ipv6Static": false
    },
    "home-lte": {
      "medium": "lte",
      "ipv4": "cgnat",
      "note": "Backup line, USB stick on the router."
    },
    "club-line": {
      "medium": "cable",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    },
    "dc": {
      "provider": "hoster",
      "asn": 64497,
      "medium": "datacenter",
      "ipv4": "public",
      "ipv4Static": true,
      "ipv6": true
    }
  },
  "sites": {
    "home": {
      "city": "Exampletown",
      "kind": "residential",
      "uplinks": [
        "home-fiber",
        "home-lte"
      ],
      "ipv6Ula": "fd12:3456:789a::/48"
    },
    "club": {
      "city": "Exampletown",
      "kind": "hackerspace",
      "provider": "club",
      "uplinks": [
        "club-line"
      ]
    },
    "dc": {
      "city": "Exampleburg",
      "kind": "datacenter",
      "provider": "hoster",
      "uplinks": [
        "dc"
      ]
    }
  },
  "networks": {
    "lan": {
      "name": "Home LAN",
      "site": "home",
      "ipv4": "192.0.2.0/24",
      "vlan": 192,
      "ipv6": "2001:db8:1::/64",
      "ipv6SubnetId": 192,
      "dhcpServer": "router",
      "dhcpPool": {
        "start": "192.0.2.100",
        "end": "192.0.2.199"
      }
    },
    "club-v10": {
      "name": "Hackerspace LAN",
      "site": "club",
      "vlan": 10,
      "ipv4": "198.51.100.0/24"
    }
  },
  "hosts": {
    "router": {
      "kind": "router",
      "vendor": "Example Networks",
      "model": "R1",
      "site": "home",
      "owner": "lab",
      "managed": false,
      "criticality": "core",
      "interfaces": {
        "lan": {
          "network": "lan",
          "ipv4": {
            "mode": "static",
            "address": "192.0.2.1"
          }
        }
      }
    },
    "nas": {
      "kind": "nas",
      "vendor": "Example Corp",
      "model": "NAS 4",
      "productId": "EX-1000",
      "serial": "NAS0001",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "tpm"
        ],
        "fallback": "console"
      },
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINasNasNasNasNasNasNasNasNasNasNasNasNas"
      ],
      "interfaces": {
        "eno1": {
          "mac": "52:54:00:12:34:56",
          "macLocal": true,
          "medium": "ethernet",
          "speed": 10000,
          "connector": "sfp-plus",
          "module": {
            "kind": "mm",
            "standard": "10gbase-sr"
          },
          "linkLocal": "eui64",
          "network": "lan",
          "ipv4": {
            "mode": "reserved",
            "address": "192.0.2.10"
          }
        }
      }
    },
    "kvm": {
      "kind": "kvm",
      "inside": "nas",
      "power": "nas",
      "manages": [
        "nas"
      ],
      "owner": "lab",
      "managed": false,
      "criticality": "lab"
    },
    "laptop": {
      "kind": "laptop",
      "vendor": "Example Corp",
      "model": "Book 14",
      "site": "home",
      "owner": "lab",
      "managed": true,
      "criticality": "lab",
      "availability": "intermittent",
      "unlock": {
        "methods": [],
        "fallback": "console"
      },
      "interfaces": {
        "wlan0": {
          "mac": "aa:bb:cc:dd:ee:02",
          "macLocal": true,
          "medium": "wifi",
          "wifiStandard": "wifi6",
          "linkLocal": "stable-privacy",
          "network": "lan",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "pve": {
      "kind": "hypervisor",
      "site": "club",
      "owner": "club",
      "managed": false,
      "interfaces": {
        "vmbr0": {
          "network": "club-v10",
          "ipv4": {
            "mode": "static",
            "address": "198.51.100.2"
          }
        }
      }
    },
    "club-vm": {
      "kind": "vm",
      "model": "Proxmox VM",
      "runsOn": "pve",
      "owner": "lab",
      "managed": true,
      "unlock": {
        "methods": [
          "nbde"
        ],
        "tang": [
          "nas"
        ],
        "fallback": "remote-ssh"
      },
      "interfaces": {
        "ens18": {
          "mac": "bc:24:11:aa:bb:cc",
          "medium": "ethernet",
          "network": "club-v10",
          "ipv4": {
            "mode": "dhcp"
          }
        }
      }
    },
    "vps": {
      "kind": "vm",
      "model": "VPS M",
      "site": "dc",
      "owner": "lab",
      "managed": true,
      "criticality": "core",
      "contracts": [
        "vps",
        "vps-ipv4"
      ],
      "sshHostKeys": [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVpsVps"
      ]
    }
  },
  "services": {
    "login": {
      "name": "Login",
      "software": "Example IdP",
      "hosts": [
        "vps"
      ],
      "package": "services.example-idp.package",
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "auth.example.org",
          "exposure": "public"
        }
      ],
      "uses": [
        "mail"
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "restic",
          "to": "storage",
          "note": "Bucket vps-backups."
        }
      ]
    },
    "proxy": {
      "name": "Reverse proxy",
      "hosts": [
        "vps"
      ],
      "criticality": "core",
      "endpoints": [
        {
          "fqdn": "proxy.example.org",
          "exposure": "public"
        }
      ],
      "data": "stateless"
    },
    "storage": {
      "name": "S3 storage",
      "software": "Example S3",
      "hosts": [
        "nas"
      ],
      "endpoints": [
        {
          "fqdn": "s3.example.org",
          "exposure": "lan",
          "port": 3900
        },
        {
          "fqdn": "s3-console.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "btrbk",
          "note": "Hourly snapshots on the same disk."
        }
      ]
    },
    "docs": {
      "name": "Documents",
      "hosts": [
        "club-vm"
      ],
      "dependsOn": [
        "login"
      ],
      "endpoints": [
        {
          "fqdn": "docs.example.org",
          "exposure": "proxy",
          "via": "proxy"
        }
      ],
      "data": "stateful",
      "backup": [
        {
          "method": "pgdump"
        },
        {
          "method": "restic",
          "to": "storage"
        }
      ]
    },
    "route": {
      "name": "Route into the hackerspace",
      "software": "Overlay routing peer",
      "hosts": [
        "club-vm"
      ],
      "data": "stateless"
    },
    "mail": {
      "name": "Mail",
      "provider": "mailco",
      "contracts": [
        "mail"
      ],
      "data": "stateful"
    }
  }
}
```

Was `just inventory` daraus ableitet, zum Beispiel: `hosts.club-vm.site` ist `club` (geerbt von `pve`); `services.docs.upstreamHosts` ist `club-vm`, `pve`, `vps`; `providers.hoster.affects` ist `docs`, `login`, `proxy`; `costs.monthly` ist `{"EUR": 6145, "USD": 250}`, und in `costs.byMonth` trägt der November die 30,00 USD des Mail-Vertrags.

## Im Editor

`inventory.json` beginnt mit `"$schema": "./inventory.schema.json"`. Editoren, die JSON Schema lesen (VS Code, Zed, IntelliJ, Neovim mit einem JSON-Language-Server), bieten dann die Felder zur Vervollständigung an, zeigen die Beschreibungen aus den Tabellen oben beim Überfahren und unterstreichen falsche Typen, unbekannte Felder und fehlerhafte Werte schon beim Tippen. Verweise und alle Regeln zwischen Einträgen prüft erst `nix flake check` (oder `just inventory-test`).

Nach einer Änderung an `spec` in `inventory.nix`: `just inventory-schema` und `just inventory-diagram`, ein Testfall in `tests/inventory.nix` und – wenn das Beispiel das neue Feld zeigen soll – `docs/inventory-example.json`. Die Checks schlagen fehl, bis alles zusammenpasst.
