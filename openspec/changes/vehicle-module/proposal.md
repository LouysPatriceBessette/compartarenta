## Why

Bojairũ needs a **Vehicle** module (`vehicle`) for personally owned **land conveyances** — car, truck, motorcycle — with accurate odometer, fuel, maintenance, and violation tracking. Vehicle data is **owned and maintained by one fixed owner** per vehicle. Sharing that vehicle with others is a separate licensed module (`vehicle-sharing`); this change defines owner-side capabilities only.

**Boat** vehicles (engine hour meter / horomètre) are **deferred from the initial release** — see `design.md` § Decisions and tasks §10.5 / §15.

This change **supersedes** the monolithic `car-sharing-module` change for all owner-side vehicle semantics. Reservation/booking is **deferred** (see `dev-ideas/2026-06-27-wish-list.md`).

## What Changes

- Introduce the **`vehicle`** product module with stable identifier `vehicle` (replacing informal `car-sharing` / `car` naming).
- Model **one fixed owner per vehicle**; ownership does not transfer inside the app (sale handled via export/import of vehicle data by the buyer).
- Support **up to three vehicles per owner** (product cap in `vehicle-domain-model`).
- Owner-side tracking (initial release — **land vehicles**):
  - fuel purchases and full-tank–anchored consumption (both Propriétaire and Emprunteur may mark full-tank anchors on shared vehicles — see `vehicle-sharing-module`)
  - **odometer** logs with **meter photo when the reading changes** (known-unchanged shortcut at session start only), monotonic validation, positive/negative gap attribution
  - maintenance / repairs log with **owner-only** service reminders (e.g., oil change at N km)
  - traffic violations log
  - lifetime vehicle metrics (total distance, consumption history)
- **Deferred (future release):** **boat** kind with **engine hour meter (horomètre)**, hour-based usage, and boat-specific consumption — see `design.md`.
- **Vehicle sale export** strips sharing links, enterer attribution, and usage ratios; buyer import receives factual history only.
- Keep derived metrics deterministic from stored facts.

## Capabilities

### New Capabilities

- `vehicle-domain-model`: Vehicles, fixed owner, vehicle kind (**car, truck, motorcycle** at initial release; **boat** deferred), owner use sessions, owner-side expenses, facts vs derived metrics.
- `odometer-logging`: Odometer before/after per use; monotonic validation per vehicle; distance derivation.
- `vehicle-odometer-gap-attribution`: Positive gap prompt; Unknown durable + Propriétaire notify; negative gap + photo verify; Propriétaire-only revision (informational notifications).
- `fuel-purchase-tracking`: Fuel purchase facts linked to the vehicle; full-tank anchors for consumption.
- `vehicle-consumption-metrics`: Owner-visible consumption per km and total distance over the vehicle lifetime (and selectable windows).
- `maintenance-and-repairs-log`: Maintenance events, costs, owner-only scheduled reminders.
- `traffic-violations-log`: Violations linked to the vehicle with responsibility state.
- `vehicle-data-portability`: Sale export (factual history only, no sharing metadata) and buyer import.
- `vehicle-legacy-code-removal`: Delete prototype `car_sharing` UI/routes/prefs; no backward compatibility.
- `vehicle-app-home-navigation`: Wire existing home tiles; sibling entries, not nested.
- `vehicle-hub-ui`: Propriétaire operations hub (My vehicles, statistics, quick actions).
- `vehicle-quick-actions-ui`: Shared quick forms; local save vs forward-to-Propriétaire routing.
- `vehicle-maintenance-alert-tiles`: Orange preview tiles; notification on threshold odometer read.
- `vehicle-module-licensing`: 2-week trial on `vehicle` only; **`vehicle-sharing` has no trial period** (not covered by the `vehicle` trial).

### Modified Capabilities

<!-- None. Sharing, allocations, and borrower usage live in `vehicle-sharing-module`. -->

## Impact

- **Licensing**: requires the `vehicle` subscription for owners; see `per-module-licensing-and-bundles` and `vehicle-sharing-module` for the paired sharing license.
- **Mobile UX**: Vehicle module hub, alert tiles, shared quick actions, statistics, export.
- **Data storage**: vehicle-scoped tables keyed by owner; no mixing across owners.
- **Contacts**: participants for sharing are specified in `vehicle-sharing-module`; owner identity uses the self Contact.
