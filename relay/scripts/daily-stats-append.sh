#!/usr/bin/env bash
# Append one daily statistics JSON line for yesterday (UTC) by calling the
# relay loopback-only stats endpoint. Intended for cron at 00:07 UTC:
#   7 0 * * * relay-user /path/to/daily-stats-append.sh
#
# Environment:
#   RELAY_STATS_URL   default http://127.0.0.1:9091/internal/stats/daily
#   RELAY_STATS_FILE  default /var/lib/compartarenta-relay/stats/daily.jsonl
#
# The relay database is never queried by this script; only the HTTP endpoint
# is used, matching the closed-app-push-delivery spec.

set -euo pipefail

RELAY_STATS_URL="${RELAY_STATS_URL:-http://127.0.0.1:9091/internal/stats/daily}"
RELAY_STATS_FILE="${RELAY_STATS_FILE:-/var/lib/compartarenta-relay/stats/daily.jsonl}"

yesterday="$(date -u -d yesterday +%F 2>/dev/null || date -u -v-1d +%F)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsS "$RELAY_STATS_URL?date=${yesterday}" -o "$tmp"

# Idempotency: skip if this date already appears as the first JSON field.
if [[ -f "$RELAY_STATS_FILE" ]] && grep -q "\"date\":\"${yesterday}\"" "$RELAY_STATS_FILE" 2>/dev/null; then
  exit 0
fi

mkdir -p "$(dirname "$RELAY_STATS_FILE")"
cat "$tmp" >>"$RELAY_STATS_FILE"
printf '\n' >>"$RELAY_STATS_FILE"
