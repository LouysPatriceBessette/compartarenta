## ADDED Requirements

### Requirement: Ratio templates are plan-scoped and stable

The system SHALL maintain ratio templates per plan, each with an internal id, a frozen display title, and a participant weight vector in basis points (sum 10000). Templates are created when an expense is saved with a split that is not equal parts.

#### Scenario: First non-equal expense creates template

- **WHEN** the user saves expense “Rent” with non-equal split weights
- **THEN** the system registers a template whose display title is “Rent” and whose weights match that save

### Requirement: Like selector is UI-only linkage

The Like selector (localized; not “category” in the label) SHALL offer a blank non-selectable first row and one entry per template. Selecting a template copies weights into the grid and recomputes row amounts from the current expense Amount. Saving the expense stores its own `PlanRatio` rows; other expenses are not updated when a template source is edited later.

#### Scenario: Like copies percents not amounts from old expense

- **WHEN** the user selects Like “Rent” on a new 800 expense
- **THEN** row percents match the Rent template and row amounts are recomputed from 800

#### Scenario: Manual grid edit clears Like selection

- **WHEN** the user selected Like “Rent” then edits a grid cell
- **THEN** the Like selector returns to the blank option

#### Scenario: Like hidden on first expense

- **WHEN** no templates exist on the plan
- **THEN** the Like selector is not shown

### Requirement: Like option two-line display

Each selectable Like option SHALL render two lines: line one is the template display title; line two is the participant percents formatted for display (e.g. `26.6% / 40.0% / 33.3%`).

#### Scenario: Template list rendering

- **WHEN** two templates exist
- **THEN** each dropdown item shows title on the first line and percent summary on the second

### Requirement: Duplicate weight vectors share one template id

If a saved expense produces the same weight vector as an existing template, the system MUST reuse the existing template id. The display title MUST remain the title from the first expense that registered that vector.

#### Scenario: Second expense same percents different name

- **WHEN** the user saves “Groceries” with the same weights as an existing template
- **THEN** no duplicate template row is created and Like list still shows the first title

### Requirement: Auto category on non-equal save

When an expense is saved with non-equal split, the system SHALL create a `PlanGroup` if needed, using the expense Name as the group title, and associate that line with the group. Manual category wizard step is not used.

#### Scenario: Non-equal save creates group

- **WHEN** the user saves “Rent” with non-equal split and no matching group exists
- **THEN** a plan group titled “Rent” exists and the line references it

#### Scenario: Equal split does not create template or group

- **WHEN** the user saves with equal parts split
- **THEN** no new ratio template is registered and no group is created solely for that reason

### Requirement: Manual category authoring removed from wizard

The housing plan wizard MUST NOT include a dedicated step or add button for authoring categories independent of expenses.

#### Scenario: Wizard steps after dates

- **WHEN** the user completes plan dates
- **THEN** the next step is expenses only (not categories)
