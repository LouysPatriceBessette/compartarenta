import '../l10n/app_localizations.dart';

/// User-facing label for a persisted maintenance category wire value.
String vehicleMaintenanceCategoryLabel(
  AppLocalizations l10n,
  String categoryWire,
) {
  return switch (categoryWire) {
    'oil' => l10n.vehicleMaintenanceCategoryOil,
    _ => categoryWire,
  };
}
