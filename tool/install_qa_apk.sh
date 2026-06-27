#!/usr/bin/env bash
# Install the dev debug QA APK onto the running emulator.
#
# Usage:
#   ./tool/install_qa_apk.sh
#   ./tool/install_qa_apk.sh /path/to/custom.apk
#   COMPARTARENTA_QA_ADB_SERIAL=emulator-5554 ./tool/install_qa_apk.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command adb

APK="${1:-${COMPARTARENTA_QA_APK_PATH}}"

SERIAL="${COMPARTARENTA_QA_ADB_SERIAL:-}"
if [[ -z "${SERIAL}" ]]; then
  SERIAL="$(qa_adb_target_serial)" || {
    echo "No adb device in 'device' state. Start the emulator first." >&2
    exit 1
  }
fi

qa_install_qa_apk_on_serial "${SERIAL}" "${APK}"
echo "Install complete."
