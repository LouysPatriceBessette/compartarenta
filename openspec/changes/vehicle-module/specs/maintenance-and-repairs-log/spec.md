## ADDED Requirements

### Requirement: Record maintenance events and expenses
The system SHALL allow the **vehicle owner** to record maintenance events including date, category, cost, optional notes, and optional attachment metadata.

#### Scenario: Owner records maintenance
- **WHEN** the owner saves a maintenance event for their vehicle
- **THEN** the system stores the event linked to that vehicle

### Requirement: Owner-only maintenance reminders and hub alert tiles
The system SHALL support configurable maintenance reminders (e.g., oil change every N km or N engine hours) and MUST deliver notifications **only to the Propriétaire's** device. **Alert tiles** on the Vehicle module hub preview upcoming thresholds per `vehicle-maintenance-alert-tiles`. Emprunteurs MUST NOT receive maintenance reminders.

#### Scenario: Emprunteur does not receive oil-change reminder
- **WHEN** a shared vehicle passes an oil-change distance threshold
- **THEN** the Propriétaire receives the reminder (and may have seen an alert tile beforehand)
- **THEN** the Emprunteur receives no maintenance reminder for that vehicle

### Requirement: Maintenance events may feed sharing allocations
Maintenance events MAY be included in expense allocations defined in `vehicle-expense-sharing` when the vehicle is shared. Canonical maintenance records live on the Propriétaire's vehicle; Emprunteurs MAY forward maintenance reports via `vehicle-quick-actions-ui`.

#### Scenario: Maintenance available for allocation window
- **WHEN** an owner computes a sharing allocation for a window that includes maintenance events
- **THEN** those events can be included per the active sharing ratios
