## ADDED Requirements

### Requirement: Users can author a detailed expense plan before proposing to peers
After completing first-launch onboarding and initial configuration (`app-onboarding-initial-setup`), the application SHALL allow the user to build a **draft expense plan** locally. The plan SHALL support, at minimum:

- **Recurring fixed expenses**: known amount, cadence (e.g., monthly), participant **ratios** per line or per **group** of lines.
- **Estimated one-off expenses**: for each item or grouped set, a **minimum** and **maximum** expected amount (a range), plus participant **ratios** for that item or group.

#### Scenario: User adds a recurring line with ratios
- **WHEN** the user creates a recurring expense with a fixed amount and assigns participant ratios that sum to the product-defined tolerance (e.g., 100%)
- **THEN** the plan editor persists the line and includes it in plan summaries and projections

#### Scenario: User adds a one-off estimate with min and max
- **WHEN** the user creates an estimated one-off expense and enters min and max amounts
- **THEN** the editor validates that min ≤ max and stores both bounds for projection purposes

### Requirement: The product encourages a relatively detailed plan before proposal
The application SHALL use **non-blocking** encouragement (e.g., completeness checklist, inline tips, “readiness” score, or summary gaps) so users understand that a more detailed plan yields clearer peer proposals and better projections. The user SHALL still be allowed to save a minimal draft locally, but **proposing to peers** MAY be gated by configurable completeness rules defined by the product.

#### Scenario: Readiness hints highlight missing detail
- **WHEN** the user’s draft plan lacks key fields (e.g., missing ratios on a line, missing period linkage to the agreement contract)
- **THEN** the UI surfaces specific guidance without deleting existing work

#### Scenario: Optional gate before “Propose to group”
- **WHEN** the product defines minimum completeness for proposals and the draft does not meet it
- **THEN** the “Propose to group” action is disabled with an explanation of what remains to fill

### Requirement: Ratios are defined per expense or per expense group
For every recurring line and every estimated one-off (or grouped bucket), the application SHALL store participant **ratio weights** (or equivalent share model) attached at the **line** level or at a declared **group** level, consistent with balance math documented by the product.

#### Scenario: Group-level ratios apply to bundled lines
- **WHEN** the user assigns ratios at a group that contains multiple recurring lines
- **THEN** projection and eventual accepted ledger behavior apply those ratios consistently to each member line according to the documented allocation rule

### Requirement: Draft plans are local until explicitly proposed
Draft plan content SHALL remain on-device under the same local-first rules as other operational data until the user explicitly initiates a **proposal** to other participants (transport via encrypted relay per `privacy-first-sync-architecture`).

#### Scenario: Saving draft does not sync automatically
- **WHEN** the user saves a draft plan without choosing “Propose to group”
- **THEN** no relay message containing the plan is sent
