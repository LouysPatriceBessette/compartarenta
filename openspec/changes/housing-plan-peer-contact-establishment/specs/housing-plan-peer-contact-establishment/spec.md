## ADDED Requirements

### Requirement: Proposal snapshots carry relay public keys for every connected co-participant on the proposer device

When exporting a housing proposal package, each entry in `participantSnapshots` for a roster co-participant who is a **connected** contact on the proposer device SHALL include:

- `id` (proposer-local roster participant id)
- `displayName`
- `avatarId`
- `contactId` (proposer-local contact row id, optional but present when known)
- `peerPublicMaterialB64` — base64url encoding of the peer's **long-term X25519 public key** (`Contacts.peerPublicMaterial` at send time)

The proposer SHALL NOT send an offer while any roster co-participant lacks exportable `peerPublicMaterialB64` (all plan participants are connected contacts on the author device per `contacts-module-integration`).

#### Scenario: Recipient learns co-participant keys from the proposal alone

- **WHEN** Louys receives Monica's proposal naming Roberr as a co-participant
- **THEN** Louys can read Roberr's `peerPublicMaterialB64` from `participantSnapshots` without any separate invitation code
- **AND** Louys can derive the steady-state listen address for messages from Roberr once routing is registered

#### Scenario: Missing key blocks author send

- **WHEN** any roster slot on the author device is not a connected contact with non-empty `peerPublicMaterial`
- **THEN** the app blocks "send offer" before any relay POST (same gate as today, with clearer remediation)

---

### Requirement: Missing-contact detection registers inbound establishment watches

When a housing proposal (initial offer, amendment, or any imported received plan revision) is persisted locally, the client SHALL:

1. Run missing peer contact detection (relay-reachable connected contact for each co-participant except `:self`).
2. For each **missing** co-participant, read `peerPublicMaterialB64` from the matching `participantSnapshots` entry.
3. Add that peer to an **inbound establishment watch list**: register pairwise steady-state routing and include the local listen address in steady inbox polling and closed-app push registration.

#### Scenario: Watch list updated on every import

- **WHEN** Louys imports Monica's proposal and Roberr is missing locally
- **THEN** Louys begins polling (and push registration when enabled) for the pairwise address derived from Louys's public key and Roberr's snapshot key
- **AND** Louys can receive a `contactEstablishmentRequest` from Roberr without an invitation code

#### Scenario: Connected peer removes watch

- **WHEN** Roberr later becomes a connected contact on Louys's device
- **THEN** the establishment watch for Roberr's snapshot key is removed (no duplicate poll targets)

---

### Requirement: Missing-contacts UI offers Establish contact only

The housing missing-contacts hub (`HousingPlanMissingContactsScreen` and equivalent entry from proposal / amendment review) SHALL:

- List co-participants with connected / missing status (as today).
- For each **missing** row, show a single primary action **Establish contact** (localized).
- **NOT** offer "create invitation code" or "enter code" on these surfaces.

Only the **recipient** of the proposal who sees missing peers MAY send an establishment request (not the original proposer on behalf of others).

#### Scenario: Louys establishes Roberr from the hub

- **WHEN** Louys opens missing contacts for Monica's received plan and taps **Establish contact** on Roberr's row
- **THEN** the app sends a plan-mediated establishment request to Roberr's public key
- **AND** Louys records outbound-pending state until Roberr responds

#### Scenario: Proposer cannot establish on behalf of recipients

- **WHEN** Monica views her sent proposal
- **THEN** she does not get missing-contact establishment actions for Louys↔Roberr gaps (she does not know which recipient lacks which peer)

---

### Requirement: Plan acceptance remains blocked until all co-participants are relay-reachable

Existing gates that block Accept / send-response on a housing offer while any co-participant is not a relay-reachable connected contact SHALL remain in force. Completing plan-mediated establishment satisfies the gate the same way invitation-code pairing did previously.

#### Scenario: Unblock after successful establishment

- **WHEN** Louys and Roberr become connected through plan-mediated establishment
- **THEN** each device's missing-contact list for that plan shows all peers connected
- **AND** Accept on the housing offer is no longer blocked for missing-contact reasons

---

### Requirement: Refusal is displayed locally on the requester device only

When the target refuses, the requester's missing-contacts row SHALL show a localized **Refused** suffix with date and time formatted per the user's date/time preferences. This state is **informational only** (does not block retries). The requester MAY tap **Establish contact** again later.

#### Scenario: Refusal timestamp shown

- **WHEN** Roberr refuses Louys's establishment request
- **THEN** Louys sees Roberr's row annotated with refusal date/time
- **AND** no connected contact is created on either side

---

### Requirement: Same flow for amendments and subsequent proposals

Missing-contact detection, watch-list updates, and the missing-contacts hub behavior SHALL run on **every** housing proposal import (initial offer, amendment, new proposal). Amendment type does not change establishment rules.

#### Scenario: Amendment introduces no new protocol branch

- **WHEN** Louys receives an amendment on the same received plan
- **THEN** missing contacts are re-evaluated and watches updated
- **AND** the same **Establish contact** actions apply for any still-missing peers
