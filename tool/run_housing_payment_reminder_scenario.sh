#!/usr/bin/env bash
# Housing payment reminder QA — single Monica-QA emulator (#10×2 + #11, simulated, no relay).
#
# Usage:
#   ./tool/run_housing_payment_reminder_scenario.sh
#   ./tool/run_housing_payment_reminder_scenario.sh --skip-build --skip-install
#
# Seed once on J−4, then one phase per fire (J−4, J−2, due day J, overdue)
# without pm clear so journal rows accumulate.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
export PATH="${HOME}/.maestro/bin:${PATH}"

SCENARIO_ID="housing_payment_reminder_before_due"
SKIP_BUILD=0
SKIP_INSTALL=0
SKIP_RESTORE=0
ARTIFACT_DIR_OVERRIDE=""
AVD="${COMPARTARENTA_PAYMENT_REMINDER_AVD:-Monica-QA}"

# Prevent overlapping runs (same AVD) — e.g. agent leftover + operator Ctrl+C race.
LOCK_FILE="${COMPARTARENTA_QA_LOCAL_DIR:-${ROOT}/qa/.local}/payment-reminder.lock"
mkdir -p "$(dirname "${LOCK_FILE}")"
exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  echo "ERROR: another housing payment reminder scenario is already running." >&2
  echo "  Lock: ${LOCK_FILE}" >&2
  echo "  If stale: pgrep -af run_housing_payment_reminder ; kill that PID; retry." >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1 ;;
    --skip-install) SKIP_INSTALL=1 ;;
    --skip-restore) SKIP_RESTORE=1 ;;
    --artifact-dir)
      if [[ $# -lt 2 ]]; then
        echo "--artifact-dir requires a path" >&2
        exit 1
      fi
      ARTIFACT_DIR_OVERRIDE="$2"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--skip-build] [--skip-install] [--skip-restore] [--artifact-dir DIR]" >&2
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

MANIFEST="${ROOT}/qa/multi_scenarios/${SCENARIO_ID}.yaml"
if [[ ! -f "${MANIFEST}" ]]; then
  echo "Missing manifest: ${MANIFEST}" >&2
  exit 1
fi

if ! command -v maestro >/dev/null 2>&1; then
  if [[ -x "${HOME}/.maestro/bin/maestro" ]]; then
    export PATH="${HOME}/.maestro/bin:${PATH}"
  else
    echo "Maestro not found. Run ./tool/install_maestro.sh" >&2
    exit 1
  fi
fi

TIMEZONE="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" timezone)"
ANCHOR_DATE_RAW="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" device_date)"
ANCHOR_DATE="$(qa_resolve_device_date "${ANCHOR_DATE_RAW}" "${TIMEZONE}")"

DATES_PY=(python3 "${ROOT}/tool/qa_housing_payment_reminder_dates.py"
  --anchor "${ANCHOR_DATE}"
  --timezone "${TIMEZONE}")
DUE_MS="$("${DATES_PY[@]}" --field due_ms)"
FIRE_J4="$("${DATES_PY[@]}" --field before_due_0)"
FIRE_J2="$("${DATES_PY[@]}" --field before_due_1)"
FIRE_DUE_DAY="$("${DATES_PY[@]}" --field before_due_2)"
FIRE_OVERDUE="$("${DATES_PY[@]}" --field overdue)"

FLOW_LAUNCH="${ROOT}/qa/flows/housing_payment_reminder_launch.yaml"
FLOW_TAP_J4="${ROOT}/qa/flows/housing_payment_reminder_tap_before_due_first.yaml"
FLOW_TAP_J2="${ROOT}/qa/flows/housing_payment_reminder_tap_before_due_second.yaml"
FLOW_TAP_DUE_DAY="${ROOT}/qa/flows/housing_payment_reminder_tap_due_day.yaml"
FLOW_TAP_OVERDUE="${ROOT}/qa/flows/housing_payment_reminder_tap_overdue.yaml"
FLOW_PROBE="${ROOT}/qa/flows/housing_payment_reminder_probe_monthly_expenses.yaml"
FLOW_OPEN_JOURNAL="${ROOT}/qa/flows/housing_payment_reminder_open_monthly_expenses.yaml"
FLOW_ASSERT_J4="${ROOT}/qa/flows/housing_payment_reminder_assert_before_due_first.yaml"
FLOW_ASSERT_J2="${ROOT}/qa/flows/housing_payment_reminder_assert_before_due_second.yaml"
FLOW_ASSERT_DUE_DAY="${ROOT}/qa/flows/housing_payment_reminder_assert_due_day.yaml"
FLOW_ASSERT_OVERDUE="${ROOT}/qa/flows/housing_payment_reminder_assert_overdue.yaml"

echo "Calendar anchor: ${ANCHOR_DATE} (${TIMEZONE})"
echo "Due ms: ${DUE_MS}"
echo "Fires: J-4=${FIRE_J4} | J-2=${FIRE_J2} | due-day=${FIRE_DUE_DAY} | overdue=${FIRE_OVERDUE}"

COORDINATOR_SCRIPT="${ROOT}/tool/coordinators/housing_payment_reminder.sh"
chmod +x "${COORDINATOR_SCRIPT}"

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
  "${ROOT}/tool/build_qa_apk.sh"
fi

echo "Ensuring emulator ${AVD} is running..."
SERIAL="$(qa_ensure_named_avd_running "${AVD}")"
echo "Device ${AVD} -> ${SERIAL}"

if [[ "${SKIP_INSTALL}" -eq 0 ]]; then
  qa_install_qa_apk_on_serial "${SERIAL}"
fi

if [[ -n "${ARTIFACT_DIR_OVERRIDE}" ]]; then
  ARTIFACT_ROOT="${ARTIFACT_DIR_OVERRIDE}"
else
  STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  ARTIFACT_ROOT="${ROOT}/qa/artifacts/multi-${SCENARIO_ID}/${STAMP}"
fi
mkdir -p "${ARTIFACT_ROOT}"

export COMPARTARENTA_PAYMENT_REMINDER_SERIAL="${SERIAL}"
export COMPARTARENTA_MULTI_ARTIFACT_ROOT="${ARTIFACT_ROOT}"
export COMPARTARENTA_MULTI_TIMEZONE="${TIMEZONE}"
export COMPARTARENTA_PAYMENT_REMINDER_ANCHOR_DATE="${ANCHOR_DATE}"
export COMPARTARENTA_PAYMENT_REMINDER_DUE_MS="${DUE_MS}"
export COMPARTARENTA_PAYMENT_REMINDER_FIRE_J4="${FIRE_J4}"
export COMPARTARENTA_PAYMENT_REMINDER_FIRE_J2="${FIRE_J2}"
export COMPARTARENTA_PAYMENT_REMINDER_FIRE_DUE_DAY="${FIRE_DUE_DAY}"
export COMPARTARENTA_PAYMENT_REMINDER_FIRE_OVERDUE="${FIRE_OVERDUE}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_LAUNCH="${FLOW_LAUNCH}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_J4="${FLOW_TAP_J4}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_J2="${FLOW_TAP_J2}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_DUE_DAY="${FLOW_TAP_DUE_DAY}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_OVERDUE="${FLOW_TAP_OVERDUE}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_PROBE="${FLOW_PROBE}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_OPEN_JOURNAL="${FLOW_OPEN_JOURNAL}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_ASSERT_J4="${FLOW_ASSERT_J4}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_ASSERT_J2="${FLOW_ASSERT_J2}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_ASSERT_DUE_DAY="${FLOW_ASSERT_DUE_DAY}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_ASSERT_OVERDUE="${FLOW_ASSERT_OVERDUE}"

# shellcheck disable=SC1090
source "${ROOT}/tool/qa_env.sh"
export -f qa_maestro_artifact_dir 2>/dev/null || true
export -f qa_screencap_md5_on_serial 2>/dev/null || true
export -f qa_open_notification_shade_on_serial 2>/dev/null || true
export -f qa_collapse_notification_shade_on_serial 2>/dev/null || true

"${COORDINATOR_SCRIPT}"

if [[ "${SKIP_RESTORE}" -eq 0 ]]; then
  ANDROID_SERIAL="${SERIAL}" "${ROOT}/tool/restore_android_date.sh" || true
fi

echo "Done. Artifacts: ${ARTIFACT_ROOT}"
