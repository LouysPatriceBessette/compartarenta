## ADDED Requirements

### Requirement: Export is scoped to one housing agreement

Export from the hub SHALL produce a bundle for **one** housing `packageId` (one entente), including:

- Active and historical **plan revisions** accepted during that entente (amendment chain),
- The active contract terms per revision,
- **Published** realized expenses and their unanimous acceptance metadata,
- Pending proposals this device still holds,
- Proof attachment **paths and display file names** (not file bytes).

Export MUST NOT include other housing packages, contacts, or car-sharing data.

#### Scenario: User with two agreements picks one

- **WHEN** the user exports from agreement A’s hub
- **THEN** the JSON contains no rows keyed to agreement B’s `packageId`

---

### Requirement: Export format is versioned JSON with checksum

The bundle SHALL be JSON with an explicit **`formatVersion`** field. The file SHALL include a **`checksum`** (algorithm documented in implementation, e.g. SHA-256 over canonical UTF-8 bytes of the payload object excluding the checksum field) so import can detect accidental corruption or deliberate tampering.

The export is **not encrypted**; UI SHALL warn users to store the file securely (localized).

#### Scenario: Tampered checksum fails import

- **WHEN** a user edits a numeric field in the JSON file and attempts import
- **THEN** import is rejected with a clear checksum failure message

#### Scenario: Version mismatch

- **WHEN** `formatVersion` is newer than this app supports
- **THEN** import is rejected with upgrade guidance

---

### Requirement: Default export is device-specific backup

The default export mode reflects **this device’s** view of the agreement: local proof paths, local acceptance timestamps, and pending items not yet accepted elsewhere. Two participants’ export files **SHALL NOT** be assumed byte-identical.

#### Scenario: Two exports differ in pending queue

- **WHEN** participant A has not yet accepted expense E and participant B has
- **THEN** their export files differ in pending vs published sections

---

### Requirement: Optional canonical export for cross-participant recovery

The product MAY support a second export mode **Canonical agreement snapshot** that serializes only **group-published** facts in **deterministic order** (stable sort keys, no local file paths — attachment references use content hash or original file name only). When present, this mode is intended so another participant can import a **shared** recovery file after device loss.

Rules for canonical mode:

- Same checksum rules apply.
- Import MUST verify `packageId` and active revision id match expectations.
- Import MUST NOT merge ambiguous conflicting published expenses; reject on hash or id collision.

#### Scenario: Canonical import on replacement phone

- **WHEN** a user imports a canonical snapshot exported by a colocataire
- **THEN** the device reconstructs published ledger and plan revision chain if checksum and ids validate

---

### Requirement: Import validates integrity before write

Import SHALL:

1. Parse JSON and verify `formatVersion` support,
2. Recompute and compare `checksum`,
3. Refuse import if mandatory entity references are inconsistent,
4. Apply rows in a single transaction where possible, with rollback on failure.

The UI SHALL state that **manual editing** of export files is unsupported and likely to fail checksum validation.

#### Scenario: Hand-edited participant id rejected

- **WHEN** checksum fails after manual JSON edit
- **THEN** no partial database write occurs

---

### Requirement: Proof paths on import are best-effort

Imported proof paths MAY not exist on the importing device. The UI SHALL display file names per `housing-realized-expense-entry` missing-file rules. Import MUST NOT fail solely because image files are absent.

#### Scenario: Import without image files

- **WHEN** JSON references `/old/device/path/receipt.jpg` which does not exist
- **THEN** import succeeds and expense shows file name with unavailable state

---

### Requirement: Hub exposes export and import

The hub action **Export / import data** SHALL open a screen with export (pick agreement if needed, choose mode when canonical exists) and import (file picker). Successful import SHALL route to the hub for that `packageId`.

#### Scenario: Import restores hub access

- **WHEN** import completes for package P
- **THEN** the user can open P’s active agreement hub

---

### Requirement: Extends client-db-exportability for housing

Housing agreement bundles SHALL satisfy the spirit of `client-db-exportability` (human-readable JSON, stable ids, versioned format) with the additional constraints in this spec (scope, checksum, agreement chain).

#### Scenario: Export includes format version field

- **WHEN** any housing agreement export is produced
- **THEN** `formatVersion` is present at the root object
