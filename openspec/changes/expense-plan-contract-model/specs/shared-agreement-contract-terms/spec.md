## ADDED Requirements

### Requirement: Every shared arrangement defines an agreement period
The **agreement contract** associated with a shared expense plan SHALL include a defined **period** of the arrangement (calendar start/end, or explicit duration with anchor date—product choice). The period SHALL be mandatory before a plan+contract package can be proposed to peers if the product requires a bounded commitment window.

#### Scenario: User cannot omit period when period is mandatory
- **WHEN** the product mandates an agreement period for group proposals and the user attempts to propose without setting it
- **THEN** the app blocks proposal with a targeted validation message

### Requirement: Early withdrawal rules define a minimum floor
The contract SHALL capture at least one enforceable floor for **early / hasty withdrawal** from the arrangement, implemented as:

- a **minimum notice period** before withdrawal takes effect, and/or  
- a **penalty amount** (or documented formula) applied on withdrawal,

such that the combination satisfies the product’s rule that there is a **non-empty minimum**: the product SHALL require at least one of notice or penalty (or both if desired), and SHALL reject saving a contract that meets neither.

#### Scenario: Contract save requires notice or penalty
- **WHEN** the user clears both minimum notice and penalty fields
- **THEN** validation prevents saving the contract as complete for proposal purposes

#### Scenario: User sets minimum notice only
- **WHEN** the user sets a positive minimum notice duration and leaves penalty unset or zero per product rules
- **THEN** the contract is valid for proposal if notice-only satisfies the minimum floor rule

### Requirement: Flexible additional rules are allowed above the minimum
Beyond the mandatory minima, the contract MAY include optional **flexible clauses** (free text within length limits, toggles, or structured addenda). These optional clauses SHALL still be part of the same proposal package and subject to the same unanimous acceptance rules as core minima.

#### Scenario: Optional clause is proposed with the package
- **WHEN** the user adds an optional flexible clause and proposes the plan+contract
- **THEN** peers see the clause as part of the proposal and must accept or reject the package as negotiated (per renegotiation spec)

### Requirement: Contract terms are versioned with the plan they accompany
Changes to contract minima or flexible clauses SHALL create a new **contract version** (or proposal revision identifier) bundled with the plan revision so that sync and audit trails can reference a single unanimously accepted snapshot.

#### Scenario: Editing contract after peer accept creates pending renegotiation
- **WHEN** an active unanimous agreement exists and one user edits core contract fields locally
- **THEN** the app treats the result as a pending renegotiation draft until proposed and unanimously accepted again
