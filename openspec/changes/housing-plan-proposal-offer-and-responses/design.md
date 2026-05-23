# Design notes — housing plan proposal offer flow

## Transport and relay

- The relay exposes `POST /v1/envelopes`, `GET /v1/inbox/{recipient}`, and `POST /v1/envelopes/{id}/ack` with **opaque** `body_b64` per recipient (`docs/contacts-module-relay-payload.md`, relay schema `envelopes`).
- **Author-side “sent” status** can distinguish at minimum:
  - **Relay accepted** the POST (valid routing relationship, TTL clamped, row inserted for that recipient).
  - **Send failed** (network, 4xx/5xx, unknown) with a user-visible error per recipient where possible.
- **Recipient-side “delivered”** in the product sense means the client successfully **decrypted**, **validated**, and **persisted** the offer event; relay **ack** removes the ciphertext from the server queue and is orthogonal to “user has opened the UI”.
- Optional **app-level** read receipts or “fetched inbox” flags MAY be added in the encrypted payload for richer UX; they are not required for an MVP if the spec’s minimum bar is relay-accept + local persistence on pull.

## Proposal package

- Reuse the logical shape in `plan-contract-proposal-payload` (`expensePlanContractProposal` with `packageId`, `revisionId`, `contentHash`, embedded `plan` + `contract`).
- Wire encoding (new `kind` in the client frame vs reuse of an existing steady-state envelope) is an **implementation** choice subject to relay audit policy; the relay MUST remain unable to read plaintext.

## Parallel responses (first come, first served)

- There is **no serial turn-taking** among recipients. The proposer’s intent is implicit in **sending** the revision (recorded as `proposed` / equivalent in the activity log).
- While the offer is **open**, **every** non-author participant still **pending** MAY submit Accept, Negotiate, or Refuse at any time.
- The **first** Negotiate or Refuse on that `revisionId` **invalidates** it for all participants who had not yet Accept. Expiry (`expiresAt`) applies the same close semantics if unanimity is not reached in time.
- **Deadline** is chosen before **each send** of a `revisionId` and is **not** copied to forked child revisions (new deadline on fork send).

## Negotiate vs Refuse

- **Negotiate** and **Refuse** both invalidate the current revision for further responses; both SHOULD carry optional free text (Negotiate: encouraged; Refuse: optional per product).
- **Negotiate** signals intent to amend without necessarily supplying a full new package in the same message; any participant MAY start a **new** revision later (fork), including from the invalidated offer snapshot.
- **Refuse** is a hard refusal from the responding participant. The refuser keeps the archived snapshot and response summary for audit/review, but they cannot fork from that refused revision. Other participants can still fork the retained snapshot.
- Immediately after a successful **Negotiate**, the responder is prompted to fork the archived snapshot now. Declining the prompt keeps the archive available in the Housing entry/workbench.

## Activity log

- Every device retains an **append-only** **activity log** of relay-related events (contact handshake, disconnect, housing send/receive, responses, invalidation, expiry, fork created, …).
- **Settings → “My activity log”** (localized) is the canonical read-only audit UI: chronological list, filters by date range and **initiator**, no mutation of entries.
- Housing workbench / offer UI may read the same store for thread status; proposal archive metadata can coexist until a normalized log table lands in Drift.
- **Fork** edges (`forkedFromRevisionId`, `forkedFromPackageId`) are logged so parallel revisions (Case #1) remain explainable.

## Concurrent offers and workbench

- **Per-revision parallel responses** apply independently: concurrency means **multiple revisions** in flight, each with its own `expiresAt` and response state—not one merged timeline across packages.
- **Case #2** (two dwellings, same recipient B): two `packageId` values; B’s client lists two threads. **Final accept** and **send** are limited by the **Agreement period overlap gate** against B’s other participating plans—not by blanket withdrawal.
- **Case #1** (parallel forks): after `R1` invalidates, `R2` and `R3` are independent open revisions; recipients may see two **actionable** threads until each resolves.
- **Workbench selector** unifies navigation from home and authoring: draft row + per-offer rows; fork action is gated on **fork-eligibility** (not open).
- If the module has archived revisions but no active/open proposal, Housing entry shows an archive/new-plan choice before step 1. Eligible archives open the editor prefilled from the snapshot; ineligible archives open read-only offer review.
- **Agreement period overlap gate** replaces a blanket “withdraw from a plan first” rule: comparison uses **calendar dates only** (no time-of-day, no UTC for this gate). **At most one shared day** between periods never blocks; **two or more** shared days block **send** / **final accept** until dates change.

