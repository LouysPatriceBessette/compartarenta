## ADDED Requirements

### Requirement: Maintenance alert tiles preview upcoming service thresholds
On each **owned** vehicle card in the **Vehicle module hub**, the app SHALL show **alert tiles** — compact cards indicating upcoming maintenance thresholds before a push/in-app notification fires.

Each tile corresponds to a **configured maintenance rule** (e.g., oil change every N km after the last service of that category).

#### Scenario: Tile appears before due threshold
- **WHEN** the last oil change was at 4 500 km and the rule is 5 000 km
- **AND** current mileage is at least 4 500 km
- **THEN** an alert tile indicates oil change due in 500 km (or equivalent remaining distance/hours)
- **THEN** the tile uses a **warning** visual treatment (product default: orange-toned tile)

#### Scenario: Multiple alert types may coexist
- **WHEN** rules exist for oil, tires, wipers, headlights, spark plugs, or other configured categories
- **THEN** the hub MAY show one tile per upcoming threshold that enters its preview window

Preview window default: **500 km** before the due threshold unless a rule specifies otherwise.

### Requirement: Notification fires when threshold is reached on odometer read
When the Propriétaire (or a forwarded Emprunteur reading that updates canonical mileage) saves an odometer reading that **reaches or exceeds** a due threshold, the app SHALL **immediately** schedule or show the maintenance notification for that rule (Propriétaire device only per `maintenance-and-repairs-log`).

Alert tiles for that rule MAY disappear or transition to a "due now" state after the notification fires.

#### Scenario: Notification on reading that crosses 5 000 km
- **WHEN** oil change is due at 5 000 km since last service
- **AND** a new reading moves current mileage from 4 950 km to 5 010 km
- **THEN** the Propriétaire receives the oil-change notification immediately
- **THEN** Emprunteur devices do not receive maintenance notifications

### Requirement: Completing maintenance clears or resets tiles
When the Propriétaire records a **Maintenance performed** event for a category, alert tiles and countdowns for that category SHALL reset from the new baseline (meter reading at service).

#### Scenario: Oil change maintenance resets tile
- **WHEN** the Propriétaire logs an oil change at 5 010 km
- **THEN** the oil-change alert tile clears until the next preview window before the following due interval

### Requirement: Alert tiles are Propriétaire hub only
Alert tiles SHALL NOT appear on **Vehicle sharing hub** accessible-vehicle cards (Emprunteur view). Emprunteurs rely on Propriétaire maintenance ownership per domain specs.

#### Scenario: Borrower hub has no maintenance alert tiles
- **WHEN** an Emprunteur views an accessible vehicle on the Vehicle sharing hub
- **THEN** maintenance alert tiles are not shown on that card
