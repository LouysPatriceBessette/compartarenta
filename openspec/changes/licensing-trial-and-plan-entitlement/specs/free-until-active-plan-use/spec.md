## ADDED Requirements

### Requirement: App is free and unlimited until a plan is actively in use
The application SHALL remain free with no feature limits as long as:

- there is not at least a second participant linked to an accepted expense plan, AND
- no synchronization has occurred due to a realized expense transaction.

Synchronizations caused by plan or contract modifications (plan renegotiation proposals, acceptance/rejection of plan changes) SHALL NOT, by themselves, start the trial.

#### Scenario: Single-user usage remains free
- **WHEN** the user has no linked peer participant for any accepted plan
- **THEN** the app remains fully usable without triggering a trial

#### Scenario: Plan edits sync does not start trial
- **WHEN** two participants are linked to an accepted plan and they synchronize only plan/contract changes (no realized expenses synced)
- **THEN** the plan does not enter trial solely due to those plan-sync events

#### Scenario: Realized expense sync starts active use
- **WHEN** a plan has at least two linked participants AND a synchronization event occurs due to a realized expense (an actual expense transaction recorded by a participant)
- **THEN** the plan transitions into “active use” and the 6-week trial start timestamp is recorded

