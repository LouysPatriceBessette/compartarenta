#!/usr/bin/env bash
# Install the dev debug QA APK onto the running emulator.
#
# Usage:
#   ./tool/install_qa_apk.sh
#   ./tool/install_qa_apk.sh /path/to/custom.apk

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command adb

APK="${1:-${COMPARTARENTA_QA_APK_PATH}}"
if [[ ! -f "${APK}" ]]; then
  echo "APK not found: ${APK}" >&2
  echo "Run ./tool/build_qa_apk.sh first." >&2
  exit 1
fi

SERIAL="$(qa_adb_target_serial)" || {
  echo "No adb device in 'device' state. Start the emulator first." >&2
  exit 1
}

if [[ "${SERIAL}" != emulator-* ]]; then
  echo "Refusing to install on a non-emulator device (${SERIAL})." >&2
  echo "Disconnect the physical device or stop it from claiming adb default." >&2
  exit 1
fi

qa_wait_for_boot_completed "${SERIAL}"

echo "Installing ${APK} on ${SERIAL} (${COMPARTARENTA_QA_APP_ID})"
adb -s "${SERIAL}" install -r "${APK}"
echo "Install complete."
