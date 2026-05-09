## ADDED Requirements

### Requirement: Define a wire payload for a plan+contract proposal package
When a participant chooses “Propose to group”, the client SHALL produce a single logical **proposal package** that contains the complete content needed for peers to review and accept or reject the same revision.

The package MUST be self-contained and MUST NOT require fetching additional state to evaluate the proposal (beyond participant identities already known to the group context).

#### Scenario: Peer receives a proposal and can render it offline
- **WHEN** a peer device receives a proposal package revision
- **THEN** it can render a human-readable summary, line-by-line diffs, and projection preview using only the payload
- **AND** it can accept/reject the revision without pulling other content

### Requirement: Proposal package has stable identifiers and revision identity
The payload MUST include:

- a **package id** (stable across renegotiations of the same group context)
- a **revision id** (unique per proposed revision)
- a **content hash** (computed over the normalized package content; algorithm is an implementation detail)
- timestamps for when the revision was created and when it expires (optional)

Acceptance is always tied to the exact same revision identity (revision id + content hash).

#### Scenario: Same revision accepted on all devices
- **WHEN** two devices claim to accept revision `R2`
- **THEN** they MUST be referring to the same `revisionId` and `contentHash`

### Requirement: Payload includes full contract terms for the revision
The proposal package MUST carry the full **agreement contract** terms for that revision, including:

- period start and end
- minimum notice days
- penalty (minor units) and currency
- optional flexible clauses text (bounded length)
- contract version number for display and auditability

#### Scenario: Contract review screen does not require prior context
- **WHEN** a peer opens the contract tab for a revision
- **THEN** all fields are present in the payload and can be shown without lookups

### Requirement: Payload includes full expense plan structure for the revision
The proposal package MUST carry the full plan definition for that revision, including:

- plan metadata (type, title, default currency)
- groups (optional)
- lines, each with:
  - title
  - recurring fixed amount OR one-off min/max range (minor units)
  - cadence (for recurring)
  - currency (explicit per line)
  - optional group association
- ratios as a list of weight entries, each binding:
  - participant id
  - scope: either a specific line id OR a specific group id
  - weight integer (scale is an implementation detail)

#### Scenario: Peer can compute a projection from the payload
- **WHEN** a peer opens the “Preview” panel for a proposal revision
- **THEN** the app can compute a projection from the contract period and the included lines and bounds

### Requirement: Payload includes acceptance tracking metadata (audit only)
The payload MAY include an initial acceptance matrix (e.g., empty or “proposer accepted”), but acceptance state is ultimately maintained as events in the sync layer.

At minimum, the local client SHALL store (per revision) the following audit fields:

- proposer participant id
- createdAt timestamp
- each participant’s response status: pending / accepted / rejected
- response timestamps (when known)

#### Scenario: Status screen shows who accepted
- **WHEN** a proposal revision is pending
- **THEN** each participant can see who has accepted, rejected, or is pending for that exact revision

## Canonical JSON shape (non-normative)

```json
{
  "kind": "expensePlanContractProposal",
  "packageId": "pkg:abc",
  "revisionId": "rev:002",
  "contentHash": "sha256:…",
  "createdAt": "2026-05-09T15:00:00Z",
  "proposerParticipantId": "u1",
  "plan": {
    "type": "housing",
    "title": "My housing plan",
    "defaultCurrency": "CAD",
    "groups": [{ "id": "g1", "title": "Utilities" }],
    "lines": [
      {
        "id": "l1",
        "title": "Rent",
        "currency": "CAD",
        "recurring": { "cadence": "monthly", "amountMinor": 120000 }
      },
      {
        "id": "l2",
        "title": "Repairs",
        "currency": "CAD",
        "oneOff": { "minAmountMinor": 0, "maxAmountMinor": 30000 }
      }
    ],
    "ratios": [
      { "participantId": "u1", "lineId": "l1", "weight": 5000 },
      { "participantId": "u2", "lineId": "l1", "weight": 5000 }
    ]
  },
  "contract": {
    "version": 2,
    "periodStart": "2026-06-01T00:00:00Z",
    "periodEnd": "2026-11-30T23:59:59Z",
    "minNoticeDays": 30,
    "penalty": { "currency": "CAD", "amountMinor": 0 },
    "clauses": "…"
  }
}
```

