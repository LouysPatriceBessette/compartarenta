#!/usr/bin/env python3
"""Compute housing payment reminder QA dates (mirrors relay scheduling/firetimes.go)."""

from __future__ import annotations

import argparse
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo


def before_date_offsets(recurrence_period_days: int) -> list[int]:
    if recurrence_period_days < 20:
        return [2]
    if recurrence_period_days <= 40:
        return [4, 2]
    return [6, 2]


def monthly_due_at_local(at_local: datetime, recurrence_day: int) -> datetime:
    """Calendar instant J (due) for monthly recurrence containing [at_local]."""
    clamped = min(max(recurrence_day, 1), 28)
    y, m = at_local.year, at_local.month
    period_start = datetime(y, m, clamped, tzinfo=at_local.tzinfo)
    if at_local < period_start:
        if m == 1:
            y -= 1
            m = 12
        else:
            m -= 1
        period_start = datetime(y, m, clamped, tzinfo=at_local.tzinfo)
    if m == 12:
        next_start = datetime(y + 1, 1, clamped, tzinfo=at_local.tzinfo)
    else:
        next_start = datetime(y, m + 1, clamped, tzinfo=at_local.tzinfo)
    return next_start


def before_due_fires_local(
    *,
    due_local: datetime,
    recurrence_period_days: int,
    materialize_after: datetime,
) -> list[datetime]:
    j = due_local.date()
    out: list[datetime] = []
    for k in before_date_offsets(recurrence_period_days):
        fire = datetime(
            j.year,
            j.month,
            j.day,
            14,
            0,
            0,
            tzinfo=due_local.tzinfo,
        ) - timedelta(days=k)
        if fire > materialize_after:
            out.append(fire)
    return out


def first_before_due_fire_iso(
    *,
    anchor_iso: str,
    timezone: str,
    recurrence_day: int = 1,
    recurrence_period_days: int = 30,
    fire_index: int = 0,
    margin_minutes: int = 5,
) -> str:
    tz = ZoneInfo(timezone)
    anchor = datetime.fromisoformat(anchor_iso)
    if anchor.tzinfo is None:
        anchor = anchor.replace(tzinfo=tz)
    else:
        anchor = anchor.astimezone(tz)

    due = monthly_due_at_local(anchor, recurrence_day)
    fires = before_due_fires_local(
        due_local=due,
        recurrence_period_days=recurrence_period_days,
        materialize_after=anchor - timedelta(seconds=1),
    )
    if not fires:
        raise ValueError(
            f"no before_due fire after anchor {anchor_iso} "
            f"(due={due.isoformat()})",
        )
    if fire_index < 0 or fire_index >= len(fires):
        raise IndexError(
            f"fire_index {fire_index} out of range (0..{len(fires) - 1})",
        )
    fire = fires[fire_index] + timedelta(minutes=margin_minutes)
    return fire.isoformat(timespec="seconds")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--anchor", required=True, help="Phase-1 anchor ISO datetime")
    parser.add_argument("--timezone", default="America/Toronto")
    parser.add_argument("--recurrence-day", type=int, default=1)
    parser.add_argument("--recurrence-period-days", type=int, default=30)
    parser.add_argument("--fire-index", type=int, default=0)
    parser.add_argument("--margin-minutes", type=int, default=5)
    args = parser.parse_args()
    print(
        first_before_due_fire_iso(
            anchor_iso=args.anchor,
            timezone=args.timezone,
            recurrence_day=args.recurrence_day,
            recurrence_period_days=args.recurrence_period_days,
            fire_index=args.fire_index,
            margin_minutes=args.margin_minutes,
        ),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
