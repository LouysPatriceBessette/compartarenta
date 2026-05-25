## ADDED Requirements

### Requirement: Onboarding explains the product’s core purpose
The onboarding sequence SHALL communicate, in plain language, that the app helps users track **shared expenses**, agreed **split ratios**, **payments**, and **who owes whom**, and that peer updates arrive as **proposals** the user can accept or reject (high-level only; detailed sync rules remain in `privacy-first-sync-architecture`).

#### Scenario: Value proposition is visible before deep configuration
- **WHEN** the user progresses through the first onboarding steps
- **THEN** they can understand why expense and balance data stays on-device and why peers send proposals, without opening external documentation

### Requirement: Onboarding welcomes the user and sets expectations (trial + privacy)
At the start of onboarding, the app MUST show a concise welcome message that:
- thanks the user for trying the app,
- explains that setup consists of configuring one or more “plans” (e.g., shared housing and/or car sharing),
- explains the 2-week real-mode trial period,
- reassures the user that the app does not collect their data,
- and makes it clear the user can uninstall if they are not satisfied with the conditions.

#### Scenario: User sees concise welcome and privacy reassurance
- **WHEN** the user opens the app on first launch and onboarding starts
- **THEN** the first onboarding screen shows a short welcome/trial/privacy message before asking for detailed configuration

### Requirement: Provide an initial concise copy draft
The specification MUST include an initial concise English copy draft for the welcome message so it can be iterated later.

#### Scenario: Copy exists for later refinement
- **WHEN** implementers build the first onboarding screen
- **THEN** they can use the draft copy as an initial baseline and replace/extend it later without changing the flow structure

### Requirement: Onboarding is structured as a linear or bounded graph with explicit progress
The onboarding flow SHALL define an ordered set of steps (or a small branching graph) with visible progress (e.g., step indicator or section titles). The user SHALL always understand which step they are on and how to go back when back is allowed.

#### Scenario: Back navigation respects step rules
- **WHEN** the user taps back on a step that allows backward navigation
- **THEN** they return to the previous step without losing already-validated inputs for steps that were completed

#### Scenario: Back on first step exits or minimizes app per platform norms
- **WHEN** the user invokes system back on the first onboarding step on Android
- **THEN** the app follows platform-appropriate behavior (e.g., leave onboarding to home screen) without corrupting partial state

### Requirement: Mandatory vs optional steps are explicit
Each onboarding step SHALL be classified as **mandatory** or **optional** in the specification implemented by the app. Optional steps MAY offer “Skip”. Mandatory steps SHALL NOT offer “Skip” unless skipping defers the step to in-app settings with a blocking banner until completed.

#### Scenario: Skippable step can be skipped
- **WHEN** a step is marked optional and the user taps Skip
- **THEN** the app advances and records that the step was skipped (if the product needs to prompt again later)

#### Scenario: Mandatory step cannot be skipped without deferral contract
- **WHEN** a step is mandatory and has no deferral contract
- **THEN** the user cannot reach the main shell without completing it or exiting the app

### Requirement: Onboarding completion is persisted
When the user completes all mandatory onboarding steps (and any configured optional path), the application SHALL persist an onboarding completion flag (or equivalent durable record) so restarts do not replay onboarding.

#### Scenario: Kill and relaunch after completion
- **WHEN** the user completes onboarding and force-stops the app before visiting the main shell
- **THEN** on next launch the app does not require repeating completed mandatory steps unless completion was not persisted successfully

### Requirement: Mid-onboarding interruption is resumable
If the user leaves the app during onboarding, the application SHALL resume at the earliest incomplete mandatory step, preserving inputs that were already saved to draft or settings storage.

#### Scenario: Resume after OS kills background app
- **WHEN** the user partially completes onboarding and the process is stopped by the OS
- **THEN** reopening the app returns them to the incomplete step with prior valid inputs restored where technically feasible

### Requirement: Legal and policy links are reachable during onboarding
Where the product requires acknowledgment of terms or a privacy policy before meaningful use, the onboarding flow SHALL surface links to those documents and record acknowledgment according to product policy.

#### Scenario: Privacy policy link works from onboarding
- **WHEN** the user opens the privacy policy link from onboarding
- **THEN** the document opens in an in-app browser or external browser and the user can return to onboarding without losing progress

### Requirement: Permission requests are deferred until needed
The onboarding flow SHALL NOT request sensitive OS permissions (e.g., notifications, contacts, location) unless the immediately following step requires them, and SHALL show an in-context rationale before the system dialog.

#### Scenario: No premature permission dialog
- **WHEN** the user is on early onboarding slides that do not use a protected capability
- **THEN** the app does not trigger unrelated OS permission prompts

### Requirement: Welcome message draft copy (initial, concise)
The app SHALL use the following initial draft copy (English) for the welcome screen, which may be refined later:

“Thanks for trying Compartarenta.
In the next steps, you’ll configure your sharing plan(s) (shared housing, car sharing, or both) and start a 6‑week real‑mode trial.
Your data stays on your device—this app does not collect it.
If these conditions don’t work for you, you can uninstall at any time.”

#### Scenario: Draft copy is shown verbatim initially
- **WHEN** the onboarding welcome screen is displayed
- **THEN** the screen shows the draft copy text (or a product-approved refinement) in the user’s selected language
