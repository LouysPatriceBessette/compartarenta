## 1. Domain model and persistence

- [ ] 1.1 Extend local schema for expense plan lines: recurring vs one-off estimate, min/max, grouping, ratios, currency alignment.
- [ ] 1.2 Extend local schema for agreement contract: period bounds, min notice, optional penalty, free-text flexible clauses (bounded length).

## 2. UX

- [ ] 2.1 Implement plan editor with encouragement patterns (checklist completeness, summary panel, “ready to propose” gate).
- [ ] 2.2 Implement projection screen or panel with clear “preview / not binding” labeling.
- [ ] 2.3 Implement contract editor with validation for mandatory minima (period, notice and/or penalty per product rule).

## 3. Sync and consensus

- [ ] 3.1 Define wire payloads for “plan + contract package” proposals and unanimous acceptance tracking.
- [ ] 3.2 Implement renegotiation flow: version bumps, pending vs active contract, rollback when not unanimous.

## 4. Tests

- [ ] 4.1 Unit tests for projection math given ratios, recurring schedule, and min/max one-offs (document assumptions).
- [ ] 4.2 Tests that partial acceptance does not activate a new contract version.
