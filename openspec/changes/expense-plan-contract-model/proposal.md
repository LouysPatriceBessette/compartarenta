## Why

After first launch and basic settings (`app-onboarding-initial-setup`), users need to model **how** shared expenses will work before and during peer collaboration. The product encourages a **detailed expense plan** (recurring items, estimated one-off ranges, participant ratios) so peers receive a clear **proposal**. Users also need **projections** (“if everyone accepts, who pays roughly how much”). Finally, shared arrangements behave like a **flexible contract** with mandatory floors (agreement period, early-withdrawal notice and/or penalty), while remaining **renegotiable** only with **unanimous** participant consent—aligned with proposal/accept semantics in `privacy-first-sync-architecture`.

## What Changes

- Define requirements for building and refining a **shared expense plan** (structure, recurrence, estimates, ratios).
- Define requirements for **projection / preview** of per-participant obligations if the plan were accepted as-is.
- Define requirements for the **agreement contract** layer (period, minimum notice for hasty withdrawal, withdrawal penalty where applicable) as non-empty minima with room for richer optional rules.
- Define requirements for **renegotiation**: any change to an active agreement or plan that affects the group requires **unanimous** acceptance from all participants.

## Capabilities

### New Capabilities

- `expense-plan-structure-and-editor`: Draft and detailed plan modeling (recurring, one-off ranges, groups, ratios).
- `plan-projection-preview`: Per-participant payment projections under “all accept” assumptions.
- `shared-agreement-contract-terms`: Agreement period and minimum withdrawal rules (notice and/or penalty).
- `contract-unanimous-renegotiation`: Versioning and unanimous consent for changes to plans or contract terms.

### Modified Capabilities

- None (cross-references only).

## Impact

- Extends the local domain model beyond single-line expenses; may require new UI flows and persistence.
- Tightly couples to sync: plan + contract packages are likely **proposed** and **accepted/rejected** per participant device.
