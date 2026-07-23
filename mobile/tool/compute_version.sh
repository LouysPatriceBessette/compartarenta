#!/usr/bin/env bash
# Compute Flutter build identifiers from git history.
#
# - BUILD_NAME   = most recent reachable tag, stripped of any leading "v"
#                  (e.g. v0.1.0 -> 0.1.0). Fallback "0.0.0" if no tag exists.
# - BUILD_NUMBER = number of commits between that tag and HEAD. 0 when HEAD
#                  is exactly the tagged commit. Falls back to the total
#                  commit count of HEAD when no tag exists.
# - GIT_SHA      = short SHA of HEAD (`git rev-parse --short HEAD`). Empty
#                  string if not available.
#
# Output mode (default): a single line of Flutter CLI flags ready to be
# spliced into `flutter build ...`, e.g.
#
#   flutter build apk $(./tool/compute_version.sh) ...
#
# This includes `--build-name=`, `--build-number=` AND
# `--dart-define=GIT_SHA=...` so the running app can self-identify down to
# the exact commit on the About screen.
#
# Output mode (`--env`): KEY=VALUE pairs, suitable for `eval` or `source`.
#
# The script must run somewhere inside the Bojairu git work tree; if it
# cannot find one (e.g. shallow checkout without tags, or a CI environment
# stripped of git metadata), it falls back to "0.0.0+0" and an empty SHA.

set -euo pipefail

mode="flags"
if [[ "${1:-}" == "--env" ]]; then
  mode="env"
fi

build_name="0.0.0"
build_number="0"
git_sha=""

if git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --is-inside-work-tree \
       >/dev/null 2>&1; then
  repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" \
                rev-parse --show-toplevel)"
  if latest_tag="$(git -C "${repo_root}" describe --tags --abbrev=0 \
                    2>/dev/null)"; then
    build_name="${latest_tag#v}"
    build_number="$(git -C "${repo_root}" rev-list --count \
                     "${latest_tag}..HEAD" 2>/dev/null || echo 0)"
  else
    build_number="$(git -C "${repo_root}" rev-list --count HEAD \
                     2>/dev/null || echo 0)"
  fi
  git_sha="$(git -C "${repo_root}" rev-parse --short HEAD 2>/dev/null || true)"
fi

case "${mode}" in
  env)
    echo "BUILD_NAME=${build_name}"
    echo "BUILD_NUMBER=${build_number}"
    echo "GIT_SHA=${git_sha}"
    ;;
  flags)
    echo "--build-name=${build_name} --build-number=${build_number} --dart-define=GIT_SHA=${git_sha}"
    ;;
esac
