# Store assets and listing content

This folder is the **single source of truth** for App Store / Google Play listing content and related assets.

It is designed to work **before you have any store accounts**, and to be copied into the respective consoles later.

## Structure

- `listing/`: text content per locale (name, description, keywords, support/privacy links)
- `assets/`: icons, screenshots, and other artwork (by platform + device)
- `review/`: App Review notes, test credentials placeholders, and submission checklists

## Rename-friendly

If the app name changes, update:
- `listing/<locale>/app_name.txt`
- Android label (per flavor): `android/app/build.gradle.kts` `resValue("string","app_name", ...)`
- iOS display name: `ios/Runner/Info.plist` (we can update when you’re ready)

