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
#
# Browser CORS on the relay / Apache allow-list commonly expects
# http://localhost:5001 or :5002. This script defaults to port 5001
# unless you pass --web-port=... or set WEB_PORT (e.g. WEB_PORT=5002).
#

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

API_BASE_URL_VALUE="${API_BASE_URL:-https://sync.incoherences.org}"

web_port_args=()
if [[ "$*" != *--web-port* ]]; then
  web_port_args=(--web-port="${WEB_PORT:-5001}")
fi

# Flutter `flutter run -d chrome` always seeds/caches the live Chrome profile
# under mobile/.dart_tool/chrome-device (see flutter_tools web_device.dart).
# Do NOT pass a separate --user-data-dir: on exit Flutter copies the session
# into chrome-device and deletes that custom directory, which made backups to
# ~/.cache/compartarenta/flutter-web-chrome look empty after Ctrl+C.
#
# `flutter clean` deletes all of mobile/.dart_tool/, so the backup must live
# outside .dart_tool/ (default: ~/.cache/compartarenta/chrome-device-backup).
# Before refresh.sh: dart run melos run backup:web-chrome-profile
CHROME_PROFILE_DIR="${COMPARTARENTA_WEB_CHROME_PROFILE_DIR:-${DIR}/.dart_tool/chrome-device}"
CHROME_PROFILE_BACKUP_DIR="${COMPARTARENTA_WEB_PROFILE_BACKUP_DIR:-${HOME}/.cache/compartarenta/chrome-device-backup}"
DART_TOOL_CHROME_PROFILE_BACKUP_DIR="${DIR}/.dart_tool/chrome-device-backup"
LEGACY_CHROME_USER_DATA_DIR="${HOME}/.cache/compartarenta/flutter-web-chrome"
LEGACY_CHROME_PROFILE_BACKUP_DIR="${LEGACY_CHROME_USER_DATA_DIR}-backup"

_profile_has_onboarding_complete() {
  find "${CHROME_PROFILE_DIR}/Default/Local Storage" -type f 2>/dev/null \
    | xargs strings 2>/dev/null \
    | grep -q 'flutter.onboarding.complete' || return 1
  return 0
}

_migrate_legacy_backup_if_needed() {
  if [[ -d "${CHROME_PROFILE_BACKUP_DIR}/Default" ]]; then
    return 0
  fi
  if [[ -d "${DART_TOOL_CHROME_PROFILE_BACKUP_DIR}/Default" ]]; then
    echo "Migrating web profile backup from ${DART_TOOL_CHROME_PROFILE_BACKUP_DIR} (inside .dart_tool)"
    mkdir -p "${CHROME_PROFILE_BACKUP_DIR}"
    rsync -a "${DART_TOOL_CHROME_PROFILE_BACKUP_DIR}/" "${CHROME_PROFILE_BACKUP_DIR}/"
    return 0
  fi
  if [[ ! -d "${LEGACY_CHROME_PROFILE_BACKUP_DIR}/Default" ]]; then
    return 0
  fi
  echo "Migrating legacy web profile backup from ${LEGACY_CHROME_PROFILE_BACKUP_DIR}"
  mkdir -p "${CHROME_PROFILE_BACKUP_DIR}"
  rsync -a "${LEGACY_CHROME_PROFILE_BACKUP_DIR}/" "${CHROME_PROFILE_BACKUP_DIR}/"
}

_restore_chrome_profile_from_backup() {
  if [[ "${COMPARTARENTA_WEB_SKIP_PROFILE_RESTORE:-}" == "1" ]]; then
    return 0
  fi
  _migrate_legacy_backup_if_needed
  if [[ ! -d "${CHROME_PROFILE_BACKUP_DIR}/Default" ]]; then
    echo "No web Chrome profile backup at ${CHROME_PROFILE_BACKUP_DIR} (skip restore)"
    return 0
  fi
  if _profile_has_onboarding_complete; then
    echo "Live web Chrome profile already has onboarding data; skip restore from backup"
    return 0
  fi
  echo "Restoring web Chrome profile from ${CHROME_PROFILE_BACKUP_DIR}"
  mkdir -p "${CHROME_PROFILE_DIR}"
  rsync -a "${CHROME_PROFILE_RSYNC_EXCLUDES[@]}" \
    "${CHROME_PROFILE_BACKUP_DIR}/" "${CHROME_PROFILE_DIR}/"
}

# Match flutter_tools chrome.dart (_isNotCacheDirectory); "Code Cache" has a space.
CHROME_PROFILE_RSYNC_EXCLUDES=(
  --exclude='Default/Cache/'
  --exclude='Default/Code Cache/'
  --exclude='Default/GPUCache/'
  --exclude='GrShaderCache/'
  --exclude='ShaderCache/'
)

_backup_chrome_profile() {
  if [[ ! -d "${CHROME_PROFILE_DIR}/Default" ]]; then
    return 0
  fi
  mkdir -p "${CHROME_PROFILE_BACKUP_DIR}"
  # Allow Chrome to finish Flutter's cache copy after SIGINT (Melos Ctrl+C).
  sleep 3
  echo "Backing up web Chrome profile to ${CHROME_PROFILE_BACKUP_DIR}"
  rsync -a --delete "${CHROME_PROFILE_RSYNC_EXCLUDES[@]}" \
    "${CHROME_PROFILE_DIR}/" "${CHROME_PROFILE_BACKUP_DIR}/"
  du -sh "${CHROME_PROFILE_BACKUP_DIR}" || true
}

_restore_chrome_profile_from_backup
trap _backup_chrome_profile EXIT INT TERM

echo "Web Chrome profile (Flutter cache): ${CHROME_PROFILE_DIR}"
echo "Web Chrome profile backup: ${CHROME_PROFILE_BACKUP_DIR}"

# COOP/COEP enable Drift's more reliable OPFS-backed web storage (see
# docs/development-roadmap.md). Without them, IndexedDB fallback may lose
# very recent writes when this process stops Chrome on restart.
./tool/flutterw run \
  -d chrome \
  "${web_port_args[@]}" \
  --web-header=Cross-Origin-Opener-Policy=same-origin \
  --web-header=Cross-Origin-Embedder-Policy=require-corp \
  --dart-define=ENV=dev \
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}" \
  "$@"
_backup_chrome_profile
