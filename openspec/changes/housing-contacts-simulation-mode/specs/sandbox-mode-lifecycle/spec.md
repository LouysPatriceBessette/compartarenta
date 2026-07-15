## ADDED Requirements

### Requirement: Sandbox mode flag survives database wipe

The application SHALL persist a boolean `sandboxMode` and a timestamp `sandboxEnteredAt` in preference storage that survives local database wipe. When `sandboxMode` is true, process bootstrap SHALL wire a non-HTTP in-process relay client suitable for multi-identity inbox delivery (FakeRelay or equivalent implementing the same `RelayClient` surface used by production) and SHALL start the PeerSimulator. When `sandboxMode` is false, bootstrap SHALL use the production HTTP relay client as today.

#### Scenario: Cold start after wipe in sandbox
- **WHEN** `sandboxMode` is true and the local database is empty after an enter-flow wipe
- **THEN** bootstrap attaches FakeRelay and PeerSimulator without requiring a user “seed” action
- **THEN** the production sync URL is not used for envelope transport

#### Scenario: Real mode bootstrap
- **WHEN** `sandboxMode` is false
- **THEN** bootstrap uses the production HTTP relay path
- **THEN** PeerSimulator is not started

### Requirement: Enter simulation from housing plan wizard step 1

The sole product UI to enter sandbox SHALL be on Housing plan authoring step 1 (participants). The control SHALL be an orange button labeled with the localized “Mode simulation” string, placed on the same row as Next, aligned to the start (left in LTR). Tapping it SHALL open a confirmation dialog. The dialog SHALL present the product-approved body (free simulation overview, advanced features not simulated, risk of missing real invitations, 8-hour return reminder) and actions Cancel and Simulate (localized). Confirming Simulate SHALL start the enter protocol.

#### Scenario: Button placement on step 1
- **WHEN** the user is on housing plan step 1 and sandbox entry is available
- **THEN** Mode simulation appears on the same footer row as Next, start-aligned
- **THEN** Next remains end-aligned

#### Scenario: Cancel keeps real mode
- **WHEN** the user opens the dialog and chooses Cancel
- **THEN** `sandboxMode` remains false
- **THEN** no wipe occurs

### Requirement: Sandbox entry is gated by real housing plan presence

The Mode simulation control SHALL be unavailable when a real housing plan draft or an active housing plan exists on the device. Re-entry into sandbox after a real plan exists is NOT required for this MVP.

#### Scenario: Active or draft plan blocks entry
- **WHEN** a real housing plan draft or active plan is present
- **THEN** Mode simulation is not available (disabled or absent per implementation, but not actionable)

#### Scenario: No real plan allows entry
- **WHEN** no real housing plan draft and no active housing plan exist and the user is on step 1
- **THEN** Mode simulation is available

### Requirement: Enter protocol uses dual-verified checkpoint before wipe

When the user confirms Simulate and the device has preservable operational data, the application SHALL: (1) export using the existing full-device export path; (2) verify integrity by decoding the export as in the import pre-check; (3) write a second copy to a fixed private application path outside the shared Documents/Compartarenta tree; (4) verify that second copy; (5) wipe the local database only if both copies verify. The preference `sandboxMode` SHALL be set true and `sandboxEnteredAt` recorded such that the next cold start boots sandbox. Wipe SHALL NOT be exposed as a user-facing “Reset local database” product action. After wipe, a full process restart SHALL be required (auto-relaunch if reliable; otherwise instruct the user to reopen the app).

#### Scenario: Wipe only after dual verify
- **WHEN** either export copy fails integrity verification
- **THEN** the database is not wiped
- **THEN** `sandboxMode` is not left inconsistently enabling sandbox without a successful enter

#### Scenario: Empty or non-preservable DB
- **WHEN** there is no preservable operational data to checkpoint
- **THEN** the enter flow sets sandbox prefs and restarts into sandbox without requiring a checkpoint file

### Requirement: Exit simulation restores checkpoint when present

Exiting sandbox SHALL wipe simulation database contents, import from the fixed internal checkpoint when it exists and verifies, clear `sandboxMode` (and related sandbox prefs as needed), and restart into real mode. When no checkpoint exists, exit SHALL wipe simulation data, clear sandbox prefs, and restart into a clean real-mode installation state.

#### Scenario: Exit with checkpoint
- **WHEN** the user confirms exit and a verified checkpoint exists
- **THEN** after restart the restored real data is present and `sandboxMode` is false

#### Scenario: Exit without checkpoint
- **WHEN** the user confirms exit and no checkpoint exists
- **THEN** the app returns to real mode with an empty operational DB

### Requirement: Exit controls via Simulation ribbon and eight-hour nudge

While `sandboxMode` is true, the Simulation ribbon SHALL be tappable. Tapping it SHALL open a confirmation dialog whose body is the localized equivalent of « Sortir du mode simulation? » and whose actions are Cancel (**Annuler**) and Yes (**Oui**). Choosing **Oui** SHALL run the exit protocol. Choosing **Annuler** SHALL dismiss the dialog and leave sandbox active. There SHALL NOT be a dedicated Settings row whose sole purpose is exiting simulation.

Independently, when the app is opened (or returns to foreground) and `sandboxEnteredAt` is at least 8 hours earlier, the application SHALL present a suggestion to return to real mode (dialog and/or local notification; if notification permission is denied, a snackbar or in-app dialog SHALL still convey the suggestion). That suggestion SHALL offer a path to run the same exit protocol.

#### Scenario: Ribbon tap opens exit dialog
- **WHEN** sandbox is active and the user taps the Simulation ribbon
- **THEN** the exit confirmation dialog is shown with Cancel and Yes actions

#### Scenario: Confirm exit from ribbon
- **WHEN** the user chooses Yes on the ribbon exit dialog
- **THEN** the exit protocol runs

#### Scenario: Cancel keeps sandbox
- **WHEN** the user chooses Cancel on the ribbon exit dialog
- **THEN** sandbox remains active and no wipe/import exit runs

#### Scenario: Eight-hour reopen nudge
- **WHEN** sandbox has been active for ≥ 8 hours and the user opens the app
- **THEN** a return-to-real suggestion is shown
- **THEN** the user can choose to exit simulation via that suggestion

### Requirement: Simulation ribbon visible in release builds

Whenever `sandboxMode` is true, the application SHALL show a persistent Simulation ribbon (text “Simulation” / localized equivalent) in the style and general position of the Flutter debug banner (upper corner), including on release/store builds. The ribbon MUST NOT depend solely on `debugShowCheckedModeBanner`.

#### Scenario: Release build shows Simulation
- **WHEN** a release build runs with `sandboxMode` true
- **THEN** the Simulation ribbon is visible

### Requirement: AppBar trailing clearance beside Simulation ribbon

When the Simulation ribbon is visible, any AppBar (or equivalent top chrome) that places a settings gear (or other trailing control) in the same upper-right corner SHALL reserve **40 logical pixels** of trailing space to the end/right of that control so the ribbon does not obscure or block taps on it. The 40 px value is the initial product trial and MAY be tuned later after device QA without changing the exit dialog contract.

#### Scenario: Settings gear remains tappable under ribbon
- **WHEN** sandbox is active on a screen that shows both the Simulation ribbon and a top-right settings action
- **THEN** at least 40 logical pixels of clearance exist trailing the settings control
- **THEN** the settings control remains reachable without tapping the ribbon

### Requirement: Hard gates for out-of-scope sandbox actions

When `sandboxMode` is true, the application SHALL block: user-initiated device export/import; external contact invitation code generation and redemption UI; Vehicle and Vehicle sharing module entry; major housing participation-change flows; production entitlement active-use reporting for sandbox activity; push/wake registration for relay delivery. Blocking SHALL be enforced in logic, not only by hiding controls.

#### Scenario: Export blocked in sandbox
- **WHEN** sandbox is active and the user opens Settings device export/import
- **THEN** export and import actions are unavailable or refused with feedback

#### Scenario: Vehicle entry blocked
- **WHEN** sandbox is active and the user taps Vehicle or Vehicle sharing on the module home
- **THEN** those tiles are visible but disabled and do not navigate into the modules

### Requirement: No payment reminders or device wake in sandbox

Sandbox mode SHALL NOT schedule housing payment reminders, relay expiry simulations, or device-wake push notifications.

#### Scenario: No reminder jobs in sandbox
- **WHEN** sandbox is active during an active housing plan
- **THEN** no payment-reminder or wake push is scheduled for that sandbox session
