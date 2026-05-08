## ADDED Requirements

### Requirement: License is individual per participant
The usage license SHALL be individual: each participant linked to a plan SHALL maintain an active paid license for full plan operation.

#### Scenario: Each participant must purchase
- **WHEN** a plan is operating in paid mode
- **THEN** each linked participant has an active license status for that plan context (or a product-defined equivalent mapping)

### Requirement: Participants are collectively responsible for plan licensing coverage
The product SHALL treat participants as collectively responsible for ensuring all required licenses for a plan are paid so the plan can operate.

#### Scenario: Missing one license blocks plan operation
- **WHEN** at least one required participant license is unpaid
- **THEN** the plan is not considered fully entitled for operation (grace/read-only rules apply elsewhere)

### Requirement: Monthly renewal aligns to a shared plan renewal date
Once all required licenses linked to a plan are paid, the plan SHALL establish a shared monthly renewal date. All participants linked to that plan SHALL renew on the same date (even though the licenses are individual).

#### Scenario: Plan becomes fully paid and sets shared renewal date
- **WHEN** the final missing participant license is successfully paid for a plan
- **THEN** the app sets a plan-level renewal anchor date and reflects it consistently for all participants

