## ADDED Requirements

### Requirement: Active plan and contract may only change after unanimous acceptance
Any change that would alter the **binding** shared expense plan or **agreement contract** for a group of participants SHALL require **unanimous acceptance**: every participant MUST explicitly accept the same proposal revision (same version identifier or cryptographically linked content hash—implementation detail) on their own device before the new version becomes **active** for the group.

#### Scenario: One holdout blocks activation
- **WHEN** at least one participant has not accepted the new proposal revision
- **THEN** the group continues to operate under the prior active version (if any) and the new revision remains pending or rejected per participant state

#### Scenario: Unanimous accept activates new version
- **WHEN** all participants have accepted the same proposal revision
- **THEN** that revision becomes the active plan+contract for projection-to-ledger transitions and downstream sync semantics defined elsewhere

### Requirement: Renegotiation is always available while the group exists
The product SHALL allow participants to initiate **renegotiation** at any time while the shared context is active, producing a new proposal revision that may change expense lines, estimates, ratios, agreement period, notice, penalty, or flexible clauses—subject to validation and unanimous acceptance.

#### Scenario: Participant opens renegotiation from settings
- **WHEN** a participant chooses “Propose changes to agreement”
- **THEN** they can edit draft changes and send a new proposal package without being blocked by calendar except where the currently active contract forbids timing of proposals (if such a rule exists—otherwise not blocked)

### Requirement: Partial or split acceptance is not applied as group law
The application SHALL NOT apply a mix of old and new contract terms across participants for the same revision. Acceptance is **per revision**; until unanimity, no participant’s device SHALL treat the new revision as binding group law.

#### Scenario: Mixed responses do not merge terms
- **WHEN** some participants accept and others reject or remain pending on revision R2
- **THEN** no device activates R2 for group computations; rejections follow the proposal lifecycle in `data-locality-and-client-storage`

### Requirement: Unanimous consent applies to reductions of minima as well as increases
If a proposal would **relax** a mandatory floor (e.g., shorten minimum notice below the prior active minimum, remove penalty where the group had agreed one), that change SHALL still require unanimous acceptance so protections cannot be stripped unilaterally.

#### Scenario: Relaxing notice requires unanimous accept
- **WHEN** a participant proposes a shorter minimum notice than the active contract
- **THEN** the proposal cannot take effect until every participant accepts

### Requirement: Auditability of what each participant accepted
For each proposal revision, the client SHALL retain sufficient metadata (ids, timestamps, participant ids) to show **who** has accepted, pending, or rejected, for in-app transparency. Payloads remain protected by E2EE rules in `end-to-end-encryption` when transmitted.

#### Scenario: Group status screen shows acceptance matrix
- **WHEN** a proposal revision is pending
- **THEN** each participant can see acceptance status for all participants without exposing draft edits that were never proposed

### Requirement: Minimal acceptance metadata may be visible for server-side roster reconstruction
The transport MAY expose a minimal non-payload metadata surface for proposal and amendment responses so an entitlement service can reconstruct the accepted active roster for a plan without reading the business payload.

At minimum this metadata MAY include:

- `plan_id`
- `revision_id`
- `participant_installation_id`
- `decision_kind`

This metadata MUST remain narrower than the business payload and MUST NOT expose plan line text, clause text, proof data, or other business-domain fields.

#### Scenario: Server reconstructs accepted roster without payload access
- **WHEN** the entitlement service observes response metadata for all participants on a proposal revision
- **THEN** it can determine whether that revision became the active accepted roster for the plan without parsing business payload ciphertext
