# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

- [ ] **License vhost — remove dev CORS for `http://localhost:5001`** (ops, before production web).  
  Dev QA added CORS on `license.incoherences.org` so Flutter web (`run:dev:web`)
  can call `registerInstallation` / `reportPlanRoster` from the browser. **Remove
  or replace** the `<LocationMatch "^/v1/">` CORS block in the deployed license
  Apache vhost when shipping a real web origin (or when dev web no longer targets
  prod license). Template:
  `entitlement/deploy/apache2/license-vhost.conf.template`. **VPS scope:** virtual
  host only — no entitlement container or relay release required.

- [ ] **Relay `/healthz` — human-readable on mobile** (ops / QA prerequisite).  
  Today `GET /healthz` returns raw JSON only; on a phone browser it is tiny, top-left,
  and unusable for quick “is the relay up?” checks during multi-device manual QA
  (see 2026-06-16 transfer expense test). Add a minimal mobile-friendly page
  (status, build digest, schema version) — via relay `Accept` negotiation, a small
  static Apache page, or both. **Do before inviting non-developers to manual relay QA.**

- [ ] **Housing balance chart — roster SVG overflow with inactive participants** (bug, minor).  
  Active roster is capped at **8** participants because only eight due-split SVG layouts exist. When **inactive participants** retain non-zero balances, the UI may need to show **more than eight** balance rows; relying on the active-roster cap alone can overflow or hide labels. Inactive settlement tiles landed on the balances screen (2026); chart/legend layout still needs a pass.

- [ ] **Rich text editor for multiline agreement fields** — Housing and car-sharing agreement rules (custom rule body, building rules, suggestion templates, withdrawal notes). Replace plain `TextField` with a lightweight rich editor (bold, lists optional later) so authors are not steered toward manual bullet characters in copy.

- [ ] **Housing — post-activation onboarding swiper** (deferred UX).  
  Multi-card dismissible explainer after unanimous activation (expenses, proofs, peer review, balances, amendments, export). Card copy **not** in OpenSpec yet.  
  **Depends on:** hub implemented (`housing-active-agreement-operations`).  
  **Track:** `openspec/changes/housing-active-agreement-operations/design.md` § Deferred UX.

- [ ] **Mobile dependencies — phase 3 (remaining majors).**  
  `go_router`, `flutter_secure_storage`, `app_links`, … as features need them.  
  **Mobile-only**; relay wake stays on `closed-app-push-delivery`.  
  **Scope:** `mobile/` + workspace `pubspec.lock` only.

## Done

- [x] **Android local E2E QA toolchain (Maestro + emulator + seed + orchestrator)** — Phases 0–3 (2026-06).
  Pinned AVD, programmable clock (`set_android_date.sh`), debug-Android DB seed
  (`qa_scenario_seed.dart`), nine housing end-of-agreement Maestro scenarios,
  `Semantics.identifier` (`qa-*`) guardrails, `run_all_scenarios.sh` with
  manifest discovery + aggregated HTML report (`qa_run_report.py`), Melos scripts
  (`qa:run-scenario`, `qa:run-all-scenarios`, `qa:verify`). User guide:
  `docs/qa-android-e2e.md`. **No CI** (manual runs only). Covers hub gating for
  settlement window, renewal fork, participation-change banner, and expired proposal
  archive — not multi-device relay, web, entitlement VPS clock, or push cron.

- [x] **Housing — active plan in-force implementation** (spec: `housing-active-agreement-operations`).  
  Hub, realized expense entry/ledger, and amendment passes landed (2026); export/import (pass 5) remains open in that change’s `tasks.md`.

- [x] **User units + calendar week start** — `openspec/changes/user-units-and-calendar-preferences/`: editable date format and distance in Settings → Units; week start (Sunday/Monday) in onboarding and settings; `showAppDatePicker` / `showAppDateRangePicker`; quiet-hours and car availability week columns use `prefs.resolvedFirstDayOfWeekIndex`. Currency and time-zone policy edit remain TBD (2026-05-22).

- [x] **Mobile dependencies — phase 2 (notifications + permissions).**  
  Bumped `flutter_local_notifications` ^21.0.0 and `permission_handler` ^12.0.1.
  Migrated `initialize()` / `show()` to named parameters (v20+ API) in
  `push_notification_service.dart`, `contact_notification_service_native.dart`,
  `developer_test_notification_native.dart`. Verified: `flutter analyze .`,
  `flutter test`, `flutter build apk --debug --flavor dev` (2026-05-20).

- [x] **Mobile dependencies — phase 1 (Firebase stack).**  
  Bumped `firebase_core` ^4.9.0 and `firebase_messaging` ^16.2.2 in `mobile/pubspec.yaml`
  (lockfile: core 4.9.0, messaging 16.2.2). No Dart API changes required. Verified:
  `flutter analyze .`, `flutter test`, `flutter build apk --debug --flavor dev`
  (2026-05-20). **Scope:** mobile only; relay unchanged.

- [x] **Mobile dependencies — phase 0 (constraint-safe `pub upgrade`).**  
  `flutter pub upgrade` in `mobile/` (no `--major-versions`): lockfile bumps for
  `flutter_material_design_icons`, `json_annotation`, `url_launcher_android`.
  Verified: `flutter analyze .`, `flutter test` (2026-05-20). **Scope:** workspace
  `pubspec.lock` only.

- [x] **Flutter Android / Gradle — obsolete Java 8 `javac` options.**  
  Aligned Flutter plugin subprojects to Java 17 via
  `mobile/android/build.gradle.kts` (`subprojects` + `afterEvaluate` /
  `state.executed` fallback on `BaseExtension.compileOptions` and
  `KotlinCompile` JVM 17). Verified: `flutter build apk --debug --flavor dev`
  (2026-05-20). **Scope:** mobile Android build only.
