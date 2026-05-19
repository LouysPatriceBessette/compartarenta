## Context

Notifications are core infrastructure for every existing and future Compartarenta module. The current architecture decodes peer events only after the client receives an envelope through polling, which leaves any "killed app" use case effectively broken on both Android and iOS. The product owner has accepted that closed-app delivery requires a server-driven wake mechanism and has accepted the privacy trade-off this entails, scoped tightly to transport routing material.

Relevant constraints:

- The relay is privacy-sensitive and high-cost to change (release + audit). Per `relay-changes-minimize.mdc`, every relay edit must be justified.
- The privacy spec `subscription-entitlement-minimal-server-state` previously forbade any durable server-side mapping of users to anything other than subscription validation artifacts. This change explicitly relaxes that constraint for transport routing tokens.
- The relay carries only ChaCha20-Poly1305 ciphertext; it has no business-domain knowledge. Push payloads must preserve that contract.
- Web is dev-only. No production web UI is offered; web push is not implemented.
- Multi-device per user is expected: one user may register several routing-id → token rows from different devices.

## Goals / Non-Goals

**Goals:**

- Make closed-app push delivery the durable transport for **all** future notification kinds, not only Contacts add requests. V1 only enables the Contacts add request kind functionally, but the transport, token lifecycle, and relay endpoints are designed once and reused.
- Treat the (recipient routing id, push token) mapping as transport routing material with strict TTL, and document the data minimization rules so the audit reviewer can validate them mechanically.
- Provide a self-cleaning lifecycle: any inactive device, uninstall, or revoked OS notification permission causes the registration to expire silently on the next TTL boundary.
- Provide a defensible operational metric (active-device count) without leaking message-level activity.
- Keep all user-visible notification controls (master switch, category switches, sound) authoritative: the closed-app push is just a wake signal, the actual notification is still built locally.

**Non-Goals:**

- Encrypted push payloads beyond what the OS push providers already protect.
- Decrypting or interpreting envelope contents on the relay.
- Web push delivery.
- A high-priority "VoIP-style" iOS notification path.
- Implementing every notification kind in V1. Only Contacts add requests are wired functionally; everything else continues to use the existing polling-based flow.
- Storing message content, message identifiers, or any business-domain metadata on the relay beyond the existing envelope TTL window.

## Decisions

### 1. Privacy posture: explicit exception, narrowly scoped

The privacy spec is amended to permit storing transport routing tokens. The exception is bounded by:

- **Schema scope**: a single table conceptually `routing_push_tokens(recipient_routing_id, provider, push_token, expires_at, last_seen_at)`. No other column may be added without an additional privacy spec change.
- **Retention**: every row has a hard `expires_at`. The relay MUST purge expired rows during regular maintenance and SHOULD purge them on access. The default TTL is **30 days** from last successful keep-alive refresh.
- **No payload coupling**: the relay MUST NOT cross-reference this table with envelope contents, ciphertext bodies, or any other table beyond the index lookup required to fan out a wake push.
- **No analytics coupling**: `last_seen_at` MAY be used to compute aggregate active-device counts (operator metric) but MUST NOT be exposed at row granularity, exported, or joined with any external user identifier.

Alternatives considered:

- Stateless ephemeral webhook: too brittle; the device would have to be opened often enough that the device is effectively a foreground app. Rejected on UX grounds.
- Long-lived persistence without TTL: rejected, indistinguishable from a regular user database and not defensible.

### 2. Keep-alive lifecycle (the chosen compromise)

The relay treats the registration as ephemeral: it has a hard TTL. The client is responsible for refreshing the registration before expiry whenever the device is genuinely active. This combines the "ephemeral" defensibility of the original Option C with practical persistence as long as the device is actually being used.

Refresh triggers on the client:

- App cold start, foreground resume, and after any sign of an actual user session.
- Receipt of a wake push (the device is alive, so we refresh opportunistically).
- An opportunistic background task scheduled on Android via `WorkManager` (periodic, requires network, no battery requirement) and on iOS via `BGAppRefreshTask` (best-effort, OS scheduled).
- Explicit re-registration on FCM/APNs token rotation events.

Refresh windows:

- Target refresh at roughly `TTL − 7 days` so a single skipped opportunity still leaves several days of headroom.
- Hard back-off and silent failure if the OS denies background execution; the next foreground refresh fixes it.

Natural expiry conditions (no special code path required):

- Uninstall — device never refreshes, server purges at `expires_at`.
- OS notification permission revoked — client unregisters proactively; if it cannot, the token becomes invalid at FCM/APNs and the relay purges it on the next dispatch error.
- Device powered off or kept offline for > TTL — server purges at `expires_at`.

This satisfies the product owner's stated criteria: data is ephemeral by construction, but the keep-alive prevents accidental drops for users who simply have not opened the app this week.

Alternatives considered:

- Fixed long TTL with no keep-alive: drops legitimate active users who happen not to launch the app every N days. Rejected on UX.
- Forced foreground re-registration only: same drawback, with the additional problem that some users open the app rarely enough to never reach a re-registration.
- Refresh on every push wake only: works for chatty users but degrades for users who get no traffic. The Android/iOS background tasks fix this.

### 3. Operator metric: active devices

Aggregate `last_seen_at` is exposed only as a count or histogram bucket, never per-row. Acceptable counters include:

- Devices active in the last 1 / 7 / 30 days.
- Devices by provider (FCM vs APNs).
- TTL purge counts.

This is the commercially defensible metric described by the product owner.

### 4. Push payload contract

Every wake push payload is data-only and limited to:

```
{
  "kind": "wake_for_inbox",
  "recipient": "<routing-id>"
}
```

The relay MAY add a stable schema version field. The relay MUST NOT include any envelope id, sender id, message kind specific to a business domain (housing, contacts, etc.), or human-readable text. The OS notification UI is constructed entirely on the device after the app polls, decrypts, and runs its existing notification builders.

iOS caveat: a pure data-only push (`content-available: 1`, no `alert`) is delivered only on a best-effort basis. If field testing shows that critical messages are throttled, the relay MAY add a generic, non-personalized `alert` such as "New activity". The exact wording is owned by the mobile app team and ships in app-side localized resources; the relay must not embed the user-facing text directly. This degraded mode is acceptable per product owner sign-off.

### 5. Multi-device fan-out

The relay fans out to every active `(routing-id, provider, push_token)` row matching the envelope recipient. Per-row dispatch failures are individually logged with no message context, and rows whose providers report a permanent token error are purged eagerly. No "last device wins" logic.

### 6. V1 functional scope: Contacts add requests only

The mobile app initially wires only the Contacts add request path through the wake mechanism. Other peer events (Contacts disconnect, Housing plan offer, plan responses, etc.) continue to use the existing polling-based local notification path. Subsequent changes can opt each category into wake dispatch one by one without protocol changes because the relay-side dispatch is generic.

### 7. Platforms

Android and iOS only. Web continues to be a development surface; the existing developer test notification action covers web verification. Production web users do not exist.

### 8. Relay integration point

Wake dispatch is added in the same code path that finalizes envelope persistence in the relay inbox. Dispatch failures MUST NOT prevent envelope delivery; they are logged with provider, error class, and no payload content.

### 9. Storage and indexes

- Primary key `(recipient_routing_id, provider, push_token)`.
- Index on `recipient_routing_id` to support fan-out.
- Index on `expires_at` to support purge.
- No index on `last_seen_at` (only used for aggregate counts).

### 10. Configuration and secrets

New environment variables for the relay:

- `FCM_SERVICE_ACCOUNT_JSON_PATH` — file path to Google service account JSON for FCM HTTP v1.
- `APNS_AUTH_KEY_PATH` — file path to APNs `.p8` key.
- `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_ENVIRONMENT` (`sandbox` / `production`).
- `ROUTING_PUSH_TOKEN_TTL_SECONDS` — default `2592000` (30 days).
- `ROUTING_PUSH_TOKEN_PURGE_INTERVAL_SECONDS` — default `3600`.

The audit checklist gains items asking the reviewer to confirm that these are present, that the table schema matches the spec, and that no other column is silently added.

## Risks / Trade-offs

- **Privacy delta is permanent** → mitigated by narrow scope, strict TTL, and explicit non-coupling rules. The audit document captures the exact contract.
- **iOS data-only delivery is best-effort** → mitigated by the option to add a generic non-personalized alert; documented as degraded mode that the product owner has pre-accepted.
- **Multi-device users get multiple pushes** → acceptable; better than picking a single "primary" device incorrectly.
- **FCM/APNs as third-party dependencies** → operator already runs the rest of the stack; adding push provider secrets is incremental, not architectural.
- **Background task throttling** → if the OS denies a refresh window, the next foreground refresh fixes it; only sustained inactivity drops the registration.
- **Operator visibility of last_seen_at** → mitigated by exposing only aggregate metrics; row-level data is not exported and not joined with subscription tables.
- **Wake push triggers cause network traffic** → wake pushes are small and rare; the relay sends one per envelope per registered device. No batching is required for V1.

## Migration Plan

1. Ship the proposal, design, and spec deltas. Land them as a single change so the audit reviewer can trace the privacy posture in one place.
2. Implement the relay side first behind a feature flag (the table can exist before the dispatcher is enabled). Run the schema migration in the relay deployment and verify the purge job.
3. Implement the client side. Wire registration and keep-alive but do not yet hook the wake handler into the Contacts notifications.
4. Enable the wake handler for the Contacts add request kind.
5. Field test on TestFlight and Play internal track for at least one week to validate iOS opportunistic delivery and Android battery-optimization edge cases.
6. Roll out to production, monitor active-device counts and purge counts.
7. Document the wake dispatch as a generic transport so subsequent notification kinds can be opted in by mobile-only changes.

Rollback: disable the relay-side dispatcher flag; the client keep-alive becomes a no-op against an endpoint that returns success without persisting; existing polling continues to drive notifications exactly as before. The schema and the audit posture remain documented even if the runtime is paused.

## Open Questions

- Exact TTL default: 30 days is the proposed starting point. Field testing may push this to 14 or 45 days.
- Whether the wake push schema needs a version field beyond `kind`. Likely yes, but the version field placement (top-level vs nested) is left to implementation.
- Whether the developer test notification action on web should be extended to simulate a wake push round trip. Most likely not necessary for V1.
