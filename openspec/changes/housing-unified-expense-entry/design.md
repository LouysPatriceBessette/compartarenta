## Context

**Current wizard** (`HousingPlanScreen`, 6 steps indexed 0–5):

| UI step # | Code `_stepIndex` | Title key | Role |
|-----------|-------------------|-----------|------|
| 1 | 0 | Participants | Roster |
| 2 | 1 | Plan dates | Agreement period |
| 3 | 2 | Expense categories | Manual `PlanGroup` CRUD |
| 4 | 3 | Expenses | `ReorderableListView` + `_LineEditorDialog` |
| 5 | 4 | Split | Per-participant chips + sliders/`RationalPercentText` |
| 6 | 5 | Agreement rules | Contract extras |

**Target wizard (4 steps):**

| UI step # | Code index | Role |
|-----------|------------|------|
| 1 | 0 | Participants (unchanged) |
| 2 | 1 | Plan dates (unchanged) |
| 3 | 2 | **Expenses** — list + full-page form (this change) |
| 4 | 3 | Agreement rules (was step 6) |

Validation today: `_validateStep2Expenses` on leaving expense step; `_validateStep3Ratios` (weights sum to 10000 bps per line or group) on leaving split step. Resume logic skips optional categories and jumps to expenses (index 3) — will simplify to index 2.

**Persistence today:**

- `PlanLines`: `amountUsesRange`, `minAmountMinor`, `maxAmountMinor`, `recurrenceDayOfMonth`, optional `groupId`
- `PlanRatios`: per `lineId` or `groupId`, `weight` in basis points (sum 10000)
- `PlanGroups`: manual title/description

Proposal payload (`PlanAgreementProposalService`) mirrors line/ratio/group fields; relay does not parse them.

## Goals / Non-Goals

**Goals:**

- One expense step with list + navigated form containing all fields in the ordered spec (name through split grid).
- Extract **`ExpensePlanLineForm`** usable from wizard and (API-wise) from a future “minor plan edit” route without duplicating logic.
- Persist splits at save time with explicit total-mismatch gate (no auto redistribution across rows).
- Auto ratio templates + optional auto `PlanGroup` when split ≠ equal parts.
- Agreement-period-bounded recurrence with user confirmation of inferred kind.

**Non-Goals (defer):**

- Payment reminder / paid / overdue **notifications** (fields may be stored; no scheduler UI).
- Full **minor plan amendment** flow (only form reusability and `ExpensePlanLineFormScope` API).
- Car-sharing module parity.
- Relay protocol versioning or server-side validation.
- Legacy **proposal payload import** mapping (no plan export feature shipped; not required for this change).
- **Active plan in-force** usage flow (Pass 5 / `ExpensePlanLineFormScope.minorEdit`, budget threshold dialog, notifications).

## Reuse / Modify / Add / Remove matrix

### Reuse with little or no change

| Asset | Location | Notes |
|-------|----------|-------|
| Expense list + reorder | `_stepExpenses` | Becomes step 2 body; drop group subtitle or show ratio template label |
| Title, description, recurring switches | `_LineEditorDialog` | Move into form; rename title label → “Name” |
| Single amount `TextField` + `_parseMinor` | `_LineEditorDialog` | Drop min/max branch |
| `splitMinorByWeights` / `weightsAreMaximallyBalanced` | `split_minor_by_weights.dart` | Equal-parts detection + Hamilton on save |
| `formatMinorAsMoney`, display percent helpers | `format_money.dart`, `display_numbers.dart` | Grid and “Like” second line |
| `PlanRatio` upsert/delete pattern | `_setRatioWeightBps`, `_editLine` aftermath | Called from form save, not split step |
| Participant ids / labels | `_allParticipantIds`, `_ratioParticipantLabel` | Grid column 2 |
| Proposal transport grouping | `plan_agreement_proposal_service.dart` | Extend JSON keys |

### Modify

| Asset | Change |
|-------|--------|
| `HousingPlanScreen` | 4 steps; remove category/split steps; navigate to form route; validation on step 2 only |
| `PlanLines` schema | Add `amountIsBudgetCap`, `paymentResponsibleParticipantId`, `recurrenceSpecJson`, `ratioTemplateId`; deprecate range fields |
| `PlanProjection.unitMinor` | Budget cap: use `amountMinor` as cap, not midpoint of min/max |
| `_validateStep2Expenses` | Recurrence spec + amount + ratios consistent; rename to `_validateExpensesStep` |
| `_inferResumeStepIndex` / `_isHousingPlanWizardFullyDoneInDb` | New indices |
| Proposal payload JSON | Add new fields when building/sending proposals; no legacy import mapping |
| Conformance checklist | E1, E3, E7, E8 rows |

### Add

| Item | Description |
|------|-------------|
| `ExpensePlanLineForm` widget | Super-component; `ExpensePlanLineFormScope` enum: `proposalDraft`, `minorEdit` (stub) |
| `ExpenseSplitGrid` | 3-column table + correction row |
| `ExpenseRatioTemplateRepository` | Plan-scoped templates: id, weight vector, frozen display title |
| `RecurrenceRangePicker` + confirm dialog | Calendar icon → range → 3-option dialog |
| `LikeRatioSelector` | Custom 2-line dropdown; hidden until ≥1 template |
| DB table `PlanRatioTemplates` (name TBD) | `id`, `planId`, `title`, `weightsJson`, `createdAt` |
| Navigation | `Navigator.push` full-screen form (Material page), not `showDialog` |

### Remove

| Item | Notes |
|-------|-------|
| `_stepExpenseCategories`, `_CategoryEditorDialog` | Manual categories |
| `_stepRatios`, `_buildSplitRatioLineCard`, `_buildSplitRatioGroupCard` | ~600+ lines |
| `_splitTickFractionsForParticipantCount`, slider tick UI | “Vinculum” periodic ticks |
| `RationalPercentText` in split step | Keep widget elsewhere if needed; not in expense form grid (use 1-decimal terminating / 4+ellipsis per display rules) |
| `amountUsesRange` switch + min/max fields | Replaced by radio |
| Category dropdown in line editor | Replaced by ratio templates + “Like” (no `PlanGroup`) |
| `_initRatiosIfNeeded` on wizard Next | Ratios written on form save |
| Group-level ratio authoring in wizard | Lines always own `PlanRatio` rows; chart does not bundle by group |

## Decisions

### D1 — Wizard step consolidation

Merge old steps 3–5 into new step 3 (code index 2). **Agreement rules** become index 3. `_housingPlanStepCount = 4`.

**Alternative:** Keep 6 steps but embed grid in dialog — rejected (no screen space, user request).

### D2 — Ratio templates vs `groupId`

- **Weights** always stored per line in `PlanRatio` at save.
- **`ratioTemplateId`** (nullable) records which “Like” option was used at save time for analytics only; editing template source line does not update other lines.
- **`PlanGroup`**: not created by the unified expense flow; ratio templates replace the old manual/auto category UX. Lines that use “Like” copy **weights only** and MUST NOT receive a `groupId` from the template.
- **Presentation chart**: **one chart item per expense line**; no aggregation by `PlanGroup`, template, or category.

**Alternative:** Reuse `groupId` as template id — conflates bundling with UI aid; rejected.

### D3 — Equal parts detection

Treat split as equal when `weightsAreMaximallyBalanced` after mapping to bps (same as today’s fair split). No auto `PlanGroup` / template registration.

### D4 — Grid editing rules

- Only **same-row** sync: editing amount → recompute percent; editing percent → recompute amount; basis = line total amount field.
- **No** cross-row auto adjustment when sum ≠ total.
- Show correction row; disable Save when mismatch ≠ 0.
- Changing any cell after selecting “Like” clears selector to blank option (option #0).

### D5 — Amount type radio

- **Determined:** `amountIsBudgetCap = false`; `amountMinor` required.
- **Budgeted (max):** `amountIsBudgetCap = true`; `amountMinor` is the **upper-bound estimate** for the plan presentation chart. Threshold-exceed confirmation dialog and peer notifications when a live expense exceeds the cap are deferred to the **active plan in-force** flow.

### D6 — Recurrence storage

Store normalized JSON on line, e.g. `{ "kind": "monthlyDay", "day": 10, "anchor": "2026-06-10" }` | `{ "kind": "everyNDays", "n": 14, "anchor": "..." }` | `{ "kind": "nthWeekday", "ordinal": 2, "weekday": 3, "anchor": "..." }`. Drop `recurrenceDayOfMonth` after migration.

Range picker constrained to `[agreement.periodStart, agreement.periodEnd]`. Inference from range is heuristic → **confirmation dialog** with human-readable choices (per user annex).

### D7 — Form reusability

`ExpensePlanLineForm` accepts:

- `planId`, `lineId?`, `agreementPeriod`, `participants`, `existingTemplates`, `onSaved`, `scope`.

Minor edit scope hides wizard-only chrome but keeps same validation.

### D8 — Relay / transport

Client-only payload extension when proposals are sent; relay remains opaque JSON. **No legacy payload import** in this change (plan export is not implemented). Local DB migration may still backfill existing draft rows on device (`amountUsesRange` → `amountIsBudgetCap`, `recurrenceDayOfMonth` → `recurrenceSpecJson`).

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Large change set | **Two PRs:** PR1 = passes 1–2, PR2 = passes 3–4; form extract before deleting split step in PR2 |
| Legacy DB rows with groups + group ratios | Migration: expand group ratios onto member lines or delete orphan group ratios |
| Recurrence inference wrong | Mandatory confirm dialog; store only after confirm |
| Percent display vs bps drift | Persist bps; display via existing percent formatters; save blocked on money mismatch not bps drift |
| Proposal peers on old app version | Not a concern until export/send is widely used; encode new fields only |

## Migration Plan

1. Add columns / `plan_ratio_templates` table (schema v15+).
2. Backfill: `amountUsesRange` → `amountIsBudgetCap`; drop min/max from active UI; one-time script sets `recurrenceSpecJson` from `recurrenceDayOfMonth` when possible.
3. Ship new wizard; update checklist.
4. Later: drop deprecated DB columns once all local drafts are migrated.

## Delivery plan (2 PRs)

| PR | Passes | Scope |
|----|--------|--------|
| **#1** | 1 + 2 | Schema, projection, proposal payload fields, `ExpensePlanLineForm` module (usable in isolation; wizard still on old steps until PR2) |
| **#2** | 3 + 4 | Wizard cutover, remove split/categories UI, cleanup, checklist |

## Deferred — active plan in-force flow (separate change, after usage flow is designed)

Tracked outside this change (see `repo-maintenance-backlog` entry). Includes:

- `ExpensePlanLineFormScope` for editing lines on an **accepted / in-force** plan
- Budget-cap **threshold** confirmation when a submitted expense exceeds the monthly cap
- **Notifications:** optional designated payer (before-date reminder to payer only; on-payment and overdue to others); when default **All** is selected, **every** participant gets before-date reminder and overdue reminder if unpaid
- Pass 5 tasks from `tasks.md` (form scope stub → full wiring)

## Resolved product decisions

1. **Like / chart:** “Like” copies weights only; no auto `groupId`. Presentation chart: **one item per expense line**; no grouping by template or category.
2. **Recurrence UI:** Calendar only when `isRecurring` is on.
3. **Budget cap:** `amountMinor` is the high estimate for the presentation chart; threshold dialog + notifications → active in-force flow.
4. **Template deduplication:** Same weight vector → one internal template id; display title from first expense that registered it.
5. **Payment responsible:** Optional. Default UI = **All** (stored as null): all participants receive before-date and overdue reminders. Single designated payer → that participant gets before-date reminder; others per annex (on payment / overdue) when that flow ships.
6. **Percent input:** Basis points authoritative at save; display per `display-number-rounding`.
7. **Legacy data:** No proposal payload legacy import. Local DB may still migrate draft rows and orphan **group-level** ratios on device.
