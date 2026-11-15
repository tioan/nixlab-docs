# Inventar-Schema

`inventory.json` folgt einem festen Format: neun Abschnitte, jeder ein Objekt aus Einträgen mit ID als Schlüssel, jedes Feld mit einem Typ, manche davon Verweise in einen anderen Abschnitt. Diese Seite ist die vollständige Referenz dieses Formats – jedes Feld mit Typ, ob es Pflicht ist, seinem Standardwert und seiner Bedeutung, ein Beispiel pro Abschnitt und ein ganzes Beispiel-Inventar. *Wozu* das Inventar da ist, wie es geprüft wird und was daraus abgeleitet wird, steht unter [Inventar](inventory.md).

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
 viewBox="0.00 0.00 1389.00 1291.81" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 1287.81)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1243.75,-735.31 1110.75,-735.31 1110.75,-502.81 1243.75,-502.81 1243.75,-735.31"/>
<polygon fill="#f1efe8" stroke="none" points="1110.75,-502.81 1110.75,-735.31 1243.75,-735.31 1243.75,-502.81 1110.75,-502.81"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1110.75,-716.06 1110.75,-735.31 1243.75,-735.31 1243.75,-716.06 1110.75,-716.06"/>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-716.06 1110.75,-735.31 1243.75,-735.31 1243.75,-716.06 1110.75,-716.06"/>
<text text-anchor="start" x="1155.88" y="-722.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-696.81 1110.75,-716.06 1183.25,-716.06 1183.25,-696.81 1110.75,-696.81"/>
<text text-anchor="start" x="1114.75" y="-702.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-696.81 1183.25,-716.06 1243.75,-716.06 1243.75,-696.81 1183.25,-696.81"/>
<text text-anchor="start" x="1187.25" y="-702.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-677.56 1110.75,-696.81 1183.25,-696.81 1183.25,-677.56 1110.75,-677.56"/>
<text text-anchor="start" x="1114.75" y="-684.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-677.56 1183.25,-696.81 1243.75,-696.81 1243.75,-677.56 1183.25,-677.56"/>
<text text-anchor="start" x="1187.25" y="-683.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-658.31 1110.75,-677.56 1183.25,-677.56 1183.25,-658.31 1110.75,-658.31"/>
<text text-anchor="start" x="1114.75" y="-665.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-658.31 1183.25,-677.56 1243.75,-677.56 1243.75,-658.31 1183.25,-658.31"/>
<text text-anchor="start" x="1187.25" y="-664.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-639.06 1110.75,-658.31 1183.25,-658.31 1183.25,-639.06 1110.75,-639.06"/>
<text text-anchor="start" x="1114.75" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-639.06 1183.25,-658.31 1243.75,-658.31 1243.75,-639.06 1183.25,-639.06"/>
<text text-anchor="start" x="1187.25" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-619.81 1110.75,-639.06 1183.25,-639.06 1183.25,-619.81 1110.75,-619.81"/>
<text text-anchor="start" x="1114.75" y="-626.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-619.81 1183.25,-639.06 1243.75,-639.06 1243.75,-619.81 1183.25,-619.81"/>
<text text-anchor="start" x="1187.25" y="-625.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-600.56 1110.75,-619.81 1183.25,-619.81 1183.25,-600.56 1110.75,-600.56"/>
<text text-anchor="start" x="1114.75" y="-606.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-600.56 1183.25,-619.81 1243.75,-619.81 1243.75,-600.56 1183.25,-600.56"/>
<text text-anchor="start" x="1187.25" y="-606.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-581.31 1110.75,-600.56 1183.25,-600.56 1183.25,-581.31 1110.75,-581.31"/>
<text text-anchor="start" x="1114.75" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-581.31 1183.25,-600.56 1243.75,-600.56 1243.75,-581.31 1183.25,-581.31"/>
<text text-anchor="start" x="1187.25" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-562.06 1110.75,-581.31 1183.25,-581.31 1183.25,-562.06 1110.75,-562.06"/>
<text text-anchor="start" x="1114.75" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-562.06 1183.25,-581.31 1243.75,-581.31 1243.75,-562.06 1183.25,-562.06"/>
<text text-anchor="start" x="1187.25" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-541.31 1110.75,-562.06 1183.25,-562.06 1183.25,-541.31 1110.75,-541.31"/>
<text text-anchor="start" x="1114.75" y="-548.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-541.31 1183.25,-562.06 1243.75,-562.06 1243.75,-541.31 1183.25,-541.31"/>
<text text-anchor="start" x="1187.25" y="-548.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-522.06 1110.75,-541.31 1183.25,-541.31 1183.25,-522.06 1110.75,-522.06"/>
<text text-anchor="start" x="1114.75" y="-527.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-522.06 1183.25,-541.31 1243.75,-541.31 1243.75,-522.06 1183.25,-522.06"/>
<text text-anchor="start" x="1187.25" y="-527.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-502.81 1110.75,-522.06 1183.25,-522.06 1183.25,-502.81 1110.75,-502.81"/>
<text text-anchor="start" x="1114.75" y="-508.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-502.81 1183.25,-522.06 1243.75,-522.06 1243.75,-502.81 1183.25,-502.81"/>
<text text-anchor="start" x="1187.25" y="-508.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node6" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1381,-309.18 1308.75,-309.18 1308.75,-212.93 1381,-212.93 1381,-309.18"/>
<polygon fill="#f1efe8" stroke="none" points="1308.75,-212.93 1308.75,-309.18 1381,-309.18 1381,-212.93 1308.75,-212.93"/>
<g id="a_node6_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1308.75,-289.93 1308.75,-309.18 1381,-309.18 1381,-289.93 1308.75,-289.93"/>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-289.93 1308.75,-309.18 1381,-309.18 1381,-289.93 1308.75,-289.93"/>
<text text-anchor="start" x="1322.75" y="-296.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node6_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-270.68 1308.75,-289.93 1349,-289.93 1349,-270.68 1308.75,-270.68"/>
<text text-anchor="start" x="1312.75" y="-276.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node6_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-270.68 1349,-289.93 1381,-289.93 1381,-270.68 1349,-270.68"/>
<text text-anchor="start" x="1353" y="-276.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-251.43 1308.75,-270.68 1349,-270.68 1349,-251.43 1308.75,-251.43"/>
<text text-anchor="start" x="1312.75" y="-258.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-251.43 1349,-270.68 1381,-270.68 1381,-251.43 1349,-251.43"/>
<text text-anchor="start" x="1353" y="-257.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-232.18 1308.75,-251.43 1349,-251.43 1349,-232.18 1308.75,-232.18"/>
<text text-anchor="start" x="1312.75" y="-237.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-232.18 1349,-251.43 1381,-251.43 1381,-232.18 1349,-232.18"/>
<text text-anchor="start" x="1353" y="-237.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-212.93 1308.75,-232.18 1349,-232.18 1349,-212.93 1308.75,-212.93"/>
<text text-anchor="start" x="1312.75" y="-218.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node6_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-212.93 1349,-232.18 1381,-232.18 1381,-212.93 1349,-212.93"/>
<text text-anchor="start" x="1353" y="-218.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1243.75,-551.68C1356.87,-551.68 1200.36,-310.75 1301.37,-299.93"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.2,-302.04 1307.09,-299.64 1300.99,-297.85 1301.2,-302.04"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="474.25,-869.43 239.25,-869.43 239.25,-66.68 474.25,-66.68 474.25,-869.43"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-66.68 239.25,-869.43 474.25,-869.43 474.25,-66.68 239.25,-66.68"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-850.18 239.25,-869.43 474.25,-869.43 474.25,-850.18 239.25,-850.18"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-850.18 239.25,-869.43 474.25,-869.43 474.25,-850.18 239.25,-850.18"/>
<text text-anchor="start" x="344" y="-856.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-830.93 239.25,-850.18 404,-850.18 404,-830.93 239.25,-830.93"/>
<text text-anchor="start" x="243.25" y="-836.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-830.93 404,-850.18 474.25,-850.18 474.25,-830.93 404,-830.93"/>
<text text-anchor="start" x="408" y="-836.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-810.18 239.25,-830.93 404,-830.93 404,-810.18 239.25,-810.18"/>
<text text-anchor="start" x="243.25" y="-816.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-810.18 404,-830.93 474.25,-830.93 474.25,-810.18 404,-810.18"/>
<text text-anchor="start" x="408" y="-817.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-790.93 239.25,-810.18 404,-810.18 404,-790.93 239.25,-790.93"/>
<text text-anchor="start" x="243.25" y="-796.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-790.93 404,-810.18 474.25,-810.18 474.25,-790.93 404,-790.93"/>
<text text-anchor="start" x="408" y="-796.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-description" tabindex="0" role="link"><title>hosts.description</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-771.68 239.25,-790.93 404,-790.93 404,-771.68 239.25,-771.68"/>
<text text-anchor="start" x="243.25" y="-777.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">description</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-description" tabindex="0" role="link"><title>hosts.description</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-771.68 404,-790.93 474.25,-790.93 474.25,-771.68 404,-771.68"/>
<text text-anchor="start" x="408" y="-777.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-750.93 239.25,-771.68 404,-771.68 404,-750.93 239.25,-750.93"/>
<text text-anchor="start" x="243.25" y="-757.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-750.93 404,-771.68 474.25,-771.68 474.25,-750.93 404,-750.93"/>
<text text-anchor="start" x="408" y="-758.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-731.68 239.25,-750.93 404,-750.93 404,-731.68 239.25,-731.68"/>
<text text-anchor="start" x="243.25" y="-737.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-731.68 404,-750.93 474.25,-750.93 474.25,-731.68 404,-731.68"/>
<text text-anchor="start" x="408" y="-737.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-712.43 239.25,-731.68 404,-731.68 404,-712.43 239.25,-712.43"/>
<text text-anchor="start" x="243.25" y="-718.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.connector</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-712.43 404,-731.68 474.25,-731.68 474.25,-712.43 404,-712.43"/>
<text text-anchor="start" x="408" y="-718.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-dhcpv6duid" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.dhcpv6Duid</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-693.18 239.25,-712.43 404,-712.43 404,-693.18 239.25,-693.18"/>
<text text-anchor="start" x="243.25" y="-698.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.dhcpv6Duid</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-dhcpv6duid" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.dhcpv6Duid</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-693.18 404,-712.43 474.25,-712.43 474.25,-693.18 404,-693.18"/>
<text text-anchor="start" x="408" y="-698.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-673.93 239.25,-693.18 404,-693.18 404,-673.93 239.25,-673.93"/>
<text text-anchor="start" x="243.25" y="-679.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-673.93 404,-693.18 474.25,-693.18 474.25,-673.93 404,-673.93"/>
<text text-anchor="start" x="408" y="-679.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-654.68 239.25,-673.93 404,-673.93 404,-654.68 239.25,-654.68"/>
<text text-anchor="start" x="243.25" y="-660.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-654.68 404,-673.93 474.25,-673.93 474.25,-654.68 404,-654.68"/>
<text text-anchor="start" x="408" y="-660.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-635.43 239.25,-654.68 404,-654.68 404,-635.43 239.25,-635.43"/>
<text text-anchor="start" x="243.25" y="-642.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-635.43 404,-654.68 474.25,-654.68 474.25,-635.43 404,-635.43"/>
<text text-anchor="start" x="408" y="-641.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-616.18 239.25,-635.43 404,-635.43 404,-616.18 239.25,-616.18"/>
<text text-anchor="start" x="243.25" y="-621.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-616.18 404,-635.43 474.25,-635.43 474.25,-616.18 404,-616.18"/>
<text text-anchor="start" x="408" y="-621.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-596.93 239.25,-616.18 404,-616.18 404,-596.93 239.25,-596.93"/>
<text text-anchor="start" x="243.25" y="-602.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-596.93 404,-616.18 474.25,-616.18 474.25,-596.93 404,-596.93"/>
<text text-anchor="start" x="408" y="-602.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-577.68 239.25,-596.93 404,-596.93 404,-577.68 239.25,-577.68"/>
<text text-anchor="start" x="243.25" y="-583.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.macLocal</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-577.68 404,-596.93 474.25,-596.93 474.25,-577.68 404,-577.68"/>
<text text-anchor="start" x="408" y="-583.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-558.43 239.25,-577.68 404,-577.68 404,-558.43 239.25,-558.43"/>
<text text-anchor="start" x="243.25" y="-564.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-558.43 404,-577.68 474.25,-577.68 474.25,-558.43 404,-558.43"/>
<text text-anchor="start" x="408" y="-564.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-539.18 239.25,-558.43 404,-558.43 404,-539.18 239.25,-539.18"/>
<text text-anchor="start" x="243.25" y="-544.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-539.18 404,-558.43 474.25,-558.43 474.25,-539.18 404,-539.18"/>
<text text-anchor="start" x="408" y="-544.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-519.93 239.25,-539.18 404,-539.18 404,-519.93 239.25,-519.93"/>
<text text-anchor="start" x="243.25" y="-526.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.kind</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-519.93 404,-539.18 474.25,-539.18 474.25,-519.93 404,-519.93"/>
<text text-anchor="start" x="408" y="-525.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-500.68 239.25,-519.93 404,-519.93 404,-500.68 239.25,-500.68"/>
<text text-anchor="start" x="243.25" y="-506.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.standard</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-500.68 404,-519.93 474.25,-519.93 474.25,-500.68 404,-500.68"/>
<text text-anchor="start" x="408" y="-506.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-479.93 239.25,-500.68 404,-500.68 404,-479.93 239.25,-479.93"/>
<text text-anchor="start" x="243.25" y="-486.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-479.93 404,-500.68 474.25,-500.68 474.25,-479.93 404,-479.93"/>
<text text-anchor="start" x="408" y="-487.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-460.68 239.25,-479.93 404,-479.93 404,-460.68 239.25,-460.68"/>
<text text-anchor="start" x="243.25" y="-466.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-460.68 404,-479.93 474.25,-479.93 474.25,-460.68 404,-460.68"/>
<text text-anchor="start" x="408" y="-466.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-441.43 239.25,-460.68 404,-460.68 404,-441.43 239.25,-441.43"/>
<text text-anchor="start" x="243.25" y="-447.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.speed</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-441.43 404,-460.68 474.25,-460.68 474.25,-441.43 404,-441.43"/>
<text text-anchor="start" x="408" y="-447.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-422.18 239.25,-441.43 404,-441.43 404,-422.18 239.25,-422.18"/>
<text text-anchor="start" x="243.25" y="-427.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.wifiStandard</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-422.18 404,-441.43 474.25,-441.43 474.25,-422.18 404,-422.18"/>
<text text-anchor="start" x="408" y="-427.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-402.93 239.25,-422.18 404,-422.18 404,-402.93 239.25,-402.93"/>
<text text-anchor="start" x="243.25" y="-409.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-402.93 404,-422.18 474.25,-422.18 474.25,-402.93 404,-402.93"/>
<text text-anchor="start" x="408" y="-408.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-383.68 239.25,-402.93 404,-402.93 404,-383.68 239.25,-383.68"/>
<text text-anchor="start" x="243.25" y="-390.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-383.68 404,-402.93 474.25,-402.93 474.25,-383.68 404,-383.68"/>
<text text-anchor="start" x="408" y="-389.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-362.93 239.25,-383.68 404,-383.68 404,-362.93 239.25,-362.93"/>
<text text-anchor="start" x="243.25" y="-369.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-362.93 404,-383.68 474.25,-383.68 474.25,-362.93 404,-362.93"/>
<text text-anchor="start" x="408" y="-370.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-343.68 239.25,-362.93 404,-362.93 404,-343.68 239.25,-343.68"/>
<text text-anchor="start" x="243.25" y="-349.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-343.68 404,-362.93 474.25,-362.93 474.25,-343.68 404,-343.68"/>
<text text-anchor="start" x="408" y="-349.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-324.43 239.25,-343.68 404,-343.68 404,-324.43 239.25,-324.43"/>
<text text-anchor="start" x="243.25" y="-330.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-324.43 404,-343.68 474.25,-343.68 474.25,-324.43 404,-324.43"/>
<text text-anchor="start" x="408" y="-330.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-303.68 239.25,-324.43 404,-324.43 404,-303.68 239.25,-303.68"/>
<text text-anchor="start" x="243.25" y="-311.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-303.68 404,-324.43 474.25,-324.43 474.25,-303.68 404,-303.68"/>
<text text-anchor="start" x="408" y="-310.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-282.93 239.25,-303.68 404,-303.68 404,-282.93 239.25,-282.93"/>
<text text-anchor="start" x="243.25" y="-289.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-282.93 404,-303.68 474.25,-303.68 474.25,-282.93 404,-282.93"/>
<text text-anchor="start" x="408" y="-290.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-263.68 239.25,-282.93 404,-282.93 404,-263.68 239.25,-263.68"/>
<text text-anchor="start" x="243.25" y="-269.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-263.68 404,-282.93 474.25,-282.93 474.25,-263.68 404,-263.68"/>
<text text-anchor="start" x="408" y="-269.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-242.93 239.25,-263.68 404,-263.68 404,-242.93 239.25,-242.93"/>
<text text-anchor="start" x="243.25" y="-249.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-242.93 404,-263.68 474.25,-263.68 474.25,-242.93 404,-242.93"/>
<text text-anchor="start" x="408" y="-250.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_95"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-223.68 239.25,-242.93 404,-242.93 404,-223.68 239.25,-223.68"/>
<text text-anchor="start" x="243.25" y="-229.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_96"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-223.68 404,-242.93 474.25,-242.93 474.25,-223.68 404,-223.68"/>
<text text-anchor="start" x="408" y="-229.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_97"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-202.93 239.25,-223.68 404,-223.68 404,-202.93 239.25,-202.93"/>
<text text-anchor="start" x="243.25" y="-209.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_98"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-202.93 404,-223.68 474.25,-223.68 474.25,-202.93 404,-202.93"/>
<text text-anchor="start" x="408" y="-210.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_99"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-183.68 239.25,-202.93 404,-202.93 404,-183.68 239.25,-183.68"/>
<text text-anchor="start" x="243.25" y="-189.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_100"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-183.68 404,-202.93 474.25,-202.93 474.25,-183.68 404,-183.68"/>
<text text-anchor="start" x="408" y="-189.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_101"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-164.43 239.25,-183.68 404,-183.68 404,-164.43 239.25,-164.43"/>
<text text-anchor="start" x="243.25" y="-170.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_102"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-164.43 404,-183.68 474.25,-183.68 474.25,-164.43 404,-164.43"/>
<text text-anchor="start" x="408" y="-170.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_103"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-145.18 239.25,-164.43 404,-164.43 404,-145.18 239.25,-145.18"/>
<text text-anchor="start" x="243.25" y="-150.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_104"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-145.18 404,-164.43 474.25,-164.43 474.25,-145.18 404,-145.18"/>
<text text-anchor="start" x="408" y="-150.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_105"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-125.93 239.25,-145.18 404,-145.18 404,-125.93 239.25,-125.93"/>
<text text-anchor="start" x="243.25" y="-132.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_106"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-125.93 404,-145.18 474.25,-145.18 474.25,-125.93 404,-125.93"/>
<text text-anchor="start" x="408" y="-131.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_107"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-105.18 239.25,-125.93 404,-125.93 404,-105.18 239.25,-105.18"/>
<text text-anchor="start" x="243.25" y="-111.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_108"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-105.18 404,-125.93 474.25,-125.93 474.25,-105.18 404,-105.18"/>
<text text-anchor="start" x="408" y="-112.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_109"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-85.93 239.25,-105.18 404,-105.18 404,-85.93 239.25,-85.93"/>
<text text-anchor="start" x="243.25" y="-91.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_110"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-85.93 404,-105.18 474.25,-105.18 474.25,-85.93 404,-85.93"/>
<text text-anchor="start" x="408" y="-91.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_111"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-66.68 239.25,-85.93 404,-85.93 404,-66.68 239.25,-66.68"/>
<text text-anchor="start" x="243.25" y="-72.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_112"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-66.68 404,-85.93 474.25,-85.93 474.25,-66.68 404,-66.68"/>
<text text-anchor="start" x="408" y="-72.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-820.56C757.75,-820.56 823.59,-727.34 1103.26,-725.7"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.09,-727.8 1109.09,-725.69 1103.08,-723.6 1103.09,-727.8"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="660.25,-685.06 539.25,-685.06 539.25,-451.06 660.25,-451.06 660.25,-685.06"/>
<polygon fill="#f1efe8" stroke="none" points="539.25,-451.06 539.25,-685.06 660.25,-685.06 660.25,-451.06 539.25,-451.06"/>
<g id="a_node3_113"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="539.25,-665.81 539.25,-685.06 660.25,-685.06 660.25,-665.81 539.25,-665.81"/>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-665.81 539.25,-685.06 660.25,-685.06 660.25,-665.81 539.25,-665.81"/>
<text text-anchor="start" x="578.75" y="-672.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-646.56 539.25,-665.81 615.5,-665.81 615.5,-646.56 539.25,-646.56"/>
<text text-anchor="start" x="543.25" y="-652.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-646.56 615.5,-665.81 660.25,-665.81 660.25,-646.56 615.5,-646.56"/>
<text text-anchor="start" x="619.5" y="-652.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_116"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-627.31 539.25,-646.56 615.5,-646.56 615.5,-627.31 539.25,-627.31"/>
<text text-anchor="start" x="543.25" y="-634.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_117"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-627.31 615.5,-646.56 660.25,-646.56 660.25,-627.31 615.5,-627.31"/>
<text text-anchor="start" x="619.5" y="-633.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_118"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-608.06 539.25,-627.31 615.5,-627.31 615.5,-608.06 539.25,-608.06"/>
<text text-anchor="start" x="543.25" y="-614.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_119"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-608.06 615.5,-627.31 660.25,-627.31 660.25,-608.06 615.5,-608.06"/>
<text text-anchor="start" x="619.5" y="-613.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_120"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-587.31 539.25,-608.06 615.5,-608.06 615.5,-587.31 539.25,-587.31"/>
<text text-anchor="start" x="543.25" y="-593.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_121"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-587.31 615.5,-608.06 660.25,-608.06 660.25,-587.31 615.5,-587.31"/>
<text text-anchor="start" x="619.5" y="-594.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_122"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-568.06 539.25,-587.31 615.5,-587.31 615.5,-568.06 539.25,-568.06"/>
<text text-anchor="start" x="543.25" y="-573.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_123"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-568.06 615.5,-587.31 660.25,-587.31 660.25,-568.06 615.5,-568.06"/>
<text text-anchor="start" x="619.5" y="-573.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_124"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-548.81 539.25,-568.06 615.5,-568.06 615.5,-548.81 539.25,-548.81"/>
<text text-anchor="start" x="543.25" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_125"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-548.81 615.5,-568.06 660.25,-568.06 660.25,-548.81 615.5,-548.81"/>
<text text-anchor="start" x="619.5" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_126"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-529.56 539.25,-548.81 615.5,-548.81 615.5,-529.56 539.25,-529.56"/>
<text text-anchor="start" x="543.25" y="-535.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6SubnetId</text>
</a>
</g>
<g id="a_node3_127"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-529.56 615.5,-548.81 660.25,-548.81 660.25,-529.56 615.5,-529.56"/>
<text text-anchor="start" x="619.5" y="-535.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node3_128"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-510.31 539.25,-529.56 615.5,-529.56 615.5,-510.31 539.25,-510.31"/>
<text text-anchor="start" x="543.25" y="-517.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_129"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-510.31 615.5,-529.56 660.25,-529.56 660.25,-510.31 615.5,-510.31"/>
<text text-anchor="start" x="619.5" y="-516.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_130"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-491.06 539.25,-510.31 615.5,-510.31 615.5,-491.06 539.25,-491.06"/>
<text text-anchor="start" x="543.25" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_131"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-491.06 615.5,-510.31 660.25,-510.31 660.25,-491.06 615.5,-491.06"/>
<text text-anchor="start" x="619.5" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_132"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-470.31 539.25,-491.06 615.5,-491.06 615.5,-470.31 539.25,-470.31"/>
<text text-anchor="start" x="543.25" y="-477.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_133"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-470.31 615.5,-491.06 660.25,-491.06 660.25,-470.31 615.5,-470.31"/>
<text text-anchor="start" x="619.5" y="-477.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_134"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-451.06 539.25,-470.31 615.5,-470.31 615.5,-451.06 539.25,-451.06"/>
<text text-anchor="start" x="543.25" y="-456.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_135"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-451.06 615.5,-470.31 660.25,-470.31 660.25,-451.06 615.5,-451.06"/>
<text text-anchor="start" x="619.5" y="-456.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-490.31C558.73,-490.31 458.69,-664.04 531.64,-674.9"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="531.46,-676.99 537.59,-675.31 531.75,-672.8 531.46,-676.99"/>
</g>
<g id="node5" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="635.88,-325.56 563.62,-325.56 563.62,-248.56 635.88,-248.56 635.88,-325.56"/>
<polygon fill="#f1efe8" stroke="none" points="563.62,-248.56 563.62,-325.56 635.88,-325.56 635.88,-248.56 563.62,-248.56"/>
<g id="a_node5_136"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="563.62,-306.31 563.62,-325.56 635.88,-325.56 635.88,-306.31 563.62,-306.31"/>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-306.31 563.62,-325.56 635.88,-325.56 635.88,-306.31 563.62,-306.31"/>
<text text-anchor="start" x="582.88" y="-313.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node5_137"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-287.06 563.62,-306.31 603.88,-306.31 603.88,-287.06 563.62,-287.06"/>
<text text-anchor="start" x="567.62" y="-292.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_138"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-287.06 603.88,-306.31 635.88,-306.31 635.88,-287.06 603.88,-287.06"/>
<text text-anchor="start" x="607.88" y="-292.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_139"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-267.81 563.62,-287.06 603.88,-287.06 603.88,-267.81 563.62,-267.81"/>
<text text-anchor="start" x="567.62" y="-274.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_140"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-267.81 603.88,-287.06 635.88,-287.06 635.88,-267.81 603.88,-267.81"/>
<text text-anchor="start" x="607.88" y="-273.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_141"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-248.56 563.62,-267.81 603.88,-267.81 603.88,-248.56 563.62,-248.56"/>
<text text-anchor="start" x="567.62" y="-254.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_142"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-248.56 603.88,-267.81 635.88,-267.81 635.88,-248.56 603.88,-248.56"/>
<text text-anchor="start" x="607.88" y="-254.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-314.06C510.93,-314.06 521.91,-315.69 555.17,-315.91"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="554.95,-318.01 560.96,-315.93 554.97,-313.81 554.95,-318.01"/>
</g>
<g id="node8" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="828.25,-490.93 725.25,-490.93 725.25,-353.18 828.25,-353.18 828.25,-490.93"/>
<polygon fill="#f1efe8" stroke="none" points="725.25,-353.18 725.25,-490.93 828.25,-490.93 828.25,-353.18 725.25,-353.18"/>
<g id="a_node8_143"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="725.25,-471.68 725.25,-490.93 828.25,-490.93 828.25,-471.68 725.25,-471.68"/>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-471.68 725.25,-490.93 828.25,-490.93 828.25,-471.68 725.25,-471.68"/>
<text text-anchor="start" x="765.88" y="-478.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node8_144"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-452.43 725.25,-471.68 767.75,-471.68 767.75,-452.43 725.25,-452.43"/>
<text text-anchor="start" x="729.25" y="-459.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node8_145"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-452.43 767.75,-471.68 828.25,-471.68 828.25,-452.43 767.75,-452.43"/>
<text text-anchor="start" x="771.75" y="-458.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_146"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-433.18 725.25,-452.43 767.75,-452.43 767.75,-433.18 725.25,-433.18"/>
<text text-anchor="start" x="729.25" y="-438.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Ula</text>
</a>
</g>
<g id="a_node8_147"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-433.18 767.75,-452.43 828.25,-452.43 828.25,-433.18 767.75,-433.18"/>
<text text-anchor="start" x="771.75" y="-438.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_148"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-413.93 725.25,-433.18 767.75,-433.18 767.75,-413.93 725.25,-413.93"/>
<text text-anchor="start" x="729.25" y="-420.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node8_149"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-413.93 767.75,-433.18 828.25,-433.18 828.25,-413.93 767.75,-413.93"/>
<text text-anchor="start" x="771.75" y="-419.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_150"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-394.68 725.25,-413.93 767.75,-413.93 767.75,-394.68 725.25,-394.68"/>
<text text-anchor="start" x="729.25" y="-400.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_151"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-394.68 767.75,-413.93 828.25,-413.93 828.25,-394.68 767.75,-394.68"/>
<text text-anchor="start" x="771.75" y="-400.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_152"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-373.93 725.25,-394.68 767.75,-394.68 767.75,-373.93 725.25,-373.93"/>
<text text-anchor="start" x="729.25" y="-380.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_153"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-373.93 767.75,-394.68 828.25,-394.68 828.25,-373.93 767.75,-373.93"/>
<text text-anchor="start" x="771.75" y="-381.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node8_154"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-353.18 725.25,-373.93 767.75,-373.93 767.75,-353.18 725.25,-353.18"/>
<text text-anchor="start" x="729.25" y="-360.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_155"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-353.18 767.75,-373.93 828.25,-373.93 828.25,-353.18 767.75,-353.18"/>
<text text-anchor="start" x="771.75" y="-360.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-213.31C557.65,-213.31 597.61,-183 660.25,-238.06 742.34,-310.2 619.37,-473.42 717.78,-481.03"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.51,-483.12 723.59,-481.24 717.67,-478.92 717.51,-483.12"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M661.25,-597.68C700.09,-597.68 678.35,-650.7 660.25,-685.06 629.61,-743.2 586.06,-723.92 539.25,-770.06 506.09,-802.74 521.55,-853.83 481.74,-859.32"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="481.76,-857.22 475.91,-859.7 482.03,-861.41 481.76,-857.22"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M660.25,-480.68C686.43,-480.68 694.82,-481.19 717.66,-481.29"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.58,-483.39 723.59,-481.3 717.59,-479.19 717.58,-483.39"/>
</g>
<g id="node4" class="node">
<title>overlays</title>
<polygon fill="#f1efe8" stroke="none" points="125.88,-1283.81 48.38,-1283.81 48.38,-1168.31 125.88,-1168.31 125.88,-1283.81"/>
<polygon fill="#f1efe8" stroke="none" points="48.38,-1168.31 48.38,-1283.81 125.88,-1283.81 125.88,-1168.31 48.38,-1168.31"/>
<g id="a_node4_156"><a data-target="overlays" tabindex="0" role="link"><title>overlays</title>
<polygon fill="#d3d1c7" stroke="none" points="48.38,-1264.56 48.38,-1283.81 125.88,-1283.81 125.88,-1264.56 48.38,-1264.56"/>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1264.56 48.38,-1283.81 125.88,-1283.81 125.88,-1264.56 48.38,-1264.56"/>
<text text-anchor="start" x="67.62" y="-1271.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">overlays</text>
</a>
</g>
<g id="a_node4_157"><a data-target="overlays-ipv4" tabindex="0" role="link"><title>overlays.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1245.31 48.38,-1264.56 93.88,-1264.56 93.88,-1245.31 48.38,-1245.31"/>
<text text-anchor="start" x="52.38" y="-1252.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node4_158"><a data-target="overlays-ipv4" tabindex="0" role="link"><title>overlays.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="93.88,-1245.31 93.88,-1264.56 125.88,-1264.56 125.88,-1245.31 93.88,-1245.31"/>
<text text-anchor="start" x="97.88" y="-1251.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_159"><a data-target="overlays-ipv6" tabindex="0" role="link"><title>overlays.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1226.06 48.38,-1245.31 93.88,-1245.31 93.88,-1226.06 48.38,-1226.06"/>
<text text-anchor="start" x="52.38" y="-1231.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node4_160"><a data-target="overlays-ipv6" tabindex="0" role="link"><title>overlays.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="93.88,-1226.06 93.88,-1245.31 125.88,-1245.31 125.88,-1226.06 93.88,-1226.06"/>
<text text-anchor="start" x="97.88" y="-1231.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_161"><a data-target="overlays-name" tabindex="0" role="link"><title>overlays.name</title>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1206.81 48.38,-1226.06 93.88,-1226.06 93.88,-1206.81 48.38,-1206.81"/>
<text text-anchor="start" x="52.38" y="-1213.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_162"><a data-target="overlays-name" tabindex="0" role="link"><title>overlays.name</title>
<polygon fill="none" stroke="#b4b2a9" points="93.88,-1206.81 93.88,-1226.06 125.88,-1226.06 125.88,-1206.81 93.88,-1206.81"/>
<text text-anchor="start" x="97.88" y="-1212.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_163"><a data-target="overlays-note" tabindex="0" role="link"><title>overlays.note</title>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1187.56 48.38,-1206.81 93.88,-1206.81 93.88,-1187.56 48.38,-1187.56"/>
<text text-anchor="start" x="52.38" y="-1193.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_164"><a data-target="overlays-note" tabindex="0" role="link"><title>overlays.note</title>
<polygon fill="none" stroke="#b4b2a9" points="93.88,-1187.56 93.88,-1206.81 125.88,-1206.81 125.88,-1187.56 93.88,-1187.56"/>
<text text-anchor="start" x="97.88" y="-1193.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_165"><a data-target="overlays-software" tabindex="0" role="link"><title>overlays.software</title>
<polygon fill="none" stroke="#b4b2a9" points="48.38,-1168.31 48.38,-1187.56 93.88,-1187.56 93.88,-1168.31 48.38,-1168.31"/>
<text text-anchor="start" x="52.38" y="-1174.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node4_166"><a data-target="overlays-software" tabindex="0" role="link"><title>overlays.software</title>
<polygon fill="none" stroke="#b4b2a9" points="93.88,-1168.31 93.88,-1187.56 125.88,-1187.56 125.88,-1168.31 93.88,-1168.31"/>
<text text-anchor="start" x="97.88" y="-1174.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node7" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-1146.06 0,-1146.06 0,-558.06 174.25,-558.06 174.25,-1146.06"/>
<polygon fill="#f1efe8" stroke="none" points="0,-558.06 0,-1146.06 174.25,-1146.06 174.25,-558.06 0,-558.06"/>
<g id="a_node7_167"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-1126.81 0,-1146.06 174.25,-1146.06 174.25,-1126.81 0,-1126.81"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-1126.81 0,-1146.06 174.25,-1146.06 174.25,-1126.81 0,-1126.81"/>
<text text-anchor="start" x="68" y="-1133.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node7_168"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1107.56 0,-1126.81 107,-1126.81 107,-1107.56 0,-1107.56"/>
<text text-anchor="start" x="4" y="-1113.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node7_169"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1107.56 107,-1126.81 174.25,-1126.81 174.25,-1107.56 107,-1107.56"/>
<text text-anchor="start" x="111" y="-1113.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node7_170"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1088.31 0,-1107.56 107,-1107.56 107,-1088.31 0,-1088.31"/>
<text text-anchor="start" x="4" y="-1094.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node7_171"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1088.31 107,-1107.56 174.25,-1107.56 174.25,-1088.31 107,-1088.31"/>
<text text-anchor="start" x="111" y="-1094.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_172"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1069.06 0,-1088.31 107,-1088.31 107,-1069.06 0,-1069.06"/>
<text text-anchor="start" x="4" y="-1074.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node7_173"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1069.06 107,-1088.31 174.25,-1088.31 174.25,-1069.06 107,-1069.06"/>
<text text-anchor="start" x="111" y="-1074.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node7_174"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1049.81 0,-1069.06 107,-1069.06 107,-1049.81 0,-1049.81"/>
<text text-anchor="start" x="4" y="-1055.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node7_175"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1049.81 107,-1069.06 174.25,-1069.06 174.25,-1049.81 107,-1049.81"/>
<text text-anchor="start" x="111" y="-1055.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node7_176"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1030.56 0,-1049.81 107,-1049.81 107,-1030.56 0,-1030.56"/>
<text text-anchor="start" x="4" y="-1036.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node7_177"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1030.56 107,-1049.81 174.25,-1049.81 174.25,-1030.56 107,-1030.56"/>
<text text-anchor="start" x="111" y="-1036.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node7_178"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1011.31 0,-1030.56 107,-1030.56 107,-1011.31 0,-1011.31"/>
<text text-anchor="start" x="4" y="-1017.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node7_179"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1011.31 107,-1030.56 174.25,-1030.56 174.25,-1011.31 107,-1011.31"/>
<text text-anchor="start" x="111" y="-1017.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node7_180"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-992.06 0,-1011.31 107,-1011.31 107,-992.06 0,-992.06"/>
<text text-anchor="start" x="4" y="-997.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node7_181"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-992.06 107,-1011.31 174.25,-1011.31 174.25,-992.06 107,-992.06"/>
<text text-anchor="start" x="111" y="-997.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node7_182"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-972.81 0,-992.06 107,-992.06 107,-972.81 0,-972.81"/>
<text text-anchor="start" x="4" y="-978.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node7_183"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-972.81 107,-992.06 174.25,-992.06 174.25,-972.81 107,-972.81"/>
<text text-anchor="start" x="111" y="-978.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node7_184"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-953.56 0,-972.81 107,-972.81 107,-953.56 0,-953.56"/>
<text text-anchor="start" x="4" y="-960.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node7_185"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-953.56 107,-972.81 174.25,-972.81 174.25,-953.56 107,-953.56"/>
<text text-anchor="start" x="111" y="-959.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_186"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-934.31 0,-953.56 107,-953.56 107,-934.31 0,-934.31"/>
<text text-anchor="start" x="4" y="-940.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node7_187"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-934.31 107,-953.56 174.25,-953.56 174.25,-934.31 107,-934.31"/>
<text text-anchor="start" x="111" y="-940.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_188"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-913.56 0,-934.31 107,-934.31 107,-913.56 0,-913.56"/>
<text text-anchor="start" x="4" y="-920.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node7_189"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-913.56 107,-934.31 174.25,-934.31 174.25,-913.56 107,-913.56"/>
<text text-anchor="start" x="111" y="-920.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node7_190"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-892.81 0,-913.56 107,-913.56 107,-892.81 0,-892.81"/>
<text text-anchor="start" x="4" y="-899.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node7_191"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-892.81 107,-913.56 174.25,-913.56 174.25,-892.81 107,-892.81"/>
<text text-anchor="start" x="111" y="-900.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node7_192"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-873.56 0,-892.81 107,-892.81 107,-873.56 0,-873.56"/>
<text text-anchor="start" x="4" y="-879.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node7_193"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-873.56 107,-892.81 174.25,-892.81 174.25,-873.56 107,-873.56"/>
<text text-anchor="start" x="111" y="-879.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_194"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-854.31 0,-873.56 107,-873.56 107,-854.31 0,-854.31"/>
<text text-anchor="start" x="4" y="-861.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node7_195"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-854.31 107,-873.56 174.25,-873.56 174.25,-854.31 107,-854.31"/>
<text text-anchor="start" x="111" y="-860.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_196"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-833.56 0,-854.31 107,-854.31 107,-833.56 0,-833.56"/>
<text text-anchor="start" x="4" y="-840.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node7_197"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-833.56 107,-854.31 174.25,-854.31 174.25,-833.56 107,-833.56"/>
<text text-anchor="start" x="111" y="-840.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node7_198"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-814.31 0,-833.56 107,-833.56 107,-814.31 0,-814.31"/>
<text text-anchor="start" x="4" y="-820.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node7_199"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-814.31 107,-833.56 174.25,-833.56 174.25,-814.31 107,-814.31"/>
<text text-anchor="start" x="111" y="-820.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node7_200"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-795.06 0,-814.31 107,-814.31 107,-795.06 0,-795.06"/>
<text text-anchor="start" x="4" y="-801.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node7_201"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-795.06 107,-814.31 174.25,-814.31 174.25,-795.06 107,-795.06"/>
<text text-anchor="start" x="111" y="-800.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_202"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-775.81 0,-795.06 107,-795.06 107,-775.81 0,-775.81"/>
<text text-anchor="start" x="4" y="-782.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node7_203"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-775.81 107,-795.06 174.25,-795.06 174.25,-775.81 107,-775.81"/>
<text text-anchor="start" x="111" y="-781.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_204"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-756.56 0,-775.81 107,-775.81 107,-756.56 0,-756.56"/>
<text text-anchor="start" x="4" y="-762.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node7_205"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-756.56 107,-775.81 174.25,-775.81 174.25,-756.56 107,-756.56"/>
<text text-anchor="start" x="111" y="-762.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_206"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-737.31 0,-756.56 107,-756.56 107,-737.31 0,-737.31"/>
<text text-anchor="start" x="4" y="-743.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node7_207"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-737.31 107,-756.56 174.25,-756.56 174.25,-737.31 107,-737.31"/>
<text text-anchor="start" x="111" y="-743.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node7_208"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-716.56 0,-737.31 107,-737.31 107,-716.56 0,-716.56"/>
<text text-anchor="start" x="4" y="-723.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node7_209"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-716.56 107,-737.31 174.25,-737.31 174.25,-716.56 107,-716.56"/>
<text text-anchor="start" x="111" y="-723.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node7_210"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-695.81 0,-716.56 107,-716.56 107,-695.81 0,-695.81"/>
<text text-anchor="start" x="4" y="-702.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node7_211"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-695.81 107,-716.56 174.25,-716.56 174.25,-695.81 107,-695.81"/>
<text text-anchor="start" x="111" y="-703.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node7_212"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-676.56 0,-695.81 107,-695.81 107,-676.56 0,-676.56"/>
<text text-anchor="start" x="4" y="-683.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node7_213"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-676.56 107,-695.81 174.25,-695.81 174.25,-676.56 107,-676.56"/>
<text text-anchor="start" x="111" y="-682.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_214"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-657.31 0,-676.56 107,-676.56 107,-657.31 0,-657.31"/>
<text text-anchor="start" x="4" y="-663.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_215"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-657.31 107,-676.56 174.25,-676.56 174.25,-657.31 107,-657.31"/>
<text text-anchor="start" x="111" y="-663.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_216"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-638.06 0,-657.31 107,-657.31 107,-638.06 0,-638.06"/>
<text text-anchor="start" x="4" y="-643.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node7_217"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-638.06 107,-657.31 174.25,-657.31 174.25,-638.06 107,-638.06"/>
<text text-anchor="start" x="111" y="-643.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_218"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-617.31 0,-638.06 107,-638.06 107,-617.31 0,-617.31"/>
<text text-anchor="start" x="4" y="-623.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_219"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-617.31 107,-638.06 174.25,-638.06 174.25,-617.31 107,-617.31"/>
<text text-anchor="start" x="111" y="-624.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_220"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-598.06 0,-617.31 107,-617.31 107,-598.06 0,-598.06"/>
<text text-anchor="start" x="4" y="-603.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node7_221"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-598.06 107,-617.31 174.25,-617.31 174.25,-598.06 107,-598.06"/>
<text text-anchor="start" x="111" y="-603.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_222"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-577.31 0,-598.06 107,-598.06 107,-577.31 0,-577.31"/>
<text text-anchor="start" x="4" y="-583.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node7_223"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-577.31 107,-598.06 174.25,-598.06 174.25,-577.31 107,-577.31"/>
<text text-anchor="start" x="111" y="-584.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node7_224"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-558.06 0,-577.31 107,-577.31 107,-558.06 0,-558.06"/>
<text text-anchor="start" x="4" y="-563.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node7_225"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-558.06 107,-577.31 174.25,-577.31 174.25,-558.06 107,-558.06"/>
<text text-anchor="start" x="111" y="-563.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-903.18C362.92,-903.18 410.08,-903.06 598.75,-903.06 598.75,-903.06 598.75,-903.06 777.75,-903.06 797.36,-903.06 1053.39,-747.81 1103.48,-727.8"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.98,-729.84 1109.15,-726.15 1102.8,-725.8 1103.98,-729.84"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-706.18C245.64,-706.18 171.08,-848.62 231.63,-859.19"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-861.28 237.59,-859.67 231.78,-857.09 231.44,-861.28"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-627.68C302.1,-627.68 146.65,-144.2 239.25,-56.06 355.22,54.33 438.65,-33.06 598.75,-33.06 598.75,-33.06 598.75,-33.06 970.5,-33.06 1098.79,-33.06 1151.67,-36.73 1243.75,-126.06 1301.01,-181.6 1231.05,-292.35 1301.49,-299.22"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301,-301.3 1307.09,-299.48 1301.19,-297.1 1301,-301.3"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-384.31C924.92,-384.31 950.26,-399.08 1045.75,-384.06 1164.55,-365.37 1185.16,-302.22 1301.33,-299.64"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.11,-301.74 1307.09,-299.57 1301.06,-297.54 1301.11,-301.74"/>
</g>
<g id="node9" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1045.75,-373.31 893.25,-373.31 893.25,-100.81 1045.75,-100.81 1045.75,-373.31"/>
<polygon fill="#f1efe8" stroke="none" points="893.25,-100.81 893.25,-373.31 1045.75,-373.31 1045.75,-100.81 893.25,-100.81"/>
<g id="a_node9_226"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="893.25,-354.06 893.25,-373.31 1045.75,-373.31 1045.75,-354.06 893.25,-354.06"/>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-354.06 893.25,-373.31 1045.75,-373.31 1045.75,-354.06 893.25,-354.06"/>
<text text-anchor="start" x="952.25" y="-360.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node9_227"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-334.81 893.25,-354.06 978.5,-354.06 978.5,-334.81 893.25,-334.81"/>
<text text-anchor="start" x="897.25" y="-340.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node9_228"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-334.81 978.5,-354.06 1045.75,-354.06 1045.75,-334.81 978.5,-334.81"/>
<text text-anchor="start" x="982.5" y="-340.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node9_229"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-315.56 893.25,-334.81 978.5,-334.81 978.5,-315.56 893.25,-315.56"/>
<text text-anchor="start" x="897.25" y="-321.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node9_230"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-315.56 978.5,-334.81 1045.75,-334.81 1045.75,-315.56 978.5,-315.56"/>
<text text-anchor="start" x="982.5" y="-321.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node9_231"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-296.31 893.25,-315.56 978.5,-315.56 978.5,-296.31 893.25,-296.31"/>
<text text-anchor="start" x="897.25" y="-303.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node9_232"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-296.31 978.5,-315.56 1045.75,-315.56 1045.75,-296.31 978.5,-296.31"/>
<text text-anchor="start" x="982.5" y="-302.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node9_233"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-277.06 893.25,-296.31 978.5,-296.31 978.5,-277.06 893.25,-277.06"/>
<text text-anchor="start" x="897.25" y="-283.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node9_234"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-277.06 978.5,-296.31 1045.75,-296.31 1045.75,-277.06 978.5,-277.06"/>
<text text-anchor="start" x="982.5" y="-282.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node9_235"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-256.31 893.25,-277.06 978.5,-277.06 978.5,-256.31 893.25,-256.31"/>
<text text-anchor="start" x="897.25" y="-262.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node9_236"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-256.31 978.5,-277.06 1045.75,-277.06 1045.75,-256.31 978.5,-256.31"/>
<text text-anchor="start" x="982.5" y="-263.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node9_237"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-237.06 893.25,-256.31 978.5,-256.31 978.5,-237.06 893.25,-237.06"/>
<text text-anchor="start" x="897.25" y="-242.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node9_238"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-237.06 978.5,-256.31 1045.75,-256.31 1045.75,-237.06 978.5,-237.06"/>
<text text-anchor="start" x="982.5" y="-242.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node9_239"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-217.81 893.25,-237.06 978.5,-237.06 978.5,-217.81 893.25,-217.81"/>
<text text-anchor="start" x="897.25" y="-223.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node9_240"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-217.81 978.5,-237.06 1045.75,-237.06 1045.75,-217.81 978.5,-217.81"/>
<text text-anchor="start" x="982.5" y="-223.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node9_241"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-198.56 893.25,-217.81 978.5,-217.81 978.5,-198.56 893.25,-198.56"/>
<text text-anchor="start" x="897.25" y="-204.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node9_242"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-198.56 978.5,-217.81 1045.75,-217.81 1045.75,-198.56 978.5,-198.56"/>
<text text-anchor="start" x="982.5" y="-204.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node9_243"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-179.31 893.25,-198.56 978.5,-198.56 978.5,-179.31 893.25,-179.31"/>
<text text-anchor="start" x="897.25" y="-185.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node9_244"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-179.31 978.5,-198.56 1045.75,-198.56 1045.75,-179.31 978.5,-179.31"/>
<text text-anchor="start" x="982.5" y="-185.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node9_245"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-160.06 893.25,-179.31 978.5,-179.31 978.5,-160.06 893.25,-160.06"/>
<text text-anchor="start" x="897.25" y="-165.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node9_246"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-160.06 978.5,-179.31 1045.75,-179.31 1045.75,-160.06 978.5,-160.06"/>
<text text-anchor="start" x="982.5" y="-165.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node9_247"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-140.81 893.25,-160.06 978.5,-160.06 978.5,-140.81 893.25,-140.81"/>
<text text-anchor="start" x="897.25" y="-146.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node9_248"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-140.81 978.5,-160.06 1045.75,-160.06 1045.75,-140.81 978.5,-140.81"/>
<text text-anchor="start" x="982.5" y="-146.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node9_249"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-121.56 893.25,-140.81 978.5,-140.81 978.5,-121.56 893.25,-121.56"/>
<text text-anchor="start" x="897.25" y="-127.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node9_250"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-121.56 978.5,-140.81 1045.75,-140.81 1045.75,-121.56 978.5,-121.56"/>
<text text-anchor="start" x="982.5" y="-127.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node9_251"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-100.81 893.25,-121.56 978.5,-121.56 978.5,-100.81 893.25,-100.81"/>
<text text-anchor="start" x="897.25" y="-107.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node9_252"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-100.81 978.5,-121.56 1045.75,-121.56 1045.75,-100.81 978.5,-100.81"/>
<text text-anchor="start" x="982.5" y="-108.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-363.56C854.43,-363.56 862.82,-363.66 885.66,-363.68"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="885.58,-365.78 891.59,-363.68 885.59,-361.58 885.58,-365.78"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-266.68C1249.17,-266.68 913.44,-714.1 1103.17,-725.46"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.03,-727.56 1109.09,-725.63 1103.15,-723.36 1103.03,-727.56"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-111.18C1187,-111.18 1165.78,-292.99 1301.32,-299.38"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.04,-301.48 1307.09,-299.52 1301.14,-297.28 1301.04,-301.48"/>
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

## overlays { #overlays }

Ein Netz, das an keinem Standort liegt, etwa das Mesh, dem jeder Peer beitritt.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="overlays-ipv4"></span>`ipv4` | String: an IPv4 prefix like 100.64.0.0/10 | Pflicht | IPv4 range the peers get their addresses from. |
| <span id="overlays-ipv6"></span>`ipv6` | String: an IPv6 prefix like fd12:3456:789a:1::/64 |  | IPv6 range of the overlay, when it has one. |
| <span id="overlays-name"></span>`name` | String | Pflicht | Display name. |
| <span id="overlays-note"></span>`note` | String |  | Free text: anything worth knowing that has no field of its own. |
| <span id="overlays-software"></span>`software` | String |  | What builds the overlay (NetBird, Tailscale). |

```json
{
  "overlays": {
    "mesh": {
      "name": "Mesh",
      "software": "NetBird",
      "ipv4": "100.64.0.0/22",
      "ipv6": "fd12:3456:789a:1::/64"
    }
  }
}
```

Regeln über das Schema hinaus: Das IPv4-Präfix hat keine Host-Bits.

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
  "overlays": {
    "mesh": {
      "name": "Mesh",
      "software": "NetBird",
      "ipv4": "100.64.0.0/22",
      "ipv6": "fd12:3456:789a:1::/64"
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
