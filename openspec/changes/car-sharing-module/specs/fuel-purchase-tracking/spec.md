## ADDED Requirements

### Requirement: Record fuel purchases with cost and optional volume
The system SHALL allow users to record fuel purchases with:
- date/time
- total cost
- volume (liters/gal)
- odometer reading at purchase time
- a boolean flag indicating whether the purchase is a full-tank refill (“full tank”)
- vehicle association

#### Scenario: User records a fuel purchase with required volume and odometer
- **WHEN** a user saves a fuel purchase with date/time, total cost, volume, and odometer reading
- **THEN** the system stores the purchase for the selected vehicle

#### Scenario: User marks a purchase as full tank
- **WHEN** a user records a fuel purchase and sets full tank = true
- **THEN** the system stores the purchase as a “full tank” entry for the selected vehicle

### Requirement: Fuel purchases can be included in consumption windows
The system SHALL allow selecting a time window for consumption calculations and SHALL include fuel purchases whose timestamps fall within that window.

#### Scenario: Purchases are included based on timestamps
- **WHEN** a user selects a consumption window from Date A to Date B
- **THEN** the system includes fuel purchases within that range for computations

### Requirement: Full-tank entries are used as anchors for accurate consumption
The system SHALL treat full-tank entries as anchors for accurate consumption calculations and SHALL always display consumption between the most recent pair of full-tank entries available for a vehicle.

#### Scenario: Consumption is anchored between two full-tank entries
- **WHEN** a vehicle has at least two fuel purchases marked full tank
- **THEN** the system can compute and display consumption for the interval between the last two full-tank entries

### Requirement: Support linking purchases to usage history for explainability
The system SHALL present an explainable link between included purchases and the distance basis used for consumption calculations (e.g., “total distance in the selected window”).

#### Scenario: User can see what data powered the computation
- **WHEN** the system displays a computed consumption metric
- **THEN** the system shows which purchases and which distance total were used
