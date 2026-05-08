## ADDED Requirements

### Requirement: Projection shows approximate per-participant payment if the plan were accepted
The application SHALL compute and display a **projection** of how much each participant would be expected to pay (or fund) over the **agreement period** defined in `shared-agreement-contract-terms`, given:

- recurring fixed amounts in the plan,
- one-off items represented by min/max estimates using **documented projection assumptions** (e.g., use midpoint, min-only, max-only, or user-selected expected value—the product SHALL pick one and disclose it in-app or in docs).

#### Scenario: Projection uses documented estimate rule for one-offs
- **WHEN** the plan contains one-off items with min and max
- **THEN** the projection applies the documented rule consistently and labels that one-offs are estimates

#### Scenario: Projection updates as the draft changes
- **WHEN** the user edits amounts, ratios, or the agreement period
- **THEN** the projection panel updates without requiring a network call

### Requirement: Projection is clearly non-binding until unanimous acceptance
The UI SHALL distinguish **projection / preview** from **agreed balances** derived from accepted ledger entries (`data-locality-and-client-storage`). Language and visual treatment SHALL make clear that projections depend on draft or proposed data and on unanimous acceptance of the plan+contract package.

#### Scenario: Preview banner on projection view
- **WHEN** the user views projections for a draft or not-yet-unanimously-accepted proposal
- **THEN** a prominent indicator states that amounts are not final for the group until unanimous acceptance

### Requirement: Projection respects the agreement period boundary
Projection totals SHALL be scoped to the configured agreement period (start/end or rolling window per product). If the period is open-ended, the product SHALL document how projections are annualized or bounded for display.

#### Scenario: Period change alters projected totals
- **WHEN** the user shortens the agreement period in the contract editor
- **THEN** recurring projections scale or truncate per documented rules and the UI reflects the new period
