#!/usr/bin/env python3
"""Append agent transcript lines to dev-ideas/agent-transcripts/ mirror.

Fails loudly (non-zero exit) on missing input or I/O errors — never silent skip.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

_SESSION_ID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)
_NNN_RE = re.compile(r"^(\d{3})_")


def _repo_root(explicit: Path | None) -> Path:
    return explicit.resolve() if explicit else Path(__file__).resolve().parent.parent


def _read_text(*, text: str | None, text_file: Path | None) -> str:
    if text is not None:
        return text
    if text_file is not None:
        try:
            return text_file.read_text(encoding="utf-8")
        except OSError as exc:
            raise SystemExit(f"error: cannot read {text_file}: {exc}") from exc
    if sys.stdin.isatty():
        raise SystemExit(
            "error: provide --text, --text-file, or pipe message on stdin",
        )
    return sys.stdin.read()


def _resolve_log_path(root: Path, day: str, session_id: str) -> Path:
    dir_path = root / "dev-ideas" / "agent-transcripts" / day
    try:
        dir_path.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise SystemExit(f"error: cannot create {dir_path}: {exc}") from exc

    matches = sorted(dir_path.glob(f"*_{session_id}.jsonl"))
    if matches:
        return matches[0]

    max_n = 0
    for path in dir_path.glob("*.jsonl"):
        match = _NNN_RE.match(path.name)
        if match:
            max_n = max(max_n, int(match.group(1)))
    return dir_path / f"{max_n + 1:03d}_{session_id}.jsonl"


def _append_line(log_path: Path, role: str, text: str) -> None:
    if role == "assistant" and not text:
        raise SystemExit("error: refuse to append empty assistant message")

    line = {
        "role": role,
        "message": {"content": [{"type": "text", "text": text}]},
    }
    try:
        with log_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(line, ensure_ascii=False) + "\n")
    except OSError as exc:
        raise SystemExit(f"error: cannot append to {log_path}: {exc}") from exc


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Append one or two JSONL lines to dev-ideas/agent-transcripts/.",
    )
    parser.add_argument(
        "--session-id",
        required=True,
        help="Cursor agent transcript UUID for this chat session",
    )
    parser.add_argument(
        "--date",
        default=date.today().isoformat(),
        help="Calendar date folder (YYYY-MM-DD, default: today)",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root (default: parent of tool/)",
    )
    parser.add_argument(
        "--role",
        choices=["user", "assistant"],
        help="Single-line mode: message role",
    )
    parser.add_argument("--text", help="Message body (alternative to --text-file/stdin)")
    parser.add_argument(
        "--text-file",
        type=Path,
        help="Read message body from file (alternative to --text/stdin)",
    )
    parser.add_argument(
        "--user-file",
        type=Path,
        help="Turn mode: read verbatim user message from this file",
    )
    parser.add_argument(
        "--assistant-file",
        type=Path,
        help="Turn mode: read full assistant reply from this file",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)

    session_id = args.session_id.strip()
    if not _SESSION_ID_RE.match(session_id):
        raise SystemExit(f"error: invalid --session-id: {session_id!r}")

    root = _repo_root(args.repo_root)
    log_path = _resolve_log_path(root, args.date, session_id)

    turn_mode = args.user_file is not None and args.assistant_file is not None
    single_mode = args.role is not None or args.text is not None or args.text_file is not None

    if not turn_mode and not single_mode and not sys.stdin.isatty():
        single_mode = True

    if turn_mode:
        if single_mode:
            raise SystemExit(
                "error: use either turn mode (--user-file/--assistant-file) "
                "or single mode (--role with text/stdin), not both",
            )
        user_text = _read_text(text=None, text_file=args.user_file)
        assistant_text = _read_text(text=None, text_file=args.assistant_file)
        _append_line(log_path, "user", user_text)
        _append_line(log_path, "assistant", assistant_text)
    elif single_mode:
        if args.role is None:
            raise SystemExit("error: single mode requires --role")
        text = _read_text(text=args.text, text_file=args.text_file)
        _append_line(log_path, args.role, text)
    else:
        raise SystemExit(
            "error: provide turn mode (--user-file and --assistant-file) "
            "or single mode (--role with --text, --text-file, or stdin)",
        )

    print(log_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
