#!/usr/bin/env python3
"""Check that the merge-order workflow lists the same steps as the step registry.

Usage:  python scripts/check-init-order.py
Needs:  PyYAML
Why:    plugins/cuevik-start/references/workflows/cuevik-init-order.yml is copied into every project
        repo, where steps.yml does not exist, so it carries its own table of the steps. A step added,
        moved or given an alias in steps.yml and not in that table would gate the wrong PRs.

Checks
  1. The workflow's STEPS table has one line per steps.yml step, in the same order, each line the
     step's slug followed by its aliases in the same order.
  2. The workflow's EXPRESS list is the slugs of express.yml `covers`, in the same order.
  3. No slug or alias is used twice, and no slug's branch is the Express lane's or migrate's.
Any failure exits non-zero.
"""
import re, sys
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parent.parent
REFS = ROOT / "plugins" / "cuevik-start" / "references"
WORKFLOW = REFS / "workflows" / "cuevik-init-order.yml"
failures = []


def load(path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def workflow_tables():
    """The STEPS table (a list of name lists) and the EXPRESS list from the workflow's script."""
    script = "\n".join(s.get("run", "") for job in load(WORKFLOW)["jobs"].values() for s in job["steps"])
    steps = re.search(r'^STEPS="\n(.*?)\n"$', script, re.S | re.M)
    express = re.search(r'^EXPRESS="(.*?)"$', script, re.M)
    if not steps or not express:
        sys.exit(f"{WORKFLOW.relative_to(ROOT).as_posix()}: no STEPS=\"...\" table or EXPRESS=\"...\" list found")
    return [line.split() for line in steps[1].splitlines() if line.strip()], express[1].split()


def main():
    registry = load(REFS / "steps.yml")["steps"]
    lane = load(REFS / "express.yml")["express"]
    table, express = workflow_tables()
    wf = WORKFLOW.relative_to(ROOT).as_posix()

    want = [[s["slug"], *s.get("aliases", [])] for s in registry]
    if table != want:
        failures.append(f"{wf}: STEPS differs from steps.yml (slug, then aliases, in step order)")
        for i in range(max(len(table), len(want))):
            got, exp = (t[i] if i < len(t) else None for t in (table, want))
            if got != exp:
                failures.append(f"    line {i + 1}: workflow {' '.join(got) if got else '(none)'}"
                                f"  |  steps.yml {' '.join(exp) if exp else '(none)'}")

    slug_of = {s["id"]: s["slug"] for s in registry}
    if unknown := [c for c in lane["covers"] if c not in slug_of]:
        failures.append(f"express.yml covers unknown step ids {unknown}")
    elif express != (covered := [slug_of[c] for c in lane["covers"]]):
        failures.append(f"{wf}: EXPRESS is {express}, but express.yml covers {covered}")

    names = [n for line in want for n in line]
    if twice := sorted({n for n in names if names.count(n) > 1}):
        failures.append(f"steps.yml uses a slug or alias more than once: {twice}")
    reserved = {lane["branch"], "init/migrate"}
    if taken := [s["slug"] for s in registry if f"init/{s['slug']}" in reserved]:
        failures.append(f"steps.yml slug {taken} would share a branch with the Express lane or migrate")

    if failures:
        print("INIT-ORDER CHECKS FAILED:")
        for f in failures:
            print("  -" if not f.startswith("    ") else "   ", f.strip())
        sys.exit(1)
    print(f"init-order checks passed ({len(want)} steps, {len(names) - len(want)} aliases, {len(express)} Express steps)")


if __name__ == "__main__":
    main()
