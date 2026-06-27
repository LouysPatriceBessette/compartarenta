## ADDED Requirements

### Requirement: Record meter readings for a vehicle use
The system SHALL allow recording a **before** and **after** meter reading for each vehicle use, with timestamps and attribution to the acting Contact (Propriétaire or approved Emprunteur).

For land vehicles (car, truck, motorcycle), meter readings are **odometer** values (distance).
For **boat** vehicles, meter readings are **engine hour meter** values (cumulative engine hours).

User-facing labels (per locale):
- **FR:** **Horomètre** (boat) — official French term (OQLF *Grand dictionnaire terminologique*); not jargon. In France the variant **horamètre** may be used if regional French copy is offered later.
- **EN:** Engine hour meter (boat)
- **ES:** Cronómetro del motor (boat)

Land vehicles continue to use **odomètre** / odometer per existing product terminology.

#### Scenario: Propriétaire logs before and after odometer readings
- **WHEN** the Propriétaire starts a land-vehicle use and saves a before odometer reading
- **THEN** the system stores the reading linked to that use
- **WHEN** the Propriétaire ends the use and saves an after reading
- **THEN** the system computes distance when both readings are valid

#### Scenario: Emprunteur logs before and after horometer readings on a boat
- **WHEN** an approved Emprunteur uses a boat and saves before/after engine hour readings
- **THEN** the system stores readings on the Propriétaire's canonical vehicle record
- **THEN** usage duration is computed as \(after - before\) engine hours

### Requirement: Enforce monotonic meter readings per vehicle
For a given vehicle, the system MUST prevent saving a meter reading lower than the latest known reading for that vehicle, unless the user explicitly marks the entry as a correction with an audit note.

#### Scenario: System blocks decreasing reading without correction flag
- **WHEN** a user attempts to save an after reading lower than the vehicle's latest known reading without marking correction
- **THEN** the system rejects the save and explains the conflict

### Requirement: Derive usage amount per vehicle use
The system SHALL compute usage for a session as \(after - before\) when both readings exist and are valid (kilometers for odometer uses, engine hours for boat horometer uses).

#### Scenario: Distance or hours computed after both readings exist
- **WHEN** a vehicle use has valid before and after readings
- **THEN** the system computes and displays the usage amount for that session

### Requirement: No pre-trip usage estimates
The system MUST NOT treat planned or estimated distance/fuel as authoritative for reconciliation. Only before/after readings on completed (or in-progress) uses are factual inputs.

#### Scenario: User cannot finalize session on estimate alone
- **WHEN** a user attempts to close a use without an after reading
- **THEN** the system does not compute a final usage amount for reconciliation until the after reading is recorded
