## ADDED Requirements

### Requirement: Privacy policy exists and is accessible in-app and in store listings
The product SHALL publish a privacy policy that is accessible from within the app and linked in both store listings.

#### Scenario: In-app access to privacy policy
- **WHEN** the user opens Settings (or equivalent)
- **THEN** the user can open the privacy policy URL

#### Scenario: Store listing includes privacy policy
- **WHEN** preparing a store submission
- **THEN** the store listing includes the privacy policy URL and it resolves successfully

### Requirement: Data collection and sharing are declared accurately
The product SHALL maintain an explicit inventory of data collected/shared by the app and SHALL ensure store privacy disclosures match the inventory.

#### Scenario: Update privacy disclosures after changing telemetry
- **WHEN** telemetry, analytics, ads, or third-party SDKs change data collection behavior
- **THEN** the data inventory and store disclosures are updated before submission

### Requirement: Consent is collected where required
If the app uses functionality that requires user consent (e.g., tracking, personalized ads, region-specific requirements), the app SHALL collect consent prior to enabling that functionality.

#### Scenario: Consent required for optional tracking
- **WHEN** the app is configured to use tracking that requires consent
- **THEN** the user is prompted for consent before tracking begins and the choice is persisted

