## ADDED Requirements

### Requirement: Car expenses use fixed categories
The system SHALL classify each car expense into exactly one of the following fixed categories:
- Fuel
- Maintenance
- Violations
- Payments

#### Scenario: User must choose one fixed category
- **WHEN** a user creates a car expense
- **THEN** the system requires selecting exactly one of the fixed categories (Fuel, Maintenance, Violations, Payments)

### Requirement: Fuel category shows real usage as informational input
For Fuel expenses, the system SHALL compute and display observed usage information (e.g., usage ratios for a selected window), but MUST treat it as informational and MUST NOT automatically change the agreed fuel-sharing ratios.

#### Scenario: Observed usage is displayed but does not change ratios
- **WHEN** a user views the Fuel sharing screen for a window with computed usage ratios
- **THEN** the system displays the observed usage ratios
- **THEN** the system does not modify the configured fuel-sharing ratios unless a proposal is explicitly accepted

### Requirement: Maintenance category uses a single agreed ratio
For Maintenance expenses, the system SHALL apply a single configured maintenance-sharing ratio across all Maintenance expenses attached to the vehicle/group.

#### Scenario: Maintenance ratio applies to all maintenance expenses
- **WHEN** a maintenance-sharing ratio is configured for a group
- **THEN** all Maintenance expenses included in allocations use that same ratio

### Requirement: Payments category uses a specific sharing ratio
For Payments expenses (e.g., leasing payments), the system SHALL apply a configured payments-sharing ratio across all Payments expenses.

#### Scenario: Payments ratio is applied to a lease payment expense
- **WHEN** a Payments expense is included in an allocation window
- **THEN** the system allocates the expense using the configured payments-sharing ratio

### Requirement: Violations require a single responsible participant or unknown
For Violations expenses, the system MUST have exactly one responsible state:
- a single responsible participant, or
- responsible = unknown

#### Scenario: Violation saved with unknown responsible
- **WHEN** a user records a violation and selects responsible = unknown
- **THEN** the system stores the violation in the unknown-responsible state
- **THEN** the system does not allocate the violation to a specific participant until responsibility is resolved

### Requirement: Unknown-responsible violations require evidence attachments
If a violation is recorded with responsible = unknown, the system MUST require at least one attachment (evidence photo/document).

#### Scenario: System blocks unknown-responsible violation without attachments
- **WHEN** a user attempts to save a violation with responsible = unknown and zero attachments
- **THEN** the system rejects the save and requires adding evidence

### Requirement: Participants can propose and accept ratio changes
For Fuel, Maintenance, and Payments categories, the system SHALL support proposing a change to the relevant sharing ratio and SHALL require explicit acceptance by the participants affected before applying the change.

#### Scenario: Ratio proposal requires acceptance before taking effect
- **WHEN** a participant proposes a new fuel-sharing ratio
- **THEN** the proposal is recorded as pending
- **THEN** the currently active ratio remains in effect until the proposal is accepted

### Requirement: Participants can propose and accept violation responsibility attribution
For a violation with responsible = unknown, the system SHALL allow:
- a participant to self-declare responsibility, or
- any participant to propose attributing responsibility to a specific participant,
and SHALL require acceptance by the proposed responsible participant before finalizing responsibility.

#### Scenario: A participant self-declares responsibility
- **WHEN** a participant selects “I am responsible” for an unknown-responsible violation
- **THEN** the system sets that participant as responsible for the violation

#### Scenario: Responsibility proposal requires acceptance
- **WHEN** a participant proposes assigning responsibility for a violation to another participant
- **THEN** the system records the proposal as pending
- **THEN** the proposed participant can accept or reject the proposal
- **THEN** responsibility is finalized only if the proposed participant accepts

### Requirement: Expense allocation is explainable by category, ratios, and decisions
The system MUST provide an explainable breakdown of allocations including:
- the expenses included, grouped by category
- the active ratios used (Fuel/Maintenance/Payments)
- the responsibility resolution state for each violation (responsible participant or unknown)
- any pending proposals relevant to the window (ratio changes or responsibility attribution)

#### Scenario: User reviews an allocation breakdown
- **WHEN** a user opens an allocation result for a window
- **THEN** the system displays the included expenses grouped by category and the rules/ratios applied
