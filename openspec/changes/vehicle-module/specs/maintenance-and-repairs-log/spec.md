## ADDED Requirements

### Requirement: Record maintenance events and expenses
The system SHALL allow the **vehicle owner** to record maintenance events including date, category, cost, optional notes, and optional attachment metadata.

#### Scenario: Owner records maintenance
- **WHEN** the owner saves a maintenance event for their vehicle
- **THEN** the system stores the event linked to that vehicle

### Requirement: Owner-only maintenance reminders
The system SHALL support configurable maintenance reminders (e.g., oil change every N km or every N months) and MUST deliver them **only to the vehicle owner's** device. Borrowers MUST NOT receive maintenance reminders for vehicles they borrow.

#### Scenario: Borrower does not receive oil-change reminder
- **WHEN** a borrowed vehicle passes an oil-change distance threshold
- **THEN** the owner receives the reminder
- **THEN** the borrower receives no maintenance reminder for that vehicle

### Requirement: Maintenance events may feed sharing allocations
Maintenance events MAY be included in expense allocations defined in `vehicle-expense-sharing` when the vehicle is shared. Recording maintenance remains owner-only.

#### Scenario: Maintenance available for allocation window
- **WHEN** an owner computes a sharing allocation for a window that includes maintenance events
- **THEN** those events can be included per the active sharing ratios
