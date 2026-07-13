#!/usr/bin/env bash
# Single-emulator coordinator — housing payment reminders #10/#11 (simulated, no relay).
#
# Seed once → phase per fire (J−4, J−2, overdue). Journal rows persist across phases.
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
DUE_MS="${COMPARTARENTA_PAYMENT_REMINDER_DUE_MS:?missing due ms}"
FIRE_J4="${COMPARTARENTA_PAYMENT_REMINDER_FIRE_J4:?missing J-4 fire}"
FIRE_J2="${COMPARTARENTA_PAYMENT_REMINDER_FIRE_J2:?missing J-2 fire}"
FIRE_OVERDUE="${COMPARTARENTA_PAYMENT_REMINDER_FIRE_OVERDUE:?missing overdue fire}"
FLOW_LAUNCH="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_LAUNCH:?missing launch flow}"
FLOW_TAP_J4="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_J4:?missing J-4 tap flow}"
FLOW_TAP_J2="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_J2:?missing J-2 tap flow}"
FLOW_TAP_OVERDUE="${COMPARTARENTA_PAYMENT_REMINDER_FLOW_TAP_OVERDUE:?missing overdue tap flow}"

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

_run_notification_phase() {
  local phase_label="$1"
  local kind="$2"
  local fire_iso="$3"
  local logcat_needle="$4"
  local tap_flow="$5"

  _log_phase "${phase_label}"
  echo "  Emulator date -> ${fire_iso}; schedule ${kind} (due_ms=${DUE_MS}); no pm clear."
  qa_set_android_date_on_serial "${SERIAL}" "${fire_iso}" "${TIMEZONE}"
  qa_schedule_payment_reminder_post_action_on_serial "${SERIAL}" "${kind}" "${DUE_MS}"
  qa_clear_logcat_on_serial "${SERIAL}"
  qa_prepare_for_maestro "${SERIAL}"
  _run_maestro "${phase_label}-launch" "${FLOW_LAUNCH}" || return 1

  if ! qa_wait_for_logcat_on_serial "${SERIAL}" "${logcat_needle}" 30; then
    echo "  FAILED: simulated delivery logcat missing (${logcat_needle})." >&2
    adb -s "${SERIAL}" logcat -d 2>/dev/null | grep -E 'housingPaymentReminder' | tail -20 >&2 || true
    return 1
  fi

  echo "  Opening notification shade (adb expand-notifications)..."
  qa_open_notification_shade_on_serial "${SERIAL}"
  sleep 1
  _run_maestro "${phase_label}-tap" "${tap_flow}" || return 1
  qa_collapse_notification_shade_on_serial "${SERIAL}"
}

echo "================================================================================"
echo "Housing payment reminder QA (#10×2 + #11 overdue, simulated) — serial ${SERIAL}"
echo "  Anchor (calendar): ${ANCHOR_DATE}"
echo "  Due ms (UTC):      ${DUE_MS}"
echo "  Fires: J-4=${FIRE_J4} | J-2=${FIRE_J2} | overdue=${FIRE_OVERDUE}"
echo "  No relay — client display only; journal persists across phases."
echo "================================================================================"

_log_phase "Seed once (active plan)"
qa_set_android_date_on_serial "${SERIAL}" "${FIRE_J4}" "${TIMEZONE}"
COMPARTARENTA_QA_GRANT_POST_NOTIFICATIONS=1 \
  qa_seed_scenario_on_serial "${SERIAL}" "housing_payment_reminder_simulate_before_due"

_run_notification_phase \
  "phase1-j4-before-due" \
  "before_due" \
  "${FIRE_J4}" \
  "housingPaymentReminder: simulated kind=before_due qa=#10" \
  "${FLOW_TAP_J4}"

_run_notification_phase \
  "phase2-j2-before-due" \
  "before_due" \
  "${FIRE_J2}" \
  "housingPaymentReminder: simulated kind=before_due qa=#10" \
  "${FLOW_TAP_J2}"

_run_notification_phase \
  "phase3-overdue" \
  "overdue" \
  "${FIRE_OVERDUE}" \
  "housingPaymentReminder: simulated kind=overdue qa=#11" \
  "${FLOW_TAP_OVERDUE}"

echo "================================================================================"
echo "PASS — #10 J−4, #10 J−2, #11 overdue simulated; journal persisted across phases"
echo "Artifacts: ${ARTIFACT_ROOT}"
echo "================================================================================"
