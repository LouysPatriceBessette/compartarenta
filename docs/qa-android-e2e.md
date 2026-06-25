# Manual Android QA / E2E (phase 0)

This document describes the **local, manual** Android QA toolchain introduced in
phase 0. There is **no CI** — run scripts when you need them.

Phase 0 delivers:

- A pinned AVD: `Compartarenta-QA`
- Emulator clock helpers: `set_android_date.sh`, `restore_android_date.sh`
- Maestro CLI installer
- Dev-flavor **debug** APK build + install scripts
- A verification script

Later phases add scenario manifests, Maestro flows, and DB seeding.

## Prerequisites

- Android SDK with `platform-tools`, `emulator`, and `cmdline-tools`
- `ANDROID_SDK_ROOT` or `ANDROID_HOME` (defaults to `~/Android/Sdk` when present)
- Java 17+ (for Gradle / Flutter Android builds)
- Network for the first system-image download and Maestro install

## One-time setup

From the repository root:

```bash
./tool/melosw run qa:create-avd
./tool/melosw run qa:install-maestro
./tool/melosw run qa:build-apk
```

Or run the underlying scripts directly (`./tool/create_qa_avd.sh`, etc.).

Verify:

```bash
./tool/melosw run qa:verify
```

### Defaults (override via environment)

| Variable | Default |
| --- | --- |
| `COMPARTARENTA_QA_AVD_NAME` | `Compartarenta-QA` |
| `COMPARTARENTA_QA_APP_ID` | `com.compartarenta.compartarenta.dev` |
| `COMPARTARENTA_QA_SYSTEM_IMAGE` | `system-images;android-34;google_apis;x86_64` |
| `COMPARTARENTA_QA_DEVICE_PROFILE` | `pixel_7` |
| `COMPARTARENTA_QA_DEFAULT_TIMEZONE` | `America/Toronto` |
| `COMPARTARENTA_QA_API_BASE_URL` | `https://sync.incoherences.org` |

Local runtime state (clock snapshots) is stored under `qa/.local/` (gitignored).

## Typical manual run

```bash
# 1. Start emulator (cold boot — matches scenario orchestration later)
./tool/melosw run qa:start-emulator

# 2. Install or refresh the app
./tool/melosw run qa:build-apk
./tool/melosw run qa:install-apk

# 3. Optional: push a scenario date (emulator only)
./tool/set_android_date.sh 2027-08-11T09:00:00 America/Toronto

# … manual exploration or (phase 1+) Maestro flows …

# 4. Restore host clock behaviour on the emulator
./tool/restore_android_date.sh
```

Use `./tool/start_qa_emulator.sh --quick` to skip `-no-snapshot-load` when you
want a faster resume.

## Script reference

| Script | Purpose |
| --- | --- |
| `tool/qa_env.sh` | Shared constants and adb/SDK helpers (sourced by other scripts) |
| `tool/create_qa_avd.sh` | Create `Compartarenta-QA` AVD |
| `tool/start_qa_emulator.sh` | Start the QA emulator |
| `tool/set_android_date.sh` | Set emulator date/time (refuses physical devices) |
| `tool/restore_android_date.sh` | Restore automatic date/time |
| `tool/install_maestro.sh` | Install Maestro CLI to `~/.maestro/bin` |
| `tool/build_qa_apk.sh` | Build `app-dev-debug.apk` |
| `tool/install_qa_apk.sh` | `adb install -r` the QA APK |
| `tool/verify_qa_phase0.sh` | Check phase-0 prerequisites |

Melos wrappers: `qa:create-avd`, `qa:start-emulator`, `qa:install-maestro`,
`qa:build-apk`, `qa:install-apk`, `qa:verify`.

## Maestro app id

When writing Maestro flows (phase 1), use the **dev** application id:

```yaml
appId: com.compartarenta.compartarenta.dev
```

## Safety notes

- When a **physical Android device** is also plugged in, QA scripts target the
  **emulator** (`emulator-*`) only. `install_qa_apk.sh` and `set_android_date.sh`
  refuse non-emulator serials.
- `set_android_date.sh` **refuses non-emulator** adb targets to avoid changing
  a physical phone's clock.
- Always run `restore_android_date.sh` after a dated scenario, or delete
  `qa/.local/clock-restore.env` only if you accept leaving auto-time disabled.
- Phase 0 does not seed the database or run Maestro flows — that is phase 1+.

## Out of scope (phase 0)

- Scenario library (`qa/scenarios/`), fixtures, orchestrator
- Screenshots and `run_scenario.sh`
- CI / GitHub Actions
- Web (Monica / Roberr) or multi-device sync

See `dev-ideas/2026-06-24-Comment-tester-E2E-à-implémenter.md` for the full
roadmap (personal notes, gitignored).
