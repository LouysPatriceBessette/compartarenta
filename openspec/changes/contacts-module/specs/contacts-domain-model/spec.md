## ADDED Requirements

### Requirement: A Contact is a first-class on-device entity
The app SHALL persist a **Contact** entity as a first-class record on-device. A Contact SHALL have, at minimum:
- a stable on-device identifier that does not change over the lifetime of the contact,
- a display name chosen by the local user,
- an avatar identifier (referencing an avatar selection consistent with `initial-configuration`),
- a kind flag distinguishing **local-only** contacts from **connected** contacts,
- timestamps for creation and last update.

Connected contacts SHALL additionally persist the relay-routing identifier and the public key material needed to encrypt envelopes addressed to that contact, per `end-to-end-encryption`.

#### Scenario: Local-only row exists only for connection lifecycle or legacy migration
- **WHEN** the app needs a contact row before a handshake completes, after a disconnect demotion, or when mirroring legacy module participants during migration
- **THEN** the row MAY exist with kind = local-only and SHALL NOT be treated as an eligible co-participant in relay-backed modules until kind becomes `connected`
- **THEN** the Contact has no routing identifier and no peer public material while it remains local-only

#### Scenario: Promotion from local-only to connected
- **WHEN** a successful handshake completes for a contact stub (per `contact-handshake-over-relay`)
- **THEN** the Contact's kind transitions from local-only to connected
- **THEN** the stable identifier of the Contact is unchanged across this promotion

### Requirement: Modules reference Contacts instead of authoring inline participants
After this capability is in place, modules that ask the user to "add a participant" (e.g., a housing participant, a vehicle participant) SHALL author the participant by **referencing an existing connected Contact** (selected through the module picker) or by driving the user to **invite and complete a handshake** first. Modules SHALL NOT introduce new ad-hoc participants that bypass the Contacts data model.

#### Scenario: Adding a housing co-participant uses the contact picker
- **WHEN** a user adds a new co-participant to a housing plan after this capability is enabled
- **THEN** the user picks from connected Contacts or uses the picker's invite entry point so the peer can become connected
- **THEN** the housing participant row references the Contact identifier; it does NOT embed a fresh inline name/avatar pair as the authoritative record

#### Scenario: Module participants reflect the effective contact name
- **WHEN** the local user changes how a contact is shown (canonical peer update and/or **local display label** per `contact-peer-display-ownership`)
- **THEN** every module participant referencing that Contact reflects the updated **effective** name in subsequent displays
- **THEN** historical ledger entries previously displayed under an older effective name continue to be readable; presentation MAY show the current effective name

### Requirement: User-facing status distinguishes disconnected ex-peers
Contacts whose **technical** kind is `local-only` **only because** they were demoted after a prior `connected` relationship (disconnect per `contact-privacy-and-deletion`) SHALL be shown to the user as **Disconnected** (localized), not with the same copy as never-connected invitation stubs.

#### Scenario: Disconnected is not “never connected”
- **WHEN** a contact row has no routing material after a completed disconnect
- **THEN** the Contacts UI presents **Disconnected** (or equivalent localized label) for that row
- **WHEN** a contact row is a pre-handshake invitation stub that was never `connected`
- **THEN** the UI SHALL NOT present the same status string as for a post-disconnect demotion (exact strings are a UX decision documented under `contact-peer-display-ownership`)

### Requirement: Canonical vs local display fields
The on-device shape that stores **peer canonical** identity separately from **local display label** is specified in `contact-peer-display-ownership`. The Contacts domain model SHALL remain the anchor for stable `Contact.id` and `kind`; label fields MAY be added without changing module foreign keys.

### Requirement: Modules retain a snapshot view of a contact's name and avatar at moments of historical record
For historical readability (per `data-locality-and-client-storage`), modules MAY persist a per-row **display snapshot** (name, avatar) captured at the time a record was accepted into the local ledger. The snapshot SHALL be informational; the Contact reference SHALL remain the authoritative identity link.

#### Scenario: Deleted contact does not erase historical ledger readability
- **WHEN** a user deletes a Contact that previously appeared in module ledger entries
- **THEN** historical entries continue to display the snapshot name/avatar captured at acceptance time
- **THEN** new entries can no longer reference the deleted Contact

### Requirement: Per-module participant attributes remain owned by the module
A Contact SHALL hold identity data only (name, avatar, routing, public material). Per-module attributes such as ratio, role, or per-module display alias SHALL be stored by the module itself, on the module's participant row that references the Contact.

#### Scenario: Same contact, different roles per module
- **WHEN** a user has a Contact referenced as a housing participant and also referenced as a vehicle participant
- **THEN** the contact's identity (name, avatar) is shared
- **THEN** each module independently stores its own role, ratio, and module-specific attributes for that participant

### Requirement: The Contacts list is consultable independently from any module
The app SHALL provide a Contacts area (list, detail, edit) reachable from the main shell, usable even when no module is active or enabled. The Contacts area SHALL exist for users who have not yet linked any participant to any module.

#### Scenario: New user can manage contacts before adding to a module
- **WHEN** a freshly onboarded user opens the Contacts area before adding a housing or vehicle participant
- **THEN** the area is reachable, the empty state is informative, and the user can start an invitation or redeem a code to build connected contacts

### Requirement: Existing module participants are migrated into Contacts on first upgrade
On the first launch of an app version that introduces Contacts, the app SHALL run a one-time migration that creates a Contact for each unique participant referenced by an existing module, and rewrites each module's participant row to reference its corresponding Contact identifier. The de-duplication policy across modules SHALL be conservative: identical (display name, avatar) pairs MAY be unified into one Contact; otherwise distinct Contacts are created and the user MAY merge them manually later.

Migration SHALL produce **local-only** Contacts. It SHALL NOT create connected Contacts and SHALL NOT initiate any handshake or relay traffic on the user's behalf. **Commercial / product rule:** those migrated rows are placeholders; co-participants in relay-backed plans SHALL NOT remain on migration-only local rows once the product enforces connected-only participation—the user MUST invite each person and complete connection (and thus satisfy licensing / sign-in on their device) before they count as valid co-participants.

#### Scenario: Migration unifies identical name+avatar across modules
- **WHEN** the same (display name, avatar) pair existed as a participant in both housing and a hypothetical other module before the upgrade
- **THEN** the migration creates one Contact and both modules reference it
- **THEN** the resulting Contact's kind is local-only until a handshake promotes it

#### Scenario: Migration does not auto-connect contacts
- **WHEN** the migration runs
- **THEN** no invitation code is generated and no handshake message is sent
- **THEN** all migrated Contacts are local-only until the user explicitly initiates a handshake later
