#!/usr/bin/env bash
# Run all QA scenarios discovered from qa/scenarios/*.yaml on the Android emulator.
#
# Usage: ./tool/run_all_scenarios.sh [--skip-build] [--skip-install] [--skip-restore] [--no-retry]
#
# After the first scenario, --skip-build and --skip-install are applied automatically
# unless you pass --rebuild-each. Each failed scenario is retried once after System UI
# recovery unless --no-retry is set.
#
# Produces a unified run directory:
#   qa/artifacts/run-<UTC-timestamp>/
#     index.html      aggregated report
#     results.json    machine-readable summary
#     <scenario-id>/  per-scenario Maestro output + screenshots

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

EXTRA_ARGS=()
REBUILD_EACH=0
SKIP_RESTORE=0
RETRY_FAILED=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) EXTRA_ARGS+=(--skip-build) ;;
    --skip-install) EXTRA_ARGS+=(--skip-install) ;;
    --skip-restore) SKIP_RESTORE=1 ;;
    --rebuild-each) REBUILD_EACH=1 ;;
    --no-retry) RETRY_FAILED=0 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! mapfile -t SCENARIOS < <(python3 "${ROOT}/tool/qa_scenario_manifest.py" --list); then
  echo "Failed to list scenarios from qa/scenarios/*.yaml" >&2
  exit 1
fi

if [[ "${#SCENARIOS[@]}" -eq 0 ]]; then
  echo "No scenarios found under qa/scenarios/" >&2
  exit 1
fi

echo "Discovered ${#SCENARIOS[@]} scenario(s): ${SCENARIOS[*]}"

if ! python3 "${ROOT}/tool/qa_scenario_manifest.py" --validate; then
  echo "Scenario manifest validation failed. Fix qa/scenarios/ before running." >&2
  exit 1
fi

if ! python3 "${ROOT}/tool/verify_qa_semantics.py"; then
  echo "Maestro ↔ Dart semantics verification failed." >&2
  exit 1
fi

RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${ROOT}/qa/artifacts/run-${RUN_STAMP}"
mkdir -p "${RUN_DIR}"

STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "${RUN_DIR}" "${RUN_STAMP}" "${STARTED_AT}" <<'PY'
import json
import sys
from pathlib import Path

run_dir, run_id, started_at = sys.argv[1:4]
payload = {
    "run_id": run_id,
    "started_at": started_at,
    "finished_at": None,
    "scenarios": [],
}
Path(run_dir, "results.json").write_text(
    json.dumps(payload, indent=2) + "\n",
    encoding="utf-8",
)
PY

FAILED=()
PASSED=()
FIRST=1

append_result() {
  local scenario="$1"
  local status="$2"
  local error_msg="${3:-}"
  python3 - "${RUN_DIR}" "${scenario}" "${status}" "${error_msg}" <<'PY'
import json
import sys
from pathlib import Path

run_dir, scenario_id, status, error_msg = sys.argv[1:5]
path = Path(run_dir) / "results.json"
data = json.loads(path.read_text(encoding="utf-8"))
entry = {
    "id": scenario_id,
    "status": status,
    "artifact_dir": scenario_id,
}
if error_msg:
    entry["error"] = error_msg
data["scenarios"].append(entry)
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

run_one_scenario() {
  local scenario="$1"
  local artifact_dir="$2"
  local -a run_args=(--artifact-dir "${artifact_dir}")
  run_args+=("${EXTRA_ARGS[@]}")
  if [[ "${FIRST}" -eq 0 && "${REBUILD_EACH}" -eq 0 ]]; then
    run_args+=(--skip-build --skip-install)
  fi
  run_args+=(--skip-restore)
  "${ROOT}/tool/run_scenario.sh" "${scenario}" "${run_args[@]}"
}

for scenario in "${SCENARIOS[@]}"; do
  if [[ "${FIRST}" -eq 0 ]]; then
    SERIAL="$(qa_use_emulator_adb_serial)"
    qa_prepare_for_maestro "${SERIAL}"
    sleep 1
  fi

  echo "========== ${scenario} =========="
  SCENARIO_ARTIFACT_DIR="${RUN_DIR}/${scenario}"
  MAX_ATTEMPTS=1
  if [[ "${RETRY_FAILED}" -eq 1 ]]; then
    MAX_ATTEMPTS=2
  fi

  RUN_EXIT=1
  RUN_LOG="$(mktemp)"
  for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
    if [[ "${attempt}" -gt 1 ]]; then
      echo "Retrying ${scenario} after System UI recovery (attempt ${attempt}/${MAX_ATTEMPTS})..."
      SERIAL="$(qa_use_emulator_adb_serial)"
      qa_recover_system_ui "${SERIAL}"
      sleep 2
    fi
    set +e
    run_one_scenario "${scenario}" "${SCENARIO_ARTIFACT_DIR}" >"${RUN_LOG}" 2>&1
    RUN_EXIT=$?
    set -e
    if [[ "${RUN_EXIT}" -eq 0 ]]; then
      break
    fi
  done

  if [[ "${RUN_EXIT}" -eq 0 ]]; then
    PASSED+=("${scenario}")
    append_result "${scenario}" "passed"
    cat "${RUN_LOG}"
  else
    FAILED+=("${scenario}")
    ERROR_SNIPPET="$(tail -n 20 "${RUN_LOG}")"
    append_result "${scenario}" "failed" "${ERROR_SNIPPET}"
    cat "${RUN_LOG}" >&2
    SERIAL="$(qa_use_emulator_adb_serial)"
    qa_recover_system_ui "${SERIAL}"
  fi
  rm -f "${RUN_LOG}"
  FIRST=0
done

RESTORE_ARGS=()
if [[ "${SKIP_RESTORE}" -eq 1 ]]; then
  RESTORE_ARGS=(--skip-restore)
fi
REPORT_PATH="$("${ROOT}/tool/qa_finalize_run.sh" "${RUN_DIR}" "${RESTORE_ARGS[@]}")"

echo ""
echo "Done: ${#PASSED[@]}/${#SCENARIOS[@]} scenario(s) passed."
echo "Passed (${#PASSED[@]}): ${PASSED[*]:-none}"
echo "Failed (${#FAILED[@]}): ${FAILED[*]:-none}"
echo "Run directory: ${RUN_DIR}"
echo "HTML report: ${REPORT_PATH}"

if [[ "${#FAILED[@]}" -gt 0 ]]; then
  exit 1
fi
