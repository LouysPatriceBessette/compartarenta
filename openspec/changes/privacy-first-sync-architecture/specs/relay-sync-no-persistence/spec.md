## ADDED Requirements

### Requirement: Relay carries encrypted ledger synchronization messages only
The relay SHALL transport **encrypted ledger synchronization messages** between participants. These messages include (non-exhaustively): proposed expense or ledger updates, explicit **accept** and **reject** outcomes, and follow-up **amended proposals** after rejection. The relay SHALL NOT interpret message types as authorization to mutate any server-side ledger; ledger truth remains client-side per `data-locality-and-client-storage`.

#### Scenario: Transport delivery is distinct from ledger acceptance
- **WHEN** the relay completes delivery of a ciphertext to the recipient device (per ack/TTL rules below)
- **THEN** that event means only that the ciphertext was available to the client, not that the expense is part of the recipient’s accepted on-device ledger

### Requirement: Relay stores ciphertext only and only until delivery succeeds
The relay SHALL accept only encrypted payloads from clients. The relay SHALL retain a given relay message only until it is successfully delivered to all intended recipients (or until a documented timeout/TTL expires), after which the ciphertext SHALL be deleted from relay storage.

#### Scenario: Successful delivery deletes relay copy
- **WHEN** all intended recipients acknowledge successful receipt (or equivalent delivery completion signal)
- **THEN** the relay no longer returns that message and no longer retains it in durable relay storage

### Requirement: TTL bounds relay retention on failure
If delivery cannot be completed within a configured time window, the relay SHALL delete the undelivered ciphertext after TTL expiry and SHALL NOT fall back to indefinite retention.

#### Scenario: Undelivered message expires
- **WHEN** a relay message remains undelivered past its TTL
- **THEN** the relay deletes the message and subsequent fetch attempts receive a not-found or expired response

### Requirement: Relay does not transform user plaintext
The relay SHALL NOT decrypt or re-encrypt user payloads for product purposes. If transport encryption (e.g., TLS) is used, it is separate from payload encryption and SHALL NOT be presented as end-to-end protection.

#### Scenario: Server process memory does not require plaintext access
- **WHEN** relay software processes an incoming message
- **THEN** it validates framing, authorization, TTL, and routing using metadata and ciphertext only

### Requirement: Message identity supports proposals, rejections, and corrections
The protocol SHALL allow recipients and senders to correlate messages using stable **message identifiers** (and, where applicable, **proposal identifiers**) carried in metadata or an authenticated outer envelope, without exposing plaintext expense fields to the relay. After a **reject**, a subsequent **amended proposal** SHALL use a new proposal identifier (or documented supersession semantics) so that retries and corrections are auditable and idempotency does not resurrect rejected ledger content.

#### Scenario: Rejected proposal is not revived by a transport retry
- **WHEN** the originator retries network delivery with the same idempotency key for the same proposal envelope
- **THEN** the relay semantics do not cause a previously rejected proposal to become a second durable server-side copy beyond the defined idempotency window

#### Scenario: Amended expense after rejection is a distinct proposal
- **WHEN** a peer sends a corrected expense after the recipient rejected an earlier proposal
- **THEN** the new ciphertext is distinguishable as a new proposal (new proposal id or documented replacement chain) from the rejected one

### Requirement: Idempotency without content logging
The relay MAY use idempotency keys and deduplication structures to avoid double delivery, but SHALL NOT require logging message bodies for correctness.

#### Scenario: Duplicate submission does not create a second durable copy
- **WHEN** the same idempotent send is retried by the client
- **THEN** the relay does not create an additional durable ciphertext record beyond the semantics defined for that idempotency key

### Requirement: Transport routing push tokens are out of band from envelope ciphertext
The relay MAY durably store opaque transport routing push tokens for closed-app wake delivery, subject to the `closed-app-push-delivery` capability: strict TTL on every row, no coupling to envelope plaintext or business metadata, and wake push payloads limited to `{ v, kind, recipient }`. This table is transport routing material, not user operational payload storage.

#### Scenario: Envelope persistence does not require push token plaintext
- **WHEN** the relay persists an envelope for a recipient
- **THEN** envelope storage semantics remain unchanged
- **AND** optional wake dispatch reads only the routing push token table index, not envelope ciphertext content
