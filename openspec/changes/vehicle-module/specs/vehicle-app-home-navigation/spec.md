## ADDED Requirements

### Requirement: Home module tiles already exist in the shell
The app home **already renders** two sibling module tiles using localized keys `homeModuleVehicle` and `homeModuleVehicleSharing` (FR: *Véhicule*, *Partage de véhicule* — see `HomeScreen` in the mobile app). Vehicle work SHALL **wire** these existing tiles to the respective hubs, replacing the interim "coming soon" placeholder, rather than adding a nested menu or new home affordance names.

#### Scenario: Existing home tiles navigate to hubs when implemented
- **WHEN** the vehicle hubs ship
- **THEN** tapping **Vehicle** opens the Vehicle module hub (not a selector and not **Vehicle sharing**)
- **THEN** tapping **Vehicle sharing** opens the Vehicle sharing hub
- **THEN** the home layout remains two peer tiles alongside Contacts and Housing

#### Scenario: Interim coming-soon state is replaced
- **WHEN** a tile's module is entitled and enabled
- **THEN** the tile is active and navigates to its hub
- **WHEN** the module is not entitled or is disabled
- **THEN** the tile is hidden or shows licensing guidance per enable/disable rules (replacing a permanent disabled stub)

### Requirement: App home exposes one top-level affordance per vehicle module
The app home (main shell) SHALL expose **separate, sibling** entry affordances for the vehicle domain — not a nested `Vehicle → Sharing` hierarchy and not an intermediate selector between the two hubs.

| App home affordance | Opens | Visible when |
| --- | --- | --- |
| **Vehicle** (localized; FR: *Véhicule*) | Vehicle module hub | User has effective **`vehicle`** entitlement (EV) and the module is enabled |
| **Vehicle sharing** (localized; FR: *Partage de véhicule*) | Vehicle sharing hub | User has effective **`vehicle-sharing`** entitlement (PP/PE) |

#### Scenario: Navigation paths are direct from app home
- **WHEN** the user taps **Vehicle** on the app home
- **THEN** the app opens the Vehicle module hub directly
- **THEN** the path is `App home → Vehicle → Vehicle module hub`

#### Scenario: Vehicle sharing is not nested under Vehicle
- **WHEN** the user taps **Vehicle sharing** on the app home
- **THEN** the app opens the Vehicle sharing hub directly
- **THEN** the path is `App home → Vehicle sharing → Vehicle sharing hub`
- **THEN** the user did not pass through the Vehicle module hub or a sub-menu under **Vehicle**

### Requirement: Both affordances may appear together
When the user holds both modules (typical Propriétaire who shares), the app home SHALL show **both** affordances as **peer** entries. The app MUST NOT require choosing between hubs on an intermediate screen.

#### Scenario: Propriétaire who shares sees two home buttons
- **WHEN** a user has effective `vehicle` and `vehicle-sharing`
- **THEN** the app home shows both **Vehicle** and **Vehicle sharing**
- **THEN** each affordance navigates to its respective hub in one tap

#### Scenario: Emprunteur-only sees sharing affordance
- **WHEN** a user has `vehicle-sharing` only (PE)
- **THEN** the app home shows **Vehicle sharing** but not **Vehicle**

#### Scenario: Solo owner sees vehicle affordance only
- **WHEN** a user has `vehicle` only (EV, no sharing subscription)
- **THEN** the app home shows **Vehicle** but not **Vehicle sharing**

### Requirement: Disabled or unentitled modules hide their home affordance
When a module is disabled in settings or the user lacks effective entitlement, that module's app home affordance SHALL be hidden or replaced with licensing guidance — consistent with per-module enable/disable rules.

#### Scenario: Disabled sharing hides sharing home entry
- **WHEN** the user toggles `vehicle-sharing` off in settings
- **THEN** **Vehicle sharing** is not offered on the app home
- **THEN** **Vehicle** remains available if `vehicle` is still enabled and entitled
