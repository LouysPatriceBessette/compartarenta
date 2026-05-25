## ADDED Requirements

### Requirement: Non-payment triggers a 1-week grace period for the plan
If a required participant license becomes unpaid for a plan that requires full licensing coverage (e.g., post-trial paid operation), the plan SHALL enter a 1-week grace period.

During grace:
- all participants are notified daily,
- full plan operation remains available (unless stores or platform rules force earlier restriction),
- the UX clearly states the remaining grace duration and required action.

#### Scenario: Daily grace notifications to all participants
- **WHEN** the plan is in grace due to at least one unpaid required license
- **THEN** the app notifies all participants daily until the plan is restored to paid status or grace expires

### Requirement: Grace expiry transitions the plan to read-only mode
If the plan is still missing required paid licenses at grace expiry, the application SHALL transition the plan into read-only mode.

Read-only mode SHALL:
- allow consultation of past accepted ledger data,
- block initiation of a new realized expense entry flow for that plan,
- allow completion of a realized expense flow that was already initiated before the transition to read-only, if product policy keeps this exception,
- block any operation that would mutate the accepted ledger for that plan once the read-only boundary is crossed (product-defined list, but must include creating new realized expense proposals after the transition).

#### Scenario: Read-only blocks new expenses
- **WHEN** the plan is in read-only mode
- **THEN** the user cannot initiate a new realized expense flow for that plan

#### Scenario: In-progress expense flow may complete after read-only transition
- **WHEN** the user already initiated a realized expense flow before the plan entered read-only mode
- **THEN** the product MAY allow that already-started flow to complete according to the documented transition policy

### Requirement: Export is always available in read-only mode
In read-only mode, the application SHALL provide data export so participants can always retrieve their historical records.

Supported export formats SHALL be documented as part of this capability (or in linked documentation), and SHALL not be silently removed without a documented migration.

#### Scenario: Export remains accessible while read-only
- **WHEN** the plan transitions to read-only mode
- **THEN** the user can access export functionality and complete an export at any time while the plan remains in read-only mode

### Requirement: Housing import may remain separately guarded by entitlement
This capability's always-available export rule does not imply unrestricted housing import. Housing import MAY require a valid housing entitlement as specified in `housing-agreement-data-portability`, while export remains always available.

#### Scenario: Export allowed while import is still refused
- **WHEN** the plan is in read-only mode and the participant lacks valid housing entitlement for import
- **THEN** export remains available
- **THEN** housing import may still be refused per the module-specific import guard

