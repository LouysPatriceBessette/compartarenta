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
- Migrating in-flight proposal packages on other peers (best-effort import of legacy fields).

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
| Import/export proposal | Map new fields; legacy `amountUsesRange` → `amountIsBudgetCap` on read |
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
| Category dropdown in line editor | Replaced by auto group + “Like” |
| `_initRatiosIfNeeded` on wizard Next | Ratios written on form save |
| Group-level ratio authoring in wizard | Lines always own `PlanRatio` rows; groups only for bundling/projection if auto-created |

## Decisions

### D1 — Wizard step consolidation

Merge old steps 3–5 into new step 3 (code index 2). **Agreement rules** become index 3. `_housingPlanStepCount = 4`.

**Alternative:** Keep 6 steps but embed grid in dialog — rejected (no screen space, user request).

### D2 — Ratio templates vs `groupId`

- **Weights** always stored per line in `PlanRatio` at save.
- **`ratioTemplateId`** (nullable) records which “Like” option was used at save time for analytics only; editing template source line does not update other lines.
- **`PlanGroup`**: created when saved weights are not equal parts; `title` = expense name at first creation; `groupId` set on that line. Further lines using “Like” copy weights only; they need not share `groupId` unless we want projection grouping — **default: do not auto-assign `groupId` on “Like” copies** (only non-equal first save creates group). Clarify in Open Questions.

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
- **Budgeted (max):** `amountIsBudgetCap = true`; `amountMinor` is ceiling for projection/settlement semantics (document in projection).

### D6 — Recurrence storage

Store normalized JSON on line, e.g. `{ "kind": "monthlyDay", "day": 10, "anchor": "2026-06-10" }` | `{ "kind": "everyNDays", "n": 14, "anchor": "..." }` | `{ "kind": "nthWeekday", "ordinal": 2, "weekday": 3, "anchor": "..." }`. Drop `recurrenceDayOfMonth` after migration.

Range picker constrained to `[agreement.periodStart, agreement.periodEnd]`. Inference from range is heuristic → **confirmation dialog** with human-readable choices (per user annex).

### D7 — Form reusability

`ExpensePlanLineForm` accepts:

- `planId`, `lineId?`, `agreementPeriod`, `participants`, `existingTemplates`, `onSaved`, `scope`.

Minor edit scope hides wizard-only chrome but keeps same validation.

### D8 — Relay / transport

Client-only payload extension; old recipients ignore unknown keys. Import maps legacy lines: `amountUsesRange: true` → `amountIsBudgetCap: true`, midpoint not used going forward.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Large single PR | Phased tasks (below); form extract before deleting split step |
| Legacy DB rows with groups + group ratios | Migration: expand group ratios onto member lines or delete orphan group ratios |
| Recurrence inference wrong | Mandatory confirm dialog; store only after confirm |
| Percent display vs bps drift | Persist bps; display via existing percent formatters; save blocked on money mismatch not bps drift |
| Proposal peers on old app version | Transport keeps sending `recurrenceDayOfMonth` as fallback during transition |

## Migration Plan

1. Add columns / `plan_ratio_templates` table (schema v15+).
2. Backfill: `amountUsesRange` → `amountIsBudgetCap`; drop min/max from active UI; one-time script sets `recurrenceSpecJson` from `recurrenceDayOfMonth` when possible.
3. Ship new wizard; update checklist.
4. Later: remove deprecated columns from payload export after all clients updated.

## Open Questions

1. **Auto `groupId` on “Like”:** Should a line that copies “Like Loyer” also join the `PlanGroup` named Loyer, or only copy weights? (Spec assumes **weights only** unless product wants grouped projection.)
2. **One-off + recurrence UI:** Show recurrence calendar only when `isRecurring == true`? (Assumed **yes**.)
3. **Budget cap in projection:** Use full cap, 80% estimate, or actuals only at settlement? (Assumed **cap = `amountMinor`** for preview upper bound.)
4. **Template deduplication:** Same weight vector → same template id even if titles differ? (Assumed **yes**, display title from first registrant.)
5. **Minor edit:** Which fields are editable post-acceptance? (Out of scope; form API only.)
6. **Percent column input:** Allow user typing non-terminating values or round on blur to bps? (Assumed **bps authoritative**, display follows `display-number-rounding` rule.)
