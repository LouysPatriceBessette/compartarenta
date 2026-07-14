## ADDED Requirements

### Requirement: Sale export contains factual vehicle history only
The system SHALL provide a **sale/transfer export** that produces a zip artifact containing a human-comprehensible JSON snapshot and selected media with **factual vehicle history**:
- meter readings (full journal with dates; last odometer photo only)
- fuel purchases (including full-tank anchors; no fuel meter photos)
- maintenance events (full journal; all maintenance attachments)
- consumption estimate history (complete)
- newest vehicle photo gallery (carousel) only
- vehicle kind and label metadata (make, model, color, etc.)

The export MUST NOT include traffic violations. The export MUST identify the module as `vehicle` per `module-enable-disable-and-data-isolation`.

#### Scenario: Propriétaire exports before sale
- **WHEN** the Propriétaire initiates a sale export for a vehicle
- **THEN** the system produces a transfer bundle with complete factual history
- **THEN** the export does not claim to transfer ownership inside the app

### Requirement: Sale export strips sharing and attribution metadata
The sale export MUST NOT include:
- active or historical **sharing links** (Propriétaire ↔ Emprunteur relationships),
- **who entered** each fact (Propriétaire vs Emprunteur attribution),
- **usage ratios** or other sharing-derived allocation metrics,
- counts or identities of participants who shared the vehicle.

Only anonymous factual records remain, suitable for a new Propriétaire's clean ledger.

#### Scenario: Export excludes sharing relationships and attribution
- **WHEN** a Propriétaire exports a vehicle that had active Emprunteurs and computed usage ratios
- **THEN** the export contains fuel, meter, maintenance, and consumption-estimate facts
- **THEN** the export omits violations, borrower links, enterer identity, and usage-ratio outputs

### Requirement: Import creates a new owned vehicle on the buyer's device
The system SHALL support importing a sale zip export by creating a **new** vehicle record owned by the importing user (same license rules as manual vehicle add). Import MUST NOT attach the data to another Propriétaire's existing vehicle id. After a successful import the app SHALL navigate to the vehicle list without a success dialog; import failures SHALL show an error dialog.

#### Scenario: Buyer imports purchased vehicle data
- **WHEN** a user imports a valid sale zip from the add-vehicle form
- **THEN** the system creates a new vehicle owned by the importing user
- **THEN** factual records from the export are available on that new vehicle without prior sharing metadata
- **THEN** media extracted from the zip are stored under `Documents/Compartarenta` using the local vehicle path layout
- **THEN** the vehicle remains eligible for undo-import until a confirming action occurs

### Requirement: Undo import while only rename and consult have occurred
After a sale import, the system SHALL offer **Undo import** while the vehicle remains undo-eligible. Undo eligibility ends when the user records any post-import activity other than renaming the vehicle or consulting data. Imported historical facts (including prior fuel purchases in the export) do not by themselves end eligibility.

Post-import activity that ends eligibility includes, without limitation:
- starting a use session (as soon as the session is recorded as started),
- recording a new fuel purchase,
- recording maintenance, meter readings (outside the rename/consult path), violations, gallery changes, deactivation, or any other new journal fact.

While undo-eligible, renaming the display label and consulting existing data MUST NOT remove the Undo import affordance.

#### Scenario: Undo import remains after rename only
- **WHEN** a user has imported a vehicle and only renames it and/or consults its data
- **THEN** Undo import remains available

#### Scenario: Undo import ends when a use session starts
- **WHEN** a user starts a use session on an imported undo-eligible vehicle
- **THEN** after they confirm the import-confirm dialog, Undo import is no longer available

### Requirement: Confirming action warns that import can no longer be undone
Before completing any user-submitted action that would end undo eligibility, the system SHALL show a dialog:

- Body: that the action confirms the import and the user will no longer be able to undo the import
- Actions: Cancel and Confirm

- **WHEN** the user cancels — **THEN** the submitted action is not applied and Undo import remains available
- **WHEN** the user confirms — **THEN** the action proceeds and Undo import is no longer available

### Requirement: Undo import reverts database and imported media
Undo import SHALL completely revert the import for that vehicle: remove the vehicle and its imported/local rows for that vehicle from the database, and delete media files that were placed under `Documents/Compartarenta` for that vehicle from the sale zip. The affordance SHALL be placed under the Import control on the Add-vehicle screen and SHALL disappear when the vehicle is no longer undo-eligible.

#### Scenario: Buyer undoes a curiosity import
- **WHEN** the user chooses Undo import for an undo-eligible imported vehicle
- **THEN** that vehicle is gone from the owned list and its imported media files are deleted

### Requirement: Routine export may include sharing metadata; sale export mode does not
The app MAY offer a separate **full Propriétaire export** (not for sale) that includes sharing links and attribution for the Propriétaire's own records. The **sale export mode** defined here is the strict factual subset.

#### Scenario: Two export modes
- **WHEN** the Propriétaire chooses sale/transfer export
- **THEN** attribution and sharing metadata are stripped
- **WHEN** the Propriétaire chooses a full backup export for their own archives
- **THEN** the product MAY include sharing metadata if documented in export manifest
