## ADDED Requirements

### Requirement: Closed-app wake transport
The system SHALL provide a closed-app push transport that lets the relay wake the client app on Android and iOS so the app can poll the relay, decrypt envelopes locally, and surface notifications through the existing on-device notification builders. The wake transport SHALL be designed as a generic mechanism reusable for all current and future notification kinds.

#### Scenario: Relay envelope arrives for a registered recipient
- **WHEN** the relay accepts and persists an envelope for a recipient routing id
- **AND** at least one non-expired routing push token is registered for that recipient
- **THEN** the relay dispatches a wake push to every registered routing push token for that recipient

#### Scenario: Relay envelope arrives for an unregistered recipient
- **WHEN** the relay accepts and persists an envelope for a recipient routing id
- **AND** no non-expired routing push token is registered for that recipient
- **THEN** the relay does not dispatch any wake push and continues normal envelope persistence

#### Scenario: Closed app receives wake push
- **WHEN** an Android or iOS device receives a wake push for its recipient routing id while the app is closed
- **THEN** the device launches the app background isolate
- **AND** the app polls the relay, decrypts pending envelopes, and surfaces a local notification using the existing on-device notification builder

### Requirement: Wake push payload is data-only and content-free
The system SHALL ensure that wake push payloads contain no plaintext business content. The relay SHALL emit only a `kind` discriminator and the target recipient routing id. The relay SHALL NOT include envelope identifiers, sender identity, business-domain metadata, or human-readable strings derived from envelope contents.

#### Scenario: Wake payload minimal shape
- **WHEN** the relay dispatches a wake push
- **THEN** the push body contains at most a payload kind, the recipient routing id, and an optional schema version field
- **AND** the push body does not contain envelope ciphertext, envelope identifiers, sender identifiers, business-domain message types, expense amounts, contact display names, or any plaintext title or body derived from envelope content

#### Scenario: iOS degraded mode generic alert
- **WHEN** the relay is configured to ship a generic alert because iOS data-only delivery is being throttled
- **THEN** the alert text is a constant, non-personalized string that does not depend on envelope content
- **AND** the localized user-facing string is owned and shown by the mobile app, not embedded by the relay

### Requirement: V1 functional surface
The system SHALL initially wire the wake transport functionally only for Contacts add request envelopes. All other notification categories SHALL continue to operate exactly as before this change, including their existing polling-based local notification path and their existing app-level controls.

#### Scenario: Contacts add request triggers wake
- **WHEN** a peer submits a Contacts add request and the relay accepts the resulting envelope
- **THEN** the relay dispatches a wake push as described in this capability
- **AND** the receiving app, after polling and decrypting, surfaces the existing Contacts add request notification according to user preferences

#### Scenario: Other notification kinds remain on polling-only path
- **WHEN** the relay accepts an envelope whose business kind is not Contacts add request
- **THEN** the relay still dispatches a wake push if the recipient is registered, but no additional V1 client-side behavior is required
- **AND** the existing polling-based local notification path continues to deliver these notifications without regression

### Requirement: Platform scope
The system SHALL implement closed-app push delivery on Android via FCM HTTP v1 and on iOS via APNs. Web push SHALL NOT be implemented.

#### Scenario: Android registration uses FCM
- **WHEN** an Android client registers for closed-app push delivery
- **THEN** the registration is recorded with provider `fcm` and an FCM registration token

#### Scenario: iOS registration uses APNs
- **WHEN** an iOS client registers for closed-app push delivery
- **THEN** the registration is recorded with provider `apns` and an APNs device token

#### Scenario: Web is not registered
- **WHEN** the app runs on web
- **THEN** the client SHALL NOT call the closed-app push registration endpoints
- **AND** the relay SHALL NOT accept registrations whose provider value is reserved for web push

### Requirement: Multi-device fan-out
The system SHALL support multiple non-expired routing push tokens per recipient routing id. The relay SHALL dispatch a wake push to every registered token for the recipient on each qualifying envelope.

#### Scenario: User has two active devices
- **WHEN** a single recipient routing id has one active FCM token and one active APNs token
- **THEN** the relay dispatches one wake push per registered token, in parallel, when an envelope arrives

#### Scenario: Per-token dispatch failure does not block others
- **WHEN** dispatch to one of several registered tokens fails
- **THEN** the relay still attempts dispatch to the remaining tokens
- **AND** the per-token error is logged with provider and error class but without envelope context

### Requirement: Routing push token registration
The system SHALL expose explicit registration and unregistration endpoints on the relay. Registration SHALL be authenticated to bind the token to the holder of the recipient routing identity, using the same mechanism that authenticates envelope ingestion for that routing id. Each registration SHALL set or refresh an `expires_at` based on a configured time-to-live.

#### Scenario: Authenticated registration is accepted
- **WHEN** an authenticated client posts a registration request with provider, push token, and recipient routing id
- **THEN** the relay creates or refreshes a row in the routing push token store
- **AND** the relay returns the resulting `expires_at` so the client can schedule keep-alive refresh

#### Scenario: Unauthenticated registration is rejected
- **WHEN** a registration request arrives without valid authentication for the supplied recipient routing id
- **THEN** the relay rejects the request and does not store any data

#### Scenario: Client unregisters
- **WHEN** the client posts an unregister request for an existing (recipient, provider, push token) tuple
- **THEN** the relay deletes the corresponding row

### Requirement: Strict TTL on routing push tokens
The system SHALL enforce a hard time-to-live on every routing push token row. The relay SHALL purge rows whose `expires_at` has passed. The relay SHALL NOT extend TTL automatically beyond the configured maximum even if the client refreshes aggressively.

#### Scenario: TTL expiry triggers purge
- **WHEN** a routing push token row reaches its `expires_at` and the client has not refreshed
- **THEN** the relay purges the row during the next purge cycle or on the next access, whichever comes first

#### Scenario: Refresh resets TTL
- **WHEN** an authenticated client refreshes a registration before `expires_at`
- **THEN** the relay updates `expires_at` to now plus the configured TTL
- **AND** the relay updates `last_seen_at`

#### Scenario: Token reported invalid by provider is purged
- **WHEN** the FCM or APNs provider returns a permanent error indicating the token is no longer valid
- **THEN** the relay purges the corresponding row promptly, without waiting for TTL expiry

### Requirement: Client-side keep-alive
The system SHALL implement a client-side keep-alive that opportunistically refreshes routing push token registrations while the device is genuinely active. The keep-alive SHALL refresh on app cold start, on foreground resume, on receipt of a wake push, on FCM/APNs token rotation, and on opportunistic background execution scheduled through the platform background task APIs.

#### Scenario: App foreground triggers refresh
- **WHEN** the app moves to the foreground and has previously registered a routing push token
- **THEN** the client refreshes the registration if more than a configured fraction of the TTL has elapsed since the last refresh

#### Scenario: Background task refresh succeeds
- **WHEN** the OS executes the app's scheduled background refresh task
- **AND** the device still has system notification permission
- **AND** network is available
- **THEN** the client refreshes the registration and reschedules the next background task

#### Scenario: Background task is denied or throttled
- **WHEN** the OS does not schedule the background refresh task within the planned window
- **THEN** the client SHALL NOT block other functionality
- **AND** the registration SHALL be refreshed on the next foreground resume or wake push, whichever happens first

#### Scenario: Token rotation triggers re-registration
- **WHEN** FCM or APNs reports a new push token to the client
- **THEN** the client SHALL unregister the previous token and register the new token

### Requirement: Natural expiry on inactivity, uninstall, or permission revocation
The system SHALL ensure that an uninstalled app, a powered-off device, or a device whose OS notification permission has been revoked causes the routing push token to expire silently within at most one TTL cycle, with no special server-side detection logic required.

#### Scenario: Uninstalled app expires silently
- **WHEN** the app is uninstalled and no client refresh occurs for the duration of the TTL
- **THEN** the relay purges the corresponding row at `expires_at`

#### Scenario: OS revoked permission expires silently
- **WHEN** the user revokes notification permission in OS settings and the client cannot deliver an unregistration request
- **THEN** the next provider dispatch will return a permanent error
- **AND** the relay purges the row promptly per the TTL provider-error rule

#### Scenario: Device offline longer than TTL expires silently
- **WHEN** the device is offline for longer than one TTL cycle and no refresh occurs
- **THEN** the relay purges the row at `expires_at`

### Requirement: Aggregate-only operator metrics
The system SHALL allow operators to derive aggregate active-device counts from `last_seen_at`. The relay SHALL NOT expose per-row `last_seen_at` data outside the dispatch path. The relay SHALL NOT join routing push token data with subscription or audit records beyond what is required for purge and dispatch.

#### Scenario: Operator views active-device counts
- **WHEN** an operator queries the configured metrics surface
- **THEN** the relay reports counts of active devices over standard time windows (e.g., 1 day, 7 days, 30 days) and counts by provider
- **AND** the relay does not report per-row identifiers in those metrics

#### Scenario: Routing push table is not joined with subscription data
- **WHEN** the relay processes a subscription validation or any other server-side operation outside push dispatch
- **THEN** the operation SHALL NOT read or join the routing push token table

### Requirement: User control governs wake registration
The system SHALL make closed-app push registration conditional on the app-level master notification switch and on the relevant category preferences. When a user disables the master switch or disables every wake-eligible category, the client SHALL unregister and SHALL NOT re-register until the user re-enables a wake-eligible setting.

#### Scenario: Master switch off prevents registration
- **WHEN** the app-level master notification switch is off
- **THEN** the client SHALL NOT register a routing push token
- **AND** the client SHALL unregister any previously registered token for this device

#### Scenario: User turns the master switch off after a previous registration
- **WHEN** the user turns the master switch off
- **THEN** the client unregisters the routing push token best-effort
- **AND** if unregistration cannot reach the relay, the registration expires naturally at TTL

#### Scenario: Wake-eligible category preference governs registration
- **WHEN** every wake-eligible notification category is disabled
- **THEN** the client SHALL NOT register a routing push token, even if the master switch is on

### Requirement: Wake dispatch is best-effort and never blocks envelope delivery
The system SHALL treat wake push dispatch as a best-effort side effect of envelope persistence. A wake push dispatch failure SHALL NOT prevent envelope persistence, SHALL NOT prevent retrieval through polling, and SHALL NOT affect any other envelope semantics.

#### Scenario: Push provider unreachable
- **WHEN** the FCM or APNs provider is temporarily unreachable
- **THEN** the relay logs the dispatch failure
- **AND** the relay still persists the envelope normally and serves it via polling

#### Scenario: Push provider rate-limited
- **WHEN** the push provider rate-limits the relay
- **THEN** the relay backs off and may drop wake dispatches as a load-shedding measure
- **AND** the envelope still becomes available via polling

### Requirement: Documented operational configuration
The system SHALL require the relay deployment documentation, the relay state schema documentation, and the relay audit checklist to be updated to describe routing push tokens, their TTL, their purge job, and the FCM and APNs credentials needed for dispatch.

#### Scenario: Deployment documentation describes credentials
- **WHEN** the change ships
- **THEN** the relay deployment documentation lists `FCM_SERVICE_ACCOUNT_JSON_PATH`, the APNs auth key path, key id, team id, bundle id, and environment selection, and explains where these secrets must live in production

#### Scenario: Audit checklist covers the routing push table
- **WHEN** the change ships
- **THEN** the relay audit checklist contains items asking the reviewer to confirm the routing push table schema, TTL enforcement, and the absence of extra columns beyond those specified in this capability
