## ADDED Requirements

### Requirement: Plan proposal offers are sent only to connected co-participants

When the plan author sends a **housing expense plan + agreement** proposal, the app SHALL target every **non-author** roster participant whose `Contact` is **connected** (per `contacts-module-integration`). The offer payload SHALL be the same **self-contained** proposal package as defined in `plan-contract-proposal-payload` (including `packageId`, `revisionId`, `contentHash`, embedded `plan` and `contract`), so peers can render the **preview-equivalent** UI without extra fetches.

#### Scenario: Unknown or non-connected roster slot blocks send

- **WHEN** any roster participant is not a connected contact
- **THEN** the app blocks “send offer” with a clear remediation (open contact picker / complete invitation handshake)
- **THEN** no partial send is performed for that revision

---

### Requirement: Author chooses a response deadline before send

The author SHALL select a **response deadline** (maximum time allowed for the ordered recipients to respond while the offer remains **open**) before dispatch. The deadline SHALL be stored on the revision metadata as an absolute **expires at** instant (implementation stores UTC; UI converts for display).

#### Scenario: Deadline is visible to all recipients

- **WHEN** a recipient opens the offer
- **THEN** they see both the **response window** conceptually and the **exact expiry** as calendar date and time in the format **`YYYY-MM-DD HH:MM`** (24-hour clock, no locale-dependent month names for this line)
- **AND** the UI states the timezone used for that display (e.g. device local or explicit label) so the instant is unambiguous

---

### Requirement: Author sees per-recipient send status to the relay

After attempting dispatch, the author UI SHALL show, for each recipient, whether the relay **accepted** the envelope for queuing (HTTP success and row accepted per `POST /v1/envelopes` semantics) or the send **failed** (per-recipient error when fan-out is independent). This is **not** a guarantee the peer has read the message; it is “queued for delivery subject to TTL”.

#### Scenario: Mixed relay acceptance across recipients

- **WHEN** three envelopes are posted and two succeed while one fails with a client-visible error
- **THEN** the author sees two recipients as **queued** (or equivalent label) and one as **failed** with retry affordance where the product supports it

#### Scenario: Relay acceptance does not imply peer decision

- **WHEN** all envelopes are relay-accepted
- **THEN** recipient rows remain **pending decision** until an app-level response event is recorded, not merely because relay POST succeeded

---

### Requirement: Recipients are notified and can view without deciding

Recipients SHALL receive a **notification** (OS-appropriate: push where configured, otherwise in-app/inbox badge) that a new offer exists. Opening the offer SHALL allow **back navigation** or **app backgrounding** without recording a decision. **No implicit** Accept / Negotiate / Refuse SHALL be inferred from dismiss or time passage alone (expiry is handled separately).

#### Scenario: Close without action leaves state pending for that user

- **WHEN** the user views the offer and returns to the home screen without choosing an action
- **THEN** their response status remains **pending** (subject to expiry and serial gate rules below)

---

### Requirement: Recipients choose Accept, Negotiate, or Refuse with text rules

While the offer is **open** for that recipient under the serial gate, they SHALL be able to submit exactly one of:

- **Accept** — no free-text required.
- **Negotiate** — free-text **required** (bounded length; empty not allowed).
- **Refuse** — free-text **optional** (bounded length).

The client SHALL validate these rules before send.

#### Scenario: Negotiate with empty text is blocked

- **WHEN** the user selects Negotiate and leaves the text empty
- **THEN** submit is disabled or rejected with validation messaging

---

### Requirement: Responses are broadcast to all participants

Every submitted response (Accept, Negotiate, or Refuse) SHALL be delivered to **all** plan participants for that package context (author + every roster participant), not only the original author. Payload MUST identify `revisionId`, responder participant id, decision enum, optional text, and responder timestamp for audit.

#### Scenario: Another participant learns the outcome without polling the author only

- **WHEN** participant B submits Refuse with text
- **THEN** participant C (still pending or waiting) receives the same response event and their UI updates per invalidation rules

---

### Requirement: Serial response order and invalidation

At offer creation, the app SHALL assign a **fixed response order** among **non-author** roster participants: default **ascending participant `sortOrder`**, tie-break by ascending `participantId` (stable string compare). The author is **not** in this queue (proposal emission records the author as proposer).

While a `revisionId` is **open**:

1. Only the **first** participant in the order whose status is still **pending** MAY submit a decision.
2. **WHEN** they submit **Accept** — their status becomes **accepted**; the **next** pending participant in order becomes the active responder.
3. **WHEN** they submit **Negotiate** or **Refuse** — the revision is **invalidated** for **all** participants who had not yet submitted **Accept** on this revision; their client state becomes **closed / superseded** (labels are localized). No further responses are accepted for that `revisionId`.

#### Scenario: Second participant cannot jump ahead

- **WHEN** participant 1 is still pending
- **THEN** participant 2’s UI does not offer submit (or shows waiting) for that `revisionId`

#### Scenario: First responder refuses — offer closes for everyone pending

- **WHEN** participant 1 refuses
- **THEN** participants 2..N see the offer as **no longer actionable** for that revision
- **AND** history records the refusal and optional text

#### Scenario: All ordered recipients accept — revision eligible for unanimous activation

- **WHEN** every ordered recipient has submitted **Accept**
- **THEN** the revision meets the acceptance side of `contract-unanimous-renegotiation` together with the implicit proposer intent (see next requirement) and MAY transition to **pending activation** or **active** per activation rules defined elsewhere (this spec does not redefine activation mechanics beyond recording unanimity on the same `revisionId`)

---

### Requirement: Proposer intent on the same revision

The author’s act of sending revision `R` SHALL be recorded in history as **proposed** (or **proposer accepted** if the product prefers explicit symmetry). Downstream logic SHALL treat unanimity as “proposer record + all ordered recipients **Accept** on `R`” without requiring the author to tap **Accept** again for the same unchanged payload, unless a future product decision explicitly requires it (if so, update this spec in a follow-up).

---

### Requirement: Expiry closes the offer without a participant decision

**WHEN** wall-clock passes **expires at** before the serial queue completes with all **Accept**:

- **THEN** the revision is **invalidated** (same user-visible consequence as Negotiate/Refuse for remaining pending users)
- **AND** history records **expired** with timestamp

---

### Requirement: Full proposal history is retained on every participant device

Each client SHALL retain a durable **event history** for proposal activity, at minimum keyed by `packageId` and `revisionId`, sufficient to render:

- timeline of send, relay-accept per recipient (if captured), deliveries (if captured), responses, invalidations, expiry
- message text for Negotiate/Refuse when present

History MUST survive normal app restarts and MUST NOT depend on the relay retaining ciphertext after ack/TTL (the relay is not the system of record).

#### Scenario: Offline peer catches up

- **WHEN** a device was offline during two revisions
- **THEN** after sync it can render both timelines from retained or newly ingested encrypted events

---

### Requirement: Any participant may fork a new revision from an invalidated offer

**WHEN** a `revisionId` is **invalidated** or **expired**:

- **THEN** any roster participant (including non-authors) MAY open the retained snapshot and **edit** it to produce a **new** revision with a new `revisionId` (same `packageId` lineage per `plan-contract-proposal-payload`) and submit it through the same send flow
- **AND** the author of that new revision becomes the **proposer** for that revision’s history records

#### Scenario: Non-original author resubmits

- **WHEN** participant C forks after B’s refusal
- **THEN** history shows C as proposer of `R2` while retaining read-only `R1` events

---

### Requirement: UI replaces “invitation codes for housing participants” as the primary path

The housing invitation / preview surface SHALL NOT present **contact invitation codes** as the only way to onboard plan participants. It SHALL steer users to **connected contacts** for send-offer; contact codes remain available only where `contact-invitation-and-codes` applies (pairing), e.g. picker empty-state **Invite**.

#### Scenario: Connected roster shows send offer, not code generation

- **WHEN** all roster participants are connected
- **THEN** the primary action is to configure deadline and **send proposal**, not “generate codes” for those people

---

## Notes (non-normative)

- Wire message kinds and JSON fields for offer/response/broadcast SHOULD be documented next to `docs/contacts-module-relay-payload.md`; relay Go changes are **not** assumed unless a future audit requires a new opaque `kind` byte — prefer evolving client plaintext schema under existing steady-state encryption where policy allows.
- If `contract-unanimous-renegotiation` audit matrix requirements conflict with storage here, treat this spec as the **housing offer UX** source of truth and align the shared “status screen” wording in a later editorial pass.
