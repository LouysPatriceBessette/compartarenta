#!/usr/bin/env bash
# Host-side wrapper around the relay's loopback-only stats endpoint.
#
# The relay's `daily-stats-append.sh` (next to this file) assumes the cron
# runs in a context where `curl http://127.0.0.1:9091/...` is observed as a
# loopback caller by the relay process. When the relay runs inside a Docker
# container, the host's loopback is NOT the container's loopback, so a
# direct `curl` from the host receives HTTP 404.
#
# This wrapper sidesteps the problem without modifying the relay binary or
# the original script: it runs a minimal `curl` container that joins the
# relay container's network namespace
# (`docker run --network container:<name>`), so the in-container loopback
# is what answers the request. The relay sees a legitimate loopback peer
# and serves JSON.
#
# Intended cron line (UTC interpretation):
#
#   CRON_TZ=UTC
#   7 0 * * * /srv/compartarenta-relay/source/relay/scripts/daily-stats-append-via-docker.sh \
#     >> /srv/compartarenta-stats/cron.log 2>&1
#
# Environment:
#   COMPARTARENTA_RELAY_CONTAINER  default: compartarenta-relay
#   COMPARTARENTA_CURL_IMAGE       default: curlimages/curl:8.5.0
#   STATS_FILE_PATH                default: /srv/compartarenta-stats/daily.jsonl
#
# Variable naming matches the closed-app-push-delivery design spec
# (`openspec/changes/closed-app-push-delivery/design.md` § 10).

set -euo pipefail

CONTAINER="${COMPARTARENTA_RELAY_CONTAINER:-compartarenta-relay}"
CURL_IMAGE="${COMPARTARENTA_CURL_IMAGE:-curlimages/curl:8.5.0}"
STATS_FILE_PATH="${STATS_FILE_PATH:-/srv/compartarenta-stats/daily.jsonl}"

yesterday="$(date -u -d yesterday +%F 2>/dev/null || date -u -v-1d +%F)"

# Idempotent re-run: skip if yesterday is already recorded.
if [[ -f "$STATS_FILE_PATH" ]] && grep -q "\"date\":\"${yesterday}\"" "$STATS_FILE_PATH" 2>/dev/null; then
  exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

docker run --rm --network "container:${CONTAINER}" "${CURL_IMAGE}" \
  -fsS "http://127.0.0.1:9091/internal/stats/daily?date=${yesterday}" \
  > "$tmp"

mkdir -p "$(dirname "$STATS_FILE_PATH")"
# The relay uses encoding/json.Encoder.Encode, which already appends a
# trailing newline. Do not add a second one or `wc -l` will count an
# extra blank line and JSONL parsers may see an empty record.
cat "$tmp" >>"$STATS_FILE_PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/run-marketing-stats-data-rebuild.sh" ]]; then
  "$SCRIPT_DIR/run-marketing-stats-data-rebuild.sh"
fi
