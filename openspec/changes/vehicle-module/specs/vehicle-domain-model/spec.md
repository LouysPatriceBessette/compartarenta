## ADDED Requirements

### Requirement: Vehicle module has core owner-side entities
The system SHALL represent the **vehicle** module using at least:
- **Vehicle** (fixed owner, vehicle kind, display label)
- **VehicleUse** (owner-attributed usage session with odometer before/after)
- **FuelPurchase** (date, cost, volume, odometer, full-tank flag)
- **MaintenanceEvent** (date, category, cost, optional notes, optional attachment metadata)
- **TrafficViolation** (date, type, amount, responsibility state)
- **Derived metrics** (distance, consumption per km, totals — not stored as authoritative facts)

Borrower-attributed sessions and sharing links are defined in `vehicle-sharing-module`.

#### Scenario: Owner creates a land vehicle
- **WHEN** a user with effective `vehicle` entitlement adds a new vehicle and selects its kind (car, truck, or motorcycle)
- **THEN** the system persists a vehicle record with that user as the **fixed owner**
- **THEN** the vehicle is available for owner-side logging and, if the user also holds `vehicle-sharing`, for sharing setup

### Requirement: Each vehicle has exactly one fixed owner
Each vehicle record SHALL name exactly one owner for its entire lifetime in the app. The system MUST NOT transfer ownership inside the app. A change of real-world owner SHALL be handled by export on the seller's device and import on the buyer's device (see `vehicle-data-portability`).

#### Scenario: Sharing does not change owner
- **WHEN** an owner approves a borrower on a vehicle
- **THEN** the vehicle's owner field remains the original owner Contact
- **THEN** the borrower is not listed as owner

### Requirement: An owner may register up to three vehicles
The system SHALL allow one owner to create and maintain at most **three** vehicle records independently. The system MUST NOT allow creating a fourth owned vehicle until the owner removes an existing one.

#### Scenario: Owner with two vehicles
- **WHEN** an owner registers a car and later registers a motorcycle
- **THEN** both vehicles appear in the owner's vehicle list
- **THEN** odometer, fuel, and maintenance data are scoped per vehicle

#### Scenario: Owner cannot register a fourth vehicle
- **WHEN** an owner already has three registered vehicles
- **AND** they attempt to add another vehicle
- **THEN** the system blocks creation
- **THEN** the user sees clear guidance that the limit is three vehicles per Propriétaire

### Requirement: Initial-release vehicle kinds use odometer
At **initial release**, the system SHALL support **car**, **truck**, and **motorcycle** kinds. Each uses **odometer** readings (km or mi) for usage, monotonic validation, and distance derivation.

The domain model MAY remain **extensible** for additional kinds without a new product module.

#### Scenario: Motorcycle uses odometer rules
- **WHEN** an owner logs odometer readings for a motorcycle
- **THEN** the same monotonic validation and distance derivation rules apply as for a car

### Requirement: Facts are stored separately from derived metrics
The system SHALL store factual inputs (odometer readings, timestamps, purchase amounts, expenses) separately from derived metrics (distance traveled, consumption per km, lifetime totals).

#### Scenario: Derived metrics recompute after an edit
- **WHEN** the owner edits an odometer reading for a past use
- **THEN** the system recomputes affected distance and consumption outputs from stored facts

### Requirement: Vehicle data is scoped by owner
Operational queries for the `vehicle` module SHALL return only vehicles owned by the local user (plus vehicles shared **to** the user via `vehicle-sharing`, which are read/usage-scoped there — not as owned vehicles).

#### Scenario: User does not see another owner's vehicle in the owned list
- **WHEN** a user views their owned vehicles
- **THEN** vehicles owned by other Contacts are not listed as owned
- **THEN** vehicles shared with the user appear only in the sharing module surfaces

## DEFERRED Requirements (boat — future release)

> **Decision (2026-07-06):** boat is **not** in scope for the initial release. See `design.md` § Decisions.

### Requirement: Boat kind uses engine hour meter (deferred)
When the boat release ships, the system SHALL support a **boat** vehicle kind. **Boat** uses **engine hour meter** (horometer) readings instead of road distance for usage and monotonic validation.

#### Scenario: Boat uses engine hours not road odometer
- **WHEN** an owner registers a boat
- **THEN** use sessions record engine hour meter before/after readings
- **THEN** consumption metrics use hours-based windows where applicable
