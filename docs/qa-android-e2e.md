# Manual Android QA / E2E

This document is the **user guide** for Compartarenta's local Android QA toolchain:
a pinned emulator, programmable clock, programmatic database seeding, and Maestro
UI flows with screenshots.

Runs are **manual** on your machine. There is **no CI** integration for this
toolchain.

## What you get

| Layer | Role |
| --- | --- |
| **Emulator** | Fixed AVD `Compartarenta-QA` (API 34, Pixel 7 profile) |
| **Clock** | Push a scenario date on the emulator only (`set_android_date.sh`) |
| **Seed** | Populate Drift + prefs from Dart (`qa_scenario_seed.dart`, debug Android) |
| **Maestro** | Navigate the app, assert UI, capture screenshots |
| **Orchestrator** | Shell scripts tie the layers together per scenario or for a full run |
| **Guardrails** | Manifest validation, Maestro ↔ Dart semantics checks, HTML report |

## Prerequisites

- **Android SDK** with `platform-tools`, `emulator`, and `cmdline-tools`
- `ANDROID_SDK_ROOT` or `ANDROID_HOME` (defaults to `~/Android/Sdk` when present)
- **Java 17+** (Gradle / Flutter Android builds)
- **Flutter** deps resolved for `mobile/` (scripts call `./tool/flutterw` via melos)
- **Python 3** (manifest parsing, verification, HTML report)
- **Network** for the first system-image download and Maestro CLI install
- **Maestro CLI** (installed once via `./tool/install_maestro.sh` → `~/.maestro/bin`)

Use a **physical device only if you know what you are doing**. By default, QA
scripts target the **emulator** (`emulator-*`) and refuse to change a phone's
clock.

## One-time setup

From the repository root:

```bash
./tool/melosw run qa:create-avd
./tool/melosw run qa:install-maestro
./tool/melosw run qa:build-apk
```

Equivalent shell scripts: `./tool/create_qa_avd.sh`, `./tool/install_maestro.sh`,
`./tool/build_qa_apk.sh`.

Verify the toolchain:

```bash
./tool/melosw run qa:verify
```

This checks phase-0 prerequisites (SDK, AVD, Maestro, optional APK/emulator),
validates all scenario manifests, and verifies Maestro `qa-*` ids against Dart
`Semantics.identifier` strings.

### Defaults (override via environment)

| Variable | Default |
| --- | --- |
| `COMPARTARENTA_QA_AVD_NAME` | `Compartarenta-QA` |
| `COMPARTARENTA_QA_APP_ID` | `com.compartarenta.compartarenta.dev` |
| `COMPARTARENTA_QA_SYSTEM_IMAGE` | `system-images;android-34;google_apis;x86_64` |
| `COMPARTARENTA_QA_DEVICE_PROFILE` | `pixel_7` |
| `COMPARTARENTA_QA_DEFAULT_TIMEZONE` | `America/Toronto` |
| `COMPARTARENTA_QA_API_BASE_URL` | `https://sync.incoherences.org` |
| `COMPARTARENTA_QA_APK_PATH` | `mobile/build/app/outputs/flutter-apk/app-dev-debug.apk` |

Local runtime state (clock snapshots) lives under `qa/.local/` (gitignored).
Scenario outputs live under `qa/artifacts/` (gitignored).

## Quick start

### Run one scenario end-to-end

```bash
./tool/melosw run qa:run-scenario -- settlement_open
```

This single command:

1. Starts the QA emulator (or waits if already running)
2. Builds and installs the dev debug APK (unless you pass `--skip-build` / `--skip-install`)
3. Sets the emulator clock from the scenario manifest
4. Seeds the database (clears app data, cold-starts once, applies seed)
5. Runs the Maestro flow with screenshots
6. Restores automatic date/time on the emulator

Artifacts: `qa/artifacts/settlement_open/<UTC-timestamp>/`

### Run every scenario + HTML report

```bash
./tool/melosw run qa:run-all-scenarios
```

Discovers all `qa/scenarios/*.yaml`, validates manifests and semantics first, then
runs each scenario sequentially. Output:

```
qa/artifacts/run-<UTC-timestamp>/
  index.html          ← open in a browser
  results.json
  period_end_day/     ← per-scenario Maestro output + PNG screenshots
  settlement_open/
  …
```

The APK is built/installed only for the **first** scenario. The emulator clock
is restored **once** after the full run.

Options (pass after `--` with melos):

| Flag | Effect |
| --- | --- |
| `--skip-build` | Reuse existing `app-dev-debug.apk` |
| `--skip-install` | Do not `adb install` |
| `--skip-restore` | Leave emulator clock as-is after the run |
| `--rebuild-each` | Build and install before **every** scenario (slow; debugging) |

### Manual exploration (no Maestro)

```bash
./tool/melosw run qa:start-emulator
./tool/melosw run qa:build-apk
./tool/melosw run qa:install-apk

./tool/set_android_date.sh 2027-08-11T09:00:00 America/Toronto
./tool/melosw run qa:seed -- settlement_open
# … use the app on the emulator …
./tool/restore_android_date.sh
```

Faster emulator resume (snapshot): `./tool/start_qa_emulator.sh --quick`

### Multi-device scenarios (two emulators)

Some flows (e.g. contact handshake) need **two Android emulators** coordinated by a shell orchestrator.

**One-time:** create persona AVDs (in addition to `Compartarenta-QA`):

```bash
COMPARTARENTA_QA_AVD_NAME=Louys-QA ./tool/melosw run qa:create-avd
COMPARTARENTA_QA_AVD_NAME=Monica-QA ./tool/melosw run qa:create-avd
```

**Happy path (inviter Monica-QA + invitee Louys-QA):**

```bash
./tool/melosw run qa:run-multi-scenario -- contact_handshake_happy_path
```

**Bug 9.1 probe (10 attempts, writes `bug_91_result.txt`):**

```bash
./tool/melosw run qa:run-multi-scenario -- contact_handshake_bug_91
```

**Housing proposal happy path (proposer Monica-QA + recipient Louys-QA, both Android):**

The coordinator runs **sequentially**: Monica completes the full plan wizard and sends;
Louys opens Housing, accepts the proposal, and lands on the **active agreement hub**
(`qa-housing-active-hub`). Monica then asserts the same hub — not an invite screen
showing “Louys Accepté” (unanimous activation remounts both devices to the hub).

Rebuild the debug APK after changing QA semantics or flows (do not use `--skip-build`
until a successful run with a fresh build):

```bash
./tool/melosw run qa:run-multi-scenario -- housing_proposal_happy_path
```

**Bug 1.22 probe (3 attempts, proposer identity drift, writes `bug_122_result.txt`):**

After drift + reconnect, the coordinator asserts Louys has **two** connected Monica-QA
rows (`qa-contacts-row-monica-qa` index **1**, plus banner
`qa-contacts-duplicate-connected-monica-qa`) — not merely one visible row. Then sends
the housing proposal. Reproduced when duplicate Monica and/or missing proposal UI. On first repro the
coordinator **completes that attempt** (send + recipient artifacts) then **stops** — remaining
attempts are not run.

Maestro debug output is written under short paths such as
`qa/artifacts/multi-housing_proposal_bug_122/<stamp>/attempt-001/handshake-after-drift/…`
(no doubled artifact root).

```bash
./tool/melosw run qa:run-multi-scenario -- housing_proposal_bug_122
```

Manifests live under `qa/multi_scenarios/`. Each declares `role_*` blocks (AVD, seed, flow) and a `coordinator` script in `tool/coordinators/`. The inviter exports the invitation short code to `app_flutter/compartarenta_qa_handshake_code.txt` for the orchestrator to pass to the invitee Maestro flow (`INVITE_CODE`).

**Relay / TLS note:** scenarios that hit the production relay (`https://sync.incoherences.org`) must keep `device_date` **inside the relay certificate validity window**. Housing settlement scenarios use 2027-08-11 for hub gating; contact-handshake manifests use the current calendar date instead — pushing the emulator past the cert `notAfter` yields `CERTIFICATE_VERIFY_FAILED: certificate has expired` on `establishRouting`, and Maestro will hang waiting for the invitation short code.

Artifacts: `qa/artifacts/multi-<scenario-id>/<UTC-timestamp>/`.

## Repository layout

```
qa/
  scenarios/*.yaml       Single-device scenario manifests
  multi_scenarios/*.yaml Multi-device manifests (roles + coordinator)
  flows/*.yaml           Maestro flows (UI steps, assertions, screenshots)
  artifacts/             Run output (gitignored)
  .local/                Clock restore state (gitignored)

mobile/lib/debug/
  qa_scenario_seed.dart       Seed dispatch + postconditions (debug Android)
  qa_scenario_seed_helpers.dart   Shared housing seed builders

tool/
  run_scenario.sh        One scenario end-to-end
  run_multi_device_scenario.sh  Multi-emulator orchestrator entry point
  coordinators/          Per-domain coordination scripts (contact handshake, …)
  run_all_scenarios.sh   All manifests + aggregated report
  seed_qa_scenario.sh    Seed only (used by run_scenario)
  qa_scenario_manifest.py   Parse / list / validate manifests
  verify_qa_semantics.py    Maestro qa-* ids ↔ Dart identifiers
  qa_run_report.py       Generate index.html from results.json
  verify_qa.sh           Full verification entry point
  …                      Emulator, APK, clock, Maestro install scripts
```

## How a scenario works

Each scenario is defined by a **manifest** in `qa/scenarios/<id>.yaml`:

```yaml
id: settlement_open
description: Day after periodEnd, non-zero balances — settlement open
device_date: "2027-08-11T09:00:00"
timezone: America/Toronto
seed: settlement_open
flow: qa/flows/settlement_open.yaml
screenshot_prefix: settlement_open
```

| Field | Purpose |
| --- | --- |
| `id` | Scenario name; **must match** the filename stem (`settlement_open.yaml`) |
| `device_date` | Passed to `set_android_date.sh` (emulator only) |
| `timezone` | IANA timezone for the clock push |
| `seed` | Id consumed by `kQaScenarioIds` in `qa_scenario_seed.dart` |
| `flow` | Maestro YAML path relative to repo root |

**Pipeline** (`run_scenario.sh`):

```
emulator → build/install APK → set clock → seed (pm clear + marker + cold start)
→ Maestro test → restore clock → write artifacts
```

**Seeding** (debug builds only):

1. `adb shell pm clear` on the dev app id
2. Write scenario id to `app_flutter/compartarenta_qa_seed` via `run-as`
3. Cold-start the app; `maybeApplyQaAndroidSeed` in bootstrap clears Drift, seeds, deletes marker
4. `force-stop` so Maestro can `launchApp` on a clean process with data intact

Seeds set **French UI** (`prefs.languageCode=fr`) so Maestro text assertions match.

## Scenario catalog

Ten manifests ship today (housing hub + plan-draft wizard). Anchor agreement
`periodEnd`: **2027-08-10** (noon UTC in seed data).

| Scenario id | Device date | Expected UI |
| --- | --- | --- |
| `period_end_day` | 2027-08-11 | Expense tile disabled (zero balances) |
| `settlement_open` | 2027-08-11 | Settlement tile visible |
| `settlement_window_open` | 2027-08-11 | Same seed/expectation as `settlement_open` (phase-1 POC id) |
| `settlement_last_day` | 2027-09-10 | Settlement tile + “available until” subtitle |
| `settlement_closed` | 2027-09-11 | Expense and settlement closed |
| `renewal_fork_visible` | 2027-08-15 | “New term from current plan” tile |
| `voluntary_withdrawal_ack_j5` | 2027-08-11 | Participation banner (last ack day) |
| `voluntary_withdrawal_effective` | 2027-08-11 | Withdrawal applied; no banner |
| `proposal_response_expired` | 2027-08-11 | Archive list shows expired proposal |
| `proposal_wizard_expenses` | 2027-06-15 | Plan-draft wizard: 3 expenses (equal / custom / Like), summary + response deadline |

List manifests from the shell:

```bash
python3 tool/qa_scenario_manifest.py --list
```

## Melos commands

Prefer `./tool/melosw` over `dart run melos` (avoids redundant `pub get`).

| Command | Action |
| --- | --- |
| `qa:create-avd` | Create `Compartarenta-QA` AVD |
| `qa:start-emulator` | Start emulator (cold boot) |
| `qa:install-maestro` | Install Maestro CLI |
| `qa:build-apk` | Build `app-dev-debug.apk` |
| `qa:install-apk` | Install APK on running emulator |
| `qa:verify` | Full toolchain verification |
| `qa:validate-scenarios` | Manifest / seed / flow checks only |
| `qa:verify-semantics` | Maestro ↔ Dart id alignment only |
| `qa:seed` | Seed one scenario (`-- <id>`) |
| `qa:run-scenario` | One full scenario (`-- <id> [options]`) |
| `qa:run-all-scenarios` | All scenarios + `index.html` |

Examples:

```bash
./tool/melosw run qa:run-scenario -- settlement_open --skip-build
./tool/melosw run qa:run-all-scenarios -- --skip-restore
./tool/melosw run qa:run-all-scenarios -- --skip-build --skip-install
./tool/melosw run qa:run-all-scenarios -- --no-retry
./tool/melosw run qa:seed -- voluntary_withdrawal_ack_j5
```

## Shell script reference

| Script | Purpose |
| --- | --- |
| `tool/qa_env.sh` | Shared constants and adb helpers (sourced by other scripts) |
| `tool/create_qa_avd.sh` | Create the QA AVD |
| `tool/start_qa_emulator.sh` | Start emulator (`--quick` for snapshot resume) |
| `tool/set_android_date.sh` | Set emulator date/time |
| `tool/restore_android_date.sh` | Restore automatic date/time |
| `tool/install_maestro.sh` | Install Maestro to `~/.maestro/bin` |
| `tool/build_qa_apk.sh` | Build dev debug APK |
| `tool/install_qa_apk.sh` | `adb install -r` on emulator |
| `tool/seed_qa_scenario.sh` | Seed one scenario |
| `tool/run_scenario.sh` | Full single-scenario orchestrator |
| `tool/run_all_scenarios.sh` | Discover all scenarios + HTML report |
| `tool/qa_finalize_run.sh` | Write `finished_at`, build `index.html`, restore clock |
| `tool/verify_qa.sh` | Combined verification |
| `tool/verify_qa_phase0.sh` | Prerequisites only (called by `verify_qa.sh`) |
| `tool/qa_scenario_manifest.py` | `--list`, `--validate`, or `manifest key` |
| `tool/verify_qa_semantics.py` | Maestro `qa-*` ↔ Dart check |
| `tool/qa_run_report.py` | Build `index.html` for a run directory |

### `run_scenario.sh` options

```bash
./tool/run_scenario.sh <scenario-id> [--skip-build] [--skip-install] [--skip-restore] [--artifact-dir DIR]
```

| Option | Effect |
| --- | --- |
| `--skip-build` | Do not run `build_qa_apk.sh` |
| `--skip-install` | Do not run `install_qa_apk.sh` |
| `--skip-restore` | Do not restore emulator clock after the scenario |
| `--artifact-dir DIR` | Write Maestro output to `DIR` (used by `run_all_scenarios.sh`) |

### `run_all_scenarios.sh` options

```bash
./tool/run_all_scenarios.sh [--skip-build] [--skip-install] [--skip-restore] [--rebuild-each] [--no-retry]
```

| Option | Effect |
| --- | --- |
| `--skip-build` / `--skip-install` | Passed to every scenario (first scenario still builds unless both set) |
| `--skip-restore` | Do not restore emulator clock after the full run |
| `--rebuild-each` | Build and install APK before every scenario |
| `--no-retry` | Do not retry failed scenarios once after System UI recovery |

Default artifact path when `--artifact-dir` is omitted:
`qa/artifacts/<scenario-id>/<UTC-timestamp>/`

## Maestro

### Application id

Every flow must declare the **dev** package:

```yaml
appId: com.compartarenta.compartarenta.dev
```

Maestro is invoked with `--udid <emulator-serial>` so a plugged-in phone is never
driven by mistake.

**Text selectors** (`assertVisible: "…"`) are treated as **regular expressions** and
must match the **entire** accessibility label of a node. Use `.*substring.*` for
partial matches (e.g. a subtitle with a date, or a banner prefixed with a name).

**`inputText`** (Maestro CLI) accepts **ASCII only** — no accented letters (see
[mobile-dev-inc/maestro#146](https://github.com/mobile-dev-inc/maestro/issues/146)).
Use unaccented QA fixture strings in flows (e.g. `Electricite`); keep French
**UI labels** in `tapOn` / `assertVisible` where Maestro reads rendered text, not
keyboard input.

Split grid **amount** and **percent** fields clear their text on focus so a new
value replaces the equal-share default (Maestro and manual entry).

Like-template dropdown: `qa-housing-expense-like-template`; menu options
`qa-housing-expense-like-option-<slug>` (e.g. `…-electricite` in
`proposal_wizard_expenses`).

Wizard expense rows: `qa-housing-wizard-expense-<slug>` (e.g. `…-loyer`,
`…-electricite`, `…-internet` in `proposal_wizard_expenses`). Prefer ids over
`assertVisible` on titles — list row text is not always exposed to Maestro.

Recurrence date range (debug builds): `showAppDateRangePicker` uses a Maestro-aware
picker with one semantics id per day (`qa-housing-expense-recurrence-day-YYYY-MM-DD`)
so day numbers are unambiguous when several months are visible. Flow: start day,
end day, then **`qa-housing-expense-recurrence-range-save`** (`enabled: true`) —
the picker does not auto-close after the end date.

### Shared subflow

`qa/flows/_enter_housing_hub.yaml` — launch app, tap housing tile (`qa-home-housing`),
wait for `qa-housing-active-hub`. Reused by most housing hub scenarios via `runFlow`
(`file: _enter_housing_hub.yaml`, path relative to the calling flow).

`_dismiss_ime_done.yaml` — tap Gboard's IME checkmark (bottom-right) to dismiss the
soft keyboard after `inputText`. Used by `proposal_wizard_expenses` on the pinned
Pixel 7 QA AVD; prefer this over `hideKeyboard` when the keyboard covers form actions.

`_save_expense_line.yaml` — dismiss IME (`_dismiss_ime_done.yaml`), wait until
`qa-housing-expense-form-save` is **visible**, then tap it (form
`bottomNavigationBar`; do not `scrollUntilVisible` for this id; do not refocus
text fields before save — that reopens the keyboard and hides the bar).

`qa-housing-expense-form` wraps the scrollable **body** only; the save id is a
sibling in `bottomNavigationBar` (not nested under the form container).

Prefer `id: "qa-home-housing"` over tapping `"Logement"` text: the home tile wraps
`Semantics(identifier: …)`, which is not always exposed as a plain text node to Maestro.

### Screenshots

`takeScreenshot: <name>` in flows writes PNGs into the scenario artifact
directory. The aggregated `index.html` thumbnails these files.

Capture a screenshot **only when a visible screen change is expected** — duplicate
frames hurt visual QA review.

| Pattern | Screenshots |
| --- | --- |
| Hub scenarios (`runFlow: _enter_housing_hub.yaml`) | `01_home` (settled home), `02_housing_hub` (after Logement tap) |
| `proposal_response_expired` | `01_home`, `02_expired_archive` (archive list) |
| `proposal_wizard_expenses` | `01_home`, `02_wizard_expenses_step`, `03_three_expenses`, `04_summary`, `05_response_deadline` |
| Scenario-specific asserts | No extra PNG after assertions on the same screen |

Before `01_home`, flows call `waitForAnimationToEnd` so the native Android splash
is gone. Hub scenarios assert tile/banner state on `02_housing_hub` without a
third identical capture.

## Semantics identifiers (`qa-*`)

Maestro does **not** see Flutter `Key`s. It uses the Android accessibility tree.
Stable targeting uses `Semantics(identifier: 'qa-…')` in **debug** builds, referenced
from flows as:

```yaml
- extendedWaitUntil:
    visible:
      id: "qa-housing-hub-settlement-due"
```

| Id | Surface |
| --- | --- |
| `qa-home-housing` | Home → Logement tile |
| `qa-housing-active-hub` | Active agreement hub screen |
| `qa-housing-hub-settlement-due` | Settlement-due expense tile |
| `qa-housing-hub-enter-expense` | Active-period expense entry tile |
| `qa-housing-hub-expense-disabled` | Disabled expense tile |
| `qa-housing-hub-renewal-fork` | Renewal fork tile |
| `qa-housing-participation-banner` | Participation change banner |
| `qa-housing-archive-expired` | Expired proposal archive card |
| `qa-housing-wizard-expenses-step` | Plan-draft wizard — expenses step header |
| `qa-housing-wizard-add-expense` | Wizard — add expense (+) |
| `qa-housing-wizard-next` | Wizard — Next / Finish footer |
| `qa-housing-wizard-summary` | Plan summary after wizard |
| `qa-housing-expense-form` | Full-screen expense line form |
| `qa-housing-expense-form-save` | Expense form — Enregistrer |
| `qa-housing-expense-name` | Expense form — name field |
| `qa-housing-expense-amount` | Expense form — amount field |
| `qa-housing-expense-split-pct-0` / `-1` | Split grid — percent row (0-based) |
| `qa-housing-expense-recurrence-confirm` | Recurrence confirm dialog |
| `qa-housing-expense-recurring-switch` | Expense form — Récurrent toggle |

**Verifier** (`verify_qa_semantics.py`):

- Every `qa-*` id in `qa/flows/**/*.yaml` must appear in `mobile/lib/**/*.dart`
- **`screens/car_sharing/`** is excluded (immature vehicle module)
- Dart ids not used in any flow → **warning** only (not a failure)

```bash
./tool/melosw run qa:verify-semantics
```

**Convention** when adding flows: `qa-<module>-<surface>-<state>` in Dart first,
then reference the same string in Maestro YAML.

## Verification

| Check | Command |
| --- | --- |
| Full | `./tool/melosw run qa:verify` |
| Manifests only | `./tool/melosw run qa:validate-scenarios` |
| Semantics only | `./tool/melosw run qa:verify-semantics` |
| Seed unit tests | `cd mobile && ./tool/flutterw test test/qa_scenario_seed_test.dart` |
| Tooling unit tests | `python3 tool/qa_tools_test.py -v` |

Manifest validation enforces:

- Required keys: `id`, `device_date`, `timezone`, `seed`, `flow`
- `seed` ∈ `kQaScenarioIds` in `qa_scenario_seed.dart`
- Flow file exists
- Filename stem matches `id`

## Adding a new scenario

1. **Implement seed** in `mobile/lib/debug/qa_scenario_seed.dart` (+ helpers if needed);
   add id to `kQaScenarioIds` and `mobile/test/qa_scenario_seed_test.dart`.
2. **Create manifest** `qa/scenarios/<id>.yaml` (filename stem = `id`).
3. **Create Maestro flow** `qa/flows/<id>.yaml`; add `Semantics.identifier` for any
   new `id:` assertions.
4. **Validate**:
   ```bash
   ./tool/melosw run qa:validate-scenarios
   ./tool/melosw run qa:verify-semantics
   ```
5. **Run**:
   ```bash
   ./tool/melosw run qa:run-scenario -- <id>
   ```

No edit to `run_all_scenarios.sh` is required — discovery is automatic.

## Troubleshooting

| Symptom | Things to check |
| --- | --- |
| Maestro not found | `./tool/install_maestro.sh`; ensure `~/.maestro/bin` on `PATH` |
| Wrong device targeted | Unplug phone or ensure only emulator shows `adb devices` as `device` |
| Seed timeout | Debug APK installed; `adb logcat -d \| grep 'qa seed'` |
| `run-as` seed failed | App must be debug flavor with `run-as` enabled |
| Maestro id not found | Identifier only in `kDebugMode`; rebuild APK after Dart changes |
| Clock not restored | Run `./tool/restore_android_date.sh`; check `qa/.local/clock-restore.env` |
| Stale APK | Omit `--skip-build` or run `./tool/melosw run qa:build-apk` |
| Maestro cannot see visible text (e.g. “Logement”) | Use `id: "qa-…"` — custom `Semantics` tiles expose `identifier`, not always searchable text |
| Text assert fails though string is on screen | Maestro `text` selectors are **regex** matching the **whole** node (e.g. subtitle includes a date; banner includes a name). Use `.*partial.*` or prefer `id: "qa-…"` |
| Maestro `Invalid File Path` on `runFlow` | Subflow `file:` must be **relative to the calling flow** (e.g. `_enter_housing_hub.yaml`, not `qa/flows/…`) |
| MissingPluginException after reinstall | Stop melos, force-quit app, cold start again (see melos workflow rules) |
| `System UI keeps stopping` during `run-all-scenarios` | Emulator instability after manual clock jumps / repeated `pm clear` — not a Maestro selector bug. `run_all_scenarios` retries each failed scenario once after `qa_recover_system_ui` (restarts `com.android.systemui`). If it persists: cold-boot the AVD (`qa:start-emulator` without `--quick`) |
| Maestro hangs on `Launch app` (no output for minutes) | Do **not** run `killall com.android.systemui` before every scenario (removed from the normal path). Cold-boot the emulator, then retry. `run_scenario.sh` caps Maestro at `COMPARTARENTA_QA_MAESTRO_TIMEOUT_SEC` (default 600 s) |
| Intermittent `qa-home-housing` not visible with System UI dialog on screen | Dismiss/recover System UI first; failure screenshots under `qa/artifacts/` usually show the modal |

`run_all_scenarios.sh` accepts `--no-retry` to disable the single automatic retry per scenario.

## Out of scope

This toolchain does **not** cover:

- CI / GitHub Actions headless runs
- Flutter **web** (Monica / Roberr dev browsers)
- Multi-device sync (separate apps per machine)
- Entitlement trial/grace tied to VPS clock
- Relay push cron / production relay-dependent flows without fixtures
- Vehicle / car-sharing module (`screens/car_sharing/`)

For the original design notes and effort estimates, see the personal roadmap in
`dev-ideas/2026-06-24-Comment-tester-E2E-à-implémenter.md` (gitignored).
