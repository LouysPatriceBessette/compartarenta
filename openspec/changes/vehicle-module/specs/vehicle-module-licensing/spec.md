## ADDED Requirements

### Requirement: Vehicle module trial is two weeks and starts on first active vehicle use
The `vehicle` module (`EV`) SHALL use a **2-week** trial period, consistent with the product-wide trial duration in `trial-notifications-and-timeline`. The trial SHALL start on the module-specific **active use** event for `vehicle` (first substantive owner-side use — e.g., first owned vehicle registered or first owner-side fact recorded; exact trigger documented before ship).

#### Scenario: Vehicle trial duration matches housing
- **WHEN** a user's `vehicle` module enters active trial
- **THEN** the trial length is 2 weeks, not 6 weeks

### Requirement: Vehicle-sharing has no trial period
The `vehicle-sharing` module (`PP` / `PE`) SHALL **not** offer any trial period. It SHALL NOT start its own trial when purchased or when a user first accepts or offers sharing. An active **`vehicle` module trial SHALL NOT** waive, extend, or substitute for a paid **`vehicle-sharing`** subscription on any device.

PP and PE operations require effective paid **`vehicle-sharing`** entitlement (or bundle coverage that includes `vehicle-sharing`) regardless of the Propriétaire's or Emprunteur's `vehicle` trial state.

#### Scenario: Borrower-only subscriber has no sharing trial
- **WHEN** an Emprunteur activates or uses `vehicle-sharing` without owning `vehicle`
- **THEN** no trial clock starts for `vehicle-sharing`
- **THEN** paid `vehicle-sharing` entitlement (or bundle coverage) is required for PE operations

#### Scenario: Owner vehicle trial does not unlock sharing without vehicle-sharing subscription
- **WHEN** a Propriétaire is in `active-trial` on `vehicle` and has not purchased `vehicle-sharing`
- **THEN** PP operations (offer sharing) remain blocked until `vehicle-sharing` is paid
- **THEN** an Emprunteur cannot accept or log usage (PE) on that vehicle without their own paid `vehicle-sharing` unless bundle coverage applies

### Requirement: Trial messaging uses consistent two-week copy
All user-visible trial messaging for `vehicle` SHALL reference a **2-week** trial. No surface SHALL mention a 6-week vehicle or housing trial. No surface SHALL imply that `vehicle-sharing` has a trial or is included free during the `vehicle` trial.

#### Scenario: Onboarding copy matches 2-week trial
- **WHEN** onboarding or licensing screens mention the real-mode trial
- **THEN** the duration stated is 2 weeks
- **THEN** `vehicle-sharing` is not described as trial-eligible or covered by the `vehicle` trial
