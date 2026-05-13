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
#   dart run melos run run:dev:web -- --web-port=5001
#

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

API_BASE_URL_VALUE="${API_BASE_URL:-https://sync.incoherences.org}"

./tool/flutterw run \
  -d chrome \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  "$@"
