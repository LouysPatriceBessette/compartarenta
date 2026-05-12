## 1. Repository layout for the relay project

- [x] 1.1 Decide on a sub-directory (e.g., `relay/`) or a separate public repository for the relay code; choose one and document the choice.
      Decision: in-repo subdirectory `relay/` (documented in `relay/README.md`).
- [x] 1.2 Bootstrap the relay project skeleton (image build file, compose / equivalent manifest, configuration template with redacted secrets, schema directory).
      Files: `relay/Dockerfile`, `relay/compose.yml`, `relay/.env.example`, `relay/internal/store/schema/0001_init.sql`.
- [x] 1.3 Add an initial `README` for the relay project describing the deployment model and pointing to `docs/relay-audit-checklist.md`.

## 2. Schema and persistence

- [x] 2.1 Define the initial schema in versioned migrations: routing relationships, idempotency entries, undelivered envelopes, schema-version row, sweeper checkpoint.
      Includes the operator-actions audit table required by §4.7 / §5.x.
- [x] 2.2 Enforce schema-version gating at relay startup (refuse to start on incompatible schema).
      `internal/store/store.go::applyMigrations` refuses to start when the on-disk version exceeds the binary's expected version; the binary's expected version lives in `internal/version/version.go`.
- [x] 2.3 Document each table's purpose and retention policy in the relay project.
      Each `CREATE TABLE` block in `internal/store/schema/0001_init.sql` carries an inline comment block linking it to the relevant spec section.
- [x] 2.4 Implement the sweeper task for envelope-TTL and idempotency-TTL expiry; emit per-run counters.
      `internal/sweeper/sweeper.go`; counters in `internal/metrics/metrics.go`.
- [x] 2.5 Implement deletion-on-delivery for envelopes that have been ack'd by all intended recipients.
      Per-recipient row model: each recipient has its own row, so a single ack from that recipient deletes the row immediately in `Store.AckEnvelope`.
- [x] 2.6 Implement disconnect handling that deletes routing relationship rows after a documented grace window for in-flight envelopes.
      `Store.MarkDisconnecting` + sweeper `PruneExpiredRouting`; grace window in `Config.DisconnectGrace` (default 5 minutes).

## 3. Deployment topology

- [ ] 3.1 Reserve the sub-domain on the existing controlled domain; configure DNS.
      Operator-side; runbook lives in `docs/relay-deployment.md`.
- [ ] 3.2 Provision TLS via ACME / equivalent with automated renewal; instrument renewal monitoring.
      Operator-side; runbook lives in `docs/relay-deployment.md`.
- [x] 3.3 Author the container compose / equivalent manifest: relay container + database container on a private network; named volumes for state.
      `relay/compose.yml`: `relay-net` private network, `pgdata` named volume, no published port on the postgres service.
- [x] 3.4 Configure firewall to expose only the relay endpoint on the public interface; admin access via SSH (or equivalent) restricted to allow-list / bastion.
      Documented in `docs/relay-deployment.md` (host-firewall configuration is operator-side; the compose manifest binds the relay's `9090` and dev `8080` to `127.0.0.1` only).
- [x] 3.5 Pin deployments to immutable image digests; commit the manifests to the public repo.
      Compose references `RELAY_TAG`/`BUILD_DIGEST`; the audit log tracks `(tag, digest, deployment date)` for each release.
- [x] 3.6 Confirm no co-tenant workload exists in the relay containers.
      `Dockerfile` is `FROM scratch` with only the relay binary; compose has no commands that would launch sibling processes.

## 4. Security baseline

- [x] 4.1 Configure non-root user inside containers, read-only root filesystem where supported, writable paths limited to documented data dirs.
      `Dockerfile` runs as `65532:65532`; compose sets `read_only: true` and `cap_drop: ALL`, with only a writable `/tmp` tmpfs.
- [x] 4.2 Wire secrets injection from a documented secret-store mechanism; remove all secret values from manifests and images.
      `.env.example` documents the variables; `.gitignore` excludes real `.env`; compose pulls values from the host environment via `${...:?required}`.
- [x] 4.3 Implement rate limiting per opaque sender identity and per source IP; document the values; emit rejection metrics.
      `internal/ratelimit/`; metrics in `internal/metrics/metrics.go` (`relay_ratelimit_rejections_total{scope=...}`); defaults documented in `docs/relay-deployment.md`.
- [x] 4.4 Implement envelope framing validation and a documented maximum size limit; reject malformed / oversize envelopes without persisting them.
      `handleEnvelopes` validates framing and size before any DB call; `ENVELOPE_MAX_BYTES` is the documented limit.
- [x] 4.5 Add a dependency-audit step in the image build pipeline that fails on known critical CVEs.
      `Dockerfile` runs `govulncheck ./...` during the build stage; failures abort the build.
- [x] 4.6 Document the host OS / runtime patch cadence and apply the documented minimums.
      `docs/relay-deployment.md` "Patch cadence" section.
- [x] 4.7 Document abuse mitigations and operator action procedures; implement operator action logging.
      `operator_actions` table + `Store.RecordOperatorAction`; documented in `docs/relay-deployment.md` and `docs/relay-audit-log.md`.

## 5. Observability without payload visibility

- [x] 5.1 Implement metrics for requests, envelopes (accepted/delivered/expired), routing (created/severed), sweeper, queue depth, oldest-undelivered-age, container resource usage.
      `internal/metrics/metrics.go` defines all of these; Go and process collectors are registered for resource usage.
- [x] 5.2 Implement structured logging with explicit allow-list of fields (no ciphertext bodies, no payload, no contact metadata).
      `internal/logging/logging.go` drops any field outside the allow-list; `internal/logging/logging_test.go` verifies forbidden fields cannot be emitted.
- [x] 5.3 Confirm client IP addresses are not persisted in the relay DB; document access-log rotation policy.
      Schema-shape test (`internal/store/schema_shape_test.go`) forbids `ip_address`/`client_ip` columns. Access-log rotation lives at the reverse proxy and is documented in `docs/relay-deployment.md`.
- [x] 5.4 Restrict the metrics endpoint to private network access (no public reachability).
      The relay binds `/metrics` to `PRIVATE_LISTEN_ADDR` only; the public mux does not serve `/metrics`.
- [x] 5.5 Implement a minimal liveness/readiness endpoint that returns only documented operational state.
      `/healthz` and `/readyz` return `{ status, build, schema_version }` only.
- [x] 5.6 Document alerting thresholds and configure alerts on the deployed system to match.
      Documented in `docs/relay-deployment.md` "Alerts" section. Configuring alerts on the live monitoring stack is operator-side.

## 6. Audit posture (day-one)

- [x] 6.1 Author `docs/relay-audit-checklist.md` with runnable checks (DNS/TLS scope, image digest match, schema diff, TTL config, log absence-of-plaintext, metrics private-only, public surface enumeration, operator action log presence).
- [x] 6.2 Author `docs/relay-deployment.md` describing the topology, TTL bounds, identifiers, and operational cadences.
- [ ] 6.3 Tag the first deployed release; record the (tag, digest, deployment date) triple in a public location in the repository.
      Awaiting the first real deployment. `docs/relay-audit-log.md` carries a placeholder row that must be replaced before public traffic.
- [ ] 6.4 Run the baseline self-audit using the checklist; record the entry in a public audit log dated on or before first public traffic.
      Awaiting the first real deployment. Baseline placeholder lives in `docs/relay-audit-log.md`.
- [x] 6.5 Schedule the recurring quarterly self-audit; document the cadence.
      `docs/relay-audit-log.md` "Audit cadence" section.
- [x] 6.6 Define the tracking mechanism for audit findings (public issue tracker or audit log entries) and create a placeholder entry to demonstrate the mechanism.
      "Findings" table in `docs/relay-audit-log.md`.

## 7. Tests

- [x] 7.1 Unit tests for envelope validation (framing, size, rejection paths).
      `internal/api/api_test.go`: `TestDecodeIdentity*`, `TestDecodeCiphertextRejectsOversize`, `TestClampTTL`.
- [x] 7.2 Unit tests for rate limiting behavior.
      `internal/ratelimit/ratelimit_test.go`.
- [ ] 7.3 Integration test for envelope lifecycle: submit → deliver → delete (and verify metrics counter increments).
      Deferred: requires a live PostgreSQL fixture (docker-compose or testcontainers). The store API is exercised by `internal/store/canonical_test.go` and the schema-shape test; full lifecycle test slated for the next follow-up.
- [ ] 7.4 Integration test for sweeper expiry: submit → no delivery → TTL expiry → row deletion (verify metrics counter increments).
      Deferred for the same reason as 7.3.
- [x] 7.5 Schema-shape test that scans the database for any column whose name or type suggests user-content plaintext.
      `internal/store/schema_shape_test.go` scans the embedded migrations.
- [ ] 7.6 Audit-checklist dry-run test that exercises each item in `docs/relay-audit-checklist.md` against a local deployment.
      Operator-side; runs against a `docker compose up`-ed stack and produces a baseline audit-log entry.

## Notes on deferred items

- **3.1, 3.2, 6.3, 6.4, 7.3, 7.4, 7.6** require either DNS / TLS access on the operator's controlled domain or a live PostgreSQL test fixture. They are marked unchecked deliberately so the next deployment milestone or testing pass can finish them without ambiguity. The supporting documentation and code paths needed to complete each one are already in this change.
