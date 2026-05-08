## ADDED Requirements

### Requirement: If a single unpaid license blocks a plan, the plan must be updated for remaining participants
If a plan is blocked due to one participant’s required license being unpaid (while at least two other participant licenses remain active), the application SHALL guide the group to modify the plan to reflect the remaining participants.

#### Scenario: Removal flow is offered when a participant blocks the group
- **WHEN** the plan is blocked because a required license is unpaid
- **THEN** the app offers a “Modify plan for remaining participants” flow that results in a new plan proposal (subject to unanimous acceptance per existing contract renegotiation rules)

### Requirement: The app produces a differential impact report between old and new plans
When generating a modified plan that removes a participant due to payment failure, the application SHALL produce a **differential impact report** showing the impact of removing that participant on each remaining participant’s projected obligations, using the projection rules defined in `expense-plan-contract-model`.

The report SHALL be suitable for export and reference, but the app SHALL not present it as legal advice.

#### Scenario: Differential report compares obligations
- **WHEN** a participant is removed and a new plan is drafted
- **THEN** the app generates a diff that shows per-participant changes between the prior plan and the proposed replacement plan (e.g., projected monthly totals before vs after)

### Requirement: Dispute-limited behavior is explicit
In this scenario, the application SHALL do no further dispute adjudication beyond producing the differential report and allowing exports. Any additional dispute handling is out of scope of the product.

#### Scenario: App does not claim to resolve disputes
- **WHEN** users view the differential report
- **THEN** the UI and documentation state the app does not resolve legal disputes and that users are responsible for their agreements

