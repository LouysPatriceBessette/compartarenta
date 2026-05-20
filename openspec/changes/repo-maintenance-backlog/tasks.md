# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

- [ ] **Mobile dependencies — phased major upgrades (phases 2–3).**  
  Phase 2 — `flutter_local_notifications`, `permission_handler`; phase 3 — rest
  (`go_router`, `flutter_secure_storage`, …) as features need them.  
  **Phases 2–3** are **mobile-only** and do **not** require a relay release for existing
  notification behavior. **Relay wake** stays on `closed-app-push-delivery`.  
  **Scope:** `mobile/` + workspace `pubspec.lock` only.

## Done

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
