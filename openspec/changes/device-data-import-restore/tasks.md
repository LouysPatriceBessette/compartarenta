# Tasks — device data import and restore

## 1. Spec and protocol

- [x] 1.1 Apply deltas to superseded specs (`housing-agreement-data-portability`, `delinquency-grace-readonly-and-export`, licensing tasks, entitlement API).
- [x] 1.2 Document envelope kind 15 `participantInstallationMigration` in client protocol docs.
- [x] 1.3 Document entitlement migration API (relay → entitlement).

## 2. Export

- [x] 2.1 Implement full-device export service (all modules, versioned JSON, checksum, migration metadata).
- [x] 2.2 Move export entry to Settings; remove hub export/import tile when Settings path ships.

## 3. Import gate (store)

- [ ] 3.1 Android: query active purchases for housing standalone or housing-including bundle.
- [ ] 3.2 iOS: StoreKit-equivalent query (implementation without deferred test hardware).
- [x] 3.3 Dev billing fake for debug builds until store integration lands.

## 4. Import apply

- [x] 4.1 File picker, format/checksum validation, required field checks (`participant_installation_id`, plan ids).
- [x] 4.2 Non-empty DB warning + confirm + wipe + transactional import.
- [x] 4.3 Canonical backup: self vs other participant selection UI (dialog; identity remap deferred until canonical export ships).

## 5. Entitlement migration

- [x] 5.1 Client: send kind-15 envelope after successful local import only.
- [x] 5.2 Entitlement server: replace old installation id with new across all linked records; plan_id verification.
- [x] 5.3 Relay: forward migration to entitlement (minimal handler).
- [x] 5.4 Client: migration uses `RelayHttpPolicy` (3 transport retries); network message + **Retry migration** in Settings when exhausted; no re-import required.

## 6. Tests

- [x] 6.1 Unit: import gate from mocked store responses (active / trial / grace / expired).
- [x] 6.2 Unit: wipe-on-confirm, no migration on import failure.
- [x] 6.3 Integration: migration payload validation (plan_id mismatch, old id missing).
- [ ] 6.4 Android integration: export → wipe → import → migration (when billing fake available).

## Dependencies

- `client-db-exportability` format conventions.
- `per-module-licensing-and-bundles` product identifiers for housing gate.
- `entitlement-server` migration endpoint.
- Bootstrap registration of new `participant_installation_id` (existing).
