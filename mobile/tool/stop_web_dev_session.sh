#!/usr/bin/env bash
set -euo pipefail

# Melos prefixes stderr as "ERROR:" — stdout for expected leftovers (Cursor sandbox).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="${DIR}/.dart_tool/web-dev-session-server.pid"
PORT_FILE="${DIR}/.dart_tool/web-dev-session-port"

HOST="${WEB_DEV_SESSION_HOST:-localhost}"
PORT="${WEB_DEV_SESSION_PORT:-}"
if [[ -z "${PORT}" && -f "${PORT_FILE}" ]]; then
  PORT="$(cat "${PORT_FILE}")"
fi
PORT="${PORT:-18765}"
URL="http://${HOST}:${PORT}/session"
ME="$(id -un)"

echo "Stopping web dev session server at ${URL}…"

_pids_on_port() {
  if ! command -v fuser >/dev/null 2>&1; then
    return 0
  fi
  fuser -n tcp "${PORT}" 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+$' || true
}

_same_user_namespace_as_self() {
  local pid="$1"
  local self_ns target_ns
  self_ns="$(readlink /proc/self/ns/user 2>/dev/null || echo)"
  target_ns="$(readlink "/proc/${pid}/ns/user" 2>/dev/null || echo)"
  [[ -n "${self_ns}" && -n "${target_ns}" && "${self_ns}" == "${target_ns}" ]]
}

_is_cursor_sandbox_pid() {
  local pid="$1"
  local attr
  attr="$(cat "/proc/${pid}/attr/current" 2>/dev/null || true)"
  [[ "${attr}" == *cursor_sandbox* ]] \
    || ! _same_user_namespace_as_self "${pid}"
}

_kill_pid() {
  local pid="$1"
  if ! kill -0 "${pid}" 2>/dev/null; then
    return 0
  fi
  if kill "${pid}" 2>/dev/null; then
    return 0
  fi
  if _is_cursor_sandbox_pid "${pid}"; then
    return 0
  fi
  echo "Could not stop pid ${pid} (Permission denied)." >&2
  return 1
}

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}")"
  _kill_pid "${pid}" || true
  sleep 0.2
  rm -f "${PID_FILE}"
fi

pkill -u "${ME}" -f 'web_dev_session_server' 2>/dev/null || true

while read -r pid; do
  [[ -z "${pid}" ]] && continue
  _kill_pid "${pid}" || true
done < <(_pids_on_port)

sleep 0.2
while read -r pid; do
  [[ -z "${pid}" ]] && continue
  if kill -0 "${pid}" 2>/dev/null; then
    kill -9 "${pid}" 2>/dev/null || true
  fi
done < <(_pids_on_port)

rm -f "${PORT_FILE}"
sleep 0.2

if ss -tln 2>/dev/null | grep -q ":${PORT} "; then
  holder_pid="$(ss -tlnp 2>/dev/null | grep ":${PORT} " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | head -1)"
  if [[ -n "${holder_pid}" ]] && _is_cursor_sandbox_pid "${holder_pid}"; then
    echo "Note: port ${PORT} is still held by a Cursor agent sandbox (pid ${holder_pid}); safe to ignore."
    echo "  run:dev:web will use the next port. Optional: sudo fuser -k ${PORT}/tcp"
    exit 0
  fi
  echo "Port ${PORT} is still in use after stop:" >&2
  ss -tlnp 2>/dev/null | grep ":${PORT} " >&2 || true
  if [[ -n "${holder_pid}" ]]; then
    holder_user="$(ps -o user= -p "${holder_pid}" 2>/dev/null | tr -d ' ')"
    if [[ "${holder_user}" == "${ME}" ]]; then
      echo "  Your process (pid ${holder_pid}) is still listening. Try: kill -9 ${holder_pid}" >&2
    else
      echo "  Held by ${holder_user} (pid ${holder_pid}). Try: sudo kill ${holder_pid}" >&2
    fi
  fi
  exit 1
fi

echo "Stopped (port ${PORT} free)."
