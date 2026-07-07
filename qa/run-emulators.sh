#!/usr/bin/env bash
# Ensure QA AVDs exist, start one emulator per AVD, collect adb serials.
#
# Usage (from repo root):
#   qa/run-emulators.sh
#   qa/run-emulators.sh -n 3
#   qa/run-emulators.sh -n 3 --install-apk
#
# -n: number of emulators to start (1–5, first N entries of AVD_NAMES). Default: 1.
#
# Each AVD gets a fixed port (5554, 5556, …) so serials are predictable:
#   Louys-QA   -> emulator-5554
#   Monica-QA  -> emulator-5556
#   …

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=../tool/qa_env.sh
source "${ROOT}/tool/qa_env.sh"
qa_export_android_sdk_paths
qa_require_command avdmanager
qa_require_command emulator
qa_require_command adb

NUM_EMULATORS=1
INSTALL_APK=false

usage() {
  echo "Usage: qa/run-emulators.sh [-n COUNT] [--install-apk]" >&2
  echo "  -n COUNT   Start the first COUNT AVDs (1–5). Default: 1." >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n)
      if [[ $# -lt 2 ]]; then
        echo "Error: -n requires a value (1–5)." >&2
        usage
        exit 1
      fi
      NUM_EMULATORS="$2"
      shift 2
      ;;
    --install-apk)
      INSTALL_APK=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "${NUM_EMULATORS}" =~ ^[1-5]$ ]]; then
  echo "Error: -n must be an integer from 1 to 5 (inclusive); got: ${NUM_EMULATORS}" >&2
  usage
  exit 1
fi

APK="${COMPARTARENTA_QA_APK_PATH}"
ALL_AVD_NAMES=("${COMPARTARENTA_QA_PERSONA_AVD_NAMES[@]}")
AVD_NAMES=("${ALL_AVD_NAMES[@]:0:${NUM_EMULATORS}}")
BASE_PORT=5554
EMULATOR_COMMON_ARGS=(-netdelay none -netspeed full -prop ro.setupwizard.mode=DISABLED)

avd_exists() {
  local name="$1"
  avdmanager list avd | grep -Fq "Name: ${name}"
}

# Return serial if this AVD is already running (device state).
running_serial_for_avd() {
  local avd_name="$1"
  local serial avd_on_device
  while IFS= read -r serial; do
    [[ -z "${serial}" ]] && continue
    avd_on_device="$(adb -s "${serial}" emu avd name 2>/dev/null | tr -d '\r' || true)"
    if [[ "${avd_on_device}" == "${avd_name}" ]]; then
      echo "${serial}"
      return 0
    fi
  done < <(adb devices | awk '/^emulator-[0-9]+\tdevice$/{print $1}')
  return 1
}

port_in_use() {
  local port="$1"
  adb devices | grep -q "^emulator-${port}[[:space:]]"
}

echo "=== Ensure AVDs exist (${NUM_EMULATORS} emulator(s)) ==="
for avd_name in "${AVD_NAMES[@]}"; do
  if avd_exists "${avd_name}"; then
    echo "  OK  ${avd_name}"
  else
    echo "  CREATE  ${avd_name}"
    # This line is to install an OS image WITHOUT Google apps (Compartarenta is NOT working)
    # COMPARTARENTA_QA_SYSTEM_IMAGE='system-images;android-34;default;x86_64'

    # This line is to install an OS image WITH Google apps
    COMPARTARENTA_QA_SYSTEM_IMAGE='system-images;android-34;google_apis;x86_64'
    COMPARTARENTA_QA_AVD_NAME="${avd_name}" "${ROOT}/tool/create_qa_avd.sh"
  fi
done

echo
echo "=== Start emulators ==="
declare -a AVD_SERIALS=()
declare -A AVD_TO_SERIAL=()

i=0
for avd_name in "${AVD_NAMES[@]}"; do
  port=$((BASE_PORT + i * 2))
  expected_serial="emulator-${port}"

  if serial="$(running_serial_for_avd "${avd_name}")"; then
    echo "  RUNNING  ${avd_name} -> ${serial}"
    AVD_TO_SERIAL["${avd_name}"]="${serial}"
    AVD_SERIALS+=("${serial}")
  else
    if port_in_use "${port}"; then
      echo "  WARN  port ${port} busy; ${avd_name} will get the next free adb serial" >&2
      echo "Starting ${avd_name} (auto port)..."
      nohup emulator -avd "${avd_name}" "${EMULATOR_COMMON_ARGS[@]}" >/dev/null 2>&1 &
      # Wait until a new emulator appears that matches this AVD name.
      serial=""
      attempts=0
      while [[ -z "${serial}" && "${attempts}" -lt 120 ]]; do
        if serial="$(running_serial_for_avd "${avd_name}")"; then
          break
        fi
        sleep 2
        attempts=$((attempts + 1))
      done
      if [[ -z "${serial}" ]]; then
        echo "Timed out waiting for ${avd_name} to register on adb." >&2
        exit 1
      fi
    else
      echo "  START  ${avd_name} -> ${expected_serial} (port ${port})"
      nohup emulator -avd "${avd_name}" -port "${port}" "${EMULATOR_COMMON_ARGS[@]}" >/dev/null 2>&1 &
      serial="${expected_serial}"
    fi
    AVD_TO_SERIAL["${avd_name}"]="${serial}"
    AVD_SERIALS+=("${serial}")
  fi
  i=$((i + 1))
done

echo
echo "=== Wait for boot ==="
for serial in "${AVD_SERIALS[@]}"; do
  echo "  boot  ${serial}"
  qa_wait_for_boot_completed "${serial}"
done

echo
echo "=== Serials (adb devices) ==="
adb devices

echo
echo "=== AVD -> serial ==="
for avd_name in "${AVD_NAMES[@]}"; do
  echo "  ${avd_name} -> ${AVD_TO_SERIAL[${avd_name}]}"
done

if [[ "${INSTALL_APK}" == true ]]; then
  echo
  echo "=== Install APK on each emulator ==="
  for serial in "${AVD_SERIALS[@]}"; do
    echo "  install  ${serial}"
    qa_install_qa_apk_on_serial "${serial}" "${APK}"
  done
fi

map_entries=()
for avd_name in "${AVD_NAMES[@]}"; do
  map_entries+=("${avd_name}=${AVD_TO_SERIAL[${avd_name}]}")
done
qa_write_avd_serials_map "${map_entries[@]}"
echo
echo "Wrote AVD serial map: ${COMPARTARENTA_QA_AVD_SERIALS_MAP}"

echo
echo "Run dev builds (one terminal per persona):"
for avd_name in "${AVD_NAMES[@]}"; do
  serial="${AVD_TO_SERIAL[${avd_name}]}"
  echo "  ./tool/melosw run run:dev -- -d ${serial}   # ${avd_name}"
done
