## MODIFIED Requirements

### Requirement: V1 functional surface
The system SHALL initially wire the wake transport functionally only for Contacts add request envelopes. All other notification categories SHALL continue to operate exactly as before this change, including their existing polling-based local notification path and their existing app-level controls.

**Update (plan-mediated establishment change):** Functional wake handling SHALL also apply to `contactEstablishmentRequest` and `contactEstablishmentResponse` envelopes (plan-mediated peer pairing). Housing proposal envelopes may follow in later changes.

#### Scenario: Contacts add request triggers wake
- **WHEN** a peer submits a Contacts add request and the relay accepts the resulting envelope
- **THEN** the relay dispatches a wake push as described in this capability
- **AND** the receiving app, after polling and decrypting, surfaces the existing Contacts add request notification according to user preferences

#### Scenario: Plan-mediated establishment request triggers wake
- **WHEN** a `contactEstablishmentRequest` envelope is relay-accepted for a registered watch-list recipient
- **THEN** the target app may wake, poll, decrypt, and show the establishment notification per user preferences

#### Scenario: Other notification kinds remain on polling-only path
- **WHEN** the relay accepts an envelope whose business kind is not Contacts add request or plan-mediated establishment
- **THEN** the relay still dispatches a wake push if the recipient is registered, but no additional V1 client-side behavior is required beyond default poll-and-decrypt
- **AND** the existing polling-based local notification path continues to deliver these notifications without regression
