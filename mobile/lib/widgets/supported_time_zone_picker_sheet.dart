import 'package:flutter/material.dart';
import 'app_text_field.dart';

import '../data/supported_time_zones.dart';
import '../l10n/app_localizations.dart';

/// Result of [showSupportedTimeZonePicker]: device-local or an IANA id.
sealed class TimeZonePickerResult {}

class TimeZonePickerDevice extends TimeZonePickerResult {}

class TimeZonePickerNamed extends TimeZonePickerResult {
  TimeZonePickerNamed(this.ianaId);
  final String ianaId;
}

/// Searchable time zone list; returns device or IANA selection, or null if dismissed.
Future<TimeZonePickerResult?> showSupportedTimeZonePicker(
  BuildContext context, {
  required bool deviceSelected,
  String? selectedIanaId,
}) {
  return showModalBottomSheet<TimeZonePickerResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _TimeZonePickerBody(
        deviceSelected: deviceSelected,
        initialIanaId: selectedIanaId,
      );
    },
  );
}

class _TimeZonePickerBody extends StatefulWidget {
  const _TimeZonePickerBody({
    required this.deviceSelected,
    this.initialIanaId,
  });

  final bool deviceSelected;
  final String? initialIanaId;

  @override
  State<_TimeZonePickerBody> createState() => _TimeZonePickerBodyState();
}

class _TimeZonePickerBodyState extends State<_TimeZonePickerBody> {
  final TextEditingController _query = TextEditingController();
  late final List<String> _allIds = allIanaTimeZoneIds;
  late List<String> _filtered = _allIds;

  @override
  void initState() {
    super.initState();
    _query.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _query.removeListener(_applyFilter);
    _query.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final locale = Localizations.localeOf(context);
    final q = _query.text;
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = _allIds;
        return;
      }
      _filtered = _allIds
          .where((id) => ianaTimeZoneMatchesQuery(id, q, locale))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxH = media.size.height * 0.75;
    final availableH =
        (media.size.height - bottomInset - media.padding.top - 24).clamp(
          120.0,
          media.size.height,
        );
    final sheetH = availableH < maxH ? availableH : maxH;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppTextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: l10n.prefsTimeZoneSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.none,
                autofocus: true,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(l10n.prefsTimeZoneDevice),
                          selected: widget.deviceSelected,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(TimeZonePickerDevice()),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final id = _filtered[index];
                        return ListTile(
                          title: Text(
                            ianaTimeZoneDisplayName(id, locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: !widget.deviceSelected &&
                              widget.initialIanaId == id,
                          onTap: () => Navigator.of(
                            context,
                          ).pop(TimeZonePickerNamed(id)),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
