## ADDED Requirements

### Requirement: Full-device export includes all operational local data

The application SHALL support exporting **all** local operational data for the current installation into a single versioned JSON bundle with checksum. The bundle SHALL include every module's persisted operational tables (housing, contacts, and any other shipped modules), installation identity metadata, and any fields required for device-replacement recovery.

Export MUST NOT require an active store subscription, an active plan, or entitlement-server authorization.

#### Scenario: Export with no active subscription

- **WHEN** the user has no active paid store subscription
- **THEN** export remains available from Settings
- **THEN** the produced file contains the full operational dataset for this device

#### Scenario: Export includes migration metadata

- **WHEN** any export is produced for device replacement
- **THEN** the bundle includes the exporting installation's `participant_installation_id` and module plan identifiers (e.g. housing `plan_id`) needed for post-import entitlement migration

---

### Requirement: Import is gated only by active store subscription for housing

Import of a backup file SHALL be permitted **only** when the device reports an **active paid** store subscription that grants **housing** entitlement — either the standalone housing product or a bundle product that includes housing per `store-product-mapping-per-module` and `bundle-product-mapping`.

The following SHALL **not** influence the import button or import attempt:

- Entitlement-server housing authorization state,
- Local trial / grace / read-only plan state,
- Presence or absence of a local active plan,
- Roster membership on the entitlement server.

Trial, grace-period unpaid, and expired unpaid subscriptions SHALL disable import.

On **Android**, the gate SHALL use Google Play Billing (e.g. `queryPurchasesAsync()` or successor API) for the device's Google account.

On **iOS**, the gate SHALL use the StoreKit-equivalent active-subscription query for the device's Apple ID.

On **web (development only)**, import is out of production scope; dev builds MAY use a documented stub.

Until store integration ships, release builds SHALL keep import disabled; debug builds MAY use a documented billing fake.

#### Scenario: Active housing subscription enables import

- **WHEN** the store reports an active paid housing-capable subscription on this device
- **THEN** the Import control in Settings is enabled

#### Scenario: Free trial disables import

- **WHEN** the user is in a housing free trial without an active paid store subscription
- **THEN** Import is disabled

#### Scenario: Grace period disables import

- **WHEN** the plan is in delinquency grace and the store subscription is not active
- **THEN** Import is disabled

#### Scenario: Entitlement deny does not disable import

- **WHEN** entitlement introspection would deny relay sync for this installation
- **THEN** Import may still be enabled if the store reports an active paid housing-capable subscription

---

### Requirement: Export and import live in Settings

The product SHALL expose **Settings → Export / import data** as the sole primary entry for full-device export and import. The housing active-agreement hub SHALL NOT host import/export after this change ships.

#### Scenario: Post-reinstall access without active plan

- **WHEN** the user reinstalls the app and has no local active housing plan yet
- **THEN** they can still open Settings and reach export/import

---

### Requirement: Non-empty database requires replace confirmation and wipe

Import on a device that already holds operational data SHALL:

1. Detect non-empty local operational storage,
2. Warn that import **replaces all existing local data** and is intended primarily for device replacement,
3. Require explicit user confirmation to proceed,
4. Wipe local operational data,
5. Import the backup in a single transactional apply.

Import MUST NOT merge into a non-empty database.

#### Scenario: Replacement phone with empty DB

- **WHEN** the local database is empty and import validates
- **THEN** import proceeds without a replace warning

#### Scenario: Import on device with existing data

- **WHEN** the local database contains any operational data and the user confirms replace
- **THEN** all prior local operational data is removed before imported rows are written

---

### Requirement: Local import must fully succeed before entitlement migration

The client SHALL complete local file validation, optional wipe, and full database import before sending any installation-id migration request to the entitlement server via relay.

If local import fails, the client MUST NOT call entitlement migration.

There is no partial-import success state; partial application SHALL be treated as failure with rollback where the storage layer allows.

#### Scenario: Checksum failure

- **WHEN** checksum validation fails
- **THEN** no database write occurs and no migration envelope is sent

#### Scenario: Import transaction failure

- **WHEN** import fails mid-transaction
- **THEN** no migration envelope is sent

---

### Requirement: Installation identity migration via dedicated relay envelope

After successful local import, the client SHALL send a relay envelope of kind **`participantInstallationMigration` (numeric 15)** so the entitlement server replaces `old_participant_installation_id` with `new_participant_installation_id` everywhere server-side data links to the old identity.

The envelope payload SHALL include at minimum:

- `old_participant_installation_id` (from imported backup),
- `new_participant_installation_id` (current installation),
- `plan_id` for housing (or the module-appropriate plan identifier) — entitlement MUST verify it matches the plan associated with the old installation before migrating.

The migration SHALL succeed or fail as a whole. Example failure: old installation id not found on entitlement server.

#### Scenario: Successful migration restores relay gating

- **WHEN** local import succeeds and migration returns success
- **THEN** subsequent gated relay operations for the imported plan introspect allow for the new installation id

#### Scenario: Old id absent on server

- **WHEN** entitlement receives migration for an unknown old installation id
- **THEN** migration fails with a documented error code

#### Scenario: Plan id mismatch rejected

- **WHEN** the supplied plan id does not match entitlement's record for the old installation id
- **THEN** migration fails and no id replacement occurs

---

### Requirement: Migration transport failures retry then surface network guidance

When local import has **fully succeeded** and the client sends the installation migration envelope, **transport-level** relay failures (timeout, no HTTP response, connection errors) SHALL be retried using the same policy as other relay HTTP calls: **3 retries** after the initial attempt (`RelayHttpPolicy.maxRetries`), each with the standard per-attempt timeout.

If all transport attempts fail, the application SHALL:

1. Inform the user of a **network / relay connectivity** problem (localized, non-technical),
2. State that local data was restored but **server identity migration is still pending**,
3. Offer a **retry migration** action later (without requiring a new file import).

The user MAY verify their internet connection and retry when ready.

Transport retries SHALL NOT apply to documented **business** migration failures (e.g. unknown `old_participant_installation_id`, `plan_id` mismatch).

#### Scenario: Relay unreachable immediately after local import

- **WHEN** local wipe and import succeed but the relay returns no HTTP response on migration
- **THEN** the client retries up to 3 times per `RelayHttpPolicy`
- **THEN** if still unreachable, the user sees network guidance and may retry migration later from Settings

#### Scenario: Migration succeeds on a later manual retry

- **WHEN** a prior migration attempt failed only due to transport and the user retries migration after connectivity is restored
- **THEN** entitlement replaces the old installation id with the new one
- **THEN** gated relay operations work with the new installation id

#### Scenario: Old id not found is not a network retry

- **WHEN** entitlement returns a documented failure because the old installation id does not exist
- **THEN** the client does not treat it as a transport retry case
- **THEN** the user sees the specific migration failure, not a generic network message


When importing a **canonical** backup file (cross-participant snapshot, not the user's own device-specific export), the UI SHALL:

1. Default to restoring data for **self**, displaying the user's name for clarity,
2. Allow choosing another roster participant from the backup to restore as self,
3. Proceed with wipe/import only after identity choice is confirmed.

#### Scenario: Default self restore

- **WHEN** the user imports a canonical file and accepts the default
- **THEN** imported participant rows map to the current device's self identity per the chosen roster member

---

### Requirement: Export remains available in read-only and delinquent states

Export SHALL remain available regardless of plan read-only mode, delinquency grace, trial state, or store subscription state. This requirement aligns with `delinquency-grace-readonly-and-export` and supersedes any housing-only export guard tied to entitlement import rules.

#### Scenario: Read-only plan export

- **WHEN** the housing plan is in read-only mode
- **THEN** full-device export from Settings remains available

---

### Requirement: Extends client-db-exportability

Full-device bundles SHALL satisfy `client-db-exportability` (human-readable JSON, stable ids, explicit format version, deterministic export rules) with the additional constraints in this capability (full scope, checksum, migration metadata, wipe-on-replace import).

#### Scenario: Format version present

- **WHEN** any full-device export is produced
- **THEN** `formatVersion` is present at the root object
