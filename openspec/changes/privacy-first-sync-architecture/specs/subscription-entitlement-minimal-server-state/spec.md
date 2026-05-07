## ADDED Requirements

### Requirement: Server durable state is limited to subscription validation needs
The server SHALL NOT durably store user operational payloads (calculation inputs, outputs, or shared business-domain records) as part of the core product architecture. The only durable server-side user-associated records SHALL be those strictly necessary to validate that an in-app subscription (usage right) is active, plus unavoidable technical identifiers required to authenticate API access.

Relay ciphertext MAY contain **ledger synchronization messages** (e.g., proposed expenses, accept/reject, amendments); those remain transport artifacts and SHALL NOT be copied into durable “user ledger” or analytics tables as part of core architecture. If any short-lived processing buffer holds them, retention SHALL follow `relay-sync-no-persistence`.

#### Scenario: Schema review excludes user payload tables
- **WHEN** the server database schema is defined or changed
- **THEN** it does not include tables or columns intended to store user operational payloads for the core product

#### Scenario: No durable mirror of accepted ledger rows
- **WHEN** a recipient accepts a proposal on their device
- **THEN** the server does not gain a durable copy of the resulting accepted ledger row solely because acceptance occurred (acceptance is local per `data-locality-and-client-storage`)

### Requirement: Entitlement checks are explicit and separable from relay
Subscription validation SHALL be implemented as a distinct concern from relay message handling, so that entitlement logic cannot accidentally persist relay payloads.

#### Scenario: Relay handler cannot write to entitlement payload storage
- **WHEN** relay message ingestion is implemented
- **THEN** it does not write user operational payloads to durable entitlement or user profile storage

### Requirement: Receipt validation data is minimized
Store receipt or entitlement validation artifacts SHALL be retained only as long as needed for fraud prevention, auditing, or store-required reconciliation, and SHALL be documented with retention limits.

#### Scenario: Retention policy is documented
- **WHEN** the product ships with server-side receipt validation
- **THEN** repository documentation states what validation artifacts are stored, why, and for how long
