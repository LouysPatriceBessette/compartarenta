## Context

This change sits **after** onboarding (`app-onboarding-initial-setup`) and uses the same **proposal / accept / reject** model for anything that becomes binding for the group (`privacy-first-sync-architecture`, `data-locality-and-client-storage`).

## Concepts

| Concept | Meaning |
|--------|---------|
| **Expense plan** | A structured set of planned expenses (recurring fixed, estimated one-off ranges), optionally grouped, each with participant **ratios**. |
| **Projection** | A read-only computation: if the current draft or proposed plan were accepted unchanged, approximate per-participant totals over the agreement period. |
| **Agreement contract** | Meta-rules with **minimums**: period of the arrangement; minimum notice for early withdrawal; optional **penalty** for withdrawal; additional flexible clauses allowed above the floor. |
| **Renegotiation** | A new proposal that changes plan and/or contract; becomes active only after **unanimous** accept across all participants. |

## UX principles

- **Encourage detail without blocking**: progressive disclosure, templates, and validation hints—not a single giant form unless the user opts in.
- **Separate “draft for me” from “propose to group”**: local drafting is always possible; sending is explicit.
- **Projections are labeled as previews** until the relevant package is unanimously accepted.

## Open points (product to decide)

- Whether one-off estimates use uniform distribution within min–max or user-chosen expected value.
- Whether withdrawal rules are per-participant opt-out or group dissolution only.
- Maximum number of participants for unanimous UI.
