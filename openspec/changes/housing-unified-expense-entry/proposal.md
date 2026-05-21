## Why

The housing plan wizard currently splits **expense categories**, **expense lines**, and **per-participant split ratios** across three steps with a cramped dialog for line entry. Users must understand categories before expenses, then revisit every line again on a separate ratio step with slider/tick math (including non-terminating percent display). Consolidating into one full-screen expense step with inline split editing reduces cognitive load, matches how people think about a single “expense,” and prepares a **reusable expense form** for future minor plan amendments.

## What Changes

- **BREAKING (wizard UX):** After agreement dates, a single step lists expenses and opens a **full-page** add/edit form (no dialog). Steps **categories (old #3), expenses (old #4), and split (old #5)** are removed as separate wizard steps.
- **BREAKING (line model):** Remove **approximate amount** (`amountUsesRange`, min/max band). Replace with **Determined** vs **Budgeted (max)** on a single amount field.
- **BREAKING (recurrence):** Replace day-of-month dropdown with **date-range–driven recurrence** (fixed day of month, every *n* days, or nth weekday of month), confirmed via a disambiguation dialog, bounded by agreement period.
- **New:** Reusable `ExpensePlanLineForm` (proposal + future minor plan edit).
- **New:** Inline **3-column split grid** (amount / participant / percent) with row-local recalculation, correction row when totals diverge, **Equal parts** reset, and **Like** selector copying prior ratio templates (UI-only; no cross-line linkage after save).
- **New:** Auto-created **ratio templates** (internal id + display label from first expense using that weight vector); optional auto **category** (`PlanGroup`) when split is not equal—categories are no longer authored manually in the wizard.
- **New:** **Payment responsible** participant (nullable; default “no designated payer”); notification behavior deferred to a follow-up change.
- **Removed:** Manual category step and category editor dialog in the wizard; group-level split step UI; slider + vinculum tick fractions + `RationalPercentText` on the split step; `_initRatiosIfNeeded` lazy fill on “Next.”
- **Reuse:** `PlanLine` / `PlanRatio` / `PlanGroup` tables (extended), `splitMinorByWeights`, list/reorder UI from current expenses step, most `_LineEditorDialog` fields (renamed labels).

## Capabilities

### New Capabilities

- `housing-expense-line-form`: Full-page reusable form, field order, validation gates, save contract, and embedding contexts (wizard vs future minor edit).
- `housing-expense-split-grid`: Per-line amount/percent grid, correction row, equal-parts reset, and persistence to `PlanRatio` weights.
- `housing-expense-ratio-templates`: Internal ratio template ids, “Like” selector (two-line items), auto category creation rules, and immutability of copied ratios after save.
- `housing-expense-recurrence-picker`: Date-range UI inside agreement bounds, inference + confirmation dialog for the three recurrence kinds.

### Modified Capabilities

- `expense-plan-structure-and-editor` (delta under this change): Wizard step count and authoring flow; drop manual category authoring and separate ratio step from requirements.

## Impact

| Area | Impact |
|------|--------|
| `mobile/lib/screens/housing/housing_plan_screen.dart` | Large refactor: step indices 0–3, remove ~1500 lines of split-step UI |
| New modules under `mobile/lib/housing/expense_form/` (suggested) | Form, grid, recurrence, templates |
| `mobile/lib/db/app_database.dart` | Schema migration: line fields, optional `plan_ratio_templates`, deprecate min/max/range |
| `mobile/lib/housing/projection/plan_projection.dart` | Budget-cap semantics (no midpoint for capped lines) |
| `plan_agreement_proposal_service.dart` / transport import | Payload fields for recurrence + budget flag + payer; backward-compatible read |
| `openspec/.../housing-plan-entry-spec-conformance-checklist.md` | Rows E1–E8 need re-triage after implementation |
| Relay | **No relay source change expected** (opaque JSON payload); peers on old builds may ignore new fields until upgraded |
| Notifications | Specified in annex but **out of scope** for implementation passes here |
