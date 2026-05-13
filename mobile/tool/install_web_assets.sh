#!/usr/bin/env bash
set -euo pipefail

# Downloads the Drift web runtime assets (sqlite3 WebAssembly module and
# drift worker) into `mobile/web/`, matching the versions currently
# pinned in `pubspec.lock`.
#
# Run after the first checkout, or after any version bump of the `drift`
# / `sqlite3` packages. Idempotent — re-running just overwrites the files.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "${DIR}/.." && pwd)"
WEB_DIR="${DIR}/web"
LOCK="${ROOT}/pubspec.lock"

if [[ ! -f "${LOCK}" ]]; then
  echo "pubspec.lock not found at ${LOCK}" >&2
  exit 1
fi

extract_version() {
  # Reads the `version: "<x.y.z>"` immediately following a top-level
  # package entry (`  <name>:`) in pubspec.lock. Bails out if missing.
  local pkg="$1"
  python3 - "$LOCK" "$pkg" <<'PY'
import re, sys
lock_path, pkg = sys.argv[1], sys.argv[2]
with open(lock_path, 'r', encoding='utf-8') as fh:
    text = fh.read()
m = re.search(rf'^  {re.escape(pkg)}:\n(?:    .+\n)*?    version: "([^"]+)"',
              text, re.MULTILINE)
if not m:
    sys.exit(f"could not find version for {pkg} in pubspec.lock")
print(m.group(1))
PY
}

DRIFT_VERSION="$(extract_version drift)"
SQLITE3_VERSION="$(extract_version sqlite3)"

echo "drift   = ${DRIFT_VERSION}"
echo "sqlite3 = ${SQLITE3_VERSION}"

mkdir -p "${WEB_DIR}"

SQLITE_URL="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3_VERSION}/sqlite3.wasm"
DRIFT_URL="https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/drift_worker.js"

echo "Fetching sqlite3.wasm from ${SQLITE_URL}"
curl -fSL -o "${WEB_DIR}/sqlite3.wasm" "${SQLITE_URL}"

echo "Fetching drift_worker.dart.js from ${DRIFT_URL}"
curl -fSL -o "${WEB_DIR}/drift_worker.dart.js" "${DRIFT_URL}"

ls -lh "${WEB_DIR}/sqlite3.wasm" "${WEB_DIR}/drift_worker.dart.js"
echo "Done."
