import 'package:flutter/material.dart';

import '../../../prefs/app_preferences.dart';
import '../../../prefs/regional_unit_choices.dart';
import '../../../data/supported_time_zones.dart';
import '../../../prefs/time_zone_preference_field.dart';
import '../../../prefs/week_start.dart';
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
  late bool _useDeviceTimeZone = true;
  late String _timeZoneIanaId = kDefaultExplicitTimeZoneId;
  late WeekStart _weekStart = WeekStart.monday;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _weekStart = widget.prefs.weekStart ??
        defaultWeekStartForLocale(Localizations.localeOf(context));
    _useDeviceTimeZone = widget.prefs.usesDeviceTimeZone;
    _timeZoneIanaId = widget.prefs.timeZoneId.isEmpty
        ? kDefaultExplicitTimeZoneId
        : widget.prefs.timeZoneId;
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
                      key: ValueKey(_dateFormat),
                      isExpanded: true,
                      initialValue: _dateFormat.isEmpty ? null : _dateFormat,
                      decoration: InputDecoration(
                        labelText: l10n.prefsDateFormatLabel,
                      ),
                      items: kPreferenceDateFormats
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _dateFormat = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DistanceUnit>(
                      key: ValueKey(_distanceUnit),
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
                    TimeZonePreferenceField(
                      useDevice: _useDeviceTimeZone,
                      ianaId: _timeZoneIanaId,
                      onSelected: ({required useDevice, required ianaId}) {
                        setState(() {
                          _useDeviceTimeZone = useDevice;
                          _timeZoneIanaId = ianaId;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.prefsWeekStartLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<WeekStart>(
                      segments: [
                        ButtonSegment(
                          value: WeekStart.sunday,
                          label: Text(l10n.prefsWeekStartSunday),
                        ),
                        ButtonSegment(
                          value: WeekStart.monday,
                          label: Text(l10n.prefsWeekStartMonday),
                        ),
                      ],
                      selected: {_weekStart},
                      onSelectionChanged: (selected) {
                        if (selected.isEmpty) return;
                        setState(() => _weekStart = selected.first);
                      },
                    ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _canFinish
                          ? () async {
                              await widget.prefs.setCurrency(_currency);
                              await widget.prefs.setDateFormat(_dateFormat);
                              await widget.prefs.setDistanceUnit(_distanceUnit);
                              await widget.prefs.setWeekStart(_weekStart);
                              if (_useDeviceTimeZone) {
                                await widget.prefs.setTimeZoneToDevice();
                              } else {
                                await widget.prefs.setTimeZoneExplicit(
                                  _timeZoneIanaId,
                                );
                              }
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
