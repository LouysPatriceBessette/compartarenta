# Housing plan — peer contact establishment (plan-mediated pairing)

## Motivation

When Monica sends a housing plan to Louys and Roberr, each recipient already knows the other co-participants' **long-term relay public keys** from the proposal payload. They are not "unknown users" for pairing purposes: the missing piece is only the **local connected contact row** and steady-state routing on each device.

Today the app blocks plan acceptance and offers **invitation codes** (create / redeem). That flow is the wrong tool when identities are already disclosed inside the encrypted proposal.

## What changes

1. **Proposal payload** — each `participantSnapshots[]` entry for a connected co-participant on the proposer device SHALL include `peerPublicMaterialB64` (long-term X25519 public key).
2. **On proposal import** — missing-contact detection unchanged in purpose; additionally each missing peer's public key is added to the device's **inbound establishment watch list** (steady-state poll + closed-app push registration for the pairwise listen address).
3. **Missing-contacts UI** — replace invitation-code actions with **Establish contact** per missing row (proposal / amendment / any housing import).
4. **Plan-mediated establishment protocol** — encrypted relay messages between known public keys: request → accept/refuse response → connected contacts on both sides when accepted; local-only refusal timestamp for the requester when refused.
5. **Invitation codes** — remain for **out-of-band unknown pairing**; removed only from the housing missing-contacts hub.

## Relationship to existing capabilities

| Capability | Relationship |
|------------|--------------|
| `plan-contract-proposal-payload` | **Modified** — participant identity snapshots include relay public keys. |
| `housing-plan-proposal-offer-flow` | **Modified** — missing-contact remediation uses plan-mediated establishment, not codes. |
| `contact-invitation-and-codes` | **Unchanged** for general pairing; **not used** on housing missing-contacts surfaces. |
| `contact-handshake-over-relay` | **Companion** — hello/ack-by-code remains for strangers; plan-mediated path is a **separate** steady-state envelope exchange between known keys. |
| `closed-app-push-delivery` | **Extended** — wake transport applies to plan-mediated establishment envelopes. |
| `data-locality-and-client-storage` | **Aligned** — one installation per user; no multi-device sync. |

## Out of scope

- Implementation (this change is spec-only until approved).
- Relay binary changes (client-only bootstrap using existing `establishRouting` + envelope POST semantics).
- Replacing invitation codes globally.

## Deliverables

- [`specs/housing-plan-peer-contact-establishment/spec.md`](specs/housing-plan-peer-contact-establishment/spec.md)
- [`specs/contact-plan-mediated-establishment/spec.md`](specs/contact-plan-mediated-establishment/spec.md)
- Delta specs under this change for modified capabilities (see `specs/*/spec.md`).
