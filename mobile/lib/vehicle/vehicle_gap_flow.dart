import 'package:flutter/material.dart';

import '../db/repositories/vehicles_repository.dart';
import '../l10n/app_localizations.dart';
import '../vehicle/vehicle_owner_contact.dart';
import '../widgets/app_dialog.dart';

/// Positive gap attribution choices for a vehicle use session start.
Future<String?> showPositiveGapAttributionDialog(
  BuildContext context, {
  required String gapDisplay,
  required List<({String id, String label})> participants,
}) async {
  final l10n = AppLocalizations.of(context);
  return showAppDialog<String>(
    context: context,
    guardKey: 'vehiclePositiveGap',
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.vehicleGapAttributionTitle),
        content: Text(
          l10n.vehicleGapAttributionPrompt(gapDisplay),
        ),
        actions: [
          for (final p in participants)
            TextButton(
              onPressed: () => Navigator.pop(ctx, p.id),
              child: Text(p.label),
            ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, kVehicleGapAttributionUnknown),
            child: Text(l10n.vehicleGapAttributionUnknown),
          ),
        ],
      );
    },
  );
}

enum NegativeGapChoice { maintain, cancel }

/// Propriétaire negative-gap dialog per `vehicle-odometer-gap-attribution`.
Future<NegativeGapChoice?> showNegativeGapDialog(
  BuildContext context, {
  required String gapDisplay,
}) async {
  final l10n = AppLocalizations.of(context);
  return showAppDialog<NegativeGapChoice>(
    context: context,
    guardKey: 'vehicleNegativeGap',
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.vehicleNegativeGapTitle),
        content: Text(
          l10n.vehicleNegativeGapBody(gapDisplay),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, NegativeGapChoice.cancel),
            child: Text(l10n.vehicleNegativeGapCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, NegativeGapChoice.maintain),
            child: Text(l10n.vehicleNegativeGapMaintain),
          ),
        ],
      );
    },
  );
}

List<({String id, String label})> gapAttributionParticipants({
  required AppLocalizations l10n,
  required String actingContactId,
  required String ownerContactId,
  required List<String> activeBorrowerContactIds,
  required Map<String, String> contactLabels,
}) {
  final out = <({String id, String label})>[];
  out.add((
    id: actingContactId,
    label: l10n.vehicleGapAttributionSelf,
  ));
  if (ownerContactId != actingContactId) {
    out.add((
      id: ownerContactId,
      label: contactLabels[ownerContactId] ?? l10n.vehicleRoleOwner,
    ));
  }
  for (final id in activeBorrowerContactIds) {
    if (id == actingContactId) continue;
    out.add((
      id: id,
      label: contactLabels[id] ?? l10n.vehicleRoleBorrower,
    ));
  }
  return out;
}

bool gapRequiresOwnerNotification({
  required String attributedContactId,
  required String recordedByContactId,
}) {
  if (attributedContactId == kVehicleGapAttributionUnknown &&
      !vehicleContactIsOwnerSelf(recordedByContactId)) {
    return true;
  }
  if (attributedContactId != recordedByContactId &&
      attributedContactId != kVehicleGapAttributionUnknown) {
    return true;
  }
  return false;
}
