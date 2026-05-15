# Repo maintenance backlog — tasks

Deferred engineering chores. Pick these up when convenient; they are
**not** ordered by relay or release urgency unless explicitly noted.

## Backlog

- [ ] **Flutter Android / Gradle — obsolete Java 8 `javac` options.**  
  `assembleDevDebug` / Flutter plugin subprojects may compile with
  `-source 8 -target 8`, producing obsolete-API warnings (sometimes
  treated as errors). Align all Android subprojects with **Java 17**
  (the `mobile` app module already sets 17 in `app/build.gradle.kts`).  
  Suggested approach: extend [`mobile/android/build.gradle.kts`](../../../mobile/android/build.gradle.kts)
  with `subprojects { afterEvaluate { … } }` configuring
  `compileOptions` on `com.android.build.gradle.BaseExtension` and/or
  `JavaCompile` `options.release.set(17)`, then verify with  
  `flutter build apk --debug --flavor dev` (or `dart run melos run run:dev`
  on device).  
  **Scope:** mobile Android build only; relay Go image unaffected.

## Done

<!-- Move completed rows here with PR / date when finished. -->
