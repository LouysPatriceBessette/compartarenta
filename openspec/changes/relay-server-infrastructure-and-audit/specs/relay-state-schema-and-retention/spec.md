## ADDED Requirements

### Requirement: The relay database schema is explicitly enumerated and minimal
The relay database SHALL contain only the following kinds of data, and SHALL NOT contain anything else:

1. **Routing relationships** between connected users (opaque identifiers only, with established-at and status timestamps).
2. **Idempotency entries** (opaque idempotency key, sender opaque identity, created-at, ttl-expires-at).
3. **Undelivered ciphertext envelopes** (envelope id, sender opaque identity, recipient opaque identity, ciphertext blob, created-at, ttl-expires-at, delivered-at — null until delivered).
4. **Operational housekeeping rows** strictly required for the relay to run (e.g., schema version, sweeper checkpoints).

#### Scenario: A new table requires a documented purpose
- **WHEN** a future relay change introduces a new database table
- **THEN** the proposed table falls into one of the enumerated categories or is rejected
- **THEN** the documentation of the schema is updated as part of the same change

### Requirement: The relay database SHALL NOT store user payload plaintext
The relay database SHALL NOT contain any cleartext field that represents:
- expense amounts, expense categories, expense descriptions, attachments, dates;
- contact display names, avatars, notes, free-text profile data;
- module-specific data (housing plans, vehicle data, etc.);
- user email addresses, phone numbers, postal addresses, real names;
- device or hardware identifiers beyond opaque routing identifiers.

#### Scenario: A schema dump contains no plaintext user content
- **WHEN** an auditor extracts the schema (DDL) and a sample of rows from the relay database
- **THEN** no row contains any field that decodes to user-facing plaintext content
- **THEN** ciphertext fields are not human-readable

### Requirement: Opaque identities are not derived from user-presented identity
Routing identifiers stored in the relay database SHALL be opaque values whose generation does NOT include any user-presented identity attribute (no derivation from display name, email, phone, avatar, or any other contact metadata). They MAY be derived from the cryptographic public material exchanged during the handshake (which is itself not user identity).

#### Scenario: Routing identifier is not a hashed name
- **WHEN** an auditor inspects how routing identifiers are generated
- **THEN** the derivation function takes only opaque cryptographic material as input
- **THEN** there is no path from a known display name or email to the corresponding routing identifier

### Requirement: Envelopes are deleted after successful delivery to all intended recipients
A stored envelope SHALL be deleted from the database as soon as every intended recipient has acknowledged delivery (per `relay-sync-no-persistence`). The deletion SHALL be observable in metrics (counter incremented).

#### Scenario: Two-recipient envelope is deleted after both ack
- **WHEN** an envelope addressed to two recipients has both recipients ack delivery
- **THEN** the envelope row is removed from the database within a short, documented bound
- **THEN** subsequent fetches by either recipient return a not-found / already-delivered response

### Requirement: Undelivered envelopes are deleted at TTL expiry
A stored envelope undelivered past its `ttl_expires_at` SHALL be deleted by a periodic sweeper task. The sweeper SHALL run on a documented cadence and SHALL emit metrics indicating the number of envelopes expired per run.

#### Scenario: Sweeper deletes expired envelopes
- **WHEN** the sweeper runs and an envelope's TTL has expired without successful delivery
- **THEN** the envelope row is deleted
- **THEN** subsequent fetches by the intended recipient return a not-found / expired response

### Requirement: Idempotency entries are bounded by TTL
Idempotency entries SHALL be bounded by `ttl_expires_at`. Expired idempotency entries SHALL be deleted by the same (or a parallel) sweeper. Idempotency entries SHALL NOT be retained indefinitely.

#### Scenario: Expired idempotency entries are removed
- **WHEN** an idempotency entry's TTL has expired
- **THEN** the sweeper deletes the entry within the documented sweeper cadence

### Requirement: Routing relationships persist until severed by an explicit event
Routing relationships SHALL persist as long as both parties have a connected Contact (per `contacts-domain-model`). A relationship SHALL be removed by the relay only as the result of an explicit severing event:
- one side sends a documented "disconnect" envelope and that envelope is delivered to the peer, OR
- both sides have been inactive for a documented long-inactivity threshold (the spec sets a minimum window), OR
- abuse / operator action takes the relationship down with an audit trail.

#### Scenario: Disconnect deletes the routing row
- **WHEN** a disconnect envelope from one side is delivered to the peer
- **THEN** the relay deletes the routing relationship row after a documented short grace window for any in-flight envelopes addressed to it

### Requirement: TTL values fall within documented bounds and are publicly stated
The TTLs used for undelivered envelopes and for idempotency entries SHALL be documented values that fall within bounds stated in the relay project's documentation. The bounds SHALL be conservative (envelope TTL is days, not months; idempotency window is hours, not weeks).

#### Scenario: TTL configuration is auditable
- **WHEN** an auditor inspects the relay's runtime configuration
- **THEN** the deployed TTL values match the documented bounds
- **THEN** any change to a TTL value is accompanied by a documented justification

### Requirement: Schema migrations are versioned and reviewable
Database schema changes SHALL be applied via versioned migrations stored in the public repository. Migrations SHALL be append-only with respect to history (no editing past migrations after they ship). The relay SHALL refuse to start if its on-disk schema version is incompatible with the binary's expected schema version.

#### Scenario: Migration history is reviewable
- **WHEN** an auditor inspects the migrations directory
- **THEN** the migrations describe every change to the schema that has shipped
- **THEN** the current schema can be reconstructed by replaying the migrations

### Requirement: Backups respect the no-long-term-retention promise
If backups of relay state exist, they SHALL contain only routing relationships and operational housekeeping rows. Backups SHALL NOT extend the practical lifetime of user payloads (i.e., they SHALL NOT contain envelope ciphertext beyond the envelope TTL). The backup retention policy SHALL be documented.

#### Scenario: Backups omit envelope ciphertext past TTL
- **WHEN** an auditor inspects a backup artifact
- **THEN** the backup contains no envelope rows older than the documented TTL
- **THEN** the backup retention policy matches what is documented in the repository
