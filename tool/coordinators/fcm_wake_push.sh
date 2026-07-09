#!/usr/bin/env bash
# FCM wake manual QA — seed → kill recipient process → proposer submit only.
#
# Expects env from tool/run_fcm_wake_push_scenario.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../qa_env.sh
source "${ROOT}/tool/qa_env.sh"

PROPOSER_SERIAL="${COMPARTARENTA_ROLE_PROPOSER_SERIAL:?missing proposer serial}"
RECIPIENT_SERIAL="${COMPARTARENTA_ROLE_RECIPIENT_SERIAL:?missing recipient serial}"
PROPOSER_SEND_FLOW="${COMPARTARENTA_ROLE_PROPOSER_FLOW:?missing proposer flow}"
ARTIFACT_ROOT="${COMPARTARENTA_MULTI_ARTIFACT_ROOT:?missing artifact root}"
SCENARIO_ID="${COMPARTARENTA_MULTI_SCENARIO_ID:-fcm_wake_push}"
POST_SEND_WAIT_SEC="${COMPARTARENTA_FCM_WAKE_POST_SEND_WAIT_SEC:-45}"

MAESTRO_TIMEOUT="${COMPARTARENTA_QA_MAESTRO_TIMEOUT_SEC:-600}"

_run_maestro() {
  local label="$1"
  local serial="$2"
  local flow="$3"
  shift 3
  local out
  out="$(qa_maestro_artifact_dir "${label}")"
  mkdir -p "${out}"
  echo "  maestro [${serial}] ${flow} -> ${out}"
  timeout "${MAESTRO_TIMEOUT}" maestro test --udid "${serial}" "${flow}" --test-output-dir "${out}" "$@"
}

echo "================================================================================"
echo "FCM wake manual scenario (${SCENARIO_ID})"
echo "  Proposer (emulator): ${PROPOSER_SERIAL}"
echo "  Recipient (physical): ${RECIPIENT_SERIAL}"
echo "  Artifacts: ${ARTIFACT_ROOT}"
echo "================================================================================"

mkdir -p "${ARTIFACT_ROOT}"

echo ""
echo "== Close recipient app (kill process, not force-stop) =="
echo "  Using am kill so FCM can still wake the app (force-stop blocks delivery on Android)."
adb -s "${RECIPIENT_SERIAL}" shell am kill "${COMPARTARENTA_QA_APP_ID}" >/dev/null 2>&1 || true
echo "  App process ended on ${RECIPIENT_SERIAL}. Keep the phone on the home screen."

echo ""
echo "== Proposer submits housing plan (emulator) =="
_run_maestro "proposer-submit-plan" "${PROPOSER_SERIAL}" "${PROPOSER_SEND_FLOW}"

echo ""
echo "================================================================================"
echo "MANUAL CHECK (required)"
echo "  On ${RECIPIENT_SERIAL}: watch for an Android notification within"
echo "  ~${POST_SEND_WAIT_SEC}s WITHOUT opening the app."
echo ""
echo "  Relay (VPS): no push.wake.send_failed after envelope.accepted:"
echo "  compstack logs --tail 30 relay | grep -iE 'push|wake|envelope.accepted|routing_push_register'"
echo "================================================================================"
echo ""
echo "Waiting ${POST_SEND_WAIT_SEC}s for manual observation..."
sleep "${POST_SEND_WAIT_SEC}"

echo "Coordinator finished. Notification presence is operator-verified only."
