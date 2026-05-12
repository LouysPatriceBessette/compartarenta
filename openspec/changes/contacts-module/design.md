## Context

The app collects "participants" inline inside each module (housing today, vehicle tomorrow). For each new participant, the user types a display name and picks an avatar, and the result lives only inside that module's data. There is no way to link "this participant in housing is the same person as that participant in vehicle", no way for the participant's own device to confirm their identity, and no way to establish a trusted channel for the privacy-first sync flows already specified in `privacy-first-sync-architecture`. The Contacts capability fills this gap by becoming the **first** product feature that uses the encrypted relay end-to-end, and by becoming the **single place** in the app where a real person is represented.

This design defines the data model, the invitation/code mechanism for connecting two users out-of-band, the handshake performed over the encrypted relay, and how each module references contacts instead of authoring temporary participants. The actual deployment of the relay is specified in `relay-server-infrastructure-and-audit`; this change targets the on-device and protocol-level surface.

## Goals / Non-Goals

**Goals:**

- Define a single Contacts entity used by every module to refer to "a person the user knows".
- Define generation and out-of-band sharing of a **unique invitation code** that lets two devices identify each other on the relay without leaking identity to the relay.
- Define a **handshake protocol** that promotes a locally-created contact stub into a "connected" contact, on top of the relay semantics already specified.
- Define **migration** for existing module participants so adopting modules don't have to re-enter names and avatars manually.
- Define **privacy rules** so contact metadata (name, avatar) never reaches the relay in plaintext.
- Define **deletion** rules that do not retroactively corrupt module ledgers that referenced the contact.

**Non-Goals:**

- Defining the housing/vehicle module's exact integration code (each module owns its own follow-up change to adopt contacts).
- Inventing new cryptographic primitives. This design uses the asymmetric keys / encrypted envelopes already required by `end-to-end-encryption`.
- Address-book / OS-level contacts sync (Apple Contacts, Android People). Out of scope.
- Group concepts (a "household") beyond what is already a set of contacts referenced by a module.

## Decisions

### Decision: Contact is module-agnostic and lives in its own area

The Contact entity is stored independently of modules. Module-specific tables (housing participants, vehicle participants) hold **references** to a Contact ID, plus any module-specific attributes (e.g., a per-module display alias, role, share ratio, …). Module data does not embed name or avatar.

Rationale:

- One source of truth for identity ⇒ updating a name/avatar updates every module view.
- Mirrors the existing `participant-sets-are-independent-between-domains` rule from car sharing: participation in a module is still scoped to that module; only the **person record** is shared.
- Keeps the door open for additional modules without re-modelling.

Alternatives considered:

- **Embed name/avatar in module participant rows**: rejected — that's what we have today and is the problem.
- **Use an external system contact list (Apple Contacts / Android People)**: rejected — increases permission surface, conflicts with privacy-first stance, and many participants are app-only (no phone number / no real address book entry).

### Decision: Two kinds of contacts — local-only and connected

A **local-only contact** has just on-device data (name, avatar, optional notes). A **connected contact** additionally has a relay-routing identifier and the public material needed to send encrypted envelopes to that contact via the relay.

Rationale:

- Many real-world participants will never install the app (e.g., one-time roommate); a local-only contact lets the user keep using the app sensibly.
- Promotion from local-only → connected is the result of a completed handshake; downgrade is not automatic but can be triggered manually.
- The same Contact ID survives the promotion, so module references do not break.

### Decision: Unique invitation code format

The invitation code is generated **on-device** and carries enough entropy to be infeasibly guessable, plus a small human-checkable checksum.

- Internally it carries: the inviter's public handshake material (or a relay-stable address that resolves to that material) and a one-time nonce.
- Externally it is rendered as **either** a short human-readable token **or** an opaque deep link / QR string. The short human-readable token MUST embed a checksum so typos surface immediately, and MUST be short enough to dictate over a phone call.
- The code carries an **expiry** and is **single-use** by default (the invitee uses it once during the handshake; replays are rejected by the inviter's device because the nonce was consumed).
- The user shares the code **outside the app** (SMS, email, in person). The app does NOT send it through the relay on the inviter's behalf, because the relay has no relationship between these two users yet.

Rationale:

- Out-of-band sharing decouples connection-establishment from any pre-existing trust between users at the server level.
- A single-use nonce kills "code is leaked in a screenshot months later" replay attacks.
- A checksum on human-readable form prevents accidental cross-wiring with a typo.

Alternatives considered:

- **Server-issued codes**: rejected — adds a server identity to the relay's responsibilities beyond what `subscription-entitlement-minimal-server-state` allows.
- **QR-only codes**: rejected as sole option — there are flows (e.g., dictate over phone) where humans need a short readable code.

### Decision: Handshake protocol on top of the encrypted relay

The handshake is a small, well-defined exchange of encrypted envelopes on the relay defined by `relay-sync-no-persistence`:

1. The **inviter** generates an invitation code and creates a local-only contact stub (their side, "awaiting handshake"). The inviter also installs a **temporary listener** on the relay for the one-time address embedded in the code.
2. The **invitee** receives the code out-of-band, enters it in their app, and the app derives the relay address and the inviter's encryption key from the code.
3. The invitee creates a local-only stub for the inviter and sends a **`hello` envelope** to the inviter's one-time address. The envelope contains: invitee's public key material, invitee's chosen display name for themselves, invitee's avatar identifier, the nonce echoed from the code.
4. The inviter's device receives the `hello`, validates the nonce, and shows a **"someone is trying to connect"** UI to the inviter with the invitee's name + avatar. The inviter accepts or rejects.
5. If accepted, the inviter sends an **`ack` envelope** to the invitee with the inviter's own name + avatar + a stable relay-routing identifier. Both sides promote their stub to a connected contact.
6. The one-time address is decommissioned; further messages between the two use their established connected addresses.

Rationale:

- Exactly one round-trip is needed; both relay messages are encrypted; the relay never sees identity.
- Step 4 ensures the inviter always confirms the connection — mirroring the proposal/accept pattern used elsewhere in the product.
- Reusing the relay model keeps the security story coherent.

Alternatives considered:

- **Symmetric handshake (both parties enter a code into both apps)**: rejected as user-hostile; almost no other consumer app requires symmetric code entry.
- **Long-lived "address book broadcast"**: rejected because it forces a server-side identity registry, which contradicts the privacy-first stance.

### Decision: Migration of existing module participants

When the app is upgraded with this capability for the first time, **existing module participant rows are mirrored into Contacts** as local-only contacts:

- One Contact is created per unique (display name, avatar) pair within the user's data — duplicates across modules with identical name+avatar are unified.
- Each module's participant row is rewritten to reference its corresponding Contact ID; the inline name/avatar fields become deprecated (kept as a one-time fallback for audit/export but no longer authored).
- Migration creates **local-only** contacts; it does not pair anyone with another user. Promotion to "connected" still requires the explicit handshake.

Rationale:

- Adopting modules don't have to re-author all their participants.
- The de-duplication heuristic (same name + same avatar) is conservative; conflicts produce separate contacts that the user can merge manually later.
- No accidental over-claim that two unrelated users are "connected".

### Decision: Deletion does not retroactively corrupt module ledgers

Deleting a contact:

- Sets the contact to a deleted/archived state locally.
- Existing module references **remain intact** and continue to show the cached name/avatar from the deleted contact at the time of deletion (snapshot), so historical ledgers remain readable.
- New module entries can no longer reference the deleted contact.

Rationale:

- Preserves the local-first ledger semantics (`data-locality-and-client-storage`) — the user's accepted housing/vehicle data is not retroactively rewritten by an identity change.
- Avoids accidental data loss when the user intended to "delete from contacts" but not "erase historical activity".

### Decision: Privacy boundary for contacts and the relay

- The relay only ever sees encrypted envelopes; the routing identifier carried in metadata is opaque and not derived from the contact's display name or avatar.
- The relay never stores contact display names or avatars in any field; that is enforced by `relay-state-schema-and-retention` in the relay infrastructure change.
- The app NEVER uploads the user's full contact list to the relay or any other server — the only relay-visible facts are "I, identity A, want to send a ciphertext addressed to identity B".

Rationale:

- Coherence with `end-to-end-encryption` and `data-locality-and-client-storage`.
- Locks in the audit promise tracked by `relay-server-infrastructure-and-audit`.

## Risks / Trade-offs

- **Lost / leaked invitation code** → mitigation: short TTL, single-use nonce, explicit user copy when generating ("share this with one person only").
- **Wrong person enters the code** → mitigation: the inviter still has to explicitly accept the `hello` envelope showing the invitee's chosen name + avatar; the inviter can reject and re-issue a fresh code. The nonce being consumed prevents the wrong invitee from reusing it.
- **Identity drift over time** (a connected contact changes their name/avatar) → mitigation: updates flow as small encrypted envelopes between the connected contacts; the receiving side surfaces "this contact updated their profile" non-intrusively.
- **Module adoption lag** → housing and vehicle adopt contacts in their own follow-up changes; until they do, this change ships the Contacts area + handshake but the modules still author temporary participants. This change does NOT block on those follow-ups.
- **Apple/Google privacy reviews** (does this look like an address-book uploader?) → mitigation: explicit "out-of-band code sharing only" + no OS-contacts permission + no upload of any contact data; document the boundary in `mobile-app-privacy-compliance`.

## Migration Plan

1. Ship Contacts data tables and the on-device migration that mirrors existing module participants into local-only contacts.
2. Ship the Contacts UI (list, detail, add local-only, generate invitation).
3. Ship the relay-backed handshake (depends on `relay-server-infrastructure-and-audit` being live in at least one environment).
4. Each module's follow-up change re-points its participant pickers to use Contacts and stops authoring inline name/avatar.

Rollback strategy: contacts data is purely additive. The migration that mirrors participants into contacts is one-way but does not destroy existing module data, so rolling the app back to a previous version leaves the original participant rows intact (the deprecated inline name/avatar fallback).

## Open Questions

- Exact rendering of the human-readable invitation code (length, alphabet, grouping). The spec sets a minimum entropy and a checksum requirement; the precise letters/grouping is a UX decision.
- Whether to allow a contact to live "across multiple devices" of the same user (multi-device identity is a separate concern; flagged for a future change).
- Whether the inviter is shown a final "name as the contact will appear in my app" override after handshake or always takes the invitee's chosen self-name (UX, not specification).
