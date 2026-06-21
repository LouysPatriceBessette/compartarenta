import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/portability/housing_agreement_export_service.dart';
import '../../housing/portability/housing_export_file_sink_io.dart'
    if (dart.library.html) '../../housing/portability/housing_export_file_sink_web.dart'
    as export_sink;
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_body_padding.dart';

class HousingAgreementExportImportScreen extends StatefulWidget {
  const HousingAgreementExportImportScreen({
    super.key,
    required this.planId,
    required this.packageId,
  });

  final String planId;
  final String packageId;

  @override
  State<HousingAgreementExportImportScreen> createState() =>
      _HousingAgreementExportImportScreenState();
}

class _HousingAgreementExportImportScreenState
    extends State<HousingAgreementExportImportScreen> {
  var _exporting = false;

  Future<void> _export(BuildContext context) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context);
    try {
      final json = await HousingAgreementExportService(
        AppDatabase.processScope,
      ).exportJsonString(
        packageId: widget.packageId,
        planId: widget.planId,
      );
      if (!context.mounted) return;
      final result = await export_sink.writeHousingExportJson(
        packageId: widget.packageId,
        json: json,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message(l10n))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingExportFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingActiveHubExportImport)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          Text(
            l10n.housingExportSecurityWarning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exporting ? null : () => _export(context),
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(l10n.housingExportAction),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.housingImportNotAvailableTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.housingImportNotAvailableBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
