# Relay-scheduled notifications (cron)

## Why

Several product areas need notifications at a **future time** (payment due dates, proposal response deadlines, invitation expiry). Tasks `housing-plan-proposal-offer-and-responses` **1.4b** and `contacts-module` **3.7** currently specify **local** notification scheduling, but that approach cannot guarantee timely delivery when the app stays closed, and cannot centrally **cancel or reschedule** when shared state changes unless the app runs again. Payment-date reminders (`housing-unified-expense-entry` D.3) were deferred for the same reason.

This change defines a **relay cron** that materializes fire times server-side, dispatches **content-free wake pushes**, and relies on clients to **reconcile** schedules when authoritative events occur.

## What Changes

- **New:** Relay cron + generic `scheduled_notification_*` tables (housing payment, proposal deadline, invitation expiry).
- **New:** Client reconciliation envelopes with minimal relay-visible metadata.
- **Replaces:** Local notification scheduling for **1.4b**, **3.7**, and housing **D.3** payment reminders (before-date **and** overdue).
- **New:** Overdue **Accepted expenses** journal cards (orange, non-navigable).
- **Delta:** `relay-state-schema-and-retention` — fifth data category; **scheduling instants** (dates without amounts or labels) explicitly allowed.
- **Out of scope:** Web closed-app delivery; trial/licensing/car-sharing schedulers.

## Capabilities

### New Capabilities

- `housing-fixed-expense-payment-reminders`: Fixed recurring lines, sliding-window periods, coverage with carry, E.1–E.4 + published coverage, unanimity-sender rule.
- `scheduling-deadline-and-invitation-reminders`: Proposal deadline + Contacts invitation expiry via relay (replaces local scheduling in 1.4b / 3.7).
- `recipient-notification-timezone`: IANA timezone per routing id; activation + settings triggers; relay fire-time computation.
- `relay-scheduled-notification-jobs`: Cron, tables, ingest, wake dispatch, metrics.

### Modified Capabilities

- `relay-state-schema-and-retention`: Fifth category; scheduling timestamps permitted.
- `notification-permission-management`: Housing payment-reminder category; enable Contacts invitation-expiration switch when relay path ships.
- `closed-app-push-delivery`: Wake on cron fire (unchanged push payload).

## Impact

| Area | Impact |
|------|--------|
| `relay/` | Release + audit — migration, cron, ingest |
| `mobile/` | Reconciliation senders; reminder import builders; **remove** planned local-scheduling service for 1.4b/3.7/D.3 |
| `openspec/changes/housing-plan-proposal-offer-and-responses/tasks.md` | 1.4b → relay (task note at implementation) |
| `openspec/changes/contacts-module/tasks.md` | 3.7 → relay (task note at implementation) |

## Product decisions (2026-06-17)

| # | Decision |
|---|----------|
| 1 | Relay cron **replaces** local scheduling for payment reminders, proposal deadlines, and invitation expiry |
| 2 | Tiered before-date: W&lt;20 → J−2,**J**; 20≤W≤40 → J−4,J−2,**J**; W&gt;40 → J−6,J−2,**J**; all at **14:00** local; relay **IANA timezone** |
| 3 | **Overdue** at **14:00** local on day after due |
| 4 | Scheduling **dates/timestamps** on relay acceptable without amounts or labels |
| 5 | **Web** out of scope |
| 6 | Coverage = published sum per **sliding recurrence period** vs `unitMinor(line)`, with **carry-forward** between periods |
| 7 | `everyNDays` uses **sliding window** (anchor + n days) |
| 8 | Housing E.1–E.4 and expense publish: **only** the client establishing unanimity reconciles, same send as vote broadcast |
| 9 | Before-date → payment responsible only (or all if default); **overdue → always all roster** |
| 10 | Overdue → orange journal card; copy uses **complété** / **completed** (partial payment still overdue) |
