# Inventory schema

`inventory.json` follows a fixed format: eight sections, each an object of entries keyed by id, every field with a type, some of them references into another section. This page is the complete reference of that format – every field with its type, whether it is required, its default and its meaning, an example per section and a whole example inventory. *What* the inventory is for, how it is validated and what is derived from it is on [Inventory](inventory.md).

The format is defined once, in `spec` in `inventory.nix`. Everything on this page that describes a field is generated from it, so it cannot drift from what the validator checks:

| Generated | From | Kept fresh by |
| --- | --- | --- |
| `inventory.schema.json` – JSON Schema for the editor | `spec` | `just inventory-schema`, `checks.inventory-schema` |
| The field tables below | `inventory.schema.json` | the docs build (`docs/gen-reference.py`) |
| The diagram of all fields | `spec` | `just inventory-diagram`, `checks.inventory-diagram` |
| The examples below | `docs/inventory-example.json` | the docs build; a test (`tests/inventory.nix`) keeps the file valid |

## Overview

The arrows point from the field that holds the reference to the section it names. A section's references into itself are noted in its box (↺). Each box leads to its section below.

<figure class="nx-diagram">
<svg viewBox="0 0 680 416" role="img" aria-label="The eight sections of inventory.json and the fields that refer from one to another" xmlns="http://www.w3.org/2000/svg">
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
<a data-target="owners" tabindex="0" role="link" class="nx-gray"><rect x="20" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="44" text-anchor="middle">owners</text><text class="nx-s" x="100" y="62" text-anchor="middle">who administers</text></a>
<a data-target="hosts" tabindex="0" role="link" class="nx-gray"><rect x="260" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="44" text-anchor="middle">hosts</text><text class="nx-s" x="340" y="62" text-anchor="middle">↺ runsOn, power …</text></a>
<a data-target="services" tabindex="0" role="link" class="nx-purple"><rect x="500" y="20" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="44" text-anchor="middle">services</text><text class="nx-s" x="580" y="62" text-anchor="middle">↺ dependsOn, uses …</text></a>
<a data-target="networks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="194" text-anchor="middle">networks</text><text class="nx-s" x="100" y="212" text-anchor="middle">layer 2 + prefix</text></a>
<a data-target="sites" tabindex="0" role="link" class="nx-gray"><rect x="260" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="194" text-anchor="middle">sites</text><text class="nx-s" x="340" y="212" text-anchor="middle">where things stand</text></a>
<a data-target="contracts" tabindex="0" role="link" class="nx-coral"><rect x="500" y="170" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="580" y="194" text-anchor="middle">contracts</text><text class="nx-s" x="580" y="212" text-anchor="middle">what is paid</text></a>
<a data-target="uplinks" tabindex="0" role="link" class="nx-gray"><rect x="20" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="100" y="344" text-anchor="middle">uplinks</text><text class="nx-s" x="100" y="362" text-anchor="middle">internet lines</text></a>
<a data-target="providers" tabindex="0" role="link" class="nx-coral"><rect x="260" y="320" width="160" height="56" rx="8" stroke-width="1"/><text class="nx-t" x="340" y="344" text-anchor="middle">providers</text><text class="nx-s" x="340" y="362" text-anchor="middle">companies, clubs</text></a>
</svg>
</figure>

## All fields at a glance

Every section with all its fields – **bold** ones are required, nested objects are spelled out (`unlock.methods`, `endpoints[].fqdn`, `interfaces.<name>.mac`), and every reference field has its arrow (references inside a section only in the type column: `→ hosts`).

<figure class="nx-diagram nx-diagram-wide">
<svg
 viewBox="0.00 0.00 1389.00 1115.86" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<g id="graph0" class="graph" transform="scale(1 1) rotate(0) translate(4 1111.86)">
<title>inventory</title>
<g id="node1" class="node">
<title>contracts</title>
<polygon fill="#f1efe8" stroke="none" points="1243.75,-715.11 1110.75,-715.11 1110.75,-482.61 1243.75,-482.61 1243.75,-715.11"/>
<polygon fill="#f1efe8" stroke="none" points="1110.75,-482.61 1110.75,-715.11 1243.75,-715.11 1243.75,-482.61 1110.75,-482.61"/>
<g id="a_node1_0"><a data-target="contracts" tabindex="0" role="link"><title>contracts</title>
<polygon fill="#d3d1c7" stroke="none" points="1110.75,-695.86 1110.75,-715.11 1243.75,-715.11 1243.75,-695.86 1110.75,-695.86"/>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-695.86 1110.75,-715.11 1243.75,-715.11 1243.75,-695.86 1110.75,-695.86"/>
<text text-anchor="start" x="1155.88" y="-702.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node1_1"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-676.61 1110.75,-695.86 1183.25,-695.86 1183.25,-676.61 1110.75,-676.61"/>
<text text-anchor="start" x="1114.75" y="-682.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost</text>
</a>
</g>
<g id="a_node1_2"><a data-target="contracts-cost" tabindex="0" role="link"><title>contracts.cost</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-676.61 1183.25,-695.86 1243.75,-695.86 1243.75,-676.61 1183.25,-676.61"/>
<text text-anchor="start" x="1187.25" y="-682.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node1_3"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-657.36 1110.75,-676.61 1183.25,-676.61 1183.25,-657.36 1110.75,-657.36"/>
<text text-anchor="start" x="1114.75" y="-664.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.amount</text>
</a>
</g>
<g id="a_node1_4"><a data-target="contracts-cost-amount" tabindex="0" role="link"><title>contracts.cost.amount</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-657.36 1183.25,-676.61 1243.75,-676.61 1243.75,-657.36 1183.25,-657.36"/>
<text text-anchor="start" x="1187.25" y="-663.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_5"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-638.11 1110.75,-657.36 1183.25,-657.36 1183.25,-638.11 1110.75,-638.11"/>
<text text-anchor="start" x="1114.75" y="-644.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.currency</text>
</a>
</g>
<g id="a_node1_6"><a data-target="contracts-cost-currency" tabindex="0" role="link"><title>contracts.cost.currency</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-638.11 1183.25,-657.36 1243.75,-657.36 1243.75,-638.11 1183.25,-638.11"/>
<text text-anchor="start" x="1187.25" y="-643.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_7"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-618.86 1110.75,-638.11 1183.25,-638.11 1183.25,-618.86 1110.75,-618.86"/>
<text text-anchor="start" x="1114.75" y="-624.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">cost.dueMonth</text>
</a>
</g>
<g id="a_node1_8"><a data-target="contracts-cost-duemonth" tabindex="0" role="link"><title>contracts.cost.dueMonth</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-618.86 1183.25,-638.11 1243.75,-638.11 1243.75,-618.86 1183.25,-618.86"/>
<text text-anchor="start" x="1187.25" y="-624.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node1_9"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-599.61 1110.75,-618.86 1183.25,-618.86 1183.25,-599.61 1110.75,-599.61"/>
<text text-anchor="start" x="1114.75" y="-606.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">cost.period</text>
</a>
</g>
<g id="a_node1_10"><a data-target="contracts-cost-period" tabindex="0" role="link"><title>contracts.cost.period</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-599.61 1183.25,-618.86 1243.75,-618.86 1243.75,-599.61 1183.25,-599.61"/>
<text text-anchor="start" x="1187.25" y="-605.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node1_11"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-580.36 1110.75,-599.61 1183.25,-599.61 1183.25,-580.36 1110.75,-580.36"/>
<text text-anchor="start" x="1114.75" y="-586.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node1_12"><a data-target="contracts-note" tabindex="0" role="link"><title>contracts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-580.36 1183.25,-599.61 1243.75,-599.61 1243.75,-580.36 1183.25,-580.36"/>
<text text-anchor="start" x="1187.25" y="-586.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_13"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-561.11 1110.75,-580.36 1183.25,-580.36 1183.25,-561.11 1110.75,-561.11"/>
<text text-anchor="start" x="1114.75" y="-566.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">notice</text>
</a>
</g>
<g id="a_node1_14"><a data-target="contracts-notice" tabindex="0" role="link"><title>contracts.notice</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-561.11 1183.25,-580.36 1243.75,-580.36 1243.75,-561.11 1183.25,-561.11"/>
<text text-anchor="start" x="1187.25" y="-566.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_15"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-541.86 1110.75,-561.11 1183.25,-561.11 1183.25,-541.86 1110.75,-541.86"/>
<text text-anchor="start" x="1114.75" y="-547.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">product</text>
</a>
</g>
<g id="a_node1_16"><a data-target="contracts-product" tabindex="0" role="link"><title>contracts.product</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-541.86 1183.25,-561.11 1243.75,-561.11 1243.75,-541.86 1183.25,-541.86"/>
<text text-anchor="start" x="1187.25" y="-547.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_17"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-521.11 1110.75,-541.86 1183.25,-541.86 1183.25,-521.11 1110.75,-521.11"/>
<text text-anchor="start" x="1114.75" y="-528.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node1_18"><a data-target="contracts-provider" tabindex="0" role="link"><title>contracts.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-521.11 1183.25,-541.86 1243.75,-541.86 1243.75,-521.11 1183.25,-521.11"/>
<text text-anchor="start" x="1187.25" y="-528.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node1_19"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-501.86 1110.75,-521.11 1183.25,-521.11 1183.25,-501.86 1110.75,-501.86"/>
<text text-anchor="start" x="1114.75" y="-507.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">renews</text>
</a>
</g>
<g id="a_node1_20"><a data-target="contracts-renews" tabindex="0" role="link"><title>contracts.renews</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-501.86 1183.25,-521.11 1243.75,-521.11 1243.75,-501.86 1183.25,-501.86"/>
<text text-anchor="start" x="1187.25" y="-507.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node1_21"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1110.75,-482.61 1110.75,-501.86 1183.25,-501.86 1183.25,-482.61 1110.75,-482.61"/>
<text text-anchor="start" x="1114.75" y="-488.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">since</text>
</a>
</g>
<g id="a_node1_22"><a data-target="contracts-since" tabindex="0" role="link"><title>contracts.since</title>
<polygon fill="none" stroke="#b4b2a9" points="1183.25,-482.61 1183.25,-501.86 1243.75,-501.86 1243.75,-482.61 1183.25,-482.61"/>
<text text-anchor="start" x="1187.25" y="-488.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="node5" class="node">
<title>providers</title>
<polygon fill="#f1efe8" stroke="none" points="1381,-308.98 1308.75,-308.98 1308.75,-212.73 1381,-212.73 1381,-308.98"/>
<polygon fill="#f1efe8" stroke="none" points="1308.75,-212.73 1308.75,-308.98 1381,-308.98 1381,-212.73 1308.75,-212.73"/>
<g id="a_node5_23"><a data-target="providers" tabindex="0" role="link"><title>providers</title>
<polygon fill="#d3d1c7" stroke="none" points="1308.75,-289.73 1308.75,-308.98 1381,-308.98 1381,-289.73 1308.75,-289.73"/>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-289.73 1308.75,-308.98 1381,-308.98 1381,-289.73 1308.75,-289.73"/>
<text text-anchor="start" x="1322.75" y="-296.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">providers</text>
</a>
</g>
<g id="a_node5_24"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-270.48 1308.75,-289.73 1349,-289.73 1349,-270.48 1308.75,-270.48"/>
<text text-anchor="start" x="1312.75" y="-276.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node5_25"><a data-target="providers-contact" tabindex="0" role="link"><title>providers.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-270.48 1349,-289.73 1381,-289.73 1381,-270.48 1349,-270.48"/>
<text text-anchor="start" x="1353" y="-276.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_26"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-251.23 1308.75,-270.48 1349,-270.48 1349,-251.23 1308.75,-251.23"/>
<text text-anchor="start" x="1312.75" y="-257.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node5_27"><a data-target="providers-name" tabindex="0" role="link"><title>providers.name</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-251.23 1349,-270.48 1381,-270.48 1381,-251.23 1349,-251.23"/>
<text text-anchor="start" x="1353" y="-256.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_28"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-231.98 1308.75,-251.23 1349,-251.23 1349,-231.98 1308.75,-231.98"/>
<text text-anchor="start" x="1312.75" y="-237.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node5_29"><a data-target="providers-note" tabindex="0" role="link"><title>providers.note</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-231.98 1349,-251.23 1381,-251.23 1381,-231.98 1349,-231.98"/>
<text text-anchor="start" x="1353" y="-237.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node5_30"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1308.75,-212.73 1308.75,-231.98 1349,-231.98 1349,-212.73 1308.75,-212.73"/>
<text text-anchor="start" x="1312.75" y="-218.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">url</text>
</a>
</g>
<g id="a_node5_31"><a data-target="providers-url" tabindex="0" role="link"><title>providers.url</title>
<polygon fill="none" stroke="#b4b2a9" points="1349,-212.73 1349,-231.98 1381,-231.98 1381,-212.73 1349,-212.73"/>
<text text-anchor="start" x="1353" y="-218.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge1" class="edge">
<title>contracts:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1243.75,-531.48C1348.27,-531.48 1208.75,-310.55 1301.35,-299.76"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.21,-301.88 1307.09,-299.45 1300.98,-297.68 1301.21,-301.88"/>
</g>
<g id="node2" class="node">
<title>hosts</title>
<polygon fill="#f1efe8" stroke="none" points="474.25,-830.98 239.25,-830.98 239.25,-66.73 474.25,-66.73 474.25,-830.98"/>
<polygon fill="#f1efe8" stroke="none" points="239.25,-66.73 239.25,-830.98 474.25,-830.98 474.25,-66.73 239.25,-66.73"/>
<g id="a_node2_32"><a data-target="hosts" tabindex="0" role="link"><title>hosts</title>
<polygon fill="#d3d1c7" stroke="none" points="239.25,-811.73 239.25,-830.98 474.25,-830.98 474.25,-811.73 239.25,-811.73"/>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-811.73 239.25,-830.98 474.25,-830.98 474.25,-811.73 239.25,-811.73"/>
<text text-anchor="start" x="344" y="-818.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node2_33"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-792.48 239.25,-811.73 404,-811.73 404,-792.48 239.25,-792.48"/>
<text text-anchor="start" x="243.25" y="-798.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">availability</text>
</a>
</g>
<g id="a_node2_34"><a data-target="hosts-availability" tabindex="0" role="link"><title>hosts.availability</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-792.48 404,-811.73 474.25,-811.73 474.25,-792.48 404,-792.48"/>
<text text-anchor="start" x="408" y="-798.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_35"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-771.73 239.25,-792.48 404,-792.48 404,-771.73 239.25,-771.73"/>
<text text-anchor="start" x="243.25" y="-778.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node2_36"><a data-target="hosts-contracts" tabindex="0" role="link"><title>hosts.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-771.73 404,-792.48 474.25,-792.48 474.25,-771.73 404,-771.73"/>
<text text-anchor="start" x="408" y="-778.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node2_37"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-752.48 239.25,-771.73 404,-771.73 404,-752.48 239.25,-752.48"/>
<text text-anchor="start" x="243.25" y="-758.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node2_38"><a data-target="hosts-criticality" tabindex="0" role="link"><title>hosts.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-752.48 404,-771.73 474.25,-771.73 474.25,-752.48 404,-752.48"/>
<text text-anchor="start" x="408" y="-758.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_39"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-731.73 239.25,-752.48 404,-752.48 404,-731.73 239.25,-731.73"/>
<text text-anchor="start" x="243.25" y="-738.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">inside</text>
</a>
</g>
<g id="a_node2_40"><a data-target="hosts-inside" tabindex="0" role="link"><title>hosts.inside</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-731.73 404,-752.48 474.25,-752.48 474.25,-731.73 404,-731.73"/>
<text text-anchor="start" x="408" y="-738.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_41"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-712.48 239.25,-731.73 404,-731.73 404,-712.48 239.25,-712.48"/>
<text text-anchor="start" x="243.25" y="-718.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces</text>
</a>
</g>
<g id="a_node2_42"><a data-target="hosts-interfaces" tabindex="0" role="link"><title>hosts.interfaces</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-712.48 404,-731.73 474.25,-731.73 474.25,-712.48 404,-712.48"/>
<text text-anchor="start" x="408" y="-718.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">{name: object}</text>
</a>
</g>
<g id="a_node2_43"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-693.23 239.25,-712.48 404,-712.48 404,-693.23 239.25,-693.23"/>
<text text-anchor="start" x="243.25" y="-698.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.connector</text>
</a>
</g>
<g id="a_node2_44"><a data-target="hosts-interfaces-name-connector" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.connector</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-693.23 404,-712.48 474.25,-712.48 474.25,-693.23 404,-693.23"/>
<text text-anchor="start" x="408" y="-698.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_45"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-673.98 239.25,-693.23 404,-693.23 404,-673.98 239.25,-673.98"/>
<text text-anchor="start" x="243.25" y="-679.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4</text>
</a>
</g>
<g id="a_node2_46"><a data-target="hosts-interfaces-name-ipv4" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-673.98 404,-693.23 474.25,-693.23 474.25,-673.98 404,-673.98"/>
<text text-anchor="start" x="408" y="-679.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_47"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-654.73 239.25,-673.98 404,-673.98 404,-654.73 239.25,-654.73"/>
<text text-anchor="start" x="243.25" y="-660.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.address</text>
</a>
</g>
<g id="a_node2_48"><a data-target="hosts-interfaces-name-ipv4-address" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.address</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-654.73 404,-673.98 474.25,-673.98 474.25,-654.73 404,-654.73"/>
<text text-anchor="start" x="408" y="-660.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_49"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-635.48 239.25,-654.73 404,-654.73 404,-635.48 239.25,-635.48"/>
<text text-anchor="start" x="243.25" y="-642.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.ipv4.mode</text>
</a>
</g>
<g id="a_node2_50"><a data-target="hosts-interfaces-name-ipv4-mode" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.ipv4.mode</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-635.48 404,-654.73 474.25,-654.73 474.25,-635.48 404,-635.48"/>
<text text-anchor="start" x="408" y="-641.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_51"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-616.23 239.25,-635.48 404,-635.48 404,-616.23 239.25,-616.23"/>
<text text-anchor="start" x="243.25" y="-621.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.linkLocal</text>
</a>
</g>
<g id="a_node2_52"><a data-target="hosts-interfaces-name-linklocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.linkLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-616.23 404,-635.48 474.25,-635.48 474.25,-616.23 404,-616.23"/>
<text text-anchor="start" x="408" y="-621.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_53"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-596.98 239.25,-616.23 404,-616.23 404,-596.98 239.25,-596.98"/>
<text text-anchor="start" x="243.25" y="-602.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.mac</text>
</a>
</g>
<g id="a_node2_54"><a data-target="hosts-interfaces-name-mac" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.mac</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-596.98 404,-616.23 474.25,-616.23 474.25,-596.98 404,-596.98"/>
<text text-anchor="start" x="408" y="-602.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_55"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-577.73 239.25,-596.98 404,-596.98 404,-577.73 239.25,-577.73"/>
<text text-anchor="start" x="243.25" y="-583.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.macLocal</text>
</a>
</g>
<g id="a_node2_56"><a data-target="hosts-interfaces-name-maclocal" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.macLocal</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-577.73 404,-596.98 474.25,-596.98 474.25,-577.73 404,-577.73"/>
<text text-anchor="start" x="408" y="-583.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_57"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-558.48 239.25,-577.73 404,-577.73 404,-558.48 239.25,-558.48"/>
<text text-anchor="start" x="243.25" y="-564.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.medium</text>
</a>
</g>
<g id="a_node2_58"><a data-target="hosts-interfaces-name-medium" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-558.48 404,-577.73 474.25,-577.73 474.25,-558.48 404,-558.48"/>
<text text-anchor="start" x="408" y="-564.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_59"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-539.23 239.25,-558.48 404,-558.48 404,-539.23 239.25,-539.23"/>
<text text-anchor="start" x="243.25" y="-544.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module</text>
</a>
</g>
<g id="a_node2_60"><a data-target="hosts-interfaces-name-module" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-539.23 404,-558.48 474.25,-558.48 474.25,-539.23 404,-539.23"/>
<text text-anchor="start" x="408" y="-544.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_61"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-519.98 239.25,-539.23 404,-539.23 404,-519.98 239.25,-519.98"/>
<text text-anchor="start" x="243.25" y="-526.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.kind</text>
</a>
</g>
<g id="a_node2_62"><a data-target="hosts-interfaces-name-module-kind" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-519.98 404,-539.23 474.25,-539.23 474.25,-519.98 404,-519.98"/>
<text text-anchor="start" x="408" y="-525.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_63"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-500.73 239.25,-519.98 404,-519.98 404,-500.73 239.25,-500.73"/>
<text text-anchor="start" x="243.25" y="-506.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.module.standard</text>
</a>
</g>
<g id="a_node2_64"><a data-target="hosts-interfaces-name-module-standard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.module.standard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-500.73 404,-519.98 474.25,-519.98 474.25,-500.73 404,-500.73"/>
<text text-anchor="start" x="408" y="-506.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_65"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-479.98 239.25,-500.73 404,-500.73 404,-479.98 239.25,-479.98"/>
<text text-anchor="start" x="243.25" y="-486.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.network</text>
</a>
</g>
<g id="a_node2_66"><a data-target="hosts-interfaces-name-network" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.network</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-479.98 404,-500.73 474.25,-500.73 474.25,-479.98 404,-479.98"/>
<text text-anchor="start" x="408" y="-487.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ networks</text>
</a>
</g>
<g id="a_node2_67"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-460.73 239.25,-479.98 404,-479.98 404,-460.73 239.25,-460.73"/>
<text text-anchor="start" x="243.25" y="-466.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.note</text>
</a>
</g>
<g id="a_node2_68"><a data-target="hosts-interfaces-name-note" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-460.73 404,-479.98 474.25,-479.98 474.25,-460.73 404,-460.73"/>
<text text-anchor="start" x="408" y="-466.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_69"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-441.48 239.25,-460.73 404,-460.73 404,-441.48 239.25,-441.48"/>
<text text-anchor="start" x="243.25" y="-447.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.speed</text>
</a>
</g>
<g id="a_node2_70"><a data-target="hosts-interfaces-name-speed" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.speed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-441.48 404,-460.73 474.25,-460.73 474.25,-441.48 404,-441.48"/>
<text text-anchor="start" x="408" y="-447.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_71"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-422.23 239.25,-441.48 404,-441.48 404,-422.23 239.25,-422.23"/>
<text text-anchor="start" x="243.25" y="-427.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">interfaces.&lt;name&gt;.wifiStandard</text>
</a>
</g>
<g id="a_node2_72"><a data-target="hosts-interfaces-name-wifistandard" tabindex="0" role="link"><title>hosts.interfaces.&lt;name&gt;.wifiStandard</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-422.23 404,-441.48 474.25,-441.48 474.25,-422.23 404,-422.23"/>
<text text-anchor="start" x="408" y="-427.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_73"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-402.98 239.25,-422.23 404,-422.23 404,-402.98 239.25,-402.98"/>
<text text-anchor="start" x="243.25" y="-409.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node2_74"><a data-target="hosts-kind" tabindex="0" role="link"><title>hosts.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-402.98 404,-422.23 474.25,-422.23 474.25,-402.98 404,-402.98"/>
<text text-anchor="start" x="408" y="-408.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_75"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-383.73 239.25,-402.98 404,-402.98 404,-383.73 239.25,-383.73"/>
<text text-anchor="start" x="243.25" y="-390.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">managed</text>
</a>
</g>
<g id="a_node2_76"><a data-target="hosts-managed" tabindex="0" role="link"><title>hosts.managed</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-383.73 404,-402.98 474.25,-402.98 474.25,-383.73 404,-383.73"/>
<text text-anchor="start" x="408" y="-389.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node2_77"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-362.98 239.25,-383.73 404,-383.73 404,-362.98 239.25,-362.98"/>
<text text-anchor="start" x="243.25" y="-369.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">manages</text>
</a>
</g>
<g id="a_node2_78"><a data-target="hosts-manages" tabindex="0" role="link"><title>hosts.manages</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-362.98 404,-383.73 474.25,-383.73 474.25,-362.98 404,-362.98"/>
<text text-anchor="start" x="408" y="-370.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_79"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-343.73 239.25,-362.98 404,-362.98 404,-343.73 239.25,-343.73"/>
<text text-anchor="start" x="243.25" y="-349.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">model</text>
</a>
</g>
<g id="a_node2_80"><a data-target="hosts-model" tabindex="0" role="link"><title>hosts.model</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-343.73 404,-362.98 474.25,-362.98 474.25,-343.73 404,-343.73"/>
<text text-anchor="start" x="408" y="-349.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_81"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-324.48 239.25,-343.73 404,-343.73 404,-324.48 239.25,-324.48"/>
<text text-anchor="start" x="243.25" y="-330.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node2_82"><a data-target="hosts-note" tabindex="0" role="link"><title>hosts.note</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-324.48 404,-343.73 474.25,-343.73 474.25,-324.48 404,-324.48"/>
<text text-anchor="start" x="408" y="-330.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_83"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-303.73 239.25,-324.48 404,-324.48 404,-303.73 239.25,-303.73"/>
<text text-anchor="start" x="243.25" y="-311.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owner</text>
</a>
</g>
<g id="a_node2_84"><a data-target="hosts-owner" tabindex="0" role="link"><title>hosts.owner</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-303.73 404,-324.48 474.25,-324.48 474.25,-303.73 404,-303.73"/>
<text text-anchor="start" x="408" y="-310.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ owners</text>
</a>
</g>
<g id="a_node2_85"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-282.98 239.25,-303.73 404,-303.73 404,-282.98 239.25,-282.98"/>
<text text-anchor="start" x="243.25" y="-289.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">power</text>
</a>
</g>
<g id="a_node2_86"><a data-target="hosts-power" tabindex="0" role="link"><title>hosts.power</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-282.98 404,-303.73 474.25,-303.73 474.25,-282.98 404,-282.98"/>
<text text-anchor="start" x="408" y="-290.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_87"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-263.73 239.25,-282.98 404,-282.98 404,-263.73 239.25,-263.73"/>
<text text-anchor="start" x="243.25" y="-269.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">productId</text>
</a>
</g>
<g id="a_node2_88"><a data-target="hosts-productid" tabindex="0" role="link"><title>hosts.productId</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-263.73 404,-282.98 474.25,-282.98 474.25,-263.73 404,-263.73"/>
<text text-anchor="start" x="408" y="-269.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_89"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-242.98 239.25,-263.73 404,-263.73 404,-242.98 239.25,-242.98"/>
<text text-anchor="start" x="243.25" y="-249.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">runsOn</text>
</a>
</g>
<g id="a_node2_90"><a data-target="hosts-runson" tabindex="0" role="link"><title>hosts.runsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-242.98 404,-263.73 474.25,-263.73 474.25,-242.98 404,-242.98"/>
<text text-anchor="start" x="408" y="-250.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node2_91"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-223.73 239.25,-242.98 404,-242.98 404,-223.73 239.25,-223.73"/>
<text text-anchor="start" x="243.25" y="-229.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">serial</text>
</a>
</g>
<g id="a_node2_92"><a data-target="hosts-serial" tabindex="0" role="link"><title>hosts.serial</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-223.73 404,-242.98 474.25,-242.98 474.25,-223.73 404,-223.73"/>
<text text-anchor="start" x="408" y="-229.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node2_93"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-202.98 239.25,-223.73 404,-223.73 404,-202.98 239.25,-202.98"/>
<text text-anchor="start" x="243.25" y="-209.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node2_94"><a data-target="hosts-site" tabindex="0" role="link"><title>hosts.site</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-202.98 404,-223.73 474.25,-223.73 474.25,-202.98 404,-202.98"/>
<text text-anchor="start" x="408" y="-210.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node2_95"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-183.73 239.25,-202.98 404,-202.98 404,-183.73 239.25,-183.73"/>
<text text-anchor="start" x="243.25" y="-189.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">sshHostKeys</text>
</a>
</g>
<g id="a_node2_96"><a data-target="hosts-sshhostkeys" tabindex="0" role="link"><title>hosts.sshHostKeys</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-183.73 404,-202.98 474.25,-202.98 474.25,-183.73 404,-183.73"/>
<text text-anchor="start" x="408" y="-189.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[string]</text>
</a>
</g>
<g id="a_node2_97"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-164.48 239.25,-183.73 404,-183.73 404,-164.48 239.25,-164.48"/>
<text text-anchor="start" x="243.25" y="-170.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock</text>
</a>
</g>
<g id="a_node2_98"><a data-target="hosts-unlock" tabindex="0" role="link"><title>hosts.unlock</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-164.48 404,-183.73 474.25,-183.73 474.25,-164.48 404,-164.48"/>
<text text-anchor="start" x="408" y="-170.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node2_99"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-145.23 239.25,-164.48 404,-164.48 404,-145.23 239.25,-145.23"/>
<text text-anchor="start" x="243.25" y="-150.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.fallback</text>
</a>
</g>
<g id="a_node2_100"><a data-target="hosts-unlock-fallback" tabindex="0" role="link"><title>hosts.unlock.fallback</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-145.23 404,-164.48 474.25,-164.48 474.25,-145.23 404,-145.23"/>
<text text-anchor="start" x="408" y="-150.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node2_101"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-125.98 239.25,-145.23 404,-145.23 404,-125.98 239.25,-125.98"/>
<text text-anchor="start" x="243.25" y="-132.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">unlock.methods</text>
</a>
</g>
<g id="a_node2_102"><a data-target="hosts-unlock-methods" tabindex="0" role="link"><title>hosts.unlock.methods</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-125.98 404,-145.23 474.25,-145.23 474.25,-125.98 404,-125.98"/>
<text text-anchor="start" x="408" y="-131.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[enum]</text>
</a>
</g>
<g id="a_node2_103"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-105.23 239.25,-125.98 404,-125.98 404,-105.23 239.25,-105.23"/>
<text text-anchor="start" x="243.25" y="-111.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.tang</text>
</a>
</g>
<g id="a_node2_104"><a data-target="hosts-unlock-tang" tabindex="0" role="link"><title>hosts.unlock.tang</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-105.23 404,-125.98 474.25,-125.98 474.25,-105.23 404,-105.23"/>
<text text-anchor="start" x="408" y="-112.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node2_105"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-85.98 239.25,-105.23 404,-105.23 404,-85.98 239.25,-85.98"/>
<text text-anchor="start" x="243.25" y="-91.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">unlock.threshold</text>
</a>
</g>
<g id="a_node2_106"><a data-target="hosts-unlock-threshold" tabindex="0" role="link"><title>hosts.unlock.threshold</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-85.98 404,-105.23 474.25,-105.23 474.25,-85.98 404,-85.98"/>
<text text-anchor="start" x="408" y="-91.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node2_107"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="239.25,-66.73 239.25,-85.98 404,-85.98 404,-66.73 239.25,-66.73"/>
<text text-anchor="start" x="243.25" y="-72.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vendor</text>
</a>
</g>
<g id="a_node2_108"><a data-target="hosts-vendor" tabindex="0" role="link"><title>hosts.vendor</title>
<polygon fill="none" stroke="#b4b2a9" points="404,-66.73 404,-85.98 474.25,-85.98 474.25,-66.73 404,-66.73"/>
<text text-anchor="start" x="408" y="-72.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge2" class="edge">
<title>hosts:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-782.11C756.68,-782.11 824.63,-706.82 1103.29,-705.5"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.09,-707.6 1109.09,-705.49 1103.08,-703.4 1103.09,-707.6"/>
</g>
<g id="node3" class="node">
<title>networks</title>
<polygon fill="#f1efe8" stroke="none" points="660.25,-674.86 539.25,-674.86 539.25,-440.86 660.25,-440.86 660.25,-674.86"/>
<polygon fill="#f1efe8" stroke="none" points="539.25,-440.86 539.25,-674.86 660.25,-674.86 660.25,-440.86 539.25,-440.86"/>
<g id="a_node3_109"><a data-target="networks" tabindex="0" role="link"><title>networks</title>
<polygon fill="#d3d1c7" stroke="none" points="539.25,-655.61 539.25,-674.86 660.25,-674.86 660.25,-655.61 539.25,-655.61"/>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-655.61 539.25,-674.86 660.25,-674.86 660.25,-655.61 539.25,-655.61"/>
<text text-anchor="start" x="578.75" y="-662.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">networks</text>
</a>
</g>
<g id="a_node3_110"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-636.36 539.25,-655.61 615.5,-655.61 615.5,-636.36 539.25,-636.36"/>
<text text-anchor="start" x="543.25" y="-642.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpPool</text>
</a>
</g>
<g id="a_node3_111"><a data-target="networks-dhcppool" tabindex="0" role="link"><title>networks.dhcpPool</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-636.36 615.5,-655.61 660.25,-655.61 660.25,-636.36 615.5,-636.36"/>
<text text-anchor="start" x="619.5" y="-642.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node3_112"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-617.11 539.25,-636.36 615.5,-636.36 615.5,-617.11 539.25,-617.11"/>
<text text-anchor="start" x="543.25" y="-623.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.end</text>
</a>
</g>
<g id="a_node3_113"><a data-target="networks-dhcppool-end" tabindex="0" role="link"><title>networks.dhcpPool.end</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-617.11 615.5,-636.36 660.25,-636.36 660.25,-617.11 615.5,-617.11"/>
<text text-anchor="start" x="619.5" y="-622.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_114"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-597.86 539.25,-617.11 615.5,-617.11 615.5,-597.86 539.25,-597.86"/>
<text text-anchor="start" x="543.25" y="-604.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">dhcpPool.start</text>
</a>
</g>
<g id="a_node3_115"><a data-target="networks-dhcppool-start" tabindex="0" role="link"><title>networks.dhcpPool.start</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-597.86 615.5,-617.11 660.25,-617.11 660.25,-597.86 615.5,-597.86"/>
<text text-anchor="start" x="619.5" y="-603.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_116"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-577.11 539.25,-597.86 615.5,-597.86 615.5,-577.11 539.25,-577.11"/>
<text text-anchor="start" x="543.25" y="-583.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dhcpServer</text>
</a>
</g>
<g id="a_node3_117"><a data-target="networks-dhcpserver" tabindex="0" role="link"><title>networks.dhcpServer</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-577.11 615.5,-597.86 660.25,-597.86 660.25,-577.11 615.5,-577.11"/>
<text text-anchor="start" x="619.5" y="-584.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ hosts</text>
</a>
</g>
<g id="a_node3_118"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-557.86 539.25,-577.11 615.5,-577.11 615.5,-557.86 539.25,-557.86"/>
<text text-anchor="start" x="543.25" y="-563.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node3_119"><a data-target="networks-ipv4" tabindex="0" role="link"><title>networks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-557.86 615.5,-577.11 660.25,-577.11 660.25,-557.86 615.5,-557.86"/>
<text text-anchor="start" x="619.5" y="-563.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_120"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-538.61 539.25,-557.86 615.5,-557.86 615.5,-538.61 539.25,-538.61"/>
<text text-anchor="start" x="543.25" y="-544.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node3_121"><a data-target="networks-ipv6" tabindex="0" role="link"><title>networks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-538.61 615.5,-557.86 660.25,-557.86 660.25,-538.61 615.5,-538.61"/>
<text text-anchor="start" x="619.5" y="-544.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_122"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-519.36 539.25,-538.61 615.5,-538.61 615.5,-519.36 539.25,-519.36"/>
<text text-anchor="start" x="543.25" y="-525.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6SubnetId</text>
</a>
</g>
<g id="a_node3_123"><a data-target="networks-ipv6subnetid" tabindex="0" role="link"><title>networks.ipv6SubnetId</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-519.36 615.5,-538.61 660.25,-538.61 660.25,-519.36 615.5,-519.36"/>
<text text-anchor="start" x="619.5" y="-525.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node3_124"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-500.11 539.25,-519.36 615.5,-519.36 615.5,-500.11 539.25,-500.11"/>
<text text-anchor="start" x="543.25" y="-506.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node3_125"><a data-target="networks-name" tabindex="0" role="link"><title>networks.name</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-500.11 615.5,-519.36 660.25,-519.36 660.25,-500.11 615.5,-500.11"/>
<text text-anchor="start" x="619.5" y="-505.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_126"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-480.86 539.25,-500.11 615.5,-500.11 615.5,-480.86 539.25,-480.86"/>
<text text-anchor="start" x="543.25" y="-486.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node3_127"><a data-target="networks-note" tabindex="0" role="link"><title>networks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-480.86 615.5,-500.11 660.25,-500.11 660.25,-480.86 615.5,-480.86"/>
<text text-anchor="start" x="619.5" y="-486.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node3_128"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-460.11 539.25,-480.86 615.5,-480.86 615.5,-460.11 539.25,-460.11"/>
<text text-anchor="start" x="543.25" y="-467.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">site</text>
</a>
</g>
<g id="a_node3_129"><a data-target="networks-site" tabindex="0" role="link"><title>networks.site</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-460.11 615.5,-480.86 660.25,-480.86 660.25,-460.11 615.5,-460.11"/>
<text text-anchor="start" x="619.5" y="-467.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ sites</text>
</a>
</g>
<g id="a_node3_130"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="539.25,-440.86 539.25,-460.11 615.5,-460.11 615.5,-440.86 539.25,-440.86"/>
<text text-anchor="start" x="543.25" y="-446.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">vlan</text>
</a>
</g>
<g id="a_node3_131"><a data-target="networks-vlan" tabindex="0" role="link"><title>networks.vlan</title>
<polygon fill="none" stroke="#b4b2a9" points="615.5,-440.86 615.5,-460.11 660.25,-460.11 660.25,-440.86 615.5,-440.86"/>
<text text-anchor="start" x="619.5" y="-446.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
</g>
<g id="edge3" class="edge">
<title>hosts:e&#45;&gt;networks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-490.36C554.58,-490.36 462.46,-654.47 532,-664.73"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="531.46,-666.8 537.59,-665.12 531.75,-662.61 531.46,-666.8"/>
</g>
<g id="node4" class="node">
<title>owners</title>
<polygon fill="#f1efe8" stroke="none" points="635.88,-325.36 563.62,-325.36 563.62,-248.36 635.88,-248.36 635.88,-325.36"/>
<polygon fill="#f1efe8" stroke="none" points="563.62,-248.36 563.62,-325.36 635.88,-325.36 635.88,-248.36 563.62,-248.36"/>
<g id="a_node4_132"><a data-target="owners" tabindex="0" role="link"><title>owners</title>
<polygon fill="#d3d1c7" stroke="none" points="563.62,-306.11 563.62,-325.36 635.88,-325.36 635.88,-306.11 563.62,-306.11"/>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-306.11 563.62,-325.36 635.88,-325.36 635.88,-306.11 563.62,-306.11"/>
<text text-anchor="start" x="582.88" y="-312.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">owners</text>
</a>
</g>
<g id="a_node4_133"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-286.86 563.62,-306.11 603.88,-306.11 603.88,-286.86 563.62,-286.86"/>
<text text-anchor="start" x="567.62" y="-292.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contact</text>
</a>
</g>
<g id="a_node4_134"><a data-target="owners-contact" tabindex="0" role="link"><title>owners.contact</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-286.86 603.88,-306.11 635.88,-306.11 635.88,-286.86 603.88,-286.86"/>
<text text-anchor="start" x="607.88" y="-292.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_135"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-267.61 563.62,-286.86 603.88,-286.86 603.88,-267.61 563.62,-267.61"/>
<text text-anchor="start" x="567.62" y="-274.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node4_136"><a data-target="owners-name" tabindex="0" role="link"><title>owners.name</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-267.61 603.88,-286.86 635.88,-286.86 635.88,-267.61 603.88,-267.61"/>
<text text-anchor="start" x="607.88" y="-273.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node4_137"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="563.62,-248.36 563.62,-267.61 603.88,-267.61 603.88,-248.36 563.62,-248.36"/>
<text text-anchor="start" x="567.62" y="-254.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node4_138"><a data-target="owners-note" tabindex="0" role="link"><title>owners.note</title>
<polygon fill="none" stroke="#b4b2a9" points="603.88,-248.36 603.88,-267.61 635.88,-267.61 635.88,-248.36 603.88,-248.36"/>
<text text-anchor="start" x="607.88" y="-254.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge4" class="edge">
<title>hosts:e&#45;&gt;owners:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-314.11C510.93,-314.11 521.91,-315.52 555.17,-315.71"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="554.95,-317.81 560.96,-315.73 554.97,-313.61 554.95,-317.81"/>
</g>
<g id="node7" class="node">
<title>sites</title>
<polygon fill="#f1efe8" stroke="none" points="828.25,-480.73 725.25,-480.73 725.25,-342.98 828.25,-342.98 828.25,-480.73"/>
<polygon fill="#f1efe8" stroke="none" points="725.25,-342.98 725.25,-480.73 828.25,-480.73 828.25,-342.98 725.25,-342.98"/>
<g id="a_node7_139"><a data-target="sites" tabindex="0" role="link"><title>sites</title>
<polygon fill="#d3d1c7" stroke="none" points="725.25,-461.48 725.25,-480.73 828.25,-480.73 828.25,-461.48 725.25,-461.48"/>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-461.48 725.25,-480.73 828.25,-480.73 828.25,-461.48 725.25,-461.48"/>
<text text-anchor="start" x="765.88" y="-468.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">sites</text>
</a>
</g>
<g id="a_node7_140"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-442.23 725.25,-461.48 767.75,-461.48 767.75,-442.23 725.25,-442.23"/>
<text text-anchor="start" x="729.25" y="-448.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">city</text>
</a>
</g>
<g id="a_node7_141"><a data-target="sites-city" tabindex="0" role="link"><title>sites.city</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-442.23 767.75,-461.48 828.25,-461.48 828.25,-442.23 767.75,-442.23"/>
<text text-anchor="start" x="771.75" y="-447.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_142"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-422.98 725.25,-442.23 767.75,-442.23 767.75,-422.98 725.25,-422.98"/>
<text text-anchor="start" x="729.25" y="-428.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Ula</text>
</a>
</g>
<g id="a_node7_143"><a data-target="sites-ipv6ula" tabindex="0" role="link"><title>sites.ipv6Ula</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-422.98 767.75,-442.23 828.25,-442.23 828.25,-422.98 767.75,-422.98"/>
<text text-anchor="start" x="771.75" y="-428.73" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_144"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-403.73 725.25,-422.98 767.75,-422.98 767.75,-403.73 725.25,-403.73"/>
<text text-anchor="start" x="729.25" y="-410.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">kind</text>
</a>
</g>
<g id="a_node7_145"><a data-target="sites-kind" tabindex="0" role="link"><title>sites.kind</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-403.73 767.75,-422.98 828.25,-422.98 828.25,-403.73 767.75,-403.73"/>
<text text-anchor="start" x="771.75" y="-409.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node7_146"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-384.48 725.25,-403.73 767.75,-403.73 767.75,-384.48 725.25,-384.48"/>
<text text-anchor="start" x="729.25" y="-390.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node7_147"><a data-target="sites-note" tabindex="0" role="link"><title>sites.note</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-384.48 767.75,-403.73 828.25,-403.73 828.25,-384.48 767.75,-384.48"/>
<text text-anchor="start" x="771.75" y="-390.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node7_148"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-363.73 725.25,-384.48 767.75,-384.48 767.75,-363.73 725.25,-363.73"/>
<text text-anchor="start" x="729.25" y="-370.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node7_149"><a data-target="sites-provider" tabindex="0" role="link"><title>sites.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-363.73 767.75,-384.48 828.25,-384.48 828.25,-363.73 767.75,-363.73"/>
<text text-anchor="start" x="771.75" y="-370.98" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node7_150"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="725.25,-342.98 725.25,-363.73 767.75,-363.73 767.75,-342.98 725.25,-342.98"/>
<text text-anchor="start" x="729.25" y="-350.48" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node7_151"><a data-target="sites-uplinks" tabindex="0" role="link"><title>sites.uplinks</title>
<polygon fill="none" stroke="#b4b2a9" points="767.75,-342.98 767.75,-363.73 828.25,-363.73 828.25,-342.98 767.75,-342.98"/>
<text text-anchor="start" x="771.75" y="-350.23" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ uplinks]</text>
</a>
</g>
</g>
<g id="edge5" class="edge">
<title>hosts:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M474.25,-213.36C557.63,-213.36 597.29,-183.19 660.25,-237.86 739.53,-306.69 623.56,-463.22 717.78,-470.82"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.51,-472.91 723.59,-471.04 717.67,-468.71 717.51,-472.91"/>
</g>
<g id="edge6" class="edge">
<title>networks:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M661.25,-587.48C700.09,-587.48 680.27,-641.58 660.25,-674.86 628.68,-727.35 586.28,-701.61 539.25,-740.86 506.01,-768.59 518.5,-815.45 481.71,-820.85"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="481.75,-818.74 475.91,-821.24 482.04,-822.93 481.75,-818.74"/>
</g>
<g id="edge7" class="edge">
<title>networks:e&#45;&gt;sites:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M660.25,-470.48C686.43,-470.48 694.82,-470.99 717.66,-471.09"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="717.58,-473.19 723.59,-471.1 717.59,-468.99 717.58,-473.19"/>
</g>
<g id="node6" class="node">
<title>services</title>
<polygon fill="#f1efe8" stroke="none" points="174.25,-1107.86 0,-1107.86 0,-519.86 174.25,-519.86 174.25,-1107.86"/>
<polygon fill="#f1efe8" stroke="none" points="0,-519.86 0,-1107.86 174.25,-1107.86 174.25,-519.86 0,-519.86"/>
<g id="a_node6_152"><a data-target="services" tabindex="0" role="link"><title>services</title>
<polygon fill="#d3d1c7" stroke="none" points="0,-1088.61 0,-1107.86 174.25,-1107.86 174.25,-1088.61 0,-1088.61"/>
<polygon fill="none" stroke="#b4b2a9" points="0,-1088.61 0,-1107.86 174.25,-1107.86 174.25,-1088.61 0,-1088.61"/>
<text text-anchor="start" x="68" y="-1095.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">services</text>
</a>
</g>
<g id="a_node6_153"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1069.36 0,-1088.61 107,-1088.61 107,-1069.36 0,-1069.36"/>
<text text-anchor="start" x="4" y="-1075.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup</text>
</a>
</g>
<g id="a_node6_154"><a data-target="services-backup" tabindex="0" role="link"><title>services.backup</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1069.36 107,-1088.61 174.25,-1088.61 174.25,-1069.36 107,-1069.36"/>
<text text-anchor="start" x="111" y="-1075.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_155"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1050.11 0,-1069.36 107,-1069.36 107,-1050.11 0,-1050.11"/>
<text text-anchor="start" x="4" y="-1055.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].interval</text>
</a>
</g>
<g id="a_node6_156"><a data-target="services-backup-interval" tabindex="0" role="link"><title>services.backup[].interval</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1050.11 107,-1069.36 174.25,-1069.36 174.25,-1050.11 107,-1050.11"/>
<text text-anchor="start" x="111" y="-1055.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_157"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1030.86 0,-1050.11 107,-1050.11 107,-1030.86 0,-1030.86"/>
<text text-anchor="start" x="4" y="-1036.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep</text>
</a>
</g>
<g id="a_node6_158"><a data-target="services-backup-keep" tabindex="0" role="link"><title>services.backup[].keep</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1030.86 107,-1050.11 174.25,-1050.11 174.25,-1030.86 107,-1030.86"/>
<text text-anchor="start" x="111" y="-1036.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node6_159"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-1011.61 0,-1030.86 107,-1030.86 107,-1011.61 0,-1011.61"/>
<text text-anchor="start" x="4" y="-1017.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.all</text>
</a>
</g>
<g id="a_node6_160"><a data-target="services-backup-keep-all" tabindex="0" role="link"><title>services.backup[].keep.all</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-1011.61 107,-1030.86 174.25,-1030.86 174.25,-1011.61 107,-1011.61"/>
<text text-anchor="start" x="111" y="-1017.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node6_161"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-992.36 0,-1011.61 107,-1011.61 107,-992.36 0,-992.36"/>
<text text-anchor="start" x="4" y="-998.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.daily</text>
</a>
</g>
<g id="a_node6_162"><a data-target="services-backup-keep-daily" tabindex="0" role="link"><title>services.backup[].keep.daily</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-992.36 107,-1011.61 174.25,-1011.61 174.25,-992.36 107,-992.36"/>
<text text-anchor="start" x="111" y="-998.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_163"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-973.11 0,-992.36 107,-992.36 107,-973.11 0,-973.11"/>
<text text-anchor="start" x="4" y="-978.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.last</text>
</a>
</g>
<g id="a_node6_164"><a data-target="services-backup-keep-last" tabindex="0" role="link"><title>services.backup[].keep.last</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-973.11 107,-992.36 174.25,-992.36 174.25,-973.11 107,-973.11"/>
<text text-anchor="start" x="111" y="-978.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_165"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-953.86 0,-973.11 107,-973.11 107,-953.86 0,-953.86"/>
<text text-anchor="start" x="4" y="-959.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.monthly</text>
</a>
</g>
<g id="a_node6_166"><a data-target="services-backup-keep-monthly" tabindex="0" role="link"><title>services.backup[].keep.monthly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-953.86 107,-973.11 174.25,-973.11 174.25,-953.86 107,-953.86"/>
<text text-anchor="start" x="111" y="-959.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_167"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-934.61 0,-953.86 107,-953.86 107,-934.61 0,-934.61"/>
<text text-anchor="start" x="4" y="-940.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].keep.weekly</text>
</a>
</g>
<g id="a_node6_168"><a data-target="services-backup-keep-weekly" tabindex="0" role="link"><title>services.backup[].keep.weekly</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-934.61 107,-953.86 174.25,-953.86 174.25,-934.61 107,-934.61"/>
<text text-anchor="start" x="111" y="-940.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_169"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-915.36 0,-934.61 107,-934.61 107,-915.36 0,-915.36"/>
<text text-anchor="start" x="4" y="-922.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">backup[].method</text>
</a>
</g>
<g id="a_node6_170"><a data-target="services-backup-method" tabindex="0" role="link"><title>services.backup[].method</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-915.36 107,-934.61 174.25,-934.61 174.25,-915.36 107,-915.36"/>
<text text-anchor="start" x="111" y="-921.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_171"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-896.11 0,-915.36 107,-915.36 107,-896.11 0,-896.11"/>
<text text-anchor="start" x="4" y="-901.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].note</text>
</a>
</g>
<g id="a_node6_172"><a data-target="services-backup-note" tabindex="0" role="link"><title>services.backup[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-896.11 107,-915.36 174.25,-915.36 174.25,-896.11 107,-896.11"/>
<text text-anchor="start" x="111" y="-901.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_173"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-875.36 0,-896.11 107,-896.11 107,-875.36 0,-875.36"/>
<text text-anchor="start" x="4" y="-881.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">backup[].to</text>
</a>
</g>
<g id="a_node6_174"><a data-target="services-backup-to" tabindex="0" role="link"><title>services.backup[].to</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-875.36 107,-896.11 174.25,-896.11 174.25,-875.36 107,-875.36"/>
<text text-anchor="start" x="111" y="-882.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_175"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-854.61 0,-875.36 107,-875.36 107,-854.61 0,-854.61"/>
<text text-anchor="start" x="4" y="-861.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node6_176"><a data-target="services-contracts" tabindex="0" role="link"><title>services.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-854.61 107,-875.36 174.25,-875.36 174.25,-854.61 107,-854.61"/>
<text text-anchor="start" x="111" y="-861.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node6_177"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-835.36 0,-854.61 107,-854.61 107,-835.36 0,-835.36"/>
<text text-anchor="start" x="4" y="-841.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">criticality</text>
</a>
</g>
<g id="a_node6_178"><a data-target="services-criticality" tabindex="0" role="link"><title>services.criticality</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-835.36 107,-854.61 174.25,-854.61 174.25,-835.36 107,-835.36"/>
<text text-anchor="start" x="111" y="-841.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_179"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-816.11 0,-835.36 107,-835.36 107,-816.11 0,-816.11"/>
<text text-anchor="start" x="4" y="-822.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">data</text>
</a>
</g>
<g id="a_node6_180"><a data-target="services-data" tabindex="0" role="link"><title>services.data</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-816.11 107,-835.36 174.25,-835.36 174.25,-816.11 107,-816.11"/>
<text text-anchor="start" x="111" y="-821.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_181"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-795.36 0,-816.11 107,-816.11 107,-795.36 0,-795.36"/>
<text text-anchor="start" x="4" y="-801.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">dependsOn</text>
</a>
</g>
<g id="a_node6_182"><a data-target="services-dependson" tabindex="0" role="link"><title>services.dependsOn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-795.36 107,-816.11 174.25,-816.11 174.25,-795.36 107,-795.36"/>
<text text-anchor="start" x="111" y="-802.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_183"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-776.11 0,-795.36 107,-795.36 107,-776.11 0,-776.11"/>
<text text-anchor="start" x="4" y="-781.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints</text>
</a>
</g>
<g id="a_node6_184"><a data-target="services-endpoints" tabindex="0" role="link"><title>services.endpoints</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-776.11 107,-795.36 174.25,-795.36 174.25,-776.11 107,-776.11"/>
<text text-anchor="start" x="111" y="-781.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[object]</text>
</a>
</g>
<g id="a_node6_185"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-756.86 0,-776.11 107,-776.11 107,-756.86 0,-756.86"/>
<text text-anchor="start" x="4" y="-763.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].exposure</text>
</a>
</g>
<g id="a_node6_186"><a data-target="services-endpoints-exposure" tabindex="0" role="link"><title>services.endpoints[].exposure</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-756.86 107,-776.11 174.25,-776.11 174.25,-756.86 107,-756.86"/>
<text text-anchor="start" x="111" y="-762.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node6_187"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-737.61 0,-756.86 107,-756.86 107,-737.61 0,-737.61"/>
<text text-anchor="start" x="4" y="-744.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">endpoints[].fqdn</text>
</a>
</g>
<g id="a_node6_188"><a data-target="services-endpoints-fqdn" tabindex="0" role="link"><title>services.endpoints[].fqdn</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-737.61 107,-756.86 174.25,-756.86 174.25,-737.61 107,-737.61"/>
<text text-anchor="start" x="111" y="-743.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_189"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-718.36 0,-737.61 107,-737.61 107,-718.36 0,-718.36"/>
<text text-anchor="start" x="4" y="-724.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].note</text>
</a>
</g>
<g id="a_node6_190"><a data-target="services-endpoints-note" tabindex="0" role="link"><title>services.endpoints[].note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-718.36 107,-737.61 174.25,-737.61 174.25,-718.36 107,-718.36"/>
<text text-anchor="start" x="111" y="-724.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_191"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-699.11 0,-718.36 107,-718.36 107,-699.11 0,-699.11"/>
<text text-anchor="start" x="4" y="-704.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].port</text>
</a>
</g>
<g id="a_node6_192"><a data-target="services-endpoints-port" tabindex="0" role="link"><title>services.endpoints[].port</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-699.11 107,-718.36 174.25,-718.36 174.25,-699.11 107,-699.11"/>
<text text-anchor="start" x="111" y="-704.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node6_193"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-678.36 0,-699.11 107,-699.11 107,-678.36 0,-678.36"/>
<text text-anchor="start" x="4" y="-684.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">endpoints[].via</text>
</a>
</g>
<g id="a_node6_194"><a data-target="services-endpoints-via" tabindex="0" role="link"><title>services.endpoints[].via</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-678.36 107,-699.11 174.25,-699.11 174.25,-678.36 107,-678.36"/>
<text text-anchor="start" x="111" y="-685.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ services</text>
</a>
</g>
<g id="a_node6_195"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-657.61 0,-678.36 107,-678.36 107,-657.61 0,-657.61"/>
<text text-anchor="start" x="4" y="-664.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">hosts</text>
</a>
</g>
<g id="a_node6_196"><a data-target="services-hosts" tabindex="0" role="link"><title>services.hosts</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-657.61 107,-678.36 174.25,-678.36 174.25,-657.61 107,-657.61"/>
<text text-anchor="start" x="111" y="-664.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ hosts]</text>
</a>
</g>
<g id="a_node6_197"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-638.36 0,-657.61 107,-657.61 107,-638.36 0,-638.36"/>
<text text-anchor="start" x="4" y="-645.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">name</text>
</a>
</g>
<g id="a_node6_198"><a data-target="services-name" tabindex="0" role="link"><title>services.name</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-638.36 107,-657.61 174.25,-657.61 174.25,-638.36 107,-638.36"/>
<text text-anchor="start" x="111" y="-644.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_199"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-619.11 0,-638.36 107,-638.36 107,-619.11 0,-619.11"/>
<text text-anchor="start" x="4" y="-624.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node6_200"><a data-target="services-note" tabindex="0" role="link"><title>services.note</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-619.11 107,-638.36 174.25,-638.36 174.25,-619.11 107,-619.11"/>
<text text-anchor="start" x="111" y="-624.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_201"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-599.86 0,-619.11 107,-619.11 107,-599.86 0,-599.86"/>
<text text-anchor="start" x="4" y="-605.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">package</text>
</a>
</g>
<g id="a_node6_202"><a data-target="services-package" tabindex="0" role="link"><title>services.package</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-599.86 107,-619.11 174.25,-619.11 174.25,-599.86 107,-599.86"/>
<text text-anchor="start" x="111" y="-605.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_203"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-579.11 0,-599.86 107,-599.86 107,-579.11 0,-579.11"/>
<text text-anchor="start" x="4" y="-585.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node6_204"><a data-target="services-provider" tabindex="0" role="link"><title>services.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-579.11 107,-599.86 174.25,-599.86 174.25,-579.11 107,-579.11"/>
<text text-anchor="start" x="111" y="-586.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
<g id="a_node6_205"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-559.86 0,-579.11 107,-579.11 107,-559.86 0,-559.86"/>
<text text-anchor="start" x="4" y="-565.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">software</text>
</a>
</g>
<g id="a_node6_206"><a data-target="services-software" tabindex="0" role="link"><title>services.software</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-559.86 107,-579.11 174.25,-579.11 174.25,-559.86 107,-559.86"/>
<text text-anchor="start" x="111" y="-565.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node6_207"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-539.11 0,-559.86 107,-559.86 107,-539.11 0,-539.11"/>
<text text-anchor="start" x="4" y="-545.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">uses</text>
</a>
</g>
<g id="a_node6_208"><a data-target="services-uses" tabindex="0" role="link"><title>services.uses</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-539.11 107,-559.86 174.25,-559.86 174.25,-539.11 107,-539.11"/>
<text text-anchor="start" x="111" y="-546.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ services]</text>
</a>
</g>
<g id="a_node6_209"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="0,-519.86 0,-539.11 107,-539.11 107,-519.86 0,-519.86"/>
<text text-anchor="start" x="4" y="-525.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">version</text>
</a>
</g>
<g id="a_node6_210"><a data-target="services-version" tabindex="0" role="link"><title>services.version</title>
<polygon fill="none" stroke="#b4b2a9" points="107,-519.86 107,-539.11 174.25,-539.11 174.25,-519.86 107,-519.86"/>
<text text-anchor="start" x="111" y="-525.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
</g>
<g id="edge8" class="edge">
<title>services:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-864.98C362.92,-864.98 410.08,-864.86 598.75,-864.86 598.75,-864.86 598.75,-864.86 777.75,-864.86 796.94,-864.86 1053.73,-725.36 1103.55,-707.38"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.87,-709.47 1109.14,-705.91 1102.8,-705.41 1103.87,-709.47"/>
</g>
<g id="edge9" class="edge">
<title>services:e&#45;&gt;hosts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-667.98C245.54,-667.98 171.16,-810.18 231.64,-820.74"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="231.44,-822.83 237.59,-821.22 231.78,-818.64 231.44,-822.83"/>
</g>
<g id="edge10" class="edge">
<title>services:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M174.25,-589.48C293.71,-589.48 152.39,-137.87 239.25,-55.86 355.66,54.06 438.65,-32.86 598.75,-32.86 598.75,-32.86 598.75,-32.86 970.5,-32.86 1097.55,-32.86 1151.96,-29.01 1243.75,-116.86 1304.01,-174.53 1227.71,-291.73 1301.16,-299"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301,-301.1 1307.09,-299.28 1301.19,-296.9 1301,-301.1"/>
</g>
<g id="edge11" class="edge">
<title>sites:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-374.11C924.92,-374.11 950.01,-387.21 1045.75,-373.86 1163.61,-357.42 1186.35,-301.71 1301.4,-299.43"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.11,-301.53 1307.09,-299.37 1301.06,-297.33 1301.11,-301.53"/>
</g>
<g id="node8" class="node">
<title>uplinks</title>
<polygon fill="#f1efe8" stroke="none" points="1045.75,-363.11 893.25,-363.11 893.25,-90.61 1045.75,-90.61 1045.75,-363.11"/>
<polygon fill="#f1efe8" stroke="none" points="893.25,-90.61 893.25,-363.11 1045.75,-363.11 1045.75,-90.61 893.25,-90.61"/>
<g id="a_node8_211"><a data-target="uplinks" tabindex="0" role="link"><title>uplinks</title>
<polygon fill="#d3d1c7" stroke="none" points="893.25,-343.86 893.25,-363.11 1045.75,-363.11 1045.75,-343.86 893.25,-343.86"/>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-343.86 893.25,-363.11 1045.75,-363.11 1045.75,-343.86 893.25,-343.86"/>
<text text-anchor="start" x="952.25" y="-350.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">uplinks</text>
</a>
</g>
<g id="a_node8_212"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-324.61 893.25,-343.86 978.5,-343.86 978.5,-324.61 893.25,-324.61"/>
<text text-anchor="start" x="897.25" y="-330.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">asn</text>
</a>
</g>
<g id="a_node8_213"><a data-target="uplinks-asn" tabindex="0" role="link"><title>uplinks.asn</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-324.61 978.5,-343.86 1045.75,-343.86 1045.75,-324.61 978.5,-324.61"/>
<text text-anchor="start" x="982.5" y="-330.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_214"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-305.36 893.25,-324.61 978.5,-324.61 978.5,-305.36 893.25,-305.36"/>
<text text-anchor="start" x="897.25" y="-311.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">bandwidth</text>
</a>
</g>
<g id="a_node8_215"><a data-target="uplinks-bandwidth" tabindex="0" role="link"><title>uplinks.bandwidth</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-305.36 978.5,-324.61 1045.75,-324.61 1045.75,-305.36 978.5,-305.36"/>
<text text-anchor="start" x="982.5" y="-311.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">object</text>
</a>
</g>
<g id="a_node8_216"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-286.11 893.25,-305.36 978.5,-305.36 978.5,-286.11 893.25,-286.11"/>
<text text-anchor="start" x="897.25" y="-292.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.down</text>
</a>
</g>
<g id="a_node8_217"><a data-target="uplinks-bandwidth-down" tabindex="0" role="link"><title>uplinks.bandwidth.down</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-286.11 978.5,-305.36 1045.75,-305.36 1045.75,-286.11 978.5,-286.11"/>
<text text-anchor="start" x="982.5" y="-291.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_218"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-266.86 893.25,-286.11 978.5,-286.11 978.5,-266.86 893.25,-266.86"/>
<text text-anchor="start" x="897.25" y="-273.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-weight="bold" font-size="10.00" fill="#2c2c2a">bandwidth.up</text>
</a>
</g>
<g id="a_node8_219"><a data-target="uplinks-bandwidth-up" tabindex="0" role="link"><title>uplinks.bandwidth.up</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-266.86 978.5,-286.11 1045.75,-286.11 1045.75,-266.86 978.5,-266.86"/>
<text text-anchor="start" x="982.5" y="-272.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_220"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-246.11 893.25,-266.86 978.5,-266.86 978.5,-246.11 893.25,-246.11"/>
<text text-anchor="start" x="897.25" y="-252.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">contracts</text>
</a>
</g>
<g id="a_node8_221"><a data-target="uplinks-contracts" tabindex="0" role="link"><title>uplinks.contracts</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-246.11 978.5,-266.86 1045.75,-266.86 1045.75,-246.11 978.5,-246.11"/>
<text text-anchor="start" x="982.5" y="-253.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">[→ contracts]</text>
</a>
</g>
<g id="a_node8_222"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-226.86 893.25,-246.11 978.5,-246.11 978.5,-226.86 893.25,-226.86"/>
<text text-anchor="start" x="897.25" y="-232.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4</text>
</a>
</g>
<g id="a_node8_223"><a data-target="uplinks-ipv4" tabindex="0" role="link"><title>uplinks.ipv4</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-226.86 978.5,-246.11 1045.75,-246.11 1045.75,-226.86 978.5,-226.86"/>
<text text-anchor="start" x="982.5" y="-232.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_224"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-207.61 893.25,-226.86 978.5,-226.86 978.5,-207.61 893.25,-207.61"/>
<text text-anchor="start" x="897.25" y="-213.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv4Static</text>
</a>
</g>
<g id="a_node8_225"><a data-target="uplinks-ipv4static" tabindex="0" role="link"><title>uplinks.ipv4Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-207.61 978.5,-226.86 1045.75,-226.86 1045.75,-207.61 978.5,-207.61"/>
<text text-anchor="start" x="982.5" y="-213.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_226"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-188.36 893.25,-207.61 978.5,-207.61 978.5,-188.36 893.25,-188.36"/>
<text text-anchor="start" x="897.25" y="-194.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6</text>
</a>
</g>
<g id="a_node8_227"><a data-target="uplinks-ipv6" tabindex="0" role="link"><title>uplinks.ipv6</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-188.36 978.5,-207.61 1045.75,-207.61 1045.75,-188.36 978.5,-188.36"/>
<text text-anchor="start" x="982.5" y="-194.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_228"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-169.11 893.25,-188.36 978.5,-188.36 978.5,-169.11 893.25,-169.11"/>
<text text-anchor="start" x="897.25" y="-174.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6PrefixLength</text>
</a>
</g>
<g id="a_node8_229"><a data-target="uplinks-ipv6prefixlength" tabindex="0" role="link"><title>uplinks.ipv6PrefixLength</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-169.11 978.5,-188.36 1045.75,-188.36 1045.75,-169.11 978.5,-169.11"/>
<text text-anchor="start" x="982.5" y="-174.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">integer</text>
</a>
</g>
<g id="a_node8_230"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-149.86 893.25,-169.11 978.5,-169.11 978.5,-149.86 893.25,-149.86"/>
<text text-anchor="start" x="897.25" y="-155.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">ipv6Static</text>
</a>
</g>
<g id="a_node8_231"><a data-target="uplinks-ipv6static" tabindex="0" role="link"><title>uplinks.ipv6Static</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-149.86 978.5,-169.11 1045.75,-169.11 1045.75,-149.86 978.5,-149.86"/>
<text text-anchor="start" x="982.5" y="-155.61" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">boolean</text>
</a>
</g>
<g id="a_node8_232"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-130.61 893.25,-149.86 978.5,-149.86 978.5,-130.61 893.25,-130.61"/>
<text text-anchor="start" x="897.25" y="-136.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">medium</text>
</a>
</g>
<g id="a_node8_233"><a data-target="uplinks-medium" tabindex="0" role="link"><title>uplinks.medium</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-130.61 978.5,-149.86 1045.75,-149.86 1045.75,-130.61 978.5,-130.61"/>
<text text-anchor="start" x="982.5" y="-136.36" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">enum</text>
</a>
</g>
<g id="a_node8_234"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-111.36 893.25,-130.61 978.5,-130.61 978.5,-111.36 893.25,-111.36"/>
<text text-anchor="start" x="897.25" y="-117.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">note</text>
</a>
</g>
<g id="a_node8_235"><a data-target="uplinks-note" tabindex="0" role="link"><title>uplinks.note</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-111.36 978.5,-130.61 1045.75,-130.61 1045.75,-111.36 978.5,-111.36"/>
<text text-anchor="start" x="982.5" y="-117.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">string</text>
</a>
</g>
<g id="a_node8_236"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="893.25,-90.61 893.25,-111.36 978.5,-111.36 978.5,-90.61 893.25,-90.61"/>
<text text-anchor="start" x="897.25" y="-97.11" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#2c2c2a">provider</text>
</a>
</g>
<g id="a_node8_237"><a data-target="uplinks-provider" tabindex="0" role="link"><title>uplinks.provider</title>
<polygon fill="none" stroke="#b4b2a9" points="978.5,-90.61 978.5,-111.36 1045.75,-111.36 1045.75,-90.61 978.5,-90.61"/>
<text text-anchor="start" x="982.5" y="-97.86" font-family="Liberation Sans,Helvetica,Arial,sans-serif" font-size="10.00" fill="#5f5e5a">→ providers</text>
</a>
</g>
</g>
<g id="edge12" class="edge">
<title>sites:e&#45;&gt;uplinks:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M828.25,-353.36C854.43,-353.36 862.82,-353.46 885.66,-353.48"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="885.58,-355.58 891.59,-353.48 885.59,-351.38 885.58,-355.58"/>
</g>
<g id="edge13" class="edge">
<title>uplinks:e&#45;&gt;contracts:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-256.48C1244.83,-256.48 917.62,-694.15 1103.33,-705.27"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1103.03,-707.36 1109.09,-705.43 1103.15,-703.16 1103.03,-707.36"/>
</g>
<g id="edge14" class="edge">
<title>uplinks:e&#45;&gt;providers:h</title>
<path fill="none" stroke="#888780" stroke-width="1.1" d="M1045.75,-100.98C1189.59,-100.98 1163.33,-292.44 1301.19,-299.17"/>
<polygon fill="#888780" stroke="#888780" stroke-width="1.1" points="1301.04,-301.27 1307.09,-299.32 1301.14,-297.07 1301.04,-301.27"/>
</g>
</g>
</svg>
</figure>

A click on a section's head leads to its section below, a click on a field to its row in the field table; anywhere else the diagram opens enlarged. On its own: [inventory-schema.svg](../assets/diagrams/inventory-schema.svg).

## Conventions

**Ids.** Entries are keyed by id: lower-case letters, digits and dashes, starting with a letter or digit (`grammi`, `realtox-dus`, `home-private`). A reference field holds such an id and must name an existing entry of the right section.

**Required and optional.** A field is optional unless the table says *required*. Optional fields left out are filled in by the derived view – with the default the table gives, otherwise `null` or `[]` – so a consumer never has to write `or`.

**Unknown fields are errors.** A typo (`critcality`) is reported with the list of the known fields, in the editor right away and in `nix flake check`.

**One direction.** Every relation is stored where it starts (`hosts.runsOn`, `services.dependsOn`, `hosts.contracts`); the reverse (`guests`, `neededBy`, `covers`) is derived.

**Formats.** Strings with a format are checked against it:

| Format | Example | Used by |
| --- | --- | --- |
| IPv4 address | `192.0.2.10` | `interfaces.<name>.ipv4.address`, `dhcpPool` |
| IPv4 prefix (no host bits) | `192.0.2.0/24` | `networks.ipv4` |
| IPv6 prefix | `2001:db8:1::/64` | `networks.ipv6` |
| ULA /48 (in `fd00::/8`) | `fd12:3456:789a::/48` | `sites.ipv6Ula` |
| MAC address, lower case | `52:54:00:12:34:56` | `interfaces.<name>.mac` |
| Link-local | `eui64`, `stable-privacy`, `random` or `fe80::1234` | `interfaces.<name>.linkLocal` |
| SSH public key without comment | `ssh-ed25519 AAAAC3Nz…` | `hosts.sshHostKeys` |
| Date | `2026-10-22` | `contracts.since`, `contracts.renews` |
| Domain name, lower case | `cloud.example.org` | `services.endpoints[].fqdn` |
| Interface name | `eno1`, `eno1.20`, `wlp2s0f0` | keys of `hosts.interfaces` |

**Money** is in whole cents (`899` = 8.99) – no floating point, no rounding.

**What the schema cannot say.** A JSON Schema checks one entry at a time. Everything between entries – references, cycles, addresses inside a prefix, a contract with the right provider – is checked by `inventory.nix` only; each section below lists those rules briefly, [Validation](inventory.md#validation) has them all.

## owners { #owners }

Who administers a device – whom to call and what may be changed.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="owners-contact"></span>`contact` | string |  | Who to talk to when this owner's devices are affected. |
| <span id="owners-name"></span>`name` | string | required | Display name. |
| <span id="owners-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |

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

Rule beyond the schema: every owner owns at least one host.

## providers { #providers }

A company or club the lab depends on: an ISP, a hoster, a service bought from outside, the hackerspace.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="providers-contact"></span>`contact` | string |  | How to reach them (support address, phone, ticket system). |
| <span id="providers-name"></span>`name` | string | required | Display name of the company or club. |
| <span id="providers-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="providers-url"></span>`url` | string |  | Website or customer portal. |

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

Rule beyond the schema: something refers to every provider – a site, a line, a service or a contract.

## contracts { #contracts }

What is paid to a provider. A provider can have several; a host, line or service names the ones it is paid by.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="contracts-cost"></span>`cost` | object |  | What it costs. Leave it out until known - the contract is then listed in pending. |
| <span id="contracts-cost-amount"></span>`cost.amount` | integer ≥ 0 | required | Amount per period in cents (899 = 8.99) - whole numbers only. |
| <span id="contracts-cost-currency"></span>`cost.currency` | one of `EUR` `USD` `CHF` `GBP` | required | Currency of amount. Totals are kept per currency, never converted. |
| <span id="contracts-cost-duemonth"></span>`cost.dueMonth` | integer 1–12 |  | Only with period year, and required there: the month (1-12) the yearly amount is charged in. |
| <span id="contracts-cost-period"></span>`cost.period` | one of `month` `year` `once` | required | How often amount is charged. |
| <span id="contracts-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="contracts-notice"></span>`notice` | string |  | Notice period, as the contract words it. |
| <span id="contracts-product"></span>`product` | string |  | Product or plan name as the provider calls it. |
| <span id="contracts-provider"></span>`provider` | id from [providers](#providers) | required | Who the contract is with. |
| <span id="contracts-renews"></span>`renews` | string: a date like 2026-10-22 |  | Next date the contract renews or ends unless cancelled. |
| <span id="contracts-since"></span>`since` | string: a date like 2026-10-22 |  | Start of the contract. |

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

Rules beyond the schema: `cost.dueMonth` exactly with `period` `year`; `renews` not before `since`; a contract named by a host, line or service is with that one's provider (for a host: the provider of its site). A contract without `cost` is listed under `pending`, one nothing names under `gaps`.

## uplinks { #uplinks }

An internet line. All fields are optional, so a line can be entered before its details are known.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="uplinks-asn"></span>`asn` | integer ≥ 1 |  | Autonomous system number of the provider's network, without the AS prefix. |
| <span id="uplinks-bandwidth"></span>`bandwidth` | object |  | Booked bandwidth in Mbit/s. |
| <span id="uplinks-bandwidth-down"></span>`bandwidth.down` | integer ≥ 1 | required | Downstream in Mbit/s. |
| <span id="uplinks-bandwidth-up"></span>`bandwidth.up` | integer ≥ 1 | required | Upstream in Mbit/s. |
| <span id="uplinks-contracts"></span>`contracts` | list of id from [contracts](#contracts), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="uplinks-ipv4"></span>`ipv4` | one of `public` `cgnat` `none` |  | What the line gives for IPv4. |
| <span id="uplinks-ipv4static"></span>`ipv4Static` | boolean |  | Whether the public IPv4 address is fixed. Only meaningful with ipv4 = public. |
| <span id="uplinks-ipv6"></span>`ipv6` | boolean |  | Whether the line has native IPv6. |
| <span id="uplinks-ipv6prefixlength"></span>`ipv6PrefixLength` | integer 1–128 |  | Size of the IPv6 prefix the provider delegates (e.g. 56 for a /56). Only with ipv6. |
| <span id="uplinks-ipv6static"></span>`ipv6Static` | boolean |  | Whether the delegated IPv6 prefix is fixed. Only with ipv6. |
| <span id="uplinks-medium"></span>`medium` | one of `fiber` `dsl` `cable` `lte` `satellite` `datacenter` |  | Kind of line. |
| <span id="uplinks-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="uplinks-provider"></span>`provider` | id from [providers](#providers) |  | Internet provider (for a data centre: the hoster). |

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

Rules beyond the schema: `ipv6PrefixLength` and `ipv6Static` only with `ipv6`; every line is used by a site; `contracts` are with the line's `provider`.

## sites { #sites }

A place where devices stand.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="sites-city"></span>`city` | string | required | City the site is in. |
| <span id="sites-ipv6ula"></span>`ipv6Ula` | string: a ULA /48 like fd12:3456:789a::/48 |  | Unique local IPv6 prefix of the site (RFC 4193, random 40 bits). Only where the lab runs the network; its networks take their /64 by ipv6SubnetId. |
| <span id="sites-kind"></span>`kind` | one of `residential` `hackerspace` `club` `datacenter` | required | Kind of place. club: a club's premises the lab connects to (Remote, issue #84). |
| <span id="sites-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="sites-provider"></span>`provider` | id from [providers](#providers) |  | Who runs the place (hoster, club); empty for a home. |
| <span id="sites-uplinks"></span>`uplinks` | list of id from [uplinks](#uplinks), no duplicates | required | Internet lines of the site, the primary one first, backups after it. |

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

Rules beyond the schema: at least one uplink, the primary first; something stands at every site. `ipv6Ula` only where the lab runs the network itself – random once (RFC 4193), never changed afterwards.

## networks { #networks }

A layer-2 network with its IPv4 prefix.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="networks-dhcppool"></span>`dhcpPool` | object |  | Range the DHCP server hands out dynamically; static addresses must lie outside it. |
| <span id="networks-dhcppool-end"></span>`dhcpPool.end` | string: an IPv4 address | required | Last address of the pool. |
| <span id="networks-dhcppool-start"></span>`dhcpPool.start` | string: an IPv4 address | required | First address of the pool. |
| <span id="networks-dhcpserver"></span>`dhcpServer` | id from [hosts](#hosts) |  | The host serving DHCP for IPv4 here; it needs an interface in this network. |
| <span id="networks-ipv4"></span>`ipv4` | string: an IPv4 prefix like 192.0.2.0/24 |  | IPv4 prefix. |
| <span id="networks-ipv6"></span>`ipv6` | string: an IPv6 prefix like 2001:db8::/64 |  | IPv6 prefix, when it is fixed (static GUA). A ULA from the site's ipv6Ula is derived, not entered. |
| <span id="networks-ipv6subnetid"></span>`ipv6SubnetId` | integer 0–65535 |  | Subnet id of the network, decimal (192, often the VLAN id): its /64 inside the site's ipv6Ula and inside the prefix the primary uplink delegates. The hex form is derived. |
| <span id="networks-name"></span>`name` | string | required | Display name. |
| <span id="networks-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="networks-site"></span>`site` | id from [sites](#sites) | required | Where the network is. |
| <span id="networks-vlan"></span>`vlan` | integer 1–4094 |  | 802.1Q VLAN id. Leave out for an untagged network. |

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

Rules beyond the schema: the prefix has no host bits; the pool lies inside it, start before end, and needs `ipv4` and `dhcpServer`; the DHCP server is at the site and has an interface in the network; a VLAN id once per site; `ipv6SubnetId` once per site and small enough for the prefix the primary uplink delegates (0–255 for a /56). It is decimal; the derived view adds `ipv6SubnetHex` and the network's ULA `/64`.

## hosts { #hosts }

Every device with an address that matters – managed by this flake or not.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="hosts-availability"></span>`availability` | one of `always-on` `intermittent` | default `"always-on"` | intermittent: being offline is normal (a laptop) and is not an incident. |
| <span id="hosts-contracts"></span>`contracts` | list of id from [contracts](#contracts), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="hosts-criticality"></span>`criticality` | one of `core` `service` `lab` | default `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="hosts-inside"></span>`inside` | id from [hosts](#hosts) |  | Physically built into another device, e.g. a PCIe KVM card in its host. |
| <span id="hosts-interfaces"></span>`interfaces` | object: name → object |  | Network interfaces by name (as the OS calls them; for an appliance any label like lan/wan). A VLAN interface (eno1.10) is an entry of its own. |
| <span id="hosts-interfaces-name-connector"></span>`interfaces.<name>.connector` | one of `qsfp-plus` `qsfp28` `rj45` `sfp` `sfp-plus` `sfp28` |  | Only ethernet: the port - rj45 or an SFP/QSFP cage. |
| <span id="hosts-interfaces-name-ipv4"></span>`interfaces.<name>.ipv4` | object |  | IPv4 addressing of this interface in its network. |
| <span id="hosts-interfaces-name-ipv4-address"></span>`interfaces.<name>.ipv4.address` | string: an IPv4 address |  | The address - required for reserved and static. |
| <span id="hosts-interfaces-name-ipv4-mode"></span>`interfaces.<name>.ipv4.mode` | one of `reserved` `static` `dhcp` | required | reserved: fixed DHCP lease by MAC; static: configured on the device; dhcp: dynamic. |
| <span id="hosts-interfaces-name-linklocal"></span>`interfaces.<name>.linkLocal` | string: eui64, stable-privacy, random or an fe80:: address |  | How the IPv6 link-local address is formed: eui64 (computed from mac), stable-privacy (RFC 7217), random - or the fixed fe80:: address itself. |
| <span id="hosts-interfaces-name-mac"></span>`interfaces.<name>.mac` | string: a lower-case MAC address like aa:bb:cc:dd:ee:ff |  | Hardware address, lower case. |
| <span id="hosts-interfaces-name-maclocal"></span>`interfaces.<name>.macLocal` | boolean |  | The mac is locally administered on purpose and expected to stay: a provider's VM NIC, or a device that ships with one. Required for such a mac, wrong for any other. Not for a private (random) Wi-Fi address, which does not belong in here at all. |
| <span id="hosts-interfaces-name-medium"></span>`interfaces.<name>.medium` | one of `ethernet` `wifi` |  | Physical medium. |
| <span id="hosts-interfaces-name-module"></span>`interfaces.<name>.module` | object |  | Only a cage (not rj45): what is plugged into it. |
| <span id="hosts-interfaces-name-module-kind"></span>`interfaces.<name>.module.kind` | one of `dac` `aoc` `sm` `mm` `copper` | required | dac/aoc: a fixed cable; sm/mm: a transceiver for singlemode/multimode fibre; copper: an RJ45 transceiver. |
| <span id="hosts-interfaces-name-module-standard"></span>`interfaces.<name>.module.standard` | one of `1000base-bx` `1000base-lx` `1000base-sx` `1000base-t` `10gbase-bx` `10gbase-er` `10gbase-lr` `10gbase-lrm` `10gbase-sr` `10gbase-t` `2.5gbase-t` `25gbase-lr` `25gbase-sr` |  | Only a transceiver (not dac/aoc): the standard printed on it, e.g. 10gbase-sr. |
| <span id="hosts-interfaces-name-network"></span>`interfaces.<name>.network` | id from [networks](#networks) |  | The network this interface is in. |
| <span id="hosts-interfaces-name-note"></span>`interfaces.<name>.note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-interfaces-name-speed"></span>`interfaces.<name>.speed` | one of `10` `100` `1000` `2500` `5000` `10000` `25000` `40000` `100000` |  | Only ethernet: the most this interface can do, in Mbit/s (2500 = 2.5G) - with what sits in its cage, not what the link partner negotiates. |
| <span id="hosts-interfaces-name-wifistandard"></span>`interfaces.<name>.wifiStandard` | one of `wifi4` `wifi5` `wifi6` `wifi6e` `wifi7` |  | Only wifi: the newest Wi-Fi generation the interface supports. |
| <span id="hosts-kind"></span>`kind` | one of `server` `hypervisor` `vm` `container` `router` `switch` `ap` `pdu` `ups` `kvm` `nas` `workstation` `laptop` `phone` `tablet` `watch` `appliance` | required | What the device is. |
| <span id="hosts-managed"></span>`managed` | boolean | required | Configured by this flake (nixosConfigurations/darwinConfigurations). Must match the flake. |
| <span id="hosts-manages"></span>`manages` | list of id from [hosts](#hosts), no duplicates |  | Only kvm: the machines this KVM gives out-of-band access to. |
| <span id="hosts-model"></span>`model` | string |  | Hardware model without the vendor (ThinkCentre M720q), or for a VM the provider's product or plan name. |
| <span id="hosts-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="hosts-owner"></span>`owner` | id from [owners](#owners) | required | Who administers the device. |
| <span id="hosts-power"></span>`power` | id from [hosts](#hosts) |  | Where the power comes from: a PDU/UPS, a PoE switch, or the host a card sits in. |
| <span id="hosts-productid"></span>`productId` | string |  | The vendor's product id for drivers and firmware: Lenovo machine type (10T7...), Apple model identifier (Mac16,10). Not for vm/container. |
| <span id="hosts-runson"></span>`runsOn` | id from [hosts](#hosts) |  | Only vm/container: the machine it runs on. Optional - a rented VM's host is not in the inventory. |
| <span id="hosts-serial"></span>`serial` | string |  | Serial number. Unique lab-wide. Not for vm/container. |
| <span id="hosts-site"></span>`site` | id from [sites](#sites) |  | Where the device is. Optional for entries with runsOn or inside - they inherit it. |
| <span id="hosts-sshhostkeys"></span>`sshHostKeys` | list of string: an OpenSSH public key "<type> <base64>" without comment, no duplicates |  | The device's SSH host public keys (/etc/ssh/ssh_host_*_key.pub without the comment). Feeds known_hosts and the sops check. |
| <span id="hosts-unlock"></span>`unlock` | object |  | Disk unlock after a reboot. Leave it out for an unencrypted disk. |
| <span id="hosts-unlock-fallback"></span>`unlock.fallback` | one of `remote-ssh` `console` |  | How a human unlocks when the methods fail: over SSH (initrd, FileVault) or at the console/KVM. |
| <span id="hosts-unlock-methods"></span>`unlock.methods` | list of one of `tpm` `nbde`, no duplicates | required | Automatic unlock methods. Empty when only a human can unlock. |
| <span id="hosts-unlock-tang"></span>`unlock.tang` | list of id from [hosts](#hosts), no duplicates |  | Tang servers for nbde; any one of them is enough. |
| <span id="hosts-unlock-threshold"></span>`unlock.threshold` | integer ≥ 1 | default `1` | How many of the methods must succeed (Clevis sss threshold). Defaults to 1. |
| <span id="hosts-vendor"></span>`vendor` | string |  | Hardware manufacturer (Lenovo, Apple, GL.iNet). Not for vm/container. |

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

Rules beyond the schema (the most important ones – [Validation](inventory.md#validation) has all):

- `site` is required unless it can be inherited along `runsOn` or `inside`, and an explicit one matches the inherited one.
- `runsOn` only for `vm`/`container`, on an allowed kind; `manages` only for `kvm`; `vendor`/`productId`/`serial` not on a `vm`/`container`.
- `runsOn`, `inside` and `power` free of cycles; every host with `nbde` reaches a Tang server that comes up without a human.
- `managed` matches `flake.nix` in both directions.
- Addresses: inside the network's prefix, by mode (`reserved` needs `mac` and a DHCP server, `static` outside the pool), each once per network; MACs and host keys once lab-wide.

## services { #services }

What the hosts run, and what is bought from outside.

| Field | Type | | Meaning (from the schema) |
| --- | --- | --- | --- |
| <span id="services-backup"></span>`backup` | list of object, no duplicates |  | How its data is backed up. Only for stateful. |
| <span id="services-backup-interval"></span>`backup[].interval` | one of `hourly` `daily` `weekly` `monthly` |  | How often it runs. |
| <span id="services-backup-keep"></span>`backup[].keep` | object |  | Which versions are kept - at the target, or on the machine without to. Left out: unknown. |
| <span id="services-backup-keep-all"></span>`backup[].keep.all` | boolean |  | Only true, and only alone: every version is kept, nothing is ever pruned. |
| <span id="services-backup-keep-daily"></span>`backup[].keep.daily` | integer ≥ 1 |  | One per day for the last n days. |
| <span id="services-backup-keep-last"></span>`backup[].keep.last` | integer ≥ 1 |  | The newest n versions. |
| <span id="services-backup-keep-monthly"></span>`backup[].keep.monthly` | integer ≥ 1 |  | One per month for the last n months. |
| <span id="services-backup-keep-weekly"></span>`backup[].keep.weekly` | integer ≥ 1 |  | One per week for the last n weeks. |
| <span id="services-backup-method"></span>`backup[].method` | one of `restic` `arq` `btrbk` `pgdump` `provider-snapshot` `ha-backup` | required | restic/arq copy to another service (to); btrbk, pgdump and provider-snapshot stay on the same machine or provider; ha-backup (Home Assistant's own backup) stays on the machine without to, or goes to an upload target with to. |
| <span id="services-backup-note"></span>`backup[].note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-backup-to"></span>`backup[].to` | id from [services](#services) |  | The service the copy goes to - required with restic/arq, optional with ha-backup. |
| <span id="services-contracts"></span>`contracts` | list of id from [contracts](#contracts), no duplicates |  | The contracts this is paid for by (a rented VM, its extra IPv4, a line, a plan). |
| <span id="services-criticality"></span>`criticality` | one of `core` `service` `lab` | default `"service"` | core: the lab stops working without it; service: a service is down; lab: nothing depends on it. |
| <span id="services-data"></span>`data` | one of `stateful` `stateless` | required | stateful: it keeps data that is lost with it; stateless: it can be rebuilt from the repository. |
| <span id="services-dependson"></span>`dependsOn` | list of id from [services](#services), no duplicates |  | Services it cannot work without. |
| <span id="services-endpoints"></span>`endpoints` | list of object, no duplicates |  | How the service is reached. |
| <span id="services-endpoints-exposure"></span>`endpoints[].exposure` | one of `public` `proxy` `mesh` `lan` `loopback` | required | public: open on the internet from its own host; proxy: through a reverse proxy (name it in via); mesh: only inside the overlay network; lan: only in a local network; loopback: only on the host itself. |
| <span id="services-endpoints-fqdn"></span>`endpoints[].fqdn` | string: a lower-case domain name like cloud.example.org | required | Name it is reached by. |
| <span id="services-endpoints-note"></span>`endpoints[].note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-endpoints-port"></span>`endpoints[].port` | integer 1–65535 |  | Port, when it is not the protocol's default. |
| <span id="services-endpoints-via"></span>`endpoints[].via` | id from [services](#services) |  | The service it is reached through - the reverse proxy for exposure proxy (required there). Counts as a dependency. |
| <span id="services-hosts"></span>`hosts` | list of id from [hosts](#hosts), no duplicates |  | The machines it runs on. Exactly one of hosts and provider. |
| <span id="services-name"></span>`name` | string | required | Display name. |
| <span id="services-note"></span>`note` | string |  | Free text: anything worth knowing that has no field of its own. |
| <span id="services-package"></span>`package` | string |  | Only on managed hosts: option path of the package in the host's configuration (services.paperless.package) - version, license and language are read from there. |
| <span id="services-provider"></span>`provider` | id from [providers](#providers) |  | For a service bought from outside: who runs it. Exactly one of hosts and provider. |
| <span id="services-software"></span>`software` | string |  | The software it is (Paperless-ngx, Garage) - the version comes from package or version. |
| <span id="services-uses"></span>`uses` | list of id from [services](#services), no duplicates |  | Services it works without, but degraded (new logins fail, one feature is missing). |
| <span id="services-version"></span>`version` | string |  | Version, by hand - only where there is no package to read it from. |

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

Rules beyond the schema: exactly one of `hosts` and `provider`; `package` only on managed hosts and not together with `version`; no `core`/`service` service on an `intermittent` host; no hard dependency (`dependsOn`, `via`) on a less critical service, and none in a cycle; `via` required with `exposure` `proxy`; every `fqdn` once; `backup` only for `stateful`, `to` exactly with `restic`/`arq`. A `stateful` service whose backups all stay on its own hosts – `storage` above – is listed under `gaps`.

## A complete example

A valid inventory with every section – the source of the examples above, `docs/inventory-example.json`. Copy it as a start; `"$schema": "./inventory.schema.json"` at the top gives the editor its completion.

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

What `just inventory` derives from it, for instance: `hosts.club-vm.site` is `club` (inherited from `pve`); `services.docs.upstreamHosts` is `club-vm`, `pve`, `vps`; `providers.hoster.affects` is `docs`, `login`, `proxy`; `costs.monthly` is `{"EUR": 6145, "USD": 250}`, and November carries the 30.00 USD of the mail contract in `costs.byMonth`.

## In the editor

`inventory.json` starts with `"$schema": "./inventory.schema.json"`. Editors that read JSON Schema (VS Code, Zed, IntelliJ, Neovim with a JSON language server) then offer the fields as completion, show the descriptions of the tables above on hover, and underline wrong types, unknown fields and malformed values while typing. References and every rule between entries are only checked by `nix flake check` (or `just inventory-test`).

After changing `spec` in `inventory.nix`: `just inventory-schema` and `just inventory-diagram`, a test case in `tests/inventory.nix`, and – if the example should show the new field – `docs/inventory-example.json`. The checks fail until all of it is in step.
