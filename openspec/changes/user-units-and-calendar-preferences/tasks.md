# Tasks (deferred)

## Week start + calendar

- [ ] 1.1 Add `weekStart` (Sunday / Monday) to `AppPreferences` with getter/setter
- [ ] 1.2 Onboarding preferences step: segmented control « Semaine débute le » + persist
- [ ] 1.3 Units settings: same control, editable
- [ ] 1.4 Pass week-start into `showDateRangePicker` / plan date pickers / recurrence flow
- [ ] 1.5 Manual QA: same June 2026 range with Sunday vs Monday column headers

## Editable units (non-currency)

- [ ] 2.1 Units settings: edit date format (dropdown)
- [ ] 2.2 Units settings: edit distance unit
- [ ] 2.3 Units settings: edit time zone policy
- [ ] 2.4 Verify housing/car screens use `prefs.dateFormat` after change

## Currency (blocked on product decision)

- [ ] 3.1 **Product:** Decide if currency is editable post-onboarding (see `design.md`)
- [ ] 3.2 If yes: spec migration rule for existing `PlanLine` rows + proposal payloads
- [ ] 3.3 If no: keep currency read-only in settings; document in `UnitsSettingsScreen`

## Verification

- [ ] Onboarding + settings round-trip for all unit prefs
- [ ] Recurrence picker labels still use `dateFormat` preference (no ISO time suffix)
