## MODIFIED Requirements

### Requirement: Housing import may remain separately guarded by entitlement

**Removed.** Housing import (and all full-device import) is gated by **active store subscription** per `device-data-import-restore`, not entitlement-server state. Export remains always available in read-only mode.

#### Scenario: Export allowed while import is store-gated

- **WHEN** the plan is in read-only mode and the device has no active paid housing-capable store subscription
- **THEN** export remains available
- **THEN** import is disabled because the store reports no active paid subscription
