#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

# Extra args (e.g. -d linux) come from the command line, or from FLUTTER_DEVICE when unset.
# Example: dart run melos run run:dev -- -d chrome
# Example: FLUTTER_DEVICE=linux dart run melos run run:dev
extra=("$@")
if [[ ${#extra[@]} -eq 0 && -n "${FLUTTER_DEVICE:-}" ]]; then
  extra=(-d "${FLUTTER_DEVICE}")
fi

# Default relay base URL for the dev flavor points at the real relay so
# the handshake plumbing is enabled out of the box. Override via env
# (preferred) or by appending --dart-define=API_BASE_URL=... yourself.
API_BASE_URL_VALUE="${API_BASE_URL:-https://sync.incoherences.org}"

./tool/flutterw run \
  --flavor dev \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  "${extra[@]}"
