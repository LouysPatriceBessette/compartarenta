## ADDED Requirements

### Requirement: Android signing uses Play App Signing with secure key handling
Android releases SHALL be compatible with Google Play App Signing and SHALL keep signing keys out of source control.

#### Scenario: Produce a release artifact for Play
- **WHEN** a production Android build is produced
- **THEN** it outputs an Android App Bundle (AAB) suitable for Play Console upload and is signed according to the configured signing strategy

#### Scenario: Signing material is not committed
- **WHEN** the repository history is inspected
- **THEN** no keystore files, private keys, or raw signing certificates are present

### Requirement: iOS signing and provisioning supports CI builds
iOS releases SHALL be buildable in CI using managed credentials (certificates, provisioning profiles) with least-privilege access.

#### Scenario: CI builds iOS production artifact
- **WHEN** CI runs the iOS production build
- **THEN** it produces an IPA suitable for TestFlight/App Store submission without manual code signing steps on the CI host

### Requirement: Secrets are stored and rotated safely
Signing and submission credentials SHALL be stored in approved secret storage and SHALL have documented rotation and revocation steps.

#### Scenario: Credential rotation
- **WHEN** credentials are rotated
- **THEN** the build pipeline remains functional and the previous credentials are revoked or invalidated

