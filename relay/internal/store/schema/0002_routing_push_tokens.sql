-- 0002_routing_push_tokens.sql — Closed-app push transport routing tokens
-- and per-UTC-day operator metrics (dispatch / purge counters).
--
-- `routing_push_tokens` holds opaque FCM/APNs device tokens keyed by
-- recipient routing identity. No envelope ciphertext. `country` is the
-- only user-declared field (ISO 3166-1 alpha-2 or UNDISCLOSED).
--
-- `relay_day_metrics` aggregates technical counters per calendar day in
-- UTC for the loopback-only statistics endpoint.

BEGIN;

UPDATE schema_version SET version = 2, applied_at = now() WHERE id = 1;

CREATE TABLE routing_push_tokens (
    recipient_routing_id BYTEA       NOT NULL,
    provider             TEXT        NOT NULL
        CHECK (provider IN ('fcm', 'apns')),
    push_token           TEXT        NOT NULL,
    expires_at           TIMESTAMPTZ NOT NULL,
    last_seen_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    country              TEXT        NOT NULL DEFAULT 'UNDISCLOSED',
    PRIMARY KEY (recipient_routing_id, provider, push_token),
    CHECK (length(recipient_routing_id) BETWEEN 8 AND 64),
    CHECK (length(push_token) BETWEEN 1 AND 512),
    CHECK (length(country) BETWEEN 2 AND 32)
);

CREATE INDEX routing_push_tokens_recipient_idx
    ON routing_push_tokens (recipient_routing_id);

CREATE INDEX routing_push_tokens_expires_idx
    ON routing_push_tokens (expires_at);

CREATE TABLE relay_day_metrics (
    day_utc                   DATE   PRIMARY KEY,
    dispatch_success          BIGINT NOT NULL DEFAULT 0,
    dispatch_failure          BIGINT NOT NULL DEFAULT 0,
    routing_push_token_purges BIGINT NOT NULL DEFAULT 0
);

COMMIT;
