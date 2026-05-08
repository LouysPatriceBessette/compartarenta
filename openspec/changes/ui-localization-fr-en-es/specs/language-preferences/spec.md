## ADDED Requirements

### Requirement: User can change app language at any time
The system SHALL provide a preferences panel where the user can change the app language at any time.

#### Scenario: User switches from English to Spanish
- **WHEN** the user selects ES in preferences
- **THEN** the app updates to Spanish without requiring an app restart

### Requirement: App uses platform locale by default
If the user has not explicitly selected a language, the system SHOULD use the platform locale as the default app language when it matches a supported language.

#### Scenario: Platform locale French is used by default
- **WHEN** the user has no saved language preference
- **AND** the platform locale is FR
- **THEN** the app displays UI in French

### Requirement: Persist the user’s language override
When a user selects a language in preferences, the system MUST persist this selection and apply it on subsequent app launches until the user changes it.

#### Scenario: Selected language persists across relaunch
- **WHEN** the user sets the language to FR
- **AND** the user closes and reopens the app
- **THEN** the app displays UI in FR

