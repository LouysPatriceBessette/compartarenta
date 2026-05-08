## Why

Users need a clear, trustworthy path from store install through first launch to a state where they can use shared expense accounting without confusion. That path must be specified so implementation, UX review, and store compliance (permissions, disclosures) stay aligned.

## What Changes

- Define behavior for **first launch** after installation (cold start, returning users, and upgrade paths at a high level).
- Define an **onboarding flow** (intro, progress, skip where allowed, persistence of completion).
- Define **initial configuration** (preferences and context needed before meaningful use: e.g., display identity, currency or number format, and any mandatory steps to join or create a shared accounting context).

## Capabilities

### New Capabilities

- `install-and-first-launch`: Requirements from install through first open and cold start.
- `onboarding-flow`: Requirements for the guided first-run experience and its completion state.
- `initial-configuration`: Requirements for settings and context collected during or immediately after onboarding.

### Modified Capabilities

- None.

## Impact

- Drives navigation, state persistence, and empty-state UX in the Flutter app.
- May interact with subscription checks and future E2EE setup flows (referenced only as integration points, not fully specified here).
