# Tasks

## Week start + calendar

- [x] 1.1 Add `weekStart` (Sunday / Monday) to `AppPreferences` with getter/setter
- [x] 1.2 Onboarding preferences step: segmented control « Semaine débute le » + persist
- [x] 1.3 Units settings: same control, editable
- [x] 1.4 Pass week-start into `showDateRangePicker` / plan date pickers / recurrence flow
- [ ] 1.5 Manual QA: same June 2026 range with Sunday vs Monday column headers *(not covered by Android E2E Maestro; calendar week-start only)*.

## Editable units (non-currency)

- [x] 2.1 Units settings: edit date format (dropdown)
- [x] 2.2 Units settings: edit distance unit
- [x] 2.3 Units settings: edit time zone policy
- [x] 2.4 Verify housing/car screens use `prefs.dateFormat` after change

## Currency (blocked on product decision)

- [ ] 3.1 **Product:** Decide if currency is editable post-onboarding (see `design.md`)
- [ ] 3.2 If yes: spec migration rule for existing `PlanLine` rows + proposal payloads
- [ ] 3.3 If no: keep currency read-only in settings; document in `UnitsSettingsScreen`

## Verification

- [ ] Onboarding + settings round-trip for all unit prefs
- [ ] Recurrence picker labels still use `dateFormat` preference (no ISO time suffix)
