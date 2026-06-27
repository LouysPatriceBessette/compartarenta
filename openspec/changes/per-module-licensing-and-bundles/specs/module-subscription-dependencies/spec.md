## ADDED Requirements

### Requirement: Module subscription dependencies use Propriétaire and Emprunteur roles
Functional dependencies between `vehicle` and `vehicle-sharing` SHALL follow the EV / PP / PE model in `vehicle-sharing-licensing-and-delinquency`. This requirement summarizes store-level purchase rules; delinquency details live in that capability.

#### Scenario: Owner needs both modules to share out
- **WHEN** participant A has `vehicle-sharing` but not `vehicle`
- **THEN** A cannot register an owned vehicle
- **THEN** A cannot invite borrowers to a vehicle they own

#### Scenario: Borrower needs only vehicle-sharing
- **WHEN** participant B has `vehicle-sharing` only and accepts A's sharing invite
- **THEN** B can log usage on A's vehicle
- **THEN** B cannot create owned vehicles or invite borrowers as owner

### Requirement: Owning vehicles requires the vehicle module
Registering, importing, or maintaining owned vehicle records (fuel anchors, maintenance, owner metrics, export) SHALL require effective entitlement on **`vehicle`**, regardless of `vehicle-sharing` state.

#### Scenario: Vehicle without sharing
- **WHEN** a user has `vehicle` but not `vehicle-sharing`
- **THEN** the user can manage owned vehicles solo
- **THEN** sharing invite actions remain unavailable

### Requirement: Borrowing does not require the vehicle module
Logging usage as a borrower, viewing borrower-scoped statistics, and reconciling borrower windows SHALL require **`vehicle-sharing`** and an active sharing link, not **`vehicle`**.

#### Scenario: A borrows from C while sharing to B
- **WHEN** A has both `vehicle` and `vehicle-sharing`, shares with B, and holds an active borrower link on C's vehicle
- **THEN** A can log borrower uses on C's vehicle
- **THEN** B can log borrower uses on A's vehicle

### Requirement: Module dependency is enforced in UX and server-side entitlement projection
The app SHALL enforce module dependencies locally before enabling owner-side sharing actions. The entitlement server (when used) SHALL expose per-module state so the app can evaluate dependencies deterministically.

#### Scenario: Store receipt for vehicle-sharing alone does not unlock owner sharing
- **WHEN** a user purchases only `vehicle-sharing`
- **THEN** effective entitlement for `vehicle-sharing` is active
- **THEN** owner-side sharing publish remains blocked until `vehicle` is also entitled
