# shellcheck shell=bash
# Shared default for ENTITLEMENT_BASE_URL used by run_dev.sh and run_dev_web.sh.
#
# Override explicitly: ENTITLEMENT_BASE_URL=https://… ./tool/melosw run run:dev
# Disable client entitlement calls: ENTITLEMENT_BASE_URL= ./tool/melosw run run:dev

entitlement_base_url_default() {
  local api_base_url="${1:?api base url required}"
  if [[ -n "${ENTITLEMENT_BASE_URL:-}" ]]; then
    printf '%s' "${ENTITLEMENT_BASE_URL}"
    return
  fi
  case "${api_base_url}" in
    https://sync.incoherences.org)
      printf '%s' 'https://license.incoherences.org'
      ;;
    http://127.0.0.1:8080 | http://localhost:8080)
      printf '%s' 'http://127.0.0.1:8081'
      ;;
    *)
      printf '%s' ''
      ;;
  esac
}
