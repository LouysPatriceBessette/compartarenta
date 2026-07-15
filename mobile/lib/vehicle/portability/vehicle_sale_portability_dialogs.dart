import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../debug/qa_vehicle_semantics.dart';
import '../../l10n/app_localizations.dart';
import '../../util/product_legal_urls.dart';

Future<bool> showVehicleSaleExportConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return _showPortabilityConfirmDialog(
    context: context,
    body: l10n.vehicleExportConfirmBody,
    confirmLabel: l10n.vehicleExportConfirmExport,
    confirmSemanticsId: kQaVehicleExportConfirm,
    cancelSemanticsId: kQaVehicleExportCancel,
  );
}

Future<bool> showVehicleSaleImportConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return _showPortabilityConfirmDialog(
    context: context,
    body: l10n.vehicleImportConfirmBody,
    confirmLabel: l10n.vehicleImportConfirmImport,
    confirmSemanticsId: kQaVehicleImportConfirm,
    cancelSemanticsId: kQaVehicleImportCancel,
  );
}

Future<void> showVehicleSaleExportSuccessDialog(
  BuildContext context, {
  required String zipFileName,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.vehicleExportSuccessTitle),
      content: Text(l10n.vehicleExportSuccessBody(zipFileName)),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: kDebugMode ? kQaVehicleExportSuccessDone : null,
              button: true,
              onTap: () => Navigator.of(ctx).pop(),
              excludeSemantics: true,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonDone),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool> _showPortabilityConfirmDialog({
  required BuildContext context,
  required String body,
  required String confirmLabel,
  required String confirmSemanticsId,
  required String cancelSemanticsId,
}) async {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final faqUrl = vehicleModuleFaqUrlForLocale(locale);
  final recognizer = TapGestureRecognizer()
    ..onTap = () {
      unawaited(launchUrl(faqUrl, mode: LaunchMode.externalApplication));
    };

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: l10n.contactsDuplicateReadMore,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: recognizer,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                identifier: kDebugMode ? cancelSemanticsId : null,
                button: true,
                onTap: () => Navigator.of(ctx).pop(false),
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.commonCancel),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                identifier: kDebugMode ? confirmSemanticsId : null,
                button: true,
                onTap: () => Navigator.of(ctx).pop(true),
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  recognizer.dispose();
  return confirmed == true;
}

bool vehicleSalePortabilitySupportedOnPlatform() => !kIsWeb;
