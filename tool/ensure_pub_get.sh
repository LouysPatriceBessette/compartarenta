#!/usr/bin/env bash
# Skip pub get when workspace pubspec inputs are unchanged (avoids repeated
# pub.dev traffic on every dev launch). Source this file, then call
# ensure_workspace_pub_get. Set COMPARTARENTA_FORCE_PUB_GET=1 to always refresh.

ensure_workspace_pub_get() {
  local root="${1:-${COMPARTARENTA_ROOT:-$(pwd)}}"
  local pkg_config="${root}/.dart_tool/package_config.json"
  local stamp="${root}/.dart_tool/.pub_get_inputs_stamp"

  if [[ "${COMPARTARENTA_FORCE_PUB_GET:-0}" == "1" ]]; then
    _run_workspace_pub_get "${root}" "${stamp}"
    ENSURE_PUB_GET_SKIPPED=0
    unset PUB_OFFLINE
    return 0
  fi

  if [[ ! -f "${pkg_config}" ]] || ! _melos_snapshot_path "${root}" >/dev/null; then
    _run_workspace_pub_get "${root}" "${stamp}"
    ENSURE_PUB_GET_SKIPPED=0
    unset PUB_OFFLINE
    return 0
  fi

  local input_mtime
  input_mtime="$(_workspace_pubspec_inputs_mtime "${root}")"
  if [[ ! -f "${stamp}" || "${input_mtime}" -gt "$(cat "${stamp}")" ]]; then
    _run_workspace_pub_get "${root}" "${stamp}"
    ENSURE_PUB_GET_SKIPPED=0
    unset PUB_OFFLINE
    return 0
  fi

  echo "Workspace dependencies up to date; skipping pub get."
  ENSURE_PUB_GET_SKIPPED=1
  export PUB_OFFLINE=1
}

_melos_snapshot_path() {
  local root="$1"
  local dir="${root}/.dart_tool/pub/bin/melos"
  local snap

  shopt -s nullglob
  local snaps=("${dir}"/melos.dart*.snapshot)
  shopt -u nullglob

  if ((${#snaps[@]} == 0)); then
    return 1
  fi

  printf '%s\n' "${snaps[0]}"
}

_workspace_pubspec_inputs_mtime() {
  local root="$1"
  local newest=0
  local path mtime

  for path in \
    "${root}/pubspec.yaml" \
    "${root}/pubspec.lock" \
    "${root}/pubspec_overrides.yaml" \
    "${root}/mobile/pubspec.yaml" \
    "${root}/mobile/pubspec_overrides.yaml"; do
    [[ -f "${path}" ]] || continue
    mtime="$(stat -c %Y "${path}" 2>/dev/null || stat -f %m "${path}")"
    if (( mtime > newest )); then
      newest="${mtime}"
    fi
  done

  echo "${newest}"
}

_run_workspace_pub_get() {
  local root="$1"
  local stamp="$2"
  local input_mtime

  echo "Refreshing workspace dependencies..."
  (cd "${root}" && dart pub get)
  input_mtime="$(_workspace_pubspec_inputs_mtime "${root}")"
  mkdir -p "$(dirname "${stamp}")"
  echo "${input_mtime}" >"${stamp}"
}
