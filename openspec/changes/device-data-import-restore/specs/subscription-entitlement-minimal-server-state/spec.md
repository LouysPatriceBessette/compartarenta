## MODIFIED Requirements

### Requirement: Minimal server state may include accepted-roster and decision metadata

The minimal entitlement server state MAY include, for a gated module such as housing:

- accepted plan roster membership keyed by plan,
- participant installation identities,
- trial-consumed markers and timestamps,
- realized-expense acceptance / rejection decisions sufficient to derive unanimous acceptance.

Server state SHALL NOT gate **local data import** on the device. Import authorization is determined on-device from store subscription state per `device-data-import-restore`. The server participates **after** import via installation-id migration.

#### Scenario: Unanimity can be derived without storing business payloads

- **WHEN** the server evaluates whether a housing expense reached unanimous acceptance
- **THEN** it can do so from accepted-roster metadata and per-participant decision metadata without retaining the expense's business payload
