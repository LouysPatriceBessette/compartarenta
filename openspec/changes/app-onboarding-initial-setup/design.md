## Context

This change specifies **client-visible behavior** only. It does not define cryptographic protocols or relay semantics (see `privacy-first-sync-architecture`).

## Intended user journey (high level)

1. User installs the app from the store and opens it for the first time.
2. App performs first-launch initialization (safe defaults, no blocking network for core navigation unless explicitly required).
3. User sees onboarding screens that explain the core value (shared expenses, balances, sync with peers).
4. User completes initial configuration (identity on device, currency/format, optional choices).
5. User reaches the main shell (home / ledger entry point) with a clear empty state or resume state.

## Principles

- **Progressive disclosure**: ask only what is needed to render the first useful screen; defer advanced options.
- **Resumable**: if the app is killed mid-onboarding, the user resumes at a sensible step without data loss of already-entered configuration.
- **Honest permissions**: request OS permissions only when a feature needs them, with an in-context rationale string.

## Non-goals

- Pixel-perfect visual design and copywriting (covered in implementation and content tasks).
- Full subscription purchase flow (only “where entitlement check fits” as a stub integration point if needed).
