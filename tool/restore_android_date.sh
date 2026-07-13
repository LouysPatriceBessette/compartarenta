#!/usr/bin/env bash
# Restore automatic date/time on the QA emulator after set_android_date.sh.
#
# Usage: ./tool/restore_android_date.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command adb

SERIAL="$(qa_require_emulator_target)"
ADB=(adb -s "${SERIAL}")

qa_wait_for_boot_completed "${SERIAL}"
"${ADB[@]}" root >/dev/null 2>&1 || true

if [[ -f "${COMPARTARENTA_QA_CLOCK_STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${COMPARTARENTA_QA_CLOCK_STATE}"
  AUTO_TIME="${AUTO_TIME:-1}"
  AUTO_TIME_ZONE="${AUTO_TIME_ZONE:-1}"
  PREV_TIMEZONE="${PREV_TIMEZONE:-${COMPARTARENTA_QA_DEFAULT_TIMEZONE}}"
else
  AUTO_TIME=1
  AUTO_TIME_ZONE=1
  PREV_TIMEZONE="${COMPARTARENTA_QA_DEFAULT_TIMEZONE}"
fi

# Never leave the emulator parked on a frozen QA wall-clock. A prior run may have
# saved AUTO_TIME=0 into clock-restore.env; restoring that would keep Aug/J-date.
if [[ "${COMPARTARENTA_QA_KEEP_MANUAL_CLOCK:-0}" != "1" ]]; then
  if [[ "${AUTO_TIME}" == "0" || "${AUTO_TIME}" == "null" || -z "${AUTO_TIME}" ]]; then
    AUTO_TIME=1
  fi
  if [[ "${AUTO_TIME_ZONE}" == "0" || "${AUTO_TIME_ZONE}" == "null" || -z "${AUTO_TIME_ZONE}" ]]; then
    AUTO_TIME_ZONE=1
  fi
fi

"${ADB[@]}" shell settings put global auto_time "${AUTO_TIME}"
"${ADB[@]}" shell settings put global auto_time_zone "${AUTO_TIME_ZONE}"
"${ADB[@]}" shell setprop persist.sys.timezone "${PREV_TIMEZONE}"

# Immediate wall-clock nudge from the host (NTP may take a beat after auto_time=1).
if [[ "${COMPARTARENTA_QA_KEEP_MANUAL_CLOCK:-0}" != "1" ]]; then
  HOST_WALL="$(date '+%Y-%m-%d %H:%M:%S')"
  HOST_ADB="$(date '+%m%d%H%M%Y.%S')"
  if ! "${ADB[@]}" shell date -s "${HOST_WALL}" >/dev/null 2>&1; then
    "${ADB[@]}" shell date "${HOST_ADB}" >/dev/null 2>&1 || true
  fi
fi

"${ADB[@]}" shell am broadcast -a android.intent.action.TIME_SET >/dev/null 2>&1 || true
"${ADB[@]}" shell am broadcast -a android.intent.action.TIMEZONE_CHANGED >/dev/null 2>&1 || true

rm -f "${COMPARTARENTA_QA_CLOCK_STATE}"

CURRENT="$("${ADB[@]}" shell date | tr -d '\r')"
echo "Emulator ${SERIAL} clock restored (auto_time=${AUTO_TIME}, timezone=${PREV_TIMEZONE})."
echo "Device reports: ${CURRENT}"
