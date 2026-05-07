## Context

This change establishes an end-to-end, store-compliant delivery path for a new mobile app that will be published to Google Play and the Apple App Store. The primary uncertainty/risk in mobile store delivery is not just app code, but the surrounding lifecycle: secure signing/provisioning, environment separation (dev/staging/prod), repeatable builds, policy compliance, and store-specific submission workflows.

Constraints / assumptions for this design:
- The app should be cross-platform (Android + iOS) from a shared codebase.
- Builds must be reproducible and automatable (local developer builds + CI).
- Secrets (keystores/certificates/tokens) must not live in git and must be auditable.
- Store review requirements (privacy disclosure, metadata, screenshots, age rating, content policies) must be treated as requirements, not last-minute chores.

## Goals / Non-Goals

**Goals:**
- Define a cross-platform implementation approach that can produce store-uploadable artifacts for Android and iOS.
- Define a secure signing/provisioning workflow compatible with CI.
- Define a release workflow that supports: internal testing, beta distribution, production rollout, and quick rollback/halt.
- Define the minimal “store publishable” app surface area (crash-free, permission-sane, policy compliant, usable without surprises).

**Non-Goals:**
- Building every app feature in this change (product features beyond what is needed for store publishability can be scoped later).
- Designing brand identity/marketing copy in detail (this change only defines required assets and where they live).
- Picking vendor-specific tooling prematurely where it would constrain future architecture (exceptions: build/signing pipeline needs concrete choices).

## Decisions

### Cross-platform stack: Flutter as default

- **Decision**: Use Flutter for a single shared codebase producing Android and iOS apps, with local and CI builds driven by standard toolchains (Flutter + Gradle + Xcode), and optional automation via Fastlane where helpful.
- **Rationale**: Flutter provides a strong cross-platform story without depending on a hosted build/submission service plan. It keeps the delivery path self-managed and portable across CI providers while still supporting a mature ecosystem for store releases.
- **Alternatives considered**:
  - **React Native (including Expo/EAS)**: strong JS/TS ecosystem and can be fast to ship, but introduces dependency on Expo’s hosted services for some streamlined workflows and may require paid plans/usage depending on scale.
  - **Native (Kotlin/Swift)**: maximum control, but slower and duplicates work for MVP.

### Environments: dev / staging / prod with explicit configuration boundaries

- **Decision**: Define 3 environments with separate bundle IDs/application IDs, API base URLs, feature flags, and analytics keys.
- **Rationale**: Prevents accidental production data access during testing and allows clean store submissions and phased rollouts.
- **Implementation direction**: Use Flutter flavors/schemes (Android productFlavors, iOS schemes/configurations) plus runtime config (no secrets in the client).

### CI/CD: GitHub Actions + Flutter toolchain (optionally Fastlane) with provenance

- **Decision**: Automate build and release artifact generation in CI, storing build outputs and metadata (version, git SHA, build profile, changelog).
- **Rationale**: Eliminates “works on my machine” store submissions and provides traceability when investigating regressions.
- **Alternatives considered**:
  - **Fastlane-only**: powerful and common for store automation; still optional if we want to keep the initial pipeline minimal.

### Signing/provisioning: treat keys/certs as first-class assets with secure storage

- **Decision**: Use platform-recommended signing approaches:
  - Android: Play App Signing (upload key managed securely).
  - iOS: App Store Connect provisioning managed through Apple tooling (and optionally Fastlane match or App Store Connect API keys) with least-privilege tokens.
- **Rationale**: Minimizes key handling blast radius and improves operational safety.
- **Guardrails**: Never store raw keystores/certificates in repo; rotate credentials if exposure is suspected.

### Store readiness gating: define “release gates” before coding features

- **Decision**: Add a release checklist and enforce gates before production submission:
  - crash-free sessions target, Sentry/Crashlytics configured (or equivalent)
  - privacy disclosures complete
  - required store metadata/assets present
  - internal/beta testing completed with a go/no-go owner
- **Rationale**: Store publishing fails most often on process gaps, not code compilation.

## Risks / Trade-offs

- **[Flutter plugin/native integration complexity] → Mitigation**: Prefer stable, well-supported plugins; keep MVP scope within common capabilities; isolate platform-specific code behind clear interfaces.
- **[App Store review delays / rejections] → Mitigation**: Treat policy compliance as specs; draft review notes, test accounts, and privacy declarations early; avoid restricted permissions unless strictly needed.
- **[Secrets leakage] → Mitigation**: Centralize secrets in CI secret store; enforce `.gitignore` and secret scanning; document rotation steps.
- **[Environment drift between dev and prod] → Mitigation**: Single source of truth for config; CI builds every environment; verify bundle IDs and API endpoints per build profile.
- **[Operational complexity] → Mitigation**: Keep initial pipeline minimal (build + internal test distribution), then expand to submit/rollout automation once stable.

