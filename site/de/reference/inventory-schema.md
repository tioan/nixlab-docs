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
 viewBox="0.00 0.00 1372.50 978.81" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 974.81)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1227.25,-645.06 1094.25,-645.06 1094.25,-412.56 1227.25,-412.56 1227.25,-645.06"/>
<polygon fill="#f1efe8" stroke="none" points="1094.25,-412.56 1094.25,-645.06 1227.25,-645.06 1227.25,-412.56 1094.25,-412.56"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1094.25,-625.81 1094.25,-645.06 1227.25,-645.06 1227.25,-625.81 1094.25,-625.81"/>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-625.81 1094.25,-645.06 1227.25,-645.06 1227.25,-625.81 1094.25,-625.81"/>
<text text-anchor="start" x="1139.38" y="-632.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-606.56 1094.25,-625.81 1166.75,-625.81 1166.75,-606.56 1094.25,-606.56"/>
<text text-anchor="start" x="1098.25" y="-612.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-606.56 1166.75,-625.81 1227.25,-625.81 1227.25,-606.56 1166.75,-606.56"/>
<text text-anchor="start" x="1170.75" y="-612.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-587.31 1094.25,-606.56 1166.75,-606.56 1166.75,-587.31 1094.25,-587.31"/>
<text text-anchor="start" x="1098.25" y="-594.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-587.31 1166.75,-606.56 1227.25,-606.56 1227.25,-587.31 1166.75,-587.31"/>
<text text-anchor="start" x="1170.75" y="-593.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-568.06 1094.25,-587.31 1166.75,-587.31 1166.75,-568.06 1094.25,-568.06"/>
<text text-anchor="start" x="1098.25" y="-574.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-568.06 1166.75,-587.31 1227.25,-587.31 1227.25,-568.06 1166.75,-568.06"/>
<text text-anchor="start" x="1170.75" y="-573.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-548.81 1094.25,-568.06 1166.75,-568.06 1166.75,-548.81 1094.25,-548.81"/>
<text text-anchor="start" x="1098.25" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-548.81 1166.75,-568.06 1227.25,-568.06 1227.25,-548.81 1166.75,-548.81"/>
<text text-anchor="start" x="1170.75" y="-554.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-529.56 1094.25,-548.81 1166.75,-548.81 1166.75,-529.56 1094.25,-529.56"/>
<text text-anchor="start" x="1098.25" y="-536.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-529.56 1166.75,-548.81 1227.25,-548.81 1227.25,-529.56 1166.75,-529.56"/>
<text text-anchor="start" x="1170.75" y="-535.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-510.31 1094.25,-529.56 1166.75,-529.56 1166.75,-510.31 1094.25,-510.31"/>
<text text-anchor="start" x="1098.25" y="-516.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-510.31 1166.75,-529.56 1227.25,-529.56 1227.25,-510.31 1166.75,-510.31"/>
<text text-anchor="start" x="1170.75" y="-516.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-491.06 1094.25,-510.31 1166.75,-510.31 1166.75,-491.06 1094.25,-491.06"/>
<text text-anchor="start" x="1098.25" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-491.06 1166.75,-510.31 1227.25,-510.31 1227.25,-491.06 1166.75,-491.06"/>
<text text-anchor="start" x="1170.75" y="-496.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-471.81 1094.25,-491.06 1166.75,-491.06 1166.75,-471.81 1094.25,-471.81"/>
<text text-anchor="start" x="1098.25" y="-477.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-471.81 1166.75,-491.06 1227.25,-491.06 1227.25,-471.81 1166.75,-471.81"/>
<text text-anchor="start" x="1170.75" y="-477.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-451.06 1094.25,-471.81 1166.75,-471.81 1166.75,-451.06 1094.25,-451.06"/>
<text text-anchor="start" x="1098.25" y="-458.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-451.06 1166.75,-471.81 1227.25,-471.81 1227.25,-451.06 1166.75,-451.06"/>
<text text-anchor="start" x="1170.75" y="-458.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-431.81 1094.25,-451.06 1166.75,-451.06 1166.75,-431.81 1094.25,-431.81"/>
<text text-anchor="start" x="1098.25" y="-437.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-431.81 1166.75,-451.06 1227.25,-451.06 1227.25,-431.81 1166.75,-431.81"/>
<text text-anchor="start" x="1170.75" y="-437.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1094.25,-412.56 1094.25,-431.81 1166.75,-431.81 1166.75,-412.56 1094.25,-412.56"/>
<text text-anchor="start" x="1098.25" y="-418.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1166.75,-412.56 1166.75,-431.81 1227.25,-431.81 1227.25,-412.56 1166.75,-412.56"/>
<text text-anchor="start" x="1170.75" y="-418.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node5" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1364.5,-305.93 1292.25,-305.93 1292.25,-209.68 1364.5,-209.68 1364.5,-305.93"/>
<polygon fill="#f1efe8" stroke="none" points="1292.25,-209.68 1292.25,-305.93 1364.5,-305.93 1364.5,-209.68 1292.25,-209.68"/>
<g id="a_node5_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1292.25,-286.68 1292.25,-305.93 1364.5,-305.93 1364.5,-286.68 1292.25,-286.68"/>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-286.68 1292.25,-305.93 1364.5,-305.93 1364.5,-286.68 1292.25,-286.68"/>
<text text-anchor="start" x="1306.25" y="-293.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node5_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-267.43 1292.25,-286.68 1332.5,-286.68 1332.5,-267.43 1292.25,-267.43"/>
<text text-anchor="start" x="1296.25" y="-273.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-267.43 1332.5,-286.68 1364.5,-286.68 1364.5,-267.43 1332.5,-267.43"/>
<text text-anchor="start" x="1336.5" y="-273.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-248.18 1292.25,-267.43 1332.5,-267.43 1332.5,-248.18 1292.25,-248.18"/>
<text text-anchor="start" x="1296.25" y="-254.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-248.18 1332.5,-267.43 1364.5,-267.43 1364.5,-248.18 1332.5,-248.18"/>
<text text-anchor="start" x="1336.5" y="-253.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-228.93 1292.25,-248.18 1332.5,-248.18 1332.5,-228.93 1292.25,-228.93"/>
<text text-anchor="start" x="1296.25" y="-234.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-228.93 1332.5,-248.18 1364.5,-248.18 1364.5,-228.93 1332.5,-228.93"/>
<text text-anchor="start" x="1336.5" y="-234.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1292.25,-209.68 1292.25,-228.93 1332.5,-228.93 1332.5,-209.68 1292.25,-209.68"/>
<text text-anchor="start" x="1296.25" y="-215.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node5_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1332.5,-209.68 1332.5,-228.93 1364.5,-228.93 1364.5,-209.68 1332.5,-209.68"/>
<text text-anchor="start" x="1336.5" y="-215.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1227.25,-461.43C1303.5,-461.43 1219.35,-307.09 1284.95,-296.84"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.76,-298.96 1290.59,-296.43 1284.45,-294.77 1284.76,-298.96"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="457.75,-693.56 239.25,-693.56 239.25,-64.06 457.75,-64.06 457.75,-693.56"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-64.06 239.25,-693.56 457.75,-693.56 457.75,-64.06 239.25,-64.06"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-674.31 239.25,-693.56 457.75,-693.56 457.75,-674.31 239.25,-674.31"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-674.31 239.25,-693.56 457.75,-693.56 457.75,-674.31 239.25,-674.31"/>
<text text-anchor="start" x="335.75" y="-681.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-655.06 239.25,-674.31 387.5,-674.31 387.5,-655.06 239.25,-655.06"/>
<text text-anchor="start" x="243.25" y="-660.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-655.06 387.5,-674.31 457.75,-674.31 457.75,-655.06 387.5,-655.06"/>
<text text-anchor="start" x="391.5" y="-660.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-634.31 239.25,-655.06 387.5,-655.06 387.5,-634.31 239.25,-634.31"/>
<text text-anchor="start" x="243.25" y="-640.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-634.31 387.5,-655.06 457.75,-655.06 457.75,-634.31 387.5,-634.31"/>
<text text-anchor="start" x="391.5" y="-641.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-615.06 239.25,-634.31 387.5,-634.31 387.5,-615.06 239.25,-615.06"/>
<text text-anchor="start" x="243.25" y="-620.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-615.06 387.5,-634.31 457.75,-634.31 457.75,-615.06 387.5,-615.06"/>
<text text-anchor="start" x="391.5" y="-620.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-594.31 239.25,-615.06 387.5,-615.06 387.5,-594.31 239.25,-594.31"/>
<text text-anchor="start" x="243.25" y="-600.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-594.31 387.5,-615.06 457.75,-615.06 457.75,-594.31 387.5,-594.31"/>
<text text-anchor="start" x="391.5" y="-601.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-575.06 239.25,-594.31 387.5,-594.31 387.5,-575.06 239.25,-575.06"/>
<text text-anchor="start" x="243.25" y="-580.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-575.06 387.5,-594.31 457.75,-594.31 457.75,-575.06 387.5,-575.06"/>
<text text-anchor="start" x="391.5" y="-580.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-555.81 239.25,-575.06 387.5,-575.06 387.5,-555.81 239.25,-555.81"/>
<text text-anchor="start" x="243.25" y="-561.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-555.81 387.5,-575.06 457.75,-575.06 457.75,-555.81 387.5,-555.81"/>
<text text-anchor="start" x="391.5" y="-561.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-536.56 239.25,-555.81 387.5,-555.81 387.5,-536.56 239.25,-536.56"/>
<text text-anchor="start" x="243.25" y="-542.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-536.56 387.5,-555.81 457.75,-555.81 457.75,-536.56 387.5,-536.56"/>
<text text-anchor="start" x="391.5" y="-542.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-517.31 239.25,-536.56 387.5,-536.56 387.5,-517.31 239.25,-517.31"/>
<text text-anchor="start" x="243.25" y="-524.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-517.31 387.5,-536.56 457.75,-536.56 457.75,-517.31 387.5,-517.31"/>
<text text-anchor="start" x="391.5" y="-523.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-498.06 239.25,-517.31 387.5,-517.31 387.5,-498.06 239.25,-498.06"/>
<text text-anchor="start" x="243.25" y="-503.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-498.06 387.5,-517.31 457.75,-517.31 457.75,-498.06 387.5,-498.06"/>
<text text-anchor="start" x="391.5" y="-503.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-478.81 239.25,-498.06 387.5,-498.06 387.5,-478.81 239.25,-478.81"/>
<text text-anchor="start" x="243.25" y="-484.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-478.81 387.5,-498.06 457.75,-498.06 457.75,-478.81 387.5,-478.81"/>
<text text-anchor="start" x="391.5" y="-484.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-459.56 239.25,-478.81 387.5,-478.81 387.5,-459.56 239.25,-459.56"/>
<text text-anchor="start" x="243.25" y="-465.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-459.56 387.5,-478.81 457.75,-478.81 457.75,-459.56 387.5,-459.56"/>
<text text-anchor="start" x="391.5" y="-465.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-438.81 239.25,-459.56 387.5,-459.56 387.5,-438.81 239.25,-438.81"/>
<text text-anchor="start" x="243.25" y="-445.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-438.81 387.5,-459.56 457.75,-459.56 457.75,-438.81 387.5,-438.81"/>
<text text-anchor="start" x="391.5" y="-446.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-419.56 239.25,-438.81 387.5,-438.81 387.5,-419.56 239.25,-419.56"/>
<text text-anchor="start" x="243.25" y="-425.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-419.56 387.5,-438.81 457.75,-438.81 457.75,-419.56 387.5,-419.56"/>
<text text-anchor="start" x="391.5" y="-425.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-400.31 239.25,-419.56 387.5,-419.56 387.5,-400.31 239.25,-400.31"/>
<text text-anchor="start" x="243.25" y="-407.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-400.31 387.5,-419.56 457.75,-419.56 457.75,-400.31 387.5,-400.31"/>
<text text-anchor="start" x="391.5" y="-406.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-381.06 239.25,-400.31 387.5,-400.31 387.5,-381.06 239.25,-381.06"/>
<text text-anchor="start" x="243.25" y="-387.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-381.06 387.5,-400.31 457.75,-400.31 457.75,-381.06 387.5,-381.06"/>
<text text-anchor="start" x="391.5" y="-386.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-360.31 239.25,-381.06 387.5,-381.06 387.5,-360.31 239.25,-360.31"/>
<text text-anchor="start" x="243.25" y="-366.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-360.31 387.5,-381.06 457.75,-381.06 457.75,-360.31 387.5,-360.31"/>
<text text-anchor="start" x="391.5" y="-367.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-341.06 239.25,-360.31 387.5,-360.31 387.5,-341.06 239.25,-341.06"/>
<text text-anchor="start" x="243.25" y="-346.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-341.06 387.5,-360.31 457.75,-360.31 457.75,-341.06 387.5,-341.06"/>
<text text-anchor="start" x="391.5" y="-346.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-321.81 239.25,-341.06 387.5,-341.06 387.5,-321.81 239.25,-321.81"/>
<text text-anchor="start" x="243.25" y="-327.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-321.81 387.5,-341.06 457.75,-341.06 457.75,-321.81 387.5,-321.81"/>
<text text-anchor="start" x="391.5" y="-327.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-301.06 239.25,-321.81 387.5,-321.81 387.5,-301.06 239.25,-301.06"/>
<text text-anchor="start" x="243.25" y="-308.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-301.06 387.5,-321.81 457.75,-321.81 457.75,-301.06 387.5,-301.06"/>
<text text-anchor="start" x="391.5" y="-308.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-280.31 239.25,-301.06 387.5,-301.06 387.5,-280.31 239.25,-280.31"/>
<text text-anchor="start" x="243.25" y="-286.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-280.31 387.5,-301.06 457.75,-301.06 457.75,-280.31 387.5,-280.31"/>
<text text-anchor="start" x="391.5" y="-287.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-261.06 239.25,-280.31 387.5,-280.31 387.5,-261.06 239.25,-261.06"/>
<text text-anchor="start" x="243.25" y="-266.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-261.06 387.5,-280.31 457.75,-280.31 457.75,-261.06 387.5,-261.06"/>
<text text-anchor="start" x="391.5" y="-266.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-240.31 239.25,-261.06 387.5,-261.06 387.5,-240.31 239.25,-240.31"/>
<text text-anchor="start" x="243.25" y="-246.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-240.31 387.5,-261.06 457.75,-261.06 457.75,-240.31 387.5,-240.31"/>
<text text-anchor="start" x="391.5" y="-247.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-221.06 239.25,-240.31 387.5,-240.31 387.5,-221.06 239.25,-221.06"/>
<text text-anchor="start" x="243.25" y="-226.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-221.06 387.5,-240.31 457.75,-240.31 457.75,-221.06 387.5,-221.06"/>
<text text-anchor="start" x="391.5" y="-226.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-200.31 239.25,-221.06 387.5,-221.06 387.5,-200.31 239.25,-200.31"/>
<text text-anchor="start" x="243.25" y="-206.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-200.31 387.5,-221.06 457.75,-221.06 457.75,-200.31 387.5,-200.31"/>
<text text-anchor="start" x="391.5" y="-207.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-181.06 239.25,-200.31 387.5,-200.31 387.5,-181.06 239.25,-181.06"/>
<text text-anchor="start" x="243.25" y="-186.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-181.06 387.5,-200.31 457.75,-200.31 457.75,-181.06 387.5,-181.06"/>
<text text-anchor="start" x="391.5" y="-186.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-161.81 239.25,-181.06 387.5,-181.06 387.5,-161.81 239.25,-161.81"/>
<text text-anchor="start" x="243.25" y="-167.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-161.81 387.5,-181.06 457.75,-181.06 457.75,-161.81 387.5,-161.81"/>
<text text-anchor="start" x="391.5" y="-167.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-142.56 239.25,-161.81 387.5,-161.81 387.5,-142.56 239.25,-142.56"/>
<text text-anchor="start" x="243.25" y="-148.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-142.56 387.5,-161.81 457.75,-161.81 457.75,-142.56 387.5,-142.56"/>
<text text-anchor="start" x="391.5" y="-148.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-123.31 239.25,-142.56 387.5,-142.56 387.5,-123.31 239.25,-123.31"/>
<text text-anchor="start" x="243.25" y="-130.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-123.31 387.5,-142.56 457.75,-142.56 457.75,-123.31 387.5,-123.31"/>
<text text-anchor="start" x="391.5" y="-129.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-102.56 239.25,-123.31 387.5,-123.31 387.5,-102.56 239.25,-102.56"/>
<text text-anchor="start" x="243.25" y="-109.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-102.56 387.5,-123.31 457.75,-123.31 457.75,-102.56 387.5,-102.56"/>
<text text-anchor="start" x="391.5" y="-109.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-83.31 239.25,-102.56 387.5,-102.56 387.5,-83.31 239.25,-83.31"/>
<text text-anchor="start" x="243.25" y="-89.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-83.31 387.5,-102.56 457.75,-102.56 457.75,-83.31 387.5,-83.31"/>
<text text-anchor="start" x="391.5" y="-89.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-64.06 239.25,-83.31 387.5,-83.31 387.5,-64.06 239.25,-64.06"/>
<text text-anchor="start" x="243.25" y="-69.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="387.5,-64.06 387.5,-83.31 457.75,-83.31 457.75,-64.06 387.5,-64.06"/>
<text text-anchor="start" x="391.5" y="-69.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-644.68C738.18,-644.68 810.07,-635.59 1086.84,-635.43"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.59,-637.54 1092.59,-635.43 1086.58,-633.34 1086.59,-637.54"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="643.75,-609.18 522.75,-609.18 522.75,-394.43 643.75,-394.43 643.75,-609.18"/>
<polygon fill="#f1efe8" stroke="none" points="522.75,-394.43 522.75,-609.18 643.75,-609.18 643.75,-394.43 522.75,-394.43"/>
<g id="a_node3_95"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="522.75,-589.93 522.75,-609.18 643.75,-609.18 643.75,-589.93 522.75,-589.93"/>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-589.93 522.75,-609.18 643.75,-609.18 643.75,-589.93 522.75,-589.93"/>
<text text-anchor="start" x="562.25" y="-596.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_96"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-570.68 522.75,-589.93 599,-589.93 599,-570.68 522.75,-570.68"/>
<text text-anchor="start" x="526.75" y="-576.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_97"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-570.68 599,-589.93 643.75,-589.93 643.75,-570.68 599,-570.68"/>
<text text-anchor="start" x="603" y="-576.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_98"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-551.43 522.75,-570.68 599,-570.68 599,-551.43 522.75,-551.43"/>
<text text-anchor="start" x="526.75" y="-558.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_99"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-551.43 599,-570.68 643.75,-570.68 643.75,-551.43 599,-551.43"/>
<text text-anchor="start" x="603" y="-557.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_100"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-532.18 522.75,-551.43 599,-551.43 599,-532.18 522.75,-532.18"/>
<text text-anchor="start" x="526.75" y="-538.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_101"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-532.18 599,-551.43 643.75,-551.43 643.75,-532.18 599,-532.18"/>
<text text-anchor="start" x="603" y="-537.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_102"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-511.43 522.75,-532.18 599,-532.18 599,-511.43 522.75,-511.43"/>
<text text-anchor="start" x="526.75" y="-517.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_103"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-511.43 599,-532.18 643.75,-532.18 643.75,-511.43 599,-511.43"/>
<text text-anchor="start" x="603" y="-518.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_104"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-492.18 522.75,-511.43 599,-511.43 599,-492.18 522.75,-492.18"/>
<text text-anchor="start" x="526.75" y="-497.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_105"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-492.18 599,-511.43 643.75,-511.43 643.75,-492.18 599,-492.18"/>
<text text-anchor="start" x="603" y="-497.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_106"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-472.93 522.75,-492.18 599,-492.18 599,-472.93 522.75,-472.93"/>
<text text-anchor="start" x="526.75" y="-478.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_107"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-472.93 599,-492.18 643.75,-492.18 643.75,-472.93 599,-472.93"/>
<text text-anchor="start" x="603" y="-478.68" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_108"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-453.68 522.75,-472.93 599,-472.93 599,-453.68 522.75,-453.68"/>
<text text-anchor="start" x="526.75" y="-460.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_109"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-453.68 599,-472.93 643.75,-472.93 643.75,-453.68 599,-453.68"/>
<text text-anchor="start" x="603" y="-459.43" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_110"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-434.43 522.75,-453.68 599,-453.68 599,-434.43 522.75,-434.43"/>
<text text-anchor="start" x="526.75" y="-440.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_111"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-434.43 599,-453.68 643.75,-453.68 643.75,-434.43 599,-434.43"/>
<text text-anchor="start" x="603" y="-440.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_112"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-413.68 522.75,-434.43 599,-434.43 599,-413.68 522.75,-413.68"/>
<text text-anchor="start" x="526.75" y="-421.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_113"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-413.68 599,-434.43 643.75,-434.43 643.75,-413.68 599,-413.68"/>
<text text-anchor="start" x="603" y="-420.93" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="522.75,-394.43 522.75,-413.68 599,-413.68 599,-394.43 522.75,-394.43"/>
<text text-anchor="start" x="526.75" y="-400.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="599,-394.43 599,-413.68 643.75,-413.68 643.75,-394.43 599,-394.43"/>
<text text-anchor="start" x="603" y="-400.18" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-449.18C527.86,-449.18 455.71,-588.6 515.26,-598.95"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="514.94,-601.03 521.09,-599.42 515.28,-596.85 514.94,-601.03"/>
</g>
<g id="node4" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="619.38,-322.31 547.12,-322.31 547.12,-245.31 619.38,-245.31 619.38,-322.31"/>
<polygon fill="#f1efe8" stroke="none" points="547.12,-245.31 547.12,-322.31 619.38,-322.31 619.38,-245.31 547.12,-245.31"/>
<g id="a_node4_116"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="547.12,-303.06 547.12,-322.31 619.38,-322.31 619.38,-303.06 547.12,-303.06"/>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-303.06 547.12,-322.31 619.38,-322.31 619.38,-303.06 547.12,-303.06"/>
<text text-anchor="start" x="566.38" y="-309.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node4_117"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-283.81 547.12,-303.06 587.38,-303.06 587.38,-283.81 547.12,-283.81"/>
<text text-anchor="start" x="551.12" y="-289.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node4_118"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-283.81 587.38,-303.06 619.38,-303.06 619.38,-283.81 587.38,-283.81"/>
<text text-anchor="start" x="591.38" y="-289.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_119"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-264.56 547.12,-283.81 587.38,-283.81 587.38,-264.56 547.12,-264.56"/>
<text text-anchor="start" x="551.12" y="-271.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_120"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-264.56 587.38,-283.81 619.38,-283.81 619.38,-264.56 587.38,-264.56"/>
<text text-anchor="start" x="591.38" y="-270.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_121"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="547.12,-245.31 547.12,-264.56 587.38,-264.56 587.38,-245.31 547.12,-245.31"/>
<text text-anchor="start" x="551.12" y="-251.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_122"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="587.38,-245.31 587.38,-264.56 619.38,-264.56 619.38,-245.31 587.38,-245.31"/>
<text text-anchor="start" x="591.38" y="-251.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-311.43C494.42,-311.43 505.41,-312.52 538.67,-312.67"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="538.46,-314.77 544.46,-312.68 538.46,-310.57 538.46,-314.77"/>
</g>
<g id="node7" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="811.75,-434.06 708.75,-434.06 708.75,-315.56 811.75,-315.56 811.75,-434.06"/>
<polygon fill="#f1efe8" stroke="none" points="708.75,-315.56 708.75,-434.06 811.75,-434.06 811.75,-315.56 708.75,-315.56"/>
<g id="a_node7_123"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="708.75,-414.81 708.75,-434.06 811.75,-434.06 811.75,-414.81 708.75,-414.81"/>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-414.81 708.75,-434.06 811.75,-434.06 811.75,-414.81 708.75,-414.81"/>
<text text-anchor="start" x="749.38" y="-421.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node7_124"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-395.56 708.75,-414.81 751.25,-414.81 751.25,-395.56 708.75,-395.56"/>
<text text-anchor="start" x="712.75" y="-402.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node7_125"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-395.56 751.25,-414.81 811.75,-414.81 811.75,-395.56 751.25,-395.56"/>
<text text-anchor="start" x="755.25" y="-401.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_126"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-376.31 708.75,-395.56 751.25,-395.56 751.25,-376.31 708.75,-376.31"/>
<text text-anchor="start" x="712.75" y="-383.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node7_127"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-376.31 751.25,-395.56 811.75,-395.56 811.75,-376.31 751.25,-376.31"/>
<text text-anchor="start" x="755.25" y="-382.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_128"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-357.06 708.75,-376.31 751.25,-376.31 751.25,-357.06 708.75,-357.06"/>
<text text-anchor="start" x="712.75" y="-362.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_129"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-357.06 751.25,-376.31 811.75,-376.31 811.75,-357.06 751.25,-357.06"/>
<text text-anchor="start" x="755.25" y="-362.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_130"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-336.31 708.75,-357.06 751.25,-357.06 751.25,-336.31 708.75,-336.31"/>
<text text-anchor="start" x="712.75" y="-342.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_131"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-336.31 751.25,-357.06 811.75,-357.06 811.75,-336.31 751.25,-336.31"/>
<text text-anchor="start" x="755.25" y="-343.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_132"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="708.75,-315.56 708.75,-336.31 751.25,-336.31 751.25,-315.56 708.75,-315.56"/>
<text text-anchor="start" x="712.75" y="-323.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node7_133"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="751.25,-315.56 751.25,-336.31 811.75,-336.31 811.75,-315.56 751.25,-315.56"/>
<text text-anchor="start" x="755.25" y="-322.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M457.75,-210.68C541.11,-210.68 579.18,-182.08 643.75,-234.81 710.74,-289.51 624.97,-416.69 701.38,-424.09"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="701,-426.18 707.09,-424.36 701.19,-421.98 701,-426.18"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M644.75,-521.81C683.59,-521.81 669.2,-579.85 643.75,-609.18 608.09,-650.28 572.15,-605 522.75,-627.81 490.53,-642.68 495.03,-678.41 465.15,-683.36"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="465.23,-681.25 459.41,-683.8 465.55,-685.43 465.23,-681.25"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M643.75,-424.06C669.93,-424.06 678.32,-424.37 701.16,-424.42"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="701.08,-426.52 707.09,-424.43 701.09,-422.32 701.08,-426.52"/>
</g>
<g id="node6" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-970.81 0,-970.81 0,-382.81 174.25,-382.81 174.25,-970.81"/>
<polygon fill="#f1efe8" stroke="none" points="0,-382.81 0,-970.81 174.25,-970.81 174.25,-382.81 0,-382.81"/>
<g id="a_node6_134"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-951.56 0,-970.81 174.25,-970.81 174.25,-951.56 0,-951.56"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-951.56 0,-970.81 174.25,-970.81 174.25,-951.56 0,-951.56"/>
<text text-anchor="start" x="68" y="-958.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node6_135"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-932.31 0,-951.56 107,-951.56 107,-932.31 0,-932.31"/>
<text text-anchor="start" x="4" y="-938.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node6_136"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-932.31 107,-951.56 174.25,-951.56 174.25,-932.31 107,-932.31"/>
<text text-anchor="start" x="111" y="-938.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_137"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-913.06 0,-932.31 107,-932.31 107,-913.06 0,-913.06"/>
<text text-anchor="start" x="4" y="-918.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node6_138"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-913.06 107,-932.31 174.25,-932.31 174.25,-913.06 107,-913.06"/>
<text text-anchor="start" x="111" y="-918.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_139"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-893.81 0,-913.06 107,-913.06 107,-893.81 0,-893.81"/>
<text text-anchor="start" x="4" y="-899.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node6_140"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-893.81 107,-913.06 174.25,-913.06 174.25,-893.81 107,-893.81"/>
<text text-anchor="start" x="111" y="-899.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node6_141"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-874.56 0,-893.81 107,-893.81 107,-874.56 0,-874.56"/>
<text text-anchor="start" x="4" y="-880.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node6_142"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-874.56 107,-893.81 174.25,-893.81 174.25,-874.56 107,-874.56"/>
<text text-anchor="start" x="111" y="-880.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node6_143"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-855.31 0,-874.56 107,-874.56 107,-855.31 0,-855.31"/>
<text text-anchor="start" x="4" y="-861.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node6_144"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-855.31 107,-874.56 174.25,-874.56 174.25,-855.31 107,-855.31"/>
<text text-anchor="start" x="111" y="-861.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_145"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-836.06 0,-855.31 107,-855.31 107,-836.06 0,-836.06"/>
<text text-anchor="start" x="4" y="-841.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node6_146"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-836.06 107,-855.31 174.25,-855.31 174.25,-836.06 107,-836.06"/>
<text text-anchor="start" x="111" y="-841.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_147"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-816.81 0,-836.06 107,-836.06 107,-816.81 0,-816.81"/>
<text text-anchor="start" x="4" y="-822.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node6_148"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-816.81 107,-836.06 174.25,-836.06 174.25,-816.81 107,-816.81"/>
<text text-anchor="start" x="111" y="-822.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_149"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-797.56 0,-816.81 107,-816.81 107,-797.56 0,-797.56"/>
<text text-anchor="start" x="4" y="-803.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node6_150"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-797.56 107,-816.81 174.25,-816.81 174.25,-797.56 107,-797.56"/>
<text text-anchor="start" x="111" y="-803.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_151"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-778.31 0,-797.56 107,-797.56 107,-778.31 0,-778.31"/>
<text text-anchor="start" x="4" y="-785.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node6_152"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-778.31 107,-797.56 174.25,-797.56 174.25,-778.31 107,-778.31"/>
<text text-anchor="start" x="111" y="-784.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_153"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-759.06 0,-778.31 107,-778.31 107,-759.06 0,-759.06"/>
<text text-anchor="start" x="4" y="-764.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node6_154"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-759.06 107,-778.31 174.25,-778.31 174.25,-759.06 107,-759.06"/>
<text text-anchor="start" x="111" y="-764.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_155"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-738.31 0,-759.06 107,-759.06 107,-738.31 0,-738.31"/>
<text text-anchor="start" x="4" y="-744.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node6_156"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-738.31 107,-759.06 174.25,-759.06 174.25,-738.31 107,-738.31"/>
<text text-anchor="start" x="111" y="-745.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_157"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-717.56 0,-738.31 107,-738.31 107,-717.56 0,-717.56"/>
<text text-anchor="start" x="4" y="-724.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node6_158"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-717.56 107,-738.31 174.25,-738.31 174.25,-717.56 107,-717.56"/>
<text text-anchor="start" x="111" y="-724.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node6_159"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-698.31 0,-717.56 107,-717.56 107,-698.31 0,-698.31"/>
<text text-anchor="start" x="4" y="-704.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node6_160"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-698.31 107,-717.56 174.25,-717.56 174.25,-698.31 107,-698.31"/>
<text text-anchor="start" x="111" y="-704.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_161"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-679.06 0,-698.31 107,-698.31 107,-679.06 0,-679.06"/>
<text text-anchor="start" x="4" y="-685.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node6_162"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-679.06 107,-698.31 174.25,-698.31 174.25,-679.06 107,-679.06"/>
<text text-anchor="start" x="111" y="-684.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_163"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-658.31 0,-679.06 107,-679.06 107,-658.31 0,-658.31"/>
<text text-anchor="start" x="4" y="-664.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node6_164"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-658.31 107,-679.06 174.25,-679.06 174.25,-658.31 107,-658.31"/>
<text text-anchor="start" x="111" y="-665.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_165"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-639.06 0,-658.31 107,-658.31 107,-639.06 0,-639.06"/>
<text text-anchor="start" x="4" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node6_166"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-639.06 107,-658.31 174.25,-658.31 174.25,-639.06 107,-639.06"/>
<text text-anchor="start" x="111" y="-644.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_167"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-619.81 0,-639.06 107,-639.06 107,-619.81 0,-619.81"/>
<text text-anchor="start" x="4" y="-626.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node6_168"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-619.81 107,-639.06 174.25,-639.06 174.25,-619.81 107,-619.81"/>
<text text-anchor="start" x="111" y="-625.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_169"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-600.56 0,-619.81 107,-619.81 107,-600.56 0,-600.56"/>
<text text-anchor="start" x="4" y="-607.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node6_170"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-600.56 107,-619.81 174.25,-619.81 174.25,-600.56 107,-600.56"/>
<text text-anchor="start" x="111" y="-606.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_171"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-581.31 0,-600.56 107,-600.56 107,-581.31 0,-581.31"/>
<text text-anchor="start" x="4" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node6_172"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-581.31 107,-600.56 174.25,-600.56 174.25,-581.31 107,-581.31"/>
<text text-anchor="start" x="111" y="-587.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_173"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-562.06 0,-581.31 107,-581.31 107,-562.06 0,-562.06"/>
<text text-anchor="start" x="4" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node6_174"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-562.06 107,-581.31 174.25,-581.31 174.25,-562.06 107,-562.06"/>
<text text-anchor="start" x="111" y="-567.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_175"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-541.31 0,-562.06 107,-562.06 107,-541.31 0,-541.31"/>
<text text-anchor="start" x="4" y="-547.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node6_176"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-541.31 107,-562.06 174.25,-562.06 174.25,-541.31 107,-541.31"/>
<text text-anchor="start" x="111" y="-548.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_177"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-520.56 0,-541.31 107,-541.31 107,-520.56 0,-520.56"/>
<text text-anchor="start" x="4" y="-527.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node6_178"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-520.56 107,-541.31 174.25,-541.31 174.25,-520.56 107,-520.56"/>
<text text-anchor="start" x="111" y="-527.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node6_179"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-501.31 0,-520.56 107,-520.56 107,-501.31 0,-501.31"/>
<text text-anchor="start" x="4" y="-508.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_180"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-501.31 107,-520.56 174.25,-520.56 174.25,-501.31 107,-501.31"/>
<text text-anchor="start" x="111" y="-507.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_181"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-482.06 0,-501.31 107,-501.31 107,-482.06 0,-482.06"/>
<text text-anchor="start" x="4" y="-487.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_182"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-482.06 107,-501.31 174.25,-501.31 174.25,-482.06 107,-482.06"/>
<text text-anchor="start" x="111" y="-487.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_183"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-462.81 0,-482.06 107,-482.06 107,-462.81 0,-462.81"/>
<text text-anchor="start" x="4" y="-468.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node6_184"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-462.81 107,-482.06 174.25,-482.06 174.25,-462.81 107,-462.81"/>
<text text-anchor="start" x="111" y="-468.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_185"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-442.06 0,-462.81 107,-462.81 107,-442.06 0,-442.06"/>
<text text-anchor="start" x="4" y="-448.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node6_186"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-442.06 107,-462.81 174.25,-462.81 174.25,-442.06 107,-442.06"/>
<text text-anchor="start" x="111" y="-449.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node6_187"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-422.81 0,-442.06 107,-442.06 107,-422.81 0,-422.81"/>
<text text-anchor="start" x="4" y="-428.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node6_188"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-422.81 107,-442.06 174.25,-442.06 174.25,-422.81 107,-422.81"/>
<text text-anchor="start" x="111" y="-428.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_189"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-402.06 0,-422.81 107,-422.81 107,-402.06 0,-402.06"/>
<text text-anchor="start" x="4" y="-408.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node6_190"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-402.06 107,-422.81 174.25,-422.81 174.25,-402.06 107,-402.06"/>
<text text-anchor="start" x="111" y="-409.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_191"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-382.81 0,-402.06 107,-402.06 107,-382.81 0,-382.81"/>
<text text-anchor="start" x="4" y="-388.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node6_192"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-382.81 107,-402.06 174.25,-402.06 174.25,-382.81 107,-382.81"/>
<text text-anchor="start" x="111" y="-388.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-727.93C355.58,-727.93 400.92,-727.81 582.25,-727.81 582.25,-727.81 582.25,-727.81 761.25,-727.81 884.82,-727.81 910.24,-687.06 1029.25,-653.81 1055.57,-646.45 1062.95,-637.26 1086.7,-635.67"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.66,-637.78 1092.59,-635.49 1086.52,-633.58 1086.66,-637.78"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-530.93C245.39,-530.93 171.29,-672.79 231.66,-683.32"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-685.41 237.59,-683.8 231.78,-681.22 231.44,-685.41"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-452.43C264.22,-452.43 172.7,-113.36 239.25,-52.81 352.26,50.02 429.46,-29.81 582.25,-29.81 582.25,-29.81 582.25,-29.81 954,-29.81 1078.15,-29.81 1135.47,-4.2 1227.25,-87.81 1297.04,-151.39 1200.73,-288.54 1284.73,-295.99"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.5,-298.08 1290.59,-296.24 1284.68,-293.89 1284.5,-298.08"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M811.75,-346.68C840.64,-346.68 847.86,-346.78 876.75,-346.81 944.53,-346.87 961.78,-353.23 1029.25,-346.81 1145.19,-335.78 1172.09,-297.98 1284.71,-296.36"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.6,-298.46 1290.59,-296.32 1284.57,-294.26 1284.6,-298.46"/>
</g>
<g id="node8" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1029.25,-336.06 876.75,-336.06 876.75,-63.56 1029.25,-63.56 1029.25,-336.06"/>
<polygon fill="#f1efe8" stroke="none" points="876.75,-63.56 876.75,-336.06 1029.25,-336.06 1029.25,-63.56 876.75,-63.56"/>
<g id="a_node8_193"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="876.75,-316.81 876.75,-336.06 1029.25,-336.06 1029.25,-316.81 876.75,-316.81"/>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-316.81 876.75,-336.06 1029.25,-336.06 1029.25,-316.81 876.75,-316.81"/>
<text text-anchor="start" x="935.75" y="-323.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_194"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-297.56 876.75,-316.81 962,-316.81 962,-297.56 876.75,-297.56"/>
<text text-anchor="start" x="880.75" y="-303.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node8_195"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-297.56 962,-316.81 1029.25,-316.81 1029.25,-297.56 962,-297.56"/>
<text text-anchor="start" x="966" y="-303.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_196"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-278.31 876.75,-297.56 962,-297.56 962,-278.31 876.75,-278.31"/>
<text text-anchor="start" x="880.75" y="-284.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node8_197"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-278.31 962,-297.56 1029.25,-297.56 1029.25,-278.31 962,-278.31"/>
<text text-anchor="start" x="966" y="-284.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node8_198"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-259.06 876.75,-278.31 962,-278.31 962,-259.06 876.75,-259.06"/>
<text text-anchor="start" x="880.75" y="-265.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node8_199"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-259.06 962,-278.31 1029.25,-278.31 1029.25,-259.06 962,-259.06"/>
<text text-anchor="start" x="966" y="-264.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_200"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-239.81 876.75,-259.06 962,-259.06 962,-239.81 876.75,-239.81"/>
<text text-anchor="start" x="880.75" y="-246.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node8_201"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-239.81 962,-259.06 1029.25,-259.06 1029.25,-239.81 962,-239.81"/>
<text text-anchor="start" x="966" y="-245.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_202"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-219.06 876.75,-239.81 962,-239.81 962,-219.06 876.75,-219.06"/>
<text text-anchor="start" x="880.75" y="-225.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node8_203"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-219.06 962,-239.81 1029.25,-239.81 1029.25,-219.06 962,-219.06"/>
<text text-anchor="start" x="966" y="-226.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node8_204"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-199.81 876.75,-219.06 962,-219.06 962,-199.81 876.75,-199.81"/>
<text text-anchor="start" x="880.75" y="-205.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node8_205"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-199.81 962,-219.06 1029.25,-219.06 1029.25,-199.81 962,-199.81"/>
<text text-anchor="start" x="966" y="-205.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_206"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-180.56 876.75,-199.81 962,-199.81 962,-180.56 876.75,-180.56"/>
<text text-anchor="start" x="880.75" y="-186.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node8_207"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-180.56 962,-199.81 1029.25,-199.81 1029.25,-180.56 962,-180.56"/>
<text text-anchor="start" x="966" y="-186.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_208"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-161.31 876.75,-180.56 962,-180.56 962,-161.31 876.75,-161.31"/>
<text text-anchor="start" x="880.75" y="-167.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node8_209"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-161.31 962,-180.56 1029.25,-180.56 1029.25,-161.31 962,-161.31"/>
<text text-anchor="start" x="966" y="-167.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_210"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-142.06 876.75,-161.31 962,-161.31 962,-142.06 876.75,-142.06"/>
<text text-anchor="start" x="880.75" y="-147.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node8_211"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-142.06 962,-161.31 1029.25,-161.31 1029.25,-142.06 962,-142.06"/>
<text text-anchor="start" x="966" y="-147.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_212"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-122.81 876.75,-142.06 962,-142.06 962,-122.81 876.75,-122.81"/>
<text text-anchor="start" x="880.75" y="-128.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node8_213"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-122.81 962,-142.06 1029.25,-142.06 1029.25,-122.81 962,-122.81"/>
<text text-anchor="start" x="966" y="-128.56" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_214"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-103.56 876.75,-122.81 962,-122.81 962,-103.56 876.75,-103.56"/>
<text text-anchor="start" x="880.75" y="-109.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node8_215"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-103.56 962,-122.81 1029.25,-122.81 1029.25,-103.56 962,-103.56"/>
<text text-anchor="start" x="966" y="-109.31" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_216"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-84.31 876.75,-103.56 962,-103.56 962,-84.31 876.75,-84.31"/>
<text text-anchor="start" x="880.75" y="-90.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_217"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-84.31 962,-103.56 1029.25,-103.56 1029.25,-84.31 962,-84.31"/>
<text text-anchor="start" x="966" y="-90.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_218"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="876.75,-63.56 876.75,-84.31 962,-84.31 962,-63.56 876.75,-63.56"/>
<text text-anchor="start" x="880.75" y="-70.06" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_219"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="962,-63.56 962,-84.31 1029.25,-84.31 1029.25,-63.56 962,-63.56"/>
<text text-anchor="start" x="966" y="-70.81" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M811.75,-325.93C837.93,-325.93 846.32,-326.34 869.16,-326.42"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="869.08,-328.52 875.09,-326.43 869.09,-324.32 869.08,-328.52"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1029.25,-229.43C1209.49,-229.43 919.63,-624.41 1087.02,-635.21"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1086.52,-637.29 1092.59,-635.38 1086.65,-633.09 1086.52,-637.29"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1029.25,-73.93C1179.78,-73.93 1140.56,-288.99 1284.79,-296.13"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1284.54,-298.22 1290.59,-296.27 1284.64,-294.02 1284.54,-298.22"/>
</g>
</g>
</svg>
</figure>

Ein Klick auf den Kopf eines Abschnitts führt zu seinem Abschnitt weiter unten, ein Klick auf ein Feld zu seiner Zeile in der Feldtabelle; anderswo öffnet sich das Diagramm vergrößert. Als Datei: [inventory-schema.svg](../assets/diagrams/inventory-schema.svg).

## Konventionen

**IDs.** Einträge haben eine ID als Schlüssel: Kleinbuchstaben, Ziffern und Bindestriche, am Anfang ein Buchstabe oder eine Ziffer (`grammi`, `realtox-dus`, `home-main`). Ein Verweisfeld enthält eine solche ID und muss einen vorhandenen Eintrag des richtigen Abschnitts nennen.

**Pflicht und optional.** Ein Feld ist optional, wenn die Tabelle nicht *Pflicht* sagt. Fehlende optionale Felder füllt die abgeleitete Sicht auf – mit dem Standardwert aus der Tabelle, sonst `null` oder `[]` –, damit ein Nutzer der Daten nie `or` schreiben muss.

**Unbekannte Felder sind Fehler.** Ein Tippfehler (`critcality`) wird mit der Liste der bekannten Felder gemeldet, im Editor sofort und in `nix flake check`.

**Eine Richtung.** Jede Beziehung steht dort, wo sie beginnt (`hosts.runsOn`, `services.dependsOn`, `hosts.contracts`); die Gegenrichtung (`guests`, `neededBy`, `covers`) wird abgeleitet.

**Formate.** Strings mit einem Format werden dagegen geprüft:

| Format | Beispiel | Verwendet von |
| --- | --- | --- |
| IPv4-Adresse | `192.0.2.10` | `interfaces.<name>.ipv4.address`, `dhcpPool` |
| IPv4-Präfix (ohne Host-Bits) | `192.0.2.0/24` | `networks.ipv4` |
| IPv6-Präfix | `2001:db8:1::/64` | `networks.ipv6` |
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
| <span id="sites-kind"></span>`kind` | eins von `residential` `hackerspace` `datacenter` | Pflicht | Kind of place. |
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
      ]
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

Regeln über das Schema hinaus: mindestens ein Anschluss, der primäre zuerst; an jeder Site steht etwas.

## networks { #networks }

Ein Layer-2-Netz mit seinem IPv4-Präfix.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="networks-dhcppool"></span>`dhcpPool` | Objekt |  | Range the DHCP server hands out dynamically; static addresses must lie outside it. |
| <span id="networks-dhcppool-end"></span>`dhcpPool.end` | String: an IPv4 address | Pflicht | Last address of the pool. |
| <span id="networks-dhcppool-start"></span>`dhcpPool.start` | String: an IPv4 address | Pflicht | First address of the pool. |
| <span id="networks-dhcpserver"></span>`dhcpServer` | ID aus [hosts](#hosts) |  | The host serving DHCP for IPv4 here; it needs an interface in this network. |
| <span id="networks-ipv4"></span>`ipv4` | String: an IPv4 prefix like 192.0.2.0/24 |  | IPv4 prefix. |
| <span id="networks-ipv6"></span>`ipv6` | String: an IPv6 prefix like 2001:db8::/64 |  | IPv6 prefix, when it is fixed (ULA or static GUA). |
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
      "ipv6": "2001:db8:1::/64",
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

Regeln über das Schema hinaus: Das Präfix hat keine Host-Bits; der Pool liegt darin, Start vor Ende, und braucht `ipv4` und `dhcpServer`; der DHCP-Server steht an der Site und hat ein Interface im Netz; eine VLAN-ID nur einmal pro Site.

## hosts { #hosts }

Jedes Gerät mit einer Adresse, die zählt – von diesem Flake verwaltet oder nicht.

| Feld | Typ | | Bedeutung (aus dem Schema, englisch) |
| --- | --- | --- | --- |
| <span id="hosts-availability"></span>`availability` | eins von `always-on` `intermittent` | Standard `"always-on"` | intermittent: being offline is normal (a laptop) and is not an incident. |
| <span id="hosts-contracts"></span>`contracts` | Liste von ID aus [contracts](#contracts), ohne Duplikate |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="hosts-criticality"></span>`criticality` | eins von `core` `service` `lab` | Standard `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="hosts-inside"></span>`inside` | ID aus [hosts](#hosts) |  | Physically built into another device, e.g. a PCIe KVM card in its host. |
| <span id="hosts-interfaces"></span>`interfaces` | Objekt: Name → Objekt |  | Network interfaces by name (as the OS calls them; for an appliance any label like lan/wan). A VLAN interface (eno1.10) is an entry of its own. |
| <span id="hosts-interfaces-name-ipv4"></span>`interfaces.<name>.ipv4` | Objekt |  | IPv4 addressing of this interface in its network. |
| <span id="hosts-interfaces-name-ipv4-address"></span>`interfaces.<name>.ipv4.address` | String: an IPv4 address |  | The address - required for reserved and static. |
| <span id="hosts-interfaces-name-ipv4-mode"></span>`interfaces.<name>.ipv4.mode` | eins von `reserved` `static` `dhcp` | Pflicht | reserved: fixed DHCP lease by MAC; static: configured on the device; dhcp: dynamic. |
| <span id="hosts-interfaces-name-linklocal"></span>`interfaces.<name>.linkLocal` | String: eui64, stable-privacy, random or an fe80:: address |  | How the IPv6 link-local address is formed: eui64 (computed from mac), stable-privacy (RFC 7217), random - or the fixed fe80:: address itself. |
| <span id="hosts-interfaces-name-mac"></span>`interfaces.<name>.mac` | String: a lower-case MAC address like aa:bb:cc:dd:ee:ff |  | Hardware address, lower case. |
| <span id="hosts-interfaces-name-medium"></span>`interfaces.<name>.medium` | eins von `ethernet` `wifi` |  | Physical medium. |
| <span id="hosts-interfaces-name-network"></span>`interfaces.<name>.network` | ID aus [networks](#networks) |  | The network this interface is in. |
| <span id="hosts-interfaces-name-note"></span>`interfaces.<name>.note` | String |  | Free text: anything worth knowing that has no field of its own. |
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
          "medium": "ethernet",
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
          "medium": "wifi",
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
      ]
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
      "ipv6": "2001:db8:1::/64",
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
          "medium": "ethernet",
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
          "medium": "wifi",
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
