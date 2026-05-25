## Context

The mobile app performs substantial computation using data that must remain on the user device (shared expenses, agreed split ratios, recorded payments, and derived balances such as who owes whom). Peers synchronize **ledger proposals** through a server relay: a recipient **accepts** or **rejects** incoming proposals; only accepted rows become part of that device’s authoritative on-device ledger. A server validates subscription entitlement with minimal retained state. The relay must not retain delivered ciphertext after successful delivery (per TTL/ack rules). All user-to-user payloads are end-to-end encrypted.

## Goals

- Make the privacy posture **reviewable from source** where possible (client + any open server components).
- Keep server-side retained data **narrowly scoped** to subscription validation.
- Ensure relay behavior is **time-bounded** and **non-durable** for user payloads after successful delivery.

## Non-goals

- Choosing a specific database engine (SQLite, Isar, Hive, etc.) in this document.
- Choosing a specific transport (WebSocket, gRPC, HTTP long-poll) beyond generic requirements.
- Legal interpretation of GDPR or other regulations (handled in privacy policy and legal review).

## Architecture overview

```text
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│  User A     │  E2EE   │  Relay / API     │  E2EE   │  User B     │
│  (client DB)│◄───────►│  (entitlement +  │◄───────►│  (client DB)│
│             │         │   ephemeral q)   │         │             │
└─────────────┘         └────────┬─────────┘         └─────────────┘
                                 │
                                 ▼
                        Subscription / billing
                        (minimal durable records)
```

## Key decisions (to be refined during implementation)

1. **E2EE model**: Prefer asymmetric encryption for key agreement plus symmetric encryption for bulk payloads, or a pre-established sharing channel with rotated keys per space/group.
2. **Relay unit**: Encrypted **ledger sync message** (proposal, accept/reject, amended proposal) with TTL, max size, idempotency key, stable **message** and **proposal** identifiers, and explicit “delivered to device then delete ciphertext” semantics—distinct from “accepted into ledger.”
3. **Server truth for entitlement**: Store only what stores (Play/App Store) and your backend need to map a user or anonymous account to an active subscription window, plus the minimal trial / accepted-roster metadata needed for relay-gated housing operations.

## Relay-visible metadata for gated operations

The relay and entitlement layer may observe a minimal metadata surface for gated operations while leaving the business payload fully end-to-end encrypted.

For housing, the visible metadata may include:

- `module = housing`
- `message_kind`
- `plan_id`
- `revision_id` for plan/amendment response events
- `expense_id` for realized expense decision events
- `participant_installation_id`
- `decision_kind`
- sender / recipient opaque routing identities
- authorization scope or signed entitlement assertion id

This metadata exists so the entitlement service can reconstruct:

- the accepted active roster for a housing plan,
- whether any participating installation identity previously consumed housing trial,
- whether a realized expense has reached unanimous acceptance,
- whether the relay should allow or refuse a gated request.

The relay still does not read plan lines, proofs, amounts, rejection text, or other business-domain payload fields.

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Logs capture payload or PII | Structured logging policy: no bodies, short retention, redaction |
| Queue backups retain messages | Disable payload backup for relay queues or encrypt at rest with keys rotated frequently |
| Metadata correlation | Document what metadata exists (IP, timestamps) and retention |
| Key loss locks users out | Backup/recovery UX (user-controlled or optional cloud backup with separate consent) |

## Dependencies

- Store subscription APIs (Google Play / App Store) and server-side receipt validation.
- Cryptographic libraries suitable for mobile and server (validated, maintained).

## Open questions

- Anonymous vs authenticated accounts for relay addressing.
- Group size limits and fan-out strategy for relay.
- Whether the relay server code will be in the same public repository as the client.
