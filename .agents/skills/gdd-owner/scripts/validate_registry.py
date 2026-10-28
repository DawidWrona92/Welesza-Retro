#!/usr/bin/env python3
"""Validate design/registry.yaml against the registry schema.

Usage: python3 validate_registry.py <design-dir> [--json]

Checks:
  1. IDs are unique
  2. IDs use a known prefix
  3. status is one of proposed|approved|canon|deprecated
  4. every ref exists in the registry
  5. no canon entry refs a proposed or deprecated entry
  6. canon entries have a `file` field

Exit code 0 on success, 1 when any error is found, 2 on usage or parse problems.
No third-party dependencies: a small YAML subset parser is included.
"""
import json
import re
import sys
from pathlib import Path

PREFIXES = {
    "P", "MECH", "ZON", "CHR", "ENM", "ITM", "WPN", "CUR", "QST",
    "PUZ", "FAC", "SHOP", "SKL",
}
STATUSES = {"proposed", "approved", "canon", "deprecated"}
ID_RE = re.compile(r"^([A-Z]+?)(?:-([a-z0-9][a-z0-9-]*))?$")


def _scalar(value):
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [_scalar(v) for v in inner.split(",")]
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    if value in ("null", "~", ""):
        return None
    return value


def parse_registry(text):
    """Parse the limited YAML shape used by registry.yaml."""
    entries = []
    current = None
    in_entries = False
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].rstrip() if not re.search(r"['\"].*#.*['\"]", raw) else raw.rstrip()
        if not line.strip():
            continue
        if line.strip() == "entries:":
            in_entries = True
            continue
        if not in_entries:
            continue
        stripped = line.strip()
        if stripped.startswith("- "):
            current = {}
            entries.append(current)
            stripped = stripped[2:]
        if current is None:
            raise ValueError(f"unexpected line outside an entry: {raw!r}")
        if ":" not in stripped:
            raise ValueError(f"cannot parse line: {raw!r}")
        key, _, value = stripped.partition(":")
        current[key.strip()] = _scalar(value)
    return entries


def prefix_of(entry_id):
    if re.fullmatch(r"P\d+", entry_id):
        return "P"
    return entry_id.split("-", 1)[0]


def validate(entries):
    errors = []
    by_id = {}
    for i, e in enumerate(entries):
        eid = e.get("id")
        if not eid:
            errors.append(f"entry #{i + 1}: missing id")
            continue
        if eid in by_id:
            errors.append(f"{eid}: duplicate id")
        else:
            by_id[eid] = e  # first occurrence is the one refs resolve to
    for e in entries:
        eid = e.get("id")
        if not eid:
            continue
        pre = prefix_of(eid)
        if pre not in PREFIXES:
            errors.append(f"{eid}: unknown prefix '{pre}'")
        if pre != "P" and not re.fullmatch(r"[A-Z]+-[a-z0-9][a-z0-9-]*", eid):
            errors.append(f"{eid}: id must be PREFIX- followed by lowercase letters, digits or hyphens")
        status = e.get("status")
        if status not in STATUSES:
            errors.append(f"{eid}: invalid status {status!r}")
        refs = e.get("refs") or []
        if not isinstance(refs, list):
            errors.append(f"{eid}: refs must be a list")
            refs = []
        for r in refs:
            if r not in by_id:
                errors.append(f"{eid}: ref {r} does not exist")
                continue
            if status == "canon" and by_id[r].get("status") in ("proposed", "deprecated"):
                errors.append(
                    f"{eid}: canon entry refs {r} which is {by_id[r].get('status')}"
                )
        if status == "canon" and not e.get("file"):
            errors.append(f"{eid}: canon entry has no file")
    return errors


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    as_json = "--json" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    path = Path(args[0])
    if path.is_dir():
        path = path / "registry.yaml"
    if not path.exists():
        print(f"error: {path} not found", file=sys.stderr)
        return 2
    try:
        entries = parse_registry(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    errors = validate(entries)
    if as_json:
        print(json.dumps({"entries": len(entries), "errors": errors}, indent=2))
    else:
        if errors:
            for err in errors:
                print(f"ERROR {err}")
            print(f"\n{len(errors)} error(s) in {len(entries)} entries")
        else:
            print(f"OK: {len(entries)} entries, no errors")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
