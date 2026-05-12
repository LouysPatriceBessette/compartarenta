## 1. Repository layout for the relay project

- [ ] 1.1 Decide on a sub-directory (e.g., `relay/`) or a separate public repository for the relay code; choose one and document the choice.
- [ ] 1.2 Bootstrap the relay project skeleton (image build file, compose / equivalent manifest, configuration template with redacted secrets, schema directory).
- [ ] 1.3 Add an initial `README` for the relay project describing the deployment model and pointing to `docs/relay-audit-checklist.md`.

## 2. Schema and persistence

- [ ] 2.1 Define the initial schema in versioned migrations: routing relationships, idempotency entries, undelivered envelopes, schema-version row, sweeper checkpoint.
- [ ] 2.2 Enforce schema-version gating at relay startup (refuse to start on incompatible schema).
- [ ] 2.3 Document each table's purpose and retention policy in the relay project.
- [ ] 2.4 Implement the sweeper task for envelope-TTL and idempotency-TTL expiry; emit per-run counters.
- [ ] 2.5 Implement deletion-on-delivery for envelopes that have been ack'd by all intended recipients.
- [ ] 2.6 Implement disconnect handling that deletes routing relationship rows after a documented grace window for in-flight envelopes.

## 3. Deployment topology

- [ ] 3.1 Reserve the sub-domain on the existing controlled domain; configure DNS.
- [ ] 3.2 Provision TLS via ACME / equivalent with automated renewal; instrument renewal monitoring.
- [ ] 3.3 Author the container compose / equivalent manifest: relay container + database container on a private network; named volumes for state.
- [ ] 3.4 Configure firewall to expose only the relay endpoint on the public interface; admin access via SSH (or equivalent) restricted to allow-list / bastion.
- [ ] 3.5 Pin deployments to immutable image digests; commit the manifests to the public repo.
- [ ] 3.6 Confirm no co-tenant workload exists in the relay containers.

## 4. Security baseline

- [ ] 4.1 Configure non-root user inside containers, read-only root filesystem where supported, writable paths limited to documented data dirs.
- [ ] 4.2 Wire secrets injection from a documented secret-store mechanism; remove all secret values from manifests and images.
- [ ] 4.3 Implement rate limiting per opaque sender identity and per source IP; document the values; emit rejection metrics.
- [ ] 4.4 Implement envelope framing validation and a documented maximum size limit; reject malformed / oversize envelopes without persisting them.
- [ ] 4.5 Add a dependency-audit step in the image build pipeline that fails on known critical CVEs.
- [ ] 4.6 Document the host OS / runtime patch cadence and apply the documented minimums.
- [ ] 4.7 Document abuse mitigations and operator action procedures; implement operator action logging.

## 5. Observability without payload visibility

- [ ] 5.1 Implement metrics for requests, envelopes (accepted/delivered/expired), routing (created/severed), sweeper, queue depth, oldest-undelivered-age, container resource usage.
- [ ] 5.2 Implement structured logging with explicit allow-list of fields (no ciphertext bodies, no payload, no contact metadata).
- [ ] 5.3 Confirm client IP addresses are not persisted in the relay DB; document access-log rotation policy.
- [ ] 5.4 Restrict the metrics endpoint to private network access (no public reachability).
- [ ] 5.5 Implement a minimal liveness/readiness endpoint that returns only documented operational state.
- [ ] 5.6 Document alerting thresholds and configure alerts on the deployed system to match.

## 6. Audit posture (day-one)

- [ ] 6.1 Author `docs/relay-audit-checklist.md` with runnable checks (DNS/TLS scope, image digest match, schema diff, TTL config, log absence-of-plaintext, metrics private-only, public surface enumeration, operator action log presence).
- [ ] 6.2 Author `docs/relay-deployment.md` describing the topology, TTL bounds, identifiers, and operational cadences.
- [ ] 6.3 Tag the first deployed release; record the (tag, digest, deployment date) triple in a public location in the repository.
- [ ] 6.4 Run the baseline self-audit using the checklist; record the entry in a public audit log dated on or before first public traffic.
- [ ] 6.5 Schedule the recurring quarterly self-audit; document the cadence.
- [ ] 6.6 Define the tracking mechanism for audit findings (public issue tracker or audit log entries) and create a placeholder entry to demonstrate the mechanism.

## 7. Tests

- [ ] 7.1 Unit tests for envelope validation (framing, size, rejection paths).
- [ ] 7.2 Unit tests for rate limiting behavior.
- [ ] 7.3 Integration test for envelope lifecycle: submit → deliver → delete (and verify metrics counter increments).
- [ ] 7.4 Integration test for sweeper expiry: submit → no delivery → TTL expiry → row deletion (verify metrics counter increments).
- [ ] 7.5 Schema-shape test that scans the database for any column whose name or type suggests user-content plaintext.
- [ ] 7.6 Audit-checklist dry-run test that exercises each item in `docs/relay-audit-checklist.md` against a local deployment.
