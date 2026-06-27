## Why

Compartarenta needs a **Vehicle** module (`vehicle`) that covers any personally owned conveyance — car, truck, motorcycle, boat, etc. — with accurate odometer, fuel, maintenance, and violation tracking. Vehicle data is **owned and maintained by one fixed owner** per vehicle. Sharing that vehicle with others is a separate licensed module (`vehicle-sharing`); this change defines owner-side capabilities only.

This change **supersedes** the monolithic `car-sharing-module` change for all owner-side vehicle semantics. Reservation/booking is **deferred** (see `dev-ideas/2026-06-27-wish-list.md`).

## What Changes

- Introduce the **`vehicle`** product module with stable identifier `vehicle` (replacing informal `car-sharing` / `car` naming).
- Model **one fixed owner per vehicle**; ownership does not transfer inside the app (sale handled via export/import of vehicle data by the buyer).
- Support **multiple vehicles per owner**.
- Owner-side tracking:
  - fuel purchases and full-tank–anchored consumption (both Propriétaire and Emprunteur may mark full-tank anchors on shared vehicles — see `vehicle-sharing-module`)
  - odometer or **horometer** (boats) logs and monotonic validation
  - maintenance / repairs log with **owner-only** service reminders (e.g., oil change at N km)
  - traffic violations log
  - lifetime vehicle metrics (total distance, consumption history)
- **Vehicle sale export** strips sharing links, enterer attribution, and usage ratios; buyer import receives factual history only.
- Keep derived metrics deterministic from stored facts.

## Capabilities

### New Capabilities

- `vehicle-domain-model`: Vehicles, fixed owner, vehicle kind (car, truck, motorcycle, boat, …), owner use sessions, owner-side expenses, facts vs derived metrics.
- `odometer-logging`: Odometer before/after per use; monotonic validation per vehicle; distance derivation.
- `fuel-purchase-tracking`: Fuel purchase facts linked to the vehicle; full-tank anchors for consumption.
- `vehicle-consumption-metrics`: Owner-visible consumption per km and total distance over the vehicle lifetime (and selectable windows).
- `maintenance-and-repairs-log`: Maintenance events, costs, owner-only scheduled reminders.
- `traffic-violations-log`: Violations linked to the vehicle with responsibility state.
- `vehicle-data-portability`: Sale export (factual history only, no sharing metadata) and buyer import.
- `vehicle-module-licensing`: 2-week trial on `vehicle` only; sharing free during vehicle trial; no standalone `vehicle-sharing` trial.

### Modified Capabilities

<!-- None. Sharing, allocations, and borrower usage live in `vehicle-sharing-module`. -->

## Impact

- **Licensing**: requires the `vehicle` subscription for owners; see `per-module-licensing-and-bundles` and `vehicle-sharing-module` for the paired sharing license.
- **Mobile UX**: vehicle list, owner use log, fuel/maintenance/violation entry, owner metrics, export.
- **Data storage**: vehicle-scoped tables keyed by owner; no mixing across owners.
- **Contacts**: participants for sharing are specified in `vehicle-sharing-module`; owner identity uses the self Contact.
