#!/usr/bin/env bash
# Create (or verify) the Bojairu-QA Android Virtual Device.
#
# Installs the pinned system image when missing, then runs avdmanager.
# Idempotent: safe to re-run.
#
# Usage: ./tool/create_qa_avd.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command avdmanager
qa_require_command sdkmanager

AVD_NAME="${COMPARTARENTA_QA_AVD_NAME}"
SYSTEM_IMAGE="${COMPARTARENTA_QA_SYSTEM_IMAGE}"
DEVICE_PROFILE="${COMPARTARENTA_QA_DEVICE_PROFILE}"

if avdmanager list avd | grep -Fq "Name: ${AVD_NAME}"; then
  echo "AVD already exists: ${AVD_NAME}"
  avdmanager list avd | awk -v name="${AVD_NAME}" '
    $0 ~ ("Name: " name) { show=1 }
    show { print }
    show && $0 == "" { exit }
  '
  exit 0
fi

echo "Creating AVD ${AVD_NAME}"
echo "  system image : ${SYSTEM_IMAGE}"
echo "  device profile: ${DEVICE_PROFILE}"

if ! sdkmanager --list_installed 2>/dev/null | grep -Fq "${SYSTEM_IMAGE}"; then
  echo "Installing system image (one-time download; may take several minutes)..."
  # sdkmanager may close the pipe early (SIGPIPE / exit 141) — not a failure.
  set +o pipefail
  yes | sdkmanager --licenses >/dev/null 2>&1 || true
  yes | sdkmanager --install "${SYSTEM_IMAGE}"
  set -o pipefail
fi

echo "no" | avdmanager create avd \
  --name "${AVD_NAME}" \
  --package "${SYSTEM_IMAGE}" \
  --device "${DEVICE_PROFILE}" \
  --force

echo "AVD ${AVD_NAME} created."
avdmanager list avd | awk -v name="${AVD_NAME}" '
  $0 ~ ("Name: " name) { show=1 }
  show { print }
  show && $0 == "" { exit }
'
