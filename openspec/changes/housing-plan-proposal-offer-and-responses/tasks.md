# Tasks — housing plan proposal offer flow (tracking)

- [x] 1.1 Replace or retire UI that suggests **only** “generate invitation codes” for housing participants; route send-offer to **connected** roster members with the preview payload.
- [x] 1.2 Author: **response deadline** before each **send** of a given `revisionId`.
  - Before dispatch, the author picks a deadline (product-defined presets, e.g. 48 h / 7 days / custom).
  - Persist `expiresAt` (UTC wall-clock instant) on **that revision only for that dispatch** — it defines when **this send** stops accepting responses.
  - **Fork / new revision:** a forked child revision MUST NOT inherit a parent’s `expiresAt`; the author is prompted to choose a **new** deadline when they send that revision.
  - UI/storage may keep `expiresAt` on revision rows, but semantics are **per send**, not lineage across forks.
- [x] 1.3 Author: multi-recipient relay POST fan-out + per-recipient **send status** (relay accepted vs error).
- [x] 1.4 Recipient: **inbox import** + **notification on offer receipt** (not deadline reminder).
  - **Local persistence:** after decrypt/validate, persist the offer locally (proposal package, `packageId` / `revisionId`, roster, `expiresAt`, pending response state) so the recipient can open it from Housing/workbench without re-fetching ciphertext from the relay.
  - **Notification on receipt:** when a new housing proposal envelope is imported, fire a **local notification** (and push when the platform and notification prefs allow — same category as “plan submission received”). This is **“you have a new offer to review”**, not “deadline approaching”.
  - **Out of scope for 1.4:** reminders as the response deadline nears → **1.4b**.
- [ ] 1.4b **Deadline reminder** notifications (housing proposal response window).
  - For each **open** `revisionId` where the local user is still **pending** (recipient) or is the **author** awaiting peer responses (product decision per role), schedule one or more reminders before `expiresAt` (from 1.2) via relay scheduled notifications (domain `housing_proposal_deadline`).
  - **Lead times** depend on the deadline preset chosen at send (product table, e.g. 48 h → remind at 24 h + 6 h; 7 days → remind at 48 h + 24 h — document in spec or `design.md` when fixed).
  - **Cancel / reschedule** when the user submits a response, the revision is **invalidated** or **expired**, or `expiresAt` changes on resend.
  - Respect app-level master notification switch and the Housing category for **offer expiration**.
  - **Not** the same as 1.4 receipt notification; copy MUST distinguish “new offer” vs “deadline approaching”.
  - Log reminder-fired events in the activity log (1.8) when that store exists.
- [x] 1.5 Recipient: offer detail UI with **deadline** and **expiry** shown as `YYYY-MM-DD HH:MM` (timezone rule in spec).
- [x] 1.6 Recipient: **Accept** | **Negotiate** | **Refuse** + text rules; broadcast outcome envelope to **all** participants (including proposer and non-responding peers).
- [x] 1.7 **Parallel responses** (first come, first served) — not serial turn-taking.
  - While a `revisionId` is **open**, **every** non-author participant still **pending** MAY submit **Accept**, **Negotiate**, or **Refuse** at any time (no “your turn” / waiting for another recipient first).
  - **Invalidation:** the **first** recorded **Negotiate** or **Refuse** on that revision invalidates it for **all** participants who had not yet **Accept** on that revision (no further decisions on that `revisionId`).
  - **Unanimity:** when **every** non-author participant has **Accept**, the revision meets the acceptance side of unanimous activation (with proposer intent on send — see spec).
  - **Expiry:** if wall-clock passes `expiresAt` before unanimity, same invalidation consequence as 1.2 (see spec).
- [x] 1.8 **Activity log** (append-only, Settings) — relay-related events for this device.
  - **Store:** append-only local event log for transmissions handled via the relay (and their app-level outcomes), keyed at minimum by timestamp, event kind, `packageId` / `revisionId` when applicable, and **initiator** (local user vs identified peer / contact).
  - **UI:** **Settings → “My activity log”** (localized; FR example: *Log de mon activité*): chronological list generated as events arrive; **read-only** (no edit, delete, or replay actions on the list).
  - **Filters (view only):** date range; **initiator** (e.g. me / a specific contact / system-local).
  - **Minimum event kinds:** contact add request (handshake), contact disconnected, contact deleted (local actions that affect relay traffic where applicable), housing plan **sent** / **received**, housing proposal **response** (Accept / Negotiate / Refuse), revision **invalidated** / **expired**, **fork created** (links to 1.13). Extend with other relay kinds as they ship.
  - **Housing thread UI** (workbench / offer detail) may **read** the same store for status/timeline, but the Settings page is the canonical **audit trail** deliverable for this task.
- [x] 1.9 Invalidated offer: “**Fork / edit and submit**” entry for **any** participant from retained snapshot (new `revisionId`, same `packageId` lineage per `plan-contract-proposal-payload`).
- [x] 1.10 Wire protocol: define encrypted JSON message kinds (offer, response, invalidation notice) and document alongside `docs/contacts-module-relay-payload.md` (follow relay change-minimization: prefer client-only protocol docs unless relay must change).
- [ ] 1.10b Document minimal relay-visible metadata for proposal / amendment responses (`plan_id`, `revision_id`, `participant_installation_id`, `decision_kind`) so the entitlement layer can reconstruct accepted plan rosters without reading payloads.
- [x] 1.11 **Workbench model**: persist and list local draft(s), sent threads, received threads; compute `entries.length` for navigation rules.
- [x] 1.12 **Home Housing**: open workbench **selector** when `entries.length > 1`; preserve direct-to-summary for single lone draft (spec).
- [x] 1.13 **Fork lineage** fields on revision rows + `fork created` activity-log events (1.8); UI shows provenance (“forked from …”).
- [x] 1.14 **Fork gating** in editor/workbench: disable fork while source `revisionId` is **open**; enable when invalidated/expired/closed per spec.
- [x] 1.15 **Concurrent offers**: independent per-`revisionId` state machines; inbox UI lists multiple threads (Case #1 / #2).
- [x] 1.16 **Agreement period overlap gate**: compute **blocking intervals** per participating plan (active contract dates, else open revision proposed dates); compare **calendar days only** (strip time; no UTC for this test); block **send** / **final accept** when **S ≥ 2** shared days with any blocking interval; **S ≤ 1** never blocks (handoff on same calendar day allowed).
- [x] 1.17 **UX copy** for calendar conflicts (**≥ 2** shared days; show conflicting plan label + date range); optional suggest “adjust dates”.


- [ ] 1.18 Wire checklist [`housing-plan-entry-spec-conformance-checklist.md`](../expense-plan-contract-model/housing-plan-entry-spec-conformance-checklist.md) rows for home selector / workbench when implemented.
- [x] 1.19 Archive invalidated proposals with response summary messages; prompt Negotiate responders to fork; prevent Refuse responders from forking the refused revision.
- [x] 1.20 Housing entry archive/new-plan page before step 1; eligible archive opens editable fork, ineligible archive opens read-only review.
- [x] 1.20b **Android E2E (partial):** expired proposal visible in archive list — Maestro scenario `proposal_response_expired` (`qa-housing-archive-expired`). Does **not** cover send/receive, multi-device sync, or drift cases (**1.22**).
- [ ] 1.21 Wishlist: detect and retire stale connected contacts after a peer reinstalls / loses local data and reconnects under a new identity, so proposal sends do not need fallback fan-out.
- [ ] 1.25 Wishlist: revisit the order of the 4 plan-draft wizard steps to add entry for pre-existing inter-participant debt before activation.
- [x] 1.23 **Unanimous activation notification** (spec: `housing-plan-proposal-offer-flow` — *Unanimous activation notifies all participants from the last acceptor device*).
  - When the **last** non-author **Accept** completes unanimity on a `revisionId`, the accepting device notifies **all** roster participants (localized unanimous-agreement copy).
  - Deep-link / route to active agreement hub (`housing-active-agreement-operations`), not the closed offer screen.
  - Dedupe per `revisionId` on devices that already recorded activation locally.
  - Activity log: **agreement activated** on emitter.
  - *(See `housing_activation_notification_service.dart`, hooks in `handshake_orchestrator.dart`, `housing_proposal_transport_service.dart`, `housing_invite_proposal_screen.dart`; test `housing_activation_notification_service_test.dart`.)*
- [ ] 1.22 Bug: Housing proposal delivery/notification unreliable after identity drift (web resets, stale contacts, reconnects). **Not closed** — happy path validated May 2026; drift scenarios still open.
  - **Validated (May 2026, dev):** Fresh handshake on both sides (no stale/disconnected rows); same relay URL; web `housing_proposal posted` + `delivered`; Android `steady inbox fetched` + `housing_proposal imported` + local notification; proposal in a `received:…` plan (not the author’s `housing:default`). Web plan draft survives `CTRL+C` on `run:dev:web` (persistent Chrome profile + draft backup) — reduces how often step 2 below is needed.
  - **Validated (May 2026, dev):** In-force **amendment** send/accept across web (proposer) + Android (invitee): `housing_proposal_response` delivery, activation on proposer hub, decision notification on web; Android hub UX after accept. Export/import hub action not exercised.
  - **Still uncertain / not proven fixed:**
    - Web local data wipe + new identity without a clean reciprocal handshake on Android (stale `connected` rows, mismatched `peerPublicMaterial`, `no_routing_relationship`, or poll on wrong steady inbox → `steady inbox empty` on all contacts).
    - Participant `contactId` pointing at an obsolete handshake row while another row has the current peer key (related to **1.21**).
    - Android app sleep / cold start before poll (push wake not relied on in dev; Firebase API key errors on Android dev flavor).
    - Author looking at `housing:default` on the recipient device instead of `received:…` or workbench (UX confusion, not always transport failure).
  - **Reproduced (Jul 2026, Android E2E):** Multi-device Maestro scenario `housing_proposal_bug_122` (`qa/multi_scenarios/housing_proposal_bug_122.yaml`, coordinator `tool/coordinators/housing_proposal.sh`). After proposer-only identity drift (Monica re-seeded and re-handshaken; Louys keeps prior contact rows), recipient shows **two connected Monica-QA contact rows** (`qa-contacts-duplicate-connected-monica-qa` banner). Verdict `REPRODUCED` on attempt 001 (`bug_122_result.txt`); same attempt completed send + recipient proposal UI. Run: `./tool/melosw run qa:run-multi-scenario -- housing_proposal_bug_122`. See `docs/qa-android-e2e.md`.
  - **Repro when still broken (drift):**
    1. Android and web connected through the relay.
    2. Restart `run:dev:web` and lose web-side data (or reset web DB / identity without matching Android contact cleanup).
    3. Recreate web user and reconnect; repeat until Android has multiple contact rows or mismatched ids (`contact:handshake:…` vs `contact:redeemed:…` with different peer keys).
    4. From web, send a housing proposal.
    5. On Android: no `housing_proposal imported` and/or empty Housing module for the invitee role.
  - **Log triage:** Web: `posted` / `delivered` vs `failed` / `no_routing_relationship`. Android: `steady inbox poll skipped: no peer keys` vs `steady inbox empty for …` (wrong inbox) vs `fetched` without `imported` (decrypt / sender key mismatch) vs `imported from contact:…` (success). See `dev-ideas/2026-05-20-housing-bug-1-22-investigation.md`.
  - **Mitigations already in app (do not close 1.22):** `establishRouting` before proposal POST; abandon pending revision on total send failure + resend; poll all contacts with `peerPublicMaterial`; sender-key reconciliation on import; housing entry poll on resume / inbox tick.
  - **Expected behavior:** Current Android identity receives, imports, and displays the proposal; local notification when prefs allow.

- [x] 1.24 **Bug (high / likely):** Participant identity drift across profile rename and missing-contact establishment.
  - **Policy (Jun 2026):**
    - **Before send:** inbound `profile_update` and local self-rename update linked `participants` rows (`contactId` / `:self`); contact module already updates contacts.
    - **During open vote:** self **display-name** change blocked for every local housing vote (open proposal/amendment, participation change, agreement-expiration settlement window); avatar-only edits allowed; no `profile_update` broadcast for name while blocked.
    - **Plan-mediated establishment race:** on `contactEstablishmentRequest` / `contactEstablishmentResponse`, reconcile name mismatch when `peerPublicMaterialB64` matches (establishment, participant, contact, revision snapshots). No broad pubkey fallback in `relayReachableContactForParticipant`.
  - **Repro (regression guard):**
    1. **A** connected to **B** and **C**; **B** and **C** not connected.
    2. **A** sends housing proposal (missing peer contacts on at least one device).
    3. **B** tries to rename during open vote → blocked on **B**; **A** receives no conflicting `profile_update` during vote.
    4. **Before send** scenario: **B** renames, **A**’s draft roster updates with contact.
    5. **Edge:** rename/proposal race → plan-mediated handshake reconciles by public key on invitation/response.
  - **Implementation:** `profile_rename_policy.dart`, `housing_participant_profile_sync.dart`, `housing_plan_peer_identity_reconcile.dart`, `handshake_orchestrator.dart`, `profile_identity_settings_screen.dart`, `app.dart`.
  - **Related:** **1.22**, **1.21**, contacts-module missing-contacts flow, `user-profile-and-contact-display-labels`.
