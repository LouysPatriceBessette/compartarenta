#!/usr/bin/env bash
# FCM wake manual QA — Monica (emulator) + physical recipient (default R3CY202HKYL).
#
# Sequential steps only (no parallel Maestro). Operator confirms notification on phone.
#
# Usage:
#   ./tool/run_fcm_wake_push_scenario.sh
#   COMPARTARENTA_FCM_WAKE_RECIPIENT_SERIAL=R3CY202HKYL ./tool/run_fcm_wake_push_scenario.sh
#   ./tool/run_fcm_wake_push_scenario.sh --skip-build --skip-install
#
# Prerequisites:
#   - USB debugging on; adb devices shows the recipient serial.
#   - Monica-QA AVD exists (qa:create-avd with COMPARTARENTA_QA_AVD_NAME=Monica-QA).
#   - This script builds/installs the current dev debug APK on BOTH emulator and phone.
#     Recipient seed uses pm clear; POST_NOTIFICATIONS is re-granted via adb before cold start.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
export PATH="${HOME}/.maestro/bin:${PATH}"

SCENARIO_ID="fcm_wake_push_emulator_physical"
SKIP_BUILD=0
SKIP_INSTALL=0
SKIP_RESTORE=0
ARTIFACT_DIR_OVERRIDE=""
RECIPIENT_SERIAL="${COMPARTARENTA_FCM_WAKE_RECIPIENT_SERIAL:-R3CY202HKYL}"
PROPOSER_AVD="${COMPARTARENTA_FCM_WAKE_PROPOSER_AVD:-Monica-QA}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1 ;;
    --skip-install) SKIP_INSTALL=1 ;;
    --skip-restore) SKIP_RESTORE=1 ;;
    --recipient-serial)
      if [[ $# -lt 2 ]]; then
        echo "--recipient-serial requires a value" >&2
        exit 1
      fi
      RECIPIENT_SERIAL="$2"
      shift
      ;;
    --artifact-dir)
      if [[ $# -lt 2 ]]; then
        echo "--artifact-dir requires a path" >&2
        exit 1
      fi
      ARTIFACT_DIR_OVERRIDE="$2"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--skip-build] [--skip-install] [--skip-restore] [--recipient-serial SERIAL] [--artifact-dir DIR]" >&2
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

COORDINATOR="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" coordinator)"
MODE="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" mode 2>/dev/null || true)"
DEVICE_DATE="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" device_date)"
TIMEZONE="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" timezone)"
PROPOSER_SEED="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" role.proposer.seed)"
RECIPIENT_SEED="$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" role.recipient.seed)"
PROPOSER_FLOW="${ROOT}/$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" role.proposer.flow)"
RECIPIENT_FLOW="${ROOT}/$(python3 "${ROOT}/tool/qa_multi_scenario_manifest.py" "${MANIFEST}" role.recipient.flow)"

COORDINATOR_SCRIPT="${ROOT}/tool/coordinators/${COORDINATOR}.sh"
if [[ ! -f "${COORDINATOR_SCRIPT}" ]]; then
  echo "Coordinator script missing: ${COORDINATOR_SCRIPT}" >&2
  exit 1
fi
chmod +x "${COORDINATOR_SCRIPT}"

qa_require_usb_serial "${RECIPIENT_SERIAL}"

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
  "${ROOT}/tool/build_qa_apk.sh"
fi

echo "Ensuring proposer emulator ${PROPOSER_AVD} is running..."
PROPOSER_SERIAL="$(qa_ensure_named_avd_running "${PROPOSER_AVD}")"
echo "Proposer ${PROPOSER_AVD} -> ${PROPOSER_SERIAL}"

if [[ "${SKIP_INSTALL}" -eq 0 ]]; then
  qa_install_qa_apk_on_serial "${PROPOSER_SERIAL}"
  COMPARTARENTA_QA_ALLOW_USB_APK_INSTALL=1 qa_install_qa_apk_on_serial "${RECIPIENT_SERIAL}"
fi

if [[ -n "${ARTIFACT_DIR_OVERRIDE}" ]]; then
  ARTIFACT_ROOT="${ARTIFACT_DIR_OVERRIDE}"
else
  STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  ARTIFACT_ROOT="${ROOT}/qa/artifacts/multi-${SCENARIO_ID}/${STAMP}"
fi
mkdir -p "${ARTIFACT_ROOT}"

qa_set_android_date_on_serial "${PROPOSER_SERIAL}" "${DEVICE_DATE}" "${TIMEZONE}"
qa_seed_scenario_on_serial "${PROPOSER_SERIAL}" "${PROPOSER_SEED}"
"${ROOT}/tool/qa_fcm_wake_establish_relay_routing.sh"
COMPARTARENTA_QA_GRANT_POST_NOTIFICATIONS=1 \
  qa_seed_scenario_on_serial "${RECIPIENT_SERIAL}" "${RECIPIENT_SEED}"

qa_prepare_for_maestro "${PROPOSER_SERIAL}"
# Recipient must stay out of force-stopped state or Android blocks FCM (GCM CANCELLED).
adb -s "${RECIPIENT_SERIAL}" shell am kill "${COMPARTARENTA_QA_APP_ID}" >/dev/null 2>&1 || true
adb -s "${RECIPIENT_SERIAL}" shell input keyevent KEYCODE_BACK >/dev/null 2>&1 || true
sleep 1

export COMPARTARENTA_MULTI_SCENARIO_ID="${SCENARIO_ID}"
export COMPARTARENTA_MULTI_MANIFEST="${MANIFEST}"
export COMPARTARENTA_MULTI_MODE="${MODE}"
export COMPARTARENTA_MULTI_ARTIFACT_ROOT="${ARTIFACT_ROOT}"
export COMPARTARENTA_MULTI_DEVICE_DATE="${DEVICE_DATE}"
export COMPARTARENTA_MULTI_TIMEZONE="${TIMEZONE}"
export COMPARTARENTA_ROLE_PROPOSER_SERIAL="${PROPOSER_SERIAL}"
export COMPARTARENTA_ROLE_RECIPIENT_SERIAL="${RECIPIENT_SERIAL}"
export COMPARTARENTA_ROLE_PROPOSER_SEED="${PROPOSER_SEED}"
export COMPARTARENTA_ROLE_RECIPIENT_SEED="${RECIPIENT_SEED}"
export COMPARTARENTA_ROLE_PROPOSER_FLOW="${PROPOSER_FLOW}"
export COMPARTARENTA_ROLE_RECIPIENT_FLOW="${RECIPIENT_FLOW}"

echo "Running FCM wake coordinator ${COORDINATOR} (recipient=${RECIPIENT_SERIAL})"
set +e
"${COORDINATOR_SCRIPT}"
COORD_EXIT=$?
set -e

if [[ "${SKIP_RESTORE}" -eq 0 ]]; then
  ANDROID_SERIAL="${PROPOSER_SERIAL}" "${ROOT}/tool/restore_android_date.sh" || true
fi

cp "${MANIFEST}" "${ARTIFACT_ROOT}/multi-scenario.yaml"

echo ""
echo "================================================================================"
if [[ "${COORD_EXIT}" -eq 0 ]]; then
  echo "Automation PASSED | ${SCENARIO_ID} (notification still requires manual check)"
else
  echo "Automation FAILED | ${SCENARIO_ID} (exit ${COORD_EXIT})"
fi
echo "Artifacts: ${ARTIFACT_ROOT}"
echo "================================================================================"
echo ""

exit "${COORD_EXIT}"
