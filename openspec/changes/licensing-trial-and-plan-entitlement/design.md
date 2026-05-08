## Context

This change specifies **product behavior** for licensing, trials, and plan-level entitlement. It is intended to integrate with:

- proposal/acceptance semantics for plans and renegotiation (`expense-plan-contract-model`)
- local-first data and sync rules (`privacy-first-sync-architecture`)

## Definitions

- **Plan**: a unanimously accepted plan+contract package (expense structure + agreement terms).
- **Participant**: a user/device that is linked to a plan.
- **Plan is in active use**: a plan is considered actively in use when it has at least two linked participants AND at least one synchronization event occurs due to a **realized expense** (not merely plan edits).
- **Realized expense sync**: synchronization triggered by recording an actual expense transaction, not by modifying the plan or contract terms.
- **Trial start**: the timestamp at which the 6-week trial begins for the plan.
- **Plan entitlement**: whether the plan is allowed to operate in full-featured mode given current license status of all participants.
- **Read-only mode**: the application allows viewing past data but blocks actions that mutate ledger state or require active plan operation.

## Key behavioral principles

- **Free until active use**: free/unlimited usage remains available until the plan crosses the “active use” boundary.
- **Individual license, plan-level enforcement**: every participant must have a valid license for the plan to operate.
- **Shared renewal date**: once all licenses for a plan are paid, monthly billing aligns to a shared renewal date for all participants.
- **Grace then read-only**: if a required license becomes unpaid, the plan enters a 1-week grace period, then transitions to read-only, while always allowing export of historical data.
- **Dispute-limited tooling**: if one participant’s payment blocks the group, the app produces a differential impact report and requires plan updates for remaining participants; the app does not adjudicate disputes.

## Open questions (explicitly product decisions)

- Whether OS-level push notifications are required or in-app notifications are sufficient.
- Export formats available in read-only mode.
- Whether “linked to plan” requires explicit account creation or device-scoped identity.

