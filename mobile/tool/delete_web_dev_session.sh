#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT_FILE="${DIR}/.dart_tool/web-dev-session-port"

HOST="${WEB_DEV_SESSION_HOST:-localhost}"
PORT="${WEB_DEV_SESSION_PORT:-}"
if [[ -z "${PORT}" && -f "${PORT_FILE}" ]]; then
  PORT="$(cat "${PORT_FILE}")"
fi
PORT="${PORT:-18765}"
URL="http://${HOST}:${PORT}/session"
WIPE_URL="http://${HOST}:${PORT}/session/wipe-pending"
FILE="${HOME}/.cache/compartarenta/web-dev-session.json"
WIPE_MARKER="${DIR}/.dart_tool/web-dev-wipe-browser-on-next-launch"

_schedule_browser_wipe_on_next_launch() {
  mkdir -p "$(dirname "${WIPE_MARKER}")"
  : >"${WIPE_MARKER}"
  if curl -sf -X POST "${WIPE_URL}" >/dev/null 2>&1; then
    echo "Scheduled one-shot browser wipe on the dev session server."
  fi
  echo "Next run:dev:web will wipe browser storage once (OPFS, localStorage mirrors, prefs)."
}

if curl -sf -X DELETE "${URL}" >/dev/null 2>&1; then
  echo "Deleted web dev session via ${URL}"
  _schedule_browser_wipe_on_next_launch
elif [[ -f "${FILE}" ]]; then
  rm -f "${FILE}"
  echo "Deleted web dev session file ${FILE} (server not running)"
  _schedule_browser_wipe_on_next_launch
else
  echo "No web dev session at ${URL} or ${FILE}"
  echo "Scheduling browser wipe on next run:dev:web anyway."
  _schedule_browser_wipe_on_next_launch
fi
