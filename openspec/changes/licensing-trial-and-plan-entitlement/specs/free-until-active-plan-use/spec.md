## ADDED Requirements

### Requirement: App is free and unlimited until a plan is actively in use
The application SHALL remain free with no feature limits as long as:

- there is not at least a second participant linked to an accepted expense plan, AND
- no synchronization has occurred due to a realized expense transaction.

Synchronizations caused by plan or contract modifications (plan renegotiation proposals, acceptance/rejection of plan changes) SHALL NOT, by themselves, start the trial.

Visibility of `plan_id` alone SHALL NOT start trial state on the entitlement service or relay.

#### Scenario: Single-user usage remains free
- **WHEN** the user has no linked peer participant for any accepted plan
- **THEN** the app remains fully usable without triggering a trial

#### Scenario: Plan edits sync does not start trial
- **WHEN** two participants are linked to an accepted plan and they synchronize only plan/contract changes (no realized expenses synced)
- **THEN** the plan does not enter trial solely due to those plan-sync events

#### Scenario: Realized expense sync starts active use
- **WHEN** a plan has at least two linked participants AND a synchronization event occurs due to a realized expense (an actual expense transaction recorded by a participant)
- **THEN** the plan transitions into “active use” and the 2-week trial start timestamp is recorded by the entitlement service

#### Scenario: Plan metadata alone does not start trial
- **WHEN** the relay or entitlement service sees a housing `plan_id` without a qualifying realized-expense synchronization event
- **THEN** no trial state is created solely from that `plan_id`

### Requirement: Trial eligibility is consumed per housing installation identity
Housing trial eligibility SHALL be tracked per app installation identity.

When a qualifying active-use event starts the housing trial for an accepted plan, the entitlement service SHALL mark every participating installation identity in that accepted roster as having consumed housing trial eligibility.

#### Scenario: Participating installations consume housing trial together
- **WHEN** the first qualifying realized-expense synchronization event starts trial for accepted housing plan P
- **THEN** every installation identity in P's accepted roster is marked `trial_consumed`

### Requirement: A new housing plan is not trial-eligible if any participant previously consumed housing trial
A newly accepted housing plan SHALL NOT become trial-eligible if any participating installation identity has previously consumed housing trial eligibility.

#### Scenario: Former trial user prevents a second housing trial
- **WHEN** a newly accepted housing plan includes at least one installation identity already marked `trial_consumed`
- **THEN** that plan does not receive a new housing trial period

