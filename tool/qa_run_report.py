#!/usr/bin/env python3
"""Generate an aggregated HTML report for a qa:run-all-scenarios run."""

from __future__ import annotations

import argparse
import html
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def load_results(run_dir: Path) -> dict:
    results_path = run_dir / "results.json"
    if not results_path.is_file():
        raise FileNotFoundError(f"missing {results_path}")
    return json.loads(results_path.read_text(encoding="utf-8"))


def list_screenshots(scenario_dir: Path) -> list[Path]:
    if not scenario_dir.is_dir():
        return []
    shots = [
        p
        for p in scenario_dir.iterdir()
        if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    ]
    return sorted(shots, key=lambda p: p.name)


def rel_href(from_dir: Path, target: Path) -> str:
    return html.escape(target.relative_to(from_dir).as_posix())


def render_html(run_dir: Path, data: dict) -> str:
    run_id = html.escape(str(data.get("run_id", run_dir.name)))
    started = html.escape(str(data.get("started_at", "")))
    finished = html.escape(str(data.get("finished_at", "")))
    scenarios = data.get("scenarios", [])

    passed = sum(1 for s in scenarios if s.get("status") == "passed")
    failed = sum(1 for s in scenarios if s.get("status") != "passed")
    total = len(scenarios)

    rows: list[str] = []
    for entry in scenarios:
        scenario_id = html.escape(str(entry.get("id", "")))
        status = str(entry.get("status", "unknown"))
        status_class = "pass" if status == "passed" else "fail"
        artifact_name = entry.get("artifact_dir") or scenario_id
        scenario_dir = run_dir / artifact_name
        error = entry.get("error")
        error_html = (
            f'<pre class="error">{html.escape(error)}</pre>' if error else ""
        )

        thumbs: list[str] = []
        for shot in list_screenshots(scenario_dir):
            href = rel_href(run_dir, shot)
            thumbs.append(
                f'<a href="{href}"><img src="{href}" alt="{html.escape(shot.name)}" '
                f'title="{html.escape(shot.name)}"></a>',
            )
        gallery = (
            f'<div class="gallery">{"".join(thumbs)}</div>'
            if thumbs
            else '<span class="muted">No screenshots</span>'
        )

        folder_link = ""
        if scenario_dir.is_dir():
            folder_link = (
                f'<a href="{html.escape(artifact_name)}/">artifacts</a>'
            )

        rows.append(
            f"""<tr>
  <td><code>{scenario_id}</code></td>
  <td class="{status_class}">{html.escape(status)}</td>
  <td>{folder_link}</td>
  <td>{gallery}{error_html}</td>
</tr>""",
        )

    body_rows = "\n".join(rows) if rows else "<tr><td colspan='4'>No scenarios</td></tr>"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bojairu QA run {run_id}</title>
  <style>
    body {{ font-family: system-ui, sans-serif; margin: 24px; color: #111; }}
    h1 {{ margin-bottom: 0.2em; }}
    .meta {{ color: #555; margin-bottom: 1.5em; }}
    .summary span {{ margin-right: 1.5em; }}
    .pass {{ color: #0a7a2f; font-weight: 600; }}
    .fail {{ color: #b00020; font-weight: 600; }}
    table {{ border-collapse: collapse; width: 100%; }}
    th, td {{ border: 1px solid #ddd; padding: 10px; vertical-align: top; }}
    th {{ background: #f5f5f5; text-align: left; }}
    .gallery {{ display: flex; flex-wrap: wrap; gap: 8px; margin-top: 6px; }}
    .gallery img {{ max-height: 160px; border: 1px solid #ccc; border-radius: 4px; }}
    .muted {{ color: #777; }}
    pre.error {{
      margin-top: 8px; padding: 8px; background: #fff3f3; border: 1px solid #f3c0c0;
      white-space: pre-wrap; font-size: 12px;
    }}
    code {{ font-size: 0.95em; }}
  </style>
</head>
<body>
  <h1>Bojairu QA run</h1>
  <p class="meta">Run id: <code>{run_id}</code><br>
  Started: {started or "—"}<br>
  Finished: {finished or "—"}</p>
  <p class="summary">
    <span><strong>{total}</strong> scenario(s)</span>
    <span class="pass">{passed} passed</span>
    <span class="fail">{failed} failed</span>
  </p>
  <table>
    <thead>
      <tr>
        <th>Scenario</th>
        <th>Status</th>
        <th>Folder</th>
        <th>Screenshots</th>
      </tr>
    </thead>
    <tbody>
{body_rows}
    </tbody>
  </table>
</body>
</html>
"""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "run_dir",
        type=Path,
        help="qa/artifacts/run-<timestamp>/ directory",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="HTML output path (default: <run_dir>/index.html)",
    )
    args = parser.parse_args()
    run_dir = args.run_dir.resolve()
    output = args.output or (run_dir / "index.html")

    try:
        data = load_results(run_dir)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if "finished_at" not in data or not data["finished_at"]:
        data["finished_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    html_text = render_html(run_dir, data)
    output.write_text(html_text, encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
