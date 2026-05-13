# Contacts Module Integration Contract

This document records the reusable contract for modules that need
participants. It complements the OpenSpec capability
`contacts-module-integration`; module-specific adoption work may add its own
deltas, but it must not redefine what a Contact is.

## Picker UX

Modules SHALL add participants through the shared Contacts picker. The picker
lists visible Contacts, distinguishes local-only / connected / blocked state,
and offers two entry points when the desired person is missing:

- **Add a contact** creates a local-only Contact without relay traffic.
- **Invite a contact** creates an out-of-band invitation code that can later
  promote the Contact to connected through the relay handshake.

Modules SHALL NOT expose a parallel authoritative flow that asks for a
temporary participant name and avatar inline after adopting Contacts.

## Participant Storage

Module participant rows SHALL store:

- a reference to the selected `Contacts.id`,
- module-specific fields such as role, share ratio, alias, or acceptance state,
- a historical display snapshot (`displayName`, `avatarId`) captured when the
  participant is added or when a proposal is accepted.

The Contact remains the source of truth for current display information while
the participant snapshot preserves historical readability if the Contact is
renamed or deleted later.

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
