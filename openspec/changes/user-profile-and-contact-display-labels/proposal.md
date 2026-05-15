## Why

Users need to **change their own display name and avatar after onboarding** (today this is implied by `initial-configuration` but not fully specified as a first-class Settings flow). Separately, **each user owns how a peer appears in their own Contacts list**: duplicates, unpleasant names, and personal nicknames are resolved locally without forcing the peer to approve a label. The peer must still be **informed** when someone else renames them in that person’s list, and must see a **concise matrix** of “how I appear to each contact” when multiple people use different labels.

After a **disconnect**, both sides currently see the technical `local-only` kind; the product should communicate **Disconnected** clearly and steer users toward **reconnection** using the **existing invitation + handshake** path (new code, same protocol stack).

This change is specification-only; implementation follows in a later pass.

## What Changes

- **Settings / self-identity:** explicit requirements to edit the user’s own display name and avatar after setup, with validation and propagation to connected peers via existing encrypted **profile-update** semantics (`contact-handshake-over-relay`).
- **Contact display ownership:** distinguish the peer’s **canonical** identity (what they choose for themselves and broadcast) from each owner’s **local display label** (how this device shows that contact). Only the peer edits their **avatar**; others cannot change it.
- **Peer visibility:** a profile area listing, per connected contact, the effective label that contact uses for the local user, plus any local override the user applied on their side.
- **Canonical name changes vs local overrides:** rules for notifications when the peer updates their name, and for **accept (align)** vs **keep override** when the new canonical name collides or relates to an existing local label (including the “already matches my override” silent case).
- **Disconnected UX:** user-facing status **Disconnected** (localized) for former `connected` contacts demoted after disconnect; primary action **Request reconnection** reuses **generate invitation + handshake** (no new transport).
- **Contacts detail:** de-emphasize editing the peer’s name/avatar as if it were their identity; replace with **local display label** editing and **reconnect** where applicable.

## Capabilities

### New Capabilities

- `self-identity-settings-and-sync`: Post-setup editing of the user’s display name and avatar in Settings; sync to peers.
- `contact-peer-display-ownership`: Local labels, peer notifications, “how I appear to others” matrix, avatar ownership, disconnect/reconnect UX requirements.

### Modified Capabilities

- `contacts-domain-model`: Disconnected presentation; pointer to split canonical vs local display.
- `contact-handshake-over-relay`: Clarify profile-update as **canonical self** broadcast; reference label/notification rules.
- `contact-privacy-and-deletion`: Disconnect/reconnect UX at product level (no new relay privacy class).
- `initial-configuration`: Cross-reference detailed post-setup identity editing to this change.

## Impact

- Touches **Settings**, **Contacts list/detail**, **Profile / self** UI, and possibly **new encrypted envelope kinds** or structured payloads for “appearance notices” (design decision in `design.md`).
- Builds on `contacts-module` handshake and profile-update paths; does not replace the relay trust model in `privacy-first-sync-architecture`.
