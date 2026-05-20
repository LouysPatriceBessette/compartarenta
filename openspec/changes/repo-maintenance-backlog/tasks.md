# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

<!-- Add new deferred chores here. -->

## Done

- [x] **Flutter Android / Gradle — obsolete Java 8 `javac` options.**  
  Aligned Flutter plugin subprojects to Java 17 via
  `mobile/android/build.gradle.kts` (`subprojects` + `afterEvaluate` /
  `state.executed` fallback on `BaseExtension.compileOptions` and
  `KotlinCompile` JVM 17). Verified: `flutter build apk --debug --flavor dev`
  (2026-05-20). **Scope:** mobile Android build only.
