#!/usr/bin/env bash
# Run all phase-2 QA scenarios sequentially on the Android emulator.
#
# Usage: ./tool/run_all_scenarios.sh [--skip-build] [--skip-install] [--skip-restore]
#
# After the first scenario, --skip-build and --skip-install are applied automatically
# unless you pass --rebuild-each.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SCENARIOS=(
  period_end_day
  settlement_open
  settlement_last_day
  settlement_closed
  renewal_fork_visible
  voluntary_withdrawal_ack_j5
  voluntary_withdrawal_effective
  proposal_response_expired
)

EXTRA_ARGS=()
REBUILD_EACH=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) EXTRA_ARGS+=(--skip-build) ;;
    --skip-install) EXTRA_ARGS+=(--skip-install) ;;
    --skip-restore) EXTRA_ARGS+=(--skip-restore) ;;
    --rebuild-each) REBUILD_EACH=1 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

FAILED=()
PASSED=()
FIRST=1

for scenario in "${SCENARIOS[@]}"; do
  echo "========== ${scenario} =========="
  RUN_ARGS=("${EXTRA_ARGS[@]}")
  if [[ "${FIRST}" -eq 0 && "${REBUILD_EACH}" -eq 0 ]]; then
    RUN_ARGS+=(--skip-build --skip-install)
  fi
  if "${ROOT}/tool/run_scenario.sh" "${scenario}" "${RUN_ARGS[@]}"; then
    PASSED+=("${scenario}")
  else
    FAILED+=("${scenario}")
  fi
  FIRST=0
done

echo ""
echo "Passed (${#PASSED[@]}): ${PASSED[*]:-none}"
echo "Failed (${#FAILED[@]}): ${FAILED[*]:-none}"

if [[ "${#FAILED[@]}" -gt 0 ]]; then
  exit 1
fi
