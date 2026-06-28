## ADDED Requirements

### Requirement: Record meter readings for a vehicle use
The system SHALL allow recording a **start** and **end** meter reading for each vehicle use, with timestamps and attribution to the acting Contact (Propriétaire or approved Emprunteur).

Each saved meter reading MUST include a **photo of the odometer or horometer display** at capture time. The system MUST reject a reading save without an attached photo.

For land vehicles (car, truck, motorcycle), meter readings are **odometer** values (distance).
For **boat** vehicles, meter readings are **engine hour meter** values (cumulative engine hours).

User-facing labels (per locale):
- **FR:** **Horomètre** (boat) — official French term (OQLF *Grand dictionnaire terminologique*); not jargon. In France the variant **horamètre** may be used if regional French copy is offered later.
- **EN:** Engine hour meter (boat)
- **ES:** Cronómetro del motor (boat)

Land vehicles continue to use **odomètre** / odometer per existing product terminology.

#### Scenario: Reading rejected without photo
- **WHEN** a user attempts to save a meter reading without an odometer/horometer photo
- **THEN** the system rejects the save and prompts for a photo

#### Scenario: Propriétaire logs start and end odometer readings
- **WHEN** the Propriétaire starts a land-vehicle use and saves a start odometer reading with photo
- **THEN** the system stores the reading and photo linked to that use
- **WHEN** the Propriétaire ends the use and saves an end reading with photo
- **THEN** the system computes distance when both readings are valid

#### Scenario: Emprunteur logs start and end horometer readings on a boat
- **WHEN** an approved Emprunteur uses a boat and saves start/end engine hour readings with photos
- **THEN** the system stores readings on the Propriétaire's canonical vehicle record
- **THEN** usage duration is computed as \(end - start\) engine hours

### Requirement: Enforce monotonic meter readings with negative-gap flow
For a given vehicle, the system MUST NOT silently accept a meter reading lower than the latest known reading. When a new reading is lower, **negative gap handling** in `vehicle-odometer-gap-attribution` applies (Propriétaire dialog or Propriétaire notification with photo verification). A lower reading MAY be persisted only through that acknowledged path or an explicit Propriétaire **correction** with audit note.

#### Scenario: Decreasing reading uses negative-gap flow
- **WHEN** a user attempts to save a reading lower than the vehicle's latest known reading
- **THEN** the negative-gap flow runs instead of a silent save
- **THEN** generic monotonic rejection applies only if the user abandons the negative-gap flow without acknowledgment

### Requirement: Sessions use start and end readings
Each vehicle use SHOULD be opened with a **start** meter reading and closed with an **end** reading. Gap handling when a start reading exceeds the latest stored reading is defined in `vehicle-odometer-gap-attribution`.

#### Scenario: Session usage excludes unexplained gap unless attributed
- **WHEN** a session has start and end readings with no intervening gap record
- **THEN** session usage remains \(end - start\) per this spec
- **WHEN** a gap was attributed at session start
- **THEN** the attributed gap amount is stored separately per `vehicle-odometer-gap-attribution`

### Requirement: Derive usage amount per vehicle use
The system SHALL compute usage for a session as \(end - start\) when both readings exist and are valid (kilometers for odometer uses, engine hours for boat horometer uses). Unlogged meter increases detected at session start are handled as **gap attribution** per `vehicle-odometer-gap-attribution`, not folded silently into the session delta.

#### Scenario: Distance or hours computed after both readings exist
- **WHEN** a vehicle use has valid start and end readings
- **THEN** the system computes and displays the usage amount for that session as \(end - start\)

### Requirement: No pre-trip usage estimates
The system MUST NOT treat planned or estimated distance/fuel as authoritative for reconciliation. Only before/after readings on completed (or in-progress) uses are factual inputs.

#### Scenario: User cannot finalize session on estimate alone
- **WHEN** a user attempts to close a use without an after reading
- **THEN** the system does not compute a final usage amount for reconciliation until the after reading is recorded
