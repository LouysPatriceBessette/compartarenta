## ADDED Requirements

### Requirement: A public threat model explains trust boundaries
The repository SHALL include a threat model document describing trusted components (user device, OS, stores), untrusted network, and relay operator capabilities, including what an attacker with relay access can and cannot learn.

The threat model SHALL explicitly cover the **proposal-based ledger sync** model: transport delivery of ciphertext, local **accept** and **reject**, and amended proposals after rejection, aligned with `data-locality-and-client-storage` and `relay-sync-no-persistence`.

#### Scenario: Threat model references E2EE and metadata
- **WHEN** a reviewer reads the threat model
- **THEN** they can identify what confidentiality and integrity guarantees apply to ciphertext on the relay and what metadata is still visible

#### Scenario: Threat model states what the relay learns without decryption
- **WHEN** the threat model is complete
- **THEN** it states whether routing metadata (e.g., recipient, message category, proposal ids) is visible to the relay and what user harm scenarios remain (e.g., traffic analysis)

### Requirement: Claims in README match verifiable surfaces
Public claims about “no user data retained on servers beyond subscription validation” SHALL be qualified to match what can be verified from open artifacts (client source, open server source, published APIs) or SHALL explicitly call out what requires external audit.

#### Scenario: README distinguishes verified vs audited assertions
- **WHEN** the repository is public
- **THEN** top-level documentation distinguishes claims backed by open code from claims dependent on deployment or third-party review

### Requirement: Protocol and persistence semantics are machine-reviewable where practical
The relay protocol (authorization model, TTL, ack semantics, error codes) SHALL be specified in a stable document under version control (e.g., OpenAPI or protocol markdown) so changes can be reviewed in pull requests.

The protocol specification SHALL include the **ledger synchronization message lifecycle**: proposal submission, delivery ack, accept/reject messages, superseding amended proposals after reject, and identifier rules (message id, proposal id), consistent with `relay-sync-no-persistence` and `end-to-end-encryption`.

#### Scenario: Protocol change triggers spec review
- **WHEN** a pull request changes relay protocol semantics
- **THEN** the corresponding spec requirements or scenarios are updated in the same change unless explicitly deferred with a tracked follow-up

### Requirement: Automated tests cover deletion and non-retention paths
The system SHALL include automated tests that assert relay deletion after successful delivery (or TTL expiry) at the appropriate layer (integration tests against a test relay, or contract tests with fakes), in addition to manual runbooks.

#### Scenario: CI fails if relay retention regresses
- **WHEN** relay persistence behavior regresses to retain delivered ciphertext
- **THEN** automated tests fail in continuous integration

### Requirement: Client tests cover proposal acceptance boundaries
Automated client tests SHALL cover that **delivery of ciphertext does not imply ledger mutation** without an explicit local accept path, and that **reject** does not leave accepted ledger traces for that proposal id (per product rules for pending state cleanup).

#### Scenario: Pending proposal does not affect published balance
- **WHEN** a proposal ciphertext is delivered but not accepted
- **THEN** tests assert that balances computed from the accepted ledger exclude that proposal
