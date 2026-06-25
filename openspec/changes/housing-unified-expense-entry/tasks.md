# Implementation tasks

## Delivery (2 PRs)

| PR | Passes | Goal |
|----|--------|------|
| **#1** | 1 + 2 | Data model, projection, proposal payload fields, full `ExpensePlanLineForm` (wizard may still use old steps until PR2 merges) |
| **#2** | 3 + 4 | Wizard cutover (4 steps), remove categories/split UI, cleanup, checklist |

---

## Pass 1 — Data model and transport (PR #1)

- [x] 1.1 Add `PlanRatioTemplates` table (`id`, `planId`, `displayTitle`, `weightsJson`, `createdAt`) and DAO helpers
- [x] 1.2 Extend `PlanLines`: `amountIsBudgetCap`, `paymentResponsibleParticipantId`, `recurrenceSpecJson`, `ratioTemplateId`; keep deprecated columns only for **local DB** backfill
- [x] 1.3 Drift migration v15+: backfill on device (`amountUsesRange` → `amountIsBudgetCap`; `recurrenceDayOfMonth` → `recurrenceSpecJson` where possible)
- [x] 1.4 Update `PlanProjection.unitMinor` for budget cap (high estimate for presentation chart; not min/max midpoint)
- [x] 1.5 Extend `PlanAgreementProposalService` payload JSON with new line fields when building proposals (**no legacy payload import** — plan export not implemented)
- [x] 1.6 Unit tests: template dedup by weight vector; budget cap projection; recurrence JSON round-trip

---

## Pass 2 — Extract super-component (PR #1)

- [x] 2.1 Create `mobile/lib/housing/expense_form/` module structure
- [x] 2.2 Implement `ExpenseSplitGrid` (correction row, row-local math, equal parts reset, save disabled on mismatch)
- [x] 2.3 Implement `ExpenseRatioTemplateRepository` (list, register on save, lookup by weights)
- [x] 2.4 Implement `LikeRatioSelector` (two-line items, blank row, clear on grid edit)
- [x] 2.5 Implement `RecurrenceRangePicker` + confirmation dialog (agreement-bounded range; hidden when not recurring)
- [x] 2.6 Implement `ExpensePlanLineForm` composing fields 1–12 per spec; wire save to DB (line + ratios + template; no `groupId` on save)
- [x] 2.7 Unit tests: split grid logic + recurrence spec (`housing_expense_*_test.dart`); widget tests optional follow-up
- [x] 2.8 Add l10n keys (EN/FR/ES): Name, Budgeted max, Payment responsible, All (default), Equal parts, Like, Split section, correction row

---

## Pass 3 — Wizard integration (PR #2)

- [x] 3.1 Reduce `_housingPlanStepCount` to 4; reindex agreement rules step
- [x] 3.2 Replace step 2 body with expense list (from old step 3); `+` navigates to `ExpensePlanLineForm` route
- [x] 3.3 Remove `_stepExpenseCategories`, category FAB, `_CategoryEditorDialog`
- [x] 3.4 Remove `_stepRatios` and related state (`_ratioParticipantIndex`, sliders, tick fractions, `_shareAmountControllers`, etc.)
- [x] 3.5 Update `_inferResumeStepIndex`, `_isHousingPlanWizardFullyDoneInDb`, footer Next validation (per-line ratios complete)
- [x] 3.6 Delete `_LineEditorDialog` / `_LineDraft` after form route works
- [x] 3.7 Update housing summary / presentation chart: one item per `PlanLine` (no group/template aggregation), budget cap semantics, drop category-step assumptions

---

## Pass 4 — Cleanup and conformance (PR #2)

- [x] 4.1 Stop writing `amountUsesRange`, `minAmountMinor`, `maxAmountMinor` on new saves
- [x] 4.2 Local DB: migrate or strip orphan **group-level** `PlanRatio` rows (draft plans on device only)
- [x] 4.3 Update `housing-plan-entry-spec-conformance-checklist.md` rows E1, E3, E7, E8
- [ ] 4.4 Manual QA: add 3 expenses (equal, custom, Like), recurring confirm dialog, proposal payload fields on send *(not covered by Android E2E Maestro today; future proposal-wizard scenario)*.
- [x] 4.5 Note notification + budget-threshold follow-up in `repo-maintenance-backlog` (active in-force flow)

---

## Deferred — active plan in-force flow (not PR #1 or #2)

Specified in `openspec/changes/housing-active-agreement-operations/`. Implementation tracked there and in `repo-maintenance-backlog`.

- [x] D.1 Wire `ExpensePlanLineForm` with `ExpensePlanLineFormScope` for accepted / in-force plans
- [x] D.2 Budgeted (max): confirmation dialog when a submitted expense exceeds the monthly cap
- [x] D.3 Notifications: designated payer vs default **All** (all participants: before-date + overdue reminders). *(Implemented in `housing-scheduled-payment-reminders`: `HousingPaymentReminderService`, relay cron, overdue journal card.)*
- [x] D.4 Define which fields are editable on an in-force plan vs proposal draft

---

## Verification checklist (acceptance)

- [x] Wizard shows 4 steps; no standalone categories or split steps
- [x] Expense form is full screen; dialog not used for add/edit
- [x] Approximate/min/max UI absent; Determined / Budgeted (max) works
- [x] Grid hidden without amount; correction row blocks save
- [x] Like selector appears after first non-equal expense; copying then editing clears Like
- [x] Recurrence range cannot exceed agreement period; confirm dialog required; calendar only when recurring
- [x] Proposal payload includes new fields when a proposal is built (no legacy import path added)
