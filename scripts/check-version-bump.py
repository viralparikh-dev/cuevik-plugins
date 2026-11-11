#!/usr/bin/env python3
"""Check that a change to a plugin's installable files bumps that plugin's version.

Usage:  python scripts/check-version-bump.py               compare HEAD with origin/main
        python scripts/check-version-bump.py --base <ref>  compare HEAD with <ref>
Needs:  git, with <ref> fetched and enough history to find where HEAD left it
Why:    Claude Code detects a plugin update by its version. A change merged without a bump never
        reaches the users who already installed the plugin.

Checks
  For each plugins/<plugin>/ with a committed change since HEAD left <ref>, other than its own
  README.md (documentation only: README.md, Versioning), .claude-plugin/plugin.json has a
  `version` that differs from the one at that point and is not lower.
  A plugin that is new or removed in the change is skipped.
Any failure exits non-zero.
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")


def version(ref, plugin):
    """The plugin's version at ref, or None when it has no plugin.json or no version there."""
    shown = git("show", f"{ref}:plugins/{plugin}/.claude-plugin/plugin.json")
    return json.loads(shown.stdout).get("version") if shown.returncode == 0 else None


def core(v):
    m = re.match(r"(\d+)\.(\d+)\.(\d+)", v)
    return tuple(int(n) for n in m.groups()) if m else None


def main():
    parser = argparse.ArgumentParser(description="Check that changed plugins bump their version.")
    parser.add_argument("--base", default="origin/main", help="ref to compare HEAD with (default: origin/main)")
    base = parser.parse_args().base

    fork = git("merge-base", base, "HEAD")
    if fork.returncode:
        sys.exit(f"cannot find where HEAD left {base}: fetch it with full history (git fetch origin)")
    fork = fork.stdout.strip()
    # --no-renames: a file moved out of a plugin still counts as a change to that plugin.
    diff = git("diff", "--name-only", "--no-renames", fork, "HEAD")
    if diff.returncode:
        sys.exit(f"git diff failed: {diff.stderr.strip()}")

    changed = {}  # plugin -> first changed file that needs a bump
    for path in diff.stdout.splitlines():
        parts = path.split("/")
        if len(parts) >= 3 and parts[0] == "plugins" and path != f"plugins/{parts[1]}/README.md":
            changed.setdefault(parts[1], path)

    failures = []
    for plugin, path in sorted(changed.items()):
        old, new = version(fork, plugin), version("HEAD", plugin)
        if old is None or new is None:
            continue
        manifest = f"plugins/{plugin}/.claude-plugin/plugin.json"
        if core(new) is None:
            failures.append(f"{manifest}: version {new!r} is not MAJOR.MINOR.PATCH")
        elif new == old:
            failures.append(f"{manifest}: version is still {old}, but {path} changed. Bump it.")
        elif core(old) is not None and core(new) < core(old):
            failures.append(f"{manifest}: version went down, {old} -> {new}")

    if failures:
        print("VERSION CHECKS FAILED:")
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print(f"version checks passed ({len(changed)} changed plugins"
          + (": " + ", ".join(sorted(changed)) if changed else "") + f"; base {base})")


if __name__ == "__main__":
    main()
