## ADDED Requirements

### Requirement: CI produces reproducible build artifacts for each environment
The build pipeline SHALL produce reproducible Android and iOS artifacts for dev/staging/prod with traceability to source (git SHA) and configuration (build profile).

#### Scenario: CI build output includes provenance
- **WHEN** CI produces a build artifact
- **THEN** it records at least: git SHA, version/build number, build profile, and build timestamp alongside the artifact

### Requirement: Release pipeline supports internal testing before production
The release pipeline SHALL support distributing builds to testers prior to production rollout (e.g., Play internal testing, TestFlight).

#### Scenario: Create a beta release
- **WHEN** a beta release is triggered
- **THEN** Android and iOS builds are distributed to the configured tester channels

### Requirement: Automated checks gate production submission
Production submission SHALL be gated by automated checks that validate minimum quality and compliance readiness.

#### Scenario: Gate blocks production on failing checks
- **WHEN** required checks fail (e.g., tests, lint, build, required metadata/assets missing)
- **THEN** the pipeline does not proceed to the production submission step

