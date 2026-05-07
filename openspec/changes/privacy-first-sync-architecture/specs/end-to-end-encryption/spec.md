## ADDED Requirements

### Requirement: User-to-user exchanges are end-to-end encrypted
All user-to-user shared payloads that traverse the relay SHALL be end-to-end encrypted such that operators of the relay infrastructure cannot derive plaintext without compromising client endpoints or cryptographic keys held by participants.

Payloads include **ledger synchronization content**: proposed expenses (and related ratio or grouping data), accept/reject decisions, amended proposals, and any other messages defined by the sync protocol in `relay-sync-no-persistence`.

#### Scenario: Relay operator cannot read shared payload
- **WHEN** ciphertext is stored at rest in relay queues or transient buffers
- **THEN** the relay does not possess the private material required to decrypt the user payload under the documented threat model

#### Scenario: Reject and accept decisions are protected like proposals
- **WHEN** a recipient sends an accept or reject response for a proposal
- **THEN** the response is end-to-end encrypted on the wire format so the relay cannot read the decision plaintext

### Requirement: Cryptographic identity and versioning are explicit
The product SHALL define a versioned wire format for encrypted messages (algorithm IDs, nonces, ciphertext layout) and SHALL reject messages with unknown or deprecated versions according to a documented policy.

#### Scenario: Unknown wire version is rejected
- **WHEN** a client sends a message with an unsupported encryption version
- **THEN** the recipient client rejects parsing and surfaces a controlled error path (no silent downgrade)

### Requirement: Authenticated binding between envelope metadata and ciphertext
Where the relay uses outer metadata for routing (e.g., recipient, TTL, message type category, proposal id), clients SHALL cryptographically bind that metadata to the inner ciphertext where needed so peers can detect tampering or mis-routing without trusting the relay for semantic integrity of ledger proposals.

#### Scenario: Recipient detects mismatched routing metadata
- **WHEN** outer metadata does not match the authenticated inner envelope
- **THEN** the client rejects the message and does not apply any ledger effect

### Requirement: Key distribution is documented and implemented without server-held decryption keys
Key agreement or distribution for shared spaces SHALL be documented (e.g., pairwise keys, group keys, invitation flows). The server SHALL NOT be configured to hold server-side keys whose purpose is to decrypt user-shared payloads for routine operations.

#### Scenario: Server configuration review
- **WHEN** production server configuration is reviewed for launch
- **THEN** there is no routine secret material that enables decryption of user-shared payloads by the service operator

### Requirement: Forward secrecy and compromise recovery are addressed
The design SHALL document expectations for key rotation, device compromise, and revocation (even if some mitigations are client UX). If forward secrecy is claimed, the mechanism SHALL be specified and tested.

#### Scenario: Documented revocation behavior
- **WHEN** a user reports device compromise or removes a peer from a shared space
- **THEN** documentation states what cryptographic or operational steps occur and what guarantees apply afterward
