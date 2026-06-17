-- Entitlement service schema v1.
-- Durable state is limited to entitlement and gating metadata only
-- (subscription-entitlement-minimal-server-state).

CREATE TABLE IF NOT EXISTS schema_version (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  version INT NOT NULL
);

CREATE TABLE IF NOT EXISTS installations (
  installation_id TEXT PRIMARY KEY,
  trial_housing_consumed BOOLEAN NOT NULL DEFAULT FALSE,
  trial_housing_consumed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS housing_plans (
  plan_id TEXT PRIMARY KEY,
  lifecycle_state TEXT NOT NULL,
  trial_started_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  grace_ends_at TIMESTAMPTZ,
  active_use_started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS housing_plan_rosters (
  plan_id TEXT NOT NULL,
  revision_id TEXT NOT NULL,
  participant_installation_id TEXT NOT NULL,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (plan_id, revision_id, participant_installation_id)
);

CREATE TABLE IF NOT EXISTS housing_plan_active_revision (
  plan_id TEXT PRIMARY KEY,
  revision_id TEXT NOT NULL,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS housing_expense_decisions (
  plan_id TEXT NOT NULL,
  expense_id TEXT NOT NULL,
  participant_installation_id TEXT NOT NULL,
  decision_kind TEXT NOT NULL,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (plan_id, expense_id, participant_installation_id)
);

CREATE TABLE IF NOT EXISTS housing_plan_licenses (
  plan_id TEXT NOT NULL,
  participant_installation_id TEXT NOT NULL,
  license_state TEXT NOT NULL,
  expires_at TIMESTAMPTZ,
  reported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (plan_id, participant_installation_id)
);

CREATE TABLE IF NOT EXISTS license_receipts (
  id BIGSERIAL PRIMARY KEY,
  installation_id TEXT NOT NULL,
  module TEXT NOT NULL,
  platform TEXT NOT NULL,
  receipt_blob JSONB NOT NULL,
  validation_state TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO schema_version (id, version) VALUES (1, 1)
ON CONFLICT (id) DO UPDATE SET version = EXCLUDED.version;
