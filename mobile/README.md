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

1. Stop the Melos run (`Ctrl+C` in the terminal).
2. Force-quit the app on the device (swipe it away from recents).
3. Start again: `dart run melos run run:dev`

If it still fails:

```bash
cd mobile && ./tool/flutterw clean
dart run melos run run:dev
```

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
