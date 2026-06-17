## MODIFIED Requirements

### Requirement: Notification Categories

The system SHALL model notification categories for peer-triggered Contacts and Housing events.

#### Scenario: Contacts categories are available

- **WHEN** the user opens notification settings
- **THEN** the system shows controls for Contacts add requests, disconnection notices, and unconsumed invitation expiration

#### Scenario: Housing categories are available

- **WHEN** the user opens notification settings
- **THEN** the system shows controls for received housing plan submissions, participant decision status changes, non-unanimous plan offer expiration, and **fixed-expense payment reminders** (before-date and overdue)

#### Scenario: Payment reminder category is independent

- **WHEN** the user disables fixed-expense payment reminders
- **THEN** other Housing categories continue to operate according to their own switches
