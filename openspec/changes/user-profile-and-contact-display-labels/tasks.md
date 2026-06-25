> **Status:** Client-side implementation largely complete (Sections 1–3, 5). Relay appearance-notice envelopes (Section 6) and peer-appearance matrix UI (4.1) remain open.

## 1. Data model

- [x] 1.1 Add persisted fields (or a sibling table) for **local display label** per Contact, distinct from canonical name fields updated from the relay.
- [x] 1.2 Persist last-known **canonical** peer name and avatar separately from local label; migrate existing rows conservatively.
- [x] 1.3 Add a durable flag or derivation rule for **Disconnected** presentation (ex-`connected` without routing vs never-connected stub).

## 2. Settings — self identity

- [x] 2.1 Settings UI: edit display name with the same validation as onboarding.
- [x] 2.2 Settings UI: edit avatar from the supported palette.
- [x] 2.3 Wire saves to existing profile-update broadcast for connected peers.
- [x] 2.4 Block self **display-name** save and name-bearing `profile_update` broadcast while the local user is on roster for an open housing vote (`housing-plan-proposal-offer-flow` / task **1.24**); avatar-only edits remain allowed.

## 3. Contacts UI

- [x] 3.1 List + detail: show **Disconnected** where applicable; remove misleading “local only” copy for demoted peers.
- [x] 3.2 Detail: **Request reconnection** routes to invitation flow; contextual copy for reconnect.
- [x] 3.3 Detail / overflow: edit **local display label** only; clarify copy that this is “how you see them”.
- [x] 3.4 Remove or repurpose any legacy path that edits a peer’s name as if it were canonical identity.

## 4. Profile — peer view matrix

- [ ] 4.1 Profile screen: **How I appear to others** compact table (columns: contact, their label for me).
- [x] 4.2 Ingest appearance notices (or equivalent) to populate the matrix; handle offline / TTL drops gracefully. _(Placeholder copy only until relay notices land.)_

## 5. Notifications — canonical name changes

- [x] 5.1 On inbound profile-update changing peer canonical name, compare to local display label; implement silent match vs prompt with **Align** / **Keep my label**.
- [x] 5.2 Localization for all new strings (EN baseline per repo rules; FR/ES follow `ui-localization-fr-en-es`).

## 6. Relay / crypto (deferred follow-up commit)

- [ ] 6.1 Define or extend encrypted envelope type for **appearance notices** (informational only), with schema versioning and rejection of malformed payloads.
- [ ] 6.2 Document payload in `docs/contacts-module-relay-payload.md` (or successor) once shape is fixed.

_Client-side handling of existing `profile-update` envelopes (canonical rename vs local label, dialog) is implemented in the app; the items above cover **new** relay traffic for peer-appearance matrix sync._

## 7. Tests

- [ ] 7.1 Unit tests: effective name resolution (override, clear, missing canonical).
- [ ] 7.2 Unit tests: scenario F branching (equal vs unequal override).
- [ ] 7.3 Widget or integration tests: Settings save triggers profile-update fan-out (mock relay).
