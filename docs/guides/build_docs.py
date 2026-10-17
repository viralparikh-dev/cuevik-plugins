#!/usr/bin/env python3
"""Build the Cuevik Plugins walkthrough (.html + .pdf) from its .md source.

Usage:  python docs/guides/build_docs.py            (run from anywhere)

The .md file is the only one edited by hand. This script:
  1. checks every internal #link resolves to a heading
  2. writes <guide>.html (self-contained, print-ready) and <guide>.pdf (A4, via installed Chrome)
Any failed check stops the build so the files never drift apart.
"""
import re, sys
from pathlib import Path
import markdown

DOCS = Path(__file__).resolve().parent
MD = DOCS / "Cuevik-Plugins_Walkthrough.md"
HTML = MD.with_suffix(".html")
PDF = MD.with_suffix(".pdf")
EYEBROW = "Cuevik Plugins · Walkthrough"


def fail(msg):
    sys.exit(f"SYNC CHECK FAILED: {msg}")


def slug(value, sep="-"):
    value = re.sub(r"[^\w\s-]", "", value).strip().lower()
    return re.sub(r"[-\s]+", sep, value)


# ---------------------------------------------------------------------------------------------
# Styling: Cuevik design tokens (light mode). Values are copied verbatim; change them only when
# the design system changes, and keep tier-1 primitives out of component rules (semantic tokens
# only).
# ---------------------------------------------------------------------------------------------
TOKENS = """
:root{
  /* tier 1 - brand primitives (verbatim) */
  --clay-100:#e7ebf0; --clay-300:#a0b0bf; --clay-600:#0c385a; --clay-700:#072740;
  --moss-100:#dfecf8; --moss-700:#1c689c;
  --stone-50:#fafafa; --stone-100:#f2f2f2; --stone-200:#d4d4d4; --stone-600:#676767; --stone-900:#1a1a1a;
  /* tier 2 - semantic tokens (the only names used below) */
  --background:var(--stone-50); --foreground:var(--stone-900);
  --card:#ffffff; --card-foreground:var(--stone-900);
  --primary:var(--clay-600); --primary-foreground:#ffffff; --primary-text:var(--clay-600);
  --primary-hover:var(--clay-700); --primary-muted:var(--clay-100); --primary-border:var(--clay-300);
  --muted:var(--stone-100); --muted-foreground:var(--stone-600);
  --border:var(--stone-200); --ring:var(--clay-600);
  --info:var(--moss-700); --info-muted:var(--moss-100); --info-border:#85a9c8;
  --warning:#9c5400; --warning-muted:#fbebd6; --warning-border:#d5b196;
  --destructive:#9b2d00; --destructive-muted:#f7eae6; --destructive-border:#d8a291;
  /* scales */
  --radius-sm:6px; --radius-md:10px; --radius-lg:16px;
  --text-xs:12px; --text-sm:13px; --text-base:15px; --text-md:17px; --text-lg:20px; --text-2xl:30px;
  --leading-tight:1.15; --leading-snug:1.35; --leading-normal:1.55;
  --tracking-tight:-0.01em;
  --shadow-xs:0 1px 2px rgba(26,26,26,0.06);
  --font-sans:"Archivo",Arial,Helvetica,sans-serif;
  --font-mono:"IBM Plex Mono",Consolas,Menlo,monospace;
}
"""

CSS = """
*{box-sizing:border-box;-webkit-print-color-adjust:exact;print-color-adjust:exact}
html,body{margin:0;background:var(--background);color:var(--foreground)}
body{font:400 var(--text-base)/var(--leading-normal) var(--font-sans)}
main{max-width:210mm;margin:0 auto;padding:13mm 14mm 16mm}
h1,h2,h3{font-weight:600;letter-spacing:var(--tracking-tight);color:var(--foreground)}
h1{font-size:var(--text-2xl);line-height:var(--leading-tight);margin:2px 0 8px}
h2{font-size:var(--text-lg);line-height:var(--leading-snug);margin:30px 0 10px;break-after:avoid;break-inside:avoid}
.keep{break-inside:avoid}
.keep>h2,.keep>h3{margin-top:0}
.keep.k2{margin-top:30px}
.keep.k3{margin-top:18px}
section.sec{margin-top:30px}
h3{font-size:var(--text-md);line-height:var(--leading-snug);margin:18px 0 6px;break-after:avoid}
h2 .num{vertical-align:2px;margin-right:10px;display:inline-flex;align-items:center;justify-content:center;min-width:28px;height:28px;padding:0 8px;border-radius:999px;
  background:var(--foreground);color:var(--card);font-size:var(--text-sm);font-weight:600;letter-spacing:0}
p{margin:0 0 8px}
ul,ol{margin:4px 0 10px;padding-left:22px} li{margin:3px 0}
strong{font-weight:600}
a{color:var(--primary-text);font-weight:600;text-decoration:none}
a:hover{text-decoration:underline;color:var(--primary-hover)}
a:focus-visible{outline:3px solid var(--ring);outline-offset:2px;border-radius:var(--radius-sm)}
code{font-family:var(--font-mono);font-size:0.86em;background:var(--muted);border-radius:var(--radius-sm);padding:1px 5px;color:var(--foreground)}
pre{background:var(--card);border:1px solid var(--border);border-left:3px solid var(--primary);border-radius:var(--radius-md);
  padding:10px 14px;margin:8px 0 12px;overflow-x:auto;break-inside:avoid}
pre code{background:none;padding:0;font-size:var(--text-sm);line-height:1.6}
hr{display:none}

/* header */
.hero{margin-bottom:18px}
.eyebrow{font-size:var(--text-xs);font-weight:600;color:var(--muted-foreground);letter-spacing:0.04em}
.meta{display:flex;flex-wrap:wrap;gap:6px;margin:8px 0 12px}
.chip{display:inline-flex;align-items:center;gap:6px;border:1px solid var(--primary-border);background:var(--primary-muted);color:var(--primary-text);
  border-radius:999px;padding:2px 10px;font-size:var(--text-xs);font-weight:600}
.chip.neutral{border-color:var(--border);background:var(--card);color:var(--foreground)}
.chip code{background:none;padding:0;color:inherit;font-size:var(--text-xs)}
.lead{font-size:var(--text-md);line-height:var(--leading-snug);max-width:165mm}

/* contents card */
.toc{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-lg);box-shadow:var(--shadow-xs);padding:12px 16px;margin:6px 0 4px;break-inside:avoid}
.toc .ttl{font-size:var(--text-sm);font-weight:600;color:var(--muted-foreground);margin-bottom:4px}
.toc ul{list-style:none;margin:0;padding:0;columns:2;column-gap:28px}
.toc li{margin:2px 0;font-size:var(--text-sm);break-inside:avoid}
.toc li ul{display:none}

/* tables */
.tbl.short{break-inside:avoid}
.tbl{border:1px solid var(--border);border-radius:var(--radius-md);overflow:hidden;background:var(--card);margin:8px 0 14px}
table{width:100%;border-collapse:collapse;font-size:var(--text-sm)}
th,td{text-align:left;vertical-align:top;padding:6px 10px;border-bottom:1px solid var(--border)}
thead{display:table-header-group}
th{background:var(--muted);color:var(--foreground);font-weight:600;font-size:var(--text-xs)}
tr:last-child td{border-bottom:0}
tr{break-inside:avoid}
td:first-child,td.nw{white-space:nowrap}
td code{white-space:nowrap}

/* footer note */
.foot{margin-top:22px;padding-top:8px;border-top:1px solid var(--border);font-size:var(--text-xs);color:var(--muted-foreground)}

@page{size:A4;margin:12mm 0 14mm}
@media print{main{padding-top:0;padding-bottom:0}pre,pre code{white-space:pre-wrap;overflow-wrap:anywhere}}
@media screen{main{background:var(--background)}}
@media screen and (max-width:820px){main{padding:16px}.toc ul{columns:1}td:first-child,td code{white-space:normal}.tbl{overflow-x:auto}}
"""


def font_faces():
    import base64
    faces = []
    for fam, stem, weights in (("Archivo", "archivo", (400, 600, 700)), ("IBM Plex Mono", "ibm-plex-mono", (400, 600))):
        for w in weights:
            f = DOCS / "fonts" / f"{stem}-latin-{w}-normal.woff2"
            b64 = base64.b64encode(f.read_bytes()).decode()
            faces.append(f'@font-face{{font-family:"{fam}";font-style:normal;font-weight:{w};font-display:block;'
                         f'src:url(data:font/woff2;base64,{b64}) format("woff2")}}')
    return "\n".join(faces)


def shape(body_html):
    """Turn plain markdown HTML into the Cuevik document layout."""
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(body_html, "html.parser")
    h1 = soup.find("h1")
    meta_p = h1.find_next_sibling("p")
    lead_p = meta_p.find_next_sibling("p")
    hero = soup.new_tag("header", attrs={"class": "hero"})
    eyebrow = soup.new_tag("div", attrs={"class": "eyebrow"}); eyebrow.string = EYEBROW
    meta = soup.new_tag("div", attrs={"class": "meta"})
    for part in re.split(r"\s+·\s+", meta_p.decode_contents()):
        label = re.sub(r"<[^>]+>", "", part).split(":", 1)
        chip = soup.new_tag("span", attrs={"class": "chip" if "Plugin" in label[0] else "chip neutral"})
        chip.append(BeautifulSoup(re.sub(r"<strong>[^<]*</strong>\s*", "", part), "html.parser"))
        chip.insert(0, label[0].strip() + " ")
        meta.append(chip)
    lead_p["class"] = "lead"
    h1.insert_before(hero)
    for el in (eyebrow, h1.extract(), meta):
        hero.append(el)
    meta_p.decompose()
    hero.append(lead_p.extract())
    for h2 in soup.find_all("h2"):
        m = re.match(r"(\d+)\.\s+(.*)", h2.get_text())
        if m:
            h2.clear()
            num = soup.new_tag("span", attrs={"class": "num"}); num.string = m.group(1)
            h2.append(num); h2.append(m.group(2))
    for t in soup.find_all("table"):
        short = len(t.find_all("tr")) <= 9
        wrap = soup.new_tag("div", attrs={"class": "tbl short" if short else "tbl"}); t.wrap(wrap)
        for td in t.find_all("td"):
            if len(td.get_text(strip=True)) <= 12:
                td["class"] = "nw"
    # keep every heading with the block that follows it (no orphaned headings at page foot)
    for h in soup.find_all(["h2", "h3"]):
        nxt = h.find_next_sibling()
        if nxt is None:
            continue
        if "tbl" in (nxt.get("class") or []) and len(nxt.find_all("tr")) > 9:
            continue  # long tables may split across pages (header row repeats); short ones stay with their heading
        keep = soup.new_tag("div", attrs={"class": f"keep k{h.name[1]}"})
        h.insert_before(keep); keep.append(h.extract()); keep.append(nxt.extract())
    foot = soup.new_tag("div", attrs={"class": "foot"})
    foot.string = f"{EYEBROW} · Generated from {MD.name} by docs/guides/build_docs.py"
    soup.append(foot)
    return str(soup)


def build():
    text = MD.read_text(encoding="utf-8")
    md = markdown.Markdown(extensions=["tables", "fenced_code", "toc", "sane_lists"],
                           extension_configs={"toc": {"slugify": slug, "toc_depth": "2-3"}})
    body = md.convert(text)
    ids = set(re.findall(r'id="([^"]+)"', body))
    broken = [l for l in re.findall(r'href="#([^"]+)"', body) if l not in ids]
    if broken:
        fail(f"broken internal links: {broken}")
    title = re.search(r"^# (.+)$", text, re.M).group(1)
    inner = re.sub(r'^<div class="toc">\s*|\s*</div>\s*$', "", md.toc.strip())
    toc = f'<nav class="toc"><div class="ttl">Contents</div>{inner}</nav>'
    body = body.replace("<hr />", toc + "<hr />", 1)  # contents after the intro block
    body = shape(body)
    html = (f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<meta name="generator" content="docs/guides/build_docs.py">'
            f"<title>{title}</title><style>{font_faces()}\n{TOKENS}{CSS}</style></head>"
            f"<body><main>{body}</main></body></html>")
    HTML.write_text(html, encoding="utf-8")
    print(f"wrote {HTML.name}")

    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(channel="chrome")
        pg = b.new_page()
        pg.goto(HTML.as_uri()); pg.wait_for_load_state("load")
        pg.evaluate("document.fonts.ready")
        pg.pdf(path=str(PDF), format="A4", print_background=True, prefer_css_page_size=True,
               display_header_footer=True, header_template="<span></span>",
               footer_template=('<div style="font:8px Arial,sans-serif;color:#676767;width:100%;padding:0 14mm;display:flex;justify-content:space-between">'
                                f'<span>{title}</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>'))
        b.close()
    print(f"wrote {PDF.name}")


if __name__ == "__main__":
    build()
