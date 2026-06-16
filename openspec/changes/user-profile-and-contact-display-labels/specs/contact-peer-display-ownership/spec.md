## ADDED Requirements

### Requirement: Canonical peer identity vs local display label
For each Contact representing another person, the app SHALL distinguish:

1. **Canonical peer identity** — display name and avatar **chosen by that peer** and learned through the handshake and subsequent **profile-update** envelopes (encrypted). This is what the peer asserts about themselves.
2. **Local display label** — an optional string **chosen only by the local user** that overrides how this contact is shown **in this user’s** Contacts list, module pickers, and other local surfaces that list contacts by name.

The **effective list name** for a contact SHALL be: local display label if set; otherwise the peer’s canonical display name.

The **avatar shown** for a peer SHALL always follow the peer’s **canonical** avatar from profile data. Other users SHALL NOT set or override a peer’s avatar on their own device except by receiving updated canonical avatar data from the peer (see scenario D).

#### Scenario: Default display uses canonical name
- **WHEN** no local display label is set for a connected contact
- **THEN** every local surface uses the peer’s canonical display name from the latest validated envelope

#### Scenario: Local display label hides an unpleasant canonical name
- **WHEN** the user sets a local display label for a contact
- **THEN** the Contacts list and other local surfaces show the label instead of the canonical name
- **THEN** the canonical name remains stored and remains the peer’s asserted identity

### Requirement: Duplicate names in one list are an accepted edge case (A)
The product SHALL NOT require globally unique display names. If two contacts share the same effective list name, the UI SHOULD disambiguate (e.g., secondary line, avatar, last interaction) but uniqueness is **not** a hard requirement.

#### Scenario: Two “Éric” entries
- **WHEN** two distinct contacts resolve to the same effective list name
- **THEN** the app remains functional and the user can still distinguish contacts through avatars and/or auxiliary UI hints

### Requirement: Renaming on someone else’s device is one-way information for the peer (C)
When user **G** sets or changes a **local display label** for user **F**, **F** SHALL be informed that **G** displays them under that label, **without** requiring F to accept or reject the change for G’s UI to apply.

#### Scenario: Peer sees how one contact labels them
- **WHEN** G sets F’s local display label to “Éric” and an appearance notice is delivered to F
- **THEN** F’s profile includes an entry that G currently sees them as “Éric”
- **THEN** F’s own canonical name is unchanged unless F edits it in Settings

### Requirement: “How I appear to others” is a concise matrix (E)
The local user’s profile (or a dedicated sub-screen) SHALL include a **table-style summary**: one row per **other contact** for which the app knows an effective label, columns at minimum: **Contact (canonical or stable id)** and **Their label for me**. Multiple rows reflect multiple contacts labeling the user differently.

#### Scenario: Fafoin sees Gilles and Monica
- **WHEN** Gilles labels Fafoin “Éric” and Monica labels Fafoin “Erik”
- **THEN** Fafoin’s matrix lists Gilles → “Éric” and Monica → “Erik” in a compact readable layout

### Requirement: Avatar is owner-only (D)
Only the **peer** may change their avatar canonical value. The local user SHALL NOT upload or push an avatar image/identifier onto someone else’s canonical identity record.

#### Scenario: Contact detail does not offer “change their avatar”
- **WHEN** the user opens a connected contact’s detail
- **THEN** there is no control that edits the peer’s canonical avatar as if it were local data
- **THEN** the user may still change **their own** avatar in Settings

### Requirement: Peer canonical name change with local override (F)
When a peer **updates their canonical display name** via profile-update:

- **WHEN** the new canonical string **equals** the local display label already in use for that contact  
- **THEN** the effective list name stays the same and the app SHALL NOT require a disruptive confirmation for that contact (optional subtle copy allowed).

- **WHEN** the new canonical string **differs** from the local display label (including when a label was never set and the old canonical differed)  
- **THEN** the app SHALL surface a non-blocking notification or inbox-style item: the peer has a new preferred name, with actions **Align to their name** (clears or resets local label so effective = canonical) and **Keep my label** (local display label unchanged).

- **WHEN** the peer's canonical name or avatar changes and a module participant row references that contact by `contactId`  
- **THEN** denormalized roster display fields on that row are updated per `contacts-module-integration` and `housing-plan-proposal-offer-flow` (task **1.24**)

#### Scenario: Monica keeps “Erik”
- **WHEN** Fafoin’s canonical name becomes “Éric” and Monica had overridden “Erik”
- **THEN** Monica receives the name-change affordance and can choose **Keep my label**, leaving her list showing “Erik” until she changes it

#### Scenario: Gilles sees no change when overrides matched
- **WHEN** Gilles had already set local label “Éric” and Fafoin’s canonical name updates to “Éric”
- **THEN** Gilles’s list continues to show “Éric” with no mandatory dialog

### Requirement: Disconnected contacts use a distinct user-facing status
For a Contact whose **technical** kind is `local-only` **because** routing was cleared after a prior `connected` relationship (disconnect demotion per `contact-privacy-and-deletion`), the app SHALL present status **Disconnected** (localized), not the generic “local only” string used for invitation stubs that were never connected.

Stub contacts that were **never** connected MAY continue to use the generic local-only label or a dedicated “Pending connection” label; exact copy is a UX decision but MUST NOT conflate with Disconnected.

#### Scenario: After mutual disconnect both users see Disconnected
- **WHEN** two peers disconnect and both devices demote the Contact to local-only without routing
- **THEN** each user’s Contacts list shows **Disconnected** (or equivalent localized string) for that row

### Requirement: Request reconnection reuses invitation + handshake
The app SHALL provide a **Request reconnection** (or equivalent) action on Disconnected contacts that launches the **same invitation and handshake flow** as first-time pairing: generate or obtain a fresh invitation, share out-of-band, redeem, `hello` / `ack`, promotion to `connected`. No separate relay “reconnect” transport is introduced.

#### Scenario: User taps Request reconnection
- **WHEN** the user confirms Request reconnection for a Disconnected contact
- **THEN** the app routes them into the existing invitation UX (`contact-invitation-and-codes` + `contact-handshake-over-relay`)
- **THEN** upon successful handshake the same stable Contact id is promoted where the domain model preserves ids across demotion

### Requirement: Contact detail prioritizes reconnect and local label over “edit their identity”
For Disconnected ex-peers, the primary actions SHOULD be **Request reconnection** and **Delete** (per privacy rules), not editing fields that resemble **their** canonical identity.

For any contact, editing the **name field** in contact UI SHALL mean editing the **local display label** (or clearing it), not impersonating a server-side change to the peer’s canonical name. Implementation MAY remove a legacy “edit name as if global” path entirely.

#### Scenario: User clears local label
- **WHEN** the user clears the local display label
- **THEN** the effective list name falls back to the peer’s canonical display name

### Requirement: Appearance notices respect privacy rules
Any payload that carries “how I label you on my device” SHALL travel only inside **encrypted peer-to-peer** envelopes, consistent with `contact-privacy-and-deletion` and `relay-state-schema-and-retention`. The relay MUST NOT gain plaintext access to these strings.

#### Scenario: No plaintext label in relay headers
- **WHEN** an appearance notice is sent
- **THEN** the label text appears only inside ciphertext addressed to the peer
