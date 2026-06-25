#!/usr/bin/env python3
"""Read simple key: value fields from qa/scenarios/*.yaml manifests."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def parse_manifest(path: Path) -> dict[str, str]:
    fields: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("screenshots:"):
            continue
        match = re.match(r"^([a-zA-Z0-9_]+):\s*(.+)$", line)
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        fields[key] = value
    return fields


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("key")
    args = parser.parse_args()
    fields = parse_manifest(args.manifest)
    if args.key not in fields:
        print(f"manifest key not found: {args.key}", file=sys.stderr)
        return 1
    print(fields[args.key])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
