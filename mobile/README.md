# Compartarenta Mobile (Flutter)

This is the Flutter app workspace for the `mobile-app-store-release` change.

## Tooling

This repo vendors a Flutter SDK in `../tools/flutter/` to avoid requiring a system install.

## Run (dev)

From the repository root (Melos):

```bash
dart run melos run run:dev
```

Optional device: `dart run melos run run:dev -- -d <deviceId>`

Web: `dart run melos run run:dev:web`

The `mobile/tool/run_dev.sh` script is what Melos invokes; you normally do not
need to call it directly.

### Android: `MissingPluginException` at startup

If the app shows **Startup failed** with `MissingPluginException` for
`shared_preferences` or `path_provider`, the native plugins were not registered
(often after restarting the dev process without a full app reinstall on device).

1. Stop **every** Melos / `flutter run` terminal (`Ctrl+C`).
2. Rebuild and reinstall (usually enough; no `flutter clean` required):

```bash
dart run melos run run:dev
```

3. Wait until the terminal finishes **Installing…** before opening the app from
   the launcher. Do not open the app from the icon while an old process is still
   attached.

4. If the error persists: `dart run melos run clean`, then `get`, `codegen`,
   `web:assets`, and `run:dev` again. Prefer uninstalling “Compartarenta (Dev)”
   manually (Android Settings → Apps) if `--uninstall-first` did not run.

`run_dev.sh` passes `--uninstall-first` on mobile targets so reinstall clears
stale native plugins when an Android device is selected.

### Web data across melos restarts

Use `dart run melos run run:dev:web` (Flutter caches the Chrome profile under
`mobile/.dart_tool/chrome-device`, default port **5001**). A different port or
profile looks like a fresh app.

`melos run web:assets` only refreshes `mobile/web/sqlite3.wasm` and
`drift_worker.dart.js` to match `pubspec.lock` after a `drift` / `sqlite3` bump.
It does **not** control session retention. Melos may label curl progress lines as
`ERROR:` even when the script ends with `Done.`

If the web DB looks empty after `flutter clean` + `codegen` despite correct
`run:dev:web`, check `local_storage_checkpoint:` lines (especially
`reason=contact-promoted` before stop, then `reason=startup` after relaunch).
`run_dev_web.sh` restores `~/.cache/compartarenta/chrome-device-backup` on start
and rsyncs `chrome-device` on exit (Melos Ctrl+C / `q`). Do not pass a separate
`--user-data-dir` under `~/.cache/…`: Flutter copies the session into
`chrome-device` on exit and deletes that custom directory.

A methodical run should show `onboardingComplete=true` and `contacts=1` on
`contact-promoted`, then the same on the next `startup` if persistence works.

`flutter clean` (e.g. `refresh.sh`) deletes `.dart_tool/`, including
`chrome-device`. **Before `refresh.sh`**, run:

```bash
dart run melos run backup:web-chrome-profile
```

Then `run:dev:web` restores that backup when the live profile lacks
`flutter.onboarding.complete` on disk. The debug build also mirrors contacts to
`compartarenta.dev.sessionMirror.v1` in localStorage when checkpoints fire.

`web:assets` in refresh is only needed after a `drift` / `sqlite3` version bump.

# compartarenta

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
