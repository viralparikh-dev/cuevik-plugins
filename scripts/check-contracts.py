#!/usr/bin/env python3
"""Check the shared contracts and every plugin's copy of them.

Usage:  python scripts/check-contracts.py                  check this repo
        python scripts/check-contracts.py --sync           first copy each contract over its plugin copies
        python scripts/check-contracts.py --target <repo>  also check <repo>/.cuevik/*.json
Needs:  python -m pip install -r scripts/requirements.txt

Checks
  1. Every contracts/<name>/ folder is declared in contracts/consumers.json, and every declared
     contract and plugin exists.
  2. Every .json file under contracts/ parses; each <name>.schema.json is valid JSON Schema 2020-12
     and <name>.example.json validates against it. A contract with no <name>.schema.json describes
     no file (contracts/board/): it is only compared with its copies.
  3. The lineage example is a valid graph: unique paths, upstream paths known, no self-links, no cycles.
  4. Each declared copy at plugins/<plugin>/references/contracts/<name>/ exists and matches
     contracts/<name>/ file for file (line endings ignored, since core.autocrlf rewrites them).
  5. No plugin holds an undeclared copy.
  6. With --target: for each contract with a schema, <repo>/.cuevik/<name>.json exists and passes
     checks 2 and 3.
  7. No plugin prose (skills, references, READMEs; not the contract copies) states a schemaVersion
     number. The number lives in each contract's schema; prose says "the current schemaVersion" and
     a reader looks it up, so a bump cannot leave a stale number behind.
Any failure exits non-zero.

--sync writes before it checks: for each contract in contracts/consumers.json it makes every declared
plugin copy match contracts/<name>/ (files added, replaced or removed), then runs the checks above.
It touches nothing else: an undeclared copy is still reported, not deleted.
"""
import argparse, json, re, shutil, sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
    from jsonschema.exceptions import SchemaError
except ImportError:
    sys.exit("jsonschema is not installed: python -m pip install -r scripts/requirements.txt")

ROOT = Path(__file__).resolve().parent.parent
CONTRACTS = ROOT / "contracts"
PLUGINS = ROOT / "plugins"
failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


def load(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        failures.append(f"{path.as_posix()}: {e}")
        return None


def files(folder):
    return {p.relative_to(folder).as_posix(): p for p in folder.rglob("*") if p.is_file()}


def text(path):
    return path.read_bytes().replace(b"\r\n", b"\n")


def validate(name, instance, label):
    """Validate instance against contracts/<name>/<name>.schema.json; report every error."""
    schema = load(CONTRACTS / name / f"{name}.schema.json")
    if schema is None or instance is None:
        return
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as e:
        failures.append(f"contracts/{name}/{name}.schema.json is not valid JSON Schema: {e.message}")
        return
    for e in sorted(Draft202012Validator(schema).iter_errors(instance), key=lambda e: list(e.absolute_path)):
        where = "/".join(str(p) for p in e.absolute_path) or "(root)"
        failures.append(f"{label}: {where}: {e.message}")
    if name == "lineage" and isinstance(instance, dict):
        check_lineage(instance, label)


def check_lineage(lineage, label):
    docs = [d for d in lineage.get("documents", []) if isinstance(d, dict)]
    paths = [d.get("path") for d in docs]
    check(len(paths) == len(set(paths)), f"{label}: duplicate paths {sorted(p for p in set(paths) if paths.count(p) > 1)}")
    up = {d.get("path"): d.get("upstream", []) for d in docs}
    for path, ups in up.items():
        for u in ups:
            check(u in up, f"{label}: {path} upstream {u} is not a listed document")
            check(u != path, f"{label}: {path} lists itself as upstream")
    state = {}  # path -> 1 visiting, 2 done

    def visit(p, trail):  # depth-first; returns True once a cycle is reported
        if state.get(p) == 2 or p not in up:
            return False
        if state.get(p) == 1:
            failures.append(f"{label}: cycle " + " -> ".join(trail[trail.index(p):] + [p]))
            return True
        state[p] = 1
        if any(visit(u, trail + [p]) for u in up[p]):
            return True
        state[p] = 2
        return False

    any(visit(p, []) for p in up)


def sync(declared, contracts):
    """Make every declared plugin copy match its contract folder; print what changed."""
    changed = 0
    for name, plugins in sorted(declared.items()):
        if name not in contracts:
            continue
        source = files(CONTRACTS / name)
        for plugin in plugins:
            if not (PLUGINS / plugin).is_dir():
                continue  # the checks report the unknown plugin
            copy_dir = PLUGINS / plugin / "references" / "contracts" / name
            copy = files(copy_dir) if copy_dir.is_dir() else {}
            for f, src in sorted(source.items()):
                if f not in copy or text(src) != text(copy[f]):
                    (copy_dir / f).parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(src, copy_dir / f)
                    print(f"synced   {(copy_dir / f).relative_to(ROOT).as_posix()}")
                    changed += 1
            for f in sorted(copy.keys() - source.keys()):
                copy[f].unlink()
                print(f"removed  {copy[f].relative_to(ROOT).as_posix()}")
                changed += 1
    print(f"sync: {changed} files changed" if changed else "sync: every copy already matches")


# A schemaVersion written as a number, or "<config|lineage|contract> ... version <n>", in prose.
VERSION_IN_PROSE = re.compile(r"schemaVersion\W{0,15}\d|(?i:\b(?:config|lineage|contract)\b[^.\n]{0,25}\bversions? \d)")


def check_prose_versions():
    for path in sorted(PLUGINS.rglob("*")):
        rel = path.relative_to(ROOT).as_posix()
        if path.suffix not in (".md", ".yml") or not path.is_file() or "/references/contracts/" in rel:
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if VERSION_IN_PROSE.search(line):
                failures.append(f"{rel}:{number}: states a schemaVersion number; say \"the current schemaVersion\" "
                                f"and let the reader take it from the contract's schema: {line.strip()[:90]}")


def main():
    parser = argparse.ArgumentParser(description="Check the shared contracts and every plugin's copy of them.")
    parser.add_argument("--target", type=Path, help="project repo whose .cuevik/*.json to validate too")
    parser.add_argument("--sync", action="store_true", help="first copy each contract over its declared plugin copies")
    args = parser.parse_args()
    consumers = load(CONTRACTS / "consumers.json") or {}
    declared = {k: v for k, v in consumers.items() if not k.startswith("$")}
    contracts = {p.name for p in CONTRACTS.iterdir() if p.is_dir()}
    if args.sync:
        sync(declared, contracts)
    for name in sorted(contracts - declared.keys()):
        failures.append(f"contracts/{name}/ is not declared in contracts/consumers.json")
    for name in sorted(declared.keys() - contracts):
        failures.append(f"consumers.json declares {name}, but contracts/{name}/ does not exist")

    for path in sorted(CONTRACTS.rglob("*.json")):
        load(path)
    with_schema = {n for n in contracts if (CONTRACTS / n / f"{n}.schema.json").is_file()}
    for name in sorted(with_schema):
        example = CONTRACTS / name / f"{name}.example.json"
        validate(name, load(example), f"contracts/{name}/{example.name}")

    target = args.target
    if target:
        for name in sorted(with_schema):
            path = target / ".cuevik" / f"{name}.json"
            if path.is_file():
                validate(name, load(path), path.as_posix())
            else:
                failures.append(f"{path.as_posix()} is missing")

    for name, plugins in sorted(declared.items()):
        if name not in contracts:
            continue
        source = files(CONTRACTS / name)
        for plugin in plugins:
            if not (PLUGINS / plugin).is_dir():
                failures.append(f"consumers.json: {name} -> unknown plugin {plugin}")
                continue
            copy_dir = PLUGINS / plugin / "references" / "contracts" / name
            rel = copy_dir.relative_to(ROOT).as_posix()
            if not copy_dir.is_dir():
                failures.append(f"{rel}/ is missing")
                continue
            copy = files(copy_dir)
            for f in sorted(source.keys() - copy.keys()):
                failures.append(f"{rel}/{f} is missing")
            for f in sorted(copy.keys() - source.keys()):
                failures.append(f"{rel}/{f} is not in contracts/{name}/")
            for f in sorted(source.keys() & copy.keys()):
                check(text(source[f]) == text(copy[f]), f"{rel}/{f} differs from contracts/{name}/{f}")

    check_prose_versions()

    for copy_dir in sorted(PLUGINS.glob("*/references/contracts/*")):
        plugin, name = copy_dir.parts[-4], copy_dir.name
        check(plugin in declared.get(name, []),
              f"{copy_dir.relative_to(ROOT).as_posix()}/ is not declared in contracts/consumers.json")

    if failures:
        print("CONTRACT CHECKS FAILED:")
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print(f"contract checks passed ({len(contracts)} contracts, "
          f"{sum(len(v) for v in declared.values())} plugin copies"
          + (f", target {target.as_posix()}" if target else "") + ")")


if __name__ == "__main__":
    main()
