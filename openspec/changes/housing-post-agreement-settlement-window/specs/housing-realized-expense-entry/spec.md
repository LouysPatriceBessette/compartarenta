## ADDED Requirements

### Requirement: Post-end settlement entry is time-boxed and agreement-scoped

Realized-expense entry for an ended housing agreement SHALL remain available only during the settlement-open state defined by `housing-agreement-amendment-and-closure`.

During that settlement-open state:

- the user MAY record additional realized expenses for the ended agreement,
- the payment date picker MUST remain scoped to that ended agreement,
- selectable dates MUST end no later than one calendar month after the agreement `periodEnd`, and
- any expense entered there MUST stay attached to the ended agreement even if a successor agreement already exists.

#### Scenario: Late settlement expense is still allowed

- **WHEN** an agreement ended on 2026-10-28, balances are still not zero, and the user opens expense entry on 2026-11-10
- **THEN** the ended agreement still allows expense entry and the payment date picker may select dates through 2026-11-28 inclusive

#### Scenario: Closed settlement window blocks late entry

- **WHEN** an ended agreement is past its one-calendar-month settlement window
- **THEN** the expense-entry flow for that agreement is blocked

#### Scenario: Successor agreement does not absorb old-term settlement entry

- **WHEN** a new agreement already exists and the user records a late settlement expense from the previous ended agreement
- **THEN** the new expense is stored under the previous agreement, not the successor agreement
