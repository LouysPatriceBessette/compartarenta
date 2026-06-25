#!/usr/bin/env bash
# Finalize a qa:run-all-scenarios run: results.json timestamp, HTML report, clock restore.
#
# Usage: ./tool/qa_finalize_run.sh <run-dir> [--skip-restore]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RUN_DIR="${1:-}"
SKIP_RESTORE=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-restore) SKIP_RESTORE=1 ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ -z "${RUN_DIR}" ]]; then
  echo "Usage: $0 <run-dir> [--skip-restore]" >&2
  exit 1
fi

if [[ ! -d "${RUN_DIR}" ]]; then
  echo "Run directory not found: ${RUN_DIR}" >&2
  exit 1
fi

FINISHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "${RUN_DIR}" "${FINISHED_AT}" <<'PY'
import json
import sys
from pathlib import Path

run_dir, finished_at = sys.argv[1:3]
path = Path(run_dir) / "results.json"
data = json.loads(path.read_text(encoding="utf-8"))
data["finished_at"] = finished_at
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

REPORT_PATH="$(python3 "${ROOT}/tool/qa_run_report.py" "${RUN_DIR}")"

if [[ "${SKIP_RESTORE}" -eq 0 ]]; then
  "${ROOT}/tool/restore_android_date.sh"
fi

echo "${REPORT_PATH}"
