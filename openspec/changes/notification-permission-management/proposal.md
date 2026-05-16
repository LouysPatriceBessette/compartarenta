## Why

Notification permission is currently requested too early, during initial app load, before users understand why the app needs it. The app needs a reusable, user-controlled notification permission model that can be invoked from relevant flows and managed later from Settings.

## What Changes

- Add a notification permission management capability covering system notification permission, app-level notification categories, and sound preferences.
- Move notification permission prompts out of initial setup and into explicit user actions, starting with invitation-related entry points.
- Add Settings surfaces for notification management, units, and about information so users can review or change preferences outside of a specific flow.
- Introduce reusable UI/logic boundaries so future notification entry points can request permission consistently after a user action.
- Keep local actions from creating local notifications; notifications should generally correspond to peer-triggered events.

## Capabilities

### New Capabilities

- `notification-permission-management`: User-facing notification permission management, category preferences, sound preferences, and flow-triggered permission prompts.

### Modified Capabilities

- None.

## Impact

- Flutter mobile/web app settings UI and navigation.
- Notification initialization and permission request timing.
- Future notification event routing for Contacts and Housing.
- App preference storage for app-level notification categories and sound settings.
- Platform notification integrations: Firebase Messaging, browser notification permission, Android/iOS notification permission, and local notification display.
