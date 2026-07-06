## Context

This change specifies **product behavior** for licensing, trials, and plan-level entitlement. It is intended to integrate with:

- proposal/acceptance semantics for plans and renegotiation (`expense-plan-contract-model`)
- local-first data and sync rules (`privacy-first-sync-architecture`)

## Definitions

- **Plan**: a unanimously accepted plan+contract package (expense structure + agreement terms).
- **Participant**: a user/device that is linked to a plan.
- **Installation identity**: the locally generated long-lived app installation identity used as the stable participant-installation scope for entitlement and trial tracking. It is not a hardware identifier.
- **Plan is in active use**: a plan is considered actively in use when it has at least two linked participants AND at least one synchronization event occurs due to a **realized expense** (not merely plan edits).
- **Realized expense sync**: synchronization triggered by recording an actual expense transaction, not by modifying the plan or contract terms.
- **Trial start**: the timestamp recorded by the entitlement service when the first qualifying realized-expense sync is authorized for an accepted plan.
- **Trial consumed**: the durable fact that a given installation identity has already consumed trial eligibility for housing and cannot unlock a new housing trial merely by joining a later plan.
- **Accepted plan roster**: the canonical list of participant installation identities that unanimously accepted the currently active housing plan revision.
- **Plan entitlement**: whether the plan is allowed to operate in full-featured mode given current license status of all participants.
- **Read-only mode**: the application allows viewing past data but blocks actions that mutate ledger state or require active plan operation.

## Key behavioral principles

- **Free until active use**: free/unlimited usage remains available until the plan crosses the “active use” boundary.
- **Individual license, plan-level enforcement**: every participant must have a valid license for the plan to operate.
- **Canonical entitlement state**: the entitlement service is the canonical source for housing trial state, trial-consumption state, plan roster eligibility, and relay-facing allow/deny decisions.
- **Shared renewal date**: once all licenses for a plan are paid, monthly billing aligns to a shared renewal date for all participants.
- **Grace then read-only**: if a required license becomes unpaid, the plan enters a 1-week grace period, then transitions to read-only, while always allowing export of historical data.
- **Relay-enforced gating with minimal metadata**: the relay may enforce housing entitlement decisions using minimal visible metadata (`module`, `plan_id`, `revision_id` or `expense_id`, participant installation identity, decision kind, and request scope) without reading business payload ciphertext.
- **No second housing trial once any participant consumed one**: a newly accepted housing plan is not trial-eligible if any participating installation identity previously consumed housing trial eligibility.
- **Dispute-limited tooling**: if one participant’s payment blocks the group, the app guides plan updates for remaining participants (ratio redistribution, inactive participant); it does not adjudicate disputes. A **differential impact report** (before/after projected obligations) is deferred to a future release — see `dev-ideas/2026-06-27-wish-list.md` § 3. Voluntary withdrawal and ejection plan adaptation is specified in `housing-participation-change-major-flow`.

## Relay / entitlement state model

The entitlement service keeps only the minimum durable state needed to enforce housing licensing and relay authorization:

- installation-identity level trial-consumed markers and timestamps,
- accepted housing plan rosters (`plan_id` -> participant installation identities),
- housing trial state per accepted plan (`trial_started_at`, `trial_ends_at`, current plan entitlement state),
- module-scoped entitlement state (for example, housing import authorization),
- store validation artifacts and renewal windows.

The relay does not query Apple or Google directly. It either:

- validates short-lived signed entitlement assertions issued by the entitlement service, or
- performs online introspection against the entitlement service for gated operations.

## Relay-visible metadata

To keep E2EE while still allowing relay-side gating, the transport exposes a minimal non-payload metadata surface to the relay and entitlement layer. For housing this includes at minimum:

- `module = housing`,
- `message_kind`,
- `plan_id`,
- `revision_id` for plan/amendment response events when applicable,
- `expense_id` for realized expense decision events when applicable,
- `participant_installation_id`,
- `decision_kind` for plan/amendment and realized-expense responses,
- sender/recipient opaque identities and relay authorization scope.

This metadata is sufficient to reconstruct:

- the accepted active plan roster,
- whether a housing plan is trial-eligible,
- whether a realized expense has reached unanimous acceptance,
- whether a request should be refused by the relay.

## Open questions (explicitly product decisions)

- Whether OS-level push notifications are required or in-app notifications are sufficient.
- Export formats available in read-only mode.
- Exact relay pattern for gated operations: signed short-lived assertions only, online introspection only, or hybrid.

