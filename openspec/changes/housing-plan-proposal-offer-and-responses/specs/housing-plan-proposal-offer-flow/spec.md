## ADDED Requirements

### Requirement: Plan proposal offers are sent only to connected co-participants

When the plan author sends a **housing expense plan + agreement** proposal, the app SHALL target every **non-author** roster participant whose `Contact` is **connected** (per `contacts-module-integration`). The offer payload SHALL be the same **self-contained** proposal package as defined in `plan-contract-proposal-payload` (including `packageId`, `revisionId`, `contentHash`, embedded `plan` and `contract`), so peers can render the **preview-equivalent** UI without extra fetches.

#### Scenario: Unknown or non-connected roster slot blocks send

- **WHEN** any roster participant is not a connected contact
- **THEN** the app blocks “send offer” with a clear remediation (open contact picker / complete invitation handshake)
- **THEN** no partial send is performed for that revision

---

### Requirement: Author chooses a response deadline before each send

The author SHALL select a **response deadline** (maximum time allowed for recipients to respond while **this send** of the offer remains **open**) immediately before each **dispatch** of a given `revisionId`. The chosen deadline SHALL be stored as an absolute **expires at** instant on **that revision for that send** (implementation stores UTC; UI converts for display).

A **forked** child revision MUST NOT inherit the parent revision’s `expiresAt`. When the author sends a forked (or otherwise new) revision, they MUST choose a **new** deadline for that dispatch.

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

Recipients SHALL receive a **notification** when a **new offer is received** on the device (OS-appropriate: local notification; push where configured and notification prefs allow). This notification means “a proposal awaits your review”, **not** “the response deadline is approaching”. **Deadline reminder** notifications (if ever added) are a separate product decision and are **out of scope** of this requirement.

After decrypt and validate, the client SHALL **persist** the offer locally (package, revision, roster, `expiresAt`, response state) so the recipient can open it from Housing/workbench without relying on the relay queue still holding ciphertext.

Opening the offer SHALL allow **back navigation** or **app backgrounding** without recording a decision. **No implicit** Accept / Negotiate / Refuse SHALL be inferred from dismiss or time passage alone (expiry is handled separately).

#### Scenario: Close without action leaves state pending for that user

- **WHEN** the user views the offer and returns to the home screen without choosing an action
- **THEN** their response status remains **pending** (subject to expiry and parallel-response rules below)

---

### Requirement: Recipients choose Accept, Negotiate, or Refuse with text rules

While the offer is **open** for that recipient (any pending participant may respond — see **Parallel responses and invalidation**), they SHALL be able to submit exactly one of:

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

### Requirement: Parallel responses and invalidation (first come, first served)

There is **no serial turn-taking** among recipients. The author is **not** in the responder set (proposal emission records the author as proposer).

While a `revisionId` is **open**:

1. **Every** non-author participant whose status is still **pending** MAY submit a decision at any time.
2. **WHEN** a participant submits **Accept** — their status becomes **accepted**; other pending participants remain able to respond until the revision is invalidated, expires, or becomes unanimously accepted.
3. **WHEN** the **first** **Negotiate** or **Refuse** is recorded for that revision — the revision is **invalidated** for **all** participants who had not yet submitted **Accept** on this revision; their client state becomes **closed / superseded** (labels are localized). No further responses are accepted for that `revisionId`.

#### Scenario: Two recipients may respond concurrently

- **WHEN** participants B and C are both still pending on the same open `revisionId`
- **THEN** both MAY submit Accept, Negotiate, or Refuse without waiting for the other

#### Scenario: First non-Accept closes the offer for everyone still pending

- **WHEN** participant B refuses while C is still pending
- **THEN** C sees the offer as **no longer actionable** for that revision
- **AND** the activity log records the refusal and optional text

#### Scenario: All recipients accept — revision eligible for unanimous activation

- **WHEN** every non-author recipient has submitted **Accept**
- **THEN** the revision meets the acceptance side of `contract-unanimous-renegotiation` together with the implicit proposer intent (see next requirement) and MAY transition to **pending activation** or **active** per activation rules defined elsewhere (this spec does not redefine activation mechanics beyond recording unanimity on the same `revisionId`)

---

### Requirement: Proposer intent on the same revision

The author’s act of sending revision `R` SHALL be recorded in history as **proposed** (or **proposer accepted** if the product prefers explicit symmetry). Downstream logic SHALL treat unanimity as “proposer record + all non-author recipients **Accept** on `R`” without requiring the author to tap **Accept** again for the same unchanged payload, unless a future product decision explicitly requires it (if so, update this spec in a follow-up).

---

### Requirement: Expiry closes the offer without a participant decision

**WHEN** wall-clock passes **expires at** before every non-author recipient has submitted **Accept**:

- **THEN** the revision is **invalidated** (same user-visible consequence as Negotiate/Refuse for remaining pending users)
- **AND** the activity log records **expired** with timestamp

---

### Requirement: Activity log on every participant device

Each client SHALL retain a durable, **append-only** **activity log** of relay-related events on that device. The log is the system of record for audit and MUST survive normal app restarts. The relay is not the system of record.

#### Requirement: Settings activity log UI

The app SHALL expose **Settings → “My activity log”** (localized title; e.g. FR *Log de mon activité*): a read-only chronological list built from the log. The user MAY filter by **date range** and by **initiator** (e.g. self, a specific contact, or local/system). The user MUST NOT edit, delete, or mutate log entries from this UI.

Minimum event kinds include: contact add request (handshake), contact disconnected, contact deleted (where applicable), housing plan **sent** / **received**, housing proposal **response** (Accept / Negotiate / Refuse), revision **invalidated** / **expired**, and **fork created**. Additional relay kinds MAY be appended as they ship.

Housing workbench / offer screens MAY read the same store to show thread status, but the Settings page is the canonical **audit trail** surface.

Proposal-related entries SHALL be sufficient to render, per `packageId` / `revisionId` when applicable: send, relay-accept per recipient (if captured), deliveries (if captured), responses, invalidations, expiry, Negotiate/Refuse message text when present, and **fork** provenance (`fork created` with `forkedFromRevisionId` / `forkedFromPackageId`).

The log MUST NOT depend on the relay retaining ciphertext after ack/TTL.

#### Scenario: Offline peer catches up

- **WHEN** a device was offline during two revisions
- **THEN** after sync it can render both timelines from retained or newly ingested encrypted events

---

### Requirement: Fork eligibility depends on invalidation reason and responder

**WHEN** a `revisionId` is **invalidated** or **expired**:

- **THEN** the client SHALL retain a read-only archive of the offer snapshot and response summary.
- **AND** participants MAY fork from the retained snapshot only when they are eligible under the invalidation reason.
- **AND** a participant who submitted a **Refuse** response SHALL NOT be eligible to fork that same refused revision.
- **AND** other participants MAY open the retained snapshot and **edit** it to produce a **new** revision with a new `revisionId` (same `packageId` lineage per `plan-contract-proposal-payload` when the group context is unchanged; a **new** `packageId` MAY be minted when the fork intentionally starts a new group context—implementation SHALL still record **fork lineage** fields)
- **AND** the author of that new revision becomes the **proposer** for that revision’s activity-log entries
- **AND** the new revision SHALL carry **fork lineage** metadata (`forkedFromPackageId`, `forkedFromRevisionId`, …) as required in **Fork lineage is mandatory** above
- **AND** **Fork from workbench only when source revision is not forkable-blocked** applies to UI affordances

#### Scenario: Refuser keeps archive but cannot fork

- **WHEN** participant B refuses revision `R1`
- **THEN** B retains the archived proposal and response summary
- **AND** B can view the offer but cannot fork it
- **AND** all other participants may fork from `R1` if otherwise eligible

#### Scenario: Negotiator is prompted to fork

- **WHEN** participant B submits Negotiate on revision `R1`
- **THEN** B retains the archived proposal and response summary
- **AND** B is immediately asked whether they want to fork `R1` to make changes
- **AND** choosing “not now” leaves the archive available for later fork from the housing workbench

#### Scenario: Non-original author resubmits

- **WHEN** participant C forks after B’s refusal
- **THEN** history shows C as proposer of `R2` while retaining read-only `R1` events

---

### Requirement: Housing entry offers archive choices before editing

When there is no active or open housing proposal but archived proposals exist, the housing module SHALL show a pre-editor choice page before step 1. The page SHALL list archived proposal snapshots and an option to create a new plan.

#### Scenario: Eligible archived proposal forks into editor

- **WHEN** the user selects an archived proposal they are eligible to fork
- **THEN** the editor opens prefilled from that archived snapshot
- **AND** the next submitted proposal records fork lineage to the archived revision

#### Scenario: Ineligible archived proposal opens read-only

- **WHEN** the user selects an archived proposal they are not eligible to fork
- **THEN** the retained offer opens read-only with its response summary
- **AND** the app does not open editable step 1 for that archived proposal

---

### Requirement: UI replaces “invitation codes for housing participants” as the primary path

The housing invitation / preview surface SHALL NOT present **contact invitation codes** as the only way to onboard plan participants. It SHALL steer users to **connected contacts** for send-offer; contact codes remain available only where `contact-invitation-and-codes` applies (pairing), e.g. picker empty-state **Invite**.

#### Scenario: Connected roster shows send offer, not code generation

- **WHEN** all roster participants are connected
- **THEN** the primary action is to configure deadline and **send proposal**, not “generate codes” for those people

---

### Requirement: Multiple concurrent open offers are supported per participant

A participant MAY have **more than one** proposal revision **open** at the same time when those revisions belong to **different** `packageId` values (e.g. two unrelated housing plans both addressing the same recipient) **or** when parallel **fork** revisions were created after an earlier revision was **invalidated** or **expired** (e.g. B and C each fork the same invalidated parent into two new revisions that are both in flight). **Parallel response rules** apply **independently per `revisionId`**; the client SHALL not merge timelines across unrelated revisions.

#### Scenario: Two proposers, one recipient (different plans)

- **WHEN** A’s offer targets only B on plan `pkg:A` and C’s offer targets only B on plan `pkg:C`
- **THEN** B’s inbox shows **two** distinct actionable threads, each keyed by its own `packageId` / `revisionId`, with independent deadlines and response state

#### Scenario: Parallel forks after invalidation

- **WHEN** A’s revision `R1` is invalidated by B’s refusal and both B and C fork `R1` into `R2` and `R3` respectively
- **THEN** each new revision has its own `revisionId`, its own roster and `expiresAt` (chosen at send), and participants who receive both SHALL see **two** open offers until each is resolved or invalidated

---

### Requirement: Agreement period overlap gate (cross-plan propose and final accept)

The app SHALL prevent a user from **(a)** **sending** (as proposer) a new housing proposal whose embedded agreement contract period **conflicts** with any **blocking calendar interval** derived from another housing plan they **currently participate in**, and from **(b)** recording **final accept** on a received offer whose period **conflicts** with any such interval. **Conflict** means **two or more shared calendar days** between the candidate period and that interval under **Day-only overlap** below (sharing **at most one** calendar day is **never** a conflict for this gate).

**Negotiate** and **Refuse** on a received offer SHALL remain available even when **final accept** is blocked by a calendar conflict (so the user can decline or steer toward dates with **S ≤ 1** against all blocking intervals).

**Blocking calendar interval** (for overlap tests only):

- For each housing plan **P** where the user is a **current roster participant**:
  - **WHEN** **P** has an **active** unanimous agreement per `contract-unanimous-renegotiation`, the blocking interval SHALL be that agreement’s **periodStart**–**periodEnd** interpreted as **inclusive calendar dates** (see **Day-only overlap** below).
  - **ELSE WHEN** **P** has no active agreement but the user is party to an **open** (not invalidated, not expired) proposal revision on **P**, the blocking interval SHALL be that revision’s proposed `contract.periodStart`–`contract.periodEnd`, same **day-only** interpretation.
  - **ELSE** there is **no** blocking interval on **P** for this user for overlap purposes (e.g. roster exists only as draft with no bound period yet—implementation SHALL define whether a draft-only plan contributes an interval; default **no** until a period is fixed on a sent revision or active contract).

**Day-only overlap (no UTC / no time-of-day for this gate)**

- Each agreement period SHALL be reduced to an **inclusive range of calendar dates** using only the **date** parts of `periodStart` and `periodEnd` from the payload or active contract (strip time-of-day; do **not** apply UTC offset logic for this comparison—same displayed calendar day is the same day everywhere).
- Let **S** be the number of **calendar days** in the intersection of the candidate period and a blocking interval (inclusive counting on both ends). **WHEN** **S ≤ 1** **THEN** that pair does **not** block (this **permits** a **single** shared day, e.g. one plan’s last day is another’s first day, or any other exactly-one-day touch). **WHEN** **S ≥ 2** **THEN** the candidate **conflicts** with that blocking interval and **send** / **final accept** SHALL be blocked until the user adjusts dates or the blocking interval changes.

**WHEN** the candidate period **does not conflict** with any blocking interval under this rule (all pairs have **S ≤ 1**), the user **MAY** **negotiate**, **propose**, and **final accept** per the rest of this spec without leaving the prior plan’s roster solely for calendar reasons.

#### Scenario: Two non-overlapping futures are allowed

- **WHEN** the user participates in plan P1 with active period ending 2026-12-31 and receives an offer on P2 covering 2027-01-01 onward with **S = 0** shared days with P1’s blocking interval
- **THEN** they MAY negotiate and accept P2’s offer without leaving P1’s roster

#### Scenario: End of one plan and start of another on the same calendar day is allowed

- **WHEN** plan P1’s last day and plan P2’s first day are the **same calendar date** (inclusive ranges share exactly that one day, **S = 1**)
- **THEN** **send** and **final accept** are **not** blocked by this gate for that pair

#### Scenario: Two or more shared calendar days block final accept

- **WHEN** a received offer shares **two or more** calendar days with the user’s blocking interval on another plan
- **THEN** **final accept** is blocked with a localized explanation referencing the conflicting plan (label) and dates
- **AND** **Refuse** and **Negotiate** (with required text for Negotiate) remain enabled

#### Scenario: Two or more shared calendar days block send

- **WHEN** the user participates in plan P with a blocking interval and edits a proposal for plan Q whose period shares **two or more** calendar days with P’s interval
- **THEN** **send proposal** is blocked until they shorten/adjust Q’s dates or P’s blocking interval changes

#### Scenario: Multiple pending offers with at most one-day touch still OK

- **WHEN** the user has several pending offers whose periods never share **two or more** days with any blocking interval
- **THEN** they MAY view and respond while that revision is open without calendar-based blocking beyond this rule

---

### Requirement: Fork lineage is mandatory in history and in new revision metadata

Every proposal revision that is created by **fork** (copying a prior snapshot) SHALL persist:

- `forkedFromPackageId` (nullable when not a fork)
- `forkedFromRevisionId` (nullable when not a fork)
- optional `forkedFromProposerParticipantId` for audit display

The **event history** for each revision SHALL include events that record **fork created** with links to the parent so any participant can answer “did this come from a fork, and from which revision?”.

#### Scenario: History shows fork provenance

- **WHEN** C forks invalidated `R1` into `R3`
- **THEN** `R3` metadata and timeline show parent `R1` (and its `packageId`) read-only, even if `R3` later uses a new `packageId` per `plan-contract-proposal-payload` rules for a new group context

---

### Requirement: Plan workbench selector (draft + all offers)

The housing **authoring / entry** flow SHALL expose a **workbench selector** listing **every** plan-related entry the user may work on, including at minimum:

1. **Local draft** — the user’s unsubmitted work-in-progress (wizard incomplete or complete); always listed even when empty of sent history.
2. **Received offers** — revisions where this user is a recipient and may view (and respond when allowed).
3. **Sent offers** — revisions this user proposed to others (author view, statuses).

**WHEN** the user has **more than one** such entry **or** any entry besides a single local draft with no other threads, the app SHALL show this selector **before** jumping straight to a single plan summary.

#### Scenario: Single draft only — current behaviour preserved

- **WHEN** the only entry is one local draft and there are no received/sent offer threads
- **THEN** the home **Housing** entry MAY navigate directly to that draft’s summary (current behaviour)

#### Scenario: Draft plus one received offer — selector first

- **WHEN** there is a local draft and at least one received offer
- **THEN** tapping Housing opens the **selector**; choosing an entry opens the corresponding summary / wizard step

---

### Requirement: Home Housing entry uses the selector when multiple entries exist

The home-screen **Housing** affordance SHALL open the **workbench selector** **WHEN** the user has **more than one** workbench entry (draft + offers, multiple drafts, multiple offers, or any combination totaling **two or more** rows).

**WHEN** there is **exactly one** workbench entry and it is **only** the user’s local draft with **no** sent/received offer threads, the app MAY keep the current behaviour and open that draft’s **summary** directly.

#### Scenario: Completed draft with no offers still single entry

- **WHEN** exactly one completed local draft and zero offers
- **THEN** direct summary remains allowed

#### Scenario: Draft plus one received offer — two entries

- **WHEN** one local draft and one received offer (two entries)
- **THEN** Housing opens the **selector** first

#### Scenario: Only one received offer, no local draft

- **WHEN** exactly one workbench entry (e.g. a single received offer)
- **THEN** the app MAY open that offer’s summary directly or still use the selector—either is acceptable if `entries.length == 1`

---

### Requirement: Fork from workbench only when source revision is not forkable-blocked

The workbench (and plan authoring steps) SHALL offer **Fork from this offer** only when the selected source revision is **fork-eligible**: its state is **invalidated**, **expired**, or otherwise **closed** for further responses per this spec **and** creating a draft from that fork would not immediately violate the **Agreement period overlap gate** (e.g. user may still need to adjust dates before send).

**WHEN** a revision is still **open** (awaiting responses from any pending participant) **THEN** the user SHALL **not** be offered fork from that revision as an editing source until that revision is **invalidated**, **expired**, or otherwise **closed**; they MUST take or await a **decision** on that offer first (or wait for expiry).

#### Scenario: Cannot fork an open offer

- **WHEN** revision `R` is still open for decisions
- **THEN** “Fork for edit” is disabled with explanation (“Respond to this offer first” / localized)

#### Scenario: Can fork after invalidation

- **WHEN** `R` is invalidated after B’s refusal
- **THEN** B and C (and others on the roster) MAY fork from the retained snapshot of `R` into a new revision

---

## Notes (non-normative)

- Wire message kinds and JSON fields for offer/response/broadcast SHOULD be documented next to `docs/contacts-module-relay-payload.md`; relay Go changes are **not** assumed unless a future audit requires a new opaque `kind` byte — prefer evolving client plaintext schema under existing steady-state encryption where policy allows.
- If `contract-unanimous-renegotiation` audit matrix requirements conflict with storage here, treat this spec as the **housing offer UX** source of truth and align the shared “status screen” wording in a later editorial pass.
- **Concurrent offers** use distinct `packageId` / `revisionId` keys; `plan-contract-proposal-payload` already distinguishes revisions within a package—multiple packages represent multiple dwellings or independent group contexts (Case #2). **Cross-plan** actions are limited by the **Agreement period overlap gate** (day-only shared-day count; no UTC for that gate), not by a blanket withdraw-from-plan rule.
- Response **deadline** / **expires at** for offers may still use precise instants (e.g. UTC storage) for relay TTL and UI `YYYY-MM-DD HH:MM`; that is **independent** of the **day-only** agreement-period gate above.

