## ADDED Requirements

### Requirement: The relay's source, configuration, and schema are public
The relay's source code, deployment manifests, configuration templates, and database schema (including migrations) SHALL live in a public repository. Anything required to reproduce the deployment locally (image build files, compose / equivalent manifests, environment variable templates with secrets redacted) SHALL be reviewable in that repository.

#### Scenario: An external reviewer reproduces the deployment locally
- **WHEN** an external reviewer clones the public repository
- **THEN** they can build the relay image and run the documented compose / equivalent stack against a local data directory
- **THEN** they can compare the local deployment with the production documentation

### Requirement: Each deployed version maps to a tagged release
Every version of the relay running in production SHALL correspond to a tagged release in the public repository and an immutable container image digest. The mapping (tag ↔ digest ↔ deployment date) SHALL be discoverable in repository documentation (release notes, deployment log, or equivalent).

#### Scenario: Currently-deployed digest is traceable to a tag
- **WHEN** an external reviewer inspects the deployed container's image digest
- **THEN** they can find the matching tagged release in the repository
- **THEN** the release describes the changes from the previous deployed version

### Requirement: An external audit checklist lives in the repo
The repository SHALL contain a documented audit checklist (e.g., `docs/relay-audit-checklist.md`) that lists concrete, runnable checks an external reviewer can perform:
- DNS / TLS scope of the relay sub-domain,
- container image digest match,
- database schema vs documented schema diff,
- TTL configuration vs documented bounds,
- log sample inspection for absence of plaintext,
- metrics endpoint accessibility (private only),
- public surface enumeration (only the relay endpoint),
- operator action log presence and shape.

Each item SHALL include the expected outcome.

#### Scenario: Reviewer follows the checklist end-to-end
- **WHEN** an external reviewer runs the documented audit checklist
- **THEN** each item produces a pass / fail result with the expected outcome stated in the checklist
- **THEN** any failure is recorded as an audit finding

### Requirement: A periodic self-audit is performed and recorded
The operator SHALL perform a self-audit on a documented cadence (the spec requires at minimum **quarterly**). The self-audit SHALL run the public audit checklist (or its current equivalent) and SHALL record findings in a publicly readable location in the repository (release notes, audit log, or equivalent).

#### Scenario: Quarterly audit has a recent entry
- **WHEN** an external reviewer inspects the audit log
- **THEN** at least one audit entry exists within the last quarter
- **THEN** that entry summarizes the items checked and any findings

### Requirement: Audit findings are tracked and resolved transparently
Each audit finding SHALL be tracked in a publicly-visible mechanism (e.g., a repository issue, a section in the audit log) and SHALL move to resolved only after the underlying deviation has been corrected or explicitly accepted with a documented reason.

#### Scenario: An open finding is visible
- **WHEN** an audit identifies a deviation between documented and deployed behavior
- **THEN** a public record of the finding exists (issue / log entry) with description, identified date, and current status
- **THEN** the finding's resolution is also recorded publicly

### Requirement: Configuration drift between deployed and documented is itself a finding
If at any point the deployed configuration of the relay (TTL values, image digest, exposed surface, schema) differs from the publicly documented configuration, the difference SHALL be recorded as an audit finding even if the difference is intentional.

#### Scenario: Intentional config change is documented before it ships
- **WHEN** the operator changes a TTL value, an image digest, or any other deployed configuration
- **THEN** the public documentation is updated in the same change
- **THEN** the audit checklist is updated if the change affects audit expectations

### Requirement: Public claims about the relay are verifiable from the repo
Any public claim about the relay's privacy or security behavior (e.g., "the relay does not retain user payloads beyond delivery", "the relay does not store contact display names") SHALL be supported by repository artifacts that an external reviewer can inspect (schema files, migration files, configuration templates, audit checklist results).

#### Scenario: Claim and artifact alignment
- **WHEN** an external reviewer examines a public claim about the relay
- **THEN** they can locate the supporting artifact in the repository (schema, migrations, config, audit entries)
- **THEN** the artifact matches the claim

### Requirement: The audit posture applies from day one of public availability
The relay SHALL NOT be exposed to public traffic before the audit posture defined in this capability is in place: a public repository, a tagged release matching the deployed digest, an audit checklist, and a recorded baseline self-audit entry.

#### Scenario: Baseline audit precedes first public traffic
- **WHEN** the relay sub-domain becomes reachable for the first production handshake
- **THEN** the repository contains the audit checklist, the tagged release, and a baseline audit entry dated on or before that day
- **THEN** an external reviewer can locate all of the above without operator assistance
