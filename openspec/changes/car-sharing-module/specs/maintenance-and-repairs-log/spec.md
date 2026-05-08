## ADDED Requirements

### Requirement: Record maintenance events and expenses
The system SHALL allow users to record maintenance events for a vehicle, including date, category, cost, optional notes, and optional attachment metadata (e.g., receipt reference).

#### Scenario: User records a maintenance expense
- **WHEN** a user saves a maintenance event with a category label and a cost amount
- **THEN** the system stores the event associated with the selected vehicle

### Requirement: Maintenance events can be included in sharing allocations
The system SHALL allow maintenance events to be included as shared car expenses in allocation windows.

#### Scenario: Maintenance included in monthly allocation
- **WHEN** a user computes an allocation for a monthly window
- **THEN** maintenance events in that window can be included and shared according to the selected rule
