## ADDED Requirements

### Requirement: Compute usage ratio per participant
The system SHALL compute a usage ratio per participant for a selected window based on distance traveled during car uses attributed to that participant.

#### Scenario: Usage ratio is computed from distance totals
- **WHEN** a user selects a window and the system has car uses with computed distances
- **THEN** the system computes each participant’s distance total in the window
- **THEN** the system computes usage ratios as participantDistance / totalDistance

### Requirement: Compute consumption per km for a window
The system SHALL compute and display consumption per km using the interval between full-tank fuel entries, as this provides the most accurate basis for consumption.

#### Scenario: Consumption per km is shown between two full-tank entries
- **WHEN** the vehicle has at least two fuel purchases marked full tank
- **THEN** the system computes and displays consumption per km for the interval between the last two full-tank entries
- **THEN** the system shows which purchases and which distance total were used for that interval

### Requirement: Display the last full-tank date used for consumption
The system MUST display the date of the last full-tank entry used as the start anchor for the currently displayed consumption calculation.

#### Scenario: User sees the last full-tank anchor date
- **WHEN** the system displays consumption between full-tank entries
- **THEN** the system shows the date/time of the last full-tank entry used for the calculation

### Requirement: Suggest performing a full tank after long gaps
If the last full-tank entry used for consumption calculations is older than one month, the system SHOULD suggest performing a full-tank refill the next time a non-full fuel expense is recorded.

#### Scenario: Notification suggestion after non-full entry when last full is older than a month
- **WHEN** a user records a fuel purchase with full tank = false
- **AND** the last full-tank entry for the vehicle is older than one month
- **THEN** the system schedules or shows a notification suggesting a full-tank refill next time to improve consumption accuracy

### Requirement: Handle insufficient data for metrics
The system MUST handle insufficient data gracefully and MUST NOT present misleading metrics (e.g., division by zero).

#### Scenario: No distance data yields “insufficient data”
- **WHEN** the selected window has zero total distance
- **THEN** the system shows that consumption per km and usage ratio are unavailable for that window
