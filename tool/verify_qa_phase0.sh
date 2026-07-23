#!/usr/bin/env bash
# Verify Phase 0 QA prerequisites (local, manual — no CI).
#
# Usage: ./tool/verify_qa_phase0.sh
#
# Exit 0 when all checks pass; non-zero otherwise.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

failures=0

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "[ok]   ${label}"
  else
    echo "[FAIL] ${label}" >&2
    failures=$((failures + 1))
  fi
}

echo "Bojairu QA — phase 0 verification"
echo "  AVD name : ${COMPARTARENTA_QA_AVD_NAME}"
echo "  App id   : ${COMPARTARENTA_QA_APP_ID}"
echo

check "Android SDK resolvable" qa_resolve_android_sdk_root
qa_export_android_sdk_paths >/dev/null 2>&1 || true

check "adb on PATH" command -v adb
check "avdmanager on PATH" command -v avdmanager
check "sdkmanager on PATH" command -v sdkmanager
check "emulator on PATH" command -v emulator

check "AVD ${COMPARTARENTA_QA_AVD_NAME} exists" \
  bash -c "avdmanager list avd | grep -Fq 'Name: ${COMPARTARENTA_QA_AVD_NAME}'"

check "system image installed (${COMPARTARENTA_QA_SYSTEM_IMAGE})" \
  bash -c "sdkmanager --list_installed 2>/dev/null | grep -Fq '${COMPARTARENTA_QA_SYSTEM_IMAGE}'"

if command -v maestro >/dev/null 2>&1; then
  check "maestro on PATH" maestro --version
elif [[ -x "${HOME}/.maestro/bin/maestro" ]]; then
  check "maestro in ~/.maestro/bin" "${HOME}/.maestro/bin/maestro" --version
else
  echo "[FAIL] Maestro CLI not found (run ./tool/install_maestro.sh)" >&2
  failures=$((failures + 1))
fi

if [[ -f "${COMPARTARENTA_QA_APK_PATH}" ]]; then
  check "QA debug APK built" test -f "${COMPARTARENTA_QA_APK_PATH}"
else
  echo "[warn] QA debug APK not built yet (run ./tool/build_qa_apk.sh)" >&2
fi

if adb devices | awk '/^emulator-[0-9]+\tdevice$/{found=1} END{exit !found}'; then
  SERIAL="$(qa_adb_target_serial)"
  check "emulator boot completed (${SERIAL})" qa_wait_for_boot_completed "${SERIAL}"
  if adb -s "${SERIAL}" shell pm path "${COMPARTARENTA_QA_APP_ID}" 2>/dev/null | grep -q package; then
    echo "[ok]   dev APK installed on emulator"
  else
    echo "[warn] dev APK not installed on running emulator (run ./tool/install_qa_apk.sh)" >&2
  fi
else
  echo "[info] no running emulator (optional for phase 0; start with ./tool/start_qa_emulator.sh)"
fi

echo
if [[ "${failures}" -eq 0 ]]; then
  echo "Phase 0 prerequisites: OK"
  exit 0
fi

echo "Phase 0 prerequisites: ${failures} check(s) failed" >&2
exit 1
