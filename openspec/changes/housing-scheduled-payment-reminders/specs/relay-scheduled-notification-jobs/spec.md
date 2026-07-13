## ADDED Requirements

### Requirement: Scheduled notification tables are an enumerated relay data category

The relay database SHALL support a fifth data category: **scheduled notification housekeeping**, in addition to routing, idempotency, undelivered envelopes, and operational housekeeping.

Rows in this category MAY contain only:

- opaque `BYTEA` scope identifiers (`scope_key`, `period_key`, `fire_id`, `target_id`);
- enumerated `domain` and `reminder_kind`;
- timestamps (`fire_at`, `due_at`, `bound_at`, `fired_at`, `cancelled_at`, audit timestamps);
- monotonic `generation` counters and status enums;
- **IANA time zone ids** per recipient routing identity (`recipient_notification_timezone`).

Scheduling instants paired with opaque ids are **explicitly permitted**. IANA ids are operational scheduling metadata, not user-facing profile text. Tables SHALL NOT contain expense amounts, descriptions, participant display names, or other user-facing plaintext.

#### Scenario: Schema dump shows no business plaintext

- **WHEN** an auditor inspects `scheduled_notification_targets` and `scheduled_notification_fires`
- **THEN** no column decodes to user-facing expense or contact content

---

### Requirement: Reminder cron runs on a documented cadence

The relay SHALL run a reminder cron job on a documented interval (default: every five minutes, configurable by environment variable). Each run SHALL:

1. Select pending rows from `scheduled_notification_fires` with `fire_at <= now()` using row-level locking suitable for concurrent relay instances.
2. Transition selected rows to `fired` with `fired_at`.
3. Dispatch wake pushes to every non-expired routing push token for `recipient_routing_id`.
4. Persist encrypted `scheduled_reminder_due` envelopes per recipient.

#### Scenario: Due fire is processed once

- **WHEN** a fire row is due and the cron claims it
- **THEN** exactly one wake dispatch attempt set is recorded for that `fire_id`

#### Scenario: Late cron still fires

- **WHEN** the relay was down across `fire_at`
- **THEN** the fire is processed on the first cron tick after recovery

---

### Requirement: Housing payment fire times are computed on the relay

For `domain = housing_payment`, the relay SHALL compute `fire_at` in UTC from:

- `period_due_at` → calendar due date **J** in recipient IANA timezone,
- `recurrence_period_days` (**W**) on the target row,
- **Before-date** per tier (all at 14:00:00 local, never midnight):
  - W < 20 → J−2 and **J** (due day)
  - 20 ≤ W ≤ 40 → J−4, J−2, and **J**
  - W > 40 → J−6, J−2, and **J**
- **Overdue:** 14:00:00 local on J+1.

Fires whose local instant is already past when materialized SHALL be omitted.

When `iana_timezone` is missing for a recipient, the relay SHALL defer creating pending fire rows until registration.

When `iana_timezone` is updated, the relay SHALL recompute all **pending** housing payment fire rows for that recipient.

#### Scenario: W=30 schedules J−4, J−2, and due-day J at 14:00

- **WHEN** J = 2026-07-20, W = 30, timezone `America/Toronto`
- **THEN** before-date fires are 2026-07-16 14:00, 2026-07-18 14:00, and 2026-07-20 14:00 Toronto (UTC stored)

#### Scenario: W=14 schedules J−2 and due-day J

- **WHEN** J = 2026-07-20, W = 14
- **THEN** before-date fires at 2026-07-18 14:00 and 2026-07-20 14:00 local

#### Scenario: Timezone change shifts pending fires

- **WHEN** a recipient updates IANA timezone and pending before-date fires exist
- **THEN** `fire_at` values are recomputed to 14:00 in the new zone on the same J−k calendar dates

---

### Requirement: Reconciliation ingest is authenticated and idempotent

The relay SHALL expose an authenticated ingest path (HTTP handler or envelope admission hook) that applies schedule upsert/cancel messages for domains `housing_payment`, `housing_proposal_deadline`, and `contacts_invitation_expiry`.

Ingest SHALL:

- reject unauthenticated senders;
- map participant ids to `recipient_routing_id` using established routing relationships only;
- ignore stale updates when `generation` is older than the stored generation for the same `plan_id`;
- emit metrics: reconciliations accepted, fires created, fires cancelled.

#### Scenario: Stale generation is ignored

- **WHEN** a reconciliation arrives with `generation` 4 but the relay already stores `generation` 5 for that plan
- **THEN** the relay rejects or no-ops the update without deleting newer fires

---

### Requirement: Reminder cron metrics are observable

The relay SHALL increment counters for: `reminder_fires_due`, `reminder_fires_fired`, `reminder_wake_dispatch_success`, `reminder_wake_dispatch_failure`, and expose them on the existing private metrics surface.

#### Scenario: Operator can detect stuck cron

- **WHEN** pending fires exist with `fire_at` older than two cron intervals
- **THEN** an operator alert rule can fire from metrics or logs
