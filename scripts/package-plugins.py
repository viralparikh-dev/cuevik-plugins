#!/usr/bin/env python3
"""Zip each plugin into dist/<name>.zip for Claude Desktop "Upload plugin" (it accepts .zip only).

Usage:  python scripts/package-plugins.py            package every plugin
        python scripts/package-plugins.py <name>...  package only the named plugins
Output: dist/<plugin.json name>.zip (zip with .claude-plugin/plugin.json at the archive root)
"""
import json, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGINS = ROOT / "plugins"
DIST = ROOT / "dist"

wanted = set(sys.argv[1:])
DIST.mkdir(exist_ok=True)
failed = False

for plugin in sorted(p for p in PLUGINS.iterdir() if p.is_dir()):
    if wanted and plugin.name not in wanted:
        continue
    manifest = plugin / ".claude-plugin" / "plugin.json"
    if not manifest.is_file():
        print(f"skip  {plugin.name}: no .claude-plugin/plugin.json")
        failed = True
        continue
    name = json.loads(manifest.read_text(encoding="utf-8"))["name"]
    out = DIST / f"{name}.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(plugin.rglob("*")):
            if f.is_file() and f.name != ".DS_Store":
                z.write(f, f.relative_to(plugin).as_posix())  # posix separators: zip spec
    print(f"wrote {out.relative_to(ROOT)}")

sys.exit(1 if failed else 0)
