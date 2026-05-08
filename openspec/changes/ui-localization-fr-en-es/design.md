## Context

Compartarenta is a Flutter app that must support multiple UI languages and allow users to switch language at any time. The localization approach must support FR/EN/ES initially and be extensible for additional languages later, without rewriting UI code.

Constraints:
- Must work across platforms supported by Flutter.
- Language switching should update UI immediately.
- Strings must not be hard-coded in widgets once localization is introduced.

## Goals / Non-Goals

**Goals:**
- Provide a localization framework for user-facing strings with FR/EN/ES.
- Persist a user-selected language override in preferences and apply it app-wide.
- Provide a safe fallback behavior for missing translations.
- Keep the system extensible for future languages (adding a locale should be mostly “add translations + register locale”).

**Non-Goals:**
- Automatic language detection beyond using the platform locale as a default when no user override exists.
- Translation workflow automation (external services) in the initial implementation.

## Decisions

- **Use Flutter’s standard localization pipeline**
  - **Decision**: use `flutter_localizations` + `gen_l10n` (ARB-based) and generated `AppLocalizations`.
  - **Rationale**: well-supported, testable, and keeps translations as data.
  - **Alternatives**: custom JSON-based localization → more flexible but less standard and higher maintenance.

- **Language selection model: platform-default with user override**
  - **Decision**: when user has not chosen a language, app follows platform locale (best-effort). When user selects FR/EN/ES, app uses the override until changed.
  - **Rationale**: matches user expectation and enables “change at any time”.

- **Fallback behavior**
  - **Decision**: if a string is missing for a locale, fall back to English for that message (or the base locale), and avoid crashing.
  - **Rationale**: prevents broken UI and allows incremental translation work.

## Risks / Trade-offs

- **[Partial translations] → Mitigation**: enforce CI checks for missing keys where possible; fall back to English at runtime.
- **[Large refactor of existing UI text] → Mitigation**: tackle screen-by-screen; keep a task checklist by module.
