#!/usr/bin/env python3
"""Writes the pages of one site language as plain Markdown next to the built
site, plus llms.txt and llms-full.txt (https://llmstxt.org) - for language
models, which read Markdown far cheaper than the HTML pages. Runs after
`zensical build` with the same config (docs/site-build.sh, the public
repo's workflow).

Usage: gen-llms.py <zensical.<lang>.toml>

- docs_dir, site_dir, site_url and the nav come from the toml (as
  site-src.sh filled it in); paths are relative to the toml, like Zensical.
- Every page in the nav lands at its source path in site_dir
  (how-to/new-host.md next to how-to/new-host/), so its relative links and
  images resolve as in the sources.
- Cleaned for the reader: front matter and HTML comments are dropped, an
  inline diagram (<figure> with an <svg>) becomes its aria-label, the lab
  map's HTML becomes its JSON data block as a code block - the data stays,
  the markup the map is drawn with goes.
- llms.txt: the nav as link lists, one line of description per page (its
  first paragraph's first sentence), links to llms-full.txt and the other
  languages (extra.alternate). llms-full.txt: all pages in nav order, links
  made absolute.
"""
import html
import pathlib
import posixpath
import re
import sys
import tomllib
from urllib.parse import urljoin

toml_path = pathlib.Path(sys.argv[1])
base = toml_path.parent
cfg = tomllib.loads(toml_path.read_text(encoding="utf-8"))["project"]
docs = base / cfg["docs_dir"]
out = base / cfg["site_dir"]
site_url = cfg["site_url"]
lang = cfg["theme"]["language"]
TEXT = {
    "en": {"diagram": "Diagram", "full": "All pages in one file", "other": "Other languages",
           "map": "The map's data (generated from inventory.json):"},
    "de": {"diagram": "Diagramm", "full": "Alle Seiten in einer Datei", "other": "Andere Sprachen",
           "map": "Die Daten der Karte (aus inventory.json erzeugt):"},
}[lang]

FIGURE = re.compile(r"<figure\b[^>]*>.*?</figure>", re.S)
LABEL = re.compile(r'aria-label="([^"]*)"')
DATA = re.compile(r'<script type="application/json"[^>]*>(.*?)</script>', re.S)
LINK = re.compile(r"(!?\[[^\]]*\]\()([^)\s]+)(\))")


def clean(text):
    if text.startswith("---\n"):
        text = text[text.index("\n---\n", 4) + 5:].lstrip("\n")
    text = re.sub(r"<!--.*?-->\n?", "", text, flags=re.S)

    def figure(m):
        f = m.group(0)
        data = DATA.search(f)
        if data:
            # gen-lab-map.py escapes </ so it cannot end the script early.
            json = data.group(1).replace("<\\/", "</")
            return f"{TEXT['map']}\n\n```json\n{json}\n```"
        label = LABEL.search(f)
        if "<svg" in f and label:
            return f"*[{TEXT['diagram']}: {label.group(1)}]*"
        return f

    return re.sub(r"\n{3,}", "\n\n", FIGURE.sub(figure, text))


def pages(nav, section=None):
    """(section title or None, page path) in nav order."""
    for entry in nav:
        if isinstance(entry, str):
            yield section, entry
            continue
        for title, value in entry.items():
            if isinstance(value, str):
                yield section, value
            else:
                yield from pages(value, title)


def url(page):
    return urljoin(site_url, page)


def title_and_summary(text):
    title, summary = "", ""
    for para in re.split(r"\n\s*\n", text):
        para = para.strip()
        if not title and para.startswith("# "):
            title = html.unescape(para[2:].splitlines()[0].strip())
        elif title and para and not re.match(r"[#<>|!*`-]|As of:|Stand:", para):
            plain = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", " ".join(para.split()))
            # Not after "e.g.", "z. B." and the like.
            summary = re.split(r"(?<![^\w]\w\.)(?<!\w\.\w\.)(?<=[.:;])\s", plain, maxsplit=1)[0].rstrip(":;")
            break
    return title, summary


def absolute(text, page):
    """Relative links of a page as absolute URLs, for llms-full.txt."""
    def fix(m):
        target = m.group(2)
        if re.match(r"[a-z][a-z0-9+.-]*:", target):
            return m.group(0)
        if target.startswith("#"):
            return m.group(1) + url(page) + target + m.group(3)
        path = posixpath.normpath(posixpath.join(posixpath.dirname(page), target))
        return m.group(1) + url(path) + m.group(3)
    return LINK.sub(fix, text)


index = [f"# {cfg['site_name']}", "", f"> {cfg['site_description']}", "",
         f"{TEXT['full']}: [llms-full.txt]({url('llms-full.txt')})"]
others = [a for a in cfg.get("extra", {}).get("alternate", []) if a.get("lang") != lang]
if others:
    index[-1] += f" · {TEXT['other']}: " + ", ".join(
        f"[{a['name']}]({urljoin(site_url, a['link'] + 'llms.txt')})" for a in others)
index.append("")
full = []
current = None
for section, page in pages(cfg["nav"]):
    text = clean((docs / page).read_text(encoding="utf-8"))
    target = out / page
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    full.append(absolute(text, page).rstrip("\n"))
    if section != current:
        index += ["", f"## {section}", ""]
        current = section
    title, summary = title_and_summary(text)
    index.append(f"- [{title}]({url(page)})" + (f": {summary}" if summary else ""))

(out / "llms.txt").write_text("\n".join(index) + "\n", encoding="utf-8")
(out / "llms-full.txt").write_text("\n\n---\n\n".join(full) + "\n", encoding="utf-8")
