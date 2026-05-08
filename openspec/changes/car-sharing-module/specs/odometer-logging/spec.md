## ADDED Requirements

### Requirement: Record odometer readings for a car use
The system SHALL allow users to record an odometer “before” and “after” reading for each car use, along with timestamps and the responsible participant.

#### Scenario: User logs before and after readings
- **WHEN** a participant starts a car use and saves an odometer “before” reading
- **THEN** the system stores the reading linked to that car use
- **WHEN** the participant ends the car use and saves an odometer “after” reading
- **THEN** the system stores the reading linked to that car use

### Requirement: Enforce monotonic odometer readings per vehicle
For a given vehicle, the system MUST prevent saving an odometer reading that is lower than the latest known reading for that vehicle, unless the user explicitly marks the entry as a correction with an audit note.

#### Scenario: System blocks decreasing odometer without correction flag
- **WHEN** a user attempts to save an odometer “after” reading lower than the vehicle’s latest known reading
- **THEN** the system rejects the save and explains the conflict

### Requirement: Derive distance traveled per car use
The system SHALL compute distance traveled for a car use as \(after - before\) when both readings exist and are valid.

#### Scenario: Distance is computed after both readings exist
- **WHEN** a car use has valid “before” and “after” readings
- **THEN** the system computes and displays the distance traveled for that use
