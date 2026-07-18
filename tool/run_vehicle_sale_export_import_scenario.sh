#!/usr/bin/env bash
# Vehicle sale export → wipe → import QA (single emulator).
#
# Usage:
#   ./tool/run_vehicle_sale_export_import_scenario.sh
#   ./tool/run_vehicle_sale_export_import_scenario.sh --skip-build --skip-install
#
# Seeds seller history, runs Maestro export, pulls the debug zip marker, fully
# stops and cold-boots the emulator, reseeds an empty buyer identity, pushes the
# zip for debug import, runs Maestro import.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
export PATH="${HOME}/.maestro/bin:${PATH}"

SCENARIO_ID="vehicle_sale_export_import"
SELLER_SEED="vehicle_sale_export_import_seller"
BUYER_SEED="vehicle_sale_export_import_buyer"
DEVICE_DATE_RAW="current"
TIMEZONE="America/Toronto"
DEVICE_DATE="$(qa_resolve_device_date "${DEVICE_DATE_RAW}" "${TIMEZONE}")"
FLOW_EXPORT="${ROOT}/qa/flows/vehicle_sale_export.yaml"
FLOW_IMPORT="${ROOT}/qa/flows/vehicle_sale_import.yaml"

SKIP_BUILD=0
SKIP_INSTALL=0
SKIP_RESTORE=0
ARTIFACT_DIR_OVERRIDE=""

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

if ! command -v maestro >/dev/null 2>&1; then
  if [[ -x "${HOME}/.maestro/bin/maestro" ]]; then
    export PATH="${HOME}/.maestro/bin:${PATH}"
  else
    echo "Maestro not found. Run ./tool/install_maestro.sh" >&2
    exit 1
  fi
fi

for f in "${FLOW_EXPORT}" "${FLOW_IMPORT}"; do
  if [[ ! -f "${f}" ]]; then
    echo "Missing flow: ${f}" >&2
    exit 1
  fi
done

"${ROOT}/tool/start_qa_emulator.sh"
EMULATOR_SERIAL="$(qa_use_emulator_adb_serial)"
echo "Using emulator ${EMULATOR_SERIAL} (ANDROID_SERIAL)"

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
  "${ROOT}/tool/build_qa_apk.sh"
fi
if [[ "${SKIP_INSTALL}" -eq 0 ]]; then
  "${ROOT}/tool/install_qa_apk.sh"
fi

if [[ -n "${ARTIFACT_DIR_OVERRIDE}" ]]; then
  ARTIFACT_DIR="${ARTIFACT_DIR_OVERRIDE}"
else
  STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
  ARTIFACT_DIR="${ROOT}/qa/artifacts/${SCENARIO_ID}/${STAMP}"
fi
mkdir -p "${ARTIFACT_DIR}"
EXPORT_ARTIFACTS="${ARTIFACT_DIR}/export"
IMPORT_ARTIFACTS="${ARTIFACT_DIR}/import"
ZIP_HOST="${ARTIFACT_DIR}/vehicle_sale_export.zip"
mkdir -p "${EXPORT_ARTIFACTS}" "${IMPORT_ARTIFACTS}"

echo "=== Phase 1 === device=${EMULATOR_SERIAL} seed=${SELLER_SEED} set clock"
ANDROID_SERIAL="${EMULATOR_SERIAL}" "${ROOT}/tool/set_android_date.sh" \
  "${DEVICE_DATE}" "${TIMEZONE}"
ANDROID_SERIAL="${EMULATOR_SERIAL}" "${ROOT}/tool/seed_qa_scenario.sh" "${SELLER_SEED}"
qa_prepare_for_maestro "${EMULATOR_SERIAL}"

echo "=== Phase 2 === device=${EMULATOR_SERIAL} Maestro export flow=${FLOW_EXPORT}"
maestro test --udid "${EMULATOR_SERIAL}" "${FLOW_EXPORT}" \
  --test-output-dir "${EXPORT_ARTIFACTS}"

echo "=== Phase 3 === device=${EMULATOR_SERIAL} pull export zip"
if ! qa_pull_vehicle_sale_export_zip "${EMULATOR_SERIAL}" "${ZIP_HOST}"; then
  echo "Failed to pull app_flutter/compartarenta_qa_vehicle_sale_export.zip" >&2
  exit 1
fi
echo "Pulled export zip ($(wc -c <"${ZIP_HOST}") bytes) -> ${ZIP_HOST}"

# Second pm clear on a still-running emulator after Maestro often leaves System UI /
# bootstrap hung (seed_applied never appears). Full AVD stop + cold boot before buyer seed.
echo "=== Phase 4 === device=${EMULATOR_SERIAL} full emulator stop + cold boot before buyer seed"
qa_kill_emulator "${EMULATOR_SERIAL}"
"${ROOT}/tool/start_qa_emulator.sh"
EMULATOR_SERIAL="$(qa_use_emulator_adb_serial)"
echo "Using emulator ${EMULATOR_SERIAL} after cold boot (ANDROID_SERIAL)"

echo "=== Phase 5 === device=${EMULATOR_SERIAL} seed=${BUYER_SEED} set clock"
ANDROID_SERIAL="${EMULATOR_SERIAL}" "${ROOT}/tool/set_android_date.sh" \
  "${DEVICE_DATE}" "${TIMEZONE}"
ANDROID_SERIAL="${EMULATOR_SERIAL}" "${ROOT}/tool/seed_qa_scenario.sh" "${BUYER_SEED}"

echo "=== Phase 6 === device=${EMULATOR_SERIAL} push import zip"
if ! qa_push_vehicle_sale_import_zip "${EMULATOR_SERIAL}" "${ZIP_HOST}"; then
  echo "Failed to push import zip into app_flutter" >&2
  exit 1
fi
qa_prepare_for_maestro "${EMULATOR_SERIAL}"

echo "=== Phase 7 === device=${EMULATOR_SERIAL} Maestro import flow=${FLOW_IMPORT}"
maestro test --udid "${EMULATOR_SERIAL}" "${FLOW_IMPORT}" \
  --test-output-dir "${IMPORT_ARTIFACTS}"

if [[ "${SKIP_RESTORE}" -eq 0 ]]; then
  ANDROID_SERIAL="${EMULATOR_SERIAL}" "${ROOT}/tool/restore_android_date.sh" || true
fi

echo "Scenario PASSED | ${SCENARIO_ID}. Artifacts: ${ARTIFACT_DIR}"
