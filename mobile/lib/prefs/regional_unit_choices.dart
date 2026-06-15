/// Date display patterns offered in onboarding and Settings → Units.
const kPreferenceDateFormats = <String>[
  'YYYY-MM-DD',
  'DD/MM/YYYY',
  'MM/DD/YYYY',
];

/// Defaults applied when onboarding finishes (user may change in Settings → Units).
///
/// v1: [kDefaultCurrencyCode] is fixed storage; UI shows `$` only (see `format_money.dart`).
/// User-selectable currency and conversion are deferred — see `docs/development-roadmap.md`.
const kDefaultCurrencyCode = 'CAD';
const kDefaultDateFormat = 'YYYY-MM-DD';
