#!/usr/bin/env bash
# Pre-register Monica↔Louys steady-state routing on the prod relay for the
# FCM wake QA scenario (fixed X25519 seeds — see mobile/lib/debug/qa_fcm_wake_push_seed.dart).
#
# Idempotent: safe to call before every fcm_wake_push run.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

API_BASE_URL="${API_BASE_URL:-${COMPARTARENTA_QA_API_BASE_URL:-https://sync.incoherences.org}}"
API_BASE_URL="${API_BASE_URL%/}"

read -r MONICA_SELF LOUYS_PEER < <(
  python3 "${ROOT}/tool/qa_fcm_wake_relay_routing.py" listen_addresses
)

echo "Establishing relay routing (${API_BASE_URL}) Monica listen=${MONICA_SELF}"

HTTP_CODE="$(
  curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "${API_BASE_URL}/v1/handshake/establish" \
    -H 'Content-Type: application/json' \
    -d "{\"self_identity\":\"${MONICA_SELF}\",\"peer_identity\":\"${LOUYS_PEER}\"}"
)"

if [[ "${HTTP_CODE}" != "204" ]]; then
  echo "ERROR: handshake/establish returned HTTP ${HTTP_CODE} (expected 204)." >&2
  exit 1
fi

echo "Relay routing established (Monica↔Louys)."
