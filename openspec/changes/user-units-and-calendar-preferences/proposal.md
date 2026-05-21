## Why

Manual QA on the housing expense recurrence picker showed that calendar
presentation depends on locale defaults (e.g. week starting Monday) while
product expectations may differ. Unit-related preferences are collected at
onboarding but are not yet editable in **Settings → Units**, and currency
editability needs an explicit product decision because it affects existing
plans.

This change is **deferred**; it records scope for a later implementation
pass without blocking the unified expense-entry wizard work.

## What Changes (planned)

- **First-run / settings:** Let the user choose whether the **calendar week
  starts on Sunday or Monday** (initial setup + change later under unit
  settings).
- **Settings → Units:** Make **distance unit**, **date format**, and
  **time zone policy** editable (today they are mostly display-only after
  onboarding).
- **Wire calendars** (date range picker, plan dates, recurrence anchor UI)
  to the week-start preference instead of inheriting only from locale.
- **Currency:** Document open questions before allowing edits (see design).

## Capabilities

### New Capabilities

- `user-units-settings`: Editable unit preferences screen and persistence.
- `calendar-week-start`: Week-start preference and calendar integration.

### Modified Capabilities

- `install-and-first-launch` / `initial-configuration` (app-onboarding):
  add week-start choice alongside existing unit prefs when implemented.

## Impact

- `AppPreferences`, onboarding preferences step, `UnitsSettingsScreen`.
- All `showDatePicker` / `showDateRangePicker` call sites (housing plan
  dates, expense recurrence flow, car-sharing if applicable).
- **Not in scope for this proposal:** changing currency on in-flight plans
  (requires separate decision; see `design.md`).

## Out of Scope (this change id)

- Relay or server schema.
- Migrating historical plan line amounts when currency might change.
