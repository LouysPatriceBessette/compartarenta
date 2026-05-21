# Implementation tasks (phased)

Phases are ordered so each leaves the app buildable. Prefer merging phase 1–2 before deleting the old split step (feature flag optional).

---

## Pass 1 — Data model and transport (no wizard UX cutover)

- [ ] 1.1 Add `PlanRatioTemplates` table (`id`, `planId`, `displayTitle`, `weightsJson`, `createdAt`) and DAO helpers
- [ ] 1.2 Extend `PlanLines`: `amountIsBudgetCap`, `paymentResponsibleParticipantId`, `recurrenceSpecJson`, `ratioTemplateId`; keep legacy columns for read migration
- [ ] 1.3 Drift migration v15+ with backfill: `amountUsesRange` → `amountIsBudgetCap`; synthesize `recurrenceSpecJson` from `recurrenceDayOfMonth` where possible
- [ ] 1.4 Update `PlanProjection.unitMinor` for budget cap (no min/max midpoint)
- [ ] 1.5 Extend `PlanAgreementProposalService` + `housing_proposal_transport_service` import/export (new keys + legacy fallback)
- [ ] 1.6 Unit tests: template dedup by weight vector; budget cap projection; recurrence JSON round-trip

---

## Pass 2 — Extract super-component (form + grid + templates)

- [ ] 2.1 Create `mobile/lib/housing/expense_form/` module structure
- [ ] 2.2 Implement `ExpenseSplitGrid` (correction row, row-local math, equal parts reset, save disabled on mismatch)
- [ ] 2.3 Implement `ExpenseRatioTemplateRepository` (list, register on save, lookup by weights)
- [ ] 2.4 Implement `LikeRatioSelector` (two-line items, blank row, clear on grid edit)
- [ ] 2.5 Implement `RecurrenceRangePicker` + confirmation dialog (agreement-bounded range)
- [ ] 2.6 Implement `ExpensePlanLineForm` composing fields 1–12 per spec; wire save to DB (line + ratios + template + optional group)
- [ ] 2.7 Widget tests: grid math, Like copy, save gate, equal parts
- [ ] 2.8 Add l10n keys (EN/FR/ES): Name, Budgeted max, Payment responsible, Equal parts, Like, Split section, correction row

---

## Pass 3 — Wizard integration

- [ ] 3.1 Reduce `_housingPlanStepCount` to 4; reindex agreement rules step
- [ ] 3.2 Replace step 2 body with expense list (from old step 3); `+` navigates to `ExpensePlanLineForm` route
- [ ] 3.3 Remove `_stepExpenseCategories`, category FAB, `_CategoryEditorDialog`
- [ ] 3.4 Remove `_stepRatios` and related state (`_ratioParticipantIndex`, sliders, tick fractions, `_shareAmountControllers`, etc.)
- [ ] 3.5 Update `_inferResumeStepIndex`, `_isHousingPlanWizardFullyDoneInDb`, footer Next validation (per-line ratios complete)
- [ ] 3.6 Delete `_LineEditorDialog` / `_LineDraft` after form route works
- [ ] 3.7 Update housing summary / projection UI labels if they referenced categories step or approximate amounts

---

## Pass 4 — Cleanup and conformance

- [ ] 4.1 Stop writing `amountUsesRange`, `minAmountMinor`, `maxAmountMinor` on new saves
- [ ] 4.2 Legacy group-ratio migration helper (expand to lines or strip orphan group ratios)
- [ ] 4.3 Update `housing-plan-entry-spec-conformance-checklist.md` rows E1, E3, E7, E8
- [ ] 4.4 Manual QA script: add 3 expenses (equal, custom, Like), recurring confirm dialog, proposal payload inspect
- [ ] 4.5 Document open notification follow-up in `repo-maintenance-backlog` or notification change (payer reminders only)

---

## Pass 5 — Future hook (optional, not blocking)

- [ ] 5.1 Stub `ExpensePlanLineFormScope.minorEdit` entry from placeholder route
- [ ] 5.2 Define which fields minor edit may lock (out of product spec today)

---

## Verification checklist (acceptance)

- [ ] Wizard shows 4 steps; no standalone categories or split steps
- [ ] Expense form is full screen; dialog not used for add/edit
- [ ] Approximate/min/max UI absent; Determined / Budgeted (max) works
- [ ] Grid hidden without amount; correction row blocks save
- [ ] Like selector appears after first non-equal expense; copying then editing clears Like
- [ ] Recurrence range cannot exceed agreement period; confirm dialog required
- [ ] Proposal JSON includes new fields; import of old package still loads
