# Compartarenta Relay — Deployment Runbook

This runbook describes how to deploy the Compartarenta relay on an
existing VPS, under a dedicated sub-domain, with TLS terminated at the
public edge and the relay state held in a containerized PostgreSQL
instance. It is the operational counterpart to the spec at
`openspec/changes/relay-server-infrastructure-and-audit/`. Auditors
should cross-reference this document with
[`relay-audit-checklist.md`](./relay-audit-checklist.md).

## At a glance

| Item                           | Where                                                      |
|--------------------------------|------------------------------------------------------------|
| Source code                    | [`relay/`](../relay)                                       |
| Migrations (canonical)         | [`relay/internal/store/schema/`](../relay/internal/store/schema) |
| Reference compose manifest     | [`relay/compose.yml`](../relay/compose.yml)                |
| Environment template           | [`relay/.env.example`](../relay/.env.example)              |
| Audit checklist                | [`relay-audit-checklist.md`](./relay-audit-checklist.md)   |
| Audit log                      | [`relay-audit-log.md`](./relay-audit-log.md)               |
| Deployment topology spec       | `openspec/changes/relay-server-infrastructure-and-audit/specs/relay-deployment-topology/spec.md` |

## Topology

```
                 public internet
                       │
                       │ HTTPS / 443
                       ▼
              ┌──────────────────────┐
              │   reverse proxy      │  ← terminates TLS for
              │   (Caddy / nginx /   │    relay.<example.tld>
              │   traefik)           │    auto-renewed via ACME
              └──────────┬───────────┘
                         │ HTTP / 8080  (private)
                         ▼
              ┌──────────────────────┐
              │   relay container    │   non-root, read-only rootfs
              │   /v1/envelopes      │   cap_drop: ALL
              │   /v1/inbox/:id      │   no-new-privileges:true
              │   /v1/handshake/...  │
              │   /v1/disconnect     │
              │   /healthz /readyz   │
              │   /metrics  ← 9090   │  ← private port only
              └──────────┬───────────┘
                         │ tcp / 5432  (private)
                         ▼
              ┌──────────────────────┐
              │  postgres container  │   no published port
              │  pgdata named volume │   isolated network
              └──────────────────────┘
```

## Required environment

| Variable                 | Purpose                                                  | Source                         |
|--------------------------|----------------------------------------------------------|--------------------------------|
| `DATABASE_URL`           | libpq DSN for postgres                                   | secret store                   |
| `POSTGRES_USER`          | Database user                                            | secret store                   |
| `POSTGRES_PASSWORD`      | Database password                                        | secret store                   |
| `POSTGRES_DB`            | Database name                                            | secret store                   |
| `RELAY_TAG`              | Container image tag, matches the deployed digest         | repo (release notes)           |
| `BUILD_DIGEST`           | Built into the binary; surfaced via `/healthz`           | CI build                       |
| `PUBLIC_LISTEN_ADDR`     | bind address for the relay protocol + health             | manifest (default `0.0.0.0:8080`) |
| `PRIVATE_LISTEN_ADDR`    | bind address for `/metrics`                              | manifest (default `127.0.0.1:9090`) |
| `ENVELOPE_MAX_BYTES`     | ciphertext cap per envelope                              | manifest                       |
| `ENVELOPE_TTL_MIN/MAX`   | per-envelope TTL clamp range                             | manifest                       |
| `IDEMPOTENCY_TTL`        | idempotency entry lifetime                               | manifest                       |
| `DISCONNECT_GRACE`       | grace window on disconnecting routing rows               | manifest                       |
| `ROUTING_INACTIVITY_TTL` | long-inactivity TTL for routing rows                     | manifest                       |
| `SWEEPER_INTERVAL`       | cadence at which TTL deletions run                       | manifest                       |
| `RATE_LIMIT_PER_IDENTITY`| token-bucket rate per opaque identity (tokens/sec)       | manifest                       |
| `RATE_LIMIT_PER_IP`      | token-bucket rate per source IP (tokens/sec)             | manifest                       |
| `SHUTDOWN_TIMEOUT`       | drain window on SIGTERM                                  | manifest                       |

The relay's `config.Load` refuses to start without `DATABASE_URL`. It
also enforces ceiling bounds on `ENVELOPE_TTL_MAX` (~30 days) and
`IDEMPOTENCY_TTL` (~7 days). Wider values trip an explicit error.

## TLS

The relay binary itself does NOT terminate TLS. Termination happens at
the reverse proxy in front of it. Recommended pattern:

- Caddy / nginx / traefik on the same host, with `relay.<example.tld>`
  pointing to its IP.
- ACME issuance (Caddy and traefik do this automatically). Set up
  monitoring on the certificate expiry; renewal-failure alerts are
  required by `relay-deployment-topology` / "Certificate renewal is
  monitored".
- The certificate's SAN list contains **only** the relay sub-domain (and
  any other names that are exclusively part of the relay deployment).
  This is enforced by `relay-deployment-topology` /
  "TLS material is not shared with unrelated services".

## Deploying the first time

1. Provision DNS: create an `A` (and `AAAA`) record for the relay
   sub-domain pointing to the VPS.
2. Provision the host firewall to expose only TCP/443 publicly. The
   metrics port (9090) and the database port (5432) MUST NOT be reachable
   from the public internet.
3. Install the reverse proxy with an ACME-issued certificate for the
   relay sub-domain. Configure it to forward to `127.0.0.1:8080`.
4. Inject `.env` values from your secret store. Never commit them.
5. Pull or build the relay image. Pin to an immutable digest.
6. `docker compose up -d`. The relay applies migrations and refuses to
   start when the schema version doesn't match.
7. Probe `https://relay.<example.tld>/healthz` from the public side and
   `http://127.0.0.1:9090/metrics` over SSH-tunnel. The former must
   succeed; the latter must return Prometheus text. Both are part of
   the audit checklist baseline.
8. Run the audit checklist end-to-end and append an entry to
   [`relay-audit-log.md`](./relay-audit-log.md).

## Upgrading

1. Build the new image with `BUILD_DIGEST` set to the immutable digest
   you intend to deploy.
2. Tag the corresponding release in this repository. Update
   `relay-audit-log.md` with the `(tag, digest, deployment date)` triple
   before the new image becomes live.
3. `docker compose pull && docker compose up -d`.
4. Re-run `relay-audit-checklist.md`. If anything diverges from this
   document, file an audit finding per
   `relay-public-auditability` /
   "Configuration drift between deployed and documented is itself a
   finding".

Rollback is a `docker compose up -d --image-digest <previous>` away. The
routing-relationship rows survive rollbacks because they live in the
named volume.

## Patch cadence

| Surface                 | Cadence                              | Critical CVE window         |
|-------------------------|--------------------------------------|-----------------------------|
| Host OS                 | monthly review                       | 72 hours after disclosure   |
| Container runtime       | monthly review                       | 72 hours after disclosure   |
| Postgres image          | monthly review                       | 72 hours after disclosure   |
| Relay image deps        | weekly `govulncheck`                 | next image build            |

`govulncheck ./...` runs inside the Docker build stage and fails the
build on known-critical CVEs. Re-running `go mod tidy` plus rebuilding
brings in the fix.

## Alerts

Configure alerts on the deployed Prometheus collector (out of scope for
this repository; happens at the operator's monitoring stack):

| Signal                                       | Threshold                                  |
|----------------------------------------------|--------------------------------------------|
| `relay_sweeper_runs_total` rate              | should be > 0 over the last 5 minutes      |
| `relay_envelopes_queue_depth`                | alert when > N for M minutes (operator-chosen) |
| `relay_envelopes_oldest_undelivered_age_seconds` | alert when > envelope TTL minimum      |
| `relay_http_requests_total{status_class="5xx"}` rate | alert when > 1% of total over 5 minutes |
| TLS certificate expiry                       | alert > 14 days before expiry              |

The exact thresholds and recipients are role-keyed (e.g., "operator
on-call") per `relay-observability-without-plaintext` /
"Alerting thresholds are documented".

## What this relay never does

Repeated for emphasis (the audit checklist tests each item):

- It does NOT decrypt envelopes.
- It does NOT store display names, avatars, expense amounts, contact
  metadata, or any user-facing content.
- It does NOT log envelope ciphertext, recipient mapping payloads, or
  contact metadata.
- It does NOT keep delivered envelopes past the per-recipient ack.
- It does NOT keep undelivered envelopes past `ttl_expires_at`.
- It does NOT publish a metrics or admin endpoint to the public
  internet.
- It does NOT share TLS material with services unrelated to the relay.
- It does NOT host any unrelated workload in its containers.

Each of these statements is verifiable from this repository alone.

## Operator-side tasks that this repository cannot perform for you

Tasks 3.1 and 3.2 of `relay-server-infrastructure-and-audit/tasks.md`
(reserving the sub-domain and provisioning ACME) need DNS access and
domain control. They are operator runbook items by nature. The same
applies to task 7.6 (audit-checklist dry-run on a live deployment) and
to task 6.3 once a first real deployment occurs. Mark them done in
`tasks.md` when the operator completes them.
