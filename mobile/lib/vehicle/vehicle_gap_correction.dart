import '../db/app_database.dart';
import '../db/repositories/vehicles_repository.dart';

/// Context for a positive-gap correction journal entry saved before the main reading.
enum GapCorrectionContext {
  sessionStart,
  standalone;

  String get wire => name;

  static GapCorrectionContext? fromWire(String? raw) {
    if (raw == null) return null;
    for (final c in GapCorrectionContext.values) {
      if (c.name == raw) return c;
    }
    return null;
  }
}

String encodeGapCorrectionNote({
  required int gapTenths,
  required GapCorrectionContext context,
}) =>
    '$gapTenths|${context.wire}';

({int gapTenths, GapCorrectionContext context})? decodeGapCorrectionNote(
  String note,
) {
  final parts = note.split('|');
  if (parts.length != 2) return null;
  final gapTenths = int.tryParse(parts[0]);
  final context = GapCorrectionContext.fromWire(parts[1]);
  if (gapTenths == null || context == null) return null;
  return (gapTenths: gapTenths, context: context);
}

bool isGapCorrectionReading(VehicleMeterReading reading) =>
    reading.isCorrection ||
    MeterReadingRole.fromWire(reading.readingRole) ==
        MeterReadingRole.correction;
