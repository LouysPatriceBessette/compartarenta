## MODIFIED Requirements

### Requirement: Define a wire payload for a plan+contract proposal package
When a participant chooses “Propose to group”, the client SHALL produce a single logical **proposal package** that contains the complete content needed for peers to review and accept or reject the same revision.

The package MUST be self-contained and MUST NOT require fetching additional state to evaluate the proposal (beyond participant identities already known to the group context).

Each `participantSnapshots[]` entry for a connected co-participant on the proposer device MUST include `peerPublicMaterialB64` (long-term relay public key) in addition to `id`, `displayName`, `avatarId`, and optional proposer-local `contactId`. See `housing-plan-peer-contact-establishment`.

#### Scenario: Peer receives a proposal and can render it offline
- **WHEN** a peer device receives a proposal package revision
- **THEN** it can render a human-readable summary, line-by-line diffs, and projection preview using only the payload
- **AND** it can accept/reject the revision without pulling other content

#### Scenario: Peer can derive co-participant relay identity from payload
- **WHEN** a recipient imports a proposal listing co-participants they do not yet have as connected contacts
- **THEN** `participantSnapshots` supplies each missing peer's `peerPublicMaterialB64` for plan-mediated contact establishment
