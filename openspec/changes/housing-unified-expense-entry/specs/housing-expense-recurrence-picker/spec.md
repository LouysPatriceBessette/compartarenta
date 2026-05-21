## ADDED Requirements

### Requirement: Recurrence is chosen via date range inside agreement period

For recurring expenses, the system SHALL let the user pick a date range using a calendar affordance. The selectable range MUST be clamped to the agreement period start and end inclusive.

#### Scenario: Range outside agreement rejected

- **WHEN** the user picks a range ending after agreement period end
- **THEN** the system prevents confirmation or clamps selection per design decision documented in implementation

### Requirement: Recurrence kind is confirmed by the user

After range selection, the system SHALL infer a candidate recurrence kind and MUST present a confirmation dialog offering human-readable choices aligned to:

- fixed day of each month (with anchor date example)
- every N days from an anchor date
- every ordinal weekday of month (first/second/third/fourth/last + weekday) from an anchor

The user MUST confirm one option before the recurrence is stored.

#### Scenario: Ambiguous range shows three choices

- **WHEN** the user completes a range selection that could map to multiple kinds
- **THEN** the dialog shows up to three concrete worded options (not generic definitions only) and stores the chosen kind

### Requirement: Recurrence spec replaces day-of-month-only field

Persisted recurrence MUST be stored in a structured recurrence spec on the line (JSON). The wizard MUST NOT rely on `recurrenceDayOfMonth` alone for new saves.

#### Scenario: Monthly day 10 confirmed

- **WHEN** the user confirms fixed day 10 monthly from June 10 2026
- **THEN** the line stores a recurrence spec encoding that kind and anchor

### Requirement: Local draft lines without recurrence spec

When opening a **local** `PlanLine` that only has `recurrenceDayOfMonth` and no `recurrenceSpecJson`, the form SHALL synthesize a recurrence spec for editing where possible. This applies to on-device draft migration only, not proposal payload import (plan export is not implemented).

#### Scenario: Open local draft line

- **WHEN** the user edits a local line with day-of-month 15 and no spec json
- **THEN** the form shows recurring state consistent with that row

## MODIFIED Requirements

### Requirement: Author a detailed draft expense plan locally

The system SHALL allow authoring recurring and one-off expenses with per-line splits in a single wizard step after agreement dates. One-off min/max estimate bands are no longer required; budget ceiling is expressed via Budgeted (max) on a single amount.

#### Scenario: Recurring line with inline split

- **WHEN** the user adds a recurring expense with amount and non-equal split in the unified step
- **THEN** the line and ratios persist and appear in summary/projection paths

#### Scenario: Budget cap line

- **WHEN** the user marks an expense as Budgeted (max) with amount 500
- **THEN** projection uses the documented cap semantics (not min/max midpoint)
