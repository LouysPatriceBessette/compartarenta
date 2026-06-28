## Why

Sharing a vehicle fairly requires collaboration: owners invite borrowers, borrowers log usage, and participants reconcile shared costs. That collaboration is licensed separately from **`vehicle`** so a participant who only **borrows** (participant B) pays less than an owner (participant A) who maintains the asset and shares it.

An owner who wants to **offer** their vehicle for sharing needs **both** `vehicle` and `vehicle-sharing`. A borrower needs only `vehicle-sharing` plus **acceptance** by the vehicle owner. Owners and borrowers may each use multiple vehicles; sharing one's own vehicle does not prevent borrowing another owner's vehicle.

This change **supersedes** the sharing, allocation, and group semantics of `car-sharing-module`. Reservations are **deferred** (wish list).

## What Changes

- Introduce the **`vehicle-sharing`** product module (identifier `vehicle-sharing`).
- Model **sharing relationships** per vehicle: owner (requires `vehicle` + `vehicle-sharing`) and approved borrowers (requires `vehicle-sharing` only).
- Allow **multiple borrowers per vehicle** and **multiple vehicles per borrower** (same or different owners).
- Borrowers **add usage data** (odometer sessions, usage-scoped fuel facts) on the owner's vehicle record.
- **Borrower-visible metrics**: usage statistics (distance, fuel) limited to their own usage windows — not the vehicle's lifetime history.
- **Reconciliation data**: both owner and borrower see the facts needed to settle costs, but only for windows tied to the borrower's usage (and owner sees full reconciliation across all sharers).
- **Expense sharing**: configurable ratios and allocations for fuel, maintenance, payments, violations (migrated from former `car-expense-sharing`).
- Owner acceptance gate before a borrower can log usage on a vehicle.

## Capabilities

### New Capabilities

- `vehicle-sharing-domain-model`: Sharing links, owner/borrower roles, acceptance, multi-vehicle / multi-borrower rules.
- `vehicle-sharing-usage-logging`: Borrower (and owner) use sessions on a shared vehicle; attribution to borrower Contact; gap attribution notifications and Propriétaire revision per `vehicle-odometer-gap-attribution`.
- `vehicle-sharing-usage-metrics`: Borrower-scoped distance and fuel statistics; reconciliation windows.
- `vehicle-expense-sharing`: Category-based allocation (fuel, maintenance, violations, payments), proposals and acceptance.
- `vehicle-sharing-licensing-and-delinquency`: EV/PP/PE entitlement roles, 1-week grace, delinquency effects per role.
- `vehicle-sharing-hub-ui`: Accessible vehicles, statistics, quick actions (forward routing), offer path.

### Modified Capabilities

<!-- None at product-wide level. Depends on `vehicle-domain-model` and `vehicle` entitlement for owners who share. -->

## Impact

- **Licensing**: dependency rules added in `per-module-licensing-and-bundles` (`module-subscription-dependencies`).
- **Relay / sync**: sharing proposals and usage facts sync under `vehicle-sharing` scope.
- **Contacts**: borrowers and owners are connected Contacts; see `contacts-module-integration`.
- **Mobile UX**: invite/accept flows, borrower dashboard per shared vehicle, allocation review.
