#!/usr/bin/env bash
# Single-emulator coordinator — housing payment reminder #10 (simulated delivery, no relay).
#
# Expects env from tool/run_housing_payment_reminder_scenario.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../qa_env.sh
source "${ROOT}/tool/qa_env.sh"

SERIAL="${COMPARTARENTA_PAYMENT_REMINDER_SERIAL:?missing emulator serial}"
ARTIFACT_ROOT="${COMPARTARENTA_MULTI_ARTIFACT_ROOT:?missing artifact root}"
TIMEZONE="${COMPARTARENTA_MULTI_TIMEZONE:-America/Toronto}"
ANCHOR_DATE="${COMPARTARENTA_PAYMENT_REMINDER_ANCHOR_DATE:?missing anchor date}"
NOTIFICATION_DATE="${COMPARTARENTA_PAYMENT_REMINDER_NOTIFICATION_DATE:?missing notification date}"
FLOW_LAUNCH="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_LAUNCH:?missing launch flow}"
FLOW_TAP="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP:?missing tap flow}"

MAESTRO_TIMEOUT="${COMPARTARENTA_QA_MAESTRO_TIMEOUT_SEC:-600}"

_run_maestro() {
  local label="$1"
  local flow="$2"
  local out
  out="$(qa_maestro_artifact_dir "${label}")"
  mkdir -p "${out}"
  echo "  maestro device=${SERIAL} flow=$(basename "${flow}") -> ${out}"
  if ! timeout "${MAESTRO_TIMEOUT}" maestro test --udid "${SERIAL}" "${flow}" --test-output-dir "${out}"; then
    echo "  maestro FAILED: ${label} ($(basename "${flow}"))" >&2
    return 1
  fi
}

_log_phase() {
  echo "==="
  echo "=== $1"
  echo "==="
}

echo "================================================================================"
echo "Housing payment reminder QA (#10 before-due, simulated) — serial ${SERIAL}"
echo "  Anchor (calendar): ${ANCHOR_DATE}"
echo "  Notification date: ${NOTIFICATION_DATE}"
echo "  No relay interaction — client display only."
echo "================================================================================"

_log_phase "Seed + simulate #10"
echo "  Set notification date; seed active plan + simulate #10 on cold start."
qa_set_android_date_on_serial "${SERIAL}" "${NOTIFICATION_DATE}" "${TIMEZONE}"
qa_clear_logcat_on_serial "${SERIAL}"
COMPARTARENTA_QA_GRANT_POST_NOTIFICATIONS=1 \
  qa_seed_scenario_on_serial "${SERIAL}" "housing_payment_reminder_simulate_before_due"
qa_prepare_for_maestro "${SERIAL}"
_run_maestro "launch" "${FLOW_LAUNCH}"

if ! qa_wait_for_logcat_on_serial "${SERIAL}" "housingPaymentReminder: simulated kind=before_due qa=#10" 30; then
  echo "  FAILED: simulated delivery logcat missing." >&2
  adb -s "${SERIAL}" logcat -d 2>/dev/null | grep -E 'housingPaymentReminder' | tail -20 >&2 || true
  exit 1
fi

_log_phase "Tap #10 in notification shade"
echo "  Opening notification shade (adb expand-notifications)..."
qa_open_notification_shade_on_serial "${SERIAL}"
sleep 1
_run_maestro "tap-notification" "${FLOW_TAP}"
qa_collapse_notification_shade_on_serial "${SERIAL}"

echo "================================================================================"
echo "PASS — housing payment reminder #10 (simulated before-due) displayed and tapped"
echo "Artifacts: ${ARTIFACT_ROOT}"
echo "================================================================================"
