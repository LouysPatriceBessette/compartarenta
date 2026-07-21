/// User-facing full-device backup file name.
///
/// Format: `[YYYY-MM-DD_HH:MM]_Bojairũ-backup.json`
String deviceDataExportFileName({DateTime? now}) {
  final t = now ?? DateTime.now();
  final date =
      '${t.year}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
  final time =
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  return '${date}_${time}_Bojairũ-backup.json';
}
