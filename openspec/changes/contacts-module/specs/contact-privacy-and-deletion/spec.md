## ADDED Requirements

### Requirement: Contact metadata never reaches the relay in plaintext
Contact display names, avatar identifiers, and any free-text notes SHALL NEVER be transmitted to the relay in plaintext. They MAY only travel between connected contacts inside encrypted envelopes (e.g., the handshake `hello` and `ack`, or profile-update envelopes per `contact-handshake-over-relay`).

#### Scenario: Relay request bodies and headers carry no plaintext contact metadata
- **WHEN** the app submits any relay request related to a contact (handshake, module proposal, profile update)
- **THEN** any name, avatar identifier, or note belonging to a contact is present only inside the encrypted payload
- **THEN** request headers, query parameters, and the relay's persistent state contain no plaintext name or avatar (consistent with `relay-state-schema-and-retention`)

### Requirement: The app does not upload the user's contact list to any server
The app SHALL NOT upload, mirror, or analyze the user's full Contacts list to the relay, to a marketing service, to an analytics service, or to any other server. Network exchanges involving contacts are limited to per-pair encrypted envelopes between explicitly connected contacts.

#### Scenario: No bulk contact upload is performed
- **WHEN** the app starts, syncs, or runs background tasks
- **THEN** no request is made that enumerates the user's local Contacts to a remote endpoint
- **THEN** background sync activity is limited to per-pair encrypted envelopes between connected contacts

### Requirement: OS-level address-book permission is not requested by Contacts
The Contacts capability SHALL function without requesting the operating system's address-book permission (Apple Contacts permission, Android `READ_CONTACTS` permission). If a future feature ever requires such permission, it SHALL be introduced through its own change with explicit privacy review; the Contacts capability defined here does NOT request it.

#### Scenario: Contacts area opens without OS address-book permission
- **WHEN** the user opens the Contacts area for the first time
- **THEN** the app does not prompt for the OS address-book permission
- **THEN** the app does not include code paths that access the OS address book on behalf of this capability

### Requirement: Contact deletion is local and reversible only by recreation
Deleting a Contact SHALL:
- mark the Contact as deleted/archived on this device,
- preserve historical snapshots already captured on module participant rows referencing the deleted Contact (per `contacts-domain-model`),
- prevent new module participant rows from referencing the deleted Contact.

Deleting a Contact SHALL NOT send any "delete me from your device" message through the relay; deletion is a unilateral local action on this device only.

#### Scenario: Deleting a contact leaves history readable
- **WHEN** the user deletes a Contact previously referenced by a module
- **THEN** existing module ledger rows still display the historical snapshot name and avatar
- **THEN** the user cannot pick the deleted Contact when adding new module participants

#### Scenario: Deletion does not affect the peer's device
- **WHEN** the user deletes a connected Contact on their device
- **THEN** the peer's device retains its Contact for this user (no relay message is sent to delete the relationship)
- **THEN** if the user wishes to communicate the disconnection, an explicit "disconnect" action SHALL be used (specified below)

### Requirement: Disconnecting a connected contact is an explicit, separate action
The app SHALL provide an **explicit "Disconnect contact"** action separate from "Delete contact". Disconnecting SHALL:
- change the local Contact's kind back to local-only (so it can no longer receive module proposals from this device),
- send a small encrypted "disconnect" envelope to the peer through the relay so the peer can drop the connection on their side,
- have no effect on either side's accepted ledger data (historical snapshots remain).

#### Scenario: Disconnect notifies the peer
- **WHEN** the user disconnects a connected Contact
- **THEN** the local Contact's kind transitions to local-only on this device
- **THEN** an encrypted disconnect envelope is dispatched through the relay (subject to TTL like any other envelope)
- **THEN** subsequent module proposals to that Contact stop on this device

#### Scenario: Peer receives the disconnect signal
- **WHEN** the peer device receives the disconnect envelope
- **THEN** the peer's Contact for this user transitions to local-only on their device
- **THEN** the peer's existing module ledger rows referencing the now-local-only Contact remain readable; new module proposals to this Contact from the peer's device stop

### Requirement: A blocked contact is treated as disconnected and ignored
The app SHALL allow the user to **block** a Contact, which combines disconnection with a local rule that suppresses any inbound envelope from that Contact, even if a connection somehow re-emerges later. Blocking SHALL be a local-only enforcement; the relay SHALL NOT be asked to host blocklists.

#### Scenario: Blocked contact's envelopes are dropped on receipt
- **WHEN** the user blocks a connected Contact and an inbound envelope from that Contact is later delivered to this device
- **THEN** the device discards the envelope without surfacing its content
- **THEN** the relay does not know about the block (consistent with `relay-state-schema-and-retention`)

### Requirement: Privacy disclosures cover the Contacts capability
`mobile-app-privacy-compliance` SHALL be updated when this capability ships to describe the data the app collects on behalf of Contacts (display name, avatar, public material, opaque routing identifiers) and to confirm that no OS address-book permission is used. This Contacts capability SHALL ensure its privacy disclosure is consistent with what the implementation actually does.

#### Scenario: Privacy disclosure matches behavior
- **WHEN** the privacy disclosure for the Contacts capability is reviewed
- **THEN** it states no OS address-book access, no bulk contact upload, and per-pair encrypted envelopes only
- **THEN** the disclosure matches the requirements in this capability
