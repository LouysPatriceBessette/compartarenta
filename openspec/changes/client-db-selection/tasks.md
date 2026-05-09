## 1. Decision implementation (DB engine + access layer)

- [x] 1.1 Confirm SQLite + Drift as the chosen client DB stack in the mobile app dependencies
- [x] 1.2 Create initial DB module boundaries (DAO/repository layer) aligned with feature-first architecture

## 2. Schema versioning and migrations

- [x] 2.1 Define an initial schema versioning strategy (integer versions, forward-only migrations)
- [x] 2.2 Add migration tests that validate upgrading from N-1 to N preserves operational data

## 3. Exportability contract

- [x] 3.1 Define export bundle format (versioned JSON; stable IDs; references/denormalized views as needed)
- [x] 3.2 Implement a minimal export proof-of-concept that exports a small representative dataset deterministically
