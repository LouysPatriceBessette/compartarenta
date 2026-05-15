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
