# Housing participation change (major flows)

## Why

The hub **Major change** action previously forked a hidden draft plan — a poor fit for roster changes (withdrawal, ejection, unanimous termination). Participants need explicit flows with relay sync, hub gates, ratio redistribution, and ledger-only inactive participants for post-departure debts.

## What changes

- Replace `HousingAgreementRenewalScreen` fork UX with three participation-change flows (#1 termination, #2 voluntary withdrawal, #3 ejection).
- Drift tables: `housing_participation_changes`, `housing_participation_decisions`, `housing_plan_memberships`, `housing_inactive_participants`.
- Client-only relay envelope kinds 10–12 (propose, decision, notify).
- Hub red banner, per-role tile gates, past-agreement title for departed members.
- Ratio redistribution on departure; inactive participant for settlement transfers (follow-up).

## Out of scope (this change)

- Relay Go server changes.
- Post-departure impact projections.
- Full journal merge with amendments (follow-up).

## Impact

| Area | Impact |
|------|--------|
| `mobile/lib/housing/participation/` | New domain services |
| `mobile/lib/db/app_database.dart` | Schema v20 |
| `mobile/lib/relay/envelopes.dart` | Kinds 10–12 |
| `mobile/lib/screens/housing/housing_active_plan_screen.dart` | Hub gates + banner |
