#!/usr/bin/env python3
"""Build the Cuevik Plugins guides from their .md sources, after sync checks.

Usage:  python docs/guides/build_docs.py            build everything; stops if a check fails
        python docs/guides/build_docs.py --write    refresh the generated blocks in the Walkthrough .md first
        python docs/guides/build_docs.py --check    run the checks only, write nothing
        python docs/guides/build_docs.py --release  also require exact plugin versions (final merge)

Edited by hand: Cuevik-Plugins_Walkthrough.md and Cuevik-Plugins_Overview.md. Generated:
  Walkthrough .html + .pdf, WalkthroughByActor .pdf (one page per plugin), Commands .pdf,
  Overview .html + .pdf.

Blocks between <!-- gen:NAME --> markers in the Walkthrough .md are generated from the step
registry (steps.yml), the default lineage and the two command tables in the Walkthrough itself, so
they cannot drift from them. The checks stop the build when:
  1. a generated block is stale
  2. the guide's plugin versions differ from plugin.json (major.minor; exact with --release)
  3. a command is documented but not a real step, or a step / skill on disk is undocumented
  4. an internal #link does not resolve, or a guide points at a temporary design doc
  5. a term from the local, gitignored .private-terms appears in a guide
  6. the Overview exposes an internal term, or lists different commands than the Walkthrough
"""
import argparse, base64, html as H, json, re, sys
from pathlib import Path
import markdown, yaml

DOCS = Path(__file__).resolve().parent
ROOT = DOCS.parent.parent
WALK = DOCS / "Cuevik-Plugins_Walkthrough.md"
OVER = DOCS / "Cuevik-Plugins_Overview.md"
BYACTOR = DOCS / "Cuevik-Plugins_WalkthroughByActor.pdf"
COMMANDS = DOCS / "Cuevik-Plugins_Commands.pdf"
PLUGINS = ("cuevik-start", "cuevik-ship", "cuevik-docs")
PLUGIN_TITLE = {"cuevik-start": "Cuevik Start", "cuevik-ship": "Cuevik Ship", "cuevik-docs": "Cuevik Docs"}
T1 = "What each command does"
T2 = "Branches and files (ship, docs and utility commands)"
CMD = re.compile(r"`/(cuevik-[a-z]+):([\w-]+)`")
GEN = re.compile(r"<!-- gen:([\w-]+) -->(.*?)<!-- /gen:\1 -->", re.S)
# Terms the Overview must not show: it is for readers who should not see how the plugins work inside.
OVERVIEW_BANNED = re.compile(
    r"(?i:\.cuevik|\.claude|lineage|runner|steps\.yml|SKILL\.md|worktree|frontmatter|contracts?"
    r"|DECISIONS\.md|\bbranch(?:es)?\b|\bpull requests?\b|\bgh\b|\bphase\b)|\bPRs?\b")


def fail(msg):
    sys.exit(f"CHECK FAILED: {msg}")


def warn(msg):
    print(f"warning: {msg}")


def slug(value, sep="-"):
    value = re.sub(r"[^\w\s-]", "", value).strip().lower()
    return re.sub(r"[-\s]+", sep, value)


def clip(s, n):
    return s if len(s) <= n else s[: n - 1].rstrip() + "…"


def plain(s):
    return s.replace("`", "")


def names(cmds):
    return ", ".join(f"/{p}:{c}" for p, c in sorted(cmds))


# ---------------------------------------------------------------------------------------------
# Data: what the plugins themselves say (step registry, default lineage, versions, skills)
# ---------------------------------------------------------------------------------------------
LANE_OF = {"Product Owner": "po", "Architect": "ar"}


def load():
    def read(*parts):
        return ROOT.joinpath(*parts).read_text(encoding="utf-8")

    versions = {p: json.loads(read("plugins", p, ".claude-plugin", "plugin.json"))["version"] for p in PLUGINS}
    steps = yaml.safe_load(read("plugins", "cuevik-start", "references", "steps.yml"))["steps"]
    lineage = {d["path"]: d for d in json.loads(read("contracts", "lineage", "lineage.example.json"))["documents"]}
    for s in steps:
        doc = lineage.get(s["outputs"][0])
        if doc is None:
            fail(f"step {s['id']}: no lineage entry for its primary output {s['outputs'][0]}")
        for who in (doc["owner"], *doc["reviewers"]):
            if who not in LANE_OF:
                fail(f"lineage role '{who}' has no lane in the by-actor diagram (known: {', '.join(LANE_OF)})")
        s.update(owner=doc["owner"], reviewers=doc["reviewers"], reads=doc["upstream"])
    skills = {(p, f.parent.name) for p in PLUGINS for f in (ROOT / "plugins" / p / "skills").glob("*/SKILL.md")}
    return {"versions": versions, "steps": steps, "docs": list(lineage.values()), "skills": skills}


def table_rows(text, heading):
    """Body rows of the first table under the H2/H3 `heading` (header and separator dropped)."""
    m = re.search(rf"^#{{2,3}} {re.escape(heading)}[ \t]*$", text, re.M)
    if not m:
        fail(f"{WALK.name}: no section '{heading}'")
    rest = text[m.end():]
    end = re.search(r"^#{1,6} ", rest, re.M)
    lines = [l.strip() for l in (rest[: end.start()] if end else rest).splitlines() if l.lstrip().startswith("|")]
    return [[c.strip() for c in l.strip("|").split("|")] for l in lines][2:]


def command_table(text, heading, ncols):
    """{(plugin, command): [other cells]} from a table whose first column is a `/plugin:command`."""
    out = {}
    for row in table_rows(text, heading):
        m = CMD.fullmatch(row[0])
        if not m or len(row) != ncols:
            fail(f"'{heading}': bad row {row[0]!r} (want a `/plugin:command` and {ncols} columns)")
        if m.groups() in out:
            fail(f"'{heading}': {row[0]} is listed twice")
        out[m.groups()] = row[1:]
    return out


# ---------------------------------------------------------------------------------------------
# Generated content: one row model feeds both the Mermaid (for the .md) and the SVG (html/pdf)
# ---------------------------------------------------------------------------------------------
def card(kind, **kw):
    return {"kind": kind, **kw}


def start_rows(d, t1):
    rows = []
    for s in d["steps"]:
        outs, num = s["outputs"], s["id"][:2]
        title = t1[("cuevik-start", s["id"])][0]
        main = card("step", pill=f"STEP {num}", title=title, cmd=s["id"],
                    note=outs[0] + (f" + {len(outs) - 1} more" if len(outs) > 1 else ""), m=f"{num} · {title}<br/>{s['id']}")
        side = [("gh", card("pr", l1="PR → main", l2="Approved by " + " + ".join(s["reviewers"]), m="PR → main"))]
        side += [(LANE_OF[r], card("chip", text=f"{r} co-reviews", m=f"{r} co-reviews")) for r in s["reviewers"] if r != s["owner"]]
        rows.append({"main": (LANE_OF[s["owner"]], main), "side": side})
    return rows


def start_lanes(rows):
    owns = {"po": [], "ar": []}
    for lane, c in (r["main"] for r in rows):
        owns[lane].append(c["pill"][5:])
    return [{"id": "po", "cls": "warm", "title": "Product Owner", "sub": "owns " + " · ".join(owns["po"])},
            {"id": "ar", "cls": "cool", "title": "Architect", "sub": "owns " + " · ".join(owns["ar"])},
            {"id": "gh", "cls": "gh", "title": "GitHub", "sub": "PR to main, then merge"}]


ACTION_LANES = [{"id": "you", "cls": "warm", "title": "You", "sub": "approve, review, merge"},
                {"id": "cl", "cls": "claude", "title": "Claude", "sub": "runs each command in its own session"},
                {"id": "gh", "cls": "gh", "title": "GitHub", "sub": "issue, branches, PRs"}]


def action_rows(plugin, t1, t2):
    def short(s):
        return plain(s).replace("ship/<n>-<slug>/", "…/")

    rows = []
    for (p, cid), (title, _) in t1.items():
        if p != plugin:
            continue
        branch, pr_to, writes, you = t2[(p, cid)]
        num = cid[:2] if cid[:2].isdigit() else None
        code = re.search(r"`([^`]+)`", branch)
        if pr_to == "—":
            gh = card("pr", l1="No PR", l2=clip(plain(writes), 38), m="No PR")
        else:
            gh = card("pr", l1=f"PR → {short(pr_to)}", l2=short(code[1]) if code else "", m=f"PR → {short(pr_to)}")
        main = card("step", pill=f"STEP {num}" if num else cid.upper(), title=title, cmd=cid, note=clip(plain(writes), 38),
                    m=f"{num + ' · ' if num else ''}{title}<br/>{cid}")
        rows.append({"main": ("cl", main), "side": [("you", card("chip", text=clip(you, 34), m=you)), ("gh", gh)]})
    return rows


def diagrams(d, t1, t2):
    s = start_rows(d, t1)
    return {"flow-start": (start_lanes(s), s),
            "flow-ship": (ACTION_LANES, action_rows("cuevik-ship", t1, t2)),
            "flow-docs": (ACTION_LANES, action_rows("cuevik-docs", t1, t2))}


def mermaid(lanes, rows):
    nodes, edges, prev = {l["id"]: [] for l in lanes}, [], None
    for i, row in enumerate(rows):
        lane, c = row["main"]
        nodes[lane].append((f"M{i}", c["m"]))
        if prev:
            edges.append(f"  {prev} --> M{i}")
        for j, (sl, sc) in enumerate(row["side"]):
            nodes[sl].append((f"S{i}_{j}", sc["m"]))
            edges.append(f"  M{i} -.- S{i}_{j}")
        prev = f"M{i}"
    out = ["```mermaid", "flowchart TB"]
    for l in lanes:
        out.append(f'  subgraph {l["id"].upper()}["{l["title"]}"]')
        out += [f'    {nid}["{label}"]' for nid, label in nodes[l["id"]]]
        out.append("  end")
    return "\n".join(out + edges + ["```"])


def step_facts(d):
    """One facts line per cuevik-start step, keyed by gen block name. A bootstrap step reads nothing."""
    out, steps = {}, d["steps"]
    for i, s in enumerate(steps):
        reads = [] if s.get("bootstrap") else s["reads"]
        nxt = steps[i + 1]["id"] if i + 1 < len(steps) else "cleanup"
        read_list = ", ".join(f"`{u}`" for u in reads) or "—"
        write_list = ", ".join(f"`{o}`" for o in s["outputs"])
        out[f"step-{s['id']}"] = (f"**Owner:** {s['owner']}  ·  **Reviewers:** {', '.join(s['reviewers'])}  ·  "
                                  f"**Reads:** {read_list}  ·  **Writes:** {write_list}  ·  **Then:** `/cuevik-start:{nxt}`")
    return out


def doc_owners(d):
    rows = ["| Document | Owner | Reviewers | Built from |", "|---|---|---|---|"]
    for x in d["docs"]:
        rows.append("| `{}` | {} | {} | {} |".format(
            x["path"], x["owner"], ", ".join(x["reviewers"]), ", ".join(f"`{u}`" for u in x["upstream"]) or "—"))
    return "\n".join(rows)


def render_blocks(d, t1, t2):
    blocks = {name: mermaid(*model) for name, model in diagrams(d, t1, t2).items()}
    blocks.update(step_facts(d))
    blocks["doc-owners"] = doc_owners(d)
    return blocks


def sync_blocks(walk, d, t1, t2, write):
    blocks = render_blocks(d, t1, t2)
    found = {m[1] for m in GEN.finditer(walk)}
    for name in sorted(set(blocks) ^ found):
        fail(f"{WALK.name}: " + (f"no <!-- gen:{name} --> block" if name in blocks else f"unknown generated block '{name}'"))
    stale = [m[1] for m in GEN.finditer(walk) if m[2].strip() != blocks[m[1]]]
    if not stale:
        return walk
    if not write:
        fail(f"generated blocks are stale ({', '.join(stale)}). Run: python docs/guides/build_docs.py --write")
    new = GEN.sub(lambda m: f"<!-- gen:{m[1]} -->\n\n{blocks[m[1]]}\n\n<!-- /gen:{m[1]} -->", walk)
    WALK.write_text(new, encoding="utf-8")
    print(f"refreshed {', '.join(stale)} in {WALK.name}")
    return new


# ---------------------------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------------------------
def checks(walk, over, d, t1, t2, release):
    head = "\n".join(walk.splitlines()[:8])
    for p in PLUGINS:
        m = re.search(rf"{p} (\d+\.\d+(?:\.\d+)?)", head)
        if not m:
            fail(f"{WALK.name}: header does not state a version for {p}")
        given, want = m[1], d["versions"][p]
        if given.split(".")[:2] != want.split(".")[:2]:
            fail(f"{p}: guide covers {given} but plugin.json is {want}")
        if release and given != want:
            fail(f"{p}: --release needs the exact version; guide says {given}, plugin.json is {want}")
        if given.count(".") == 2 and given != want:
            warn(f"{p}: guide says {given}, plugin.json is {want}")

    if bad := [s["id"] for s in d["steps"] if s["branch"] != f"init/{s['id']}"]:
        fail(f"steps.yml branch is no longer init/<id> for {bad}; update section 5 of the Walkthrough")
    documented = set(t1)
    steps = {("cuevik-start", s["id"]) for s in d["steps"]}
    if gap := steps - documented:
        fail(f"steps in steps.yml missing from '{T1}': {names(gap)}")
    numbered = {c for c in documented if c[0] == "cuevik-start" and re.match(r"\d\d-", c[1])}
    if extra := numbered - steps:
        fail(f"numbered cuevik-start commands that are not steps in steps.yml: {names(extra)}")
    if diff := (documented - steps) ^ set(t2):
        fail(f"'{T2}' must list exactly the commands outside the nine steps; difference: {names(diff)}")
    if undocumented := d["skills"] - documented:
        fail(f"skills exist on disk but are not documented: {names(undocumented)}")

    ids = {slug(re.sub(r"[`*]", "", m[1])) for m in re.finditer(r"^#{2,3} (.+)$", walk, re.M)}
    if broken := [l for l in re.findall(r"\]\(#([^)]+)\)", walk) if l not in ids]:
        fail(f"broken internal links: {broken}")
    for name, text in ((WALK.name, walk), (OVER.name, over)):
        if m := re.search(r"DECISIONS|BUILD-PLAN|DRYRUN", text):
            fail(f"{name} mentions {m[0]}, a temporary design doc that is deleted at the last phase")

    terms = ROOT / ".private-terms"
    if terms.exists():
        for t in (l.strip().lower() for l in terms.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")):
            for name, text in ((WALK.name, walk), (OVER.name, over)):
                if t in text.lower():
                    fail(f"{name} contains a private term from .private-terms: {t!r}")
    else:
        warn("privacy scan skipped: no .private-terms file (one term per line, gitignored)")

    if m := OVERVIEW_BANNED.search(over):
        fail(f"{OVER.name} exposes an internal term: {m[0]!r}")
    listed = set(re.findall(r"^\|\s*`/(cuevik-[a-z]+):([\w-]+)`", over, re.M))
    if listed != documented:
        fail(f"{OVER.name} must list the same commands as the Walkthrough; difference: {names(listed ^ documented)}")


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
.keep:has(>.pg){break-before:page;margin-top:0}
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
.chip .lbl{font-weight:700}
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
td code.wrap,.cmds td code{white-space:normal;overflow-wrap:anywhere}
tr.grp td{background:var(--primary-muted);color:var(--primary-text);font-weight:600}

.facts{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-md);padding:8px 12px;font-size:var(--text-sm);line-height:var(--leading-snug)}

/* by-actor diagrams */
figure.sw{margin:10px 0 14px;break-inside:avoid}
.sw svg{display:block;width:100%;height:auto}
.sw text{font-family:var(--font-sans);fill:var(--foreground)}
.sw .lane{stroke:none}
.sw .lane.warm{fill:var(--warning-muted)} .sw .lane.cool{fill:var(--info-muted)}
.sw .lane.claude{fill:var(--primary-muted)} .sw .lane.gh{fill:var(--muted)}
.sw .lane-h{font-size:13px;font-weight:600}
.sw .lane-s{font-size:10.5px;fill:var(--muted-foreground)}
.sw .card{fill:var(--card);stroke-width:1.4}
.sw .card.warm{stroke:var(--warning)} .sw .card.cool{stroke:var(--info)}
.sw .card.claude{stroke:var(--primary)} .sw .card.gh{stroke:var(--muted-foreground)}
.sw .dash{fill:var(--card);stroke:var(--muted-foreground);stroke-width:1.2;stroke-dasharray:4 3}
.sw .pill{fill:var(--foreground)}
.sw .pill-t{font-size:9px;font-weight:600;letter-spacing:0.06em;fill:var(--card)}
.sw .ttl{font-size:12.5px;font-weight:600}
.sw .mono{font-family:var(--font-mono);font-size:10px;fill:var(--primary-text)}
.sw .note{font-size:10.5px;fill:var(--muted-foreground)}
.sw .link{stroke:var(--muted-foreground);stroke-width:1.4;fill:none}
.sw .link.side{stroke-dasharray:4 3}
.sw .arrow{fill:var(--muted-foreground)}
.page{break-after:page} .page:last-child{break-after:auto}
.page h1{font-size:var(--text-lg);margin:0 0 4px}
.page>p{color:var(--muted-foreground);font-size:var(--text-sm)}

/* overview */
.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin:8px 0 6px}
.card-box{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-lg);box-shadow:var(--shadow-xs);padding:12px 14px}
.card-box .keep{margin-top:0}
.card-box h3{margin:0 0 4px}
.card-box p{margin:0;font-size:var(--text-sm)}
h2.pb{break-before:page;margin-top:0}

/* footer note */
.foot{margin-top:22px;padding-top:8px;border-top:1px solid var(--border);font-size:var(--text-xs);color:var(--muted-foreground)}

@page{size:A4;margin:12mm 0 14mm}
@media print{main{padding-top:0;padding-bottom:0}pre,pre code{white-space:pre-wrap;overflow-wrap:anywhere}}
@media screen{main{background:var(--background)}}
@media screen and (max-width:820px){main{padding:16px}.toc ul{columns:1}td:first-child,td code{white-space:normal}.tbl{overflow-x:auto}.cards{grid-template-columns:1fr}}
"""

LANDSCAPE = "@page{size:A4 landscape;margin:12mm 0 14mm} main{max-width:297mm;padding:8mm 12mm 0}"
# Overview: every command on one page, so rows stay one line and the command column is fixed
OVERVIEW_CSS = "table{table-layout:fixed} th:first-child,td:first-child{width:285px} th,td{padding:4px 10px} .tbl{margin:6px 0 10px}"


def font_faces():
    faces = []
    for fam, stem, weights in (("Archivo", "archivo", (400, 600, 700)), ("IBM Plex Mono", "ibm-plex-mono", (400, 600))):
        for w in weights:
            b64 = base64.b64encode((DOCS / "fonts" / f"{stem}-latin-{w}-normal.woff2").read_bytes()).decode()
            faces.append(f'@font-face{{font-family:"{fam}";font-style:normal;font-weight:{w};font-display:block;'
                         f'src:url(data:font/woff2;base64,{b64}) format("woff2")}}')
    return "\n".join(faces)


def page_html(title, body, extra_css="", generator=None):
    gen = f'<meta name="generator" content="{generator}">' if generator else ""
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">{gen}'
            f"<title>{H.escape(title)}</title><style>{font_faces()}\n{TOKENS}{CSS}{extra_css}</style></head>"
            f"<body><main>{body}</main></body></html>")


# ---------------------------------------------------------------------------------------------
# SVG swimlane: lanes are actors, each row is one command; dashed arrows go to the PR and approvers
# ---------------------------------------------------------------------------------------------
W, M, LW, LGAP, CW = 780, 12, 244, 10, 216
PAD = (LW - CW) // 2
TOP, ROWGAP = 78, 20
CARD_H = {"step": 66, "pr": 50, "chip": 28}


def swimlane(uid, label, lanes, rows):
    idx = {l["id"]: i for i, l in enumerate(lanes)}
    lx = lambda i: M + i * (LW + LGAP)
    esc = H.escape
    y, geo = TOP, []
    for row in rows:
        cells = [(idx[lane], c) for lane, c in (row["main"], *row["side"])]
        h = max(CARD_H[c["kind"]] for _, c in cells)
        geo.append((y, h, [(i, c, lx(i) + PAD, y + (h - CARD_H[c["kind"]]) // 2, CARD_H[c["kind"]]) for i, c in cells]))
        y += h + ROWGAP
    height = y - ROWGAP + 18
    out = [f'<svg viewBox="0 0 {W} {height}" role="img" aria-label="{esc(label)}" xmlns="http://www.w3.org/2000/svg">',
           f'<defs><marker id="ah{uid}" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto">'
           f'<path d="M0 0 L8 4 L0 8 z" class="arrow"/></marker></defs>']
    for i, l in enumerate(lanes):
        out += [f'<rect class="lane {l["cls"]}" x="{lx(i)}" y="12" width="{LW}" height="{height - 24}" rx="14"/>',
                f'<text class="lane-h" x="{lx(i) + 16}" y="34">{esc(l["title"])}</text>',
                f'<text class="lane-s" x="{lx(i) + 16}" y="50">{esc(clip(l["sub"], 40))}</text>']
    mark = f'marker-end="url(#ah{uid})"'
    for (_, _, a), (_, _, b) in zip(geo, geo[1:]):
        ia, _, xa, ya, ha = a[0]
        ib, _, xb, yb, _ = b[0]
        x1, y1, x2 = xa + CW // 2, ya + ha, xb + CW // 2
        path = f"M{x1} {y1} V{yb}" if ia == ib else f"M{x1} {y1} V{(y1 + yb) // 2} H{x2} V{yb}"
        out.append(f'<path class="link" d="{path}" {mark}/>')
    for y0, h, cells in geo:
        im, _, xm, _, _ = cells[0]
        for i, _, x, _, _ in cells[1:]:
            x1, x2 = (xm + CW, x) if i > im else (xm, x + CW)
            out.append(f'<path class="link side" d="M{x1} {y0 + h // 2} H{x2}" {mark}/>')
    for _, _, cells in geo:
        for i, c, x, y0, ch in cells:
            if c["kind"] == "step":
                pw = 14 + round(6.4 * len(c["pill"]))
                out += [f'<rect class="card {lanes[i]["cls"]}" x="{x}" y="{y0}" width="{CW}" height="{ch}" rx="10"/>',
                        f'<rect class="pill" x="{x + 12}" y="{y0 - 8}" width="{pw}" height="16" rx="8"/>',
                        f'<text class="pill-t" x="{x + 12 + pw / 2}" y="{y0 + 3}" text-anchor="middle">{esc(c["pill"])}</text>',
                        f'<text class="ttl" x="{x + 14}" y="{y0 + 30}">{esc(clip(c["title"], 26))}</text>',
                        f'<text class="mono" x="{x + 14}" y="{y0 + 45}">{esc(c["cmd"])}</text>',
                        f'<text class="note" x="{x + 14}" y="{y0 + 59}">{esc(clip(c["note"], 38))}</text>']
            elif c["kind"] == "pr":
                out += [f'<rect class="dash" x="{x}" y="{y0}" width="{CW}" height="{ch}" rx="10"/>',
                        f'<text class="ttl" x="{x + 14}" y="{y0 + 21}">{esc(c["l1"])}</text>',
                        f'<text class="note" x="{x + 14}" y="{y0 + 38}">{esc(clip(c["l2"], 38))}</text>']
            else:
                out += [f'<rect class="dash" x="{x}" y="{y0}" width="{CW}" height="{ch}" rx="14"/>',
                        f'<text class="note" x="{x + 14}" y="{y0 + 18}">{esc(c["text"])}</text>']
    return "\n".join(out + ["</svg>"])


# ---------------------------------------------------------------------------------------------
# HTML documents
# ---------------------------------------------------------------------------------------------
def shape(body_html, eyebrow, foot, overview=False):
    """Turn plain markdown HTML into the Cuevik document layout."""
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(body_html, "html.parser")
    h1 = soup.find("h1")
    meta_p = h1.find_next_sibling("p")
    lead_p = meta_p.find_next_sibling("p")
    hero = soup.new_tag("header", attrs={"class": "hero"})
    eyebrow_el = soup.new_tag("div", attrs={"class": "eyebrow"}); eyebrow_el.string = eyebrow
    meta = soup.new_tag("div", attrs={"class": "meta"})
    for part in re.split(r"\s+·\s+", meta_p.decode_contents()):
        m = re.match(r"\s*<strong>([^<:]*):?</strong>\s*(.*)", part, re.S)
        if not m:
            fail(f"header line must be '**Label:** value  ·  **Label:** value', got: {part!r}")
        chip = soup.new_tag("span", attrs={"class": "chip" if m[1] == "Plugins" else "chip neutral"})
        lbl = soup.new_tag("span", attrs={"class": "lbl"}); lbl.string = m[1]
        val = soup.new_tag("span"); val.append(BeautifulSoup(m[2], "html.parser"))
        chip.append(lbl); chip.append(val)
        meta.append(chip)
    lead_p["class"] = "lead"
    h1.insert_before(hero)
    for el in (eyebrow_el, h1.extract(), meta):
        hero.append(el)
    meta_p.decompose()
    hero.append(lead_p.extract())
    for h2 in soup.find_all("h2"):
        m = re.match(r"(\d+)\.\s+(.*)", h2.get_text())
        if m:
            h2.clear()
            num = soup.new_tag("span", attrs={"class": "num"}); num.string = m[1]
            h2.append(num); h2.append(m[2])
    if overview:
        h2s = soup.find_all("h2")
        get = next(h for h in h2s if h.get_text().startswith("What you get"))
        sibs = []
        for s in get.find_next_siblings():
            if s.name == "h2":
                break
            sibs.append(s)
        grid = soup.new_tag("div", attrs={"class": "cards"})
        get.insert_after(grid)
        box = None
        for s in sibs:
            if s.name == "h3":
                box = soup.new_tag("div", attrs={"class": "card-box"}); grid.append(box)
            box.append(s.extract())
        next(h for h in h2s if h.get_text().startswith("Every command"))["class"] = "pb"
    for t in soup.find_all("table"):
        short = len(t.find_all("tr")) <= 9
        wrap = soup.new_tag("div", attrs={"class": "tbl short" if short else "tbl"}); t.wrap(wrap)
        for td in t.find_all("td"):
            if len(td.get_text(strip=True)) <= 12:
                td["class"] = "nw"
        for code in t.find_all("code"):
            if len(code.get_text()) > 24:  # long paths may wrap, at a slash
                marked = code.decode_contents().replace("/", "/<wbr>")
                code.clear(); code.append(BeautifulSoup(marked, "html.parser")); code["class"] = "wrap"
    for p in soup.find_all("p"):
        if p.get_text().startswith("Owner:") and p.find("strong"):  # the generated facts line under a step heading
            p["class"] = "facts"
    for n, fig in enumerate(soup.find_all("figure", class_="sw")):  # a diagram is most of a page: start it on a fresh one
        h = fig.find_previous(["h2", "h3"])
        if n == 0 and h.name == "h3":
            h = h.find_previous("h2")  # the first diagram also carries its section heading
        h["class"] = h.get("class", []) + ["pg"]
    # keep every heading with the block that follows it (no orphaned headings at page foot)
    for h in soup.find_all(["h2", "h3"]):
        nxt = h.find_next_sibling()
        if nxt is None:
            continue
        if "tbl" in (nxt.get("class") or []) and len(nxt.find_all("tr")) > 9:
            continue  # long tables may split across pages (header row repeats); short ones stay with their heading
        keep = soup.new_tag("div", attrs={"class": f"keep k{h.name[1]}"})
        h.insert_before(keep); keep.append(h.extract()); keep.append(nxt.extract())
    if foot:
        el = soup.new_tag("div", attrs={"class": "foot"}); el.string = foot
        soup.append(el)
    return str(soup)


def convert(text):
    md = markdown.Markdown(extensions=["tables", "fenced_code", "toc", "sane_lists"],
                           extension_configs={"toc": {"slugify": slug, "toc_depth": "2-3"}})
    return md.convert(text), md


def walkthrough_html(text, svgs):
    # the .md keeps the Mermaid version for GitHub; the html swaps each flow block for its SVG
    text = GEN.sub(lambda m: f"\n\n@@FIG:{m[1]}@@\n\n" if m[1].startswith("flow-") else f"\n\n{m[2].strip()}\n\n", text)
    body, md = convert(text)
    for name, svg in svgs.items():
        body = body.replace(f"<p>@@FIG:{name}@@</p>", f'<figure class="sw">{svg}</figure>')
    ids = set(re.findall(r'id="([^"]+)"', body))
    if broken := [l for l in re.findall(r'href="#([^"]+)"', body) if l not in ids]:
        fail(f"broken internal links: {broken}")
    inner = re.sub(r'^<div class="toc">\s*|\s*</div>\s*$', "", md.toc.strip())
    body = body.replace("<hr />", f'<nav class="toc"><div class="ttl">Contents</div>{inner}</nav><hr />', 1)
    title = re.search(r"^# (.+)$", text, re.M)[1]
    eyebrow = "Cuevik Plugins · Walkthrough"
    body = shape(body, eyebrow, f"{eyebrow} · Generated from {WALK.name} by docs/guides/build_docs.py")
    return title, page_html(title, body, generator="docs/guides/build_docs.py")


def overview_html(text):
    body, _ = convert(text)
    title = re.search(r"^# (.+)$", text, re.M)[1]
    return title, page_html(title, shape(body, "Cuevik Plugins · Overview", None, overview=True), OVERVIEW_CSS)


def inline(s):
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", H.escape(s))


def byactor_html(svgs, d):
    pages = [("flow-start", "cuevik-start: the whole flow, by who does what",
              "Lanes are the document owners. Every command is /cuevik-start:<name>. Each step ends in a PR to main."),
             ("flow-ship", "cuevik-ship: from idea to code PR",
              "You approve and merge, Claude runs each command in its own session, GitHub holds the issue, branches and PRs. Every command is /cuevik-ship:<name>."),
             ("flow-docs", "cuevik-docs: audit and update",
              "Same lanes as cuevik-ship. Every command is /cuevik-docs:<name>.")]
    body = []
    for i, (name, title, sub) in enumerate(pages):
        extra = ""
        if name == "flow-docs":
            extra = ('<h2 style="font-size:var(--text-md);margin:18px 0 6px">Who owns which document</h2>'
                     f'<div class="tbl">{markdown.markdown(doc_owners(d), extensions=["tables"])}</div>')
        body.append(f'<section class="page"><h1>{H.escape(title)}</h1><p>{H.escape(sub)}</p>'
                    f'<figure class="sw">{svgs[name]}</figure>{extra}</section>')
    return page_html("Cuevik Plugins — Walkthrough by actor", "".join(body))


def commands_html(d, t1, t2):
    def row(cmd, what, approval, branch, writes):
        return (f"<tr><td><code>{H.escape(cmd)}</code></td><td>{inline(what)}</td><td>{inline(approval)}</td>"
                f"<td>{inline(branch)}</td><td>{inline(writes)}</td></tr>")

    steps = {s["id"]: s for s in d["steps"]}
    out = ['<header class="hero"><div class="eyebrow">Cuevik Plugins · Commands</div><h1>Every command</h1></header>']
    for p in PLUGINS:
        rows = []
        for (pl, cid), (title, what) in t1.items():
            if pl != p:
                continue
            if p == "cuevik-start" and cid in steps:
                s = steps[cid]
                rows.append(row(f"/{p}:{cid}", what, ", ".join(s["reviewers"]), f"`{s['branch']}` → `main`", ", ".join(f"`{o}`" for o in s["outputs"])))
            else:
                branch, pr_to, writes, you = t2[(pl, cid)]
                rows.append(row(f"/{p}:{cid}", what, you, f"{branch} → {pr_to}" if branch != "—" else "—", writes))
        cols = "".join(f'<col style="width:{w}%">' for w in (27, 27, 10, 19, 17))
        out.append(f'<h3>{PLUGIN_TITLE[p]}</h3><div class="tbl"><table class="cmds"><colgroup>{cols}</colgroup><thead><tr><th>Command</th>'
                   f'<th>What it does</th><th>Approved by</th><th>Branch → PR to</th><th>Writes</th></tr></thead>'
                   f'<tbody>{"".join(rows)}</tbody></table></div>')
    return page_html("Cuevik Plugins — Commands", "".join(out), LANDSCAPE)


def pdf(browser, html, out, footer):
    pg = browser.new_page()
    pg.set_content(html)
    pg.wait_for_load_state("load")
    pg.evaluate("document.fonts.ready")
    pg.emulate_media(media="print")
    # a table or diagram wider than its box is clipped silently in the PDF, so stop the build instead
    if clipped := pg.evaluate("[...document.querySelectorAll('.tbl,figure.sw,.card-box')]"
                              ".filter(e => e.scrollWidth > e.clientWidth + 1).map(e => e.innerText.slice(0, 40))"):
        fail(f"{out.name}: content is wider than its box and would be clipped: {clipped}")
    pg.pdf(path=str(out), format="A4", print_background=True, prefer_css_page_size=True,
           display_header_footer=True, header_template="<span></span>",
           footer_template=('<div style="font:8px Arial,sans-serif;color:#676767;width:100%;padding:0 14mm;display:flex;justify-content:space-between">'
                            f'<span>{H.escape(footer)}</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>'))
    pg.close()
    print(f"wrote {out.name}")


def build(walk, over, d, t1, t2):
    from playwright.sync_api import sync_playwright
    svgs = {name: swimlane(i, f"{name} by actor", lanes, rows) for i, (name, (lanes, rows)) in enumerate(diagrams(d, t1, t2).items())}
    w_title, w_html = walkthrough_html(walk, svgs)
    o_title, o_html = overview_html(over)
    WALK.with_suffix(".html").write_text(w_html, encoding="utf-8")
    OVER.with_suffix(".html").write_text(o_html, encoding="utf-8")
    print(f"wrote {WALK.with_suffix('.html').name}\nwrote {OVER.with_suffix('.html').name}")
    with sync_playwright() as p:
        b = p.chromium.launch(channel="chrome")
        pdf(b, w_html, WALK.with_suffix(".pdf"), w_title)
        pdf(b, byactor_html(svgs, d), BYACTOR, "Cuevik Plugins · Walkthrough by actor")
        pdf(b, commands_html(d, t1, t2), COMMANDS, "Cuevik Plugins · Commands")
        pdf(b, o_html, OVER.with_suffix(".pdf"), "Cuevik Plugins · Overview")
        b.close()


def main():
    ap = argparse.ArgumentParser(description="Build the Cuevik Plugins guides.")
    ap.add_argument("--write", action="store_true", help="refresh the generated blocks in the Walkthrough .md")
    ap.add_argument("--check", action="store_true", help="run the checks only; write nothing")
    ap.add_argument("--release", action="store_true", help="require exact plugin versions")
    args = ap.parse_args()
    d = load()
    walk, over = WALK.read_text(encoding="utf-8"), OVER.read_text(encoding="utf-8")
    t1, t2 = command_table(walk, T1, 3), command_table(walk, T2, 5)
    checks(walk, over, d, t1, t2, args.release)
    walk = sync_blocks(walk, d, t1, t2, args.write)
    if args.check:
        print("checks passed")
        return
    build(walk, over, d, t1, t2)
    print("guides in sync with the plugins")


if __name__ == "__main__":
    main()
