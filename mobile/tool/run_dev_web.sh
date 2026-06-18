#!/usr/bin/env bash
set -euo pipefail

# Dev-flavor Flutter web. Invoked by: dart run melos run run:dev:web
#
# Persists Drift/prefs/identity to ~/.cache/compartarenta/web-dev-session.json
# via a local HTTP server (survives Ctrl+C and flutter clean). No manual backup.
#
# Melos prefixes stderr as "ERROR:" — use stdout for expected notes (port skip, etc.).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "${DIR}/.." && pwd)"

cd "${DIR}"

# shellcheck source=../../tool/ensure_pub_get.sh
source "${ROOT}/tool/ensure_pub_get.sh"
ensure_workspace_pub_get "${ROOT}"

API_BASE_URL_VALUE="${API_BASE_URL:-https://sync.incoherences.org}"
# shellcheck source=entitlement_base_url_default.sh
source "${DIR}/tool/entitlement_base_url_default.sh"
ENTITLEMENT_BASE_URL_VALUE="$(entitlement_base_url_default "${API_BASE_URL_VALUE}")"
# Use localhost (not 127.0.0.1): Flutter web is served at http://localhost:WEB_PORT
# and the browser blocks cross-origin calls to 127.0.0.1.
WEB_DEV_SESSION_HOST="${WEB_DEV_SESSION_HOST:-localhost}"
WEB_DEV_SESSION_PORT_BASE="${WEB_DEV_SESSION_PORT_BASE:-18765}"
WEB_DEV_SESSION_PORT_MAX="${WEB_DEV_SESSION_PORT_MAX:-18799}"
WEB_DEV_SESSION_PID_FILE="${DIR}/.dart_tool/web-dev-session-server.pid"
WEB_DEV_SESSION_PORT_FILE="${DIR}/.dart_tool/web-dev-session-port"
WEB_DEV_SESSION_URL_FILE="${DIR}/.dart_tool/web-dev-session-url"
HOST_SESSION_FILE="${HOME}/.cache/compartarenta/web-dev-session.json"

# Set WEB_DEV_SESSION_PORT yourself to pin a port; otherwise a free port is chosen.
WEB_DEV_SESSION_PORT="${WEB_DEV_SESSION_PORT:-}"
WEB_DEV_SESSION_URL=""

web_port_args=()
if [[ "$*" != *--web-port* ]]; then
  web_port_args=(--web-port="${WEB_PORT:-5001}")
fi

# curl alone is not enough: a zombie listener may answer 404 without CORS headers
# while the browser still gets "Failed to fetch".
_is_our_session_server() {
  local port="$1"
  local headers
  headers=$(curl -s -D - -o /dev/null --connect-timeout 1 \
    -X OPTIONS "http://${WEB_DEV_SESSION_HOST}:${port}/session" \
    -H 'Origin: http://localhost:5001' \
    -H 'Access-Control-Request-Method: PUT' 2>/dev/null || true)
  echo "${headers}" | grep -qi 'access-control-allow-origin' \
    && echo "${headers}" | grep -qi 'cross-origin-resource-policy'
}

_port_in_use() {
  local port="$1"
  ss -tln 2>/dev/null | grep -q ":${port} "
}

_session_server_pid_on_port() {
  local port="$1"
  ss -tlnp 2>/dev/null | grep ":${port} " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | head -1
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

_port_managed_by_this_shell() {
  local port="$1"
  local pid
  pid="$(_session_server_pid_on_port "${port}")"
  if [[ -z "${pid}" ]]; then
    return 1
  fi
  if [[ "$(ps -o user= -p "${pid}" 2>/dev/null | tr -d ' ')" != "$(id -un)" ]]; then
    return 1
  fi
  if _is_cursor_sandbox_pid "${pid}"; then
    return 1
  fi
  return 0
}

# Informational only (stdout — not a Melos ERROR).
_note_port_skip() {
  local port="$1"
  local pid
  pid="$(_session_server_pid_on_port "${port}")"
  if [[ -n "${pid}" ]] && _is_cursor_sandbox_pid "${pid}"; then
    echo "Note: port ${port} is used by a Cursor agent sandbox (pid ${pid}); using the next free port."
    echo "  Optional cleanup: sudo fuser -k ${port}/tcp"
    return 0
  fi
  if [[ -n "${pid}" ]]; then
    echo "Note: port ${port} is in use (pid ${pid}); trying the next port."
  else
    echo "Note: port ${port} is in use; trying the next port."
  fi
}

# Unexpected blocker — stderr only when we cannot continue.
_print_port_conflict_diagnostics() {
  local port="$1"
  echo "Port ${port} is busy and is not a session server we can use from this shell:" >&2
  ss -tlnp 2>/dev/null | grep ":${port} " >&2 || true
  if command -v fuser >/dev/null 2>&1; then
    fuser -v "${port}/tcp" 2>&1 >&2 || true
  fi
}

_print_host_backup_hint() {
  if [[ -f "${HOST_SESSION_FILE}" ]]; then
    local bytes
    bytes=$(wc -c <"${HOST_SESSION_FILE}" | tr -d ' ')
    echo "Web dev session backup on disk: ${HOST_SESSION_FILE} (${bytes} bytes)"
    echo "  Survives flutter clean / refresh.sh; restored on next run:dev:web when the server is reachable."
  else
    echo "Web dev session backup: none yet at ${HOST_SESSION_FILE}"
    echo "  Created after onboarding completes (look for web_dev_host_session: saved to host in logs)."
  fi
}

_pick_session_port() {
  if [[ -n "${WEB_DEV_SESSION_PORT}" ]]; then
    if _is_our_session_server "${WEB_DEV_SESSION_PORT}" \
      && _port_managed_by_this_shell "${WEB_DEV_SESSION_PORT}"; then
      return 0
    fi
    if _port_in_use "${WEB_DEV_SESSION_PORT}"; then
      echo "WEB_DEV_SESSION_PORT=${WEB_DEV_SESSION_PORT} is busy and not our session server." >&2
      _print_port_conflict_diagnostics "${WEB_DEV_SESSION_PORT}"
      echo "Unset WEB_DEV_SESSION_PORT to auto-pick a free port, or choose another." >&2
      return 1
    fi
    return 0
  fi

  local p
  for ((p = WEB_DEV_SESSION_PORT_BASE; p <= WEB_DEV_SESSION_PORT_MAX; p++)); do
    if _is_our_session_server "${p}" && _port_managed_by_this_shell "${p}"; then
      WEB_DEV_SESSION_PORT="${p}"
      return 0
    fi
    if _port_in_use "${p}"; then
      _note_port_skip "${p}"
      continue
    fi
    WEB_DEV_SESSION_PORT="${p}"
    if [[ "${p}" != "${WEB_DEV_SESSION_PORT_BASE}" ]]; then
      echo "Note: using port ${p} (${WEB_DEV_SESSION_PORT_BASE} unavailable)."
    fi
    return 0
  done

  echo "No free port in range ${WEB_DEV_SESSION_PORT_BASE}-${WEB_DEV_SESSION_PORT_MAX}." >&2
  return 1
}

_stop_session_server_on_port() {
  local port="$1"
  if [[ -f "${WEB_DEV_SESSION_PID_FILE}" ]]; then
    local old_pid
    old_pid="$(cat "${WEB_DEV_SESSION_PID_FILE}")"
    if kill -0 "${old_pid}" 2>/dev/null; then
      kill "${old_pid}" 2>/dev/null || true
      sleep 0.3
    fi
    rm -f "${WEB_DEV_SESSION_PID_FILE}"
  fi

  local pid
  pid="$(_session_server_pid_on_port "${port}")"
  if [[ -n "${pid}" ]] \
    && [[ "$(ps -o user= -p "${pid}" 2>/dev/null | tr -d ' ')" == "$(id -un)" ]] \
    && ! _is_cursor_sandbox_pid "${pid}"; then
    kill "${pid}" 2>/dev/null || true
    sleep 0.2
  fi
}

_start_web_dev_session_server() {
  if ! _pick_session_port; then
    return 1
  fi

  WEB_DEV_SESSION_URL="http://${WEB_DEV_SESSION_HOST}:${WEB_DEV_SESSION_PORT}"
  echo "${WEB_DEV_SESSION_PORT}" >"${WEB_DEV_SESSION_PORT_FILE}"
  echo "${WEB_DEV_SESSION_URL}" >"${WEB_DEV_SESSION_URL_FILE}"

  # Always restart so server code matches the Flutter app (stale listeners reject new session versions).
  if _is_our_session_server "${WEB_DEV_SESSION_PORT}" \
    && _port_managed_by_this_shell "${WEB_DEV_SESSION_PORT}"; then
    echo "Restarting web dev session server on ${WEB_DEV_SESSION_URL} (pick up latest session format)…"
    _stop_session_server_on_port "${WEB_DEV_SESSION_PORT}"
  fi

  if _is_our_session_server "${WEB_DEV_SESSION_PORT}"; then
    echo "Web dev session server already listening (${WEB_DEV_SESSION_URL})"
    return 0
  fi

  if _port_in_use "${WEB_DEV_SESSION_PORT}"; then
    echo "Cannot bind ${WEB_DEV_SESSION_URL}: port still in use after stop." >&2
    _print_port_conflict_diagnostics "${WEB_DEV_SESSION_PORT}"
    return 1
  fi

  mkdir -p "${HOME}/.cache/compartarenta"
  local session_server_env=(WEB_DEV_SESSION_PORT="${WEB_DEV_SESSION_PORT}")
  if [[ "${WEB_DEV_WIPE_BROWSER_ON_START:-0}" == "1" ]]; then
    session_server_env+=(WEB_DEV_WIPE_BROWSER_ON_START=1)
  fi
  env "${session_server_env[@]}" \
    dart --packages="${ROOT}/.dart_tool/package_config.json" \
    tool/web_dev_session_server.dart &
  local pid=$!
  echo "${pid}" >"${WEB_DEV_SESSION_PID_FILE}"

  local i
  for i in $(seq 1 40); do
    if _is_our_session_server "${WEB_DEV_SESSION_PORT}"; then
      echo "Web dev session server listening (pid ${pid}, ${WEB_DEV_SESSION_URL})"
      echo "Stop server: dart run melos run stop:web-dev-session"
      echo "Delete session: dart run melos run delete:web-dev-session"
      return 0
    fi
    if ! kill -0 "${pid}" 2>/dev/null; then
      echo "Web dev session server process exited before binding to port ${WEB_DEV_SESSION_PORT}" >&2
      rm -f "${WEB_DEV_SESSION_PID_FILE}"
      return 1
    fi
    sleep 0.25
  done

  echo "Web dev session server did not become ready on ${WEB_DEV_SESSION_URL} within 10s" >&2
  return 1
}

_print_host_backup_hint

WIPE_MARKER="${DIR}/.dart_tool/web-dev-wipe-browser-on-next-launch"
WEB_DEV_WIPE_BROWSER_ON_START=0
if [[ -f "${WIPE_MARKER}" ]]; then
  echo "delete:web-dev-session requested a one-shot browser wipe on next app load."
  WEB_DEV_WIPE_BROWSER_ON_START=1
  rm -f "${WIPE_MARKER}"
fi
export WEB_DEV_WIPE_BROWSER_ON_START

if ! _start_web_dev_session_server; then
  exit 1
fi

if [[ "${WEB_DEV_WIPE_BROWSER_ON_START}" == "1" ]]; then
  if curl -sf -X POST "${WEB_DEV_SESSION_URL}/session/wipe-pending" >/dev/null 2>&1; then
    echo "One-shot browser wipe armed on ${WEB_DEV_SESSION_URL} (page refresh will not repeat it)."
  fi
fi

echo "Web dev persistence: pass WEB_DEV_SESSION_URL=${WEB_DEV_SESSION_URL} to Flutter"
if [[ -n "${ENTITLEMENT_BASE_URL_VALUE}" ]]; then
  echo "Entitlement client API: ENTITLEMENT_BASE_URL=${ENTITLEMENT_BASE_URL_VALUE}"
fi

web_run_args=(
  run
  -d chrome
  "${web_port_args[@]}"
  --no-pub
  --no-web-resources-cdn
  --web-header=Cross-Origin-Opener-Policy=same-origin
  --web-header=Cross-Origin-Embedder-Policy=require-corp
  --dart-define=ENV=dev
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}"
  --dart-define="WEB_DEV_SESSION_URL=${WEB_DEV_SESSION_URL}"
)
if [[ -n "${ENTITLEMENT_BASE_URL_VALUE}" ]]; then
  web_run_args+=(--dart-define="ENTITLEMENT_BASE_URL=${ENTITLEMENT_BASE_URL_VALUE}")
fi
web_run_args+=("$@")

./tool/flutterw "${web_run_args[@]}"
