## ADDED Requirements

### Requirement: Housing wizard hosts the Mode simulation affordance

Housing plan step 1 SHALL host the Mode simulation button and dialog defined in `sandbox-mode-lifecycle`. This capability requires that housing authoring remain reachable without a pre-existing plan so users can enter sandbox before creating a simulated plan with bots.

#### Scenario: Step 1 shows Mode simulation when entry allowed
- **WHEN** the user opens housing plan authoring on step 1 and no real draft/active plan blocks entry
- **THEN** Mode simulation is shown per lifecycle requirements

### Requirement: Active hub offers one-shot bot expense simulation

When sandbox mode is active and the user is on the active housing plan hub, the application SHALL show an orange tile after the section divider that precedes “Submit an expense” and above that expense tile. Line 1 SHALL be the localized “Simuler une dépense d'un Bot” (or EN/ES equivalent). Line 2 SHALL be a smaller “Mode simulation” subtitle. The tile SHALL NOT open a form. Activating it SHALL immediately enqueue a fake inbound realized-expense proposal from a randomly chosen connected bot against a randomly chosen plan line, into the existing human review queue, and SHALL raise a local notification when notifications are permitted (otherwise in-app feedback). Amount SHALL equal that bot’s share for the chosen line multiplied by a random factor of 100%, 50%, or 150%. No proof photo SHALL be attached.

#### Scenario: Bot expense lands in review
- **WHEN** the user taps the bot expense tile with at least one connected bot and an active plan that has at least one line
- **THEN** a pending peer expense appears in the human review flow
- **THEN** a local notification or fallback in-app signal is produced without navigating to an expense form

#### Scenario: Tile only in sandbox
- **WHEN** sandbox mode is false
- **THEN** the bot expense tile is not shown

### Requirement: Minor amendments enabled; major change disabled

In sandbox mode on the active housing hub, “Modify the plan” (minor amendments) SHALL remain enabled and bots SHALL auto-accept those proposals. The major participation-change control (`housingAmendmentRosterChangeTitle` / equivalent) SHALL remain visible but disabled. Deep links or alternate navigation into major-change flows SHALL be blocked.

#### Scenario: Major change tile disabled
- **WHEN** sandbox is active on the active hub
- **THEN** the major change tile is visible and not actionable

#### Scenario: Minor amendment proceeds with bots
- **WHEN** the human submits a minor plan amendment in sandbox with connected bots
- **THEN** bots auto-accept and the amendment can complete without a second human device

### Requirement: Module home Vehicle tiles visible but disabled

On the main module home, while sandbox is active, Vehicle and Vehicle sharing tiles SHALL remain visible and SHALL be disabled so they do not enter those modules.

#### Scenario: Vehicle tiles disabled in sandbox
- **WHEN** sandbox is active on the module home
- **THEN** Vehicle and Vehicle sharing are visible and disabled
