## 1. Specs and copy

- [ ] 1.1 Confirm onboarding steps and which are mandatory vs skippable with product owner.
- [ ] 1.2 Write user-facing onboarding strings (English) and plan localization strategy.

## 2. Implementation (Flutter)

- [ ] 2.1 Add first-launch / onboarding completion persistence (secure storage or local DB flag with migration).
- [ ] 2.2 Implement onboarding route stack with back navigation rules per step.
- [ ] 2.3 Implement initial settings screen(s) bound to the configuration model.
- [ ] 2.4 Wire deep link or “join” entry if product requires joining a peer or space during setup (optional).

## 3. Quality

- [ ] 3.1 Add widget/integration tests for: cold start → onboarding → main shell; kill mid-flow → resume.
- [ ] 3.2 Add tests for permission request timing (requested only when needed).
