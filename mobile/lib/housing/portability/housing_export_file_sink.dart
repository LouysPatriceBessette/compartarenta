import '../../l10n/app_localizations.dart';

class HousingExportWriteResult {
  const HousingExportWriteResult({required this.kind, this.fileName});

  final HousingExportWriteKind kind;
  final String? fileName;

  String? savedLocationLabel(AppLocalizations l10n) {
    return switch (kind) {
      HousingExportWriteKind.clipboard => l10n.housingExportCopiedToClipboard,
      HousingExportWriteKind.file when fileName != null && fileName!.isNotEmpty =>
        l10n.housingExportSavedLocation(fileName!),
      HousingExportWriteKind.file => null,
    };
  }
}

enum HousingExportWriteKind { clipboard, file }
