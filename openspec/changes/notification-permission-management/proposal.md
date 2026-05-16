## Why

Notification permission is currently requested too early, during initial app load, before users understand why the app needs it. The app needs a reusable, user-controlled notification permission model that can be invoked from relevant flows and managed later from Settings.

## What Changes

- Add a notification permission management capability covering system notification permission, app-level notification categories, and sound preferences.
- Move notification permission prompts out of initial setup and into explicit user actions, starting with invitation-related entry points.
- Add Settings surfaces for notification management, units, and about information so users can review or change preferences outside of a specific flow.
- Introduce reusable UI/logic boundaries so future notification entry points can request permission consistently after a user action.
- Make the app-level notification master switch default to off on fresh installs, request system permission when the user turns it on, and avoid attempting to revoke system permission when the user turns it off.
- Reconcile stale app-level notification state when the user later opens notification settings after revoking system permission outside the app.
- Add a developer-only test notification action to verify the effective notification permission path on web and native platforms.
- Keep local actions from creating local notifications; notifications should generally correspond to peer-triggered events.

## Capabilities

### New Capabilities

- `notification-permission-management`: User-facing notification permission management, category preferences, sound preferences, and flow-triggered permission prompts.

### Modified Capabilities

- None.

## Impact

- Flutter mobile/web app settings UI and navigation.
- Notification initialization and permission request timing.
- App-level versus system-level permission semantics and status reconciliation.
- Future notification event routing for Contacts and Housing.
- App preference storage for app-level notification categories and sound settings.
- Platform notification integrations: Firebase Messaging, browser notification permission, Android/iOS notification permission, and local notification display.
- Developer Settings diagnostics for notification delivery.
