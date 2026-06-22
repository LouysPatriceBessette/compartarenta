## Why

Device replacement is the primary recovery path for a local-first app (`data-locality-and-client-storage`). Import gating was incorrectly tied to entitlement-server state, which is stale on a new installation. Product decision (2026-06-22): import is gated only by an **active store subscription** on the device; after a successful local restore, a dedicated relay envelope migrates the old `participant_installation_id` everywhere entitlement links data.

## What Changes

- **Full-device export/import** of all local operational data (all modules), versioned JSON with checksum — not agreement-scoped only.
- **Import gate**: active paid subscription on device (Google Play on Android, StoreKit on iOS). Trial, grace, expired, and unpaid states **disable** import. Entitlement server does **not** gate import.
- **Export** remains always available (including read-only / no active subscription).
- **Settings** hosts export/import (not the housing hub).
- **Non-empty DB**: warn, user confirms, then **wipe** and import (device-replacement primary use case).
- **Post-import**: relay envelope kind `participantInstallationMigration` (numeric **15**) replaces `old_participant_installation_id` with `new_participant_installation_id` on entitlement server, with `plan_id` (or module-scoped plan id) match check. Success or fail — no partial state.
- **Canonical colocataire backup**: extra UI to choose which roster identity to restore as **self**.
- **Dev**: fake billing stub until Play / StoreKit integration ships.

## Capabilities

### New Capabilities

- `device-data-import-restore`: Full-device backup, import gate, wipe-on-replace, installation-id migration envelope and entitlement API.

### Modified Capabilities

- `housing-agreement-data-portability`: Superseded for export/import entry and import gate; agreement-scoped export details folded into device bundle where still relevant.
- `delinquency-grace-readonly-and-export`: Import guard reference updated.
- `entitlement-service-api`: Installation-id migration endpoint / handler contract.
- `relay-entitlement-gating`: New envelope kind for migration (not gated by old id).
- `per-participant-licenses-and-plan-renewal`: Import no longer entitlement-server gated.

## Impact

- **Mobile**: Settings screen, full DB export service, import wipe flow, billing query, migration envelope sender, dev billing fake.
- **Entitlement server**: Migration API — replace old installation id with new across all linked records.
- **Relay**: Forward migration envelope to entitlement (small, auditable delta).
- **Web (dev)**: Import disabled or stub-only; not a production surface.
