## Why

Compartarenta needs to be usable by people in different languages and regions. Adding first-class UI localization now prevents hard-coding copy and enables scaling to additional languages later.

## What Changes

- Add UI localization support for **FR**, **EN**, and **ES**.
- Add a user preference to select the app language at any time from the preferences panel.
- Ensure the localization approach is extensible to support additional languages later without major refactors.

## Capabilities

### New Capabilities

- `ui-localization`: Localize all user-facing strings and support switching among FR/EN/ES at runtime, with an extensible path for future languages.
- `language-preferences`: Persist a user-selected language override and expose a preferences UI to change it at any time.

### Modified Capabilities

<!-- None yet. -->

## Impact

- **Mobile app**: Introduce localization plumbing, message catalogs, and translated strings for all screens.
- **UX**: Add a Language section in preferences; apply changes immediately across the app.
- **Testing**: Add coverage to ensure language switching works and missing translations are handled predictably.
