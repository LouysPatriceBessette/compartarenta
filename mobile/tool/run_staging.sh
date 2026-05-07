#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"
./tool/flutterw run \
  --profile \
  --flavor staging \
  --dart-define=ENV=staging \
  --dart-define=API_BASE_URL=https://example.invalid

