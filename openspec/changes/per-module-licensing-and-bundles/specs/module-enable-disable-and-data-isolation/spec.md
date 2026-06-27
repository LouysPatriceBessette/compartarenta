## ADDED Requirements

### Requirement: Each module can be enabled or disabled by the user independently
The app SHALL expose a **per-module enable/disable toggle** in settings (or an equivalent product surface). The toggle SHALL operate independently per module: enabling or disabling one module SHALL NOT change the enable/disable state of any other module.

#### Scenario: User disables vehicle-sharing but keeps housing and vehicle enabled
- **WHEN** a user toggles `vehicle-sharing` off in settings
- **THEN** the `vehicle-sharing` UI is removed from the main shell
- **THEN** the user cannot invite borrowers or log usage as a borrower until re-enabled
- **THEN** owned `vehicle` data remains on device unchanged

### Requirement: Disabling a module retains its local data
Disabling a module SHALL NOT delete or alter the module's on-device data. Re-enabling the module SHALL restore access to all of that data without loss, consistent with `data-locality-and-client-storage`.

#### Scenario: Re-enabling a module restores its data
- **WHEN** a user disables `housing`, waits, and re-enables `housing`
- **THEN** all previously stored `housing` data is available again unchanged

### Requirement: Disabling a module stops outbound relay traffic for that module
While a module is disabled, the app SHALL stop sending and accepting **module-scoped** relay traffic for that module (proposals, accept/reject, amendments). Relay traffic belonging to other modules and to non-module concerns (e.g., contact handshake) SHALL be unaffected.

#### Scenario: Disabled vehicle-sharing does not emit sharing-scoped proposals
- **WHEN** `vehicle-sharing` is disabled on a user's device
- **THEN** the device does not send new vehicle-sharing proposals over the relay
- **THEN** inbound vehicle-sharing proposals are not surfaced until `vehicle-sharing` is re-enabled

### Requirement: Disabling a module does not cancel its store subscription
The in-app enable/disable toggle SHALL NOT cancel the user's subscription on the platform store. The app SHALL communicate this explicitly in the toggle copy and link to the platform's subscription management UI when relevant.

#### Scenario: Disabling shows cancellation guidance
- **WHEN** a user toggles a module off while holding an active paid subscription for that module
- **THEN** the app surfaces a clear message that the subscription remains active until cancelled in the store, with a link to the store's subscription management UI

### Requirement: Module data is isolated per module on-device
The on-device store SHALL keep each module's operational data in a clearly identifiable scope (its own tables, namespaces, or equivalent) so that no module's queries can incidentally read or write data belonging to a different module.

#### Scenario: Module-scoped queries cannot read other modules' data
- **WHEN** the app issues a query for `housing` data
- **THEN** the query result set contains no `vehicle` data and no data from any other module

### Requirement: Export is available per module, independent of other modules' entitlement
The app SHALL provide an **export action per module** that produces the data of that module in a human-comprehensible format. Export availability for a module SHALL be governed only by that module's own entitlement rules (e.g., always available in read-only mode per `delinquency-grace-readonly-and-export` for housing) and SHALL NOT be blocked by the entitlement state of any other module.

#### Scenario: Export housing while vehicle is delinquent
- **WHEN** the user is in delinquent / read-only state on `vehicle` but in active-paid on `housing`
- **THEN** the user can export `housing` data without restriction
- **THEN** the user can also export `vehicle` data per `vehicle`'s own export rules (e.g., read-only export rule when defined for that module)

### Requirement: Export output identifies its module of origin
The exported artifact for a module SHALL clearly identify which module it represents (e.g., a header field, filename convention, or manifest entry). This is to support participants combining exports from multiple modules later for their own records.

#### Scenario: Filename or header reflects the module
- **WHEN** the user exports `housing` data
- **THEN** the exported file or its manifest names the module explicitly (no ambiguous filename like `export.csv`)

### Requirement: Re-enabling a module does not auto-replay missed peer activity it never received
Because outbound and inbound module-scoped relay traffic was paused while a module was disabled, the relay's TTL behavior may have caused undelivered proposals to expire (per `relay-sync-no-persistence`). The app SHALL NOT claim to surface "missed" proposals that have expired at the relay. When a module is re-enabled, the device SHALL resume normal relay subscriptions but SHALL NOT invent or simulate proposals that were never successfully received.

#### Scenario: Expired proposals are not resurrected at re-enable
- **WHEN** a user re-enables a module after a long disabled period during which inbound proposals expired at the relay
- **THEN** the re-enabled module does not display those expired proposals as pending
- **THEN** the originator must, per existing semantics, send a fresh amended proposal if they still want the change accepted
