## ADDED Requirements

### Requirement: Record fuel purchases on a vehicle
The system SHALL allow the **Propriétaire** or an **approved Emprunteur** on that vehicle to record fuel purchases with at least:
- date/time
- cost
- optional volume
- meter reading at purchase (odometer)
- full-tank boolean
- vehicle association

Both parties MAY mark a purchase as a **full-tank anchor** because anchors are critical for consumption calculations.

When a fuel purchase records an odometer reading, the system SHALL require a **photo of the odometer display** at save time (same proof rule as `odometer-logging` for standalone readings).

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
The system SHALL treat full-tank entries as anchors for consumption per km across the **vehicle lifetime** on the Propriétaire's view and within Emprunteur reconciliation windows on the sharing side.

#### Scenario: Consumption uses the last two full-tank anchors
- **WHEN** a vehicle has at least two fuel purchases marked full tank
- **THEN** consumption can be computed for the interval between the last two full-tank entries

### Requirement: Trust user-declared tank volumes (current release); defer residual auto-detection
**Current release (2026-07-14):** the system SHALL **accept** user-declared fuel volume and tank fill state as given. The system MUST NOT auto-detect “incoherent” residual tank volume relative to estimated consumption, and MUST NOT auto-correct consumption metrics from such detection on fuel purchase save (tasks §8 deferred to a future release).

**Future release:** when shipped, the system MAY validate partial-tank purchases against the consumption estimate from full-tank anchors (physical overflow correction + journal; optional owner notify when estimated vs declared residual differs by more than 10 L), per `vehicle-module` tasks §8.

#### Scenario (current): Fuel purchase saves without residual auto-correction
- **WHEN** the Propriétaire saves a fuel purchase with volume and after-fill tank state
- **THEN** the system stores the declared facts without requiring overflow correction or residual-discrepancy notification
