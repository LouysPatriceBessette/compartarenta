## MODIFIED Requirements

### Requirement: Agreement end and renewal

When the agreement **period ends** (calendar end reached or explicit closure action), the agreement exits normal in-force mode. Realized-expense entry for that agreement ceases **unless** the agreement is still within a settlement window and participant balances are not zero.

An ended agreement MAY remain **settlement-open** only when both conditions are true:

- participant balances for that agreement are not zero, and
- the current local calendar date is no later than one calendar month after `periodEnd`.

A settlement-open agreement MUST allow only the limited post-end operations defined by the realized-expense entry and ledger specs. It MUST NOT reopen in-force amendment behavior or turn the old agreement back into the group’s normal active term.

Starting a new term SHALL still use a **new** unanimous proposal; the author MAY **fork** the ended plan’s active revision as the starting draft. A newly accepted agreement MAY coexist with a prior agreement that is still settlement-open.

#### Scenario: Expired agreement with zero balances blocks new realized expenses

- **WHEN** today is after `periodEnd` and participant balances for that agreement are zero
- **THEN** **Enter an expense** is blocked for that agreement and the user is directed to start a new agreement if needed

#### Scenario: Ended agreement remains settlement-open for one month

- **WHEN** today is after `periodEnd`, participant balances are not zero, and the current date is within one calendar month after `periodEnd`
- **THEN** the ended agreement remains available for settlement-only realized-expense activity and balance review

#### Scenario: Settlement window closes after timeout

- **WHEN** today is later than one calendar month after `periodEnd`
- **THEN** the ended agreement no longer accepts new realized expenses even if balances are still not zero

#### Scenario: New term can coexist with prior settlement window

- **WHEN** the previous agreement is settlement-open and the group starts a new agreement for the next term
- **THEN** the new agreement can be proposed, accepted, and managed without reactivating the previous agreement as an in-force term

#### Scenario: Fork after year completed

- **WHEN** the group completes a one-year agreement and starts a new year
- **THEN** they fork the prior active plan into a new draft package instead of retyping all lines
