import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/repositories/vehicles_repository.dart';
import '../../l10n/app_localizations.dart';

/// If [vehicleId] is still sale-import undoable, asks the user to confirm that
/// the upcoming action will permanently confirm the import.
///
/// Returns `false` when the user cancels (caller must abort the action).
Future<bool> confirmSaleImportCommitmentIfNeeded(
  BuildContext context, {
  required String vehicleId,
}) async {
  final repo = VehiclesRepository(AppDatabase.processScope);
  final vehicle = await repo.getVehicle(vehicleId);
  if (vehicle == null || !vehicle.saleImportUndoAvailable) {
    return true;
  }
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l10n.vehicleSaleImportConfirmActionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.vehicleSaleImportConfirmActionConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await repo.clearSaleImportUndoAvailable(vehicleId);
  return true;
}
