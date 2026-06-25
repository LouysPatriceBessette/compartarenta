#!/usr/bin/env bash
# Push a fixed date/time onto the connected QA Android emulator.
#
# Usage:
#   ./tool/set_android_date.sh 2027-08-11T09:00:00
#   ./tool/set_android_date.sh 2027-08-11T09:00:00 America/Toronto
#
# Saves the previous auto-time settings to qa/.local/clock-restore.env so
# restore_android_date.sh can revert. Requires a running emulator (not a
# physical device).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <ISO-8601-local-datetime> [timezone-id]" >&2
  echo "Example: $0 2027-08-11T09:00:00 America/Toronto" >&2
  exit 1
fi

TARGET_ISO="$1"
TIMEZONE="${2:-${COMPARTARENTA_QA_DEFAULT_TIMEZONE}}"

qa_export_android_sdk_paths
qa_require_command adb

SERIAL="$(qa_require_emulator_target)"
ADB=(adb -s "${SERIAL}")

if ! date -d "${TARGET_ISO}" '+%Y-%m-%d %H:%M:%S' >/dev/null 2>&1; then
  echo "Could not parse datetime: ${TARGET_ISO}" >&2
  echo "Use an ISO-like value, e.g. 2027-08-11T09:00:00" >&2
  exit 1
fi

TARGET_WALL="$(date -d "${TARGET_ISO}" '+%Y-%m-%d %H:%M:%S')"
TARGET_ADB="$(date -d "${TARGET_ISO}" '+%m%d%H%M%Y.%S')"

qa_ensure_local_dir
if [[ ! -f "${COMPARTARENTA_QA_CLOCK_STATE}" ]]; then
  AUTO_TIME="$("${ADB[@]}" shell settings get global auto_time | tr -d '\r')"
  AUTO_TIME_ZONE="$("${ADB[@]}" shell settings get global auto_time_zone | tr -d '\r')"
  PREV_TIMEZONE="$("${ADB[@]}" shell getprop persist.sys.timezone | tr -d '\r')"
  cat >"${COMPARTARENTA_QA_CLOCK_STATE}" <<EOF
AUTO_TIME=${AUTO_TIME}
AUTO_TIME_ZONE=${AUTO_TIME_ZONE}
PREV_TIMEZONE=${PREV_TIMEZONE}
EOF
  echo "Saved clock restore snapshot to ${COMPARTARENTA_QA_CLOCK_STATE}"
fi

qa_wait_for_boot_completed "${SERIAL}"

"${ADB[@]}" root >/dev/null 2>&1 || true

"${ADB[@]}" shell settings put global auto_time 0
"${ADB[@]}" shell settings put global auto_time_zone 0
"${ADB[@]}" shell setprop persist.sys.timezone "${TIMEZONE}"

if ! "${ADB[@]}" shell date -s "${TARGET_WALL}" >/dev/null 2>&1; then
  "${ADB[@]}" shell date "${TARGET_ADB}"
fi

"${ADB[@]}" shell am broadcast -a android.intent.action.TIME_SET >/dev/null 2>&1 || true
"${ADB[@]}" shell am broadcast -a android.intent.action.TIMEZONE_CHANGED >/dev/null 2>&1 || true

# Manual clock jumps can destabilize System UI; allow broadcasts to settle.
sleep 2

CURRENT="$("${ADB[@]}" shell date | tr -d '\r')"
echo "Emulator ${SERIAL} clock set to ${TARGET_WALL} (${TIMEZONE})."
echo "Device reports: ${CURRENT}"
