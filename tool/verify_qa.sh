#!/usr/bin/env bash
# Verify QA toolchain: phase-0 prerequisites, scenario manifests, Maestro ↔ Dart ids.
#
# Usage: ./tool/verify_qa.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0

run_check() {
  local label="$1"
  shift
  if "$@"; then
    echo "[ok]   ${label}"
  else
    echo "[FAIL] ${label}" >&2
    failures=$((failures + 1))
  fi
}

echo "Compartarenta QA — verification"
echo

# Phase 0 checks (non-fatal sections keep their own exit code handling).
set +e
"${ROOT}/tool/verify_qa_phase0.sh"
phase0_exit=$?
set -e
if [[ "${phase0_exit}" -ne 0 ]]; then
  failures=$((failures + 1))
  echo "[FAIL] phase 0 prerequisites" >&2
else
  echo "[ok]   phase 0 prerequisites"
fi

echo
run_check "scenario manifests (qa/scenarios/*.yaml)" \
  python3 "${ROOT}/tool/qa_scenario_manifest.py" --validate

run_check "multi-device manifests (qa/multi_scenarios/*.yaml)" \
  python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" --validate

run_check "Maestro ↔ Dart semantics (qa-* ids)" \
  python3 "${ROOT}/tool/verify_qa_semantics.py"

echo
if [[ "${failures}" -eq 0 ]]; then
  echo "QA verification: OK"
  exit 0
fi

echo "QA verification: ${failures} check group(s) failed" >&2
exit 1
