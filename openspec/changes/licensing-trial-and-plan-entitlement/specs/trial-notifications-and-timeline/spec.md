## ADDED Requirements

### Requirement: Active plan use starts a 6-week trial
Once a plan enters active use (per `free-until-active-plan-use`), the application SHALL start a 6-week trial period for that plan.

#### Scenario: Trial start timestamp is stable
- **WHEN** the first realized expense sync triggers active use
- **THEN** the app records a plan trial start timestamp and does not reset it due to subsequent plan edits or additional expense sync events

### Requirement: Trial reminders are delivered on a fixed schedule
During the trial, the application SHALL notify participants that they must purchase individual licenses to continue full operation. Notifications SHALL occur:

- at 2 weeks remaining,
- at 1 week remaining,
- daily for the last 4 days of the trial.

#### Scenario: Two-week reminder
- **WHEN** the trial has 14 days remaining
- **THEN** the app notifies relevant participants about the upcoming end of the trial and how to purchase licenses

#### Scenario: Daily reminders for final 4 days
- **WHEN** the trial has 4 days remaining (inclusive) through day 1 remaining
- **THEN** the app notifies participants daily until trial end

### Requirement: Payment messaging is reassuring and not intrusive
Any trial and licensing messaging MUST be clear and reassuring, and MUST avoid aggressive or game-like purchase prompts. The app SHOULD centralize purchase actions in a single licensing screen (or “Data & Licensing management” area) rather than scattering purchase prompts across unrelated workflows.

#### Scenario: Notification links to a single licensing screen
- **WHEN** a user taps a trial reminder notification
- **THEN** the app navigates to the licensing screen that explains the trial status and next steps
- **THEN** the app does not present unrelated paywalls or pop-ups during normal feature use

### Requirement: Trial end gates plan operation unless all required licenses are paid
At the end of the 6-week trial, full plan operation SHALL require that all participants linked to that plan have valid paid licenses (per `per-participant-licenses-and-plan-renewal`).

#### Scenario: Trial ends with unpaid required licenses
- **WHEN** the trial period ends and at least one required participant license is unpaid
- **THEN** the plan transitions into the delinquency flow (grace then read-only) per `delinquency-grace-readonly-and-export`

