# Tasks — housing plan proposal offer flow (tracking)

- [ ] 1.1 Replace or retire UI that suggests **only** “generate invitation codes” for housing participants; route send-offer to **connected** roster members with the preview payload.
- [ ] 1.2 Author: response **deadline** selection + persist on revision metadata; compute **expiry** as wall-clock instant for display/storage.
- [ ] 1.3 Author: multi-recipient relay POST fan-out + per-recipient **send status** (relay accepted vs error).
- [ ] 1.4 Recipient: inbox handling + local persistence of offer + push/local notification hook (platform-specific).
- [ ] 1.5 Recipient: offer detail UI with **deadline** and **expiry** shown as `YYYY-MM-DD HH:MM` (timezone rule in spec).
- [ ] 1.6 Recipient: **Accept** | **Negotiate** | **Refuse** + text rules; broadcast outcome envelope to **all** participants (including proposer and non-responding peers).
- [ ] 1.7 Enforce **serial** response order; invalidate revision on first **non-Accept** from the active responder; unlock next on **Accept**.
- [ ] 1.8 History: local event store for all participants; render thread / status from events.
- [ ] 1.9 Invalidated offer: “**Fork / edit and submit**” entry for **any** participant from retained snapshot (new `revisionId`, same `packageId` lineage per `plan-contract-proposal-payload`).
- [ ] 1.10 Wire protocol: define encrypted JSON message kinds (offer, response, invalidation notice) and document alongside `docs/contacts-module-relay-payload.md` (follow relay change-minimization: prefer client-only protocol docs unless relay must change).
- [ ] 1.11 **Workbench model**: persist and list local draft(s), sent threads, received threads; compute `entries.length` for navigation rules.
- [ ] 1.12 **Home Housing**: open workbench **selector** when `entries.length > 1`; preserve direct-to-summary for single lone draft (spec).
- [ ] 1.13 **Fork lineage** fields on revision rows + `fork created` history events; UI shows provenance (“forked from …”).
- [ ] 1.14 **Fork gating** in editor/workbench: disable fork while source `revisionId` is **open**; enable when invalidated/expired/closed per spec.
- [ ] 1.15 **Concurrent offers**: independent per-`revisionId` state machines; inbox UI lists multiple threads (Case #1 / #2).
- [ ] 1.16 **Agreement period overlap gate**: compute **blocking intervals** per participating plan (active contract dates, else open revision proposed dates); compare **calendar days only** (strip time; no UTC for this test); block **send** / **final accept** when **S ≥ 2** shared days with any blocking interval; **S ≤ 1** never blocks (handoff on same calendar day allowed).
- [ ] 1.17 **UX copy** for calendar conflicts (**≥ 2** shared days; show conflicting plan label + date range); optional suggest “adjust dates”.


- [ ] 1.18 Wire checklist [`housing-plan-entry-spec-conformance-checklist.md`](../expense-plan-contract-model/housing-plan-entry-spec-conformance-checklist.md) rows for home selector / workbench when implemented.
- [x] 1.19 Archive invalidated proposals with response summary messages; prompt Negotiate responders to fork; prevent Refuse responders from forking the refused revision.
- [x] 1.20 Housing entry archive/new-plan page before step 1; eligible archive opens editable fork, ineligible archive opens read-only review.
- [ ] 1.21 Wishlist: detect and retire stale connected contacts after a peer reinstalls / loses local data and reconnects under a new identity, so proposal sends do not need fallback fan-out.
- [ ] 1.22 Bug: investigate missing Housing proposal delivery/notification after repeated web data resets and reconnections.
  - Steps to reproduce:
    1. Start with Android and web connected through the relay.
    2. Restart `run:dev:web`, losing the web-side local data.
    3. Recreate a web user and reconnect it with the same Android user; repeat enough times that Android has multiple connected contacts, some stale/non-existent.
    4. From web, create a Housing plan and send the proposal to the Android participant.
    5. On Android, observe that no local notification is shown.
    6. Open `Logement` on Android and observe that the received proposal is not displayed.
  - Current observed logs: Android shows no steady-state Housing fetch/import lines; web shows handshake polling but no confirmed recipient-side Housing import.
  - Expected behavior: the current Android identity receives, imports, and displays the proposal, and the configured local notification is shown.

