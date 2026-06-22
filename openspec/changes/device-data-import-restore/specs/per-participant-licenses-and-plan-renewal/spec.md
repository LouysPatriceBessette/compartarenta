## MODIFIED Requirements

### Requirement: Module-specific entitlements remain compartmentalized

Licensing and entitlement decisions SHALL remain scoped to the relevant module. A valid housing entitlement does not automatically imply entitlement for future unrelated modules, and vice versa.

Data **import** is gated by **store subscription** per `device-data-import-restore`, not by entitlement-server module authorization.

#### Scenario: Housing entitlement does not imply other module access

- **WHEN** a participant has a valid housing entitlement for relay gating
- **THEN** the system does not automatically grant access to gated synchronization in another module unless that module's entitlement policy also allows it

#### Scenario: Import gate is store-scoped to housing product

- **WHEN** a participant has no active paid housing-capable store subscription
- **THEN** full-device import is disabled regardless of entitlement-server state
