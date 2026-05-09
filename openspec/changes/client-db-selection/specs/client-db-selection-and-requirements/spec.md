## ADDED Requirements

### Requirement: Client database prioritizes minimal storage footprint
The system MUST choose and implement an on-device database approach where minimizing storage footprint is a primary objective, even if it trades off raw performance beyond what is perceptible for a single-user mobile workload.

#### Scenario: Storage footprint is treated as a first-class constraint
- **WHEN** engineers evaluate client database options
- **THEN** the decision explicitly prioritizes disk footprint over performance micro-optimizations

### Requirement: Client database supports schema versioning and migrations
The system MUST implement a schema versioning and migration mechanism that can evolve stored data across app updates without requiring users to delete and recreate their data.

#### Scenario: App update triggers a migration
- **WHEN** the app starts after an update that changes the database schema
- **THEN** the app applies a migration from the previous schema version to the new one
- **THEN** previously stored operational data remains accessible after migration

### Requirement: Migration policy differs between release and development builds
For any schema version that has been released to users, the system MUST support forward-only migrations (N → N+1) without automatic data deletion. During active development (pre-release schemas), the system MAY allow developers to reset local storage to iterate quickly, but this MUST be an explicit development-only mechanism and MUST NOT be enabled automatically in release builds.

#### Scenario: Release build never wipes data automatically
- **WHEN** a user runs a release build and a migration is required or fails
- **THEN** the app does not automatically delete the user’s local operational data
- **THEN** the app surfaces a controlled recovery path (e.g., retry, support instructions, or an explicit user-confirmed reset)

#### Scenario: Development build can reset local DB explicitly
- **WHEN** a developer runs a development build and needs to iterate on an unreleased schema
- **THEN** the app provides an explicit development-only reset mechanism (e.g., debug menu action)
- **THEN** the reset is not available by default in release builds

### Requirement: Client database supports relational modeling for shared entities
The client database SHOULD support a relational model (or equivalent) that avoids duplicating shared entities and reduces storage usage for multi-entity domains (plans, participants, expenses, car uses, reservations, tickets).

#### Scenario: Shared participant is referenced rather than duplicated
- **WHEN** the same participant appears across many expenses and car uses
- **THEN** the database stores one participant record and references it from related records

### Requirement: Performance is not a primary decision factor for single-device workloads
The system MUST NOT select a client database primarily based on server-style throughput benchmarks; the decision MUST assume a single-device workload and treat performance as secondary to footprint, correctness, and migrations.

#### Scenario: Server benchmark results do not drive the decision
- **WHEN** a database option advertises high server-like throughput
- **THEN** the decision does not treat that as a primary justification for selection

