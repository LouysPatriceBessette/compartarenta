# Pre-submission checklist (MVP)

This checklist is meant to be completed **before** uploading to Google Play / App Store Connect.

## Build / quality gates

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Android `prod` **release** AAB builds successfully
- [ ] iOS `release` builds successfully on macOS (codesign plan confirmed)

## Environment sanity

- [ ] `dev`, `staging`, `prod` can be installed side-by-side
- [ ] Each environment shows the correct `Environment: ...` in Home

## Privacy / compliance

- [ ] Privacy policy is published at a stable URL and reachable
- [ ] Data inventory exists (what’s collected/shared, by which SDK)
- [ ] Store disclosures match actual behavior (Play Data Safety / Apple labels)

## Store listing content

- [ ] `store/listing/en-US` is complete (name, descriptions, support URL, privacy URL)
- [ ] Localization decision applied (e.g., `fr-FR` optional)
- [ ] Required screenshots exist per store requirements

## Operational readiness

- [ ] Crash reporting is configured (Sentry DSN) for staging/prod
- [ ] Rollout plan defined (staged rollout on Play; phased release plan on iOS)
- [ ] Support contact is monitored (email/URL)

