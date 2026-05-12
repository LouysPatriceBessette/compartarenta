## ADDED Requirements

### Requirement: The relay is exposed on a dedicated sub-domain
The relay endpoint SHALL be reachable at a **dedicated sub-domain** of a domain controlled by the project (e.g., `relay.<example.tld>`). The sub-domain SHALL serve only the relay; it SHALL NOT be reused as a load-balancer alias for unrelated services hosted on the same VPS.

#### Scenario: The sub-domain serves only the relay
- **WHEN** an external observer connects to the relay sub-domain over HTTPS
- **THEN** the response originates from the relay process only
- **THEN** no unrelated service on the same host is reachable via that sub-domain

### Requirement: TLS is mandatory on the relay sub-domain
The relay SHALL serve only over TLS. Any plaintext HTTP exposure on the relay sub-domain SHALL exist only to redirect to HTTPS (or be absent entirely). TLS certificates SHALL be issued via an automated mechanism (e.g., ACME) and renewed automatically; renewal failures SHALL surface in monitoring.

#### Scenario: HTTPS-only endpoint
- **WHEN** a client attempts to connect to the relay over plaintext HTTP
- **THEN** either the connection is refused or it is redirected to HTTPS
- **THEN** the relay process does not accept relay protocol traffic on plaintext channels

#### Scenario: Certificate renewal is monitored
- **WHEN** the certificate's expiry approaches without successful renewal
- **THEN** monitoring raises an alert before expiry

### Requirement: TLS material is not shared with unrelated services
The TLS certificate and private key used for the relay sub-domain SHALL NOT be a wildcard certificate shared with unrelated services on the same VPS, and SHALL NOT be reused as the TLS material of any service unrelated to the relay.

#### Scenario: Relay TLS scope is isolated
- **WHEN** an auditor inspects the relay's certificate
- **THEN** the certificate's subject / SAN includes only the relay sub-domain (and any other names that are exclusively part of the relay deployment)
- **THEN** unrelated services on the same VPS use separate certificates

### Requirement: The relay process and its state database run in containers
The relay SHALL be deployed as one or more containers managed by a container runtime (Docker / Podman / Compose / Helm / equivalent). The state database used by the relay SHALL also run in a container, separate from the relay process container; both containers SHALL be defined in version-controlled deployment manifests.

#### Scenario: Deployment manifests reproduce the environment
- **WHEN** the operator deploys from version-controlled manifests on a fresh host
- **THEN** the resulting environment matches the documented topology (relay container, database container, named volumes, network rules)
- **THEN** no ad-hoc commands outside the manifests are required for routine operation

### Requirement: Persistent state lives on named volumes with documented retention
The relay's persistent state SHALL live exclusively on **named volumes** owned by the relay deployment. Bind-mounting host directories outside the documented data directory is forbidden. Volumes SHALL be documented with their purpose and retention policy (per `relay-state-schema-and-retention`).

#### Scenario: Volumes are enumerated and bounded
- **WHEN** an auditor inspects the running deployment
- **THEN** every persistent volume corresponds to a documented purpose in the relay project's documentation
- **THEN** no undocumented bind mounts are present

### Requirement: The database container is not reachable from the public internet
The database container's network port SHALL NOT be reachable from the public internet. It SHALL be accessible only from the relay container on a private network defined by the deployment manifests.

#### Scenario: Public probe to the database port is rejected
- **WHEN** an external scanner probes the database port on the host's public address
- **THEN** the probe receives no response from the database (the port is firewalled or not bound to the public interface)
- **THEN** only the relay container can reach the database

### Requirement: Admin access to the deployment uses an out-of-band channel
Administrative access to the host (SSH, container runtime control, database shell, log access) SHALL be reachable only via an out-of-band channel that is not the public relay endpoint. Operator addresses SHALL be restricted to a documented allow-list and/or a bastion host. There SHALL NOT be a public admin port on the relay sub-domain.

#### Scenario: Admin access is gated
- **WHEN** an external party attempts to reach an admin endpoint (e.g., a web admin UI, an unauthenticated container runtime API)
- **THEN** the connection is refused by network rules
- **THEN** legitimate administration requires SSH (or equivalent) through the documented allow-list / bastion

### Requirement: The relay is the only public surface exposed by the deployment
The relay deployment's public surface SHALL be limited to the relay protocol endpoint at the dedicated sub-domain. No metrics endpoint, no health endpoint usable by the public internet, and no inspection endpoint SHALL be publicly reachable. (Authenticated read-only access via a bastion or VPN is allowed.)

#### Scenario: No incidental public endpoints
- **WHEN** an external scanner enumerates the relay sub-domain
- **THEN** only the relay protocol endpoint responds
- **THEN** all other endpoints are either absent or unreachable from the public internet

### Requirement: The deployment image and configuration are pinned and reproducible
Each deployed version of the relay SHALL be identified by an immutable container image digest. The deployment manifests SHALL reference image digests (or tags pinned to specific digests) and SHALL be stored in the public repository. Configuration values used at deploy time SHALL be reviewable in the repository (with secrets templated out).

#### Scenario: Reviewer can match deployed digest to a repo manifest
- **WHEN** an external reviewer inspects the deployed container's digest
- **THEN** that digest matches the digest declared in the repository's deployment manifests for the current version
- **THEN** any difference is investigated as an audit finding

### Requirement: The deployment runs without unrelated workloads in relay containers
The relay container and the database container SHALL run **only** the relay's processes. They SHALL NOT host unrelated workloads (no co-tenant applications inside the same container).

#### Scenario: Containers are single-purpose
- **WHEN** an auditor inspects the running processes inside the relay containers
- **THEN** only the relay's expected processes are present
- **THEN** no unrelated daemons or applications run inside the relay containers
