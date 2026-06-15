import 'package:flutter/material.dart';
import 'app_text_field.dart';

import '../data/supported_currencies.dart';

/// Searchable list of supported currencies; returns selected ISO code or null if dismissed.
Future<String?> showSupportedCurrencyPicker(
  BuildContext context, {
  required String searchHint,
  String? selectedCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _CurrencyPickerBody(
        searchHint: searchHint,
        initialCode: selectedCode,
      );
    },
  );
}

class _CurrencyPickerBody extends StatefulWidget {
  const _CurrencyPickerBody({required this.searchHint, this.initialCode});

  final String searchHint;
  final String? initialCode;

  @override
  State<_CurrencyPickerBody> createState() => _CurrencyPickerBodyState();
}

class _CurrencyPickerBodyState extends State<_CurrencyPickerBody> {
  final TextEditingController _query = TextEditingController();
  late List<SupportedCurrency> _filtered = List.of(kSupportedCurrencies);

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
      _filtered = kSupportedCurrencies.where((c) => c.matchesQuery(q)).toList();
    });
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
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final c = _filtered[index];
                  final selected =
                      widget.initialCode != null &&
                      widget.initialCode!.toUpperCase() == c.code;
                  return ListTile(
                    title: Text(
                      c.displayLine,
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
