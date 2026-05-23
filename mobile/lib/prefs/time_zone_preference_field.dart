import 'package:flutter/material.dart';

import '../data/supported_time_zones.dart';
import '../l10n/app_localizations.dart';
import '../widgets/supported_time_zone_picker_sheet.dart';
import 'app_preferences.dart';
import 'time_zone_policy_field.dart';

extension TimeZonePreferenceDisplay on AppPreferences {
  bool get usesDeviceTimeZone =>
      timeZonePolicy != kTimeZonePolicyExplicit || timeZoneId.isEmpty;

  String timeZoneDisplayLine(Locale locale, AppLocalizations l10n) {
    if (usesDeviceTimeZone) return l10n.prefsTimeZoneDevice;
    if (isKnownIanaTimeZoneId(timeZoneId)) {
      return ianaTimeZoneDisplayName(timeZoneId, locale);
    }
    return timeZoneId;
  }

  Future<void> setTimeZoneToDevice() async {
    await setTimeZonePolicy(kTimeZonePolicyDevice);
    await setTimeZoneId(null);
  }

  Future<void> setTimeZoneExplicit(String ianaId) async {
    await setTimeZonePolicy(kTimeZonePolicyExplicit);
    await setTimeZoneId(ianaId);
  }
}

String timeZoneSelectionDisplayLine({
  required Locale locale,
  required AppLocalizations l10n,
  required bool useDevice,
  required String ianaId,
}) {
  if (useDevice) return l10n.prefsTimeZoneDevice;
  if (isKnownIanaTimeZoneId(ianaId)) {
    return ianaTimeZoneDisplayName(ianaId, locale);
  }
  return ianaId;
}

/// Read-only combobox: device-local or a named IANA zone (opens searchable sheet).
class TimeZonePreferenceField extends StatefulWidget {
  const TimeZonePreferenceField({
    super.key,
    required this.useDevice,
    required this.ianaId,
    required this.onSelected,
  });

  final bool useDevice;
  final String ianaId;
  final void Function({required bool useDevice, required String ianaId})
      onSelected;

  @override
  State<TimeZonePreferenceField> createState() => _TimeZonePreferenceFieldState();
}

class _TimeZonePreferenceFieldState extends State<TimeZonePreferenceField> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void didUpdateWidget(TimeZonePreferenceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllerText();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerText();
  }

  void _syncControllerText() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final line = timeZoneSelectionDisplayLine(
      locale: locale,
      l10n: l10n,
      useDevice: widget.useDevice,
      ianaId: widget.ianaId,
    );
    if (_controller.text != line) {
      _controller.text = line;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      readOnly: true,
      canRequestFocus: false,
      controller: _controller,
      decoration: InputDecoration(
        labelText: l10n.prefsTimeZoneLabel,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        FocusScope.of(context).unfocus();
        final result = await showSupportedTimeZonePicker(
          context,
          deviceSelected: widget.useDevice,
          selectedIanaId: widget.useDevice ? null : widget.ianaId,
        );
        if (result == null || !mounted) return;
        switch (result) {
          case TimeZonePickerDevice():
            widget.onSelected(
              useDevice: true,
              ianaId: widget.ianaId,
            );
          case TimeZonePickerNamed(:final ianaId):
            widget.onSelected(useDevice: false, ianaId: ianaId);
        }
      },
    );
  }
}
