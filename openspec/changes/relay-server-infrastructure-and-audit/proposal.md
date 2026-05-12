## Why

The privacy-first sync architecture (`privacy-first-sync-architecture`) defines the **product semantics** of the relay (encrypted-only, no-persistence-after-delivery, TTL-bounded, proposal/accept/reject). It does **not** define how the relay is concretely deployed, where it lives, how the small amount of state it does keep is structured, or how a third party can **audit** that the deployed instance honors those semantics. As we move toward implementing the Contacts handshake (the first feature that actually requires the relay), we need a concrete deployment specification on an **existing VPS**, under a **dedicated sub-domain**, with the relay's small persistent state held in a **container-managed database** (Docker), AND a documented **audit posture** from day one so that what is publicly claimed about the relay can be independently verified.

## What Changes

- Define infrastructure topology: the relay is exposed under a **dedicated sub-domain** of an existing domain on an existing VPS, with TLS terminated at the public edge.
- Define container packaging: the relay process and its **state database** are deployed as containers (Docker / Compose-equivalent). State persistence is restricted to **named volumes** under documented retention rules.
- Define the **relay state schema** explicitly: the database holds only the data strictly required to route encrypted messages between users (contact-pair / device-pair relationships needed for delivery routing, idempotency keys with bounded TTL, and TTL-bounded undelivered ciphertext envelopes). It SHALL NOT hold user payload plaintext, expense data, contact display names, or avatars.
- Define **operational boundaries** consistent with `privacy-first-sync-architecture`: ciphertext is deleted after successful delivery to all intended recipients; undelivered ciphertext is deleted after TTL expiry; no long-term retention; idempotency entries are time-bound.
- Define a **security baseline** for the deployment: minimal exposed surface (only the relay endpoint), TLS only, no admin port reachable from the public internet, secrets management, automated patching policy, regular dependency audits, rate limiting and abuse controls.
- Define an **audit-from-day-one** posture: the deployment topology, container images, configuration, retention parameters (TTLs, idempotency window), and operational policies SHALL be documented in the public repository in a way that an external reviewer can compare claims with implementation. A periodic self-audit checklist SHALL be maintained, and the relay code/configuration deployed SHALL match the publicly documented version.
- Define **observability without payload visibility**: logs and metrics SHALL be sufficient for operational health (request counts, error rates, TTL expiry counts, queue depth) without recording message bodies, recipient mapping payloads, or anything that would weaken the no-persistence-after-delivery promise.
- Define **backups, disaster recovery, and rotation** rules that respect the no-long-term-retention promise: backups MAY exist only for the routing metadata strictly required and SHALL respect the same TTLs as live data; backups SHALL NOT extend the practical lifetime of user payloads.
- Define **DNS, certificate, and renewal** expectations for the sub-domain (managed certs, auto-renewal, no wildcard sharing with unrelated services on the same VPS).

## Capabilities

### New Capabilities

- `relay-deployment-topology`: Sub-domain, VPS placement, TLS edge, container packaging, networking, and isolation from co-tenant services on the same host.
- `relay-state-schema-and-retention`: Concrete schema boundaries (what the relay DB stores and explicitly does NOT store), TTLs, idempotency windows, and deletion timing.
- `relay-security-baseline`: Exposed surface, secrets handling, dependency hygiene, rate limiting, abuse mitigation, and admin access rules.
- `relay-observability-without-plaintext`: Logging and metrics requirements that preserve the no-plaintext promise.
- `relay-public-auditability`: Documentation, versioning, and review surfaces that let an external party verify the deployed relay matches the publicly stated behavior.

### Modified Capabilities

<!-- None. `privacy-first-sync-architecture` already specifies the relay's product-level semantics (encrypted-only, no-persistence-after-delivery, TTL, proposal/accept/reject). This change adds concrete deployment, schema-shape, and auditability requirements; it does NOT change those semantics. -->

## Impact

- Adds repo-visible infrastructure (Docker / Compose / config) and operational documentation.
- Introduces an operations and audit burden alongside the mobile app.
- Becomes a precondition for `contacts-module` to ship its handshake.
- Establishes a public reference point that the housing-plan sync (and future module sync) can rely on without re-defining infrastructure expectations.
- Forces an early decision about which existing domain hosts the sub-domain, and confirms that the relay does not share TLS material or admin scope with unrelated services on the same VPS.
