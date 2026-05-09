## Why

Compartarenta is a local-first app: operational data must live on-device, and the app will evolve over time. We need an explicit, reviewable decision for the client database that prioritizes disk footprint, exportability, and safe schema migrations.

## What Changes

- Select a concrete client database approach for on-device persistence (engine + access layer).
- Define the non-negotiable requirements that drive the choice: minimal disk footprint, predictable migrations/versioning, and a practical export path.
- Document alternatives considered and why they were not selected.

## Capabilities

### New Capabilities

- `client-db-selection-and-requirements`: Define requirements and make a justified decision for the on-device database engine and migration strategy.
- `client-db-exportability`: Define constraints that ensure stored data can be exported into a human-comprehensible format with minimal transformation.

### Modified Capabilities

<!-- None. This change clarifies implementation choices; it does not change the existing privacy/data-locality requirements. -->

## Impact

- **Mobile app**: Introduces (or standardizes) the persistence layer choice and migration mechanism.
- **Future features**: Car sharing, housing plans, trial/licensing, and proposal-based sync all depend on stable local storage and migrations.
- **Auditing**: Makes the data-locality promise easier to review by explicitly documenting storage choice and constraints.
