## ADDED Requirements

### Requirement: User operational data for calculations resides on-device by default
The application SHALL persist user operational data used for calculations in on-device storage (a client-side database or equivalent) unless the user explicitly initiates an export or sharing flow that transmits ciphertext only.

Operational data includes, at minimum: shared expenses (or grouped expenses), per-expense or per-group payment ratios agreed between participants, payments recorded per user, and derived balances (e.g., who owes whom).

#### Scenario: Core calculation workflow without server payload upload
- **WHEN** the user performs actions that generate or update operational data used for in-app calculations
- **THEN** that data is stored locally and is not required to be uploaded to the server for the calculation to complete

#### Scenario: Balance display uses only accepted local ledger entries
- **WHEN** the app displays what one participant owes another (if any)
- **THEN** the displayed amounts are computed from expense and payment records that are present in that user’s on-device ledger according to the documented acceptance rules

### Requirement: Local data lifecycle is explicit and user-visible where appropriate
The product SHALL document (in repository documentation and/or in-app settings) what categories of data are stored locally, for what purpose, and how the user can delete local data.

#### Scenario: User requests local data deletion
- **WHEN** the user triggers a documented local reset or uninstall path
- **THEN** locally stored operational data is removed according to the documented behavior for that action

### Requirement: Shared expense domain model is represented locally
The client-side store SHALL represent shared expenses (including optional grouping), agreed split ratios per expense or per group, and payments attributed to users such that the application can compute settlement balances between participants.

#### Scenario: Ratio agreement is attached to expense or group
- **WHEN** participants configure how much each person should pay for an expense or a defined group of expenses
- **THEN** those ratio rules are stored as part of the local expense model and participate in balance calculations

### Requirement: Synchronization applies peer changes as proposals, not silent overwrites
When synchronizing, incoming updates from another participant (for example, a new expense created on the peer’s device) SHALL be applied to this user’s ledger only after an explicit **accept** action on this device. Until acceptance, the change SHALL remain a pending proposal (or equivalent state) and SHALL NOT affect published balances as if it were already agreed ledger data.

#### Scenario: Typical sync updates recipient after peer adds an expense
- **WHEN** a peer adds an expense that should appear in the shared accounting context
- **THEN** the recipient receives a proposed ledger update (via the encrypted relay path) and sees it as pending until they accept or reject it

#### Scenario: Rejected expense does not become ledger truth
- **WHEN** the user rejects a proposed expense (or correction) from a peer
- **THEN** that proposal is not incorporated into the user’s accepted ledger and the displayed balances do not treat it as an agreed expense

#### Scenario: Peer must resend a corrected expense after rejection
- **WHEN** a proposal is rejected
- **THEN** the originating peer is able to submit a new proposed expense (or amended proposal) through the same proposal channel, and the recipient again decides accept or reject

### Requirement: Ownership of accepted ledger data is local to the accepting user’s device
Authority over whether a given expense (or correction) is part of a user’s accounting truth SHALL NOT be derived from “who sent the message.” Once a transaction or expense record is **accepted** on a device, that device’s user SHALL be treated as the owner of that copy for local accounting purposes: it is stored in their client-side database as part of their accepted ledger and participates in calculations like any other locally originated accepted entry, subject to the same edit/delete rules defined by the product.

#### Scenario: Accepted peer expense is first-class local data
- **WHEN** the user accepts a proposed expense from a peer
- **THEN** the expense is persisted in the on-device ledger with the same standing as locally entered accepted data for balance and history features (within any product rules for immutability or audit trails)

#### Scenario: Sender is not the long-term authority after acceptance
- **WHEN** a peer’s proposed expense has been accepted on this device
- **THEN** subsequent balance calculations on this device do not depend on the peer’s device remaining the “source of truth” for that row; the accepted copy on this device is sufficient for local computation and display

### Requirement: Sharing does not replace local-first storage
The application SHALL continue to treat the client-side store as the system of record for each user’s **accepted** operational data; relayed ciphertext is a synchronization transport for proposals and outcomes, not a hosted system of record that replaces the user’s on-device ledger.

#### Scenario: Successful relay delivery does not bypass acceptance
- **WHEN** a relayed ciphertext message is successfully delivered to a peer
- **THEN** the recipient’s accepted ledger changes only if the recipient accepts the proposal (or an equivalent explicit confirmation defined by the product)

### Requirement: One active installation per user identity
The product SHALL treat each real-world participant as having **at most one active app installation** that holds their cryptographic identity and local database at a time. The system SHALL NOT provide server-side synchronization of a single user’s operational data across multiple simultaneous devices. Moving to a new device SHALL be handled only through the documented **export / import** (or equivalent one-time migration) path when the prior device is lost, broken, or replaced—not through live multi-device sync.

#### Scenario: No cross-device ledger sync
- **WHEN** the same person installs the app on a second device while the first installation still holds data
- **THEN** the product does not merge or reconcile the two local databases through any server
- **AND** each installation is an independent identity unless the user performs a documented migration from one device to the other

#### Scenario: Export supports device replacement only
- **WHEN** the user exports data from one installation and imports it on another
- **THEN** the purpose is recovery or device replacement
- **AND** the product does not treat this as ongoing multi-device use of the same identity
