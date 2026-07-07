#!/usr/bin/env bash
# Shared constants and helpers for manual Android QA / E2E tooling.
# Source from repo-root scripts: source "$(dirname "$0")/qa_env.sh"

if [[ -z "${COMPARTARENTA_ROOT:-}" ]]; then
  _qa_env_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  COMPARTARENTA_ROOT="$(cd "${_qa_env_script_dir}/.." && pwd)"
fi

export COMPARTARENTA_ROOT

# --- Defaults (override via env before calling scripts) -----------------------

export COMPARTARENTA_QA_AVD_NAME="${COMPARTARENTA_QA_AVD_NAME:-Compartarenta-QA}"
export COMPARTARENTA_QA_APP_ID="${COMPARTARENTA_QA_APP_ID:-com.compartarenta.compartarenta.dev}"
export COMPARTARENTA_QA_SYSTEM_IMAGE="${COMPARTARENTA_QA_SYSTEM_IMAGE:-system-images;android-34;google_apis;x86_64}"
export COMPARTARENTA_QA_DEVICE_PROFILE="${COMPARTARENTA_QA_DEVICE_PROFILE:-pixel_7}"
export COMPARTARENTA_QA_API_BASE_URL="${COMPARTARENTA_QA_API_BASE_URL:-https://sync.incoherences.org}"
export COMPARTARENTA_QA_DEFAULT_TIMEZONE="${COMPARTARENTA_QA_DEFAULT_TIMEZONE:-America/Toronto}"

export COMPARTARENTA_QA_LOCAL_DIR="${COMPARTARENTA_ROOT}/qa/.local"
export COMPARTARENTA_QA_CLOCK_STATE="${COMPARTARENTA_QA_LOCAL_DIR}/clock-restore.env"
export COMPARTARENTA_QA_AVD_SERIALS_MAP="${COMPARTARENTA_QA_LOCAL_DIR}/avd-serials.map"
export COMPARTARENTA_QA_APK_PATH="${COMPARTARENTA_QA_APK_PATH:-${COMPARTARENTA_ROOT}/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk}"

# Persona AVD order must match qa/run-emulators.sh fixed ports (5554, 5556, …).
COMPARTARENTA_QA_PERSONA_AVD_NAMES=(
  "Louys-QA"
  "Monica-QA"
  "Roberr-QA"
  "Liuva-QA"
  "Leo-QA"
)

# --- Android SDK resolution -------------------------------------------------

qa_resolve_android_sdk_root() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}" ]]; then
    echo "${ANDROID_SDK_ROOT}"
    return 0
  fi
  if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}" ]]; then
    echo "${ANDROID_HOME}"
    return 0
  fi
  if [[ -d "${HOME}/Android/Sdk" ]]; then
    echo "${HOME}/Android/Sdk"
    return 0
  fi
  return 1
}

qa_export_android_sdk_paths() {
  local sdk_root
  sdk_root="$(qa_resolve_android_sdk_root)" || {
    echo "Android SDK not found. Set ANDROID_SDK_ROOT or install the SDK." >&2
    return 1
  }
  export ANDROID_SDK_ROOT="${sdk_root}"
  export ANDROID_HOME="${sdk_root}"
  export PATH="${sdk_root}/platform-tools:${sdk_root}/emulator:${sdk_root}/cmdline-tools/latest/bin:${PATH}"
}

qa_require_command() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Required command not found on PATH: ${name}" >&2
    return 1
  fi
}

qa_ensure_local_dir() {
  mkdir -p "${COMPARTARENTA_QA_LOCAL_DIR}"
}

qa_wait_for_boot_completed() {
  local serial="${1:-}"
  local adb_args=()
  if [[ -n "${serial}" ]]; then
    adb_args=(-s "${serial}")
  fi
  adb "${adb_args[@]}" wait-for-device
  local boot_completed=""
  local attempts=0
  while [[ "${boot_completed}" != "1" && "${attempts}" -lt 120 ]]; do
    boot_completed="$(adb "${adb_args[@]}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
    if [[ "${boot_completed}" == "1" ]]; then
      break
    fi
    sleep 2
    attempts=$((attempts + 1))
  done
  if [[ "${boot_completed}" != "1" ]]; then
    echo "Timed out waiting for emulator boot (sys.boot_completed)." >&2
    return 1
  fi
}

qa_wait_for_emulator_serial() {
  local serial=""
  local attempts=0
  while [[ -z "${serial}" && "${attempts}" -lt 120 ]]; do
    serial="$(adb devices | awk '/^emulator-[0-9]+\tdevice$/{print $1; exit}')"
    if [[ -n "${serial}" ]]; then
      echo "${serial}"
      return 0
    fi
    sleep 2
    attempts=$((attempts + 1))
  done
  echo "Timed out waiting for an emulator in 'device' state (adb devices)." >&2
  adb devices >&2 || true
  return 1
}

qa_use_emulator_adb_serial() {
  local serial
  serial="$(qa_wait_for_emulator_serial)"
  export ANDROID_SERIAL="${serial}"
  echo "${serial}"
}

qa_adb_target_serial() {
  # Prefer an emulator when several devices are connected.
  local serial
  serial="$(adb devices | awk '/^emulator-[0-9]+\tdevice$/{print $1; exit}')"
  if [[ -n "${serial}" ]]; then
    echo "${serial}"
    return 0
  fi
  serial="$(adb devices | awk '/\tdevice$/{print $1; exit}')"
  if [[ -n "${serial}" ]]; then
    echo "${serial}"
    return 0
  fi
  return 1
}

qa_apk_contains_libflutter_for_abi() {
  local apk="$1"
  local lib_abi="$2"
  unzip -Z1 "${apk}" "lib/${lib_abi}/libflutter.so" 2>/dev/null \
    | grep -Fxq "lib/${lib_abi}/libflutter.so"
}

# Install the QA debug APK on one emulator. Uninstalls first so a prior
# `flutter run` on another ABI cannot leave arm64 libflutter.so in app_lib/.
qa_install_qa_apk_on_serial() {
  local serial="$1"
  local apk="${2:-${COMPARTARENTA_QA_APK_PATH}}"

  if [[ "${serial}" != emulator-* ]]; then
    echo "Refusing to install QA APK on a non-emulator device (${serial})." >&2
    return 1
  fi
  if [[ ! -f "${apk}" ]]; then
    echo "APK not found: ${apk}" >&2
    echo "Build first: ./tool/melosw run qa:build-apk" >&2
    return 1
  fi

  qa_wait_for_boot_completed "${serial}"

  local lib_abi
  lib_abi="$(adb -s "${serial}" shell getprop ro.product.cpu.abi | tr -d '\r')"
  if [[ -z "${lib_abi}" ]]; then
    echo "Could not read ro.product.cpu.abi from ${serial}." >&2
    return 1
  fi
  if ! qa_apk_contains_libflutter_for_abi "${apk}" "${lib_abi}"; then
    echo "APK missing lib/${lib_abi}/libflutter.so required by ${serial}." >&2
    echo "Rebuild: ./tool/melosw run qa:build-apk" >&2
    echo "(QA APK targets android-x64 for x86_64 emulators.)" >&2
    return 1
  fi

  echo "Uninstalling prior ${COMPARTARENTA_QA_APP_ID} on ${serial}..."
  adb -s "${serial}" uninstall "${COMPARTARENTA_QA_APP_ID}" >/dev/null 2>&1 || true

  echo "Installing ${apk} on ${serial} (ABI ${lib_abi})..."
  adb -s "${serial}" install -r "${apk}"
}

qa_require_emulator_target() {
  local serial
  serial="$(qa_adb_target_serial)" || {
    echo "No adb device in 'device' state. Start the QA emulator first." >&2
    return 1
  }
  if [[ "${serial}" != emulator-* ]]; then
    echo "Refusing to change the system clock on a non-emulator device (${serial})." >&2
    return 1
  fi
  echo "${serial}"
}

# Recover from "System UI keeps stopping" on the QA emulator (manual clock jumps and
# repeated pm clear + cold start can destabilize com.android.systemui).
# Last resort only — do not call routinely before Maestro (can hang launchApp).
qa_recover_system_ui() {
  local serial="${1:-}"
  if [[ -n "${serial}" && "${serial}" != emulator-* ]]; then
    return 0
  fi
  local adb_args=()
  if [[ -n "${serial}" ]]; then
    adb_args=(-s "${serial}")
  fi
  adb "${adb_args[@]}" root >/dev/null 2>&1 || true
  adb "${adb_args[@]}" shell input keyevent KEYCODE_BACK >/dev/null 2>&1 || true
  sleep 1
  adb "${adb_args[@]}" shell killall com.android.systemui >/dev/null 2>&1 || true
  qa_wait_for_boot_completed "${serial}"
  sleep 2
}

# Light prep after seed / before Maestro — no System UI restart.
qa_prepare_for_maestro() {
  local serial="${1:-}"
  local adb_args=()
  if [[ -n "${serial}" ]]; then
    adb_args=(-s "${serial}")
  fi
  adb "${adb_args[@]}" shell am force-stop "${COMPARTARENTA_QA_APP_ID}" >/dev/null 2>&1 || true
  adb "${adb_args[@]}" shell input keyevent KEYCODE_BACK >/dev/null 2>&1 || true
  sleep 1
}

# --- Multi-device QA helpers --------------------------------------------------

qa_write_avd_serials_map() {
  # Usage: qa_write_avd_serials_map "Louys-QA=emulator-5554" "Monica-QA=emulator-5556"
  qa_ensure_local_dir
  : >"${COMPARTARENTA_QA_AVD_SERIALS_MAP}"
  local entry avd serial
  for entry in "$@"; do
    avd="${entry%%=*}"
    serial="${entry#*=}"
    if [[ -z "${avd}" || -z "${serial}" || "${avd}" == "${serial}" ]]; then
      echo "Invalid AVD serial map entry: ${entry}" >&2
      return 1
    fi
    printf '%s=%s\n' "${avd}" "${serial}" >>"${COMPARTARENTA_QA_AVD_SERIALS_MAP}"
  done
}

qa_serial_from_avd_map() {
  local avd_name="$1"
  local line name serial
  if [[ ! -f "${COMPARTARENTA_QA_AVD_SERIALS_MAP}" ]]; then
    return 1
  fi
  while IFS='=' read -r name serial; do
    [[ -z "${name}" ]] && continue
    if [[ "${name}" == "${avd_name}" && -n "${serial}" ]]; then
      if adb devices | awk -v s="${serial}" '$1 == s && $2 == "device" { found=1 } END { exit !found }'; then
        echo "${serial}"
        return 0
      fi
    fi
  done <"${COMPARTARENTA_QA_AVD_SERIALS_MAP}"
  return 1
}

qa_serial_for_avd_by_fixed_port() {
  local avd_name="$1"
  local base_port=5554
  local i=0
  local name expected_serial
  for name in "${COMPARTARENTA_QA_PERSONA_AVD_NAMES[@]}"; do
    if [[ "${name}" == "${avd_name}" ]]; then
      expected_serial="emulator-$((base_port + i * 2))"
      if adb devices | awk -v s="${expected_serial}" '$1 == s && $2 == "device" { found=1 } END { exit !found }'; then
        echo "${expected_serial}"
        return 0
      fi
      return 1
    fi
    i=$((i + 1))
  done
  return 1
}

qa_serial_for_avd() {
  local avd_name="$1"
  local serial avd_on_device

  if serial="$(qa_serial_from_avd_map "${avd_name}")"; then
    echo "${serial}"
    return 0
  fi

  while IFS= read -r serial; do
    [[ -z "${serial}" ]] && continue
    avd_on_device="$(adb -s "${serial}" emu avd name 2>/dev/null | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)"
    if [[ -n "${avd_on_device}" && "${avd_on_device}" == "${avd_name}" ]]; then
      echo "${serial}"
      return 0
    fi
  done < <(adb devices | awk '/^emulator-[0-9]+\tdevice$/{print $1}')

  if serial="$(qa_serial_for_avd_by_fixed_port "${avd_name}")"; then
    echo "${serial}"
    return 0
  fi

  return 1
}

qa_pull_handshake_invitation_code() {
  local serial="$1"
  adb -s "${serial}" shell \
    "run-as ${COMPARTARENTA_QA_APP_ID} cat app_flutter/compartarenta_qa_handshake_code.txt" \
    2>/dev/null | tr -d '\r'
}

qa_clear_logcat_on_serial() {
  local serial="$1"
  adb -s "${serial}" logcat -c >/dev/null 2>&1 || true
}

qa_logcat_matches_on_serial() {
  local serial="$1"
  local pattern="$2"
  adb -s "${serial}" logcat -d 2>/dev/null | grep -Fq "${pattern}"
}

qa_wait_for_logcat_on_serial() {
  local serial="$1"
  local pattern="$2"
  local timeout_sec="${3:-120}"
  local attempt
  for attempt in $(seq 1 "${timeout_sec}"); do
    if qa_logcat_matches_on_serial "${serial}" "${pattern}"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

qa_maestro_test_on_serial() {
  local serial="$1"
  local flow_path="$2"
  local artifact_dir="$3"
  shift 3
  mkdir -p "${artifact_dir}"
  maestro test --udid "${serial}" "${flow_path}" --test-output-dir "${artifact_dir}" "$@"
}

# Maestro --test-output-dir: avoid doubling COMPARTARENTA_MULTI_ARTIFACT_ROOT when the
# label is already an absolute path under that root (e.g. attempt-002/... passed as
# ${ARTIFACT_ROOT}/attempt-002/...).
qa_maestro_artifact_dir() {
  local label="$1"
  local root="${COMPARTARENTA_MULTI_ARTIFACT_ROOT:-}"
  if [[ -z "${root}" ]]; then
    echo "${label}"
    return 0
  fi
  if [[ "${label}" == "${root}/"* || "${label}" == "${root}" ]]; then
    echo "${label}"
  elif [[ "${label}" == /* ]]; then
    echo "${label}"
  else
    echo "${root}/${label}"
  fi
}

qa_seed_scenario_on_serial() {
  local serial="$1"
  local scenario_id="$2"
  ANDROID_SERIAL="${serial}" "${COMPARTARENTA_ROOT}/tool/seed_qa_scenario.sh" "${scenario_id}"
}

qa_set_android_date_on_serial() {
  local serial="$1"
  local device_date="$2"
  local timezone="$3"
  ANDROID_SERIAL="${serial}" "${COMPARTARENTA_ROOT}/tool/set_android_date.sh" "${device_date}" "${timezone}"
}
