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

./tool/flutterw run \
  -d chrome \
  "${web_port_args[@]}" \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  "$@"
