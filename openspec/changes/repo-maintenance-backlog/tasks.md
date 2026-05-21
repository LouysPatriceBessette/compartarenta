# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

- [ ] **Housing — active plan in-force flow** (after usage-flow spec exists).  
  Wire `ExpensePlanLineForm` on accepted plans; budget-cap threshold confirmation when a live expense exceeds the monthly max; notifications (default **All**: every participant gets before-date + overdue reminders; single designated payer per product annex).  
  Deferred from `housing-unified-expense-entry` pass 5 / `tasks.md` § Deferred.  
  **Depends on:** in-force plan usage UX defined first.

- [ ] **Mobile dependencies — phase 3 (remaining majors).**  
  `go_router`, `flutter_secure_storage`, `app_links`, … as features need them.  
  **Mobile-only**; relay wake stays on `closed-app-push-delivery`.  
  **Scope:** `mobile/` + workspace `pubspec.lock` only.

## Done

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
