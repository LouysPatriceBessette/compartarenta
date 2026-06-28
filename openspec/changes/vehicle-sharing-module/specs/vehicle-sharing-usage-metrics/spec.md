## ADDED Requirements

### Requirement: Borrower sees usage statistics only for their windows
On a borrower's device, the system SHALL display distance and fuel-related statistics **only** for usage attributed to that borrower (per use session and selectable windows). The borrower MUST NOT see the vehicle's full lifetime owner metrics.

#### Scenario: Borrower metrics exclude others' uses
- **WHEN** borrower B opens statistics for a shared vehicle also used by D
- **THEN** B sees totals for B's sessions only
- **THEN** B does not see D's distance totals or the owner's full lifetime consumption chart

### Requirement: Reconciliation window for a borrower
For expense reconciliation, the system SHALL expose to the borrower the fuel, allocation, and usage facts necessary to settle costs **for their attributed usage windows** only.

#### Scenario: Borrower opens reconciliation for a month
- **WHEN** borrower B opens reconciliation for a calendar window
- **THEN** included uses and fuel facts are limited to B's attributed sessions intersecting that window
- **THEN** the breakdown is sufficient to compute B's share per active ratios

### Requirement: Owner sees aggregate reconciliation across sharers
The owner SHALL see reconciliation and usage ratio inputs across **all** sharers and owner uses for allocation windows.

#### Scenario: Owner allocation includes all participants
- **WHEN** the owner computes usage ratios for a window
- **THEN** distances include owner uses and all approved borrowers' uses in that window

### Requirement: Unknown-attributed gaps excluded from borrower owed inputs
Distance from gap records attributed to **Unknown** MUST NOT be included when computing an Emprunteur's attributed usage or owed share for reconciliation. The Propriétaire effectively carries Unknown usage in allocation math until they revise attribution to a named participant (see `vehicle-odometer-gap-attribution`).

#### Scenario: Borrower reconciliation ignores Unknown gaps
- **WHEN** borrower B opens reconciliation for a window containing an Unknown-attributed gap
- **THEN** that gap distance is excluded from B's attributed totals
- **THEN** the breakdown explains that Unknown gaps are Propriétaire-side until revised

### Requirement: Handle insufficient borrower data
The system MUST handle insufficient borrower-scoped data without showing misleading metrics.

#### Scenario: Borrower with no uses in window
- **WHEN** a borrower selects a window with zero attributed distance
- **THEN** usage ratio and fuel statistics are shown as unavailable with explanation
