## ADDED Requirements

### Requirement: Create reservations for a vehicle
The system SHALL allow participants to create a reservation for a vehicle for a specified start and end date/time, with an optional purpose note.

#### Scenario: User reserves the car for a time range
- **WHEN** a participant creates a reservation with start and end times
- **THEN** the system stores the reservation linked to the vehicle and participant

### Requirement: Prevent overlapping reservations
The system MUST prevent creating or editing a reservation that overlaps an existing reservation for the same vehicle.

#### Scenario: Overlap is rejected
- **WHEN** a user attempts to save a reservation whose time range overlaps an existing reservation
- **THEN** the system rejects the save and shows the conflicting reservation(s)

### Requirement: Reservations are visible in a schedule view
The system SHALL display reservations in a schedule view (list or calendar) for a selected vehicle.

#### Scenario: User views upcoming reservations
- **WHEN** a user opens the reservations view for a vehicle
- **THEN** the system shows upcoming reservations ordered by start time
