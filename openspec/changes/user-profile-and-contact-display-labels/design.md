## Context

`initial-configuration` already states that settings remain editable after onboarding, but the product still needs an explicit **self-identity** capability: display name + avatar owned by the user, editable in **Settings**, and synchronized to connected contacts using the existing **profile-update** envelope path (`contact-handshake-over-relay`).

Contacts today conflate “what I call this person on my device” with fields that also represent **last known peer identity** from the relay. This change **splits concerns**:

| Concept | Owner | Stored on | Relay |
|--------|--------|-----------|--------|
| User’s own display name + avatar | Local user | preferences / profile store | Propagated as **canonical self** in profile-update to each connected peer |
| Peer’s canonical name + avatar | Peer | Contact row fields updated from decrypted inbound envelopes | Only inside encrypted payloads |
| **Local display label** for a peer | Local user only | Contact row (or sibling table) | Optional small encrypted **appearance notice** so the peer knows how they are shown (informational; no accept/reject) |

## Goals

- Settings: user can change **own** name + avatar after setup.
- Contacts: user can set **how a peer appears in their list** without changing the peer’s canonical identity.
- Peer is **informed** of renames done on others’ devices (read-only awareness in their profile).
- Peer sees a **compact table**: for each other contact, how that contact currently labels the peer.
- When peer changes **canonical** name, contacts who use a **different** local override get a clear **sync or keep** choice; if the new canonical equals the local override, **no visible change** on that contact’s list.
- **Disconnected** is a **presentation** state for demoted ex-connected contacts; **Request reconnection** reuses **invitation + handshake** (new code; same security properties as first pairing).

## Non-Goals

- Server-side display names or global username registry.
- Moderation or blocking of peer-chosen canonical names (local overrides address discomfort).
- Letting contact owners edit another user’s avatar.

## Decision: Reconnection reuses invitation + handshake

After disconnect, routing material is cleared (`demoteToLocalOnly`). There is **no** pre-existing pairwise routing to “nudge” a reconnect without a fresh shared secret.

**Request reconnection** SHALL route the user into the same **generate invitation → out-of-band share → redeem → hello/ack** flow already specified. UX MAY pre-fill context (“Reconnecting with X”) but MUST NOT weaken nonce expiry, single-use, or encryption rules.

## Decision: Optional encrypted “appearance notice” envelope

To satisfy awareness requirements (user C) without accept/reject workflows for renames on someone else’s phone, the implementation MAY introduce a small encrypted envelope (or extend profile-update with a distinct typed payload) sent **peer → peer** meaning: “on my device, I currently display you as \<label\>”. Delivery is best-effort; if the peer is disconnected, notices queue or drop per TTL like any other envelope.

This is **informational only**: it does not change the recipient’s canonical self-identity and requires **no** acknowledgement to take effect on the sender’s side.

## Decision: “Fafoin → Éric” merge behavior (scenario F)

When the peer updates canonical name:

- If a contact’s **local override** already equals the new canonical string, the **effective** list label is unchanged; **no** notification is required for that contact (optional subtle “now matches their chosen name” is allowed).
- If a contact’s **local override** differs, the app SHALL surface an inbound **name update** affordance: **Use their new name** (clears override or sets it to canonical) vs **Keep my label** (override unchanged). This is **only** on the recipient of the profile-update, not a negotiation with the peer.

Exact copy and notification channel (banner vs inbox row) are UX details; the spec states the behavioral contract.

## Risks / Open Points

- Volume of appearance notices if users rename often: rate-limit or batch in UI.
- Conflict with future “verified display name” features: this design assumes **self-asserted** canonical names only.
