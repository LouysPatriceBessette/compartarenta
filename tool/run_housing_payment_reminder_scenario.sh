#!/usr/bin/env bash
# Housing payment reminder QA — single Monica-QA emulator (#10 simulated, no relay).
#
# Usage:
#   ./tool/run_housing_payment_reminder_scenario.sh
#   ./tool/run_housing_payment_reminder_scenario.sh --skip-build --skip-install
#
# Anchor date = current (for J−4 math). Emulator is set to the first before-due
# fire (J−4 @ 14:00 local for monthly Loyer day 1). No relay.

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
NOTIFICATION_DATE="$(python3 "${ROOT}/tool/qa_housing_payment_reminder_dates.py" \
  --anchor "${ANCHOR_DATE}" \
  --timezone "${TIMEZONE}")"
FLOW_LAUNCH="${ROOT}/$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" flow_launch)"
FLOW_TAP="${ROOT}/$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" flow_tap)"

echo "Calendar anchor: ${ANCHOR_DATE} (${TIMEZONE})"
echo "Notification date (computed): ${NOTIFICATION_DATE}"

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
export COMPARTARENTA_PAYMENT_REMINDER_NOTIFICATION_DATE="${NOTIFICATION_DATE}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_LAUNCH="${FLOW_LAUNCH}"
export COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP="${FLOW_TAP}"

# shellcheck disable=SC1090
source "${ROOT}/tool/qa_env.sh"
export -f qa_maestro_artifact_dir 2>/dev/null || true

"${COORDINATOR_SCRIPT}"

if [[ "${SKIP_RESTORE}" -eq 0 ]]; then
  ANDROID_SERIAL="${SERIAL}" "${ROOT}/tool/restore_android_date.sh" || true
fi

echo "Done. Artifacts: ${ARTIFACT_ROOT}"
