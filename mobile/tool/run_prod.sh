#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"
./tool/flutterw run \
  --release \
  --flavor prod \
  --dart-define=ENV=prod \
  --dart-define=API_BASE_URL=https://example.invalid

