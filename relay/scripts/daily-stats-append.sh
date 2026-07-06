#!/usr/bin/env bash
# Append one daily statistics JSON line for yesterday (UTC) by calling the
# relay loopback-only stats endpoint. Intended for cron at 00:07 UTC:
#   7 0 * * * relay-user /path/to/daily-stats-append.sh
#
# Environment:
#   RELAY_STATS_URL  default http://127.0.0.1:9091/internal/stats/daily
#   STATS_FILE_PATH  default /srv/compartarenta-stats/daily.jsonl
#
# Variable naming matches the closed-app-push-delivery design spec
# (`openspec/changes/closed-app-push-delivery/design.md` § 10).
# The relay database is never queried by this script; only the HTTP endpoint
# is used.

set -euo pipefail

RELAY_STATS_URL="${RELAY_STATS_URL:-http://127.0.0.1:9091/internal/stats/daily}"
STATS_FILE_PATH="${STATS_FILE_PATH:-/srv/compartarenta-stats/daily.jsonl}"

yesterday="$(date -u -d yesterday +%F 2>/dev/null || date -u -v-1d +%F)"

# Idempotency: skip if this date already appears as the first JSON field.
if [[ -f "$STATS_FILE_PATH" ]] && grep -q "\"date\":\"${yesterday}\"" "$STATS_FILE_PATH" 2>/dev/null; then
  exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsS "$RELAY_STATS_URL?date=${yesterday}" -o "$tmp"

mkdir -p "$(dirname "$STATS_FILE_PATH")"
# The relay uses encoding/json.Encoder.Encode, which already appends a
# trailing newline. Do not add a second one or `wc -l` will count an
# extra blank line and JSONL parsers may see an empty record.
cat "$tmp" >>"$STATS_FILE_PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$SCRIPT_DIR/run-marketing-stats-data-rebuild.sh" ]]; then
  "$SCRIPT_DIR/run-marketing-stats-data-rebuild.sh"
fi
