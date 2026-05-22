#!/usr/bin/env bash
set -euo pipefail

# Dev-flavor equivalent for Flutter web.
#
# Flutter web does NOT support --flavor (flavors are an Android/iOS
# concept tied to native build variants). To keep the dev experience as
# close as possible to `tool/run_dev.sh`, we forward the same
# --dart-define values but skip --flavor and target the Chrome device
# explicitly.
#
# Default relay base URL points at the real relay (same default as
# tool/run_dev.sh). Override via env or by appending dart-defines:
#
#   API_BASE_URL=http://localhost:8080 dart run melos run run:dev:web
#
# Browser CORS on the relay / Apache allow-list commonly expects
# http://localhost:5001 or :5002. This script defaults to port 5001
# unless you pass --web-port=... or set WEB_PORT (e.g. WEB_PORT=5002).
#

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

API_BASE_URL_VALUE="${API_BASE_URL:-https://sync.incoherences.org}"

web_port_args=()
if [[ "$*" != *--web-port* ]]; then
  web_port_args=(--web-port="${WEB_PORT:-5001}")
fi

# Flutter's default Chrome profile for `flutter run -d chrome` is ephemeral:
# IndexedDB (Drift) and localStorage are wiped when the dev server stops.
# Reuse a stable user-data dir so housing drafts, contacts, and prefs survive
# melos/CTRL+C restarts on the same machine.
CHROME_USER_DATA_DIR="${COMPARTARENTA_WEB_USER_DATA_DIR:-${HOME}/.cache/compartarenta/flutter-web-chrome}"
mkdir -p "${CHROME_USER_DATA_DIR}"
web_browser_flag_args=()
if [[ "$*" != *user-data-dir* ]]; then
  web_browser_flag_args+=(--web-browser-flag="--user-data-dir=${CHROME_USER_DATA_DIR}")
fi

# COOP/COEP enable Drift's more reliable OPFS-backed web storage (see
# docs/development-roadmap.md). Without them, IndexedDB fallback may lose
# very recent writes when this process stops Chrome on restart.
./tool/flutterw run \
  -d chrome \
  "${web_port_args[@]}" \
  "${web_browser_flag_args[@]}" \
  --web-header=Cross-Origin-Opener-Policy=same-origin \
  --web-header=Cross-Origin-Embedder-Policy=require-corp \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  "$@"
