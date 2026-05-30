#!/usr/bin/env bash
set -euo pipefail
# Run after stopping run:dev:web (Ctrl+C or q) and BEFORE refresh.sh when you need
# web onboarding/contacts to survive a flutter clean + codegen cycle.
#
# Flutter persists the session under mobile/.dart_tool/chrome-device (not
# ~/.cache/compartarenta/flutter-web-chrome, which is removed on web exit when
# a custom --user-data-dir was used in older scripts).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHROME_PROFILE_DIR="${COMPARTARENTA_WEB_CHROME_PROFILE_DIR:-${DIR}/.dart_tool/chrome-device}"
# Outside .dart_tool/ so `flutter clean` in refresh.sh does not delete the backup.
CHROME_PROFILE_BACKUP_DIR="${COMPARTARENTA_WEB_PROFILE_BACKUP_DIR:-${HOME}/.cache/compartarenta/chrome-device-backup}"
LEGACY_CHROME_USER_DATA_DIR="${HOME}/.cache/compartarenta/flutter-web-chrome"
LEGACY_CHROME_PROFILE_BACKUP_DIR="${LEGACY_CHROME_USER_DATA_DIR}-backup"

if [[ ! -d "${CHROME_PROFILE_DIR}/Default" ]]; then
  if [[ -d "${LEGACY_CHROME_USER_DATA_DIR}/Default" ]]; then
    echo "NOTE: Found profile only at legacy path ${LEGACY_CHROME_USER_DATA_DIR}" >&2
    echo "      Re-run run:dev:web once, then backup again (Flutter now uses chrome-device)." >&2
    CHROME_PROFILE_DIR="${LEGACY_CHROME_USER_DATA_DIR}"
  else
    echo "No Chrome profile at ${CHROME_PROFILE_DIR}" >&2
    echo "  (Flutter copies the session here when run:dev:web exits.)" >&2
    exit 1
  fi
fi

# Names include spaces (e.g. "Code Cache") — use a bash array, not word-splitting.
CHROME_PROFILE_RSYNC_EXCLUDES=(
  --exclude='Default/Cache/'
  --exclude='Default/Code Cache/'
  --exclude='Default/GPUCache/'
  --exclude='GrShaderCache/'
  --exclude='ShaderCache/'
)

sleep 2
mkdir -p "${CHROME_PROFILE_BACKUP_DIR}"
echo "Backing up ${CHROME_PROFILE_DIR} -> ${CHROME_PROFILE_BACKUP_DIR}"
rsync -a --delete "${CHROME_PROFILE_RSYNC_EXCLUDES[@]}" \
  "${CHROME_PROFILE_DIR}/" "${CHROME_PROFILE_BACKUP_DIR}/"
du -sh "${CHROME_PROFILE_BACKUP_DIR}"
