## ADDED Requirements

### Requirement: Vehicle sharing hub is the Emprunteur and cross-borrow operations home
When the user taps **Vehicle sharing** on the app home and holds effective **`vehicle-sharing`** entitlement (PE and/or PP context), the app SHALL present the **Vehicle sharing hub** — a scrollable operations home parallel to the Vehicle module hub.

**Navigation:** `App home → Vehicle sharing → Vehicle sharing hub` (see `vehicle-app-home-navigation`). Vehicle sharing is **not** nested under the **Vehicle** home affordance.

### Requirement: Hub section — Accessible vehicles
The hub SHALL include an **Accessible vehicles** section listing vehicles the user may use:

- as **Emprunteur** (active sharing link), and/or
- as **Propriétaire** previewing sharing balance on vehicles they own (when PP applies).

For each accessible vehicle, the card SHOULD surface at minimum:

- **Amount owed or credit** (settlement position from `vehicle-expense-sharing` with detail level TBD in implementation — summary amount on card, breakdown on drill-down is acceptable for first pass)
- Vehicle label and **Propriétaire** identity when the viewer is Emprunteur

Cards SHALL NOT show Propriétaire-only lifetime consumption or maintenance alert tiles.

#### Scenario: Borrower sees shared vehicle balance
- **WHEN** an Emprunteur has an active link on A's car
- **THEN** the car appears under **Accessible vehicles** with owed/credit summary when allocation data exists

#### Scenario: Owner does not list owned vehicles under accessible unless sharing context applies
- **WHEN** a Propriétaire opens the Vehicle sharing hub
- **THEN** owned vehicles appear here only when showing **sharing settlement** context (amounts owed by/to Emprunteurs), not as duplicates of **My vehicles** on the Vehicle hub

### Requirement: Hub section — Statistics
The hub SHALL include **Statistics** scoped to **accessible vehicles** and **Emprunteur windows** (per `vehicle-sharing-usage-metrics`):

- **My mileage** (attributed uses only)
- **My expenses**: fuel, violations, insurance, permits (maintenance MAY appear when forwarded events affect the user's reconciliation window — registration grouping optional on first pass)
- **Compensation paid** (amounts the user paid to others through sharing settlements)

#### Scenario: Borrower statistics exclude others' usage
- **WHEN** an Emprunteur opens **Statistics** on the Vehicle sharing hub
- **THEN** mileage and expenses reflect only that user's attributed windows

### Requirement: Hub row — Quick actions
The hub SHALL expose the same quick-action set as the Vehicle module hub (see `vehicle-quick-actions-ui`):

- Odometer / horometer reading
- Fuel purchase
- Maintenance performed
- Damage or violation report

Submissions follow **forward-to-Propriétaire** routing for shared vehicles.

#### Scenario: Quick action forwards to owner
- **WHEN** an Emprunteur submits **Fuel purchase** with full tank = true from this hub
- **THEN** the purchase is sent to the Propriétaire's canonical record per domain rules

### Requirement: Propriétaire offers a vehicle from sharing context
The app SHALL provide a path from the Vehicle sharing hub (or owned vehicle detail) for a Propriétaire with EV+PP to **offer this vehicle** to a connected Contact per `vehicle-sharing-domain-model`. This flow is **not** fully wireframed here; first implementation MAY use a simple invite + accept pattern.

#### Scenario: Offer path exists
- **WHEN** a Propriétaire with both modules taps offer sharing on a owned vehicle
- **THEN** the user can select a connected Contact and send a vehicle-specific offer

### Requirement: Hub is a guide not a layout straitjacket
As with the Vehicle module hub, layout and visual hierarchy are **guidance for the first implementation** only. Reordering sections or merging statistics into cards is allowed if capabilities remain reachable.
