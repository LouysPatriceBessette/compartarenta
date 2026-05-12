-- 0001_init.sql — Initial relay schema.
--
-- Tables in this migration are the COMPLETE set of relay-state tables.
-- Any future table MUST fall into one of the four categories described in
-- the parent capability `relay-state-schema-and-retention` (routing,
-- idempotency, undelivered envelopes, operational housekeeping).
--
-- Plaintext user content is forbidden in any column. Test
-- `schema_shape_test.go` enforces that the only payload-bearing column in
-- the entire schema is `envelopes.ciphertext`, and that column is BYTEA.

BEGIN;

-- ---------------------------------------------------------------------------
-- schema_version
-- ---------------------------------------------------------------------------
-- Single-row gate read at startup. The relay refuses to start when the
-- value here does not match the binary's compiled-in expected schema
-- version, per `relay-state-schema-and-retention` /
-- "Schema migrations are versioned and reviewable".

CREATE TABLE schema_version (
    id          SMALLINT PRIMARY KEY CHECK (id = 1),
    version     INTEGER  NOT NULL,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO schema_version (id, version) VALUES (1, 1);

-- ---------------------------------------------------------------------------
-- routing_relationships
-- ---------------------------------------------------------------------------
-- One row per established (peer_a, peer_b) routing pair.
--
-- `peer_a` and `peer_b` are OPAQUE routing identifiers exchanged during the
-- contacts handshake. They are NEVER derived from a display name, email,
-- phone number, avatar, or any other contact metadata
-- (`relay-state-schema-and-retention` / "Opaque identities are not derived
-- from user-presented identity"). The relay treats them as bytes.
--
-- The two columns are kept in canonical order (peer_a < peer_b) at insert
-- time so each pair has a single canonical row.
--
-- Retention: persists until severed by an explicit disconnect envelope
-- (delivery to the peer triggers deletion after the documented grace
-- window), or by operator action with an audit-log entry, or by the
-- long-inactivity threshold (see config DISCONNECT_GRACE_DURATION,
-- ROUTING_INACTIVITY_TTL).

CREATE TABLE routing_relationships (
    peer_a          BYTEA       NOT NULL,
    peer_b          BYTEA       NOT NULL,
    established_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    status          TEXT        NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'disconnecting')),
    disconnect_started_at TIMESTAMPTZ,
    PRIMARY KEY (peer_a, peer_b),
    CHECK (peer_a < peer_b),
    CHECK (length(peer_a) BETWEEN 8 AND 64),
    CHECK (length(peer_b) BETWEEN 8 AND 64)
);

-- ---------------------------------------------------------------------------
-- idempotency_entries
-- ---------------------------------------------------------------------------
-- Allows clients to retry POST /v1/envelopes safely without creating
-- duplicates. Bounded by ttl_expires_at; never retained indefinitely.
--
-- Retention: deleted by the sweeper at `ttl_expires_at`. The window is set
-- by config IDEMPOTENCY_TTL.

CREATE TABLE idempotency_entries (
    sender_identity BYTEA       NOT NULL,
    idempotency_key BYTEA       NOT NULL,
    envelope_id     BYTEA       NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ttl_expires_at  TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (sender_identity, idempotency_key),
    CHECK (length(sender_identity) BETWEEN 8 AND 64),
    CHECK (length(idempotency_key) BETWEEN 8 AND 64),
    CHECK (length(envelope_id) BETWEEN 8 AND 64)
);

CREATE INDEX idempotency_entries_ttl_idx
    ON idempotency_entries (ttl_expires_at);

-- ---------------------------------------------------------------------------
-- envelopes
-- ---------------------------------------------------------------------------
-- Undelivered ciphertext, addressed-to one opaque recipient. A single
-- multi-recipient client-side envelope is represented as one row per
-- recipient on the relay; that keeps the per-recipient delivery and ack
-- accounting trivial. Cross-row correlation by the relay is not required.
--
-- `ciphertext` is the ONLY column in the entire schema that is permitted
-- to hold payload bytes, and it is BYTEA. The relay never inspects it.
--
-- Retention:
--   - deleted at `delivered_at` time once a recipient acks (the row IS the
--     per-recipient unit so a single ack deletes a row);
--   - swept after `ttl_expires_at` if still undelivered.
--
-- `ttl_expires_at` is clamped to [created_at + ENVELOPE_TTL_MIN,
-- created_at + ENVELOPE_TTL_MAX] by the API layer.

CREATE TABLE envelopes (
    envelope_id        BYTEA       NOT NULL,
    sender_identity    BYTEA       NOT NULL,
    recipient_identity BYTEA       NOT NULL,
    ciphertext         BYTEA       NOT NULL,
    kind               SMALLINT    NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    ttl_expires_at     TIMESTAMPTZ NOT NULL,
    delivered_at       TIMESTAMPTZ,
    PRIMARY KEY (envelope_id, recipient_identity),
    CHECK (length(envelope_id) BETWEEN 8 AND 64),
    CHECK (length(sender_identity) BETWEEN 8 AND 64),
    CHECK (length(recipient_identity) BETWEEN 8 AND 64),
    CHECK (length(ciphertext) >= 1)
);

CREATE INDEX envelopes_inbox_idx
    ON envelopes (recipient_identity, created_at)
    WHERE delivered_at IS NULL;

CREATE INDEX envelopes_ttl_idx
    ON envelopes (ttl_expires_at)
    WHERE delivered_at IS NULL;

-- ---------------------------------------------------------------------------
-- sweeper_checkpoint
-- ---------------------------------------------------------------------------
-- One-row table tracking the last successful sweeper run. Lets operators
-- alert on a stuck sweeper without having to invent a side channel.
--
-- Retention: a single row; updated in place. Not user-derived data.

CREATE TABLE sweeper_checkpoint (
    id              SMALLINT PRIMARY KEY CHECK (id = 1),
    last_run_at     TIMESTAMPTZ,
    last_envelopes_expired   BIGINT NOT NULL DEFAULT 0,
    last_idempotency_expired BIGINT NOT NULL DEFAULT 0,
    last_routing_pruned      BIGINT NOT NULL DEFAULT 0,
    total_envelopes_expired   BIGINT NOT NULL DEFAULT 0,
    total_idempotency_expired BIGINT NOT NULL DEFAULT 0,
    total_routing_pruned      BIGINT NOT NULL DEFAULT 0
);

INSERT INTO sweeper_checkpoint (id) VALUES (1);

-- ---------------------------------------------------------------------------
-- operator_actions
-- ---------------------------------------------------------------------------
-- Audit trail for operator-initiated actions (severing an abusive routing
-- relationship, running an out-of-cycle sweeper, applying a migration).
--
-- Per `relay-observability-without-plaintext` / "Operator action logs are
-- separate from envelope logs". This table does NOT serve as an envelope
-- log; envelope events live in the structured request log only.

CREATE TABLE operator_actions (
    id           BIGSERIAL PRIMARY KEY,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    actor        TEXT        NOT NULL,
    action       TEXT        NOT NULL,
    reason       TEXT        NOT NULL,
    target_kind  TEXT,
    target_a     BYTEA,
    target_b     BYTEA
);

CREATE INDEX operator_actions_time_idx ON operator_actions (occurred_at);

COMMIT;
