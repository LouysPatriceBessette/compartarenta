## Context

`privacy-first-sync-architecture` defines the **product semantics** the relay must satisfy: encrypted-only payloads, no plaintext access by the server, no durable retention after successful delivery, TTL-bounded retention on failure, idempotency without content logging, and a proposal/accept/reject pattern that lives on clients. It does not pin down where the relay runs, how it is packaged, what its small piece of persistent state looks like in concrete terms, or how a third party can verify that a deployed instance honors those promises. This change supplies that deployment-and-audit layer.

The starting constraints are practical:

- We have an existing VPS we want to reuse, and we want the relay to be reachable via a **dedicated sub-domain** of an existing domain we already control.
- We want to ship state as a database **inside a container** (Docker), so the relay's persistent footprint is well-bounded and reproducible.
- We must be auditable **from day one** — both because `threat-model-and-verifiability` requires it, and because we plan to make privacy claims publicly that should be checkable, not just stated.

This change is a precondition for `contacts-module` because the Contacts handshake is the first feature that actually requires the relay to be running.

## Goals / Non-Goals

**Goals:**

- Specify the deployment topology of the relay (sub-domain, TLS edge, container packaging, isolation from co-tenant services).
- Specify what the relay's database stores and, just as importantly, what it must NOT store.
- Specify TTLs, idempotency windows, and the precise events that delete relay state.
- Specify a security baseline (exposed surface, secrets, admin access, rate limiting, dependency hygiene).
- Specify the observability surface (logs, metrics) in a way that preserves the no-plaintext promise.
- Specify an audit posture: documentation, versioned configuration, and external-reviewer surfaces.

**Non-Goals:**

- Choosing a specific programming language or framework for the relay implementation. Spec stays language-agnostic; implementation details belong in the relay project's README.
- Vendor lock-in to a specific VPS provider, registrar, or CDN.
- Specifying client-side handshake protocol details (that lives in `contacts-module`).
- Defining business-domain rules of housing/vehicle modules. The relay is module-agnostic.
- Sub-domain branding / SEO / public marketing — outside the spec surface.

## Decisions

### Decision: Dedicated sub-domain, isolated TLS, no shared admin scope

The relay lives at a **dedicated sub-domain** of an existing controlled domain (e.g., `relay.<example.tld>`), with its own TLS certificate (auto-renewed, e.g., ACME). The relay's certificate and admin surface SHALL NOT be shared with unrelated services on the same VPS (no wildcard cert reuse with marketing sites, no shared reverse-proxy admin).

Rationale:

- Auditable boundary: someone reviewing the relay's TLS chain sees only the relay.
- Reduces blast radius if an unrelated service on the same host is compromised.
- Lets the sub-domain be moved to a separate VPS later without churning other services.

Alternatives considered:

- **Path under an existing domain (e.g., `example.tld/relay/`)**: rejected. A separate sub-domain makes claims (CT logs, CSP, cert pinning if ever used) cleaner.
- **Own apex domain**: overkill at this stage; can be revisited if the relay becomes a standalone product.

### Decision: Containerized deployment, named-volume persistence only

The relay process and the relay database run as **containers** managed by a container runtime (Docker, Podman, or Compose-equivalent). Persistent state lives on **named volumes** with explicit retention and backup rules. No bind-mount of host paths outside the documented data directory.

Rationale:

- Reproducibility: an external reviewer can pull the same image tag and recreate the deployment locally.
- Containment: the database file system is not entangled with the host's filesystem layout.
- Upgradeability: rolling forward to a new image tag is a documented, scripted operation.

### Decision: Relay state schema is minimal and explicitly enumerated

The relay database stores only:

1. **Routing relationships**: opaque (identity_A, identity_B, established_at, status) records that let the relay accept message addressed-to mappings between users who completed a handshake. No display names, no avatars, no email, no phone.
2. **Idempotency entries**: (idempotency_key, sender_identity, created_at, ttl_expires_at) — bounded TTL.
3. **Undelivered ciphertext envelopes**: (envelope_id, sender_identity, recipient_identity, ciphertext_blob, created_at, ttl_expires_at, delivered_at NULL-until-delivered).
4. **Operational counters** in metrics storage (NOT in the relay DB) for health observability.

The schema SHALL NOT contain: payload plaintext, contact display name, contact avatar, expense amounts, expense categories, location data, device hardware identifiers beyond what is needed for delivery, user email/phone, user IP addresses (logs may incidentally capture IPs but the DB SHALL NOT persist them as relay state).

Rationale:

- Defines the audit ceiling in concrete terms: anything outside this list in the DB is a deviation.
- Makes the no-plaintext promise enforceable by inspecting the schema and the deployed migrations.

### Decision: Deletion is event-driven and time-bounded

- An envelope is **deleted** as soon as all intended recipients ack delivery (consistent with `relay-sync-no-persistence`).
- An envelope undelivered past its TTL is deleted by a periodic sweeper task, observable in metrics as a counter.
- Idempotency entries are deleted at `ttl_expires_at`.
- Routing relationships persist for as long as both parties remain connected; either side can sever the relationship, which deletes the routing row (after a short grace window for in-flight messages).

Rationale:

- Eliminates "we keep it because we forgot to delete" failure mode.
- The sweeper is observable: a stuck sweeper shows up in metrics and alerts.

### Decision: Security baseline is documented as a list of "must not"s in addition to "must"s

The relay deployment SHALL:

- Expose only the documented relay endpoint to the public internet (HTTPS on standard port). All other ports are firewalled.
- Use TLS-only (no plaintext HTTP); HTTP, if served, only redirects to HTTPS.
- Refuse admin access from the public internet. Any management interface (DB shell, container runtime control, log access) is reachable only via an out-of-band channel (e.g., SSH on a non-default port restricted to operator addresses, or via a tunneled bastion).
- Run with least-privilege container user (non-root) and read-only root filesystem where feasible.
- Keep secrets (TLS keys, DB credentials, signing keys) in an explicit secret-store mechanism, never committed to the repo, never logged.
- Apply rate limiting per source identity and per IP to mitigate flooding.
- Reject any payload not framed per the documented protocol envelope.
- Run on an OS image that receives security patches; have a documented patch cadence.
- Run a dependency-audit step in CI (image build), failing on known critical CVEs.

The relay deployment SHALL NOT:

- Log message bodies, recipient mapping payloads, or any user plaintext.
- Persist client IP addresses as part of the relay DB schema (incidental retention in ephemeral access logs is bounded by log rotation policy).
- Allow the database container to expose its port to the public internet.
- Reuse TLS material with unrelated services on the same VPS.
- Run any unrelated workload in the relay containers (no multi-tenant container).

Rationale:

- A "must not" list is easier to audit than a "must" list alone.
- Each item is a concrete check an external reviewer can run.

### Decision: Observability without payload visibility

Operational signals SHALL be sufficient to operate the relay in production:

- Counters: requests in / out, messages accepted, messages delivered, messages expired-TTL, sweeper runs, errors by class.
- Latency histograms per endpoint.
- Queue depth and oldest-undelivered-age.
- Resource counters (CPU, RAM, disk) at the container level.

Logs SHALL NOT contain message bodies or recipient mapping payloads. Logs MAY contain envelope IDs, sender/recipient opaque identifiers, timing, and error codes — these are the audit traces, not the content.

Rationale:

- Operators can run the service without seeing user content.
- Metrics-only observability is enough to detect abuse, congestion, and failures.

### Decision: Audit posture is publicly verifiable

- The relay project source (config, Compose/Helm/equivalent, schema, migration files) is in a public repository.
- Each deployed relay version maps to a tagged release and a published container digest.
- A `docs/relay-audit-checklist.md` lives in the repo and lists the concrete checks an external reviewer can run (curl + jq + container inspect + DB schema dump filtered to declared tables).
- A periodic self-audit (cadence defined in the spec; the spec sets a minimum quarterly cadence) is run by the operator and its findings published.
- Any deviation between deployed configuration and documented configuration is itself a finding that SHALL be disclosed.

Rationale:

- The audit isn't a one-time event; it's a sustained property.
- Public discoverability of the audit checklist sets the threshold for "verifiable" rather than just "claimed".

## Risks / Trade-offs

- **VPS-as-single-point-of-failure** → mitigation: documented backup strategy for routing metadata only (TTL-respecting), runbook for moving the relay to a fresh VPS using the same image and a recent backup. User payloads are not in backups because they have already been delivered or have expired.
- **Operator can read the database** → unavoidable for the routing rows; mitigation: the schema is structured so that the operator-readable data is only opaque identities + envelope ciphertext + TTL. There is no plaintext to read. Audit checklist explicitly tests that DB rows contain only ciphertext and opaque identities.
- **Co-tenant VPS workloads compromise the host** → mitigation: relay containers run isolated, with their own users; no host bind-mounts; secrets are container-scoped. A host compromise still affects the relay, but no plaintext is exposed because no plaintext exists at rest.
- **DDoS / flooding** → mitigation: rate limits per identity and per IP, queue-depth-based shedding. A determined DDoS still degrades service, but does not break the no-persistence promise.
- **Audit drift** (deployed != documented) → mitigation: audit cadence + image-tag-pinned deployments + reviewer checklist that diffs deployed config against the public configuration.
- **Sub-domain certificate transparency surface** → CT logs reveal the existence of the sub-domain. Acceptable: the project is public anyway.

## Migration Plan

This change has no on-device migration. Its deployment plan:

1. Author the relay implementation in a public sub-project (separate from the mobile app or in a `relay/` directory). The relay project ships its README, schema, configuration template, image build.
2. Provision the sub-domain on an existing controlled domain. Set up TLS issuance/renewal.
3. Provision the VPS-side container runtime, secret store, and firewall rules.
4. Deploy the relay containers from a pinned image tag.
5. Publish the deployed image digest, configuration, and audit checklist in the repo.
6. Run an initial self-audit; record findings.

Rollback: the relay is stateless beyond TTL-bounded data, so rolling back the image tag is a routine container-runtime operation. Routing relationships survive image rollbacks because they are stored in the named volume.

## Open Questions

- Exact TTL numbers: how many days before an undelivered envelope expires (the spec sets a minimum and a maximum band; the operator picks within that band).
- Exact idempotency window length.
- Whether the relay's metrics endpoint is publicly reachable (likely no; bastion-only) or proxied via authenticated read-only access.
- Whether to publish audit findings inline in the repo or via a separate page; both satisfy the spec.
- Whether to require reproducible builds for the relay image at this stage (not strictly required by the spec; flagged as a future enhancement).
