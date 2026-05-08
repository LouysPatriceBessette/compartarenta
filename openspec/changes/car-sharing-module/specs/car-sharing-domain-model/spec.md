## ADDED Requirements

### Requirement: Car sharing has core entities
The system SHALL represent car sharing using the following core entities:
- Vehicle
- Participant
- Car Use (a usage session)
- Reservation
- Car Expense (fuel, maintenance, other)
- Allocation Result (per-participant shares for a time window)

#### Scenario: User creates a vehicle and participants
- **WHEN** a user adds a new vehicle and selects participants
- **THEN** the system persists a vehicle record and participant records
- **THEN** the vehicle is associated with the selected participants for car-sharing operations

### Requirement: Car sharing data is scoped by group
The system SHALL scope car-sharing data by a “group” (the set of participants sharing the car) so that vehicles, uses, reservations, and expenses are not mixed across unrelated groups.

#### Scenario: Two groups do not see each other’s vehicles
- **WHEN** a user switches from Group A to Group B
- **THEN** vehicles, uses, reservations, and expenses from Group A are not shown in Group B

### Requirement: Participant sets are independent between domains
The system MUST support using the app for the apartment (shared housing) domain only, the car-sharing domain only, or both. Participants involved in the apartment domain MUST NOT be assumed to be involved in car sharing, and car-sharing participants MUST NOT be assumed to be involved in the apartment domain.

#### Scenario: Car-sharing group has different participants than housing group
- **WHEN** a user views the participant list for a car-sharing group
- **THEN** the list contains only participants explicitly added to that car-sharing group
- **THEN** participants from the housing domain are not implicitly included

### Requirement: Facts are stored separately from derived metrics
The system SHALL store factual inputs (odometer readings, timestamps, purchase amounts, expenses) separately from derived metrics (distance traveled, consumption per km, usage ratio).

#### Scenario: Derived metrics can be recomputed from facts
- **WHEN** a user edits an odometer reading for a past car use
- **THEN** the system recomputes any affected distance, consumption, and usage ratio outputs from stored facts
