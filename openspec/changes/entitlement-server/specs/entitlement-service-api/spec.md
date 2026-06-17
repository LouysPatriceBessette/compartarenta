## ADDED Requirements

### Requirement: Entitlement state is separate from relay payload storage
The entitlement service SHALL persist only entitlement and gating metadata. It SHALL NOT store relay ciphertext, expense amounts, plan line text, or other business-domain payloads.

#### Scenario: Schema review excludes business payload tables
- **WHEN** the entitlement database schema is inspected
- **THEN** no table stores user operational payloads from ledger sync

### Requirement: Installations can register a stable participant installation identity
The service SHALL accept registration of a `participant_installation_id` (opaque, stable per app installation) and track housing `trial_consumed` for that identity.

#### Scenario: Registration is idempotent
- **WHEN** the same installation id is registered twice
- **THEN** the service returns success without resetting trial consumption

### Requirement: Housing trial starts on qualifying active-use events only
The service SHALL record `active_use_started_at` for a plan only when a qualifying realized-expense sync event is reported or introspected (not from `plan_id` alone).

When trial starts, every installation in the plan's accepted roster SHALL be marked `trial_housing_consumed`.

#### Scenario: Realized expense propose starts trial
- **WHEN** the first qualifying active-use event is recorded for plan P with accepted roster R
- **THEN** trial start and end timestamps are set for P
- **THEN** every installation in R is marked trial consumed

#### Scenario: Plan id alone does not start trial
- **WHEN** only a plan roster is reported without a qualifying active-use event
- **THEN** no trial timestamps are created for that plan

### Requirement: New housing plans are not trial-eligible when any participant consumed trial
- **WHEN** a plan's accepted roster includes any installation already marked trial consumed
- **THEN** that plan does not receive a new trial period

### Requirement: Plan-level license coverage is enforced collectively
- **WHEN** all required participants for a plan report `active_paid` (or stub-validated paid)
- **THEN** the plan may operate in paid mode
- **WHEN** any required participant is unpaid after trial
- **THEN** delinquency rules apply (grace then read-only)

### Requirement: Introspection answers allow or deny for relay gated operations
The service SHALL expose an introspection endpoint that accepts minimal gate metadata (`module`, `plan_id`, `participant_installation_id`, operation, optional ids) and returns `allow` or `deny` with a documented code.

#### Scenario: Trial expired request is denied
- **WHEN** introspection is called for a mutating housing operation after trial expiry with unpaid licenses
- **THEN** the response is deny with code `entitlement_trial_expired` or `entitlement_not_entitled`

### Requirement: License verification is pluggable
The service SHALL support a stub verifier (client-reported status) in Phase A and SHALL allow replacement with Google Play validation without changing the durable state schema.

#### Scenario: Stub accepts reported paid status
- **WHEN** a client reports `active_paid` for an installation on a plan
- **THEN** plan-level paid evaluation includes that participant
