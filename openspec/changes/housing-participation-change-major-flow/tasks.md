# Tasks — housing participation change

- [x] Drift schema v20 + build_runner
- [x] Domain services under `housing/participation/`
- [x] Envelope kinds 10–12 + orchestrator handlers
- [x] Major change screen (3 buttons + dialogs)
- [x] Detail screen + red banner
- [x] Hub gates + past title
- [x] Navigation intent + push notifications
- [x] l10n fr/en/es
- [x] Unit tests (ratio redistribution, hub gates)
- [x] Major change invite-participant guidance dialog + FAQ anchor
- [x] Contact disconnect gate (active / vote-pending plans)
- [x] Agreement overlap voluntary-withdrawal exception
- [x] Agreement-end vote expiry settlement
- [x] Journal merge with amendments
- [x] Inactive settlement transfer UI + balance graph extension
- [x] Integration harness (3-participant happy paths)
- [x] Penalty ledger system expense publishing

## Android E2E QA (Maestro)

Partial coverage via programmatic seed + hub assertions (not full vote/sync flows):

- [x] E2E.1 Participation banner on last ack day: scenario `voluntary_withdrawal_ack_j5` (`qa-housing-participation-banner`).
- [x] E2E.2 Withdrawal effective, no banner: scenario `voluntary_withdrawal_effective`.

See `docs/qa-android-e2e.md`. Multi-participant relay mesh remains in
`relay_housing_participation_change_mesh_test.dart` and manual QA.

## Deferred — differential impact report only (wish list)

Before/after projected-obligation report — not blocking initial release. Product decision 2026-07-06. **Plan adaptation** (ratio redistribution, inactive participant, early-withdrawal penalty) is implemented above. See `dev-ideas/2026-06-27-wish-list.md` § 3.

- [ ] D.1 Differential impact report UI in voluntary withdrawal flow.
- [ ] D.2 Differential impact report UI in ejection flow.
- [ ] D.3 Tests for before/after obligation diff using `PlanProjection` rules.
