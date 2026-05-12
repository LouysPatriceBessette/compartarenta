## ADDED Requirements

### Requirement: Modules integrate with Contacts through a documented integration contract
Each module that involves participants SHALL adopt the Contacts model by:
- exposing a participant picker that lists existing Contacts and offers an "Add new contact" entry point,
- persisting module participant rows that reference a Contact identifier,
- avoiding duplication of the contact's name and avatar except as historical snapshots (per `contacts-domain-model`).

This contract SHALL be referenced from each module's own adoption change (e.g., a follow-up housing adoption change). This Contacts capability SHALL NOT itself edit any existing module spec; modules adopt this contract on their own schedule.

#### Scenario: Module adoption follows the documented contract
- **WHEN** a module's adoption change ships
- **THEN** the module references this `contacts-module-integration` capability for the integration rules
- **THEN** the adoption change adds module-specific delta specs without redefining what a Contact is

### Requirement: Adding a participant in any module routes through the contact picker
After a module has adopted Contacts, the flow for adding a participant to that module SHALL go through the contact picker. Modules SHALL NOT continue to expose a parallel "enter name and avatar inline as a temporary participant" flow as their authoritative path.

#### Scenario: Housing add-participant flow uses the contact picker
- **WHEN** a user adds a participant to a housing plan after housing has adopted Contacts
- **THEN** the user sees the contact picker (or its empty-state with "Add new contact")
- **THEN** there is no path to create a "temporary participant" with inline name/avatar as the authoritative participant record

### Requirement: A connected contact can be referenced by any module
A Contact whose kind is `connected` SHALL be eligible to be referenced as a participant by any module the local user enables. Eligibility is not module-specific.

#### Scenario: Same connected contact appears in housing and vehicle pickers
- **WHEN** the user has a connected Contact and both `housing` and `vehicle` are enabled
- **THEN** that Contact is selectable in both modules' participant pickers
- **THEN** picking the Contact in one module does not enroll the Contact in the other module

### Requirement: Local-only contacts can be referenced by modules but cannot receive module proposals
A Contact whose kind is `local-only` SHALL be selectable as a participant for purely local accounting purposes (e.g., one-time roommate the user never expects to connect). The app SHALL NOT send module-scoped relay proposals to a local-only Contact, because the relay routing material does not exist for them.

#### Scenario: Local-only participant participates in calculations without sync
- **WHEN** a housing plan references a local-only Contact as a participant
- **THEN** projections, balances, and other local calculations include that participant
- **THEN** no relay envelope is created for that participant

#### Scenario: Promoting a participant to connected unlocks sync
- **WHEN** the user promotes a local-only Contact to connected via the handshake flow
- **THEN** the module's existing participant rows referencing that Contact retain their identifier
- **THEN** subsequent module proposals can be sent to that Contact through the relay

### Requirement: Module participant rows do not embed mutable identity fields
After adoption, a module's participant row SHALL embed only:
- the Contact identifier (reference),
- module-specific attributes (role, ratio, per-module alias, etc.),
- optional historical display snapshots (name, avatar at time of acceptance, per `contacts-domain-model`).

Module participant rows SHALL NOT embed a "live" name or avatar field as the authoritative current identity.

#### Scenario: Updating a contact's name updates all module displays
- **WHEN** the local user renames a Contact
- **THEN** every module's current display of that participant reflects the new name
- **THEN** historical snapshot fields (if any) remain unchanged

### Requirement: Modules MAY define a per-module display alias
A module MAY allow the user to set a per-module display alias for a participant (e.g., a nickname used only inside that module's UI). The alias SHALL be stored on the module participant row, not on the Contact. The alias SHALL NOT override the Contact's authoritative display name elsewhere in the app.

#### Scenario: Vehicle alias does not leak into housing
- **WHEN** the user sets a vehicle-specific alias for a Contact
- **THEN** the vehicle UI shows the alias for that participant
- **THEN** the housing UI continues to show the Contact's authoritative display name

### Requirement: Connection state is reflected in module participant pickers
The contact picker shown inside a module SHALL clearly distinguish connected Contacts from local-only Contacts (e.g., via a small status indicator), so the user understands which participants can receive module proposals and which cannot.

#### Scenario: Picker shows connection state
- **WHEN** a user opens the housing participant picker
- **THEN** each Contact entry visibly indicates whether it is connected or local-only
- **THEN** the user can initiate a handshake from within the picker for local-only Contacts
