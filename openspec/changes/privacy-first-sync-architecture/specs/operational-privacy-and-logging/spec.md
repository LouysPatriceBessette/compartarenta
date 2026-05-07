## ADDED Requirements

### Requirement: Application and infrastructure logs exclude user payload content
Production logging for client and server components involved in relay and entitlement SHALL NOT include plaintext user operational data, decrypted relay bodies, or decryption keys.

This applies to **ledger synchronization messages**: expense amounts, payer splits, free-text descriptions, and any decrypted accept/reject rationale SHALL NOT appear in logs.

#### Scenario: Debug logging is disabled for sensitive paths in release builds
- **WHEN** a release build is produced
- **THEN** relay encryption/decryption paths do not emit payload contents to logs

### Requirement: Metadata retention is documented and minimized
Any unavoidable metadata (e.g., timestamps, coarse routing identifiers, IP addresses at load balancers) SHALL be documented with purpose and retention. The product SHALL minimize metadata needed for relay routing and abuse prevention.

If outer routing metadata includes **message category** (e.g., proposal vs control), **proposal identifiers**, or correlation ids, documentation SHALL state that such fields are not a substitute for reading user plaintext and SHALL justify why each field is necessary.

#### Scenario: Privacy documentation lists metadata categories
- **WHEN** the repository privacy architecture document is published
- **THEN** it enumerates metadata categories processed by relay and entitlement services and their retention windows

#### Scenario: Acceptance and rejection are not logged as plaintext events on the server
- **WHEN** a user accepts or rejects a proposal on device
- **THEN** server-side logs do not record the decision or expense details in plaintext as part of default relay operation (optional first-party telemetry, if any, is covered separately and MUST NOT contradict product privacy claims)

### Requirement: Backups and replicas do not defeat relay deletion semantics
Operational practices for databases, object stores, queues, and backups SHALL be consistent with “no durable copy after successful relay delivery” for ciphertext payloads. If backups unavoidably capture queue state, the documentation SHALL state the window and mitigations (e.g., encrypted-at-rest with tight retention, excluded paths).

#### Scenario: Backup policy is aligned with relay TTL
- **WHEN** infrastructure backups are configured for relay storage
- **THEN** the documented backup retention does not imply indefinite payload retention beyond the relay TTL semantics without explicit disclosure

### Requirement: Abuse prevention without bulk content inspection
Abuse prevention (rate limits, quotas, spam controls) SHALL be implementable without access to user plaintext payloads, relying on metadata, ciphertext size limits, reputation signals, and/or client-attested constraints.

#### Scenario: Rate limiting does not require decryption
- **WHEN** relay rate limiting triggers
- **THEN** enforcement does not depend on reading decrypted user payloads
