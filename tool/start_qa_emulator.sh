#!/usr/bin/env bash
# Start the Compartarenta-QA emulator (cold boot by default).
#
# Usage:
#   ./tool/start_qa_emulator.sh          # cold boot (-no-snapshot-load)
#   ./tool/start_qa_emulator.sh --quick  # resume from snapshot if available

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command emulator

AVD_NAME="${COMPARTARENTA_QA_AVD_NAME}"
MODE="cold"
if [[ "${1:-}" == "--quick" ]]; then
  MODE="quick"
fi

if ! avdmanager list avd | grep -Fq "Name: ${AVD_NAME}"; then
  echo "AVD ${AVD_NAME} not found. Run ./tool/create_qa_avd.sh first." >&2
  exit 1
fi

if adb devices | awk '/^emulator-[0-9]+\tdevice$/{found=1} END{exit !found}'; then
  SERIAL="$(adb devices | awk '/^emulator-[0-9]+\tdevice$/{print $1; exit}')"
  echo "Emulator already running: ${SERIAL}"
  qa_wait_for_boot_completed "${SERIAL}"
  exit 0
fi

PENDING="$(adb devices | awk '/^emulator-[0-9]+\t/{print $1; exit}')"
if [[ -n "${PENDING}" ]]; then
  echo "Waiting for existing emulator ${PENDING} to become ready..."
  SERIAL="$(qa_wait_for_emulator_serial)"
  qa_wait_for_boot_completed "${SERIAL}"
  echo "Emulator ready: ${SERIAL}"
  exit 0
fi

EMULATOR_ARGS=(-avd "${AVD_NAME}" -netdelay none -netspeed full)
if [[ "${MODE}" == "cold" ]]; then
  EMULATOR_ARGS+=(-no-snapshot-load)
fi

echo "Starting ${AVD_NAME} (${MODE} boot)..."
nohup emulator "${EMULATOR_ARGS[@]}" >/dev/null 2>&1 &
EMULATOR_PID=$!
echo "emulator pid=${EMULATOR_PID}"

SERIAL="$(qa_wait_for_emulator_serial)"
qa_wait_for_boot_completed "${SERIAL}"
echo "Emulator ready: ${SERIAL}"
