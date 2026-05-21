## Calendar week start

- New preference: `weekStartsOnSunday` (bool) or enum `WeekStart { sunday, monday }`.
- Default: derive from locale on first launch, then persist user override.
- Apply via `MaterialLocalizations` / `CalendarDatePicker` configuration
  (exact API depends on Flutter version at implementation time).
- Expense recurrence range picker and housing plan date steps must read the
  same preference so QA scenarios (e.g. June 2026 starting on Monday vs
  Sunday column alignment) match user choice.

## Editable unit settings

Today `UnitsSettingsScreen` lists currency, date format, and distance as
read-only subtitles. Planned UX:

| Preference | Edit control | Notes |
|------------|--------------|-------|
| Date format | Dropdown (existing onboarding list) | Safe to change anytime; display-only impact. |
| Distance unit | Segmented / dropdown (`km` / `miles`) | No known persisted plan payload dependency. |
| Time zone policy | Dropdown (device vs fixed zone list) | Align with existing `timeZonePolicy` key. |
| Week start | Segmented Sunday / Monday | See above. |

## Currency — product reflection required

**Open question for product owner:** Should currency remain fixed after
onboarding, or become editable in settings?

| If editable | Impacts |
|-------------|---------|
| Yes | Existing `PlanLine.currency` and displayed totals may disagree with new pref; proposals already sent keep their payload; local draft plans need a rule (convert? block? warn?). |
| No | Keep read-only in settings; only new installs choose currency. |

Other unit prefs are assumed **not** to alter stored plan economics (only
presentation). Currency is the exception and must be decided before
implementation.

## Relation to housing-unified-expense-entry

- Short-term fix (separate PR): `saveText: Utiliser` on date range picker,
  date-only anchor strings, recurrence summary on expense form tile.
- This change id tracks the **structural** preference work.
