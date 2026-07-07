## ADDED Requirements

### Requirement: Vehicle module hub is the Propriétaire operations home
When the user taps **Vehicle** on the app home and holds **`vehicle`** entitlement, the app SHALL present the **Vehicle module hub** — a scrollable operations home (same *pattern* as the housing active agreement hub: primary sections and actions, not a prescribed tab bar).

**Navigation:** `App home → Vehicle → Vehicle module hub` (see `vehicle-app-home-navigation`).

### Requirement: Hub section — My vehicles
The hub SHALL include a **My vehicles** section listing each **owned** vehicle as a card (or equivalent row). For each vehicle, the card SHOULD surface at minimum:

- **Current mileage** (odometer)
- **Current average consumption** (when sufficient data exists; otherwise an explicit insufficient-data state per `vehicle-consumption-metrics`)
- **Alert tiles** (see `vehicle-maintenance-alert-tiles`)

Tapping a vehicle card SHOULD open a **vehicle detail** surface (implementation-defined) with fuller history; this spec does not define detail layout.

#### Scenario: Owner sees owned fleet summary
- **WHEN** a Propriétaire with two owned vehicles opens the Vehicle module hub
- **THEN** both vehicles appear under **My vehicles** with current mileage and consumption summary when data allows

### Requirement: Hub section — Statistics
The hub SHALL include a **Statistics** entry or section scoped to **all owned vehicles** (with optional per-vehicle filter in implementation). Statistics SHOULD expose at minimum:

- **My mileage** (total / windowed — Propriétaire lifetime scope)
- **My expenses** grouped by: maintenance, fuel, violations, insurance, registration & permits (labels localized)
- **Compensation received from sharing** (amounts credited from `vehicle-expense-sharing` settlements)

Exact charts vs list rows are **not** prescribed; numbers must match domain specs and remain explainable.

#### Scenario: Statistics reachable from hub
- **WHEN** the Propriétaire taps **Statistics** on the Vehicle module hub
- **THEN** the user sees mileage and expense summaries for owned vehicles

### Requirement: Hub row — Quick actions
The hub SHALL expose quick-access actions that launch the shared forms in `vehicle-quick-actions-ui`:

- Odometer reading
- Fuel purchase
- Maintenance performed
- Damage or violation report

These MAY appear as a horizontal action row, a grid, or prominent buttons; visual layout is not fixed.

#### Scenario: Quick actions on Vehicle hub persist locally
- **WHEN** the Propriétaire completes **Fuel purchase** from this hub
- **THEN** behavior follows `vehicle-quick-actions-ui` local persistence rules

### Requirement: Hub is a guide not a layout straitjacket
Section order, spacing, icons, and whether statistics open inline vs navigated ARE **implementation choices** for the first pass. Subsequent UX iterations MAY reorder or collapse sections without violating this spec, provided the **capabilities** above remain reachable.

#### Scenario: Future layout change remains valid
- **WHEN** a later release moves quick actions above **My vehicles**
- **THEN** that is acceptable if all required sections remain discoverable
