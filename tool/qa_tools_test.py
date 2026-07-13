#!/usr/bin/env python3
"""Unit tests for QA tooling scripts (stdlib only)."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from qa_housing_payment_reminder_dates import first_before_due_fire_iso
from qa_run_report import render_html
from qa_scenario_manifest import list_scenario_ids, parse_manifest, validate_scenarios
from verify_qa_semantics import collect_dart_ids, collect_maestro_ids, verify_semantics


class QaScenarioManifestTest(unittest.TestCase):
    def test_parse_manifest_strips_quotes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "demo.yaml"
            path.write_text(
                'id: demo\n'
                'device_date: "2027-08-11T09:00:00"\n'
                'timezone: America/Toronto\n',
                encoding="utf-8",
            )
            fields = parse_manifest(path)
            self.assertEqual(fields["id"], "demo")
            self.assertEqual(fields["device_date"], "2027-08-11T09:00:00")

    def test_validate_scenarios_detects_missing_flow(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scenarios = root / "qa" / "scenarios"
            scenarios.mkdir(parents=True)
            (scenarios / "demo.yaml").write_text(
                "\n".join(
                    [
                        "id: demo",
                        'device_date: "2027-08-11T09:00:00"',
                        "timezone: America/Toronto",
                        "seed: demo",
                        "flow: qa/flows/missing.yaml",
                    ],
                ),
                encoding="utf-8",
            )
            seed = root / "mobile" / "lib" / "debug"
            seed.mkdir(parents=True)
            (seed / "qa_scenario_seed.dart").write_text(
                "const kQaScenarioIds = <String>{'demo'};",
                encoding="utf-8",
            )
            errors = validate_scenarios(root)
            self.assertTrue(any("flow file missing" in err for err in errors))

    def test_list_scenario_ids_sorted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scenarios = root / "qa" / "scenarios"
            scenarios.mkdir(parents=True)
            (scenarios / "b.yaml").write_text("id: b\n", encoding="utf-8")
            (scenarios / "a.yaml").write_text("id: a\n", encoding="utf-8")
            self.assertEqual(list_scenario_ids(root), ["a", "b"])


class VerifyQaSemanticsTest(unittest.TestCase):
    def test_maestro_id_must_exist_in_dart(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            flows = root / "qa" / "flows"
            flows.mkdir(parents=True)
            (flows / "demo.yaml").write_text(
                '- extendedWaitUntil:\n    visible:\n      id: "qa-demo-missing"\n',
                encoding="utf-8",
            )
            lib = root / "mobile" / "lib" / "screens"
            lib.mkdir(parents=True)
            (lib / "screen.dart").write_text(
                "identifier: 'qa-demo-present'",
                encoding="utf-8",
            )
            errors, warnings = verify_semantics(root, warn_orphans=False)
            self.assertTrue(any("qa-demo-missing" in err for err in errors))

    def test_aligned_ids_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            flows = root / "qa" / "flows"
            flows.mkdir(parents=True)
            (flows / "demo.yaml").write_text('id: "qa-demo-tile"\n', encoding="utf-8")
            lib = root / "mobile" / "lib"
            lib.mkdir(parents=True)
            (lib / "screen.dart").write_text(
                "identifier: 'qa-demo-tile'",
                encoding="utf-8",
            )
            errors, _warnings = verify_semantics(root, warn_orphans=False)
            self.assertEqual(errors, [])

    def test_car_sharing_excluded_from_dart_scan(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            flows = root / "qa" / "flows"
            flows.mkdir(parents=True)
            (flows / "demo.yaml").write_text('id: "qa-vehicle-only"\n', encoding="utf-8")
            car = root / "mobile" / "lib" / "screens" / "car_sharing"
            car.mkdir(parents=True)
            (car / "plan.dart").write_text(
                "identifier: 'qa-vehicle-only'",
                encoding="utf-8",
            )
            errors, _warnings = verify_semantics(root, warn_orphans=False)
            self.assertTrue(any("qa-vehicle-only" in err for err in errors))


class QaHousingPaymentReminderDatesTest(unittest.TestCase):
    def test_first_before_due_july_anchor(self) -> None:
        # Anchor 2026-07-13 → due 2026-08-01 → J−4 @ 14:00 Toronto + 5 min margin
        fire = first_before_due_fire_iso(
            anchor_iso="2026-07-13T09:00:00",
            timezone="America/Toronto",
            recurrence_day=1,
        )
        self.assertTrue(fire.startswith("2026-07-28T14:05:00"))


class QaRunReportTest(unittest.TestCase):
    def test_render_html_includes_scenario_rows(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp)
            scenario_dir = run_dir / "demo"
            scenario_dir.mkdir()
            (scenario_dir / "01_home.png").write_bytes(b"png")
            data = {
                "run_id": "run-test",
                "started_at": "2027-01-01T00:00:00Z",
                "finished_at": "2027-01-01T00:05:00Z",
                "scenarios": [
                    {"id": "demo", "status": "passed", "artifact_dir": "demo"},
                ],
            }
            html = render_html(run_dir, data)
            self.assertIn("demo", html)
            self.assertIn("passed", html)
            self.assertIn("01_home.png", html)


if __name__ == "__main__":
    unittest.main()
