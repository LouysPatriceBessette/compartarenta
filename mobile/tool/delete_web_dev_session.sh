#!/usr/bin/env bash
set -euo pipefail

HOST="${WEB_DEV_SESSION_HOST:-localhost}"
PORT="${WEB_DEV_SESSION_PORT:-18765}"
URL="http://${HOST}:${PORT}/session"
FILE="${HOME}/.cache/compartarenta/web-dev-session.json"

if curl -sf -X DELETE "${URL}" >/dev/null 2>&1; then
  echo "Deleted web dev session via ${URL}"
elif [[ -f "${FILE}" ]]; then
  rm -f "${FILE}"
  echo "Deleted web dev session file ${FILE} (server not running)"
else
  echo "No web dev session at ${URL} or ${FILE}"
fi
