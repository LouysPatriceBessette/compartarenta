## 1. Specs and copy

- [x] 1.1 Confirm onboarding steps and which are mandatory vs skippable with product owner.
- [x] 1.2 Write user-facing onboarding strings (English) and plan localization strategy.
- [x] 1.3 Define the initial “welcome/trial/privacy” message and translate to supported locales (FR/EN/ES when localization lands).

## 2. Implementation (Flutter)

- [x] 2.1 Add first-launch / onboarding completion persistence (secure storage or local DB flag with migration).
- [x] 2.2 Implement onboarding route stack with back navigation rules per step.
- [x] 2.3 Implement initial settings screen(s) bound to the configuration model.
- [x] 2.5 Implement profile step: required display name + avatar selection (20 placeholder icons).
- [x] 2.6 Implement regional preferences step: currency, date format, km vs miles, and time zone policy.
- [x] 2.7 Implement plan-type selection during setup (housing only / car sharing only / both), with ability to add later.
- [ ] 2.4 Wire deep link or “join” entry if product requires joining a peer or space during setup (optional).

## 3. Quality

- [x] 3.1 Add widget/integration tests for: cold start → onboarding → main shell; kill mid-flow → resume.
- [x] 3.2 Add tests for permission request timing (requested only when needed). *(Covered by `notification-permission-management`: reusable gate + widget tests in `notification_permission_gate_test.dart`; onboarding no longer requests at cold start.)*
