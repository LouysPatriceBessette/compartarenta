## ADDED Requirements

### Requirement: Fixed recurring lines qualify for payment reminders

The system SHALL schedule payment reminders only for plan lines that are **recurring**, **not** budget-capped (`amountIsBudgetCap` is false), and belong to an **active** housing agreement whose calendar period has not ended.

The **due date** for a period SHALL be the **next recurrence instant** computed from the line's recurrence spec and anchor (not a calendar-month normalization).

#### Scenario: Budget-cap line is excluded

- **WHEN** a plan line has `amountIsBudgetCap = true`
- **THEN** the system does not create reminder targets or fires for that line

#### Scenario: One-off line is excluded

- **WHEN** a plan line is not recurring
- **THEN** the system does not create reminder targets or fires for that line

#### Scenario: Agreement end suppresses future fires

- **WHEN** the agreement `periodEnd` calendar date is before a computed reminder `fire_at`
- **THEN** the system does not create or retain that fire row

---

### Requirement: Recurrence periods use sliding windows

For all recurrence kinds (including `everyNDays`), the **current period** and **next period** SHALL be defined by the line's recurrence sliding window (anchor + period length), not by calendar-month boundaries.

#### Scenario: Every-N-days period boundaries

- **WHEN** a line recurs every N days from anchor A
- **THEN** period P is the inclusive window `[A + k·N, A + (k+1)·N)` that contains the evaluation instant

---

### Requirement: Recipients follow payment-responsible rules for before-date only

**Before-date** reminder delivery SHALL follow `housing-expense-line-form` payment-responsible semantics:

- When `paymentResponsibleParticipantId` is **null** (**All**, the form default), **every** roster participant SHALL receive before-date reminders while the line is uncovered for the period.
- When a **single** participant is designated payment responsible, **only** that participant SHALL receive before-date reminders.

**Overdue** reminders SHALL **always** go to **every** roster participant when the period is **not fully covered** after the due instant, **regardless** of payment-responsible designation (partial coverage still triggers overdue).

#### Scenario: Default All receives before-date reminders

- **WHEN** a qualifying line has no designated payment responsible
- **THEN** reconciliation creates before-date reminder targets for every roster participant

#### Scenario: Designated payer alone receives before-date

- **WHEN** a qualifying line designates participant P as payment responsible
- **THEN** only P receives before-date reminder targets for that line and period

#### Scenario: Overdue notifies entire roster despite designated payer

- **WHEN** a qualifying line designates participant P as payment responsible and the line is still uncovered after the due instant
- **THEN** every roster participant receives overdue reminder targets, including participants other than P

#### Scenario: Overdue with All also notifies entire roster

- **WHEN** payment responsible is **All** and the line is uncovered after the due instant
- **THEN** every roster participant receives overdue reminder targets

---

### Requirement: Only the unanimity-establishing client reconciles housing plan reminders

For events **E.1–E.4** and for **coverage updates (B)** when a realized expense reaches published state, **only** the client that records the vote or acceptance establishing **unanimity** SHALL send the relay reconciliation envelope, and it SHALL do so **in the same send path** as the broadcast of that deciding vote or final accept.

No other participant SHALL send a competing reconciliation for the same event.

#### Scenario: Activation reconciliation from completing accept

- **WHEN** participant C's accept is the last required accept that activates revision R
- **THEN** only C's client sends `housing_reminder_schedule_upsert` in the same flow as the activation broadcast

#### Scenario: Published expense reconciliation from completing accept

- **WHEN** participant C's accept is the last required accept that publishes expense E
- **THEN** only C's client sends `housing_reminder_coverage_update` in the same flow as the accept broadcast

---

### Requirement: Reminders are reconciled after plan lifecycle events

The unanimity-establishing client SHALL send a relay reconciliation update after each of the following events:

| Code | Event |
|------|-------|
| E.1 | Unanimous activation of a plan revision |
| E.2 | Amendment changing a line's recurrence |
| E.3 | Amendment removing a line |
| E.4 | Amendment or closure changing agreement end |

Reconciliation SHALL replace pending fires for affected tuples; it SHALL NOT rely on the cron job to infer plan edits.

#### Scenario: Activation seeds reminders

- **WHEN** a housing plan revision becomes unanimously active
- **THEN** the completing client's reconciliation creates reminder targets and pending fires for every qualifying uncovered line for the current sliding-window period

#### Scenario: Recurrence change reschedules

- **WHEN** an accepted amendment changes recurrence for line L
- **THEN** all pending fires for L are cancelled and new fires are computed from the updated recurrence before the next cron tick

#### Scenario: Line removal cancels reminders

- **WHEN** line L is removed by accepted amendment
- **THEN** all targets and pending fires for L are cancelled on the relay

---

### Requirement: Coverage uses plan period amount with carry between recurrence periods

Coverage for period P SHALL compare:

- **Required amount:** `PlanProjection.unitMinor(line)` — the plan-entered amount for **one recurrence period** (not `monthlyChartUnitMinor` or other chart normalization).
- **Attributed paid amount:** the sum of **published** realized expenses attributed to P for that `planLineId`, plus any **carry-in** from the previous recurrence period, minus any amount **carried out** to the next period when the user chose to defer overpayment.

Attribution rules SHALL mirror the carry-forward semantics used for payment chart overflow (`paymentChartCarryForwardMinor`), adapted from calendar months to **recurrence sliding-window periods**.

When attributed paid amount ≥ required amount for P, the line is **covered** for P.

#### Scenario: Full coverage stops current reminders

- **WHEN** attributed published payments for line L in sliding-window period P reach the required period amount
- **THEN** no pending before-date or overdue fires remain for `(L, P)`

#### Scenario: Overpayment deferred to next period

- **WHEN** a published payment exceeds the required amount for P and the submitter deferred the excess to the next period
- **THEN** the excess is carried into period P+1 as carry-in and counts toward coverage there

#### Scenario: Full coverage schedules next period

- **WHEN** L is fully covered for P and the next period due date is on or before agreement end
- **THEN** reconciliation creates pending before-date and overdue fires for the next period

---

### Requirement: Before-date reminders tiered by recurrence period length

Let **J** be the calendar **due date** of the next recurrence (`period_due_at`) in the recipient's IANA timezone.

Let **W** be the recurrence **sliding-window length** in calendar days for the plan line (e.g. `n` for `everyNDays`; nominal month length for monthly / nth-weekday kinds — same source as period computation in the recurrence spec).

Each before-date fire is at **14:00:00 local** on **(J − k calendar days)** — never at 00:00 midnight. Offset **k = 0** is the **due date J** itself (due-day reminder).

| Window length W | Before-date fires (all at 14:00 local) |
|-----------------|----------------------------------------|
| **W < 20** | J−2, **J** |
| **20 ≤ W ≤ 40** | J−4, J−2, **J** |
| **W > 40** | J−6, J−2, **J** |

Example: J = 2026-07-20 → J−4 at 14:00 = **2026-07-16 14:00** local; due-day fire = **2026-07-20 14:00** local.

The relay SHALL compute all `fire_at` (UTC) values from J, W, the recipient's stored IANA timezone, and this table. Clients SHALL NOT send precomputed `fire_at` for housing payment before-date rows.

If a computed fire instant is **before** the moment the schedule was materialized (e.g. J−6 already passed), that fire SHALL be **skipped** (not backdated).

#### Scenario: Short period gets J−2 and due-day J

- **WHEN** line L has W = 14 and J = 2026-07-20 local
- **THEN** before-date fires exist at 2026-07-18 14:00 and 2026-07-20 14:00 local

#### Scenario: Medium period gets J−4, J−2, and due-day J

- **WHEN** line L has W = 30 and J = 2026-07-20 local
- **THEN** before-date fires exist at 2026-07-16 14:00, 2026-07-18 14:00, and 2026-07-20 14:00 local

#### Scenario: Long period gets J−6, J−2, and due-day J

- **WHEN** line L has W = 45 and J = 2026-07-20 local
- **THEN** before-date fires exist at 2026-07-14 14:00, 2026-07-18 14:00, and 2026-07-20 14:00 local

#### Scenario: Not midnight on calendar roll

- **WHEN** a before-date fire is scheduled for a given calendar day
- **THEN** it fires at 14:00:00 local that day, not at 00:00:00

---

### Requirement: Overdue fire time uses the same local hour

Housing payment **overdue** reminders SHALL fire at **14:00:00** local time on the **first calendar day after** the due date in the recipient's timezone, if the line is **not fully covered** for the period (partial payment does **not** suppress overdue).

Further overdue repeats (if any) are out of scope unless added to the product table later.

#### Scenario: First overdue at 14:00 day after due

- **WHEN** `period_due_at` is 2026-07-10 in the recipient's timezone and the period is not fully covered (including partial payment only)
- **THEN** the overdue `fire_at` is 2026-07-11 at 14:00 local (stored as UTC)


---

### Requirement: Cron-fired reminders use wake transport and on-device copy

When a pending fire row's `fire_at` is reached, the relay cron SHALL mark the row fired, dispatch a **content-free** wake push per `closed-app-push-delivery`, and deliver an encrypted `scheduled_reminder_due` envelope containing only opaque identifiers needed for on-device resolution.

The receiving client SHALL resolve display copy from **local** data, respect notification prefs, and deep-link appropriately. **Web is out of scope** for closed-app delivery.

#### Scenario: Native wake leads to localized notification

- **WHEN** the cron fires a reminder and the recipient has push registered and prefs allow
- **THEN** the device wakes, imports the reminder envelope, and shows a localized notification without relay plaintext titles or amounts

#### Scenario: Prefs block surfacing

- **WHEN** the user disabled the Housing payment-reminder category or the master switch
- **THEN** the client still MAY import the envelope but SHALL NOT surface a user-visible notification

---

### Requirement: Overdue events add a non-navigable journal card in Accepted expenses

When an **overdue** housing payment reminder is processed on a device (overdue fire imported and the line is **not fully covered** for the period — including when only a **partial** payment was recorded), the client SHALL append a **local journal entry** visible in the **Accepted expenses** list (`housingMonthlyExpensesTitle` / hub **Dépenses acceptées**).

Each entry SHALL:

- appear as a **card** in the month list whose calendar month contains the entry's **recorded local timestamp**;
- use **orange** styling (warning / overdue — distinct from default expense cards);
- display copy equivalent to: *« Le paiement dû le [due date] pour [expense line name] n'a pas été complété en date du [local date and time]. »* (localized EN/FR/ES; EN e.g. *"Payment due on [due date] for [expense line name] had not been completed as of [local date and time]."*);
- **not** open any detail screen on tap (no navigation handler).

The due date in copy SHALL be the recurrence **due date J** for that period (user-facing date format). The recorded timestamp SHALL be the local date and time when the overdue condition was recorded on this device.

#### Scenario: Overdue card after partial payment

- **WHEN** a published payment covers part but not all of the required period amount for line L and an overdue reminder fires
- **THEN** the orange journal card uses the **complété** / **completed** wording (not “enregistré” / “recorded”)

#### Scenario: Overdue card appears in accepted expenses month

- **WHEN** an overdue reminder fires for line L with due date 2026-07-20 and the period is not fully covered
- **THEN** each device that processes the overdue event shows an orange card in Accepted expenses for the month containing the recorded local datetime

#### Scenario: Month list shows overdue cards without published expenses

- **WHEN** a month has overdue journal entries but no published realized expenses
- **THEN** the Accepted expenses screen still lists the overdue cards (not the empty state)

#### Scenario: Card is not tappable

- **WHEN** the user taps the overdue journal card
- **THEN** the app does not navigate to expense detail or any other screen

#### Scenario: Coverage removes future overdue journal for that period

- **WHEN** the line becomes covered for period P before overdue fires
- **THEN** no overdue journal entry is created for P

#### Scenario: Published payment after overdue still keeps journal history

- **WHEN** an overdue journal entry was already recorded and a matching payment is later published
- **THEN** the journal entry remains visible as historical notice (implementation MAY offer no auto-delete in v1)

