import 'package:flutter/material.dart';

import '../../../prefs/app_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/supported_currencies.dart';
import '../../../widgets/supported_currency_picker_sheet.dart';

class OnboardingPreferencesStep extends StatefulWidget {
  const OnboardingPreferencesStep({
    super.key,
    required this.prefs,
    required this.onFinish,
  });

  final AppPreferences prefs;
  final VoidCallback onFinish;

  @override
  State<OnboardingPreferencesStep> createState() =>
      _OnboardingPreferencesStepState();
}

class _OnboardingPreferencesStepState extends State<OnboardingPreferencesStep> {
  late String _currency = widget.prefs.currency;
  late String _dateFormat = widget.prefs.dateFormat;
  late DistanceUnit _distanceUnit =
      widget.prefs.distanceUnit ?? DistanceUnit.km;
  late String _timeZonePolicy = widget.prefs.timeZonePolicy;

  static const _dateFormats = <String>[
    'YYYY-MM-DD',
    'DD/MM/YYYY',
    'MM/DD/YYYY',
  ];

  late final TextEditingController _currencyField = TextEditingController(
    text: _currencyLine(),
  );

  String _currencyLine() {
    if (_currency.isEmpty) return '';
    final opt = supportedCurrencyByCode(_currency);
    return opt?.displayLine ?? _currency;
  }

  @override
  void initState() {
    super.initState();
    _currencyField.text = _currencyLine();
  }

  @override
  void dispose() {
    _currencyField.dispose();
    super.dispose();
  }

  bool get _canFinish => _currency.isNotEmpty && _dateFormat.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingPreferencesTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      canRequestFocus: false,
                      controller: _currencyField,
                      decoration: InputDecoration(
                        labelText: l10n.prefsCurrencyLabel,
                        hintText: l10n.prefsCurrencySearchHint,
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        final code = await showSupportedCurrencyPicker(
                          context,
                          searchHint: l10n.prefsCurrencySearchHint,
                          selectedCode: _currency.isEmpty ? null : _currency,
                        );
                        if (code != null && context.mounted) {
                          setState(() {
                            _currency = code;
                            _currencyField.text = _currencyLine();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _dateFormat.isEmpty ? null : _dateFormat,
                      decoration: InputDecoration(
                        labelText: l10n.prefsDateFormatLabel,
                      ),
                      items: _dateFormats
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _dateFormat = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DistanceUnit>(
                      isExpanded: true,
                      initialValue: _distanceUnit,
                      decoration: InputDecoration(
                        labelText: l10n.prefsDistanceUnitLabel,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: DistanceUnit.km,
                          child: Text(
                            l10n.prefsDistanceUnitKm,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: DistanceUnit.miles,
                          child: Text(
                            l10n.prefsDistanceUnitMiles,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => _distanceUnit = value ?? DistanceUnit.km,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _timeZonePolicy,
                      decoration: InputDecoration(
                        labelText: l10n.prefsTimeZoneLabel,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'device',
                          child: Text(
                            l10n.prefsTimeZoneDevice,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'explicit',
                          child: Text(
                            l10n.prefsTimeZoneExplicit,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _timeZonePolicy = value ?? 'device'),
                    ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _canFinish
                          ? () async {
                              await widget.prefs.setCurrency(_currency);
                              await widget.prefs.setDateFormat(_dateFormat);
                              await widget.prefs.setDistanceUnit(_distanceUnit);
                              await widget.prefs.setTimeZonePolicy(
                                _timeZonePolicy,
                              );
                              widget.onFinish();
                            }
                          : null,
                      child: Text(l10n.commonFinishSetup),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
