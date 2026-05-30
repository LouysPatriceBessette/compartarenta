#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${DIR}"

./tool/flutterw pub get

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

should_filter_android_logs=true
install_mobile_target=true
for ((i = 0; i < ${#extra[@]}; i++)); do
  if [[ "${extra[i]}" == "-d" && $((i + 1)) -lt ${#extra[@]} ]]; then
    case "${extra[i + 1]}" in
      chrome|web-server|linux|windows|macos)
        should_filter_android_logs=false
        install_mobile_target=false
        ;;
    esac
  fi
done

run_args=(
  run
  --flavor dev
  --dart-define=ENV=dev
  --dart-define="API_BASE_URL=${API_BASE_URL_VALUE}"
)
# Reinstall native plugins (shared_preferences, path_provider) after plugin or Gradle changes.
if [[ "${install_mobile_target}" == "true" ]]; then
  run_args+=(--uninstall-first)
fi
run_args+=("${extra[@]}")

if [[ "${COMPARTARENTA_RUN_RAW_LOGS:-0}" == "1" || "${should_filter_android_logs}" != "true" ]]; then
  ./tool/flutterw "${run_args[@]}"
else
  printf -v quoted_run_cmd '%q ' ./tool/flutterw "${run_args[@]}"
  raw_output_file="$(mktemp)"
  cleanup() {
    rm -f "${raw_output_file}"
  }
  trap cleanup EXIT

  script -qefc "${quoted_run_cmd}" /dev/null >"${raw_output_file}" 2>&1 &
  runner_pid=$!

  tail -n +1 -F --pid="${runner_pid}" "${raw_output_file}" \
    | bash ./tool/filter_flutter_run_output.sh
  wait "${runner_pid}"
fi
