## ADDED Requirements

### Requirement: Vehicle expenses use fixed categories
The system SHALL classify each shared vehicle expense into exactly one of:
- Fuel
- Maintenance
- Violations
- Payments

#### Scenario: User must choose one category
- **WHEN** a user creates a shared vehicle expense in an allocation context
- **THEN** the system requires exactly one of the fixed categories

### Requirement: Fuel category shows observed usage as informational input
For Fuel expenses, the system SHALL display observed usage ratios for the selected window but MUST NOT automatically change agreed fuel-sharing ratios without explicit acceptance.

#### Scenario: Observed usage does not change ratios silently
- **WHEN** a user views Fuel sharing for a window with computed usage ratios
- **THEN** observed ratios are displayed
- **THEN** configured ratios change only after an accepted proposal

### Requirement: Maintenance category uses a single agreed ratio
For Maintenance expenses, the system SHALL apply one configured maintenance-sharing ratio across maintenance expenses for the shared vehicle.

#### Scenario: Maintenance ratio applies uniformly
- **WHEN** a maintenance-sharing ratio is configured for a vehicle
- **THEN** all Maintenance expenses in allocations use that ratio

### Requirement: Payments category uses a configured ratio
For Payments expenses (e.g., leasing), the system SHALL apply a configured payments-sharing ratio.

#### Scenario: Lease payment uses payments ratio
- **WHEN** a Payments expense is included in an allocation window
- **THEN** the expense is allocated using the configured payments ratio

### Requirement: Violations require one responsible participant or unknown
For Violations, the system MUST record either one responsible participant or responsible = unknown.

#### Scenario: Unknown responsibility requires evidence
- **WHEN** a user saves a violation with responsible = unknown and zero attachments
- **THEN** the save is rejected until evidence is attached

### Requirement: Ratio and responsibility changes require acceptance
Changes to Fuel, Maintenance, or Payments ratios and violation responsibility attribution SHALL follow propose-and-accept semantics among affected participants.

#### Scenario: Pending ratio proposal
- **WHEN** a participant proposes a new fuel-sharing ratio
- **THEN** the proposal is pending until accepted
- **THEN** the prior ratio remains in effect until acceptance

### Requirement: Allocations are explainable
Allocation results MUST show included expenses by category, active ratios, violation responsibility state, and pending proposals relevant to the window.

#### Scenario: User reviews allocation breakdown
- **WHEN** a user opens an allocation result
- **THEN** the system displays expenses, rules applied, and responsibility states used
