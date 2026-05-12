## ADDED Requirements

### Requirement: The handshake runs on top of the encrypted relay, not as a separate protocol
The contact handshake SHALL be carried over the **encrypted relay** as specified in `relay-sync-no-persistence` and `end-to-end-encryption`. The handshake SHALL NOT introduce a parallel transport or a plaintext channel through the relay. Relay infrastructure shall match `relay-deployment-topology` and `relay-state-schema-and-retention`.

#### Scenario: Handshake envelopes are encrypted before reaching the relay
- **WHEN** any handshake envelope (hello, ack, etc.) is dispatched
- **THEN** the envelope is encrypted on-device before being submitted to the relay
- **THEN** the relay receives only ciphertext plus the routing metadata required to deliver the envelope

### Requirement: Handshake completes in exactly one accept/reject round on the inviter side
After the invitee submits a valid invitation code, the protocol SHALL perform the following minimal exchange:
1. The invitee's device sends a `hello` envelope encrypted to the inviter's public material derived from the code. The envelope contains: invitee's public material, invitee's chosen self display name, invitee's avatar identifier, and the nonce echoed from the code.
2. The inviter's device receives the `hello`, validates the nonce locally, and surfaces a confirmation prompt to the inviter showing the invitee's name and avatar.
3. The inviter explicitly **accepts** or **rejects** the request on their device.
4. On accept, the inviter's device replies with an `ack` envelope encrypted to the invitee containing the inviter's public material, display name, avatar identifier, and a stable relay-routing identifier for future module messages.
5. Both sides promote their Contact stub to the **connected** kind.

#### Scenario: Inviter rejects the request
- **WHEN** the inviter rejects the `hello` envelope
- **THEN** no `ack` is sent
- **THEN** the invitee's device receives a documented "rejected" signal (either an explicit small envelope or by timeout, as defined by the implementation)
- **THEN** neither side persists a connected Contact for the failed handshake

#### Scenario: Successful handshake produces connected contacts on both sides
- **WHEN** the inviter accepts the request and the `ack` is delivered to the invitee
- **THEN** both devices have a Contact for the other side with kind = connected
- **THEN** the Contact records the peer's relay-routing identifier and the peer's public material

### Requirement: The handshake nonce is consumed on the inviter's device
The handshake nonce embedded in the invitation code SHALL be considered consumed once a `hello` envelope referencing it has been validated by the inviter's device, regardless of whether the inviter accepts or rejects.

#### Scenario: Replay after a rejection does not allow a second attempt with the same code
- **WHEN** the invitee submits a code that has already produced a `hello` validated by the inviter (whether the inviter accepted or rejected)
- **THEN** further `hello` envelopes referencing the same nonce are rejected by the inviter's device
- **THEN** to retry, the inviter generates a fresh invitation code

### Requirement: The inviter is shown identity information before accepting
The inviter's confirmation UI SHALL display the invitee's chosen display name and avatar in a way that makes spoofing the inviter's own pre-existing connected contacts visually distinguishable (e.g., the prompt explicitly states "Incoming connection request" and shows the values as proposed by the other party, not as already-trusted contact information).

#### Scenario: Confirmation prompt is unambiguous
- **WHEN** the inviter's device surfaces the incoming `hello`
- **THEN** the UI clearly states the values are proposed by the requesting party
- **THEN** the inviter can accept, reject, or back out without persisting anything yet

### Requirement: The one-time handshake routing identifier is decommissioned after handshake
The relay-routing identifier embedded in (or derived from) the invitation code SHALL be specific to the one-time handshake. After the handshake completes (with accept or reject), it SHALL no longer be used. Subsequent traffic between the two contacts SHALL use the connected routing identifiers exchanged during the `ack`.

#### Scenario: Future messages do not reuse the handshake address
- **WHEN** module messages are later exchanged between the two newly-connected contacts
- **THEN** they are addressed via the connected routing identifiers from the `ack`, not via the one-time handshake address

### Requirement: Handshake failures do not leak identity to other parties via the relay
If a handshake fails (rejected, expired, wrong nonce, malformed envelope), the relay state changes SHALL be limited to TTL-bounded envelope storage and idempotency entries already permitted by `relay-state-schema-and-retention`. The relay SHALL NOT acquire any new persistent record correlating the inviter and invitee beyond what is needed to deliver the in-flight envelopes.

#### Scenario: Failed handshake does not create a routing relationship
- **WHEN** an invitee submits a code but the inviter rejects (or the code expires before being used)
- **THEN** the relay does not persist a routing relationship between the two parties
- **THEN** any envelope state created for the in-flight handshake is deleted under TTL rules

### Requirement: Connected contacts can update identity information through small encrypted envelopes
Once two contacts are connected, either side MAY send small encrypted **profile-update** envelopes to communicate a changed display name or avatar identifier. The receiving side SHALL surface these updates non-intrusively (e.g., a "Contact updated their profile" affordance). Profile-update envelopes are subject to the same relay semantics as any other message (encrypted, TTL, delivered, deleted).

#### Scenario: Peer renames themselves
- **WHEN** a connected contact changes their own display name on their device and the update is delivered
- **THEN** the local Contact reflects the new display name
- **THEN** module historical snapshots (per `contacts-domain-model`) remain unchanged
