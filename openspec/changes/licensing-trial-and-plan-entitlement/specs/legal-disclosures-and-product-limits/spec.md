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

