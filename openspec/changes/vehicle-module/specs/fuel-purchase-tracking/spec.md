## ADDED Requirements

### Requirement: Record fuel purchases on a vehicle
The system SHALL allow the **Propriétaire** or an **approved Emprunteur** on that vehicle to record fuel purchases with at least:
- date/time
- cost
- optional volume
- meter reading at purchase (odometer or horometer per vehicle kind)
- full-tank boolean
- vehicle association

Both parties MAY mark a purchase as a **full-tank anchor** because anchors are critical for consumption calculations.

#### Scenario: Propriétaire records a fuel purchase
- **WHEN** the Propriétaire saves a fuel purchase for their vehicle
- **THEN** the system stores the purchase linked to that vehicle

#### Scenario: Emprunteur records a full-tank anchor
- **WHEN** an approved Emprunteur saves a fuel purchase with full tank = true on a shared vehicle
- **THEN** the system stores the purchase as a full-tank anchor on the Propriétaire's vehicle record
- **THEN** the anchor participates in consumption calculations like a Propriétaire-entered anchor

#### Scenario: Either party marks full-tank
- **WHEN** either the Propriétaire or an approved Emprunteur saves a fuel purchase with full tank = true
- **THEN** the system stores the purchase as a full-tank anchor for consumption calculations

### Requirement: Full-tank anchors drive consumption calculations
The system SHALL treat full-tank entries as anchors for consumption per km (or per hour for boats) across the **vehicle lifetime** on the Propriétaire's view and within Emprunteur reconciliation windows on the sharing side.

#### Scenario: Consumption uses the last two full-tank anchors
- **WHEN** a vehicle has at least two fuel purchases marked full tank
- **THEN** consumption can be computed for the interval between the last two full-tank entries
