## ADDED Requirements

### Requirement: TestFlight distribution supports beta validation
The release process SHALL support distributing iOS builds via TestFlight to validate functionality prior to App Store submission.

#### Scenario: Upload build to TestFlight
- **WHEN** a beta iOS build is created
- **THEN** it is uploaded to App Store Connect and becomes available in TestFlight to the configured tester groups

### Requirement: App Store submission is repeatable with required review artifacts
Each App Store submission SHALL include required metadata and review artifacts (e.g., review notes, demo account credentials if needed, support URLs, privacy policy link).

#### Scenario: Submission includes review notes
- **WHEN** the app requires special instructions to access key functionality
- **THEN** the submission includes review notes that allow reviewers to validate the app without guesswork

### Requirement: Release supports phased rollout and rapid mitigation
The release process SHALL support a controlled rollout strategy and rapid mitigation steps in case of issues.

#### Scenario: Phased release enabled
- **WHEN** a production iOS release is approved
- **THEN** it can be released using a phased release strategy (where supported) or a controlled release schedule

#### Scenario: Remove from sale
- **WHEN** a critical issue is discovered post-release
- **THEN** the app can be removed from sale and/or the affected version can be superseded via an expedited hotfix release process

