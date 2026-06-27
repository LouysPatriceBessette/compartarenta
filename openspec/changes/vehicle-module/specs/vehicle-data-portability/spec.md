## ADDED Requirements

### Requirement: Sale export contains factual vehicle history only
The system SHALL provide a **sale/transfer export** that produces a human-comprehensible artifact with **all factual vehicle history**:
- meter readings and derived distances per use (km or engine hours)
- fuel purchases (including full-tank anchors)
- maintenance events
- violations (factual fields only)
- vehicle kind and label metadata

The export MUST identify the module as `vehicle` per `module-enable-disable-and-data-isolation`.

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
- **THEN** the export contains fuel, meter, maintenance, and violation facts
- **THEN** the export omits borrower links, enterer identity, and usage-ratio outputs

### Requirement: Import creates a new owned vehicle on the buyer's device
The system SHALL support importing a sale export on a device with effective `vehicle` entitlement by creating a **new** vehicle record owned by the importing user. Import MUST NOT attach the data to another Propriétaire's existing vehicle id.

#### Scenario: Buyer imports purchased vehicle data
- **WHEN** a user with `vehicle` entitlement imports a valid sale export
- **THEN** the system creates a new vehicle owned by the importing user
- **THEN** factual records from the export are available on that new vehicle without prior sharing metadata

### Requirement: Routine export may include sharing metadata; sale export mode does not
The app MAY offer a separate **full Propriétaire export** (not for sale) that includes sharing links and attribution for the Propriétaire's own records. The **sale export mode** defined here is the strict factual subset.

#### Scenario: Two export modes
- **WHEN** the Propriétaire chooses sale/transfer export
- **THEN** attribution and sharing metadata are stripped
- **WHEN** the Propriétaire chooses a full backup export for their own archives
- **THEN** the product MAY include sharing metadata if documented in export manifest
