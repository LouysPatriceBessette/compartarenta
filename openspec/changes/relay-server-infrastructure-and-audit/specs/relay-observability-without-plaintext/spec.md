## ADDED Requirements

### Requirement: The relay emits operational metrics sufficient for production operation
The relay SHALL emit operational metrics covering at minimum:
- request counts per endpoint (success / failure),
- envelope counts (accepted, delivered, expired-TTL),
- routing relationship counts (created, severed),
- sweeper runs (count, duration, items expired per run),
- queue depth and oldest-undelivered-age,
- container-level resource counters (CPU, RAM, disk I/O).

Metrics SHALL be queryable via a documented mechanism (e.g., a metrics endpoint on a private network).

#### Scenario: Operator can read queue health
- **WHEN** the operator queries the metrics endpoint
- **THEN** they receive current values for queue depth and oldest-undelivered-age
- **THEN** they can determine whether the relay is healthy without inspecting envelope content

### Requirement: Logs do not contain user-content plaintext
The relay's logs SHALL NOT contain envelope ciphertext bodies, recipient mapping payloads, or any user-facing content. Logs MAY contain envelope IDs, opaque sender/recipient identifiers, timestamps, response codes, and error classifications.

#### Scenario: Log entry shows opaque identifiers only
- **WHEN** the relay logs a delivery event
- **THEN** the log line contains the envelope ID, opaque sender/recipient identifiers, timestamp, and outcome
- **THEN** the log line does NOT contain the ciphertext, a contact display name, or any module-specific data

### Requirement: Logs do not persist client IP addresses as relay state
Access logs MAY incidentally capture client IP addresses (as part of standard reverse-proxy logging), but client IP addresses SHALL NOT be persisted as part of the relay database schema (per `relay-state-schema-and-retention`). Access log retention SHALL be bounded by a documented rotation policy.

#### Scenario: IP addresses are not in the relay DB
- **WHEN** an auditor inspects the relay database
- **THEN** no table column stores client IP addresses as relay state
- **THEN** access logs containing IPs are rotated per the documented policy and do not migrate into the database

### Requirement: The metrics endpoint is not publicly reachable
The metrics endpoint SHALL NOT be reachable from the public internet. Access SHALL require a documented out-of-band channel (e.g., SSH-tunneled access, an internal VPN, or an authenticated read-only scraper from a documented allow-list).

#### Scenario: Public probe to metrics endpoint fails
- **WHEN** an external party probes the relay sub-domain for a standard metrics path
- **THEN** the metrics path is not exposed publicly
- **THEN** internal collectors retrieve metrics through the documented private channel

### Requirement: Health checks distinguish liveness from readiness without leaking state
The relay MAY expose a liveness/readiness check usable by the container runtime, but the response SHALL be limited to a small documented set of values (e.g., "ok", "starting", "degraded") and SHALL NOT include user-content metadata. The endpoint SHALL NOT be publicly enumerable in a way that leaks queue contents.

#### Scenario: Health check returns only operational state
- **WHEN** the container runtime probes the health endpoint
- **THEN** the response contains only the documented operational state
- **THEN** the response carries no envelope IDs, opaque identities, or queue contents

### Requirement: Operator action logs are separate from envelope logs
Operator actions (e.g., severing a routing relationship for abuse, redeploying, applying schema migrations) SHALL be recorded in an **operator action log** distinct from envelope and access logs. Each operator action SHALL include timestamp, actor, action, and reason.

#### Scenario: Operator action is auditable
- **WHEN** an operator performs an action affecting the deployment
- **THEN** the operator action log records timestamp, actor identifier, action description, and reason
- **THEN** envelope and access logs are not used as a substitute for this log

### Requirement: Observability does not require collecting personally-identifying information
The relay's metrics, logs, and tracing SHALL be sufficient to operate the service without collecting personally-identifying information about users (no real names, no emails, no contact-derived identifiers). Opaque routing identifiers are not considered personally-identifying for the purposes of this requirement, because they are derived from cryptographic material that itself is not personally-identifying (per `relay-state-schema-and-retention`).

#### Scenario: Observability stack contains no PII
- **WHEN** an auditor reviews the observability stack (metrics, logs, tracing)
- **THEN** no field contains a user's real name, email, phone number, or other personally-identifying contact metadata

### Requirement: Alerting thresholds are documented
Operational alerts SHALL be documented in the relay project's operational documentation, including thresholds (e.g., queue depth above N for M minutes, sweeper failure, TLS cert renewal failure, abnormal error rate). Alert recipients SHALL be documented at the role level (e.g., "operator on-call"), not at a personal-data level.

#### Scenario: Alerting documentation matches deployed alerts
- **WHEN** an auditor compares the documented alerts with the alerts configured on the deployed system
- **THEN** the configured alerts match the documented set
- **THEN** any difference is treated as an audit finding
