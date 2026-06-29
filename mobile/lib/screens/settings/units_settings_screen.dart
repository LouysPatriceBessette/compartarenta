import 'package:flutter/material.dart';

import '../../data/supported_time_zones.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../prefs/regional_unit_choices.dart';
import '../../prefs/time_zone_preference_field.dart';
import '../../prefs/week_start.dart';
import '../../widgets/screen_body_padding.dart';

class UnitsSettingsScreen extends StatelessWidget {
  const UnitsSettingsScreen({super.key, required this.prefs});

  final AppPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsUnitsTitle)),
      body: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final locale = Localizations.localeOf(context);
          final weekStart = prefs.resolveWeekStart(locale);
          final dateFmt = prefs.dateFormat.isEmpty ? null : prefs.dateFormat;
          final distance = prefs.distanceUnit;
          final liquidVolume = prefs.liquidVolumeUnit;
          final useDeviceTz = prefs.usesDeviceTimeZone;
          final ianaId = prefs.timeZoneId.isEmpty
              ? kDefaultExplicitTimeZoneId
              : prefs.timeZoneId;

          return ListView(
            padding: screenBodyScrollPadding(context),
            children: [
              TimeZonePreferenceField(
                useDevice: useDeviceTz,
                ianaId: ianaId,
                onSelected: ({required useDevice, required ianaId}) async {
                  if (useDevice) {
                    await prefs.setTimeZoneToDevice();
                  } else {
                    await prefs.setTimeZoneExplicit(ianaId);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(dateFmt),
                isExpanded: true,
                initialValue: dateFmt,
                decoration: InputDecoration(
                  labelText: l10n.prefsDateFormatLabel,
                ),
                items: kPreferenceDateFormats
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) async {
                  if (value != null) await prefs.setDateFormat(value);
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
                selected: {weekStart},
                onSelectionChanged: (selected) async {
                  if (selected.isEmpty) return;
                  await prefs.setWeekStart(selected.first);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DistanceUnit>(
                key: ValueKey(distance),
                isExpanded: true,
                initialValue: distance,
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
                onChanged: (value) async {
                  if (value != null) await prefs.setDistanceUnit(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LiquidVolumeUnit>(
                key: ValueKey(liquidVolume),
                isExpanded: true,
                initialValue: liquidVolume,
                decoration: InputDecoration(
                  labelText: l10n.prefsLiquidVolumeUnitLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: LiquidVolumeUnit.liter,
                    child: Text(
                      l10n.prefsLiquidVolumeUnitLiter,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: LiquidVolumeUnit.usGallon,
                    child: Text(
                      l10n.prefsLiquidVolumeUnitUsGallon,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: LiquidVolumeUnit.imperialGallon,
                    child: Text(
                      l10n.prefsLiquidVolumeUnitImperialGallon,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value != null) await prefs.setLiquidVolumeUnit(value);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
