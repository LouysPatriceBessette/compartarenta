## ADDED Requirements

### Requirement: Modules integrate with Contacts through a documented integration contract
Each module that involves participants SHALL adopt the Contacts model by:
- exposing a participant picker that lists **connected** Contacts and offers an **Invite** entry point when the desired person is missing,
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
- **THEN** the user sees the contact picker listing connected contacts (or its empty state with invite)
- **THEN** there is no path to create a "temporary participant" with inline name/avatar as the authoritative participant record

### Requirement: A connected contact can be referenced by any module
A Contact whose kind is `connected` SHALL be eligible to be referenced as a participant by any module the local user enables. Eligibility is not module-specific.

#### Scenario: Same connected contact appears in housing and vehicle pickers
- **WHEN** the user has a connected Contact and `housing`, `vehicle`, and/or `vehicle-sharing` are enabled as applicable
- **THEN** that Contact is selectable in each enabled module's participant pickers
- **THEN** picking the Contact in one module does not enroll the Contact in another module

### Requirement: Local-only contacts MUST NOT be selected as module co-participants
A Contact whose kind is `local-only` SHALL NOT appear in module participant pickers and SHALL NOT be accepted when persisting new co-participant rows for relay-backed collaboration. **Rationale (commercial):** every co-participant is expected to use the app on their own account with a valid entitlement; connection proves the relationship and supplies routing material for encrypted relay traffic.

#### Scenario: Picker lists connected contacts only
- **WHEN** a user opens a module participant picker
- **THEN** only Contacts with kind `connected` (and not locally blocked) are listed
- **THEN** the user can open the invite flow from the picker when nobody suitable is connected yet

#### Scenario: Legacy plan rows referencing local-only placeholders
- **WHEN** a plan still references a migration-created or demoted local-only Contact as a co-participant
- **THEN** the module SHALL block advancing or saving until the user replaces that slot with a connected Contact (or otherwise satisfies the module's validation), without silently treating the person as a full relay participant

### Requirement: Proposals and activation require connected contacts only
Housing (and other relay-backed modules) SHALL reject **send**, **final accept**, and **activation** when any co-participant row references a contact that is not `kind == connected` with relay routing material. Stubs, disconnected, and local-only rows MUST NOT appear in authoritative roster slots at send or activation time.

#### Scenario: Send blocked without connected peer
- **WHEN** a housing draft lists a co-participant whose contact is not connected on the author device
- **THEN** send is blocked before any relay POST

### Requirement: Module participant rows do not embed mutable identity fields
After adoption, a module's participant row SHALL embed only:
- the Contact identifier (reference),
- module-specific attributes (role, ratio, per-module alias, etc.),
- optional **denormalized** display fields (`displayName`, `avatarId`) that mirror the linked Contact for roster rendering and offline matching, updated when the Contact’s canonical profile changes (inbound `profile_update` or local contact merge) **except** while an open housing vote freezes roster identity per `housing-plan-proposal-offer-flow`,
- optional **historical** display snapshots (name, avatar at time of acceptance, per `contacts-domain-model`) that MUST NOT change after capture.

The Contact remains the **authoritative** source for current peer identity; participant display fields are not a second canonical store.

#### Scenario: Updating a contact's name updates module roster rows
- **WHEN** the local device applies a canonical name or avatar change for a Contact (inbound `profile_update` or equivalent)
- **THEN** every module participant row with that `contactId` updates its denormalized `displayName` / `avatarId` to match
- **THEN** historical snapshot fields (if any) remain unchanged
- **THEN** current module UI that reads roster display fields reflects the new name

#### Scenario: Open housing vote freezes self display name on roster
- **WHEN** the local user is on roster for an open housing vote and attempts to change their own display name
- **THEN** the change is blocked in Settings and no name-bearing `profile_update` is sent
- **THEN** existing roster rows for that vote remain unchanged until the vote closes

### Requirement: Modules MAY define a per-module display alias
A module MAY allow the user to set a per-module display alias for a participant (e.g., a nickname used only inside that module's UI). The alias SHALL be stored on the module participant row, not on the Contact. The alias SHALL NOT override the Contact's authoritative display name elsewhere in the app.

#### Scenario: Vehicle-sharing alias does not leak into housing
- **WHEN** the user sets a vehicle-sharing-specific alias for a Contact
- **THEN** the vehicle-sharing UI shows the alias for that participant
- **THEN** the housing UI continues to show the Contact's authoritative display name

### Requirement: Connection state in module pickers
Because module pickers list **connected** contacts only, the picker MAY treat every row as connected for labeling purposes; blocked contacts MUST remain excluded from selection.

#### Scenario: Picker does not offer blocked contacts as participants
- **WHEN** a Contact is marked blocked locally
- **THEN** that Contact is not offered in module participant pickers
