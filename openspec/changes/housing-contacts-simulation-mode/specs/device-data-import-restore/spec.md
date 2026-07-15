## ADDED Requirements

### Requirement: User-initiated export and import are blocked in sandbox

When `sandboxMode` is true, Settings (and any other user-facing surface) SHALL NOT allow initiating a device data export or import for portability. Feedback SHALL explain that portability is unavailable in simulation. Internal checkpoint export/copy performed by the sandbox enter/exit lifecycle is NOT a user-initiated export/import and remains allowed for those services only.

#### Scenario: Settings export refused in sandbox
- **WHEN** sandbox mode is active and the user opens device export/import settings
- **THEN** export and import are unavailable or refused
- **THEN** no user-facing portability file is written from that UI

### Requirement: Real-mode export and import unchanged outside sandbox

When `sandboxMode` is false, full-device export availability and subscription-gated import rules SHALL remain as specified in the existing device-data-import-restore capability.

#### Scenario: Real mode export still available
- **WHEN** sandbox mode is false
- **THEN** export remains available from Settings per existing requirements
