#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

# Extra args (e.g. -d linux) come from the command line, or from FLUTTER_DEVICE when unset.
# Example: melos run run:dev -- -d chrome
# Example: FLUTTER_DEVICE=linux melos run run:dev
extra=("$@")
if [[ ${#extra[@]} -eq 0 && -n "${FLUTTER_DEVICE:-}" ]]; then
  extra=(-d "${FLUTTER_DEVICE}")
fi

./tool/flutterw run \
  --flavor dev \
  --dart-define=ENV=dev \
  --dart-define=API_BASE_URL=https://example.invalid \
  "${extra[@]}"
