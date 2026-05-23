import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../util/deadline_remaining.dart';

/// Response deadline on the housing proposal screen.
class HousingResponseDeadlineDisplay extends StatelessWidget {
  const HousingResponseDeadlineDisplay({
    super.key,
    required this.expiresUtc,
    required this.dateFormat,
    required this.l10n,
  });

  final DateTime expiresUtc;
  final String dateFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DeadlineDisplay(
      title: l10n.housingInviteResponseDeadlineTitle,
      deadlineUtc: expiresUtc,
      dateFormat: dateFormat,
      l10n: l10n,
    );
  }
}
