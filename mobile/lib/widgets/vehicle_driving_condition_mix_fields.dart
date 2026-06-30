import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Integer percent fields for route / city / traffic driving mix (sum = 100).
class VehicleDrivingConditionMixFields extends StatelessWidget {
  const VehicleDrivingConditionMixFields({
    super.key,
    required this.routeController,
    required this.cityController,
    required this.trafficController,
    required this.onChanged,
  });

  final TextEditingController routeController;
  final TextEditingController cityController;
  final TextEditingController trafficController;
  final VoidCallback onChanged;

  static final _digitsOnly = [FilteringTextInputFormatter.digitsOnly];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.vehicleDrivingConditionColumn,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.vehicleDrivingConditionProportionColumn,
                    style: theme.textTheme.labelLarge,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            _row(
              context,
              label: l10n.vehicleDrivingConditionRoute,
              controller: routeController,
            ),
            _row(
              context,
              label: l10n.vehicleDrivingConditionCity,
              controller: cityController,
            ),
            _row(
              context,
              label: l10n.vehicleDrivingConditionTraffic,
              controller: trafficController,
            ),
          ],
        ),
      ],
    );
  }

  TableRow _row(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: _digitsOnly,
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              suffixText: '%',
              isDense: true,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

int? parseDrivingMixPercent(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

bool drivingMixFieldsCompleteAndValid({
  required String routeText,
  required String cityText,
  required String trafficText,
}) {
  final route = parseDrivingMixPercent(routeText);
  final city = parseDrivingMixPercent(cityText);
  final traffic = parseDrivingMixPercent(trafficText);
  if (route == null || city == null || traffic == null) return false;
  return route + city + traffic == 100;
}
