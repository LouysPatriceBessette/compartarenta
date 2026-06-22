## ADDED Requirements

### Requirement: Installation identity can be migrated from old to new

The service SHALL accept a migration request (from the relay on behalf of a registered installation) that replaces `old_participant_installation_id` with `new_participant_installation_id` in **all** durable records where the old id is referenced — including but not limited to roster membership, trial consumption markers, license state rows, and expense decision metadata.

The request SHALL include a module plan identifier (e.g. housing `plan_id`). The service SHALL reject migration when the plan identifier does not match the plan associated with the old installation id.

#### Scenario: Successful migration rebinds roster slot

- **WHEN** migration is requested with a known old id, matching plan id, and a registered new id
- **THEN** every entitlement record that referenced the old id now references the new id
- **THEN** introspection for gated operations with the new id and the same plan returns allow when other policy checks pass

#### Scenario: Unknown old id

- **WHEN** migration is requested for an old installation id that does not exist
- **THEN** the service returns failure with a documented error code

#### Scenario: Plan id mismatch

- **WHEN** the supplied plan id does not match entitlement's binding for the old installation id
- **THEN** migration fails and no records are updated

### Requirement: Migration does not store business payloads

Installation migration SHALL update only entitlement and gating metadata. It SHALL NOT accept or persist relay ciphertext, expense amounts, or plan line text.

#### Scenario: Migration payload is minimal

- **WHEN** a migration request is processed
- **THEN** only installation identity and plan correlation fields are consumed
