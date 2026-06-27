import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../entitlement/participant_installation_store.dart';
import '../../housing/portability/housing_export_file_sink.dart';
import '../../l10n/app_localizations.dart';
import '../../portability/device_data_export_file_sink_io.dart'
    if (dart.library.html) '../../portability/device_data_export_file_sink_web.dart'
    as export_sink;
import '../../portability/device_data_export_service.dart';
import '../../portability/device_data_import_service.dart';
import '../../portability/device_data_snapshot_codec.dart';
import '../../portability/pending_installation_migration_store.dart';
import '../../portability/store_import_gate.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../widgets/screen_body_padding.dart';

class DeviceDataExportImportScreen extends StatefulWidget {
  const DeviceDataExportImportScreen({super.key});

  @override
  State<DeviceDataExportImportScreen> createState() =>
      _DeviceDataExportImportScreenState();
}

class _DeviceDataExportImportScreenState
    extends State<DeviceDataExportImportScreen> {
  final _installationStore = ParticipantInstallationStore.secureStorage();
  final _importGate = defaultStoreImportGate();

  var _exporting = false;
  var _importing = false;
  var _migrating = false;
  var _importAllowed = false;
  String? _lastSavedLocation;
  String? _importSuccessMessage;
  PendingInstallationMigration? _pendingMigration;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  Future<void> _refreshState() async {
    final allowed = !kIsWeb && await _importGate.hasActiveHousingSubscription();
    final pendingStore = await PendingInstallationMigrationStore.load();
    if (!mounted) return;
    setState(() {
      _importAllowed = allowed;
      _pendingMigration = pendingStore.read();
    });
  }

  Future<DeviceDataImportService> _loadImportService() async {
    final relay = HandshakeOrchestrator.maybeInstance?.relayClient;
    if (relay == null) {
      throw StateError('relay unavailable');
    }
    final pendingStore = await PendingInstallationMigrationStore.load();
    return DeviceDataImportService(
      db: AppDatabase.processScope,
      relay: relay,
      pendingStore: pendingStore,
    );
  }

  Future<void> _export(BuildContext context) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context);
    try {
      final installationId = await _installationStore.loadOrCreateId();
      final json = await DeviceDataExportService(
        AppDatabase.processScope,
      ).exportJsonString(participantInstallationId: installationId);
      if (!context.mounted) return;
      final result = await export_sink.writeDeviceDataExportJson(json: json);
      if (!context.mounted) return;
      setState(() {
        _lastSavedLocation = switch (result.kind) {
          HousingExportWriteKind.clipboard =>
            l10n.deviceDataExportCopiedToClipboard,
          HousingExportWriteKind.file when result.fileName != null =>
            l10n.deviceDataExportSavedLocation(result.fileName!),
          HousingExportWriteKind.file => null,
        };
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deviceDataExportFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    if (_importing || _importDisabled) return;
    final l10n = AppLocalizations.of(context);
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final bytes = pick.files.single.bytes;
    if (bytes == null) return;
    final jsonText = utf8.decode(bytes);

    setState(() => _importing = true);
    try {
      final service = await _loadImportService();
      final bundle = await service.parseAndValidateBundle(jsonText);

      final choices = service.canonicalRestoreChoices(bundle);
      if (choices.isNotEmpty && context.mounted) {
        final selected = await _pickCanonicalIdentity(context, choices);
        if (selected == null) return;
      }

      final dbEmpty = await deviceOperationalDataIsEmpty(AppDatabase.processScope);
      if (!dbEmpty && context.mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deviceDataReplaceConfirmTitle),
            content: Text(l10n.deviceDataReplaceConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.commonContinue),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      await service.applyLocalImport(bundle);
      final oldId = service.oldInstallationIdFromBundle(bundle);
      final planId = service.primaryHousingPlanIdFromBundle(bundle);
      await service.persistPendingMigration(
        oldParticipantInstallationId: oldId,
        planId: planId,
      );

      final newId = await _installationStore.loadOrCreateId();
      try {
        await service.requestInstallationMigration(
          oldParticipantInstallationId: oldId,
          newParticipantInstallationId: newId,
          planId: planId,
        );
        if (!context.mounted) return;
        setState(() => _importSuccessMessage = l10n.deviceDataImportSuccess);
      } on DeviceDataMigrationException catch (e) {
        if (!context.mounted) return;
        final message = e.isTransportFailure
            ? l10n.deviceDataMigrationNetworkFailure
            : l10n.deviceDataMigrationFailed(e.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      await _refreshState();
    } on DeviceDataImportValidationException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deviceDataImportValidationFailed(e.code))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deviceDataImportFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<String?> _pickCanonicalIdentity(
    BuildContext context,
    List<CanonicalRestoreChoice> choices,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.deviceDataCanonicalRestoreTitle),
        children: [
          for (final choice in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, choice.participantId),
              child: Text(
                choice.displayName.isEmpty
                    ? choice.participantId
                    : choice.displayName,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retryMigration(BuildContext context) async {
    if (_migrating || _pendingMigration == null) return;
    setState(() => _migrating = true);
    final l10n = AppLocalizations.of(context);
    try {
      final service = await _loadImportService();
      final newId = await _installationStore.loadOrCreateId();
      await service.retryPendingMigration(newId);
      if (!context.mounted) return;
      setState(() => _importSuccessMessage = l10n.deviceDataImportSuccess);
      await _refreshState();
    } on DeviceDataMigrationException catch (e) {
      if (!context.mounted) return;
      final message = e.isTransportFailure
          ? l10n.deviceDataMigrationNetworkFailure
          : l10n.deviceDataMigrationFailed(e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  bool get _importDisabled =>
      _importSuccessMessage != null || !_importAllowed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _exporting || _importing || _migrating;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsExportImportTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          Text(
            l10n.deviceDataExportSecurityWarning,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy ? null : () => _export(context),
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(l10n.deviceDataExportAction),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: busy || _importDisabled
                ? null
                : () => _import(context),
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(l10n.deviceDataImportAction),
          ),
          if (_importSuccessMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _importSuccessMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            Text(
              l10n.deviceDataImportDisabledWeb,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (!_importAllowed && _importSuccessMessage == null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.deviceDataImportDisabledNoSubscription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_lastSavedLocation != null) ...[
            const SizedBox(height: 24),
            Text(
              l10n.deviceDataExportLastSavedTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(_lastSavedLocation!),
          ],
          if (_pendingMigration != null) ...[
            const SizedBox(height: 24),
            Text(
              l10n.deviceDataMigrationPendingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.deviceDataMigrationPendingBody),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : () => _retryMigration(context),
              child: Text(l10n.deviceDataRetryMigrationAction),
            ),
          ],
        ],
      ),
    );
  }
}
