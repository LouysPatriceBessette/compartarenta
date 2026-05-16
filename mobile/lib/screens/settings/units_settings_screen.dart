import 'package:flutter/material.dart';

import '../../data/supported_currencies.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';

class UnitsSettingsScreen extends StatelessWidget {
  const UnitsSettingsScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = prefs.currency.isEmpty
        ? l10n.commonNotSet
        : (supportedCurrencyByCode(prefs.currency)?.displayLine ??
              prefs.currency);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsUnitsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.settingsCurrencyTitle),
            subtitle: Text(currency),
          ),
          ListTile(
            title: Text(l10n.settingsDateFormatTitle),
            subtitle: Text(
              prefs.dateFormat.isEmpty ? l10n.commonNotSet : prefs.dateFormat,
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDistanceUnitTitle),
            subtitle: Text(prefs.distanceUnit?.name ?? l10n.commonNotSet),
          ),
        ],
      ),
    );
  }
}
