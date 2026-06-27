## ADDED Requirements

### Requirement: Vehicle module trial is two weeks and starts on first active vehicle use
The `vehicle` module (`EV`) SHALL use a **2-week** trial period, consistent with the product-wide trial duration in `trial-notifications-and-timeline`. The trial SHALL start on the module-specific **active use** event for `vehicle` (first substantive owner-side use — e.g., first owned vehicle registered or first owner-side fact recorded; exact trigger documented before ship).

#### Scenario: Vehicle trial duration matches housing
- **WHEN** a user's `vehicle` module enters active trial
- **THEN** the trial length is 2 weeks, not 6 weeks

### Requirement: Vehicle-sharing has no standalone trial
The `vehicle-sharing` module (`PP` / `PE`) SHALL **not** start its own trial period when purchased or when a user first accepts or offers sharing.

#### Scenario: Borrower-only subscriber has no sharing trial
- **WHEN** an Emprunteur activates `vehicle-sharing` without owning `vehicle`
- **THEN** no 2-week trial clock starts for `vehicle-sharing` alone
- **THEN** paid entitlement (or bundle coverage) is required for PE operations after any applicable free tier rules

### Requirement: Vehicle trial includes sharing at no extra charge
While the Propriétaire's **`vehicle` module is in `active-trial`**, **PP and PE operations SHALL be permitted without a paid `vehicle-sharing` subscription** on the devices involved in that trial relationship. This applies to:

- a Propriétaire exercising PP during their own vehicle trial;
- an Emprunteur exercising PE on a vehicle offered by a Propriétaire who is in vehicle trial;
- a **bundle** that includes both modules during the vehicle trial window.

Once the vehicle trial ends without payment, normal paid rules for `vehicle` and `vehicle-sharing` apply independently per `vehicle-sharing-licensing-and-delinquency`.

#### Scenario: Sharing works during owner vehicle trial without sharing subscription
- **WHEN** a Propriétaire is in `active-trial` on `vehicle` and has not purchased `vehicle-sharing`
- **THEN** the Propriétaire may offer a specific vehicle to a connected Emprunteur (PP)
- **THEN** the Emprunteur may accept and log usage (PE) during the Propriétaire's vehicle trial without their own paid `vehicle-sharing` unless otherwise required after trial end

### Requirement: Trial messaging uses consistent two-week copy
All user-visible trial messaging for `vehicle` SHALL reference a **2-week** trial. No surface SHALL mention a 6-week vehicle or housing trial.

#### Scenario: Onboarding copy matches 2-week trial
- **WHEN** onboarding or licensing screens mention the real-mode trial
- **THEN** the duration stated is 2 weeks
