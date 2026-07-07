#!/usr/bin/env bash
# Coordinator for housing-proposal multi-device QA (happy path + bug 1.22 probe).
#
# Expects env from tool/run_multi_device_scenario.sh:
#   COMPARTARENTA_ROLE_PROPOSER_SERIAL, COMPARTARENTA_ROLE_RECIPIENT_SERIAL, flows, etc.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../qa_env.sh
source "${ROOT}/tool/qa_env.sh"

PROPOSER_SERIAL="${COMPARTARENTA_ROLE_PROPOSER_SERIAL:?missing proposer serial}"
RECIPIENT_SERIAL="${COMPARTARENTA_ROLE_RECIPIENT_SERIAL:?missing recipient serial}"
PROPOSER_SEND_FLOW="${COMPARTARENTA_ROLE_PROPOSER_FLOW:?missing proposer flow}"
RECIPIENT_FLOW="${COMPARTARENTA_ROLE_RECIPIENT_FLOW:?missing recipient flow}"
ARTIFACT_ROOT="${COMPARTARENTA_MULTI_ARTIFACT_ROOT:?missing artifact root}"
MODE="${COMPARTARENTA_MULTI_MODE:-happy_path}"
ATTEMPTS="${COMPARTARENTA_MULTI_ATTEMPTS:-1}"
SCENARIO_ID="${COMPARTARENTA_MULTI_SCENARIO_ID:-housing_proposal}"

FLOWS_DIR="${ROOT}/qa/flows"
MAESTRO_TIMEOUT="${COMPARTARENTA_QA_MAESTRO_TIMEOUT_SEC:-600}"
HANDSHAKE_INVITER_GENERATE="${FLOWS_DIR}/contact_handshake_inviter_generate.yaml"
HANDSHAKE_INVITEE_REDEEM="${FLOWS_DIR}/contact_handshake_invitee_redeem_wait_connected.yaml"
HANDSHAKE_INVITER_STANDBY="${FLOWS_DIR}/contact_handshake_inviter_standby.yaml"

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

_run_maestro_probe() {
  local label="$1"
  local serial="$2"
  local flow="$3"
  local out
  out="$(qa_maestro_artifact_dir "${label}")"
  local log="${out}/probe.log"
  mkdir -p "${out}"
  echo "  probe [${serial}] ${flow} -> ${out}"
  if timeout "${MAESTRO_TIMEOUT}" maestro test --udid "${serial}" "${flow}" --test-output-dir "${out}" \
    >"${log}" 2>&1; then
    echo "  probe ${label}: symptom present"
    return 0
  fi
  if grep -qE 'not connected|Connection refused|device offline' "${log}" 2>/dev/null; then
    echo "  probe ${label}: INFRA (device/maestro) — not a clean negative" >&2
    tail -15 "${log}" >&2 || true
    return 2
  fi
  echo "  probe ${label}: symptom absent"
  tail -8 "${log}" >&2 || true
  return 1
}

_assert_bug_122_no_duplicate_monica() {
  local attempt_dir="$1"
  local base
  base="$(_attempt_rel "${attempt_dir}" "contacts")"
  _run_maestro "${base}/assert-no-duplicate" "${RECIPIENT_SERIAL}" \
    "${FLOWS_DIR}/contact_handshake_invitee_assert_no_duplicate_monica.yaml"
}

_check_bug_122_duplicate_monica() {
  local attempt_dir="$1"

  _detect_bug_122_duplicate_monica "${attempt_dir}"
  local probe_rc=$?
  if [[ "${probe_rc}" -eq 0 ]]; then
    return 0
  fi
  if [[ "${probe_rc}" -eq 2 ]]; then
    return 2
  fi

  set +e
  _assert_bug_122_no_duplicate_monica "${attempt_dir}"
  local no_dup_rc=$?
  set -e
  if [[ "${no_dup_rc}" -ne 0 ]]; then
    echo "  duplicate Monica: positive via failed assert_no_duplicate (second row present)"
    return 0
  fi
  return 1
}

_wait_for_handshake_code() {
  local serial="$1"
  local code=""
  local attempt
  for attempt in $(seq 1 30); do
    code="$(qa_pull_handshake_invitation_code "${serial}")"
    if [[ -n "${code}" ]]; then
      echo "${code}"
      return 0
    fi
    sleep 1
  done
  echo "Timed out waiting for exported invitation code on ${serial}" >&2
  return 1
}

_prepare_fresh_pair() {
  qa_seed_scenario_on_serial "${PROPOSER_SERIAL}" "${COMPARTARENTA_ROLE_PROPOSER_SEED}"
  qa_seed_scenario_on_serial "${RECIPIENT_SERIAL}" "${COMPARTARENTA_ROLE_RECIPIENT_SEED}"
  qa_prepare_for_maestro "${PROPOSER_SERIAL}"
  qa_prepare_for_maestro "${RECIPIENT_SERIAL}"
}

_attempt_root_dir() {
  local path="$1"
  if [[ "$(basename "${path}")" == "delivery" ]]; then
    path="$(dirname "${path}")"
  fi
  basename "${path}"
}

_delivery_rel() {
  echo "$(_attempt_root_dir "$1")/delivery"
}

_attempt_rel() {
  local attempt_dir="$1"
  local suffix="$2"
  echo "$(_attempt_root_dir "${attempt_dir}")/${suffix}"
}

_connect_handshake() {
  local label_prefix="$1"
  local invite_code

  _run_maestro "${label_prefix}/inviter-generate" "${PROPOSER_SERIAL}" \
    "${HANDSHAKE_INVITER_GENERATE}"

  invite_code="$(_wait_for_handshake_code "${PROPOSER_SERIAL}")"
  echo "  invitation code: ${invite_code}"

  (
    _run_maestro "${label_prefix}/inviter-standby" "${PROPOSER_SERIAL}" \
      "${HANDSHAKE_INVITER_STANDBY}"
  ) &
  local inviter_pid=$!
  sleep 1

  _run_maestro "${label_prefix}/invitee-redeem" "${RECIPIENT_SERIAL}" \
    "${HANDSHAKE_INVITEE_REDEEM}" -e "INVITE_CODE=${invite_code}"

  wait "${inviter_pid}"
  # Standby + redeem flows already assert Louys / Monica connected rows.
}

_proposer_delivered_proposal() {
  qa_logcat_matches_on_serial "${PROPOSER_SERIAL}" "housing_proposal delivered"
}

_recipient_imported_proposal() {
  qa_logcat_matches_on_serial "${RECIPIENT_SERIAL}" "housing_proposal imported"
}

_run_proposal_send_only() {
  local attempt_dir="$1"
  local base
  base="$(_delivery_rel "${attempt_dir}")"

  qa_clear_logcat_on_serial "${PROPOSER_SERIAL}"
  qa_clear_logcat_on_serial "${RECIPIENT_SERIAL}"

  echo "  phase 1/2: proposer completes plan wizard and sends proposal"
  _run_maestro "${base}/proposer-send" "${PROPOSER_SERIAL}" "${PROPOSER_SEND_FLOW}"
  if ! qa_wait_for_logcat_on_serial "${PROPOSER_SERIAL}" "housing_proposal delivered" 90; then
    echo "  proposer send: timed out waiting for logcat housing_proposal delivered" >&2
    adb -s "${PROPOSER_SERIAL}" logcat -d 2>/dev/null | grep -E 'housing_proposal' | tail -20 >&2 || true
    return 1
  fi
  echo "  proposer send: relay delivered (logcat)"
}

_run_proposal_recipient_accept_and_hub() {
  local attempt_dir="$1"
  local base
  base="$(_delivery_rel "${attempt_dir}")"

  echo "  phase 2/3: recipient opens housing, accepts proposal (2-participant plan)"
  _run_maestro "${base}/recipient-accept" "${RECIPIENT_SERIAL}" "${RECIPIENT_FLOW}"
  if ! qa_wait_for_logcat_on_serial "${RECIPIENT_SERIAL}" "housing_proposal_response posted" 120; then
    echo "  recipient accept: timed out waiting for logcat housing_proposal_response posted" >&2
    adb -s "${RECIPIENT_SERIAL}" logcat -d 2>/dev/null | grep -E 'housing_proposal_response' | tail -20 >&2 || true
    return 1
  fi
  echo "  recipient accept: response posted (logcat)"
}

_run_proposal_proposer_active_hub() {
  local attempt_dir="$1"
  local base
  base="$(_delivery_rel "${attempt_dir}")"

  echo "  phase 3/3: proposer lands on active agreement hub (not invite status chips)"
  _run_maestro "${base}/proposer-active-hub" "${PROPOSER_SERIAL}" \
    "${FLOWS_DIR}/housing_proposal_assert_active_hub.yaml"
}

_run_proposal_happy_path_once() {
  local attempt_dir="$1"
  _run_proposal_send_only "${attempt_dir}" || return 1
  _run_proposal_recipient_accept_and_hub "${attempt_dir}" || return 1
  _run_proposal_proposer_active_hub "${attempt_dir}"
}

_detect_bug_122_duplicate_monica() {
  local attempt_dir="$1"
  local base
  base="$(_attempt_rel "${attempt_dir}" "contacts")"

  _run_maestro_probe "${base}/probe-duplicate-monica" "${RECIPIENT_SERIAL}" \
    "${FLOWS_DIR}/contact_handshake_invitee_probe_duplicate_monica.yaml"
}

_detect_bug_122_missing_delivery() {
  local attempt_dir="$1"
  local base
  base="$(_delivery_rel "${attempt_dir}")"
  local missing_ui=0
  local proposer_delivered=0

  if _run_maestro_probe "${base}/probe-recipient-missing" "${RECIPIENT_SERIAL}" \
    "${FLOWS_DIR}/housing_proposal_recipient_probe_missing.yaml"; then
    missing_ui=1
  fi

  if _proposer_delivered_proposal; then
    proposer_delivered=1
  fi

  if [[ "${missing_ui}" -eq 1 && "${proposer_delivered}" -eq 1 ]]; then
    return 0
  fi

  if _recipient_imported_proposal; then
    echo "  logcat shows housing_proposal imported — not bug 1.22"
    return 1
  fi

  return 1
}

_run_proposal_recipient_received_only() {
  local attempt_dir="$1"
  local base
  base="$(_delivery_rel "${attempt_dir}")"

  echo "  phase 2/2: recipient opens housing and asserts proposal received"
  _run_maestro "${base}/recipient-assert" "${RECIPIENT_SERIAL}" \
    "${FLOWS_DIR}/housing_proposal_recipient_assert_proposal_received.yaml"
}

_run_happy_path_once() {
  local attempt_dir="$1"
  mkdir -p "${attempt_dir}"

  _prepare_fresh_pair
  _connect_handshake "$(_attempt_rel "${attempt_dir}" "handshake")"
  _run_proposal_happy_path_once "${attempt_dir}"
}

_run_bug_122_probe_once() {
  local attempt_dir="$1"
  local repro_reason=""
  mkdir -p "${attempt_dir}"

  _prepare_fresh_pair
  _connect_handshake "$(_attempt_rel "${attempt_dir}" "handshake-initial")"

  echo "  identity drift: re-seed proposer only (recipient keeps prior contact rows)"
  qa_seed_scenario_on_serial "${PROPOSER_SERIAL}" "${COMPARTARENTA_ROLE_PROPOSER_SEED}"
  qa_prepare_for_maestro "${PROPOSER_SERIAL}"

  _connect_handshake "$(_attempt_rel "${attempt_dir}" "handshake-after-drift")"

  echo "  post-drift: probe for duplicate connected Monica-QA (must be 2 rows, not 1)"
  set +e
  _check_bug_122_duplicate_monica "${attempt_dir}"
  local dup_rc=$?
  set -e
  if [[ "${dup_rc}" -eq 2 ]]; then
    return 3
  fi
  if [[ "${dup_rc}" -eq 0 ]]; then
    repro_reason="duplicate_connected_monica"
    echo "  BUG 1.22 symptom: duplicate Monica-QA on Louys — finishing this attempt (send + recipient), then stop"
  fi

  if ! _run_proposal_send_only "${attempt_dir}"; then
    if [[ -n "${repro_reason}" ]]; then
      echo "BUG 1.22 REPRODUCED: ${repro_reason} (send failed; partial artifacts in ${attempt_dir})"
      return 2
    fi
    return 3
  fi

  set +e
  _run_proposal_recipient_received_only "${attempt_dir}"
  local recipient_rc=$?
  set -e

  if [[ -n "${repro_reason}" ]]; then
    echo "BUG 1.22 REPRODUCED: ${repro_reason} (attempt ${attempt_dir##*/} completed)"
    return 2
  fi

  if [[ "${recipient_rc}" -eq 0 ]]; then
    return 0
  fi

  set +e
  _check_bug_122_duplicate_monica "${attempt_dir}"
  dup_rc=$?
  set -e
  if [[ "${dup_rc}" -eq 0 ]]; then
    echo "BUG 1.22 REPRODUCED: duplicate connected Monica-QA (attempt ${attempt_dir##*/} completed)"
    return 2
  fi

  if _detect_bug_122_missing_delivery "${attempt_dir}"; then
    echo "BUG 1.22 REPRODUCED: proposer delivered, recipient missing proposal UI (attempt completed)"
    return 2
  fi

  return 3
}

case "${MODE}" in
  happy_path)
    echo "=== Housing proposal happy path (Android + Android) ==="
    _run_happy_path_once "${ARTIFACT_ROOT}/run-001"
    ;;
  bug_122_probe)
    echo "=== Housing proposal bug 1.22 probe (${ATTEMPTS} attempts) ==="
    echo "Each attempt: drift + reconnect, then assert TWO Monica rows on Louys (index 1)."
    echo "Reproduced: duplicate Monica and/or missing proposal — finish current attempt, skip rest."
    echo "Clean: single Monica row + proposal visible (no accept/hub)."
    reproduced=0
    clean=0
    infra_fail=0
    attempt=1
    while [[ "${attempt}" -le "${ATTEMPTS}" ]]; do
      echo "--- Attempt ${attempt}/${ATTEMPTS} ---"
      attempt_dir="${ARTIFACT_ROOT}/attempt-$(printf '%03d' "${attempt}")"
      set +e
      _run_bug_122_probe_once "${attempt_dir}"
      rc=$?
      set -e
      case "${rc}" in
        0)
          clean=$((clean + 1))
          echo "Attempt ${attempt}: proposal delivered after drift (not bug 1.22)"
          ;;
        2)
          reproduced=1
          echo "Attempt ${attempt}: BUG 1.22 reproduced — no further attempts"
          break
          ;;
        *)
          infra_fail=$((infra_fail + 1))
          echo "Attempt ${attempt}: inconclusive (exit ${rc}) — excluded from repro count"
          ;;
      esac
      attempt=$((attempt + 1))
    done

    RESULT_FILE="${ARTIFACT_ROOT}/bug_122_result.txt"
    if [[ "${reproduced}" -eq 1 ]]; then
      {
        echo "verdict=REPRODUCED"
        echo "scenario=${SCENARIO_ID}"
        echo "attempts_run=${attempt}"
        echo "clean=${clean}"
        echo "infra_fail=${infra_fail}"
        echo "note=Stopped after first repro; attempt completed through delivery phases when possible"
      } >"${RESULT_FILE}"
      echo "Bug 1.22 REPRODUCED — see ${RESULT_FILE}"
      exit 2
    fi

    {
      echo "verdict=COULD_NOT_REPRODUCE"
      echo "scenario=${SCENARIO_ID}"
      echo "attempts_requested=${ATTEMPTS}"
      echo "clean=${clean}"
      echo "infra_fail=${infra_fail}"
      echo "note=No duplicate Monica or missing delivery after drift in ${ATTEMPTS} probe runs (web N/A)"
    } >"${RESULT_FILE}"
    echo "Bug 1.22 COULD NOT REPRODUCE after ${ATTEMPTS} attempts (clean=${clean}, infra=${infra_fail})"
    echo "Result: ${RESULT_FILE}"
    exit 0
    ;;
  *)
    echo "Unknown housing_proposal coordinator mode: ${MODE}" >&2
    exit 1
    ;;
esac
