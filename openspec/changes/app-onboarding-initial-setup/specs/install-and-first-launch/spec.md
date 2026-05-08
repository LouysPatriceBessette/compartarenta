## ADDED Requirements

### Requirement: First open after store install presents the first-run experience
When the user opens the application for the first time after installation from an official store build (or equivalent sideload in dev), the application SHALL present the first-run experience defined in `onboarding-flow` unless a documented exception applies (e.g., enterprise provisioning not used in this product).

#### Scenario: Cold start on first install
- **WHEN** the user launches the app and no onboarding completion record exists for this install
- **THEN** the app shows the onboarding entry screen rather than the main ledger shell as the primary destination

### Requirement: Subsequent launches skip completed onboarding
When onboarding and initial configuration have been completed according to persisted application state, a normal launch SHALL go directly to the main application shell (or the last primary destination), without forcing the full onboarding slideshow again.

#### Scenario: Returning user after completed setup
- **WHEN** the user opens the app and onboarding completion is recorded
- **THEN** the user is not presented with the full mandatory onboarding sequence again unless a product-defined “major version re-onboarding” or reset has occurred

### Requirement: App updates preserve user setup by default
Applying an application update from the store SHALL NOT reset onboarding completion or initial configuration without an explicit, user-visible migration reason (e.g., breaking schema requiring re-confirmation). If such a migration is required, the product SHALL document the behavior and provide a recovery path.

#### Scenario: Patch update preserves flags
- **WHEN** the user installs a patch update that does not include a documented setup reset
- **THEN** onboarding completion and initial configuration values remain in effect

### Requirement: First launch initialization avoids destructive defaults
The first launch path SHALL initialize local persistence safely (empty ledger, no sample production data unless the product explicitly offers opt-in demo data). The app SHALL not silently delete existing local data on first launch of a new install.

#### Scenario: Fresh install empty ledger
- **WHEN** the user completes first launch initialization on a new install
- **THEN** no accepted expense rows from a prior unrelated user exist in local storage

### Requirement: Unrecoverable local state surfaces a controlled path
If required local storage cannot be initialized (e.g., corruption detected on first run), the application SHALL show a clear error state with a retry or reset action and SHALL NOT enter an infinite blank screen.

#### Scenario: Storage initialization failure
- **WHEN** local persistence fails to initialize on cold start
- **THEN** the user sees an explanatory error UI with at least one recovery action
