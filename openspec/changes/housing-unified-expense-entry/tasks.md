# Implementation tasks

## Delivery (2 PRs)

| PR | Passes | Goal |
|----|--------|------|
| **#1** | 1 + 2 | Data model, projection, proposal payload fields, full `ExpensePlanLineForm` (wizard may still use old steps until PR2 merges) |
| **#2** | 3 + 4 | Wizard cutover (4 steps), remove categories/split UI, cleanup, checklist |

---

## Pass 1 — Data model and transport (PR #1)

- [ ] 1.1 Add `PlanRatioTemplates` table (`id`, `planId`, `displayTitle`, `weightsJson`, `createdAt`) and DAO helpers
- [ ] 1.2 Extend `PlanLines`: `amountIsBudgetCap`, `paymentResponsibleParticipantId`, `recurrenceSpecJson`, `ratioTemplateId`; keep deprecated columns only for **local DB** backfill
- [ ] 1.3 Drift migration v15+: backfill on device (`amountUsesRange` → `amountIsBudgetCap`; `recurrenceDayOfMonth` → `recurrenceSpecJson` where possible)
- [ ] 1.4 Update `PlanProjection.unitMinor` for budget cap (high estimate for presentation chart; not min/max midpoint)
- [ ] 1.5 Extend `PlanAgreementProposalService` payload JSON with new line fields when building proposals (**no legacy payload import** — plan export not implemented)
- [ ] 1.6 Unit tests: template dedup by weight vector; budget cap projection; recurrence JSON round-trip

---

## Pass 2 — Extract super-component (PR #1)

- [ ] 2.1 Create `mobile/lib/housing/expense_form/` module structure
- [ ] 2.2 Implement `ExpenseSplitGrid` (correction row, row-local math, equal parts reset, save disabled on mismatch)
- [ ] 2.3 Implement `ExpenseRatioTemplateRepository` (list, register on save, lookup by weights)
- [ ] 2.4 Implement `LikeRatioSelector` (two-line items, blank row, clear on grid edit)
- [ ] 2.5 Implement `RecurrenceRangePicker` + confirmation dialog (agreement-bounded range; hidden when not recurring)
- [ ] 2.6 Implement `ExpensePlanLineForm` composing fields 1–12 per spec; wire save to DB (line + ratios + template; no `groupId` on save)
- [ ] 2.7 Widget tests: grid math, Like copy, save gate, equal parts
- [ ] 2.8 Add l10n keys (EN/FR/ES): Name, Budgeted max, Payment responsible, All (default), Equal parts, Like, Split section, correction row

---

## Pass 3 — Wizard integration (PR #2)

- [ ] 3.1 Reduce `_housingPlanStepCount` to 4; reindex agreement rules step
- [ ] 3.2 Replace step 2 body with expense list (from old step 3); `+` navigates to `ExpensePlanLineForm` route
- [ ] 3.3 Remove `_stepExpenseCategories`, category FAB, `_CategoryEditorDialog`
- [ ] 3.4 Remove `_stepRatios` and related state (`_ratioParticipantIndex`, sliders, tick fractions, `_shareAmountControllers`, etc.)
- [ ] 3.5 Update `_inferResumeStepIndex`, `_isHousingPlanWizardFullyDoneInDb`, footer Next validation (per-line ratios complete)
- [ ] 3.6 Delete `_LineEditorDialog` / `_LineDraft` after form route works
- [ ] 3.7 Update housing summary / presentation chart: one item per `PlanLine` (no group/template aggregation), budget cap semantics, drop category-step assumptions

---

## Pass 4 — Cleanup and conformance (PR #2)

- [ ] 4.1 Stop writing `amountUsesRange`, `minAmountMinor`, `maxAmountMinor` on new saves
- [ ] 4.2 Local DB: migrate or strip orphan **group-level** `PlanRatio` rows (draft plans on device only)
- [ ] 4.3 Update `housing-plan-entry-spec-conformance-checklist.md` rows E1, E3, E7, E8
- [ ] 4.4 Manual QA: add 3 expenses (equal, custom, Like), recurring confirm dialog, proposal payload fields on send
- [ ] 4.5 Note notification + budget-threshold follow-up in `repo-maintenance-backlog` (active in-force flow)

---

## Deferred — active plan in-force flow (not PR #1 or #2)

Requires the **in-force plan usage** product flow to be specified first. Track in `openspec/changes/repo-maintenance-backlog/tasks.md`.

- [ ] D.1 Wire `ExpensePlanLineForm` with `ExpensePlanLineFormScope` for accepted / in-force plans
- [ ] D.2 Budgeted (max): confirmation dialog when a submitted expense exceeds the monthly cap
- [ ] D.3 Notifications: designated payer vs default **All** (all participants: before-date + overdue reminders)
- [ ] D.4 Define which fields are editable on an in-force plan vs proposal draft

---

## Verification checklist (acceptance)

- [ ] Wizard shows 4 steps; no standalone categories or split steps
- [ ] Expense form is full screen; dialog not used for add/edit
- [ ] Approximate/min/max UI absent; Determined / Budgeted (max) works
- [ ] Grid hidden without amount; correction row blocks save
- [ ] Like selector appears after first non-equal expense; copying then editing clears Like
- [ ] Recurrence range cannot exceed agreement period; confirm dialog required; calendar only when recurring
- [ ] Proposal payload includes new fields when a proposal is built (no legacy import path added)
