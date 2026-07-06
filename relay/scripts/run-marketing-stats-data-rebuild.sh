#!/usr/bin/env bash
# After daily-stats-append*.sh writes JSONL, regenerate the marketing site's
# stats-data.json (compartarenta.incoherences.org — scripts/update-stats.mjs).
#
# Invoked automatically at the end of daily-stats-append-via-docker.sh and
# daily-stats-append.sh. Can also be run manually after a static site deploy
# (scp) that overwrote assets/stats-data.json.
#
# Environment:
#   STATS_DATA_REBUILD_SCRIPT — path to vps-daily-stats-rebuild.sh on the VPS
#                               (marketing site repo clone)
#   Alias: COMPARTARENTA_STATS_DATA_REBUILD_SCRIPT
#
# Defaults (first executable path wins):
#   /srv/compartarenta-marketing-source/scripts/vps-daily-stats-rebuild.sh
#   ~/repos/online/compartarenta.incoherences.org/scripts/vps-daily-stats-rebuild.sh

set -euo pipefail

sleep 1

resolve_rebuild_script() {
  local candidate=""
  if [[ -n "${STATS_DATA_REBUILD_SCRIPT:-}" ]]; then
    printf '%s' "$STATS_DATA_REBUILD_SCRIPT"
    return 0
  fi
  if [[ -n "${COMPARTARENTA_STATS_DATA_REBUILD_SCRIPT:-}" ]]; then
    printf '%s' "$COMPARTARENTA_STATS_DATA_REBUILD_SCRIPT"
    return 0
  fi
  for candidate in \
    "/srv/compartarenta-marketing-source/scripts/vps-daily-stats-rebuild.sh" \
    "${HOME}/repos/online/compartarenta.incoherences.org/scripts/vps-daily-stats-rebuild.sh"; do
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

rebuild_script=""
if ! rebuild_script="$(resolve_rebuild_script)"; then
  echo "run-marketing-stats-data-rebuild: no rebuild script found; set STATS_DATA_REBUILD_SCRIPT" >&2
  exit 1
fi

exec "$rebuild_script"
