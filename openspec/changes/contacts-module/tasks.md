## 1. Data model and migration

- [ ] 1.1 Define the Contact entity in the on-device store (id, kind, display name, avatar identifier, optional notes, timestamps).
- [ ] 1.2 Add connected-contact fields (relay-routing identifier, peer public material) usable only when kind = connected.
- [ ] 1.3 Add a versioned migration that mirrors existing module participant rows into local-only Contact records and re-points participant references to Contact identifiers.
- [ ] 1.4 Keep deprecated inline name/avatar fields on existing module participant rows as one-time fallback (read-only after migration).
- [ ] 1.5 Add a per-module historical display snapshot mechanism (name, avatar captured at acceptance) for ledger readability after a Contact deletion.

## 2. Contacts UI

- [ ] 2.1 Add a Contacts area in the main shell (list, empty state, detail view, edit).
- [ ] 2.2 Implement local-only contact creation (name + avatar) without any relay traffic.
- [ ] 2.3 Implement contact detail view with kind indicator (local-only vs connected).
- [ ] 2.4 Implement edit / rename / change-avatar with updates surfaced through every module reference.
- [ ] 2.5 Implement delete (local, snapshot-preserving) and disconnect (sends disconnect envelope) as two distinct actions.
- [ ] 2.6 Implement a block action that locally suppresses inbound envelopes from a Contact.

## 3. Invitation codes

- [ ] 3.1 Implement on-device code generation (entropy + checksum + nonce + expiry + revocation flag), independent of network availability.
- [ ] 3.2 Implement a renderer for the human-readable short code (with checksum-aware validation on input).
- [ ] 3.3 Implement a QR / deep-link representation of the code for visual sharing.
- [ ] 3.4 Implement out-of-band sharing entry points (copy, share sheet, QR display).
- [ ] 3.5 Implement the outstanding-invitations list with statuses (pending, used, expired, revoked) and a revoke action.
- [ ] 3.6 Implement invitee entry UI (paste, type, scan QR) with locally-validated checksum before any relay call.

## 4. Handshake protocol over the relay

- [ ] 4.1 Implement the `hello` envelope encoder (invitee → inviter) including invitee's public material, display name, avatar identifier, and echoed nonce.
- [ ] 4.2 Implement the `ack` envelope encoder (inviter → invitee) including inviter's public material, display name, avatar identifier, and stable relay-routing identifier.
- [ ] 4.3 Implement the inviter's incoming-handshake confirmation UI (clearly labeled "Incoming connection request", accept / reject).
- [ ] 4.4 Implement nonce consumption: a nonce becomes invalid as soon as a `hello` envelope referencing it has been validated by the inviter's device, whether the inviter accepts or rejects.
- [ ] 4.5 Implement the rejection path (no `ack` sent; documented signal back to the invitee).
- [ ] 4.6 Implement decommissioning of the one-time handshake routing address after the handshake completes (accept or reject).
- [ ] 4.7 Implement promotion of the local Contact stub to connected on both sides after a successful handshake.
- [ ] 4.8 Implement profile-update envelopes for connected contacts (display name / avatar changes propagate to peers via encrypted envelopes).
- [ ] 4.9 Implement disconnect envelope dispatch on the explicit Disconnect action.

## 5. Module integration contract

- [ ] 5.1 Document the `contacts-module-integration` contract for adopting modules (housing first), including picker UX, snapshot rules, and per-module alias storage.
- [ ] 5.2 Provide a participant picker widget that lists Contacts, surfaces kind, and offers "Add new contact" + "Invite contact" entry points.
- [ ] 5.3 Ensure no parallel "inline temporary participant" path remains accessible from inside adopting modules.

## 6. Privacy compliance and audit alignment

- [ ] 6.1 Update `mobile-app-privacy-compliance` (or its successor doc) to describe Contacts data and confirm no OS-address-book permission usage.
- [ ] 6.2 Add a documentation entry describing the relay-payload surface for Contacts (handshake envelopes, profile updates, disconnect) so it can be reviewed alongside `relay-state-schema-and-retention`.
- [ ] 6.3 Confirm via code review and tests that no relay request body, header, or query parameter carries plaintext contact metadata.

## 7. Tests

- [ ] 7.1 Unit tests for code generation, checksum validation, expiry, single-use nonce consumption, and revocation.
- [ ] 7.2 Unit tests for de-duplication policy in the migration (identical name+avatar unify; otherwise distinct).
- [ ] 7.3 Integration test for full happy-path handshake (inviter accepts; both sides become connected).
- [ ] 7.4 Integration test for handshake rejection (no `ack`; invitee receives the documented signal; neither side persists a connected Contact).
- [ ] 7.5 Integration test for delete and disconnect: ledger snapshots remain readable; peer is unaffected by delete; peer is informed by disconnect.
- [ ] 7.6 Integration test confirming no relay request contains plaintext contact metadata (snapshot-style assertion on outbound requests).
