## 1. Localization setup

- [x] 1.1 Add Flutter localization dependencies/config (flutter_localizations + gen_l10n) and enable l10n generation
- [x] 1.2 Create base localization files and supported locales (EN/FR/ES) with an extensible structure for future languages
- [x] 1.3 Define fallback behavior for missing translations (fallback to default language message)

## 2. Preferences: language selection

- [x] 2.1 Add preferences UI section for Language (EN/FR/ES) accessible at all times
- [x] 2.2 Persist language override in local storage and load it on app startup
- [x] 2.3 Apply selected locale app-wide without restart when user changes language

## 3. String migration & coverage

- [x] 3.1 Identify and replace hard-coded user-facing strings with localized keys across existing screens
- [x] 3.2 Add translations for EN/FR/ES for the migrated strings
- [ ] 3.3 Add basic tests/checks to ensure locale switching works and missing keys fall back predictably
