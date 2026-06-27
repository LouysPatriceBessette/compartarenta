/// User-visible folder layout under `<Documents>/Compartarenta/`.
///
/// Reserved for future modules (spec refactor pending):
/// - [carModuleFolderName]
/// - [carSharingModuleFolderName]
class CompartarentaDocumentsLayout {
  CompartarentaDocumentsLayout._();

  static const String rootFolderName = 'Compartarenta';
  static const String housingModuleFolderName = 'Housing';
  static const String expenseProofsFolderName = 'ExpenseProofs';
  static const String backupsFolderName = 'Backups';

  /// Future: single-car module exports and artifacts.
  static const String carModuleFolderName = 'Car';

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
