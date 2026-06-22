## MODIFIED Requirements

### Requirement: Housing import requires valid housing entitlement

**Superseded** by `device-data-import-restore`: import is gated by **active store subscription** (housing standalone or housing-including bundle), not entitlement-server housing authorization. Export remains always available.

The housing hub is **not** the primary export/import entry; Settings hosts full-device export/import per `device-data-import-restore`.

Agreement-scoped export details below remain informative for housing **content** inside a full-device bundle until the full-device exporter subsumes them entirely.

---

### Requirement: Hub exposes export and import

**Replaced:** Export and import for device recovery SHALL be exposed from **Settings**, not the housing active-agreement hub. See `device-data-import-restore`.

#### Scenario: Settings path after migration

- **WHEN** the user needs to export or import data
- **THEN** they use Settings → Export / import data

---

### Requirement: Export is scoped to one housing agreement

**Note:** Full-device export (`device-data-import-restore`) is the canonical backup path. Per-agreement export from the hub MAY be retired when full-device export ships. Until then, this requirement describes housing **payload content** included in backups.

Export from the hub (if still present during transition) SHALL produce a bundle for **one** housing `packageId` (one entente), including:

- Active and historical **plan revisions** accepted during that entente (amendment chain),
- The active contract terms per revision,
- **Published** realized expenses and their unanimous acceptance metadata,
- Pending proposals this device still holds,
- Proof attachment **paths and display file names** (not file bytes).

Export MUST NOT include other housing packages, contacts, or car-sharing data when using agreement-only export mode.

#### Scenario: User with two agreements picks one

- **WHEN** the user exports from agreement A’s hub
- **THEN** the JSON contains no rows keyed to agreement B’s `packageId`

---

### Requirement: Optional canonical export for cross-participant recovery

The product MAY support a second export mode **Canonical agreement snapshot** that serializes only **group-published** facts in **deterministic order** (stable sort keys, no local file paths — attachment references use content hash or original file name only). When present, this mode is intended so another participant can import a **shared** recovery file after device loss.

Rules for canonical mode:

- Same checksum rules apply.
- Import MUST verify `packageId` and active revision id match expectations.
- Import MUST NOT merge ambiguous conflicting published expenses; reject on hash or id collision.
- Canonical import SHALL follow self-identity selection rules in `device-data-import-restore`.

#### Scenario: Canonical import on replacement phone

- **WHEN** a user with an active paid housing-capable store subscription imports a canonical snapshot exported by a colocataire
- **THEN** the device reconstructs published ledger and plan revision chain if checksum and ids validate
- **THEN** the user selects which roster identity to restore as self when required
