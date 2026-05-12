## ADDED Requirements

### Requirement: The relay process runs with least privilege
The relay container SHALL run with a non-root user and a read-only root filesystem where the technology stack allows it. Writable paths SHALL be limited to documented data directories backed by named volumes.

#### Scenario: Container does not run as root
- **WHEN** an auditor inspects the running relay container
- **THEN** the relay process runs under a non-root user
- **THEN** the root filesystem is read-only, or the writable paths are explicitly documented and limited

### Requirement: Secrets are managed by an explicit secret store
TLS keys, database credentials, signing keys, and any other secrets SHALL be sourced from an explicit secret management mechanism (e.g., environment-injected secrets from a vault, mounted secret files with restricted permissions). Secrets SHALL NOT be committed to the repository and SHALL NOT be embedded in container images.

#### Scenario: Secrets are not in images or repo
- **WHEN** an auditor extracts the relay container image and scans the repository
- **THEN** no live secret appears in image layers or in repository content
- **THEN** secret material is only present at runtime, sourced from the secret manager

### Requirement: Secrets do not appear in logs
The relay SHALL NOT log secrets, credentials, full envelope ciphertext, or routing payload data. If structured logging includes context fields, those fields SHALL be limited to non-sensitive metadata (envelope ID, opaque identities, timing, error codes).

#### Scenario: Log review finds no secret material
- **WHEN** an auditor scans recent relay logs for known secret prefixes (e.g., the leading characters of a TLS key, a DB password)
- **THEN** no secret material appears in logs

### Requirement: Rate limiting protects the relay against abuse
The relay SHALL apply rate limits per source opaque identity and per source IP for both inbound envelope submissions and outbound fetch requests. Rate limits SHALL be documented values; clients exceeding them SHALL receive documented error responses.

#### Scenario: Excess inbound submissions are rate-limited
- **WHEN** a client (or a source IP) submits envelopes above the documented rate limit
- **THEN** the relay rejects subsequent submissions with a documented status code until the window resets
- **THEN** the rejection is recorded in metrics (counter incremented)

### Requirement: The relay validates incoming envelopes against the documented protocol
The relay SHALL validate the framing of incoming envelopes (size limits, required envelope fields, plausibility checks on opaque identities) and SHALL reject envelopes that do not match the documented protocol. Validation SHALL NOT include parsing or interpreting ciphertext.

#### Scenario: Malformed envelope is rejected
- **WHEN** a client submits an envelope that does not match the documented framing
- **THEN** the relay returns a documented validation error
- **THEN** the envelope is not stored

### Requirement: The relay applies a documented size limit per envelope
The relay SHALL enforce a documented maximum size for envelope ciphertext and for total request size. Oversized payloads SHALL be rejected without storing them.

#### Scenario: Oversize envelope is rejected
- **WHEN** a client submits an envelope exceeding the documented size limit
- **THEN** the relay rejects the request before persisting any data
- **THEN** the rejection is recorded in metrics

### Requirement: Dependency hygiene is enforced in the build pipeline
The relay's container image build SHALL include a dependency-audit step (e.g., a vulnerability scanner) that fails the build on known critical CVEs. The audit step and its threshold SHALL be documented.

#### Scenario: Critical CVE blocks the build
- **WHEN** a dependency in the relay's stack publishes a critical CVE
- **THEN** the next image build for the relay fails the audit step until the dependency is upgraded
- **THEN** the audit step's output is preserved as a build artifact

### Requirement: The host OS and runtime are patched on a documented cadence
The VPS host OS, container runtime, and any host-level dependencies SHALL be patched on a documented cadence (the spec requires at minimum monthly review, with critical security patches applied within a documented short window after disclosure). The cadence SHALL be recorded in the relay project's operational documentation.

#### Scenario: Operator can show patching status
- **WHEN** an auditor asks for the current OS / runtime patch status
- **THEN** the operator can produce evidence of the last patch run and the planned next run
- **THEN** the cadence matches what is documented

### Requirement: Abuse mitigations are documented and enforceable
The relay SHALL maintain a documented set of abuse mitigations beyond rate limiting, covering (at minimum): handling of repeated invalid envelopes from a source identity, handling of recipients that repeatedly fail to ack, and operator action for relationships flagged as abusive. Operator action SHALL leave an audit trail (recorded action, timestamp, reason).

#### Scenario: Operator action is auditable
- **WHEN** an operator removes a routing relationship due to abuse
- **THEN** the action is recorded with timestamp and reason in an operator action log
- **THEN** the log is preserved per the documented retention rules
