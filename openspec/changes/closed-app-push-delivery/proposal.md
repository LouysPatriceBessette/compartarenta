## Why

Today every user-visible notification fires only after the app process has already received a relay envelope through polling. If the OS has suspended or killed the app, the user gets nothing until they reopen the app. Notifications are core infrastructure for the rest of the product (contacts, housing plan offers, future modules), so the app needs a reliable "wake from sleep" transport before more notification surfaces are built on top of unreliable foundations.

This change introduces a closed-app push delivery mechanism that lets the relay wake a target device through FCM (Android) and APNs (iOS) for any future notification kind, while keeping server-side state minimal, audit-defensible, and naturally self-cleaning for inactive devices.

## What Changes

- Add a generic closed-app push delivery mechanism: the relay can dispatch a data-only push that wakes the app on Android and iOS so the app can poll, decrypt, and locally surface the notification. The push payload carries a stable schema version field from day one for forward compatibility.
- Persist a minimal transport-only routing table on the relay: `(recipient routing id, provider, opaque push token, expires_at, last_seen_at, country)` with a strict TTL (14-day default), no message payload data, and `country` as the only optional, user-opt-in field.
- Add a client-side **keep-alive** that refreshes the routing-token TTL while the device is genuinely active (app launches, wake-from-push events, opportunistic background refresh on Android `WorkManager` / iOS `BGAppRefreshTask`). Inactivity, uninstallation, or system permission revocation cause the registration to expire naturally on the next TTL cycle.
- V1 functional surface (the only user-visible behavior change): wake the app for incoming Contacts add requests. All other notification categories continue to operate exactly as today (local notifications gated on polling, all existing app-level switches respected).
- V1 infrastructure surface: the relay endpoints, the client transport, and the data model are generic enough to cover every existing and future notification category without further protocol changes.
- Drop the current privacy non-goal that forbade server-side mapping of users to delivery handles: the new mapping is explicitly scoped to transport routing material with TTL and is documented as such.
- Platforms: Android and iOS only. Web push is explicitly out of scope; web remains the dev-only path that continues to use foreground polling and the developer test notification action.
- **BREAKING (scope of privacy spec, not of public protocol)**: the privacy spec `subscription-entitlement-minimal-server-state` is amended to permit one additional category of durable server-side data: transport routing tokens with strict TTL.
- Move the relay envelope ingestion code path to fan out a best-effort wake push to all active tokens registered for the recipient routing id, with the payload limited to `{ v, kind, recipient }`. Multi-device users receive a push on every registered device.
- Add a daily statistics pipeline that does not require any human DB access: a localhost-only relay endpoint that returns aggregate counts for the previous calendar day UTC, and a cron job (visible and auditable in the repo) that calls it at 00:07 UTC and appends one JSON line per day to a stats file. The file is the only persistent surface of these statistics and can be selectively published.
- Add an opt-in country-of-use disclosure: a new app-level setting (off by default), a localized country picker, and a single optional `country` column on the routing token table. Used only for aggregate per-country counts in the daily statistics file. Countries below a hardcoded threshold of 10 active devices per day are bucketed into `OTHER` so small populations cannot be identified.
- Add purely technical counters (dispatch success / failure, purge count, current row count) to the same daily statistics file, sharing the same cron, endpoint and file.

## Capabilities

### New Capabilities

- `closed-app-push-delivery`: relay-triggered FCM/APNs wake-up transport, client-side token registration and keep-alive lifecycle, and the contract that the relay never embeds plaintext business data in push payloads. This capability self-contains the privacy contract for the new transport routing material so the audit reviewer can read it in one place.

### Modified Capabilities

- None in this change. Three other capabilities (`subscription-entitlement-minimal-server-state`, `relay-sync-no-persistence`, `notification-permission-management`) are still defined in unarchived predecessor changes; the orchestration of their updates is described in `tasks.md` and `design.md` below. Once those predecessor changes archive into `openspec/specs/`, a follow-up change MAY introduce explicit deltas that re-state the cross-cutting rules already captured in this capability.

## Impact

- Relay (Go service under `relay/`): new endpoints to register and unregister routing tokens, new storage with TTL purge, new FCM v1 and APNs dispatchers, new operator secrets and configuration, **release + audit cycle required**.
- Flutter mobile app: new `ClosedAppPushRegistrationService`, token plumbing on Android and iOS, integration with `PushNotificationService`, background message handler updates, integration with the existing notification preference model.
- Existing privacy spec deltas as listed above. Web is intentionally not extended.
- Documentation under `docs/`: relay deployment, relay audit checklist, contacts module relay payload, and the relay state schema documents are updated to describe the new transport routing table and its retention rules.
- Operations: relay deploy requires Service Account JSON for FCM v1 and an APNs key. Audit checklist gains items about token storage, TTL, and the contractual guarantee that no plaintext business data ever appears in push payloads.
