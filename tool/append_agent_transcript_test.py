#!/usr/bin/env python3
"""Unit tests for tool/append_agent_transcript.py (stdlib only)."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from append_agent_transcript import _resolve_log_path, main


class AppendAgentTranscriptTest(unittest.TestCase):
    def test_allocates_next_nnn_for_new_session(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            day_dir = root / "dev-ideas" / "agent-transcripts" / "2026-06-20"
            day_dir.mkdir(parents=True)
            (day_dir / "001_aaa.jsonl").write_text("", encoding="utf-8")
            (day_dir / "003_bbb.jsonl").write_text("", encoding="utf-8")

            path = _resolve_log_path(
                root,
                "2026-06-20",
                "c9fec28e-b958-46e9-b716-a37ae590b452",
            )
            self.assertEqual(
                path.name,
                "004_c9fec28e-b958-46e9-b716-a37ae590b452.jsonl",
            )

    def test_reuses_existing_session_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            day_dir = root / "dev-ideas" / "agent-transcripts" / "2026-06-20"
            day_dir.mkdir(parents=True)
            existing = day_dir / "007_c9fec28e-b958-46e9-b716-a37ae590b452.jsonl"
            existing.write_text("", encoding="utf-8")

            path = _resolve_log_path(
                root,
                "2026-06-20",
                "c9fec28e-b958-46e9-b716-a37ae590b452",
            )
            self.assertEqual(path, existing)

    def test_turn_mode_appends_user_and_assistant(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            user_file = root / "user.txt"
            assistant_file = root / "assistant.txt"
            user_file.write_text("hello user", encoding="utf-8")
            assistant_file.write_text("hello assistant", encoding="utf-8")

            exit_code = main(
                [
                    "--repo-root",
                    str(root),
                    "--date",
                    "2026-06-20",
                    "--session-id",
                    "100f4394-bb18-46b3-8d97-7c1729567414",
                    "--user-file",
                    str(user_file),
                    "--assistant-file",
                    str(assistant_file),
                ],
            )
            self.assertEqual(exit_code, 0)

            log_path = (
                root
                / "dev-ideas"
                / "agent-transcripts"
                / "2026-06-20"
                / "001_100f4394-bb18-46b3-8d97-7c1729567414.jsonl"
            )
            lines = log_path.read_text(encoding="utf-8").strip().splitlines()
            self.assertEqual(len(lines), 2)
            user_line = json.loads(lines[0])
            assistant_line = json.loads(lines[1])
            self.assertEqual(user_line["role"], "user")
            self.assertEqual(
                user_line["message"]["content"][0]["text"],
                "hello user",
            )
            self.assertEqual(assistant_line["role"], "assistant")
            self.assertEqual(
                assistant_line["message"]["content"][0]["text"],
                "hello assistant",
            )

    def test_rejects_empty_assistant(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.assertRaises(SystemExit):
                main(
                    [
                        "--repo-root",
                        str(root),
                        "--date",
                        "2026-06-20",
                        "--session-id",
                        "100f4394-bb18-46b3-8d97-7c1729567414",
                        "--role",
                        "assistant",
                        "--text",
                        "",
                    ],
                )


if __name__ == "__main__":
    unittest.main()
