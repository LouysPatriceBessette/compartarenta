## ADDED Requirements

### Requirement: Plan-mediated establishment uses encrypted steady-state envelopes between known public keys

When two users already know each other's long-term relay public keys (via `participantSnapshots` in a housing proposal), either may initiate contact establishment without an invitation code. The exchange SHALL consist of:

1. **Request** — requester → target: `contactEstablishmentRequest` envelope.
2. **Response** — target → requester: `contactEstablishmentResponse` envelope with `accepted: true | false`.

Both envelopes SHALL be encrypted on-device before relay POST. The relay SHALL see only ciphertext and routing metadata.

#### Scenario: Request carries housing context

- **WHEN** Louys sends an establishment request to Roberr
- **THEN** the decrypted plaintext includes Louys's display name and avatar, Monica's display name as proposer, and enough plan metadata for the target notification string

#### Scenario: Accept response promotes contacts

- **WHEN** Roberr accepts and the response is delivered to Louys
- **THEN** both devices persist a **connected** contact with correct `peerPublicMaterial` and steady-state routing
- **AND** subsequent housing envelopes use normal connected-contact transport

---

### Requirement: Target MUST explicitly accept or refuse

The target device SHALL surface **Accept** and **Refuse** controls when a valid establishment request is decrypted. Refusal SHALL still send an encrypted response so the requester can exit pending state.

#### Scenario: Refuse sends response

- **WHEN** Roberr taps **Refuse**
- **THEN** the app posts `contactEstablishmentResponse` with `accepted: false`
- **AND** no connected contact is created on Roberr's device

---

### Requirement: Requester intent is implicit; completion waits for target accept

When the requester taps **Establish contact**, the product treats the requester as having **accepted the intent** to add the peer. The requester's contact row SHALL remain **non-connected** until an **accepted** response arrives (so a refusal never leaves a false connected row on the requester).

#### Scenario: Requester pending until accept

- **WHEN** Louys sends a request and Roberr has not yet responded
- **THEN** Louys does not treat Roberr as a connected contact for plan gates or relay fan-out
- **AND** Louys shows outbound-pending state in the missing-contacts UI

#### Scenario: Requester connects on accept response

- **WHEN** Roberr accepts and Louys decrypts the response
- **THEN** Louys promotes Roberr to connected locally

---

### Requirement: Routing bootstrap without invitation nonce

Before the first establishment message between two known keys, each side SHALL call `establishRouting` for the pairwise steady-state listen addresses derived from `(selfPub, peerPub)`. No invitation nonce or handshake-only address is used.

#### Scenario: First message after proposal import

- **WHEN** Louys sends the first establishment request to Roberr after importing Monica's proposal
- **THEN** routing between Louys's listen address and Roberr's listen address is active per relay rules
- **AND** the POST succeeds without `no_routing_relationship`

---

### Requirement: Closed-app wake applies to establishment envelopes

When closed-app push is enabled, registration for a watch-list listen address SHALL allow the relay to wake the target device on inbound `contactEstablishmentRequest` and wake the requester on `contactEstablishmentResponse`, subject to user notification preferences.

#### Scenario: Target woken for inbound request

- **WHEN** Roberr registered push for the watch-list address and Louys's request is relay-accepted
- **THEN** Roberr's app may poll, decrypt, and show the establishment notification per `closed-app-push-delivery`

---

### Requirement: Target notification body format

The user-visible notification (and in-app prompt) for an inbound establishment request SHALL use this meaning (localized):

> **[requester display name]** wishes to establish contact with you, in the context of the housing plan proposal from **[proposer display name]**.

#### Scenario: Notification matches product copy

- **WHEN** Louys (requester) and Monica (proposer) are shown in the decrypted request
- **THEN** Roberr's notification uses those names in the sentence above
