#!/usr/bin/env bash
# Wrapper for Maestro MCP in Cursor (stdio). Ensures ~/.maestro/bin is on PATH.
set -euo pipefail
export MAESTRO_CLI_NO_ANALYTICS="${MAESTRO_CLI_NO_ANALYTICS:-1}"
export PATH="${HOME}/.maestro/bin:${PATH}"
exec maestro mcp --no-viewer "$@"
