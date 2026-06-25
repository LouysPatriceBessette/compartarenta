#!/usr/bin/env python3
"""Read and validate qa/scenarios/*.yaml manifests."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_KEYS = ("id", "device_date", "timezone", "seed", "flow")
MANIFEST_KEY_RE = re.compile(r"^([a-zA-Z0-9_]+):\s*(.+)$")


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parent.parent


def scenarios_dir(root: Path) -> Path:
    return root / "qa" / "scenarios"


def parse_manifest(path: Path) -> dict[str, str]:
    fields: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("screenshots:"):
            continue
        match = MANIFEST_KEY_RE.match(line)
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        fields[key] = value
    return fields


def list_scenario_ids(root: Path) -> list[str]:
    directory = scenarios_dir(root)
    if not directory.is_dir():
        return []
    ids: list[str] = []
    for path in sorted(directory.glob("*.yaml")):
        fields = parse_manifest(path)
        scenario_id = fields.get("id") or path.stem
        ids.append(scenario_id)
    return ids


def load_seed_ids(seed_dart: Path) -> set[str]:
    if not seed_dart.is_file():
        return set()
    text = seed_dart.read_text(encoding="utf-8")
    match = re.search(
        r"const kQaScenarioIds = <String>\{([^}]*)\}",
        text,
        re.DOTALL,
    )
    if not match:
        return set()
    body = match.group(1)
    return {m.group(1) for m in re.finditer(r"'([^']+)'", body)}


def validate_scenarios(root: Path) -> list[str]:
    errors: list[str] = []
    directory = scenarios_dir(root)
    if not directory.is_dir():
        return [f"missing scenarios directory: {directory}"]

    seed_ids = load_seed_ids(root / "mobile" / "lib" / "debug" / "qa_scenario_seed.dart")
    manifests = sorted(directory.glob("*.yaml"))
    if not manifests:
        errors.append(f"no scenario manifests in {directory}")
        return errors

    seen_ids: set[str] = set()
    for path in manifests:
        rel = path.relative_to(root)
        fields = parse_manifest(path)
        scenario_id = fields.get("id") or path.stem

        for key in REQUIRED_KEYS:
            if key not in fields or not fields[key].strip():
                errors.append(f"{rel}: missing required key '{key}'")

        if scenario_id in seen_ids:
            errors.append(f"{rel}: duplicate scenario id '{scenario_id}'")
        seen_ids.add(scenario_id)

        if path.stem != scenario_id:
            errors.append(
                f"{rel}: filename stem '{path.stem}' should match id '{scenario_id}'",
            )

        seed = fields.get("seed", "")
        if seed and seed_ids and seed not in seed_ids:
            errors.append(
                f"{rel}: seed '{seed}' is not in kQaScenarioIds "
                "(mobile/lib/debug/qa_scenario_seed.dart)",
            )

        flow_rel = fields.get("flow", "")
        if flow_rel:
            flow_path = root / flow_rel
            if not flow_path.is_file():
                errors.append(f"{rel}: flow file missing: {flow_rel}")

    return errors


def cmd_list(root: Path) -> int:
    for scenario_id in list_scenario_ids(root):
        print(scenario_id)
    return 0


def cmd_validate(root: Path) -> int:
    errors = validate_scenarios(root)
    if not errors:
        count = len(list_scenario_ids(root))
        print(f"OK: {count} scenario manifest(s) validated")
        return 0
    for err in errors:
        print(f"ERROR: {err}", file=sys.stderr)
    return 1


def cmd_get(manifest: Path, key: str) -> int:
    fields = parse_manifest(manifest)
    if key not in fields:
        print(f"manifest key not found: {key}", file=sys.stderr)
        return 1
    print(fields[key])
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "manifest",
        nargs="?",
        type=Path,
        help="Path to a scenario manifest (legacy: second arg is field key)",
    )
    parser.add_argument(
        "key",
        nargs="?",
        help="Manifest field to print (legacy mode)",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print scenario ids from qa/scenarios/*.yaml (sorted)",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate all scenario manifests, seeds, and flows",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root (default: parent of tool/)",
    )
    args = parser.parse_args()
    root = args.repo_root or repo_root_from_here()

    if args.list:
        return cmd_list(root)
    if args.validate:
        return cmd_validate(root)
    if args.manifest is None or args.key is None:
        parser.error("manifest and key are required unless --list or --validate is used")
    return cmd_get(args.manifest, args.key)


if __name__ == "__main__":
    raise SystemExit(main())
