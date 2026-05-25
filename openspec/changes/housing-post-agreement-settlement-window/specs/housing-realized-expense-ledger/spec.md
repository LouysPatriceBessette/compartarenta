## MODIFIED Requirements

### Requirement: Hub routes to monthly expense summary

The active agreement hub SHALL include **Recorded expenses** (localized) listing realized expenses with **published** status whose payment date falls in the selected calendar month (per device date semantics).

Month navigation SHALL be bounded by agreement dates using local calendar-month semantics:

- the first accessible month is the agreement `periodStart` month,
- the last accessible month is the agreement `periodEnd` month, and
- if `periodEnd` falls within five calendar days of the end of its month, navigation SHALL also include the following month.

When an agreement is settlement-open per `housing-agreement-amendment-and-closure`, the monthly summary SHALL continue to expose that settlement month even though the agreement is no longer in-force.

#### Scenario: March view excludes February payments

- **WHEN** the user views March summary on 2026-03-15
- **THEN** only published expenses with payment date in March 2026 appear

#### Scenario: Mid-month agreement end does not expose following month

- **WHEN** an agreement runs from 2026-05-25 to 2026-10-15
- **THEN** monthly navigation is limited to May 2026 through October 2026 inclusive

#### Scenario: Near-end-of-month agreement exposes following month

- **WHEN** an agreement runs from 2026-06-03 to 2026-10-28
- **THEN** monthly navigation is limited to June 2026 through November 2026 inclusive
