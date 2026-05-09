## ADDED Requirements

### Requirement: Operational data export is supported and human-comprehensible
The system MUST support exporting operational data into a human-comprehensible format. The export format SHOULD be understandable without requiring the reader to understand the internal database engine.

#### Scenario: User exports their data for review
- **WHEN** a user triggers an export
- **THEN** the exported files are readable and structured for human comprehension (e.g., JSON with stable IDs and clear entity names)

### Requirement: Export transformation is minimal and deterministic
If the internal storage model is relational, the system SHALL export using minimal and deterministic transformation rules (e.g., stable IDs, references, optional denormalized views) so that exports remain consistent across versions.

#### Scenario: Same data exports consistently across runs
- **WHEN** a user exports the same dataset twice without changes
- **THEN** the two exports are structurally equivalent aside from metadata such as timestamps

### Requirement: Export format is versioned
The system MUST version the export format so that future schema changes can preserve backward compatibility or provide a clear migration path for exported data.

#### Scenario: Export includes format version
- **WHEN** the app produces an export bundle
- **THEN** the bundle includes an explicit export format version identifier

