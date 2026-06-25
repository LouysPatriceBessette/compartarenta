#!/usr/bin/env python3
"""Verify Maestro flow qa-* ids match Semantics identifiers in Dart."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

MAESTRO_ID_RE = re.compile(r"""id:\s*["'](qa-[^"']+)["']""")
DART_QA_ID_RE = re.compile(r"""['"](qa-[a-z0-9-]+)['"]""")


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parent.parent


def is_excluded_dart(path: Path, root: Path) -> bool:
    try:
        rel = path.relative_to(root).as_posix()
    except ValueError:
        return False
    return any(rel.startswith(prefix) for prefix in ("mobile/lib/screens/car_sharing/",))


def collect_maestro_ids(flows_dir: Path) -> dict[str, list[str]]:
    ids: dict[str, list[str]] = {}
    if not flows_dir.is_dir():
        return ids
    for path in sorted(flows_dir.rglob("*.yaml")):
        rel = path.as_posix()
        for qa_id in MAESTRO_ID_RE.findall(path.read_text(encoding="utf-8")):
            ids.setdefault(qa_id, []).append(rel)
    return ids


def collect_dart_ids(mobile_lib: Path, root: Path) -> dict[str, list[str]]:
    ids: dict[str, list[str]] = {}
    if not mobile_lib.is_dir():
        return ids
    for path in sorted(mobile_lib.rglob("*.dart")):
        if is_excluded_dart(path, root):
            continue
        rel = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8")
        for qa_id in DART_QA_ID_RE.findall(text):
            if not qa_id.startswith("qa-"):
                continue
            ids.setdefault(qa_id, []).append(rel)
    return ids


def verify_semantics(root: Path, *, warn_orphans: bool = True) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    maestro = collect_maestro_ids(root / "qa" / "flows")
    dart = collect_dart_ids(root / "mobile" / "lib", root)

    for qa_id, flow_paths in sorted(maestro.items()):
        if qa_id not in dart:
            flows = ", ".join(sorted(set(flow_paths)))
            errors.append(
                f"Maestro id '{qa_id}' used in {flows} but not found in mobile/lib Dart "
                "(excluding car_sharing/)",
            )

    if warn_orphans:
        for qa_id, dart_paths in sorted(dart.items()):
            if qa_id not in maestro:
                files = ", ".join(sorted(set(dart_paths)))
                warnings.append(
                    f"Dart identifier '{qa_id}' in {files} is not referenced by any "
                    "qa/flows/*.yaml (informational)",
                )

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root (default: parent of tool/)",
    )
    parser.add_argument(
        "--no-warn-orphans",
        action="store_true",
        help="Do not warn about Dart qa-* ids unused in Maestro flows",
    )
    args = parser.parse_args()
    root = args.repo_root or repo_root_from_here()

    errors, warnings = verify_semantics(
        root,
        warn_orphans=not args.no_warn_orphans,
    )

    maestro_count = len(collect_maestro_ids(root / "qa" / "flows"))
    dart_count = len(collect_dart_ids(root / "mobile" / "lib", root))

    for warning in warnings:
        print(f"WARN: {warning}", file=sys.stderr)

    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    print(
        f"OK: {maestro_count} Maestro qa-* id(s), {dart_count} Dart qa-* identifier(s) aligned",
    )
    if warnings:
        print(f"     ({len(warnings)} unused Dart identifier warning(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
