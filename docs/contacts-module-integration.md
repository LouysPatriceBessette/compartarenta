# Contacts Module Integration Contract

This document records the reusable contract for modules that need
participants. It complements the OpenSpec capability
`contacts-module-integration`; module-specific adoption work may add its own
deltas, but it must not redefine what a Contact is.

## Picker UX

Modules SHALL add co-participants through the shared Contacts picker. The picker
lists **connected** contacts only (not locally blocked). When the desired person
is missing, the picker SHALL offer an **Invite** entry point so they can
complete the handshake and become connected.

The legacy **manual local-only** path (`contact:local:`) is not a supported way
to add people who will participate in relay-backed plans. **Local-only** rows
still exist on-device for invitation stubs, post-disconnect demotion, and
migration placeholders, per `contacts-domain-model`.

Modules SHALL NOT expose a parallel authoritative flow that asks for a
temporary participant name and avatar inline after adopting Contacts.

## Participant Storage

Module participant rows SHALL store:

- a reference to the selected `Contacts.id`,
- module-specific fields such as role, share ratio, alias, or acceptance state,
- a historical display snapshot (`displayName`, `avatarId`) captured when the
  participant is added or when a proposal is accepted.

The Contact remains the source of truth for current display information. Module participant rows also store a **denormalized** `displayName` / `avatarId` copy (linked by `contactId`) for roster rendering; those fields are updated when the Contact’s canonical profile changes (inbound `profile_update`), per `housing-plan-proposal-offer-flow` task **1.24**. Separate **historical** snapshots captured at acceptance remain unchanged.

## Profile rename and housing votes

- **Before send / outside open votes:** inbound `profile_update` and local self-rename update linked `participants` rows (`contactId` match or `:self` rows).
- **During open housing votes** (proposal, amendment, participation change, agreement-expiration settlement window): the local user **cannot** change their own **display name**; avatar-only edits remain allowed; no name-bearing `profile_update` broadcast.
- **Plan-mediated establishment race:** when `contactEstablishmentRequest` / `contactEstablishmentResponse` arrives with the same `peerPublicMaterialB64` as a known missing peer but a different display name, reconcile establishment row, participant row, contact (if any), and revision `participantSnapshots` — without adding pubkey fallback to general missing-contact matching.

## Alias Rules

If a module needs a module-specific display alias, it SHALL store that alias on
the module participant row, not on the Contact. The alias is scoped to that
module only and does not change the Contact's canonical display name in other
modules.

## Housing Adoption

The housing participant step now uses the shared Contacts picker. Choosing a
Contact fills the housing participant snapshot and persists the `contactId`
reference. The previous inline temporary name/avatar authoring path is no
longer exposed from the housing step.

When a participant receives a housing proposal, co-participants who are not yet
connected locally may be reached through **Establish contact** on the plan
missing-contacts screen. That path uses encrypted steady-state envelopes
(`contactEstablishmentRequest` / `contactEstablishmentResponse`) and public keys
from `participantSnapshots` in the proposal payload — not invitation codes.
The requester enters outbound-pending state until the target explicitly accepts;
only then are both sides promoted to connected contacts.
