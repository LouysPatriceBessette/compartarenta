## ADDED Requirements

### Requirement: App provides a store-publishable MVP UX
The app SHALL provide a coherent MVP user experience that is usable without hidden setup steps and is consistent across Android and iOS.

#### Scenario: First launch without prior state
- **WHEN** the user opens the app for the first time
- **THEN** the app shows an onboarding or landing experience that clearly indicates what the app does and what the user can do next

#### Scenario: App handles loading states
- **WHEN** the app is waiting on any network-dependent data to render a screen
- **THEN** the app shows an explicit loading state and remains responsive

### Requirement: App handles error and offline conditions gracefully
The app SHALL handle network failures, timeouts, and offline conditions without crashes and with clear user messaging.

#### Scenario: Network request fails
- **WHEN** a network request fails for a user-visible operation
- **THEN** the app shows a non-technical error message and offers a retry action when retry is safe

#### Scenario: Device is offline
- **WHEN** the device has no network connectivity
- **THEN** the app indicates offline status and avoids repeated failing requests in a tight loop

### Requirement: App includes a basic settings surface suitable for store review
The app SHALL provide a settings surface that includes at minimum app version information and links required by policy (e.g., privacy policy).

#### Scenario: View app version
- **WHEN** the user opens Settings
- **THEN** the app displays the app version and build number

#### Scenario: Access privacy policy
- **WHEN** the user taps the privacy policy link in Settings
- **THEN** the app opens the privacy policy URL in an in-app browser or external browser

### Requirement: App avoids unnecessary permissions
The app SHALL NOT request OS permissions unless required for an explicitly user-initiated feature.

#### Scenario: No permission prompts on first launch
- **WHEN** the user opens the app for the first time
- **THEN** the app does not prompt for any OS permissions unless needed to complete a user action started in the app

