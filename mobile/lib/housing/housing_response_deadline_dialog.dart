import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/standard_validity_duration_bar.dart';

/// Author picks how long recipients may respond before the offer expires.
Future<Duration?> showHousingResponseDeadlineDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  var selected = StandardValidityDurations.values[2];

  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(l10n.housingInviteResponseWindowTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.housingInviteResponseWindowBody),
              const SizedBox(height: 16),
              StandardValidityDurationSegmented(
                selected: selected,
                onChanged: (d) => setLocal(() => selected = d),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.housingPlanCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    ),
  );

  if (proceed != true) return null;
  return selected;
}
