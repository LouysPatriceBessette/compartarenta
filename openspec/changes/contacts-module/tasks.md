> **Implementation status.** Wave A (everything that runs purely on-device,
> no relay, no crypto primitives) has landed. Wave B (handshake on the
> relay, disconnect envelopes, profile updates) has now landed on the
> client side: see `lib/relay/*`, `HandshakeOrchestrator`, and the
> updated invite/redeem/contact-detail screens. End-to-end integration
> tests against a live relay (tasks 7.3–7.6) remain pending until the
> relay deployment is reachable from CI.

## 1. Data model and migration

- [x] 1.1 Define the Contact entity in the on-device store (id, kind, display name, avatar identifier, optional notes, timestamps).
- [x] 1.2 Add connected-contact fields (relay-routing identifier, peer public material) usable only when kind = connected.
- [x] 1.3 Add a versioned migration that mirrors existing module participant rows into local-only Contact records and re-points participant references to Contact identifiers.
- [x] 1.4 Keep deprecated inline name/avatar fields on existing module participant rows as one-time fallback (read-only after migration).
- [x] 1.5 Add a per-module historical display snapshot mechanism (name, avatar captured at acceptance) for ledger readability after a Contact deletion.

## 2. Contacts UI

- [x] 2.1 Add a Contacts area in the main shell (list, empty state, detail view, edit).
- [x] 2.2 ~~Implement local-only contact creation (name + avatar) without any relay traffic.~~ **Superseded:** manual local-only creation was removed from the Contacts UI; local-only rows remain only for invitation stubs, disconnect demotion, and migration. Co-participants in modules must be **connected** contacts (see `contacts-module-integration` and housing validation).
- [x] 2.3 Implement contact detail view with kind indicator (local-only vs connected).
- [x] 2.4 Implement edit / rename / change-avatar with updates surfaced through every module reference.
- [x] 2.5 Implement delete (local, snapshot-preserving) and disconnect (sends disconnect envelope) as two distinct actions. *(Wave A: delete + local snapshot preservation. Wave B: disconnect envelope dispatch over the relay. Wave B follow-up: deletion is now refused while a Contact is still referenced by a module plan or is currently `connected`; the UI redirects to plan reassignment or the explicit Disconnect action — see `contact-privacy-and-deletion`.)*
- [x] 2.6 Implement a block action that locally suppresses inbound envelopes from a Contact.

## 3. Invitation codes

- [x] 3.1 Implement on-device code generation (entropy + checksum + nonce + expiry + revocation flag), independent of network availability.
- [x] 3.2 Implement a renderer for the human-readable short code (with checksum-aware validation on input).
- [x] 3.3 Implement a QR / deep-link representation of the code for visual sharing. *(QR rendering is implemented with `qr_flutter`; QR scan uses the existing deep-link representation and normalizes it back to the short code before local validation.)*
- [x] 3.4 Implement out-of-band sharing entry points (copy, share sheet, QR display). *(Copy + deep-link landed; full share-sheet integration deferred to Wave B alongside QR.)*
- [x] 3.5 Implement the outstanding-invitations list with statuses (pending, used, expired, revoked) and a revoke action.
- [x] 3.6 Implement invitee entry UI (paste, type, scan QR) with locally-validated checksum before any relay call.
- [ ] 3.7 **Invitation expiry reminder** notifications (outgoing pending invitations).
  - **Implement together with** [`housing-plan-proposal-offer-and-responses` **1.4b**](../housing-plan-proposal-offer-and-responses/tasks.md) — shared local scheduling service, lead-time table, cancel/reschedule rules, and notification-prefs gating.
  - For each **pending** invitation created on this device (`expiresAt` on the invitation row, code not yet consumed), schedule one or more **local notifications** before expiry.
  - **Lead times** depend on the invitation validity duration / preset (product table aligned with housing deadline presets where sensible — document when fixed).
  - **Cancel / reschedule** when the invitation is used, revoked, or expires; reschedule if validity is extended.
  - Respect app-level master notification switch and the Contacts category for **invitation expiration** (enable the Settings switch that is today visible but disabled once this ships; see `notification-permission-management` wishlist).
  - **Not** the same as the “incoming handshake request” notification; copy MUST distinguish invitation **expiring soon** vs **new connection request**.
  - Log reminder-fired events in the Settings activity log when that store exists (`housing-plan-proposal-offer-and-responses` **1.8**).

## 4. Handshake protocol over the relay

- [x] 4.1 Implement the `hello` envelope encoder (invitee → inviter) including invitee's public material, display name, avatar identifier, and echoed nonce. *(See `lib/relay/envelopes.dart` `EnvelopeCodec.encryptHello/decryptHello` and `relay_envelopes_test.dart`.)*
- [x] 4.2 Implement the `ack` envelope encoder (inviter → invitee) including inviter's public material, display name, avatar identifier, and stable relay-routing identifier. *(See `EnvelopeCodec.encryptAck/decryptAck`; the steady-state routing id is derived from both long-term keys in `RelayRouting.steadyStateAddress`.)*
- [x] 4.3 Implement the inviter's incoming-handshake confirmation UI (clearly labeled "Incoming connection request", accept / reject). *(See `IncomingHandshakesScreen` and the banner on `ContactsListScreen`.)*
- [x] 4.4 Implement nonce consumption: a nonce becomes invalid as soon as a `hello` envelope referencing it has been validated by the inviter's device, whether the inviter accepts or rejects. *(See `HandshakeOrchestrator._consumeInvitation` invoked on hello decryption.)*
- [x] 4.5 Implement the rejection path (no `ack` sent; documented signal back to the invitee). *(See `HandshakeOrchestrator.rejectIncoming`; the ack frame carries `accepted=false`.)*
- [x] 4.6 Implement decommissioning of the one-time handshake routing address after the handshake completes (accept or reject). *(See `_decommissionHandshakeAddresses`.)*
- [x] 4.7 Implement promotion of the local Contact stub to connected on both sides after a successful handshake. *(See `ContactsRepository.promoteToConnected` and the orchestrator's `_finalize*` methods.)*
- [x] 4.8 Implement profile-update envelopes for connected contacts (display name / avatar changes propagate to peers via encrypted envelopes). *(See `HandshakeOrchestrator.broadcastProfileUpdate` wired in `app.dart` via the prefs listener.)*
- [x] 4.9 Implement disconnect envelope dispatch on the explicit Disconnect action. *(See `HandshakeOrchestrator.sendDisconnect` and the Disconnect button on `ContactDetailScreen` for connected contacts.)*

## 5. Module integration contract

- [x] 5.1 Document the `contacts-module-integration` contract for adopting modules (housing first), including picker UX, snapshot rules, and per-module alias storage. *(See `docs/contacts-module-integration.md`.)*
- [x] 5.2 Provide a participant picker widget that lists **connected** contacts, surfaces blocked exclusion, and offers an **Invite** entry point (no manual local-only creation for module participants).
- [x] 5.3 Ensure no parallel "inline temporary participant" path remains accessible from inside adopting modules. *(Housing now routes participant selection through the Contacts picker and stores the selected `contactId` plus a snapshot.)*
- [x] 5.4 Enforce **connected-only** co-participants for housing (picker + advance-step validation); `/contacts/new` redirects to invite generation. *(Commercial rule: every co-participant uses the app on their own account.)*

## 6. Privacy compliance and audit alignment

- [ ] 6.1 Update `mobile-app-privacy-compliance` (or its successor doc) to describe Contacts data and confirm no OS-address-book permission usage.
- [x] 6.2 Add a documentation entry describing the relay-payload surface for Contacts (handshake envelopes, profile updates, disconnect) so it can be reviewed alongside `relay-state-schema-and-retention`. *(See `docs/contacts-module-relay-payload.md`.)*
- [ ] 6.3 Confirm via code review and tests that no relay request body, header, or query parameter carries plaintext contact metadata.

## 7. Tests

- [x] 7.1 Unit tests for code generation, checksum validation, expiry, single-use nonce consumption, and revocation. *(See `test/invitation_code_test.dart` and `test/contacts_repository_test.dart`.)*
- [x] 7.2 Unit tests for de-duplication policy in the migration (identical name+avatar unify; otherwise distinct). *(See `test/contacts_migration_test.dart`.)*
- [ ] 7.3 Integration test for full happy-path handshake (inviter accepts; both sides become connected). *(Wave B.)*
- [ ] 7.4 Integration test for handshake rejection (no `ack`; invitee receives the documented signal; neither side persists a connected Contact). *(Wave B.)*
- [ ] 7.5 Integration test for delete and disconnect: ledger snapshots remain readable; peer is unaffected by delete; peer is informed by disconnect. *(Wave A delete-only path can be covered now; full disconnect path is Wave B.)*
- [ ] 7.6 Integration test confirming no relay request contains plaintext contact metadata (snapshot-style assertion on outbound requests). *(Wave B.)*

## 8. Relay: static contact-invite landing (`relay/deploy/landing/contact/invite/`)

Browser-served HTML/JS on the relay vhost (release + audit required for each
deploy). Tracked separately from Flutter so client work can proceed first.

The mobile app now registers `compartarenta://contact/invite` on **Android and
iOS** and routes it with **`app_links`** to the redeem screen, which covers the
main “Open in Compartarenta” failure that was previously attributed to the
landing page alone. Remaining relay work is UX on the **HTTPS** page (copy,
languages, store badge placeholders); in-app mail WebViews that block custom schemes are an environment
limit, not something the relay HTML can fully fix without store / universal-link
work.

- [x] 8.1 **Copy UX**: add an explicit control to copy the invitation link (and
      optionally the short code) with clear feedback (`navigator.clipboard` +
      visible “copied” state / toast).
- [x] 8.2 **Languages**: keep primary instructions + CTA + link box in **English**
      by default; move FR/ES (and future locales) behind a small client-side
      language toggle (plain JS), so unknown invitee language defaults to English.
- [x] 8.3 **Store badges (no links yet)**: on the HTTPS invite page, show the
      official **Google Play** and **Apple App Store** badge images for invitees
      who have not installed the app. For now use **static logos only** (no
      `href`) because the app is not published. Add a short line of copy in
      **English** next to or under the badges, e.g. *“Don’t have Compartarenta
      installed yet? You’ll find it on Google Play and the App Store.”* (adjust
      for layout; follow each platform’s badge artwork guidelines). Wire real
      store URLs in a follow-up tracked with store release (see
      `mobile-app-store-release` tasks).

## 9. Known bugs (backlog)

- [ ] 9.1 **Bug (medium / non-blocking):** Contact handshake may report relay failure or expiry while the peer completes the connection — invitee left without a connected contact.
  - **Severity:** medium / non-blocking.
  - **Reproducibility:** uncertain (observed once in dev, May 2026).
  - **Screenshots:**
    - [`assets/bugs/contact-handshake-relay-unreachable-2026-05-28.png`](assets/bugs/contact-handshake-relay-unreachable-2026-05-28.png) — redeem screen after first submit: valid code format, then *Relais injoignable. Vérifiez votre connexion et réessayez.*
    - [`assets/bugs/contact-handshake-code-expired-on-retry-2026-05-28.png`](assets/bugs/contact-handshake-code-expired-on-retry-2026-05-28.png) — resubmitting the same code: *Cette invitation a expiré.*
    - [`assets/bugs/contact-handshake-web-connected-peer-2026-05-28.png`](assets/bugs/contact-handshake-web-connected-peer-2026-05-28.png) — inviter (web): contact *Louys* shows **Connected**.
    - [`assets/bugs/contact-handshake-android-empty-contacts-2026-05-28.png`](assets/bugs/contact-handshake-android-empty-contacts-2026-05-28.png) — invitee (Android): Contacts list still empty.
  - **Repro (reported):**
    1. On the invitee device, open **Enter a code** and submit an invitation code.
    2. UI shows relay unreachable (*Relais injoignable* / `contactsHandshakeErrorRelayUnavailable`).
    3. On the inviter device, the incoming handshake is received and **accepted**.
    4. On the invitee device, submit the **same** code again.
    5. UI shows invitation expired (*Cette invitation a expiré* / `contactsHandshakeErrorExpired`).
  - **Actual:** Asymmetric outcome — inviter has a connected contact; invitee does not. Retry is blocked by expired / consumed invitation state.
  - **Expected:** If the `hello` reached the relay and the inviter accepted, the invitee should eventually reach **Connected** (or show a recoverable in-progress state), not a false negative followed by a one-way success. Resubmitting the same code should not be required when the handshake already completed on the peer.
  - **Hypothesis:** Relay feedback window or initial HTTP error handling is too aggressive (`HandshakeOrchestrator.redeemInvitation` → `relay_unavailable`; `RedeemInvitationScreen` outcome polling / error mapping). The inviter may consume the nonce while the invitee still shows failure; late `ack` may not promote the invitee contact row.
  - **Likely area:** `mobile/lib/relay/handshake_orchestrator.dart`, `mobile/lib/screens/contacts/redeem_invitation_screen.dart`, pending-handshake rows and `processAllPendingHandshakes` / steady inbox poll timing.
  - **Related:** task **4.4** (nonce consumption on `hello`), task **4.7** (promotion to connected on both sides).

- [ ] 9.2 **Bug (high / likely — housing cross-cut):** In-flight housing proposal not re-sent when a co-participant renames before all peer contacts exist — recipients stay blocked on stale participant identity. **Track implementation in** [`housing-plan-proposal-offer-and-responses` task **1.24**](../housing-plan-proposal-offer-and-responses/tasks.md).
