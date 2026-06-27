## ADDED Requirements

### Requirement: Owner sees lifetime and windowed vehicle metrics
On the **Propriétaire's** device, the system SHALL compute and display:
- total usage over the vehicle lifetime (distance for land vehicles, engine hours for boats) and over selectable windows
- consumption per km (land) or per engine-hour window (boat) using full-tank anchors (see `fuel-purchase-tracking`)
- methodology / explainability for each displayed metric

These metrics SHALL include distance from **all** attributed uses (owner and approved borrowers).

#### Scenario: Owner sees total distance including borrower uses
- **WHEN** an owner opens metrics for a vehicle that has borrower-attributed uses
- **THEN** total distance includes borrower sessions
- **THEN** the owner can inspect which uses contributed to the total

### Requirement: Display the last full-tank anchor used for consumption
The system MUST display the date of the last full-tank entry used as the start anchor for the currently displayed consumption calculation.

#### Scenario: Owner sees full-tank anchor date
- **WHEN** the owner views consumption between full-tank entries
- **THEN** the system shows the date/time of the last full-tank entry used

### Requirement: Suggest full tank after long gaps (owner only)
If the last full-tank anchor is older than one month, the system SHOULD suggest a full-tank refill the next time the **owner** records a non-full fuel purchase.

#### Scenario: Owner notification after non-full entry when last full is stale
- **WHEN** the owner records a fuel purchase with full tank = false
- **AND** the last full-tank entry for the vehicle is older than one month
- **THEN** the system shows or schedules a reminder suggesting a full-tank refill to improve consumption accuracy

### Requirement: Handle insufficient data gracefully
The system MUST NOT present misleading metrics when data is insufficient (e.g., division by zero).

#### Scenario: No distance yields insufficient data
- **WHEN** a selected window has zero total distance
- **THEN** consumption per km is shown as unavailable with an explanation
