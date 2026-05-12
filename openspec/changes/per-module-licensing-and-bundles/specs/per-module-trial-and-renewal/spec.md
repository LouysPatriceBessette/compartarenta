## ADDED Requirements

### Requirement: Each module has its own lifecycle state machine using the housing template
Each module SHALL have an instance of the entitlement lifecycle state machine specified in `licensing-trial-and-plan-entitlement` (states: `free` / `linked-not-active` / `active-trial` / `active-paid` / `delinquent-grace` / `delinquent-readonly`). Each module's instance SHALL evolve independently of other modules' instances.

#### Scenario: Modules can be in different lifecycle states
- **WHEN** the user's `housing` is in `active-paid` and `vehicle` is in `active-trial`
- **THEN** both states co-exist and progress independently
- **THEN** events affecting `vehicle` (e.g., trial expiry) do not transition `housing` state

### Requirement: Each module defines its own "active use" trigger that starts its trial
Each module SHALL define its own product-specific event that constitutes "active use" of that module — the trigger that transitions the module from `linked-not-active` to `active-trial`. For the housing module, the trigger remains the one defined in `free-until-active-plan-use`. Other modules SHALL define their own trigger in their own licensing change before they ship to production.

#### Scenario: Active use of housing does not start the vehicle trial
- **WHEN** housing's "active use" event occurs (per `free-until-active-plan-use`)
- **THEN** only `housing` transitions to `active-trial`
- **THEN** `vehicle` remains in whatever state it was in (e.g., `free`)

#### Scenario: A module without a defined active-use trigger cannot transition to active-trial
- **WHEN** a module has not yet documented its active-use trigger in its own licensing change
- **THEN** that module SHALL remain in `free` until its trigger is specified and shipped
- **THEN** the product does not silently start a trial for a module without a documented trigger

### Requirement: Each module has its own monthly renewal anchor date
Once a module is fully paid, its renewal anchor date SHALL be set per the rules in `per-participant-licenses-and-plan-renewal` applied **per module**. Renewal anchor dates SHALL NOT be shared across modules; each module's date is independent.

#### Scenario: Housing and vehicle renew on different dates
- **WHEN** a user paid `housing` on the 5th and `vehicle` on the 18th of a month
- **THEN** the `housing` renewal anchor date is the 5th and the `vehicle` renewal anchor date is the 18th
- **THEN** the app does not attempt to align these dates with one another

### Requirement: Each module's delinquency / grace / read-only timing is independent
The delinquency grace period, daily reminders, and read-only transition for a module SHALL be evaluated based only on that module's own payment events and timing. A delinquency event on one module SHALL NOT trigger any state transition on a different module.

#### Scenario: Vehicle delinquency does not affect housing operability
- **WHEN** the user enters `delinquent-grace` for `vehicle`
- **THEN** the `housing` module's state and operability remain unchanged
- **THEN** delinquency notifications, grace timing, and read-only entry are tracked per module

### Requirement: Each module reaches read-only export availability on its own terms
When a module is in `delinquent-readonly`, the export rules defined in `delinquency-grace-readonly-and-export` SHALL apply **to that module's data**. Export availability for other modules SHALL be governed by their own state and the per-module export rules in `module-enable-disable-and-data-isolation`.

#### Scenario: Vehicle read-only allows vehicle export while housing is fully usable
- **WHEN** `vehicle` is in `delinquent-readonly` and `housing` is in `active-paid`
- **THEN** the user can export `vehicle` data per the read-only export rule
- **THEN** the user can read and edit `housing` data normally

### Requirement: Per-module trial re-start is governed per module
Whether and how a user may re-start a trial for a given module SHALL be defined in that module's own licensing change (housing's rule lives in `licensing-trial-and-plan-entitlement`). The per-module model SHALL NOT define a shared "re-trial" policy across all modules.

#### Scenario: Trial re-start rules differ by module
- **WHEN** housing's re-trial rule differs from a future module's re-trial rule
- **THEN** the app honors each module's own rule independently
- **THEN** no module's trial state is altered as a side effect of another module's re-trial event

### Requirement: Bundle entitlement satisfies any included module's lifecycle "paid" requirement
A valid bundle receipt covering a module (per `bundle-product-mapping`) SHALL satisfy that module's payment requirement for the duration of the bundle's validity. The module's local lifecycle state machine SHALL treat the bundle's coverage as a valid source of `active-paid`, applying the "most favorable source wins" rule from `module-entitlement-model`.

#### Scenario: Bundle prevents housing from going delinquent during the bundle period
- **WHEN** a user holds a valid bundle covering `housing` and the bundle is in good standing
- **THEN** `housing` does not transition to `delinquent-grace` even if a standalone `housing` subscription (if any) lapsed
- **THEN** the user sees `housing` as active-paid sourced from the bundle
