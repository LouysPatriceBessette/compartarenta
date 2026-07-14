/// User-visible folder layout under `<Documents>/Compartarenta/`.
///
/// **Policy:** all durable user-captured images MUST be written here via
/// [public_documents_file_sink_io.dart] — see OpenSpec
/// `user-owned-media-storage`. App-private paths (e.g. legacy
/// `vehicle_meter_photos/`) MUST NOT receive new media writes.
class CompartarentaDocumentsLayout {
  CompartarentaDocumentsLayout._();

  static const String rootFolderName = 'Compartarenta';
  static const String housingModuleFolderName = 'Housing';
  static const String expenseProofsFolderName = 'ExpenseProofs';
  static const String backupsFolderName = 'Backups';

  /// Single-vehicle module artifacts (galleries, future exports).
  static const String carModuleFolderName = 'Car';

  /// `Compartarenta/Car/<vehicleId>/Odometer`
  static String vehicleOdometerPhotosRelativeSubDir({
    required String vehicleId,
  }) {
    return '$rootFolderName/$carModuleFolderName/$vehicleId/Odometer';
  }

  /// `Compartarenta/Car/<vehicleId>/Gallery_<nnn>`
  static String vehicleGalleryRelativeSubDir({
    required String vehicleId,
    required int galleryIndex,
  }) {
    final folder = 'Gallery_${galleryIndex.toString().padLeft(3, '0')}';
    return '$rootFolderName/$carModuleFolderName/$vehicleId/$folder';
  }

  /// `Compartarenta/Car/<vehicleId>/Maintenance`
  static String vehicleMaintenanceAttachmentsRelativeSubDir({
    required String vehicleId,
  }) {
    return '$rootFolderName/$carModuleFolderName/$vehicleId/Maintenance';
  }

  /// Sale export zip / JSON sit directly under `Compartarenta/`.
  static String moduleRootRelativeSubDir() => rootFolderName;

  /// Future: car-sharing module (split from legacy car module spec).
  static const String carSharingModuleFolderName = 'Car_sharing';

  /// `Compartarenta/Backups` — JSON export files (housing + device backup).
  static String backupsRelativeSubDir() =>
      '$rootFolderName/$backupsFolderName';

  /// `Compartarenta/Housing/<start>_<end>/ExpenseProofs`
  static String housingExpenseProofsRelativeSubDir({
    required DateTime agreementPeriodStart,
    required DateTime agreementPeriodEnd,
  }) {
    final period = formatAgreementPeriodFolderName(
      agreementPeriodStart,
      agreementPeriodEnd,
    );
    return '$rootFolderName/$housingModuleFolderName/$period/$expenseProofsFolderName';
  }

  /// Calendar-day folder segment: `YYYY-MM-DD_YYYY-MM-DD`.
  static String formatAgreementPeriodFolderName(
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return '${_dateSegment(periodStart)}_${_dateSegment(periodEnd)}';
  }

  static String _dateSegment(DateTime date) {
    final local = date.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
