# Housing plan proposal — offer, serial responses, and broadcast outcomes

## Motivation

Housing invitation UX was initially oriented toward **invitation codes**. The **Contacts** module is now the authoritative way to reach co-participants: they are **connected** contacts with steady-state relay routing. The author should send the **same proposal package as the in-app preview** (plan + agreement terms) to all roster participants, then drive a **response deadline**, **delivery visibility**, and a **serial acceptance rule** so the group knows when a revision is still live or must be reworked.

## Relationship to existing capabilities

| Capability | Relationship |
|------------|----------------|
| `contacts-module-integration` | Plan participants are **connected** contacts; no parallel “temporary participant” path. |
| `contact-invitation-and-codes` | **No conflict**: those codes are for **pairing** (hello/ack) before a relay relationship exists. Plan offers are sent **after** connection, using the same opaque envelope transport as other steady-state messages. |
| `plan-contract-proposal-payload` | **Aligned**: offers MUST be a **self-contained** proposal package with stable `packageId` / `revisionId` / `contentHash` per that spec. |
| `contract-unanimous-renegotiation` | **Aligned**: a revision becomes **active** only after **unanimous accept** of the **same** revision. This change adds **product rules** for *how* responses are collected (serial gate + early invalidation) without merging mixed terms mid-flight. |
| `expense-plan-contract-model` (housing authoring) | **Companion**: local wizard conformance is tracked in [`housing-plan-entry-spec-conformance-checklist.md`](../expense-plan-contract-model/housing-plan-entry-spec-conformance-checklist.md); rows **E6**, **E9**, **W1**, **W2** (and related) point here for send/receive implementation. |

## Out of scope (for this change)

- Replacing or weakening contact invitation-code entropy, expiry, or handshake rules.
- Relay schema redesign beyond what already supports one row per recipient and TTL (see `relay/internal/store/schema`).

## Deliverable

One new capability spec: `specs/housing-plan-proposal-offer-flow/spec.md`, with requirements and scenarios covering author flow, recipient flow, serial invalidation, broadcast of responses, history retention, and “fork from invalidated offer”.
