#!/usr/bin/env python3
"""Check every plugins/*/skills/*/SKILL.md: frontmatter parses as YAML, has name + description,
and name equals the folder name.

Usage:  python scripts/check-frontmatter.py
Needs:  PyYAML
Why:    an unquoted ': ' in a description makes the YAML invalid and the skill loads with empty
        metadata. `claude plugin validate` only catches it on some line endings.
"""
import re, sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parent.parent
bad = 0
files = sorted(ROOT.glob("plugins/*/skills/*/SKILL.md"))
for f in files:
    rel = f.relative_to(ROOT).as_posix()
    m = re.match(r"---\r?\n(.*?)\r?\n---", f.read_text(encoding="utf-8"), re.S)
    try:
        meta = yaml.safe_load(m.group(1)) if m else None
    except yaml.YAMLError as e:
        print(f"FAIL {rel}: {str(e).splitlines()[0]}")
        bad += 1
        continue
    if not isinstance(meta, dict) or not meta.get("name") or not meta.get("description"):
        print(f"FAIL {rel}: frontmatter needs name and description")
        bad += 1
    elif meta["name"] != f.parent.name:
        print(f"FAIL {rel}: name {meta['name']!r} != folder {f.parent.name!r}")
        bad += 1
if not files:
    print("FAIL no SKILL.md found")
    bad += 1
print(f"{len(files)} skills checked, {bad} failing" if bad else f"frontmatter checks passed ({len(files)} skills)")
sys.exit(1 if bad else 0)
