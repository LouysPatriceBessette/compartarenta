## ADDED Requirements

### Requirement: Delayed System Permission Prompt
The system SHALL NOT request system notification permission during initial app load or onboarding. The system SHALL request system notification permission only after an explicit user action that benefits from notifications.

#### Scenario: Initial app load does not request permission
- **WHEN** the user opens the app for initial setup
- **THEN** the system does not show a browser, Android, or iOS notification permission prompt

#### Scenario: Contact invitation can request permission
- **WHEN** the user clicks the Contacts invitation entry point and system notification permission is not granted
- **THEN** the system requests notification permission before continuing with the invitation flow

#### Scenario: Housing participant invitation can request permission
- **WHEN** the user clicks the Housing plan summary action to invite participants and system notification permission is not granted
- **THEN** the system requests notification permission before continuing with the participant invitation flow

### Requirement: Reusable Permission Entry Point
The system SHALL provide a reusable notification permission gate that can be invoked from multiple UI flows after a user action.

#### Scenario: A flow invokes the shared permission gate
- **WHEN** a notification-relevant flow needs permission before continuing
- **THEN** the flow uses the shared permission gate instead of directly calling platform permission APIs

#### Scenario: Permission already granted
- **WHEN** a flow invokes the shared permission gate and system notification permission is already granted
- **THEN** the system continues without showing another system permission prompt

### Requirement: Settings Notification Management
The system SHALL provide a Settings page where the user can inspect and manage notification preferences outside any specific flow.

#### Scenario: User opens notification settings
- **WHEN** the user opens Settings and selects Notifications
- **THEN** the system shows notification permission status, a general notification control, category controls, and sound controls

#### Scenario: User changes a category preference
- **WHEN** the user toggles a notification category in Settings
- **THEN** the system stores the app-level preference for that category

### Requirement: Notification Categories
The system SHALL model notification categories for peer-triggered Contacts and Housing events.

#### Scenario: Contacts categories are available
- **WHEN** the user opens notification settings
- **THEN** the system shows controls for Contacts add requests, disconnection notices, and unconsumed invitation expiration

#### Scenario: Housing categories are available
- **WHEN** the user opens notification settings
- **THEN** the system shows controls for received housing plan submissions, participant decision status changes, and non-unanimous plan offer expiration

### Requirement: Notification Sound Preferences
The system SHALL allow users to disable notification sounds. The system SHALL treat the platform default sound and silence as the portable baseline. The system SHALL NOT promise arbitrary device sound selection unless a platform-specific implementation can satisfy platform constraints without unsafe or unexpected additional permissions.

#### Scenario: User disables notification sound
- **WHEN** the user turns notification sound off
- **THEN** the system records that notifications should be shown without sound where platform capabilities allow

#### Scenario: Sound selection is unavailable
- **WHEN** the platform does not provide safe in-app device sound selection
- **THEN** the system does not require an additional permission solely to select a notification sound

#### Scenario: Bundled sound selection is introduced later
- **WHEN** the system offers selectable notification sounds
- **THEN** the selectable sounds are limited to app-provided or app-managed files that meet each platform's notification sound requirements

#### Scenario: Android sound behavior changes
- **WHEN** Android notification sound behavior changes after a channel has already been created
- **THEN** the system uses a new or versioned notification channel instead of assuming the existing channel can be modified programmatically

### Requirement: Peer-Triggered Notification Rule
The system SHALL generally associate notifications with peer-triggered events and SHALL NOT create a notification solely because the local user performed a local action.

#### Scenario: Local action completes
- **WHEN** the local user performs an action that only affects their local app state
- **THEN** the system does not create a local notification for that action

#### Scenario: Peer event is received
- **WHEN** the app receives a notification-relevant event triggered by a peer
- **THEN** the system can surface a notification according to system permission and app-level preferences
