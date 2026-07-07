## ADDED Requirements

### Requirement: Record odometer readings for a vehicle use
The system SHALL allow recording a **start** and **end** **odometer** reading for each vehicle use on **land vehicles** (car, truck, motorcycle), with timestamps and attribution to the acting Contact (Propriétaire or approved Emprunteur).

Meter readings are **odometer** values (distance). Land vehicles use **odomètre** / odometer per existing product terminology.

Meter reading **photos** MUST be persisted under `Documents/Compartarenta/Car/<vehicleId>/Odometer/` per `user-owned-media-storage` when a photo file is captured.

### Requirement: Meter photo when the reading changes (known-unchanged exception at session start)
The system SHALL require a **photo of the odometer display** when saving a meter reading whose **value differs** from the applicable baseline, and in the cases listed below. The photo acts as visual proof at capture time.

**Session start:** the form pre-fills the latest known meter anchor. If the participant **keeps that unchanged value** (confirms the known reading), the system MAY save without a new photo file by persisting a **known-unchanged sentinel** (`sentinel:meter_known_unchanged`). User-visible copy SHALL state that the odometer was unchanged and no photo was recorded.

**Session end:** the system SHALL **always** require a new photo file before saving the end reading (no known-unchanged shortcut).

**Other cases:** initial vehicle registration meter, fuel-purchase meter anchors, standalone readings, and any reading entered through negative-gap or correction flows that require visual proof SHALL require a photo file unless an explicit product exception is documented for that flow.

The system MUST reject a save that requires a photo file when neither a photo nor an allowed known-unchanged sentinel is present.

#### Scenario: Session start unchanged — no new photo
- **WHEN** a user opens a session start form pre-filled with 12 400 km
- **AND** saves 12 400 km without changing the value
- **THEN** the reading is stored with the known-unchanged sentinel
- **THEN** user-visible copy indicates no photo was recorded because the odometer was unchanged

#### Scenario: Session start changed — photo required
- **WHEN** a user changes the pre-filled session start value before save
- **THEN** the system requires a photo file
- **THEN** save is blocked until a photo is attached

#### Scenario: Session end — photo always required
- **WHEN** a user completes a session with an end reading
- **THEN** the system requires a photo file before save
- **THEN** the known-unchanged sentinel is not offered for session end

#### Scenario: Save rejected when photo required but missing
- **WHEN** a user attempts to save a reading that requires a photo file without attaching one
- **THEN** the system rejects the save and prompts for a photo

#### Scenario: Propriétaire logs start and end odometer readings
- **WHEN** the Propriétaire starts a land-vehicle use and saves a session start (unchanged or with photo per rules above)
- **THEN** the system stores the start reading linked to that use
- **WHEN** the Propriétaire ends the use and saves an end reading with photo
- **THEN** the system computes distance when both readings are valid

### Requirement: Enforce monotonic meter readings with negative-gap flow
For a given vehicle, the system MUST NOT silently accept an odometer reading lower than the latest known reading. When a new reading is lower, **negative gap handling** in `vehicle-odometer-gap-attribution` applies (Propriétaire dialog or Propriétaire notification with photo verification). A lower reading MAY be persisted only through that acknowledged path or an explicit Propriétaire **correction** with audit note.

#### Scenario: Decreasing reading uses negative-gap flow
- **WHEN** a user attempts to save a reading lower than the vehicle's latest known reading
- **THEN** the negative-gap flow runs instead of a silent save
- **THEN** generic monotonic rejection applies only if the user abandons the negative-gap flow without acknowledgment

### Requirement: Sessions use start and end readings
Each vehicle use SHOULD be opened with a **start** odometer reading and closed with an **end** reading. Gap handling when a start reading exceeds the latest stored reading is defined in `vehicle-odometer-gap-attribution`.

#### Scenario: Session usage excludes unexplained gap unless attributed
- **WHEN** a session has start and end readings with no intervening gap record
- **THEN** session usage remains \(end - start\) per this spec
- **WHEN** a gap was attributed at session start
- **THEN** the attributed gap amount is stored separately per `vehicle-odometer-gap-attribution`

### Requirement: Derive distance per vehicle use
The system SHALL compute session distance as \(end - start\) in kilometers (or miles per vehicle settings) when both odometer readings exist and are valid. Unlogged odometer increases detected at session start are handled as **gap attribution** per `vehicle-odometer-gap-attribution`, not folded silently into the session delta.

#### Scenario: Distance computed after both readings exist
- **WHEN** a vehicle use has valid start and end odometer readings
- **THEN** the system computes and displays the session distance as \(end - start\)

### Requirement: No pre-trip usage estimates
The system MUST NOT treat planned or estimated distance/fuel as authoritative for reconciliation. Only before/after readings on completed (or in-progress) uses are factual inputs.

#### Scenario: User cannot finalize session on estimate alone
- **WHEN** a user attempts to close a use without an after reading
- **THEN** the system does not compute a final usage amount for reconciliation until the after reading is recorded

## DEFERRED Requirements (boat horometer — future release)

> **Decision (2026-07-06):** boat meter logging is **not** in scope for the initial release. See `vehicle-module` `design.md` § Decisions.

### Requirement: Record horometer readings for boat use (deferred)
When the boat release ships, meter readings for **boat** vehicles SHALL be **engine hour meter** values (cumulative engine hours).

User-facing labels (per locale):
- **FR:** **Horomètre** — official French term (OQLF *Grand dictionnaire terminologique*); not jargon. In France the variant **horamètre** may be used if regional French copy is offered later.
- **EN:** Engine hour meter
- **ES:** Cronómetro del motor

Photo rules SHALL mirror land-vehicle rules (known-unchanged at session start; photo always at session end; photo when value changes).

#### Scenario: Emprunteur logs start and end horometer readings on a boat
- **WHEN** an approved Emprunteur uses a boat and saves start/end engine hour readings per the photo rules above
- **THEN** the system stores readings on the Propriétaire's canonical vehicle record
- **THEN** usage duration is computed as \(end - start\) engine hours
