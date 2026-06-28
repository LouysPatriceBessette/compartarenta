## ADDED Requirements

### Requirement: Vehicle quick actions use one shared form set
The app SHALL implement **one set of quick-action forms** reused by both the **Vehicle module hub** (`vehicle-hub-ui`) and the **Vehicle sharing hub** (`vehicle-sharing-hub-ui`). The forms SHALL capture the same fields; only **persistence and routing** differ (see below).

Shared quick actions (localized labels; order MAY match hub layout):

| Quick action | Purpose |
| --- | --- |
| **Odometer / horometer reading** | Before/after or standalone reading tied to a vehicle use or fuel event |
| **Fuel purchase** | Cost, volume optional, meter reading, full-tank flag |
| **Maintenance performed** | Service event (category, cost, notes, optional attachment) |
| **Damage or violation report** | Damage note and/or traffic violation facts |

Implementation MAY use bottom sheets, full-screen routes, or hub-embedded shortcuts; this spec does not mandate a single presentation pattern.

#### Scenario: Same fuel form opens from either hub
- **WHEN** the user taps **Fuel purchase** on the Vehicle hub or the Vehicle sharing hub
- **THEN** the same fuel purchase form component opens
- **THEN** field validation rules match `fuel-purchase-tracking`

### Requirement: Vehicle hub saves quick actions locally on owned vehicles
On the **Vehicle module hub**, quick-action submissions for a **owned** vehicle SHALL persist **locally** on the Propriétaire's device as canonical vehicle facts (no relay forward unless a separate sharing sync rule applies to already-owned data).

#### Scenario: Owner fuel purchase is local
- **WHEN** the Propriétaire submits **Fuel purchase** from the Vehicle hub for their car
- **THEN** the purchase is stored on the owned vehicle record immediately
- **THEN** consumption and alert-tile logic can react on the next hub refresh

### Requirement: Vehicle sharing hub forwards quick actions to the Propriétaire
On the **Vehicle sharing hub**, quick-action submissions for an **accessible** (shared) vehicle SHALL be **sent to the Propriétaire** (relay / sync path) so facts land on the Propriétaire's canonical vehicle record. The Emprunteur MUST NOT treat the submission as a second owner ledger.

The UI SHALL make clear that the entry is **for** a shared vehicle owned by someone else (Propriétaire identity visible).

#### Scenario: Borrower odometer reading is forwarded
- **WHEN** an Emprunteur submits an odometer reading from the Vehicle sharing hub
- **THEN** the app transmits the fact to the Propriétaire's vehicle record
- **THEN** the Emprunteur sees confirmation or a clear error if PP/PE/EV licensing blocks delivery (per `vehicle-sharing-licensing-and-delinquency`)

#### Scenario: Borrower maintenance report is forwarded
- **WHEN** an Emprunteur submits **Maintenance performed** for a shared vehicle
- **THEN** the event is sent to the Propriétaire for inclusion on the canonical vehicle record
- **THEN** maintenance reminder tiles remain **Propriétaire-only** on the Vehicle hub

### Requirement: Quick actions require vehicle context
Every quick-action flow SHALL start with (or inherit) a **selected vehicle** — owned vehicle on the Vehicle hub, accessible vehicle on the Vehicle sharing hub. The app MAY pre-select the vehicle when the user taps a tile on a vehicle card.

#### Scenario: Launch from vehicle card pre-selects vehicle
- **WHEN** the user taps **Odometer reading** on a specific vehicle card
- **THEN** the form opens with that vehicle already selected

### Requirement: Quick actions do not replace full list/history screens
Hub shortcuts are **entry accelerators**. The app SHOULD still provide full history/list surfaces for uses, fuel, maintenance, and violations elsewhere (drill-down from vehicle detail or statistics). Exact navigation to history is **not** prescribed here.

#### Scenario: Hub shortcut is not the only path
- **WHEN** the user needs to edit a past fuel purchase
- **THEN** a path exists outside the hub quick-action row (e.g., vehicle detail or statistics drill-down)
