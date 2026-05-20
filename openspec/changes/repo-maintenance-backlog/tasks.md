# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

- [ ] **Mobile dependencies — phased major upgrades (phases 1–3).**  
  **Phases 1–2** (`firebase_core` / `firebase_messaging`, `flutter_local_notifications`,
  `permission_handler`, etc.) are **mobile-only** and do **not** require a relay release
  or VPS deploy for existing notification behavior (settings, permission gates, local
  notifications on polling). **Relay wake** (closed-app push, `WAKE_PUSH_DISPATCH_ENABLED`,
  FCM/APNs credentials on the relay) is a **separate** track (`closed-app-push-delivery`);
  deferring relay update does not block phases 1–2.  
  Phase 1 — Firebase stack; phase 2 — notifications + permissions; phase 3 — rest
  (`go_router`, `flutter_secure_storage`, …) as features need them.  
  **Scope:** `mobile/` + workspace `pubspec.lock` only; relay Go image unaffected unless
  ops Firebase project alignment is documented separately.

## Done

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
