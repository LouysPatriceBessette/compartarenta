## Context

Notifications are core infrastructure for every existing and future Compartarenta module. The current architecture decodes peer events only after the client receives an envelope through polling, which leaves any "killed app" use case effectively broken on both Android and iOS. The product owner has accepted that closed-app delivery requires a server-driven wake mechanism and has accepted the privacy trade-off this entails, scoped tightly to transport routing material.

Relevant constraints:

- The relay is privacy-sensitive and high-cost to change (release + audit). Per `relay-changes-minimize.mdc`, every relay edit must be justified.
- The privacy spec `subscription-entitlement-minimal-server-state` previously forbade any durable server-side mapping of users to anything other than subscription validation artifacts. This change explicitly relaxes that constraint for transport routing tokens.
- The relay carries only ChaCha20-Poly1305 ciphertext; it has no business-domain knowledge. Push payloads must preserve that contract.
- Web is dev-only. No production web UI is offered; web push is not implemented.
- Product model: **one active installation per user identity** (no cross-device sync; see `data-locality-and-client-storage`). The relay MAY store multiple push tokens per recipient routing id during token refresh or platform transitions; that is transport mechanics, not support for simultaneous multi-device use of the same identity.

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
- Multi-device identity sync or simultaneous use of one user identity on several devices (see `data-locality-and-client-storage`: one active installation per user; export/import is for device replacement only).
- A high-priority "VoIP-style" iOS notification path.
- Implementing every notification kind in V1. Only Contacts add requests are wired functionally; everything else continues to use the existing polling-based flow.
- Storing message content, message identifiers, or any business-domain metadata on the relay beyond the existing envelope TTL window.

## Decisions

### 1. Privacy posture: explicit exception, narrowly scoped

The privacy spec is amended to permit storing transport routing tokens. The exception is bounded by:

- **Schema scope**: a single table conceptually `routing_push_tokens(recipient_routing_id, provider, push_token, expires_at, last_seen_at, country)`. The `country` column is the only user-declared dimension and is optional (default `UNDISCLOSED`). No other column may be added without an additional privacy spec change.
- **Retention**: every row has a hard `expires_at`. The relay MUST purge expired rows during regular maintenance and SHOULD purge them on access. The default TTL is **14 days** from last successful keep-alive refresh, configurable through `ROUTING_PUSH_TOKEN_TTL_SECONDS` and applied to future registrations and refreshes only (existing rows migrate at their next refresh).
- **No payload coupling**: the relay MUST NOT cross-reference this table with envelope contents, ciphertext bodies, or any other table beyond the index lookup required to fan out a wake push.
- **No analytics coupling**: `last_seen_at` and `country` MAY be used to compute aggregate daily statistics (operator metric) but MUST NOT be exposed at row granularity, exported, or joined with any external user identifier.

**Product decision (2026-06-21):** The product owner confirms the relaxed privacy posture is **acceptable for the next relay audit**: durable storage of transport routing tokens with strict TTL (`expires_at`), plus `last_seen_at` for aggregate daily operator statistics only (no row-level export), and optional `country` under the same suppression rules. The bounded exception above is approved; no additional columns or row-granularity exposure without a follow-up privacy spec change.

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

### 3. Operator metric: daily snapshot via loopback endpoint and append-only file

The operator never queries the routing push token database directly. Instead:

1. The relay exposes a single statistics endpoint bound to the loopback interface only. Practical implementation choice: bind to `127.0.0.1` on a non-routable port and additionally rely on the operating system to restrict access to the dedicated relay user; a Unix domain socket is an equivalent acceptable alternative.
2. The endpoint accepts an optional `date=YYYY-MM-DD` query parameter; default value is the previous calendar day in UTC. It computes the requested day's aggregate snapshot at call time and returns it as JSON.
3. A cron job, whose script lives in this repository alongside the relay code so it is reviewed and audited like any other change, runs at **00:07 UTC** every day under the same operating-system user that owns the relay process. Concretely 00:07 UTC corresponds to roughly 23:07 in Los Angeles or 21:07 in Hawaii, and 04:07 in Montevideo or 06:07 in Madrid — late-night in the Americas, early-morning in Europe. The cron calls the endpoint for the previous calendar day and appends one line to the stats file.
4. The stats file (default location: `/var/lib/compartarenta-relay/stats/daily.jsonl`) is append-only by convention. Past lines are never modified, even if the cron is re-run. If the cron is re-run for the same day, it MUST detect that the line already exists and skip the append.

Each daily line contains:

- `date` — the calendar day the statistics describe (YYYY-MM-DD).
- `active_total` — count of distinct rows whose `last_seen_at` falls within the day.
- `by_country` — an object whose keys are ISO 3166-1 alpha-2 codes, `UNDISCLOSED`, and `OTHER`. The threshold rule below applies before serialization.
- `by_provider` — `{ "fcm": <count>, "apns": <count> }`.
- `dispatch_success_count` and `dispatch_failure_count` — wake dispatches that succeeded or failed against the upstream push provider during the day.
- `purge_count` — TTL purges executed during the day.
- `routing_push_tokens_row_count` — total live rows in the table at the moment the endpoint runs (point-in-time gauge).

The aggregation is performed in code that lives in this repository, not as ad-hoc DB queries, so the audit reviewer can verify what the endpoint can and cannot produce.

Acceptable extensions in future iterations include adding new technical counters without user dimensions. Adding any user dimension beyond `country` requires a spec amendment.

### 3a. Country aggregation, opt-in only

Country distribution is added with deliberate restrictions:

- **Opt-in.** A new app-level preference, off by default. Settings entry: "Disclose my country for anonymous statistics". When enabled, a localized dropdown lets the user pick a country; when disabled or never enabled, the client transmits `UNDISCLOSED` on every register and refresh.
- **Storage minimization.** A single `country` column on the routing push token table. No history is kept; refreshes overwrite the value.
- **Suppression threshold (hardcoded).** In the daily aggregation, any country with strictly fewer than 10 devices in the day is removed from the `by_country` map and its count is added to the `OTHER` bucket. The number `10` is hardcoded as a named constant in source so a reviewer can find it directly and so it cannot be silently relaxed via configuration. Changing it requires a code change and a code review pass.
- **UNDISCLOSED is reported separately.** Devices that did not opt in form their own bucket so the proportion of opt-in disclosure is itself visible without inferring on individual users.

Example daily line:

```json
{"date":"2026-05-18","active_total":1240,"by_country":{"CA":612,"FR":188,"US":140,"ES":97,"OTHER":58,"UNDISCLOSED":145},"by_provider":{"fcm":824,"apns":416},"dispatch_success_count":2911,"dispatch_failure_count":24,"purge_count":61,"routing_push_tokens_row_count":1273}
```

Alternatives considered:

- "Live histogram" / Prometheus-style metrics surface: rejected. Continuous exposure of `last_seen_at` semantics increases attack surface and is harder to audit than a single endpoint plus a stable file.
- Configurable suppression threshold: rejected. Letting the threshold drift via environment variable removes the audit guarantee. Hardcoded constant + code review is the stronger contract.

### 4. Push payload contract

Every wake push payload is data-only and limited to:

```json
{
  "v": 1,
  "kind": "wake_for_inbox",
  "recipient": "<routing-id>"
}
```

The `v` field is mandatory from day one. Rationale: protocol surfaces that live for years routinely need additive evolution (a future field for batch identifiers, idempotency hints, etc.). Including a version field now costs three bytes per push and prevents painful client/server desynchronization later. Clients MUST tolerate unknown fields and MUST fall back to the default wake handler if `v` is higher than they know.

The relay MUST NOT include any envelope id, sender id, message kind specific to a business domain (housing, contacts, etc.), or human-readable text. The OS notification UI is constructed entirely on the device after the app polls, decrypts, and runs its existing notification builders.

iOS caveat: a pure data-only push (`content-available: 1`, no `alert`) is delivered only on a best-effort basis. If field testing shows that critical messages are throttled, the relay MAY add a generic, non-personalized `alert` such as "New activity". The exact wording is owned by the mobile app team and ships in app-side localized resources; the relay must not embed the user-facing text directly. This degraded mode is acceptable per product owner sign-off.

### 5. Routing push token fan-out

The relay fans out to every active `(routing-id, provider, push_token)` row matching the envelope recipient. Per-row dispatch failures are individually logged with no message context, and rows whose providers report a permanent token error are purged eagerly. No "last device wins" logic.

**Product note:** Compartarenta assumes **one active installation per user identity** (`data-locality-and-client-storage`). Multiple tokens per routing id are for transport overlap (refresh, reinstall), not simultaneous multi-device sync.

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
- `ROUTING_PUSH_TOKEN_TTL_SECONDS` — default `1209600` (14 days).
- `ROUTING_PUSH_TOKEN_PURGE_INTERVAL_SECONDS` — *originally proposed at default `3600`*. **Implementation note (2026-05-19):** purge of expired routing push tokens is performed by the existing general sweeper that runs on `SWEEPER_INTERVAL` (default `1m`, which is strictly faster than the proposed 1 h cadence), so no dedicated variable was added at the binary level. Operators should rely on `SWEEPER_INTERVAL` if a different cadence is required; the original variable name is reserved should a future change reintroduce a separate cadence for token purges.
- `STATS_LISTEN_ADDR` — default `127.0.0.1:9091` (loopback only). Set to `-` to disable the listener entirely. (*Originally proposed as `STATS_ENDPOINT_LISTEN_ADDR`; renamed to `STATS_LISTEN_ADDR` at implementation.*) A Unix domain socket path is an acceptable alternative form.
- `STATS_FILE_PATH` — default `/srv/compartarenta-stats/daily.jsonl`. **Read by the cron script (`relay/scripts/daily-stats-append.sh`), not by the relay binary.** The binary only exposes the HTTP endpoint at `STATS_LISTEN_ADDR`; persistence of the daily JSONL is an operator-side concern. (*Original default `/var/lib/compartarenta-relay/stats/daily.jsonl` updated to keep the file outside the deploy user's `0700`-restricted home and under a dedicated directory the operator owns.*)

The audit checklist gains items asking the reviewer to confirm that these are present, that the table schema matches the spec, that no other column is silently added, that the suppression threshold is the hardcoded constant `10`, and that the stats endpoint is bound to loopback only.

### 11. Account and secrets sequencing

The relay needs FCM and APNs credentials at runtime, but the developer does not need every paid account immediately. Practical sequencing:

| Secret / account | Cost | When it becomes necessary |
|---|---|---|
| Firebase project + service account JSON (Android) | Free | Can be obtained immediately. Required to run the FCM dispatcher in production and to receive any FCM push on a real Android device. No paid Google account needed. |
| Apple Developer Program (iOS) | 99 USD/year | Required to obtain the APNs auth key, to install signed builds on real iOS hardware, and to test the APNs dispatcher end-to-end. iOS Simulator does not deliver pushes from a real APNs server, so a real device test is required. Defer until the iOS client implementation is ready to be tested in vivo. |
| Google Play Developer Account | 25 USD one-time | Required only to publish to the Play Store; not required for any FCM development, sideloaded test builds, or internal testing through manual APK install. Defer to release preparation. |
| App Store Connect | Included with Apple Developer Program | Required only to ship through TestFlight or the App Store. Defer to release preparation. |

The Go code for the dispatcher and the table schema can be developed and unit-tested with mocked providers before any of these accounts exist; integration testing on real hardware is what gates each account purchase.

## Risks / Trade-offs

- **Privacy delta is permanent** → mitigated by narrow scope, strict TTL, and explicit non-coupling rules. The audit document captures the exact contract.
- **iOS data-only delivery is best-effort** → mitigated by the option to add a generic non-personalized alert; documented as degraded mode that the product owner has pre-accepted.
- **Multiple push tokens per routing id during refresh overlap** → acceptable transport artifact; product does not support simultaneous multi-device use of one identity.
- **FCM/APNs as third-party dependencies** → operator already runs the rest of the stack; adding push provider secrets is incremental, not architectural.
- **Background task throttling** → if the OS denies a refresh window, the next foreground refresh fixes it; only sustained inactivity drops the registration.
- **Operator visibility of last_seen_at and country** → mitigated by routing all access through the loopback-only statistics endpoint, by the append-only file, by the suppression threshold of 10 for country buckets, and by the absence of any path that exposes row-level data. The DB itself is never queried directly by the operator.
- **Wake push triggers cause network traffic** → wake pushes are small and rare; the relay sends one per envelope per registered device. No batching is required for V1.
- **Country opt-in could still leak through fingerprinting** → mitigated by the suppression threshold (countries with < 10 active devices on a given day are bucketed into `OTHER`) and by no per-row export; pure aggregate publication of the daily file is the only intended consumption.

## Migration Plan

1. Ship the proposal, design, and spec deltas. Land them as a single change so the audit reviewer can trace the privacy posture in one place.
2. Implement the relay side first behind a feature flag (the table can exist before the dispatcher is enabled). Run the schema migration in the relay deployment and verify the purge job.
3. Implement the client side. Wire registration and keep-alive but do not yet hook the wake handler into the Contacts notifications.
4. Enable the wake handler for the Contacts add request kind.
5. Field test on TestFlight and Play internal track for at least one week to validate iOS opportunistic delivery and Android battery-optimization edge cases.
6. Roll out to production. Verify the daily stats cron fires at 00:07 UTC, that the stats file gets one line per day, and that the loopback endpoint refuses non-loopback callers.
7. Document the wake dispatch as a generic transport so subsequent notification kinds can be opted in by mobile-only changes.

Rollback: disable the relay-side dispatcher flag; the client keep-alive becomes a no-op against an endpoint that returns success without persisting; existing polling continues to drive notifications exactly as before. The schema and the audit posture remain documented even if the runtime is paused.

## Open Questions

- Exact TTL default: 14 days is the chosen starting point. Field testing may push this down toward 7 days or up if iOS background throttling proves more aggressive than expected.
- Whether to publish part or all of the daily stats file externally, and on what cadence. This is a product decision, not a technical one.
- Whether to add a complementary "rolling N-day active" series alongside the daily counts. Out of scope for V1 because it cannot be reconstructed from per-day counts without additional aggregation.
