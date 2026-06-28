import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'vehicle_usage_context.dart';

String vehicleUsageDenialMessage(
  AppLocalizations l10n,
  VehicleUsageAccessDenial denial,
) {
  return switch (denial) {
    VehicleUsageAccessDenial.vehicleNotFound =>
      l10n.vehicleUsageBlockedVehicleNotFound,
    VehicleUsageAccessDenial.notOwnedVehicleForOwnerPath =>
      l10n.vehicleUsageBlockedNotOwnedOnOwnerPath,
    VehicleUsageAccessDenial.ownVehicleOnBorrowerPath =>
      l10n.vehicleUsageBlockedOwnOnBorrowerPath,
    VehicleUsageAccessDenial.missingBorrowerIdentity =>
      l10n.vehicleUsageBlockedMissingBorrowerIdentity,
  };
}

Widget vehicleUsageDenialBody(
  BuildContext context,
  VehicleUsageAccessDenial denial,
) {
  final l10n = AppLocalizations.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        vehicleUsageDenialMessage(l10n, denial),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
