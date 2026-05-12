# Compartarenta Relay — Audit Checklist

This checklist is the runnable counterpart to the OpenSpec capability
`relay-public-auditability`. An external reviewer can clone this
repository and reproduce each check below. Every item lists the
expected outcome; any divergence is an audit finding that goes into
[`relay-audit-log.md`](./relay-audit-log.md).

Replace `<example.tld>` with the deployed sub-domain you are auditing
and `$RELAY_HOST` with the public hostname (e.g., `relay.example.tld`).
Replace `$ADMIN_HOST` with the bastion / VPS hostname over SSH where
applicable.

Tools assumed available on the auditor's machine: `curl`, `dig`,
`openssl`, `jq`, `psql`, `docker`, and SSH. No proprietary tooling.

---

## A. DNS, TLS, and public surface

### A.1 The relay sub-domain resolves to a single A/AAAA record

```bash
dig +short A $RELAY_HOST
dig +short AAAA $RELAY_HOST
```

**Expected:** at least one address record. Records do not point at a
shared load-balancer alias for unrelated services on the same VPS.

### A.2 TLS certificate covers only the relay sub-domain

```bash
echo | openssl s_client -connect $RELAY_HOST:443 -servername $RELAY_HOST 2>/dev/null \
  | openssl x509 -noout -text \
  | grep -A1 "Subject Alternative Name"
```

**Expected:** SAN list contains only the relay sub-domain (and other
names that are exclusively part of the relay deployment). No wildcard
shared with unrelated services. Required by
`relay-deployment-topology` / "TLS material is not shared with
unrelated services".

### A.3 Plaintext HTTP is refused or redirected

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://$RELAY_HOST/v1/envelopes
```

**Expected:** `301`, `308`, or refused connection. Required by
`relay-deployment-topology` / "TLS is mandatory on the relay
sub-domain".

### A.4 No incidental public endpoints

```bash
for path in /metrics /admin /debug /debug/pprof /pprof /healthz /readyz; do
  echo -n "$path: "
  curl -s -o /dev/null -w "%{http_code}\n" https://$RELAY_HOST$path
done
```

**Expected:** `/metrics`, `/admin`, `/debug`, `/debug/pprof`, `/pprof`
return non-200 (the relay does not serve them on the public listener).
`/healthz` and `/readyz` return 200. Required by
`relay-deployment-topology` / "The relay is the only public surface
exposed by the deployment".

### A.5 Database port is not reachable from the public internet

```bash
nc -zv $RELAY_HOST 5432 2>&1 | head -1
```

**Expected:** connection refused or timeout. Required by
`relay-deployment-topology` / "The database container is not reachable
from the public internet".

---

## B. Container image and configuration

### B.1 Deployed image digest matches a tagged release

On the host:

```bash
ssh $ADMIN_HOST 'docker inspect --format "{{ index .RepoDigests 0 }}" compartarenta-relay'
```

Then compare with the digest declared in the most recent entry of
[`relay-audit-log.md`](./relay-audit-log.md) under "Deployment".

**Expected:** digests match. Required by
`relay-public-auditability` / "Each deployed version maps to a tagged
release".

### B.2 No secret values committed to the repository

```bash
git -C $REPO grep -nE '(POSTGRES_PASSWORD|DATABASE_URL)=[^$]' \
  -- ':!**/relay-audit-checklist.md' ':!**/relay-deployment.md' \
  ':!**/.env.example' || echo "clean"
```

**Expected:** prints `clean`. The repository contains placeholder
values in `.env.example` and documentation only. Required by
`relay-security-baseline` / "Secrets are managed by an explicit secret
store".

### B.3 Container runs as non-root

```bash
ssh $ADMIN_HOST 'docker inspect --format "{{ .Config.User }}" compartarenta-relay'
ssh $ADMIN_HOST 'docker exec compartarenta-relay id 2>/dev/null || echo "scratch image, ok"'
```

**Expected:** non-zero UID (`65532:65532` per the Dockerfile). Required
by `relay-security-baseline` / "The relay process runs with least
privilege".

### B.4 Root filesystem is read-only on the relay container

```bash
ssh $ADMIN_HOST 'docker inspect --format "{{ .HostConfig.ReadonlyRootfs }}" compartarenta-relay'
```

**Expected:** `true`.

### B.5 No unrelated processes inside the containers

```bash
ssh $ADMIN_HOST 'docker top compartarenta-relay'
ssh $ADMIN_HOST 'docker top compartarenta-relay-db'
```

**Expected:** the relay container shows only the `/relay` process; the
database container shows only `postgres`. Required by
`relay-deployment-topology` / "The deployment runs without unrelated
workloads in relay containers".

---

## C. Schema and retention

### C.1 Live schema matches the migrations directory

Open an SSH tunnel and connect via psql:

```bash
ssh -L 5432:postgres:5432 $ADMIN_HOST
psql "postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@127.0.0.1:5432/$POSTGRES_DB" \
  -c "\dt+" \
  -c "\d+ routing_relationships" \
  -c "\d+ idempotency_entries" \
  -c "\d+ envelopes" \
  -c "\d+ sweeper_checkpoint" \
  -c "\d+ operator_actions" \
  -c "\d+ schema_version"
```

**Expected:** the printed schema matches the union of migrations in
`relay/internal/store/schema/`. The only payload-carrying column is
`envelopes.ciphertext` and it is BYTEA. Required by
`relay-state-schema-and-retention` / "The relay database schema is
explicitly enumerated and minimal".

### C.2 No table holds plaintext user content

The same psql session:

```sql
SELECT column_name, data_type, table_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND data_type IN ('text', 'character varying');
```

**Expected:** the only TEXT columns are
`schema_version` housekeeping fields,
`routing_relationships.status`,
`operator_actions.actor / action / reason / target_kind`. None of
these decode to user-facing plaintext. Required by
`relay-state-schema-and-retention` / "The relay database SHALL NOT
store user payload plaintext".

### C.3 No envelope is older than `ENVELOPE_TTL_MAX`

```sql
SELECT count(*) FROM envelopes
WHERE created_at < now() - interval '7 days';
```

**Expected:** `0`. (Adjust the interval to the operator's
`ENVELOPE_TTL_MAX` value.) Required by
`relay-state-schema-and-retention` / "Undelivered envelopes are
deleted at TTL expiry".

### C.4 Sweeper has run recently

```sql
SELECT last_run_at FROM sweeper_checkpoint WHERE id = 1;
```

**Expected:** `last_run_at` within the last `SWEEPER_INTERVAL` plus a
small jitter buffer.

### C.5 No IP addresses persisted in the relay DB

Inspect the printed schema from C.1. **Expected:** no column whose name
or type stores client IP addresses. Required by
`relay-observability-without-plaintext` / "Logs do not persist client
IP addresses as relay state".

---

## D. Logs and metrics

### D.1 Sample relay logs contain no ciphertext / payload fields

```bash
ssh $ADMIN_HOST 'docker logs --tail 200 compartarenta-relay' \
  | jq -c 'select(.msg | startswith("envelope"))' \
  | head -5
```

**Expected:** each line contains only allow-listed fields
(`endpoint`, `envelope_id`, `sender_identity`, `recipient_identity`,
`status`, `duration_ms`, `error`, `rejection_reason`, `build`, etc.).
No `ciphertext` field. No `display_name`. No `email`. Required by
`relay-observability-without-plaintext` / "Logs do not contain
user-content plaintext".

### D.2 Metrics endpoint is private-only

From the auditor's machine without SSH tunnel:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://$RELAY_HOST/metrics
```

**Expected:** non-200 (the relay does not serve metrics on the public
listener). Required by `relay-observability-without-plaintext` / "The
metrics endpoint is not publicly reachable".

### D.3 Metrics scraping works through the documented private channel

Through SSH tunnel:

```bash
ssh -L 9090:127.0.0.1:9090 $ADMIN_HOST
curl -s http://127.0.0.1:9090/metrics | head -40
```

**Expected:** Prometheus exposition text, with at least
`relay_envelopes_accepted_total`,
`relay_envelopes_delivered_total`,
`relay_envelopes_expired_total`,
`relay_envelopes_queue_depth`,
`relay_envelopes_oldest_undelivered_age_seconds`,
`relay_sweeper_runs_total`,
`relay_http_requests_total`.

---

## E. Operator action log

### E.1 Operator actions are recorded

```sql
SELECT count(*), max(occurred_at) FROM operator_actions;
```

**Expected:** at least one row exists when the operator has performed
any documented action (e.g., a baseline self-audit). Required by
`relay-observability-without-plaintext` / "Operator action logs are
separate from envelope logs".

### E.2 Each row has a reason

```sql
SELECT actor, action, reason FROM operator_actions ORDER BY occurred_at DESC LIMIT 5;
```

**Expected:** every row has non-empty `actor`, `action`, and `reason`.

---

## F. Documentation alignment

### F.1 README, deployment runbook, audit log are present

```bash
test -f relay/README.md \
  && test -f docs/relay-deployment.md \
  && test -f docs/relay-audit-checklist.md \
  && test -f docs/relay-audit-log.md \
  && echo "ok"
```

**Expected:** `ok`.

### F.2 The audit log has an entry within the last quarter

Open [`relay-audit-log.md`](./relay-audit-log.md). **Expected:** at
least one self-audit entry dated within the last 90 days. Required by
`relay-public-auditability` / "A periodic self-audit is performed and
recorded".

---

## How to record findings

Append one row per finding to the **Findings** section of
[`relay-audit-log.md`](./relay-audit-log.md). Include:

- Date and auditor (`actor`),
- Reference to the checklist item (e.g., `A.2`),
- Observed value vs expected value,
- Resolution state (`open` / `resolved` / `accepted`),
- Pointer to the underlying issue / commit when applicable.

A failing item does not become "resolved" until the underlying
deviation has been corrected or explicitly accepted with a documented
reason, per `relay-public-auditability` / "Audit findings are tracked
and resolved transparently".
