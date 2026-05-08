## Compartatrenta

Compartatrenta is a work-in-progress project with a Flutter app in `mobile/`.

## License

This project is licensed under the Elastic License 2.0 (ELv2). See `LICENSE`.

## Legal and disputes

See `docs/legal-and-disputes.md` for transparency on licensing, payment failure behavior, and dispute-limited product scope.

## Repository layout

- `mobile/`: Flutter application (Android, iOS, Web, Windows, Linux, macOS)
- `openspec/`: specifications and change tracking artifacts
- `tools/`: tooling (includes Flutter SDK/vendor tooling)

## Getting started (Flutter app)

Prerequisites:
- A Flutter SDK available on your machine, **or** use the vendored tooling under `tools/`

From the repository root:

```bash
cd mobile
flutter pub get
flutter run --flavor dev
```

Notes:
- This app defines Android product flavors (`dev`, `staging`, `prod`). Running without `--flavor` can lead to Gradle building `assembleDebug` (no-flavor), which won't produce an APK.
- Prefer the helper scripts:
  - `./tool/run_dev.sh`
  - `./tool/run_staging.sh`
  - `./tool/run_prod.sh`

