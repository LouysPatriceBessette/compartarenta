#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"
./tool/flutterw run \
  --flavor dev \
  --dart-define=ENV=dev \
  --dart-define=API_BASE_URL=https://example.invalid

