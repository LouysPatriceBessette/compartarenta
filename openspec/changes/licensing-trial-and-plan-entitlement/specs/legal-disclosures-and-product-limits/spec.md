## ADDED Requirements

### Requirement: The repository includes legal-related product behavior documentation
The repository SHALL include an English documentation page describing the app’s legal-adjacent behaviors and limits, including:

- that the app is not a law firm and does not provide legal advice,
- that participants are responsible for their own agreements,
- what the app does in payment-failure scenarios (grace, read-only, export),
- what the app does in participant-removal scenarios (differential impact report) and what it does not do (dispute adjudication).

#### Scenario: Documentation exists and is referenced from README
- **WHEN** the repository is public
- **THEN** `README.md` links to the legal/disclosures page

### Requirement: Disclose platform-managed payments and “In-App Purchases” labeling
The product documentation and in-app licensing screen MUST disclose that payments (licenses/subscriptions) are processed by the platform stores (Apple App Store / Google Play) and that the store listing may label this as “In‑App Purchases”. This disclosure MUST be written in reassuring language to reduce user anxiety about payments and data handling.

Store-supported promotional acquisition paths (such as offer-code or promo-code redemption) SHALL be described as alternative store-managed ways to obtain a valid entitlement, not as a separate product-side license class.

#### Scenario: Licensing screen reassures users about payments and data
- **WHEN** a user opens the licensing/trial screen
- **THEN** the screen explains that payment processing is handled by Apple/Google
- **THEN** the screen reassures that user operational data stays on-device and is not collected for advertising

### Requirement: Avoid scattered purchase prompts
The app MUST NOT present purchase prompts in unrelated contexts (e.g., random dialogs across the app) and SHOULD present purchase actions only in a dedicated licensing area (Settings or Data Management).

#### Scenario: Purchase action appears only in the dedicated area
- **WHEN** a user navigates the app during trial
- **THEN** purchase actions are reachable from the licensing area
- **THEN** the user is not repeatedly interrupted by purchase pop-ups

