# Entitlement server (Phase A + relay gating)

## Why

Housing licensing requires a canonical server-side source for trial state, accepted plan rosters, per-participant license coverage, and relay-facing allow/deny decisions (`licensing-trial-and-plan-entitlement`, `subscription-entitlement-minimal-server-state`). The relay must enforce gated housing operations without parsing business ciphertext (`relay-security-baseline`).

Phase A delivers the entitlement service, housing state machine, stub license reporting, and immediate relay integration. Phase B (Google Play receipt validation) and Phase C (Apple) follow; Android production ships before iOS.

## What Changes

- **New:** `entitlement/` Go service with its own PostgreSQL schema and HTTP API.
- **New:** Client endpoints to register installations, report housing metadata, and report license status (stub verifier until Play integration).
- **New:** Relay introspection endpoint; relay rejects gated housing envelopes when entitlement denies.
- **New:** Optional `entitlement_gate` field on `POST /v1/envelopes` for housing kinds 5–9.
- **Deferred:** Google Play Developer API validation (Phase B), Apple App Store Server API (Phase C), bundle SKUs, signed assertion-only path without introspection.

## Capabilities

### New Capabilities

- `entitlement-service-api`: Minimal durable state, housing lifecycle, introspection API.
- `relay-entitlement-gating`: Relay calls entitlement before accepting gated envelopes.

### Modified Capabilities

- `relay-security-baseline`: Gated housing operations are enforced when entitlement integration is configured.

## Impact

| Area | Impact |
|------|--------|
| `entitlement/` | New service; deploy alongside relay |
| `relay/` | Optional entitlement client; envelope request extension; metrics |
| `mobile/` | Not in Phase A (client wiring is a follow-up) |
| `docs/` | Entitlement deployment notes; audit checklist extension later |
