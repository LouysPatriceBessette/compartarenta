#!/usr/bin/env bash
# Build a debug APK (dev flavor) for manual QA on the emulator.
#
# Usage: ./tool/build_qa_apk.sh
#
# Output: mobile/build/app/outputs/flutter-apk/app-dev-debug.apk

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="${ROOT}/mobile"

# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"
# shellcheck source=ensure_pub_get.sh
source "${ROOT}/tool/ensure_pub_get.sh"

ensure_workspace_pub_get "${ROOT}"

API_BASE_URL_VALUE="${API_BASE_URL:-${COMPARTARENTA_QA_API_BASE_URL}}"
# shellcheck source=../mobile/tool/entitlement_base_url_default.sh
source "${MOBILE}/tool/entitlement_base_url_default.sh"
ENTITLEMENT_BASE_URL_VALUE="$(entitlement_base_url_default "${API_BASE_URL_VALUE}")"

cd "${MOBILE}"
VERSION_FLAGS="$("./tool/compute_version.sh")"

echo "Building dev debug APK (API_BASE_URL=${API_BASE_URL_VALUE})"
# shellcheck disable=SC2086
./tool/flutterw build apk --debug --flavor dev \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  --dart-define="ENTITLEMENT_BASE_URL=${ENTITLEMENT_BASE_URL_VALUE}" \
  ${VERSION_FLAGS}

APK="${MOBILE}/build/app/outputs/flutter-apk/app-dev-debug.apk"
if [[ ! -f "${APK}" ]]; then
  echo "Expected APK missing: ${APK}" >&2
  exit 1
fi

ls -lah "${APK}"
echo "QA APK ready: ${APK}"
