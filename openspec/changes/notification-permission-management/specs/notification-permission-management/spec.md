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

#### Scenario: Fresh install starts with app notifications off
- **WHEN** the app is installed or preferences are reset
- **THEN** the app-level master notification switch defaults to off
- **AND** category preferences may remain preselected but disabled until the master switch is enabled

#### Scenario: User turns app notifications on
- **WHEN** the user turns the app-level master notification switch on
- **AND** system notification permission is not granted
- **THEN** the system requests notification permission
- **AND** the app-level switch remains on only if system permission becomes granted or provisionally granted

#### Scenario: User turns app notifications off
- **WHEN** the user turns the app-level master notification switch off
- **THEN** the system disables the app-level notification preference
- **AND** the system does not attempt to revoke browser, Android, or iOS notification permission

#### Scenario: User revoked system permission outside the app
- **WHEN** the user opens notification settings
- **AND** the app-level master notification switch is on
- **AND** system notification permission is no longer granted or provisionally granted
- **THEN** the system updates the app-level master notification switch to off

#### Scenario: Notification settings opens while app notifications are off
- **WHEN** the user opens notification settings
- **AND** the app-level master notification switch is off
- **THEN** the system does not query system notification permission solely for stale-state reconciliation

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

### Requirement: Closed-app push registration follows app notification preferences
When closed-app push delivery is enabled for the product, routing push token registration on the relay SHALL be conditional on the app-level master notification switch and on at least one wake-eligible category preference. Turning the master switch off or disabling every wake-eligible category SHALL trigger unregister and SHALL suppress future registration until the user re-enables a wake-eligible setting. Wake pushes remain transport-only; local notification builders continue to honor category and master switches before surfacing user-visible alerts.

#### Scenario: Master switch off unregisters transport tokens
- **WHEN** the user turns the app-level master notification switch off
- **THEN** the client unregisters routing push tokens best-effort
- **AND** the client does not register again until the master switch and a wake-eligible category are both enabled

#### Scenario: All wake-eligible categories off prevents registration
- **WHEN** the master switch is on but every wake-eligible category is off
- **THEN** the client does not register routing push tokens on the relay

### Requirement: Developer Notification Diagnostics
The system SHALL provide a developer-only action to send a test notification so developers can verify the effective notification permission path.

#### Scenario: Developer sends a test notification
- **WHEN** a developer uses the Settings developer tool to send a test notification
- **AND** app notifications are enabled
- **AND** system notification permission is granted
- **THEN** the system sends a notification with title `TEST` and body `TEST`

#### Scenario: App notifications block the test notification
- **WHEN** a developer sends a test notification
- **AND** app notifications are disabled
- **THEN** the system does not send a notification
- **AND** the system reports that app notifications are disabled

#### Scenario: System permission blocks the test notification
- **WHEN** a developer sends a test notification
- **AND** app notifications are enabled
- **AND** system notification permission is not granted
- **THEN** the system does not send a notification
- **AND** the system reports that system notification permission is not granted
