## ADDED Requirements

### Requirement: Play Console submission supports staged rollout
The release process SHALL support submission to Google Play with a staged rollout strategy and the ability to halt or roll back.

#### Scenario: Staged rollout begins
- **WHEN** a production release is promoted in Play Console
- **THEN** it is rolled out to a configured initial percentage of users and can be increased in steps

#### Scenario: Halt rollout
- **WHEN** a critical issue is discovered during rollout
- **THEN** the rollout can be paused/halted and the previous stable release remains available

### Requirement: Play tracks are used for internal testing and beta
The release process SHALL define how internal testing and beta testing are performed using Play tracks (internal/closed/open as appropriate).

#### Scenario: Internal test build distribution
- **WHEN** an internal test build is created
- **THEN** it is uploaded to the Play internal testing track and is accessible to the intended tester group

### Requirement: Play submission requirements are met
Each release SHALL include required Play Console fields and declarations, including Data safety, content rating, and target API level compliance.

#### Scenario: Release readiness check for Play
- **WHEN** preparing a production submission
- **THEN** all required Play declarations for the app’s current behavior are complete and consistent with the implemented data collection and permissions

