import 'package:flutter/material.dart';
import 'app_dialog.dart';
import 'app_text_field.dart';

import '../util/routing_push_country_codes.dart';

/// Bottom-sheet searchable picker for an ISO 3166-1 alpha-2 country code.
/// Returns the selected uppercase code, or `null` when dismissed.
Future<String?> showRoutingPushCountryPicker(
  BuildContext context, {
  required String searchHint,
  required String emptyLabel,
  required String languageCode,
  String? selectedCode,
}) {
  return showAppModalBottomSheet<String>(
    context: context,
    guardKey: 'routingPushCountryPicker',
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _RoutingPushCountryPickerBody(
        searchHint: searchHint,
        emptyLabel: emptyLabel,
        languageCode: languageCode,
        initialCode: selectedCode,
      );
    },
  );
}

class _RoutingPushCountryPickerBody extends StatefulWidget {
  const _RoutingPushCountryPickerBody({
    required this.searchHint,
    required this.emptyLabel,
    required this.languageCode,
    this.initialCode,
  });

  final String searchHint;
  final String emptyLabel;
  final String languageCode;
  final String? initialCode;

  @override
  State<_RoutingPushCountryPickerBody> createState() =>
      _RoutingPushCountryPickerBodyState();
}

class _RoutingPushCountryPickerBodyState
    extends State<_RoutingPushCountryPickerBody> {
  final TextEditingController _query = TextEditingController();
  late List<SupportedRoutingPushCountry> _filtered = _sortedByLanguage(
    widget.languageCode,
  );

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
    final q = _query.text;
    setState(() {
      _filtered = _sortedByLanguage(widget.languageCode)
          .where((c) => c.matchesQuery(q, widget.languageCode))
          .toList(growable: false);
    });
  }

  static List<SupportedRoutingPushCountry> _sortedByLanguage(String lang) {
    final list = List<SupportedRoutingPushCountry>.of(
      kRoutingPushSupportedCountries,
    );
    // Collation ignores case AND diacritics in every supported locale so all
    // accented letters collate with their base-Latin counterpart, e.g.:
    //   - fr  "É" in "États-Unis"   collates next to "E"
    //   - es  "Ú" in "Perú"         collates next to "U"
    //   - es  "Ñ" in "España"       collates next to "N"
    // instead of falling at the end of the alphabet.
    list.sort((a, b) => a.foldedName(lang).compareTo(b.foldedName(lang)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.none,
                autofocus: true,
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.emptyLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        final selected = widget.initialCode != null &&
                            widget.initialCode!.toUpperCase() == c.code;
                        return ListTile(
                          title: Text(
                            c.displayName(widget.languageCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(c.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
