#!/usr/bin/env bash
# Seed a QA scenario on the running Android emulator (debug APK).
#
# Clears app data, writes the scenario marker consumed by bootstrap
# ([maybeApplyQaAndroidSeed]), cold-starts the app once, then stops it so Maestro
# can relaunch without clearing Drift state.
#
# Usage: ./tool/seed_qa_scenario.sh settlement_window_open

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=qa_env.sh
source "${ROOT}/tool/qa_env.sh"

qa_export_android_sdk_paths
qa_require_command adb

SCENARIO_ID="${1:-}"
if [[ -z "${SCENARIO_ID}" ]]; then
  echo "Usage: $0 <scenario-id>" >&2
  echo "Example: $0 settlement_window_open" >&2
  exit 1
fi

MANIFEST="${ROOT}/qa/scenarios/${SCENARIO_ID}.yaml"
if [[ -f "${MANIFEST}" ]]; then
  SEED_ID="$(python3 "${ROOT}/tool/qa_scenario_manifest.py" "${MANIFEST}" seed)"
else
  # Multi-device role seeds (qa/multi_scenarios) use kQaScenarioIds directly.
  SEED_ID="${SCENARIO_ID}"
  if ! python3 - "${SEED_ID}" "${ROOT}" <<'PY'
import re, sys
from pathlib import Path
seed, root = sys.argv[1], Path(sys.argv[2])
text = (root / "mobile/lib/debug/qa_scenario_seed.dart").read_text(encoding="utf-8")
m = re.search(r"const kQaScenarioIds = <String>\{([^}]*)\}", text, re.DOTALL)
ids = {x.group(1) for x in re.finditer(r"'([^']+)'", m.group(1))} if m else set()
sys.exit(0 if seed in ids else 1)
PY
  then
    echo "Unknown scenario or seed id: ${SCENARIO_ID}" >&2
    exit 1
  fi
fi
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  SERIAL="${ANDROID_SERIAL}"
else
  SERIAL="$(qa_use_emulator_adb_serial)"
fi
ADB=(adb -s "${SERIAL}")

ACTIVITY="${COMPARTARENTA_QA_APP_ID}/com.compartarenta.compartarenta.MainActivity"

echo "Seeding ${SCENARIO_ID} on ${SERIAL} (marker seed=${SEED_ID})"
"${ADB[@]}" shell pm clear "${COMPARTARENTA_QA_APP_ID}" >/dev/null

MARKER_NAME="compartarenta_qa_seed"
MARKER_DIR="app_flutter"
"${ADB[@]}" shell "run-as ${COMPARTARENTA_QA_APP_ID} mkdir ${MARKER_DIR}" >/dev/null 2>&1 || true
if ! "${ADB[@]}" shell "run-as ${COMPARTARENTA_QA_APP_ID} sh -c 'echo ${SEED_ID} > ${MARKER_DIR}/${MARKER_NAME}'"; then
  echo "run-as seed marker failed (debug APK required)." >&2
  exit 1
fi

"${ADB[@]}" shell am start -n "${ACTIVITY}" -W >/dev/null
qa_wait_for_boot_completed "${SERIAL}"

for _ in $(seq 1 30); do
  if "${ADB[@]}" logcat -d 2>/dev/null | grep -q "qa seed: applied scenario ${SEED_ID}"; then
    echo "Seed applied (${SEED_ID})."
    "${ADB[@]}" shell am force-stop "${COMPARTARENTA_QA_APP_ID}" >/dev/null || true
    exit 0
  fi
  sleep 2
done

echo "Timed out waiting for QA seed log line on ${SERIAL}." >&2
echo "Check: adb -s ${SERIAL} logcat -d | grep 'qa seed'" >&2
exit 1
