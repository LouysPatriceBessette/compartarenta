#!/usr/bin/env python3
"""Read and validate qa/multi_scenarios/*.yaml manifests."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_KEYS = ("id", "device_date", "timezone", "coordinator")
ROLE_KEY_RE = re.compile(r"^role_([a-z][a-z0-9_]*):")
MANIFEST_KEY_RE = re.compile(r"^([a-zA-Z0-9_]+):\s*(.+)$")
ROLE_FIELD_RE = re.compile(r"^\s{2}([a-z_]+):\s*(.+)$")


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parent.parent


def multi_scenarios_dir(root: Path) -> Path:
    return root / "qa" / "multi_scenarios"


def parse_manifest(path: Path) -> tuple[dict[str, str], dict[str, dict[str, str]]]:
    fields: dict[str, str] = {}
    roles: dict[str, dict[str, str]] = {}
    current_role: str | None = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        role_match = ROLE_KEY_RE.match(stripped)
        if role_match:
            current_role = role_match.group(1)
            roles[current_role] = {}
            continue

        role_field = ROLE_FIELD_RE.match(line)
        if role_field and current_role is not None:
            key, value = role_field.group(1), role_field.group(2).strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            roles[current_role][key] = value
            continue

        current_role = None
        match = MANIFEST_KEY_RE.match(stripped)
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        fields[key] = value

    return fields, roles


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


def validate_multi_scenarios(root: Path) -> list[str]:
    errors: list[str] = []
    directory = multi_scenarios_dir(root)
    if not directory.is_dir():
        return [f"missing multi_scenarios directory: {directory}"]

    seed_ids = load_seed_ids(root / "mobile" / "lib" / "debug" / "qa_scenario_seed.dart")
    manifests = sorted(directory.glob("*.yaml"))
    if not manifests:
        errors.append(f"no multi-scenario manifests in {directory}")
        return errors

    seen_ids: set[str] = set()
    for path in manifests:
        rel = path.relative_to(root)
        fields, roles = parse_manifest(path)
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

        coordinator = fields.get("coordinator", "")
        coordinator_path = root / "tool" / "coordinators" / f"{coordinator}.sh"
        if coordinator and not coordinator_path.is_file():
            errors.append(f"{rel}: coordinator script missing: tool/coordinators/{coordinator}.sh")

        if not roles:
            errors.append(f"{rel}: at least one role_* block is required")

        for role_name, role_fields in roles.items():
            for required in ("avd", "seed", "flow"):
                if required not in role_fields or not role_fields[required].strip():
                    errors.append(f"{rel}: role_{role_name} missing '{required}'")
            seed = role_fields.get("seed", "")
            if seed and seed_ids and seed not in seed_ids:
                errors.append(
                    f"{rel}: role_{role_name} seed '{seed}' not in kQaScenarioIds",
                )
            flow_rel = role_fields.get("flow", "")
            if flow_rel:
                flow_path = root / flow_rel
                if not flow_path.is_file():
                    errors.append(f"{rel}: role_{role_name} flow missing: {flow_rel}")

    return errors


def cmd_validate(root: Path) -> int:
    errors = validate_multi_scenarios(root)
    if not errors:
        count = len(list(multi_scenarios_dir(root).glob("*.yaml")))
        print(f"OK: {count} multi-scenario manifest(s) validated")
        return 0
    for err in errors:
        print(f"ERROR: {err}", file=sys.stderr)
    return 1


def cmd_get(manifest: Path, key: str) -> int:
    fields, roles = parse_manifest(manifest)
    if key.startswith("role."):
        _, role_name, field = key.split(".", 2)
        role = roles.get(role_name)
        if role is None or field not in role:
            print(f"manifest role field not found: {key}", file=sys.stderr)
            return 1
        print(role[field])
        return 0
    if key == "roles":
        print(" ".join(sorted(roles)))
        return 0
    if key not in fields:
        print(f"manifest key not found: {key}", file=sys.stderr)
        return 1
    print(fields[key])
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", nargs="?", type=Path)
    parser.add_argument("key", nargs="?")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--repo-root", type=Path, default=None)
    args = parser.parse_args()
    root = args.repo_root or repo_root_from_here()

    if args.validate:
        return cmd_validate(root)
    if args.manifest is None or args.key is None:
        parser.error("manifest and key are required unless --validate is used")
    return cmd_get(args.manifest, args.key)


if __name__ == "__main__":
    raise SystemExit(main())
