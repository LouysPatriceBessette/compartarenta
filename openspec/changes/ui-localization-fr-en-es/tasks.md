## 1. Localization setup

- [ ] 1.1 Add Flutter localization dependencies/config (flutter_localizations + gen_l10n) and enable l10n generation
- [ ] 1.2 Create base localization files and supported locales (EN/FR/ES) with an extensible structure for future languages
- [ ] 1.3 Define fallback behavior for missing translations (fallback to default language message)

## 2. Preferences: language selection

- [ ] 2.1 Add preferences UI section for Language (EN/FR/ES) accessible at all times
- [ ] 2.2 Persist language override in local storage and load it on app startup
- [ ] 2.3 Apply selected locale app-wide without restart when user changes language

## 3. String migration & coverage

- [ ] 3.1 Identify and replace hard-coded user-facing strings with localized keys across existing screens
- [ ] 3.2 Add translations for EN/FR/ES for the migrated strings
- [ ] 3.3 Add basic tests/checks to ensure locale switching works and missing keys fall back predictably
