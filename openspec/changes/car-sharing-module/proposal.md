## Why

Compartarenta currently targets equitable shared apartment expenses, but many households also need a privacy-first, error-resistant way to share a car. Adding a dedicated car-sharing module enables accurate tracking (usage, fuel, maintenance, violations) and fair cost allocation driven by real usage.

## What Changes

- Add a second module for **car sharing** alongside the existing shared-expenses (apartment) context.
- Introduce vehicle-specific tracking:
  - odometer logs (before/after each use)
  - fuel purchases and derived consumption metrics
  - maintenance expenses
  - traffic tickets / violations log
- Calculate usage ratios (per person) and consumption-per-km to support fair cost sharing.
- Add a reservation/booking capability to reserve the car in advance.
- Keep the product oriented to equitable sharing with minimal manual errors, consistent with the project’s privacy-first direction.

## Capabilities

### New Capabilities

- `car-sharing-domain-model`: Data model for vehicles, participants, trips/uses, expenses, and allocations in the car-sharing context.
- `odometer-logging`: Capture odometer readings (before/after) per car use, validate monotonicity, and derive distance traveled.
- `fuel-purchase-tracking`: Record fuel purchases (amount, cost, date, optional liters/volume) and link to usage windows for consumption calculations.
- `consumption-and-usage-metrics`: Compute consumption per km and per-user usage ratio; expose these as inputs to allocation rules.
- `car-expense-sharing`: Allocate fuel, maintenance, and other shared car expenses using configurable rules (equal split, usage-weighted, fixed ratios with adjustment suggestions).
- `maintenance-and-repairs-log`: Track maintenance events/expenses (category, vendor, notes, receipts metadata) and share them across participants.
- `traffic-violations-log`: Record tickets/infractions (date, type, amount, responsible user if known) and include in settlement.
- `car-reservations`: Reserve the vehicle for a time range; prevent conflicts; support basic recurring rules later.

### Modified Capabilities

<!-- None yet: this change introduces a new module rather than modifying existing spec-level behaviors. -->

## Impact

- **Mobile app UX**: New navigation entries/screens for car sharing (vehicle list, usage log, expenses, reservations, metrics).
- **Data storage**: New local entities and derived/calculated fields; indexing for date-based queries.
- **Business rules**: Validation (odometer monotonicity), conflict handling (reservations), and allocation computations.
- **Future sync**: Car-sharing data should align with privacy-first sync constraints (local-first, verifiable derivations) but this change focuses on app-level capabilities/specs first.
