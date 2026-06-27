## ADDED Requirements

### Requirement: Approved Emprunteurs and Propriétaires log vehicle uses
The system SHALL allow the **Propriétaire** or an **approved Emprunteur** to create a vehicle use session on a shared vehicle with meter readings before/after (odometer or horometer per `odometer-logging`), attributed to the acting Contact.

Distance for a session is derived only from **actual before/after readings**, not from estimates entered before the trip ends.

#### Scenario: Emprunteur starts and completes a use
- **WHEN** an approved Emprunteur starts a use on a shared vehicle and saves before/after readings
- **THEN** the use is stored on the **Propriétaire's canonical vehicle record**
- **THEN** the use is attributed to the Emprunteur Contact

### Requirement: Emprunteur usage facts do not grant Propriétaire privileges
Emprunteur-entered uses MUST NOT allow the Emprunteur to edit Propriétaire-only records (maintenance, violations, vehicle settings) or to change the vehicle owner.

#### Scenario: Emprunteur cannot add maintenance
- **WHEN** an Emprunteur views a shared vehicle
- **THEN** maintenance entry is not available to the Emprunteur

### Requirement: Emprunteurs do not log session-scoped fuel purchases
The system MUST NOT provide a flow for Emprunteurs to log fuel purchases tied to a usage session. Fuel reconciliation uses **full-tank anchor purchases** and meter-derived distance, not per-session liter estimates.

#### Scenario: No borrower fuel entry on use completion
- **WHEN** an Emprunteur completes a vehicle use
- **THEN** the completion flow does not prompt for liters consumed on that session
- **THEN** fuel allocation relies on anchors and shared ratios per `vehicle-expense-sharing`
