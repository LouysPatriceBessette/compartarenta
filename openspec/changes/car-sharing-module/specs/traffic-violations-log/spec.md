## ADDED Requirements

### Requirement: Record traffic violations and responsibility
The system SHALL allow users to record traffic tickets/violations for a vehicle with date, type, amount, and an optional responsible participant.

#### Scenario: Violation recorded without known responsible participant
- **WHEN** a user saves a violation with date, type, and amount but no responsible participant
- **THEN** the system stores the violation and marks responsibility as unknown

### Requirement: Violations can be allocated differently from shared expenses
The system SHALL support allocating violations only after responsibility is determined, either:
- to a single responsible participant when responsibility is finalized, or
- using a group allocation rule while responsibility remains unknown or pending.

#### Scenario: Finalized responsible participant pays the violation
- **WHEN** a violation responsibility has been finalized (self-declared or accepted proposal)
- **THEN** the system allocates 100% of the violation amount to that participant

#### Scenario: Unknown or pending responsibility uses group allocation
- **WHEN** a violation responsibility is unknown or pending acceptance
- **THEN** the system does not allocate the violation to a specific participant
- **THEN** the system uses the group allocation rule for the violation amount until responsibility is finalized
