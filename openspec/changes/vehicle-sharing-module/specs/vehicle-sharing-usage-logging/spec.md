## ADDED Requirements

### Requirement: Approved Emprunteurs and Propriétaires log vehicle uses
The system SHALL allow the **Propriétaire** or an **approved Emprunteur** to create a vehicle use session on a shared vehicle with meter readings before/after (odometer or horometer per `odometer-logging`), attributed to the acting Contact.

Distance for a session is derived only from **actual start/end readings**, not from estimates. **Gap attribution** when a session start exceeds the latest reading is defined in `vehicle-odometer-gap-attribution`.

#### Scenario: Emprunteur starts and completes a use
- **WHEN** an approved Emprunteur starts a use on a shared vehicle and saves before/after readings
- **THEN** the use is stored on the **Propriétaire's canonical vehicle record**
- **THEN** the use is attributed to the Emprunteur Contact

### Requirement: Emprunteur usage facts do not grant Propriétaire hub privileges
Emprunteur-entered uses MUST NOT allow editing Propriétaire-only settings, viewing alert tiles meant for the Propriétaire, or changing the vehicle owner. **Maintenance performed** from the sharing hub forwards a report to the Propriétaire rather than opening the Propriétaire maintenance editor on the Emprunteur device.

#### Scenario: Emprunteur cannot configure maintenance rules
- **WHEN** an Emprunteur views a shared vehicle
- **THEN** maintenance **reminder configuration** and alert tiles are not available
- **THEN** the Emprunteur MAY still submit a **Maintenance performed** quick action that forwards to the Propriétaire

### Requirement: Emprunteurs do not log session-scoped fuel purchases
The system MUST NOT provide a flow for Emprunteurs to log fuel purchases tied to a usage session. Fuel reconciliation uses **full-tank anchor purchases** and meter-derived distance, not per-session liter estimates.

#### Scenario: No borrower fuel entry on use completion
- **WHEN** an Emprunteur completes a vehicle use
- **THEN** the completion flow does not prompt for liters consumed on that session
- **THEN** fuel allocation relies on anchors and shared ratios per `vehicle-expense-sharing`

### Requirement: Shared vehicles use gap attribution for unlogged meter increases
On a shared vehicle, when a session **start** reading exceeds the latest stored reading, gap attribution per `vehicle-odometer-gap-attribution` SHALL offer the Propriétaire and active Emprunteurs as attribution targets. Attributed participants MUST receive **informational** notifications when another participant assigns them the gap. **Unknown** attributions MUST notify the Propriétaire (unless self). **Negative** gaps MUST notify the Propriétaire for photo verification (unless self). Only the **Propriétaire** MAY revise a stored gap attribution; the app MUST NOT implement an in-app contestation workflow.

#### Scenario: Gap between Emprunteur sessions
- **WHEN** Emprunteur B ends a session at 12 400 km
- **AND** Emprunteur C later starts a session at 12 650 km without B having logged an intervening reading
- **THEN** C is prompted to attribute the 250 km gap
- **WHEN** C attributes it to B
- **THEN** B is notified on their device(s)
