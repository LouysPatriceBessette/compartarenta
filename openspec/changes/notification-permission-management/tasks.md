## 1. Settings UI Preview

- [x] 1.1 Reorganize the main Settings page into Language, Profile, Notifications, Units, About, and Privacy sections.
- [x] 1.2 Add a Notifications settings page with general permission status, general notification switch, Contacts category switches, Housing category switches, and sound controls.
- [x] 1.3 Add a Units settings page grouping currency, date format, and distance unit from the existing Settings page.
- [x] 1.4 Add an About settings page grouping environment, API base URL, and app version from the existing Settings page.
- [x] 1.5 Keep developer-only Settings items unchanged and visible only under their existing developer conditions.

## 2. Permission Timing

- [ ] 2.1 Stop requesting notification permission during initial app load or onboarding.
- [ ] 2.2 Add a reusable notification permission gate that checks system permission and requests it only after a user action.
- [ ] 2.3 Invoke the reusable gate from Contacts > Invite someone.
- [ ] 2.4 Invoke the reusable gate from the Housing plan summary Invite my participants action.

## 3. Preference Model

- [ ] 3.1 Define local app preferences for general notifications, Contacts notification categories, Housing notification categories, and sound enabled/disabled.
- [ ] 3.2 Persist category switch changes from the Notifications settings page.
- [ ] 3.3 Normalize system permission state for display across web, Android, and iOS.
- [x] 3.4 Model sound choices as default/silent first, with future app-provided sounds only behind platform-specific channel and file handling.

## 4. Verification

- [ ] 4.1 Add widget coverage for the Settings navigation structure and Notifications page UI.
- [ ] 4.2 Add tests for the reusable permission gate behavior when permission is already granted, denied, or unknown.
- [x] 4.3 Run `flutter test` for the mobile package.
- [x] 4.4 Run `dart analyze` for changed Dart files.
