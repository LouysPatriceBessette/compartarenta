# Development roadmap

This document records the **current sequencing decision** for Compartarenta development. It supersedes any earlier informal ordering and is the source of truth for the order in which the OpenSpec changes are intended to be implemented.

It is a planning document, not a capability specification. Capability rules live in `openspec/changes/<change-name>/` and (after archival) in `openspec/specs/<capability>/`.

## Why the order changed

Three things shifted the order:

1. The licensing model is becoming **modular** (per module, with optional combined bundles). The existing `licensing-trial-and-plan-entitlement` change keeps its scope (housing) but is now one **instance** of the per-module model defined in the new `per-module-licensing-and-bundles` change.
2. Participants will be modeled as **Contacts** in a new top-level area. Modules will reference Contacts rather than author inline temporary participant rows. This becomes the first product feature that requires the encrypted relay to actually be running end-to-end.
3. The relay (already specified at the product-semantics level in `privacy-first-sync-architecture`) needs its concrete deployment plus a public audit posture before any feature can use it. That work is captured in the new `relay-server-infrastructure-and-audit` change.

The vehicle module is **not advanced enough** to spend time renaming or restructuring now; renaming "car" → "vehicle" is deferred and will happen alongside the vehicle module's actual implementation work, after the housing module is complete.

## Sequence

> The numbering below is the intended **implementation order**. Items within a step can overlap when independent, but each numbered step must reach a meaningful complete state before the next step starts depending on it.

### Step 1 — Contacts module (`contacts-module`)

- On-device Contact entity, list, edit, delete, disconnect, block.
- Generation and out-of-band sharing of unique invitation codes (entropy + checksum + nonce + expiry + revocation).
- Handshake protocol (`hello` / `ack`) running over the encrypted relay.
- Migration mirroring existing module participants into local-only Contacts.

Depends on (will require, at the time the handshake actually runs):
- `relay-server-infrastructure-and-audit` step (the handshake needs a deployed relay). On-device Contact features that don't need the relay can land before the relay is up.

### Step 2 — Housing module adopts Contacts

- Modify the housing flows so that "adding a participant" routes through the Contacts picker.
- Drop the inline temporary participant authoring path in housing.
- Add per-module display alias and historical display snapshots where useful.
- Track this in a follow-up housing-adoption change (to be created when this step starts). That change references `contacts-module-integration` rather than redefining what a Contact is.

### Step 3 — Vehicle module adopts Contacts and is renamed to "vehicle"

**Deferred until the vehicle module is actually advanced enough to spend time on.** No work is scheduled now.

When this step is started, it will:
- Rename existing `car-sharing-*` capability identifiers to `vehicle-*`.
- Route vehicle participants through the Contacts picker.
- Drop inline temporary participant authoring from vehicle flows.

### Step 4 — Relay server infrastructure and audit (`relay-server-infrastructure-and-audit`)

- Concrete deployment on the existing VPS under a dedicated sub-domain.
- Containerized relay + state database (Docker / Compose / equivalent), named-volume persistence.
- Explicit schema (routing relationships, idempotency entries, undelivered ciphertext envelopes, schema-version, sweeper checkpoint), TTLs, and deletion semantics.
- Security baseline (non-root containers, secret management, rate limiting, dependency hygiene, admin out-of-band only).
- Observability without payload visibility (metrics on a private endpoint, structured logs without ciphertext bodies, alerting).
- Public auditability from day one (audit checklist, tagged release matching deployed digest, baseline self-audit entry, quarterly cadence).

> Implementation note: although this step is listed after Steps 1 and 2 in product terms, the relay deployment must be **live** before Step 1's handshake can complete its first end-to-end run with two real devices. In practice, Step 4's repository skeleton, schema, audit checklist, and a development-environment deployment land **in parallel with** Step 1, and the production deployment goes live before Step 1's handshake feature ships to users.

#### Step 4 follow-ups (deferred until before the first public mobile release)

These items are NOT required for the development deployment of the relay (which is already live and serving `/healthz` end-to-end behind the documented Apache vhost). They MUST be resolved before the first public release of the mobile app that talks to this relay.

- **Inject a real build identifier into the relay binary at deploy time.** The relay's `/healthz` and `/readyz` responses expose a `build` field sourced from `internal/version.Build`, which is the placeholder string `"dev"` until overwritten via `-ldflags`. The wiring already exists end to end: the `Dockerfile` accepts `ARG BUILD_DIGEST` and passes it through `-ldflags="-X github.com/compartarenta/relay/internal/version.Build=${BUILD_DIGEST}"`; `compose.yml` plumbs `BUILD_DIGEST` and `RELAY_TAG` from the environment; `.env.example` documents them. What is missing is the **release procedure** that derives real values (typically the git short SHA, the release tag, or the immutable container image digest) and feeds them to `docker compose build` / `docker compose up` so that:
  - the audit-checklist requirement "tagged release matching deployed digest" (this Step) is satisfiable end-to-end without ambiguity,
  - operational triage can correlate a running binary with a specific source revision from `/healthz` alone, and
  - the `RELAY_TAG` used as the local image tag is no longer the literal `dev`, which would conflate distinct builds in `docker image ls`.

### Step 5 — Focus on completing the housing module

After Steps 1 and 2 land, attention focuses on completing housing:
- Finish the partially-implemented `licensing-trial-and-plan-entitlement` work scoped to housing.
- Finish the partially-implemented `expense-plan-contract-model` flows (some tasks remain).
- Apply the per-module licensing layer defined in `per-module-licensing-and-bundles` to housing as its canonical instance.
- Vehicle work remains paused.

## Modular licensing — where it sits in the order

`per-module-licensing-and-bundles` is **not a standalone shipping step**. It defines the per-module entitlement model and the store-mapping rules. Its concrete implementation lands in two places:

- The app's entitlement layer is refactored to be module-aware as part of Step 1 or Step 2 (whichever needs the entitlement layer first; in practice, Step 1's Contacts feature is free, so module-awareness is consumed first by Step 5's housing licensing).
- The Apple subscription group and Google Play subscription product for **housing** are created when Step 5 implements housing licensing. Bundles (e.g., "Housing + Vehicle") are not created until at least one second module is ready to ship.

## Mapping to the existing OpenSpec changes

| Change                                            | Role in the new order                                                                                                                                            | Status |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `app-onboarding-initial-setup`                    | Already mostly done. No re-sequencing needed.                                                                                                                    | In progress (most tasks complete) |
| `privacy-first-sync-architecture`                 | Product semantics of the relay. Unchanged. Continues to be the source of truth for relay behavior.                                                              | Not impacted by this roadmap |
| `client-db-selection`                             | On-device persistence choice. Continues to underpin all module data + Contacts.                                                                                  | Not impacted by this roadmap |
| `mobile-app-store-release`                        | Continues to apply. Per-module subscriptions will reference its release process.                                                                                 | Not impacted by this roadmap |
| `expense-plan-contract-model`                     | Belongs to Step 5 (complete housing).                                                                                                                            | In progress |
| `licensing-trial-and-plan-entitlement`            | Belongs to Step 5 (complete housing). Now treated as the housing **instance** of the per-module model.                                                          | Not started |
| `car-sharing-module`                              | Belongs to Step 3, which is deferred. No work scheduled until vehicle is ready.                                                                                  | Specified, not implemented |
| `ui-localization-fr-en-es`                        | Cross-cutting; tracked separately.                                                                                                                                | In progress |
| **NEW** `contacts-module`                         | Step 1.                                                                                                                                                          | Proposed |
| **NEW** `relay-server-infrastructure-and-audit`   | Step 4 (with dev-environment deployment in parallel with Step 1).                                                                                                | Proposed |
| **NEW** `per-module-licensing-and-bundles`        | Cross-cutting; consumed by Steps 1–5 as needed.                                                                                                                  | Proposed |

## What this roadmap deliberately does NOT do

- It does not change the product-level semantics of the relay (those live in `privacy-first-sync-architecture` and stay as-is).
- It does not rename the existing `car-sharing-module` change or its capabilities. That work is part of Step 3 when Step 3 actually starts.
- It does not lock in pricing decisions. Per-module and bundle prices are commercial decisions made before each module ships.
- It does not commit to specific dates. Sequencing is a partial order with named gates, not a schedule.

## Updating this roadmap

This file is a living document. Any change to the order, the gates between steps, or the deferral status of vehicle SHALL be made by editing this file in a dedicated commit (or pull request) with a brief rationale.
