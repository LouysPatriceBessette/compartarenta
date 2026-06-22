## ADDED Requirements

### Requirement: Relay forwards installation migration to entitlement

The relay SHALL accept envelope kind **`participantInstallationMigration` (15)** from a registered sender and forward the migration payload to the entitlement service. This kind is **not** subject to introspection against the **old** installation id (the purpose is rebinding).

#### Scenario: Migration envelope reaches entitlement

- **WHEN** a client sends kind 15 after successful local import
- **THEN** the relay forwards old id, new id, and plan id to entitlement migration handling
- **THEN** the client receives success or failure without partial server state
