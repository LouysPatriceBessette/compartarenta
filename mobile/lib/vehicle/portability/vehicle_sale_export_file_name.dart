/// Sale/transfer export base name (no extension).
///
/// Format: `[YYYY-MM-DD]-<dataOfSegment>-<displayLabel>`
/// where [dataOfSegment] is localized (e.g. FR `Données-de`).
String vehicleSaleExportBaseName({
  required DateTime date,
  required String dataOfSegment,
  required String displayLabel,
}) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final label = sanitizeVehicleSaleDisplayLabelForFileName(displayLabel);
  return '$y-$m-$d-$dataOfSegment-$label';
}

String vehicleSaleExportZipFileName({
  required DateTime date,
  required String dataOfSegment,
  required String displayLabel,
}) {
  return '${vehicleSaleExportBaseName(
    date: date,
    dataOfSegment: dataOfSegment,
    displayLabel: displayLabel,
  )}.zip';
}

String vehicleSaleExportJsonFileName({
  required DateTime date,
  required String dataOfSegment,
  required String displayLabel,
}) {
  return '${vehicleSaleExportBaseName(
    date: date,
    dataOfSegment: dataOfSegment,
    displayLabel: displayLabel,
  )}.json';
}

/// Keeps [displayLabel] as-is except for characters illegal in path components.
String sanitizeVehicleSaleDisplayLabelForFileName(String displayLabel) {
  final trimmed = displayLabel.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(displayLabel, 'displayLabel', 'must not be empty');
  }
  return trimmed.replaceAll(RegExp(r'[/\\:*?"<>|]'), '-');
}
