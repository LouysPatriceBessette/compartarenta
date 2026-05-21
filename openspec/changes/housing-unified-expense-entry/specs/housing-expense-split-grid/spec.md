## ADDED Requirements

### Requirement: Split grid layout

When the expense Amount field has a valid positive value, the system SHALL show a three-column grid: participant share amount, participant display name, participant share percent.

#### Scenario: Amount cleared

- **WHEN** the user clears the Amount field
- **THEN** the split grid is hidden

### Requirement: Initial load defaults to equal parts

On form open for a new expense, the system SHALL initialize each participant row to an equal split of the Amount (amounts and percents consistent with `splitMinorByWeights` for maximally balanced weights).

#### Scenario: Three participants and 300 total

- **WHEN** Amount is 300 and there are three participants
- **THEN** each row shows one third of the money and one third of the percent display (subject to display rounding rules)

### Requirement: Row-local recalculation only

When the user edits a row amount, the system SHALL recalculate only that row’s percent from the expense Amount. When the user edits a row percent, the system SHALL recalculate only that row’s amount from the expense Amount. The system MUST NOT auto-adjust other participants’ rows on that edit.

#### Scenario: User edits one row amount

- **WHEN** the user changes Joe’s amount on a 500 total expense
- **THEN** only Joe’s percent updates; other rows keep their prior amount and percent until the user edits them

### Requirement: Equal parts reset

The form SHALL provide a control labeled for equal split (localized; e.g. “Equal parts”) that resets all rows to the equal-parts state for the current Amount and participant count.

#### Scenario: Reset after manual edits

- **WHEN** the user edited rows away from equal parts and taps equal parts reset
- **THEN** all rows return to equal amounts and percents for the current Amount

### Requirement: Correction row for aggregate mismatch

When the sum of row amounts differs from the expense Amount, the system SHALL append a summary row showing the signed difference in money and the sum of displayed percents, with copy indicating the user must correct the grid.

#### Scenario: Positive difference

- **WHEN** row amounts sum to 600 on a 500 expense
- **THEN** the correction row shows +100 in money and the aggregate percent per spec examples

### Requirement: Persist weights on save

On successful save, the system SHALL write `PlanRatio` rows for the line id with basis-point weights derived from the grid percents (sum MUST equal 10000) and integer amounts that honor `splitMinorByWeights` when applied to the line basis.

#### Scenario: Valid grid save

- **WHEN** row amounts sum to the expense Amount and Name is valid
- **THEN** save persists the line and ratio rows and closes the form

### Requirement: No slider or periodic tick split UI on the form

The expense form MUST NOT use split sliders, vinculum tick marks, or `RationalPercentText` for editing shares. Percent cells use standard numeric entry and display formatters per project display-number rules.

#### Scenario: Form never shows slider

- **WHEN** the user edits split on the expense form
- **THEN** only grid text fields are used for amount and percent
