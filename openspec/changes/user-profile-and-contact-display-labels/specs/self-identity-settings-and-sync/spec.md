## ADDED Requirements

### Requirement: The user can edit their own display name after initial setup
The app SHALL provide a Settings (or equivalent preferences) surface where the user may change their **own** display name after onboarding, **except** when blocked by an open housing vote per `housing-plan-proposal-offer-flow` (display-name changes only; avatar edits remain allowed). The same validation rules that apply during `initial-configuration` (length, allowed characters, empty-name policy) SHALL apply to edits when not blocked.

#### Scenario: User updates display name from Settings
- **WHEN** the user saves a new non-empty valid display name in Settings and no housing vote blocks the change
- **THEN** the app persists it as the authoritative **self** display name for this device
- **THEN** subsequent handshakes, profile updates, and local UI use the updated value
- **THEN** every local housing roster row whose id ends with `:self` is updated to match

#### Scenario: Display name change blocked during open housing vote
- **WHEN** the user is on the roster of a housing plan with an open vote on this device and attempts to change only their display name in Settings
- **THEN** save is disabled with an explanation listing the blocking plan(s)
- **THEN** no `profile_update` broadcast that changes display name is sent

### Requirement: The user can edit their own avatar after initial setup
The app SHALL allow the user to change their **own** avatar selection in Settings using the same avatar vocabulary as `initial-configuration` (or a documented superset). The avatar identifier SHALL be persisted locally as part of self-identity.

#### Scenario: User updates avatar from Settings
- **WHEN** the user picks a different avatar in Settings
- **THEN** the app persists the new avatar identifier as authoritative for this device
- **THEN** local UI reflects the change immediately

### Requirement: Self-identity changes propagate to connected peers
When the user changes their display name or avatar, the app SHALL enqueue **canonical self** updates to every **connected** contact using the existing encrypted **profile-update** mechanism defined in `contact-handshake-over-relay`, **except** that a **display-name** change MUST NOT be broadcast while an open housing vote blocks self rename per `housing-plan-proposal-offer-flow`. **Avatar-only** changes SHALL still broadcast during such votes. Disconnected or blocked contacts SHALL NOT receive updates until connection rules allow delivery again.

#### Scenario: Connected peer receives profile update
- **WHEN** the user changes their display name or avatar and at least one connected peer exists, and housing vote rules allow the change (display name) or the edit is avatar-only
- **THEN** each connected peer’s device receives an encrypted profile-update (or successor envelope in the same class) carrying the new canonical fields
- **THEN** each peer’s stored **canonical** fields for this user are updated per `contact-peer-display-ownership`

### Requirement: Self-identity is not editable by remote contacts
No remote user SHALL change another user’s canonical display name or avatar through Contacts UI or relay messages except by delivering **their own** profile-update payloads from **their own** device. Requirements for how recipients merge those updates with **local display labels** belong to `contact-peer-display-ownership`.

#### Scenario: Peer cannot push a name onto the user
- **WHEN** a malicious or buggy peer sends an envelope that attempts to set the local user’s self display name
- **THEN** the app ignores it for self-identity (and follows hardening rules in `end-to-end-encryption` / message-type validation)
