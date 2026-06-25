#!/usr/bin/env bash
# Install the Maestro CLI locally (user scope, no CI).
#
# Usage: ./tool/install_maestro.sh
#
# Installs to ~/.maestro/bin by default (Maestro installer). Adds a note to
# update PATH when maestro is not already on PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

if command -v maestro >/dev/null 2>&1; then
  echo "Maestro already on PATH: $(command -v maestro)"
  maestro --version
  exit 0
fi

if [[ -x "${HOME}/.maestro/bin/maestro" ]]; then
  export PATH="${HOME}/.maestro/bin:${PATH}"
  echo "Maestro found at ${HOME}/.maestro/bin/maestro"
  maestro --version
  exit 0
fi

echo "Installing Maestro CLI..."
curl -fsSL "https://get.maestro.mobile.dev" | bash

export PATH="${HOME}/.maestro/bin:${PATH}"
if ! command -v maestro >/dev/null 2>&1; then
  echo "Maestro installed but not on PATH. Add this to your shell profile:" >&2
  echo '  export PATH="$HOME/.maestro/bin:$PATH"' >&2
  exit 1
fi

maestro --version
echo "Maestro ready."
