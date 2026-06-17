-- 0003_scheduled_notifications.sql — Relay-scheduled notification housekeeping.
--
-- Fifth category per `relay-state-schema-and-retention`: opaque scope ids,
-- scheduling instants, IANA time zones — no user-facing plaintext payloads.

BEGIN;

UPDATE schema_version SET version = 3, applied_at = now() WHERE id = 1;

CREATE TABLE scheduled_notification_targets (
    target_id              BYTEA PRIMARY KEY,
    domain                 TEXT NOT NULL
        CHECK (domain IN (
            'housing_payment',
            'housing_proposal_deadline',
            'contacts_invitation_expiry'
        )),
    scope_key              BYTEA NOT NULL,
    recipient_routing_id   BYTEA NOT NULL,
    reminder_kind          TEXT NOT NULL,
    period_key             BYTEA,
    recurrence_period_days INTEGER,
    due_at                 TIMESTAMPTZ,
    bound_at               TIMESTAMPTZ,
    generation             BIGINT NOT NULL,
    plan_generation        BIGINT,
    cancelled_at           TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (domain, scope_key, recipient_routing_id, reminder_kind, period_key)
);

CREATE INDEX scheduled_notification_targets_recipient_idx
    ON scheduled_notification_targets (recipient_routing_id)
    WHERE cancelled_at IS NULL;

CREATE TABLE scheduled_notification_fires (
    fire_id                BYTEA PRIMARY KEY,
    target_id              BYTEA NOT NULL REFERENCES scheduled_notification_targets(target_id),
    recipient_routing_id   BYTEA NOT NULL,
    fire_at                TIMESTAMPTZ NOT NULL,
    status                 TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'fired', 'cancelled')),
    fired_at               TIMESTAMPTZ,
    delivery_ack_at        TIMESTAMPTZ,
    wake_dispatch_id       BYTEA,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (target_id, fire_at)
);

CREATE INDEX scheduled_notification_fires_due_idx
    ON scheduled_notification_fires (fire_at)
    WHERE status = 'pending';

CREATE INDEX scheduled_notification_fires_undelivered_idx
    ON scheduled_notification_fires (recipient_routing_id, fired_at)
    WHERE status = 'fired' AND delivery_ack_at IS NULL;

CREATE TABLE recipient_notification_timezone (
    recipient_routing_id   BYTEA PRIMARY KEY,
    iana_timezone          TEXT NOT NULL,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (length(recipient_routing_id) BETWEEN 8 AND 64),
    CHECK (length(iana_timezone) BETWEEN 1 AND 64)
);

CREATE TABLE housing_reminder_plan_generation (
    plan_id                BYTEA PRIMARY KEY,
    generation             BIGINT NOT NULL,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (length(plan_id) BETWEEN 8 AND 64)
);

COMMIT;
