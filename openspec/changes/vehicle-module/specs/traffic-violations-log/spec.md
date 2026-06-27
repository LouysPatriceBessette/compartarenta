## ADDED Requirements

### Requirement: Record traffic violations on a vehicle
The system SHALL allow recording traffic tickets/violations for a vehicle with date, type, amount, and responsibility state (specific participant or unknown).

#### Scenario: Owner records a violation
- **WHEN** the owner saves a violation for their vehicle
- **THEN** the system stores the violation linked to that vehicle

### Requirement: Violations participate in sharing settlements
Violations MAY be allocated through `vehicle-expense-sharing` when the vehicle is shared. Responsibility resolution rules remain as defined in that capability.

#### Scenario: Unknown-responsible violation blocks allocation until resolved
- **WHEN** a violation has responsible = unknown
- **THEN** it is not allocated to a specific borrower until responsibility is finalized per sharing rules
