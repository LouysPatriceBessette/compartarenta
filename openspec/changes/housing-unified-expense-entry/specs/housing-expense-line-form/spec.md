## ADDED Requirements

### Requirement: Expense line form is a reusable full-page component

The system SHALL provide an `ExpensePlanLineForm` widget that occupies a full route (not a dialog) and SHALL be embeddable from the housing plan proposal wizard and from future minor plan edit entry points via a scope parameter.

#### Scenario: Wizard opens add expense form

- **WHEN** the user taps add expense on wizard step 3 (expenses)
- **THEN** the system navigates to a full-screen form with a back affordance and save action

#### Scenario: Wizard opens edit expense form

- **WHEN** the user taps an existing expense row
- **THEN** the system navigates to the same form pre-filled from that `PlanLine` and its `PlanRatio` rows

### Requirement: Form field order and labels

The form SHALL present fields in this order when all applicability conditions are met:

1. Name (single-line text; same control as legacy “Title”)
2. Description (optional, multiline)
3. Recurring (switch)
4. Recurrence period control (calendar affordance) when Recurring is on
5. Amount (numeric)
6. Amount type (radio): Determined | Budgeted (max)
7. Payment responsible (select; default “No designated payer”)
8. Visual separator
9. Section title “Split” (localized; not the word “ratio” in user-facing copy)
10. Equal parts control
11. Like selector (hidden until at least one ratio template exists on the plan)
12. Split grid (hidden until Amount is non-empty)

#### Scenario: Non-recurring expense hides recurrence control

- **WHEN** Recurring is off
- **THEN** the recurrence calendar control is not shown

### Requirement: Legacy approximate amount is removed

The system MUST NOT expose approximate amount, min amount, or max amount fields in the expense form. The system MUST NOT persist new data using `amountUsesRange` with min/max bands.

#### Scenario: User selects Budgeted max

- **WHEN** the user selects Budgeted (max) and enters amount 500
- **THEN** the system stores `amountIsBudgetCap = true` and `amountMinor = 50000` (minor units) with no min/max columns populated

#### Scenario: User selects Determined

- **WHEN** the user selects Determined and enters amount 300
- **THEN** the system stores `amountIsBudgetCap = false` and `amountMinor = 30000`

### Requirement: Payment responsible defaults to none

The payment responsible select SHALL list every plan participant plus an option meaning no designated payer. The default selection MUST be no designated payer.

#### Scenario: Save without changing payer

- **WHEN** the user saves a new expense without changing payment responsible
- **THEN** the stored payer participant id is null

### Requirement: Save is blocked when split totals mismatch

The primary save action MUST be disabled while the split grid reports a non-zero difference between the sum of row amounts and the expense Amount.

#### Scenario: Correction row visible

- **WHEN** row amounts sum to more or less than the expense Amount
- **THEN** the grid shows an extra row labeled for correction (localized) with the delta amount and percent sum, and save is disabled

### Requirement: Name field validation

The system MUST require a non-empty Name before save.

#### Scenario: Empty name

- **WHEN** Name is empty
- **THEN** save is disabled
