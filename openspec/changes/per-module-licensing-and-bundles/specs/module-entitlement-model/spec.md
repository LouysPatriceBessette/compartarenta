## ADDED Requirements

### Requirement: The product is organized into independently-purchasable modules
The product SHALL be organized as a set of named **modules** (e.g., `housing`, `vehicle`, `vehicle-sharing`, and future modules). Each module SHALL have its own entitlement state on-device, evaluated independently from other modules. Modules SHALL be independently purchasable through the platform stores **except where `module-subscription-dependencies` defines a functional dependency** (e.g., sharing out a vehicle requires both `vehicle` and `vehicle-sharing`).

#### Scenario: A user holds entitlement on one module without holding entitlement on another
- **WHEN** a user has an active paid subscription for `housing` and no subscription for `vehicle`
- **THEN** the app treats the user as fully entitled for `housing` and as un-entitled (free / not-yet-active) for `vehicle`
- **THEN** module-specific behavior for `vehicle` is unaffected by the active-paid status of `housing`

#### Scenario: A user holds entitlement on multiple modules simultaneously
- **WHEN** a user has independent active subscriptions for `housing` and `vehicle`
- **THEN** the app treats the user as fully entitled for both modules at the same time

### Requirement: Module identity is stable and human-readable
Each module SHALL have a stable, documented identifier (kebab-case string) used across spec deltas, app code, store mapping, and audit material. Module identifiers SHALL NOT be reused for unrelated purposes and SHALL NOT change after the module ships to production.

#### Scenario: Module identifier is referenced consistently
- **WHEN** a spec or store-mapping document refers to a module
- **THEN** it uses the documented identifier exactly (no abbreviations, no aliases)

### Requirement: Adding a future module does not require restructuring existing modules
Adding a new module to the product SHALL be possible without modifying the on-device entitlement state of already-shipped modules, without invalidating existing per-module subscriptions, and without renaming or moving any existing module's store products or subscription groups.

#### Scenario: Adding a third module preserves existing subscriptions
- **WHEN** a third module is introduced after `housing` and `vehicle`
- **THEN** existing `housing` and `vehicle` subscriptions and their state machines continue unchanged
- **THEN** users who never subscribe to the new module are unaffected

### Requirement: Effective per-module entitlement is computed deterministically across sources
The app SHALL maintain a single **effective entitlement state** per module per user, computed from a documented set of sources: (a) a valid receipt for the module's own product, (b) a valid receipt for any bundle that includes the module (per `bundle-product-mapping`), and (c) the user's local lifecycle (free / trial / linked-not-active / grace / read-only).

When multiple sources are active, the most favorable source SHALL win; the documented evaluation order SHALL be deterministic so two valid sources cannot disagree on which one is in effect.

#### Scenario: Bundle receipt projects entitlement on a module not separately subscribed
- **WHEN** the user holds a valid bundle subscription that includes `housing` but no standalone `housing` subscription
- **THEN** the effective entitlement state for `housing` is at least `active-paid` (subject to the bundle's own validity)

#### Scenario: Standalone subscription overrides a less-favorable bundle state
- **WHEN** the user holds a standalone active-paid subscription for a module and is simultaneously in a delinquent state on a bundle that includes the module
- **THEN** the module's effective entitlement remains `active-paid` from the standalone source

### Requirement: Module entitlement state never blocks other modules
Delinquency, grace, or read-only state on one module SHALL NOT cause the app to enter delinquency, grace, or read-only for any other module.

#### Scenario: Read-only on one module does not block another
- **WHEN** a user is in read-only state for `vehicle` and in active-paid for `housing`
- **THEN** `housing` UI remains fully functional including new data entry
- **THEN** only `vehicle` data entry is gated by the read-only rule
