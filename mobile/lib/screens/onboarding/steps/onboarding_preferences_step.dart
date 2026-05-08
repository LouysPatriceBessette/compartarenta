import 'package:flutter/material.dart';

import '../../../prefs/app_preferences.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingPreferencesStep extends StatefulWidget {
  const OnboardingPreferencesStep({
    super.key,
    required this.prefs,
    required this.onFinish,
  });

  final AppPreferences prefs;
  final VoidCallback onFinish;

  @override
  State<OnboardingPreferencesStep> createState() => _OnboardingPreferencesStepState();
}

class _OnboardingPreferencesStepState extends State<OnboardingPreferencesStep> {
  late String _currency = widget.prefs.currency;
  late String _dateFormat = widget.prefs.dateFormat;
  late DistanceUnit _distanceUnit =
      widget.prefs.distanceUnit ?? DistanceUnit.km;
  late String _timeZonePolicy = widget.prefs.timeZonePolicy;

  static const _currencies = <String>['CAD', 'USD', 'EUR', 'MXN'];
  static const _dateFormats = <String>['YYYY-MM-DD', 'DD/MM/YYYY', 'MM/DD/YYYY'];

  bool get _canFinish => _currency.isNotEmpty && _dateFormat.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPreferencesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currency.isEmpty ? null : _currency,
            decoration: InputDecoration(labelText: l10n.prefsCurrencyLabel),
            items: _currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _currency = value ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _dateFormat.isEmpty ? null : _dateFormat,
            decoration: InputDecoration(labelText: l10n.prefsDateFormatLabel),
            items: _dateFormats
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (value) => setState(() => _dateFormat = value ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DistanceUnit>(
            value: _distanceUnit,
            decoration: InputDecoration(labelText: l10n.prefsDistanceUnitLabel),
            items: [
              DropdownMenuItem(value: DistanceUnit.km, child: Text(l10n.prefsDistanceUnitKm)),
              DropdownMenuItem(
                value: DistanceUnit.miles,
                child: Text(l10n.prefsDistanceUnitMiles),
              ),
            ],
            onChanged: (value) => setState(() => _distanceUnit = value ?? DistanceUnit.km),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _timeZonePolicy,
            decoration: InputDecoration(labelText: l10n.prefsTimeZoneLabel),
            items: [
              DropdownMenuItem(value: 'device', child: Text(l10n.prefsTimeZoneDevice)),
              DropdownMenuItem(value: 'explicit', child: Text(l10n.prefsTimeZoneExplicit)),
            ],
            onChanged: (value) => setState(() => _timeZonePolicy = value ?? 'device'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _canFinish
                ? () async {
                    await widget.prefs.setCurrency(_currency);
                    await widget.prefs.setDateFormat(_dateFormat);
                    await widget.prefs.setDistanceUnit(_distanceUnit);
                    await widget.prefs.setTimeZonePolicy(_timeZonePolicy);
                    widget.onFinish();
                  }
                : null,
            child: Text(l10n.commonFinishSetup),
          ),
        ],
      ),
    );
  }
}

