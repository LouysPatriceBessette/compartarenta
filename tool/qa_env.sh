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
export COMPARTARENTA_QA_APK_PATH="${COMPARTARENTA_QA_APK_PATH:-${COMPARTARENTA_ROOT}/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk}"

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
