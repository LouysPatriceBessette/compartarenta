## Why

The product intends to be publicly auditable: users and reviewers must be able to verify that the application does not retain user data on servers beyond what is strictly necessary to validate subscription (usage rights). Rich operational data used for calculations must remain on the user device in a client-side database. Synchronized sharing between users must use a server only as a relay that does not retain payloads after successful delivery. Sync messages represent **proposals** (e.g., new expenses); recipients **accept** or **reject**; rejections require a new **amended proposal** from the originator. User-to-user exchanges must be encrypted.

## What Changes

- Define technical requirements for **local-first computation and storage** (client-side database, no mandatory upload of user payloads for core features).
- Define **minimal server state** for subscription validation only, with explicit boundaries on what identifiers and records may exist server-side.
- Define a **relay synchronization protocol**: encrypted payloads, delivery semantics, retention limits, and guarantees that the server does not keep a copy after successful relay.
- Define **end-to-end encryption** requirements for shared data (key distribution, forward secrecy where applicable, server visibility).
- Define **operational privacy** requirements (logging, backups, metadata, observability) so infrastructure behavior does not contradict the product promise.
- Define **verifiability** requirements so a public repository can support meaningful review (documentation, protocol specification, build and deployment transparency expectations).

## Capabilities

### New Capabilities

- `data-locality-and-client-storage`: Requirements for on-device persistence of user operational data (shared expenses, ratios, payments, balances) and **proposal-based** synchronization ownership rules.
- `subscription-entitlement-minimal-server-state`: Requirements limiting server-retained data to subscription validation and related non-payload metadata.
- `relay-sync-no-persistence`: Requirements for relay-based synchronization without durable storage of user payloads after successful delivery.
- `end-to-end-encryption`: Requirements for encryption of user-to-user exchanges and key handling such that relay operators cannot read plaintext.
- `operational-privacy-and-logging`: Requirements for logs, metrics, queues, backups, and incidental metadata retention.
- `threat-model-and-verifiability`: Requirements for documented threat model, public review surfaces, and alignment between claims and implementation.

### Modified Capabilities

- None (this change is additive; it may later cross-reference `mobile-app-privacy-compliance` in `mobile-app-store-release`).

## Impact

- Constrains backend API design, queue semantics, and deployment practices (no silent long-term payload retention).
- Requires a concrete cryptographic design and key lifecycle before implementing sharing.
- May require split licensing or documentation if server code is not fully public (claims must match what is verifiable).
