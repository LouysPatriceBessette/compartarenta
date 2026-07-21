/// Locale-specific housing module slug in export file names.
String housingExportModuleSlug(String languageCode) {
  return switch (languageCode.split('-').first) {
    'fr' => 'logement',
    'es' => 'renta',
    _ => 'housing',
  };
}

/// User-facing housing agreement export file name (short, no internal ids).
///
/// Format: `[YYYY-MM-DD_HH:MM]_Bojairũ-[logement|housing|renta].json`
String housingExportFileName({
  required String languageCode,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final date =
      '${t.year}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
  final time =
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  final slug = housingExportModuleSlug(languageCode);
  return '${date}_${time}_Bojairũ-$slug.json';
}
