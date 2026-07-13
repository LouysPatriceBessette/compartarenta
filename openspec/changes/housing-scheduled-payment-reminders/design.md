# Design — relay-scheduled notifications (cron)

## Context

### Existing scheduled-notification inventory

Notifications **not** fired directly by a peer envelope arriving in the inbox (time-based, local schedule, or server cron). User-action-triggered notifications (new proposal, expense review, activation fan-out, etc.) are **out of scope** for this table.

| # | Source change | Notification | Intended recipients | Send condition | Lead / cadence | Scheduler location |
|---|---------------|--------------|---------------------|----------------|----------------|-------------------|
| 1 | … | **Before-date** | … | … | Tiered: W&lt;20 → J−2,**J**; 20–40 → J−4,J−2,**J**; W&gt;40 → J−6,J−2,**J**; all **14:00** local | **Relay cron** |
| 2 | `housing-unified-expense-entry` design | **Overdue** payment reminder | Per payment-responsible rules | Uncovered after due date | **14:00** local, day after due | **Relay cron** |
| 3 | `housing-plan-proposal-offer-and-responses` tasks **1.4b** | Proposal **response deadline** reminder | Open `revisionId`: recipients and/or author per product table | Before `expiresAt` | **Indéfini** — product table | **Relay cron** (replaces local; author registers on dispatch) |
| 4 | `contacts-module` tasks **3.7** | **Invitation expiry** reminder (`before_expiry`, outgoing pending) | Inviter | Before invitation `expiresAt` | Validity 3h→T−30m; 8h→T−1h; 24h→T−2h; 48h→T−4h (wall-clock from `expiresAt`) | **Relay cron** (inviter registers `fires[]` on create) — **client + ingest deferred** |
| 5 | `notification-permission-management` / Contacts Settings | **Invitation expiration** (`expired`, unconsumed) | Inviter | Exactly at `expiresAt` | Same registration as #4; `reminder_kind=expired` | **Relay cron** — **client + ingest deferred** |
| 6 | `licensing-trial-and-plan-entitlement` `trial-notifications-and-timeline` | Trial start | Relevant participants | First qualifying realized-expense sync starts trial | At trial start | **Indéfini** (client-side implied) |
| 7 | Same | Trial **one-week** reminder | Relevant participants | Trial has **7 days** remaining | Once at −7d | **Defined** |
| 8 | Same | Trial **final three days** | Relevant participants | Days 3, 2, 1 remaining inclusive | Daily | **Defined** |
| 9 | `delinquency-grace-readonly-and-export` | Delinquency **daily** grace | **All** participants | Plan in grace for unpaid required license | Daily until restored or grace ends | **Defined** (1-week grace) |
| 10 | `vehicle-module` `vehicle-consumption-metrics` | Full-tank **suggestion** | Owner who recorded fuel | Non-full entry **and** last full-tank anchor **> 1 month** | On entry (not periodic) | Client schedules/shows at event |
| 11 | `housing-active-agreement-operations` qa-pass-3 | Payment-responsible reminders (D.3) | Per #1–2 | Not implemented | — | Marked done for peer-submit only; D.3 still **deferred** |

### Constraints

- `relay-state-schema-and-retention` today allows only four table categories; forbids cleartext **dates** among user payload fields.
- `closed-app-push-delivery`: wake payloads are `v` + `kind` + routing id only; web has **no** closed-app push.
- Housing plan lines and recurrence live in **client ciphertext** today; task `housing-active-agreement-operations` **3.9** (relay-visible metadata for expense decisions) is still **open**.
- Coverage math exists client-side for **calendar-month chart** (`expense_payment_chart_carry.dart`); reminder coverage needs **sliding recurrence periods** with carry adapted from that model.
- **No** `zonedSchedule` / local scheduling implementation exists in the codebase today; 1.4b remains product-table unfinished; invitation expiry (#4–#5) lead times and copy are **specified** (2026-07-13) but **client + relay `fires[]` ingest are deferred**.

## Goals / Non-Goals

**Goals:**

- Materialize future **fire times** on the relay for: housing payment reminders (before-date + overdue), proposal deadline reminders, invitation expiry reminders.
- **Reconcile** when authoritative events occur (housing: unanimity-establishing client only; proposal: author on dispatch; invitation: inviter on create).
- Fire due rows via **relay cron** → wake push → client builds localized notification.
- Respect agreement `periodEnd` for housing payment reminders.
- Honor notification master switch + per-category prefs.

**Non-Goals:**

- Budget-cap and one-off housing lines.
- Trial / licensing / vehicle module schedulers.
- **Web** closed-app scheduled delivery.
- Plaintext expense titles, amounts, or payer names on the relay.

## Decisions

### D1 — Two-layer relay model (generic)

| Layer | Table | Purpose |
|-------|-------|---------|
| **Targets** | `scheduled_notification_targets` | One row per logical reminder unit (domain + scope keys + recipient) |
| **Fire queue** | `scheduled_notification_fires` | One row per concrete `fire_at` the cron dispatches |

`domain` enum examples: `housing_payment`, `housing_proposal_deadline`, `contacts_invitation_expiry`.

Reconciliation **deletes** pending fires for affected targets and **re-inserts** computed fires.

### D2 — Reconciliation senders (by domain)

| Domain | Who sends | When |
|--------|-----------|------|
| Housing E.1–E.4, coverage B | Client establishing **unanimity** | Same send path as deciding vote / final accept broadcast |
| Proposal deadline | **Author** | Proposal dispatch |
| Invitation expiry | **Inviter** | Invitation create; cancel on revoke/use/extend |

| Domain | Before-date recipients | Overdue recipients |
|--------|------------------------|-------------------|
| Payment responsible = **All** | Every roster participant | Every roster participant |
| Single designated payer **P** | **P only** | **Every** roster participant (ignore designation) |

Overdue processing also appends an **orange non-navigable card** to the local **Accepted expenses** journal list on each device.

### D3 — Cron couples to existing sweeper infrastructure

Add `reminder_cron` (or extend `sweeper.Loop` with a second ticker) on a documented cadence (e.g. every 1–5 minutes). Query `scheduled_notification_fires WHERE status = 'pending' AND fire_at <= now()` with `FOR UPDATE SKIP LOCKED`, mark `fired`, dispatch wake push per recipient.

### D-invitation — Invitation expiry fire times (client-supplied)

Unlike housing payment (relay computes 14:00 local from `due_at` + W), domain `contacts_invitation_expiry` uses **client-computed wall-clock** `fire_at` values relative to invitation `expiresAt`:

| Validity | `before_expiry` | `expired` |
|----------|-----------------|-----------|
| 3h | `expiresAt − 30m` | `expiresAt` |
| 8h | `expiresAt − 1h` | `expiresAt` |
| 24h | `expiresAt − 2h` | `expiresAt` |
| 48h | `expiresAt − 4h` | `expiresAt` |

Omit past fires at registration. Cancel on used/revoked. Both kinds share Settings `notificationContactInvitationExpiration`.

**Implementation status:** product decisions locked in `scheduling-deadline-and-invitation-reminders`. Relay still needs a generic (or domain-specific) ingest that accepts client `fires[]` (schema `0003` already allows domain `contacts_invitation_expiry`). Ship in a later relay release + client work; not part of the housing-payment client path already shipped.

### D6 — Housing payment fire-time rules

**J** = due calendar date (`period_due_at` in recipient IANA tz). **W** = sliding-window length in days for the line.

**Before-date** (always 14:00:00 local on J−k; never midnight; **k = 0** is due day J):

| W | Fires |
|---|--------|
| W < 20 | J−2, **J** |
| 20 ≤ W ≤ 40 | J−4, J−2, **J** |
| W > 40 | J−6, J−2, **J** |

Example: J = 2026-07-20 → J−4 + 14h = 2026-07-16 14:00 local; due-day = 2026-07-20 14:00 local.

Skip any fire whose local instant is already in the past when materialized.

**Overdue:** 14:00:00 local on J+1 if still uncovered.

Relay converts local 14:00 → UTC for `fire_at`. W is supplied in schedule reconciliation per line (derived client-side from recurrence spec).

### D7 — Recipient timezone on relay

Table `recipient_notification_timezone` (`recipient_routing_id`, `iana_timezone`, `updated_at`).

| Trigger | Who |
|---------|-----|
| E.1 unanimous activation | Unanimity sender upserts **self** in schedule flow; each other participant upserts **self** on activation import |
| Settings timezone change | Local user when ≥1 active housing plan → upsert + recompute pending housing_payment fires |

Relay **recomputes** pending `fire_at` rows when timezone changes. Targets without a timezone row defer fire materialization.

### D4 — Delivery path

1. Cron marks fire row `fired`.
2. Relay sends wake push (`kind`: `wake_for_inbox` — no new push schema).
3. Relay enqueues optional **thin** steady-state envelope `housing_payment_reminder_due` (encrypted) **or** client resolves from local DB using `reminder_fire_id` returned by a new loopback-authenticated fetch — **prefer encrypted envelope** so web/background poll paths work without a new GET API. Final choice: **encrypted envelope** carrying opaque ids only.

### D5 — Schema amendment: fifth category + scheduling timestamps

**What is a “relay category”?**  
`relay-state-schema-and-retention` enumerates **allowed purposes** for relay DB tables (routing, idempotency, envelopes, housekeeping). Any new table must fit one category or the change is rejected in audit. A **fifth category** = “scheduled notification housekeeping” — not user payload, but operational rows the cron needs.

**Why not forbid dates entirely?**  
Without `fire_at` (and bounds like `period_due_at`, `agreement_end_at`), the relay cannot know **when** to wake devices; every cron tick would need to pull ciphertext from clients — impossible. Alternatives (opaque fire ids only, clients pre-register exact UTC instants) **still store instants**; hiding the timestamp does not reduce privacy if the id maps 1:1 to a payment date on device. **Product decision (2026-06-17):** timestamps without amounts or labels are acceptably opaque.

**Complexity if dates were banned:** clients would need always-on polling, or local OS alarms anyway — reintroducing the reliability problem.

## Proposed database tables (relay migration `0003_scheduled_notifications.sql`)

### `scheduled_notification_targets`

```sql
CREATE TABLE scheduled_notification_targets (
    target_id              BYTEA PRIMARY KEY,
    domain                 TEXT NOT NULL
        CHECK (domain IN (
            'housing_payment',
            'housing_proposal_deadline',
            'contacts_invitation_expiry'
        )),
  -- scope keys: which logical entity this reminder belongs to (opaque)
    scope_key              BYTEA NOT NULL,
    recipient_routing_id   BYTEA NOT NULL,
    reminder_kind          TEXT NOT NULL,  -- e.g. before_due, overdue, deadline, expiry
    period_key             BYTEA,          -- housing payment periods only
    recurrence_period_days INTEGER,       -- W: sliding window length (housing payment)
    due_at                 TIMESTAMPTZ,      -- next recurrence / expiresAt / etc.
    bound_at               TIMESTAMPTZ,    -- agreement_end or invitation expiry ceiling
    generation             BIGINT NOT NULL,
    cancelled_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (domain, scope_key, recipient_routing_id, reminder_kind, period_key)
);
```

`scope_key` encodes domain-specific ids (e.g. `plan_id‖line_id`, `revision_id`, `invitation_id`) as opaque bytes — relay does not interpret structure.

### `scheduled_notification_fires`

```sql
CREATE TABLE scheduled_notification_fires (
    fire_id                BYTEA PRIMARY KEY,
    target_id              BYTEA NOT NULL REFERENCES scheduled_notification_targets(target_id),
    recipient_routing_id   BYTEA NOT NULL,
    fire_at                TIMESTAMPTZ NOT NULL,
    status                 TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'fired', 'cancelled')),
    fired_at               TIMESTAMPTZ,
    wake_dispatch_id       BYTEA,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (target_id, fire_at)
);

CREATE INDEX scheduled_notification_fires_due_idx
    ON scheduled_notification_fires (fire_at)
    WHERE status = 'pending';
```

### `recipient_notification_timezone`

```sql
CREATE TABLE recipient_notification_timezone (
    recipient_routing_id   BYTEA PRIMARY KEY,
    iana_timezone          TEXT NOT NULL,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (length(recipient_routing_id) BETWEEN 8 AND 64),
    CHECK (length(iana_timezone) BETWEEN 1 AND 64)
);
```

Used to compute **14:00 local** fire instants per recipient. IANA id only — not a user display name.

## Reconciliation triggers (client → relay)

| Event | Client action on relay targets/fires |
|-------|--------------------------------------|
| **E.1** Unanimous activation | Qualifying lines: **before-date** targets per payment-responsible rules; **overdue** targets for **all** roster members |
| **E.2** Line recurrence change | Cancel all pending fires for `(plan, line)`; re-upsert targets from new recurrence |
| **E.3** Line removed | Cancel targets and pending fires for `(plan, line)` |
| **E.4** Agreement end changed | Reclip: cancel fires with `fire_at > agreement_end_at`; drop future periods |
| **B** Published expense covers line ≥ 100% current period | Cancel pending fires for current `period_key`; if next period starts before `agreement_end_at`, create next period targets/fires |

**Coverage rule (confirmed 2026-06-17):**

- **Required** per sliding-window period P: `PlanProjection.unitMinor(line)` (plan amount for one recurrence period — **not** `monthlyChartUnitMinor`).
- **Attributed paid** in P: sum of **published** expenses for `planLineId` attributed to P, plus **carry-in** from P−1, using carry-forward semantics analogous to `paymentChartCarryForwardMinor` but keyed to **recurrence periods** instead of calendar months.
- Overpayment deferred to next period reduces required in P+1.
- Budget-cap lines excluded. Transfers excluded (`RealizedExpenseKind.usesPlanLine`).

## Envelope extensions (minimal disclosure)

### New steady-state kinds (encrypted JSON inside existing ciphertext)

| Kind | When sent | Plaintext JSON fields (inside ciphertext) | Relay-visible metadata (if any) |
|------|-----------|-------------------------------------------|----------------------------------|
| `housing_reminder_schedule_upsert` | E.1, E.2, E.4 | `planId`, `generation`, `targets[]` with `{ lineId, recipientParticipantId, reminderKind, periodKey, periodDueAt, recurrencePeriodDays }` — **no** `fireAt` | `module`, `plan_id`, `generation` |
| `recipient_timezone_upsert` | E.1 self, activation import, settings change | `ianaTimeZoneId` | routing id only |
| `housing_reminder_schedule_cancel` | E.3, partial cancel | `planId`, `lineId?`, `periodKey?`, `reason` enum | `module`, `plan_id`, `message_kind=reminder_schedule_cancel` |
| `housing_reminder_coverage_update` | B — expense published | `planId`, `lineId`, `periodKey`, `coveredAmountMinor`, `requiredAmountMinor`, `nextPeriod` optional block same shape as upsert fires | `module`, `plan_id`, `line_id`, `expense_id`, `message_kind=reminder_coverage_update` |
| `scheduled_reminder_due` | Relay → recipient after cron | `reminderFireId`, `domain`, opaque scope ids | ids for routing only |
| `proposal_deadline_schedule_upsert` / `cancel` | Author on dispatch / response | `revisionId`, `expiresAt`, `fires[]` | `revision_id` |
| `invitation_expiry_schedule_upsert` / `cancel` | Inviter on create / revoke | `invitationId`, `expiresAt`, `fires[]` | `invitation_id` |

**Relay does not parse** encrypted business fields; ingest validates auth, maps participants → routing ids, writes SQL rows. Housing plan reconciliations use monotonic `generation` per `plan_id`; only the **unanimity-establishing** client sends for E.1–E.4 and coverage B.

### Unchanged / reused

- Wake push body: unchanged (`closed-app-push-delivery`).
- Existing realized-expense kinds gain no new fields for reminders except optional relay-visible `message_kind` on decisions if needed for task 3.9 alignment.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Relay stores calendar instants → privacy audit tension | Fifth schema category; only opaque ids + instants; no titles/amounts; document in audit checklist |
| Multi-device reconciliation races | Monotonic `generation` per plan; last-writer-wins per plan id; log conflicts |
| Relay release cost | Scoped migration + cron; user explicitly chose relay over local scheduling |
| Local scheduling specs 1.4b / 3.7 | Superseded by this change — update task wording at implementation |
| Carry logic across sliding windows | New client helper; month-based chart carry is not sufficient as-is |

## Migration Plan

1. Ship relay migration + cron behind feature flag / env `REMINDER_CRON_ENABLED`.
2. Ship client reconciliation on activation + expense publish (no user-visible change until flag on).
3. Add Settings category (default on when master on).
4. Enable cron in staging; verify wake + notification builder.
5. Production relay release + audit.

## Open Questions

| # | Status |
|---|--------|
| 1 | **Resolved** — relay replaces local for payment, proposal deadline, invitation expiry |
| 2 | **Resolved** — tiered before-date (W&lt;20 / 20–40 / &gt;40) **including due day J**; **14:00** local; relay IANA timezone |
| 3 | **Resolved** — overdue at **14:00** local, day after due |
| 4 | **Resolved** — fifth category; timestamps allowed without amounts/labels |
| 5 | **Resolved** — web out of scope |
| 6 | **Resolved** — `unitMinor` + sliding period + carry |
| 7 | **Resolved** — sliding window for `everyNDays` |
| 8 | **Resolved** — unanimity-establishing client only (housing); author/inviter for other domains |
| 9 | **Resolved (2026-07-13)** — invitation `before_expiry` / `expired` lead times + FR/EN copy (see D-invitation); **implementation deferred** pending relay `fires[]` ingest |

## Appendix — local scheduling vs relay (Q1)

**User hypothesis:** scheduling on entity creation, but delivery depends on the app being active → June 20 reminder might fire June 22.

**Nuanced answer:**

1. **Not implemented today** — no `zonedSchedule` / shared local scheduling service exists; 1.4b lead times still open; invitation expiry (#4–#5) is **specified** but client/relay ingest deferred.
2. **If implemented with OS-scheduled local notifications** (`flutter_local_notifications` `zonedSchedule` on Android/iOS), the OS **can** fire at the right time while the app is killed — so the June 20→22 slip is **not inherent** to “local” on native.
3. **Remaining local-scheduling weaknesses** that motivate relay anyway:
   - **Cancel/reschedule** on shared state change (response submitted, invitation revoked, amendment accepted) only runs when **your** app executes — stale alarms can still fire.
   - **Multi-device** — each device schedules independently; no shared source of truth.
   - **Web** — no equivalent closed-app scheduler.
   - **Polling-based** reminders (check deadline only on foreground) **would** match the June 22 failure mode — but that is an anti-pattern, not what 1.4b text literally requires.

**Conclusion:** Your reliability concern is **valid as a product choice** (especially cancel/reschedule + shared truth), even if a careful native-only `zonedSchedule` implementation could improve raw fire-time accuracy. **Relay cron replaces local scheduling** for 1.4b, 3.7, and D.3 per product decision.
