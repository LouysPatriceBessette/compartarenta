import '../../l10n/app_localizations.dart';

class HousingExportWriteResult {
  const HousingExportWriteResult({required this.kind, this.path});

  final HousingExportWriteKind kind;
  final String? path;

  String message(AppLocalizations l10n) {
    return switch (kind) {
      HousingExportWriteKind.clipboard => l10n.housingExportCopiedToClipboard,
      HousingExportWriteKind.file =>
        l10n.housingExportSavedTo(path ?? ''),
    };
  }
}

enum HousingExportWriteKind { clipboard, file }
