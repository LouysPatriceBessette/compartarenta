## 1. Settings UI Preview

- [x] 1.1 Reorganize the main Settings page into Language, Profile, Notifications, Units, About, and Privacy sections.
- [x] 1.2 Add a Notifications settings page with general permission status, general notification switch, Contacts category switches, Housing category switches, and sound controls.
- [x] 1.3 Add a Units settings page grouping currency, date format, and distance unit from the existing Settings page.
- [x] 1.4 Add an About settings page grouping environment, API base URL, and app version from the existing Settings page.
- [x] 1.5 Keep developer-only Settings items unchanged and visible only under their existing developer conditions.

## 2. Permission Timing

- [x] 2.1 Stop requesting notification permission during initial app load or onboarding.
- [x] 2.2 Add a reusable notification permission gate that checks system permission and requests it only after a user action.
- [x] 2.3 Invoke the reusable gate from Contacts > Invite someone.
- [x] 2.4 Invoke the reusable gate from the Housing plan summary Invite my participants action.

## 3. Preference Model

- [x] 3.1 Define local app preferences for general notifications, Contacts notification categories, Housing notification categories, and sound enabled/disabled.
- [x] 3.2 Persist category switch changes from the Notifications settings page.
- [x] 3.3 Normalize system permission state for display across web, Android, and iOS.
- [x] 3.4 Model sound choices as default/silent first, with future app-provided sounds only behind platform-specific channel and file handling.
- [x] 3.5 Default the app-level master notification switch to off on fresh installs and preference resets.
- [x] 3.6 Request system notification permission when the user turns the app-level master switch on, and keep the switch off if permission is not granted.
- [x] 3.7 Reconcile stale app-level enabled state when notification settings opens after system permission was revoked outside the app.

## 4. Verification

- [x] 4.1 Add widget coverage for the Settings navigation structure and Notifications page UI.
- [x] 4.2 Add tests for the reusable permission gate behavior when permission is already granted, denied, or unknown.
- [x] 4.3 Run `flutter test` for the mobile package.
- [x] 4.4 Run `dart analyze` for changed Dart files.
- [x] 4.5 Add developer-only Settings action to send a `TEST` notification through the effective local notification/browser notification path.
- [x] 4.6 Verify Chrome and Android behavior with the developer test notification action.
- [x] 4.7 Add Contacts fallback acceptance controls on a local-only contact when it has a pending incoming handshake.
- [x] 4.8 Add an explicit Contacts refresh action and targeted handshake polling logs so manual testing can distinguish "no relay envelope received" from "pending request ready to accept".
- [x] 4.9 Gate incoming Housing proposal FCM/local notifications behind the app-level notification switch and the Housing "Plan submission received" category switch.
