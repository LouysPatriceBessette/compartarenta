import 'package:flutter/material.dart';
import '../../widgets/app_text_field.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../util/display_numbers.dart';
import '../../util/fixed_decimal_input.dart';
import '../../util/format_money.dart';
import 'expense_amount_parse.dart';
import 'expense_ratio_template_repository.dart';
import 'expense_split_grid_logic.dart';

/// Three-column split editor (amount / name / percent).
class ExpenseSplitGrid extends StatelessWidget {
  const ExpenseSplitGrid({
    super.key,
    required this.state,
    required this.currencyCode,
    required this.onChanged,
    required this.onRowAmountChanged,
    required this.onRowPercentChanged,
  }) : readOnly = false;

  const ExpenseSplitGrid.readOnly({
    super.key,
    required this.state,
    required this.currencyCode,
  }) : readOnly = true,
       onChanged = _noop,
       onRowAmountChanged = _noopIndexAmount,
       onRowPercentChanged = _noopIndexPercent;

  static void _noop() {}
  static void _noopIndexAmount(int index, int amountMinor) {}
  static void _noopIndexPercent(int index, int percentTenths) {}

  final bool readOnly;
  final ExpenseSplitGridState state;
  final String currencyCode;
  final VoidCallback onChanged;
  final void Function(int index, int amountMinor) onRowAmountChanged;
  final void Function(int index, int percentTenths) onRowPercentChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                l10n.housingExpenseSplitAmountColumn,
                style: theme.textTheme.labelMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                l10n.housingExpenseSplitParticipantColumn,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                l10n.housingExpenseSplitPercentColumn,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < state.rows.length; i++)
          readOnly
              ? _ReadOnlySplitRow(
                  displayName: state.rows[i].displayName,
                  amountMinor: state.rows[i].amountMinor,
                  totalMinor: state.totalMinor,
                  currencyCode: currencyCode,
                )
              : _SplitRow(
                  key: ValueKey(state.rows[i].participantId),
                  displayName: state.rows[i].displayName,
                  amountMinor: state.rows[i].amountMinor,
                  totalMinor: state.totalMinor,
                  onAmount: (minor) => onRowAmountChanged(i, minor),
                  onPercentTenths: (t) => onRowPercentChanged(i, t),
                  onChanged: onChanged,
                ),
        if (state.hasAmountMismatch) ...[
          const Divider(),
          _CorrectionRow(
            deltaMinor: state.amountDeltaMinor,
            sumAmountMinor: state.sumAmountMinor,
            totalMinor: state.totalMinor,
            currencyCode: currencyCode,
            label: l10n.housingExpenseSplitCorrectRow,
          ),
        ],
      ],
    );
  }
}

class _ReadOnlySplitRow extends StatelessWidget {
  const _ReadOnlySplitRow({
    required this.displayName,
    required this.amountMinor,
    required this.totalMinor,
    required this.currencyCode,
  });

  final String displayName;
  final int amountMinor;
  final int totalMinor;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final pct = totalMinor > 0
        ? '${formatShareOfTotalPercentNoSuffix(
            context,
            shareNumeratorMinor: amountMinor,
            totalDenominatorMinor: totalMinor,
          )}%'
        : '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                formatMinorAsMoney(context, amountMinor, currencyCode),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                style: nameStyle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                pct,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatefulWidget {
  const _SplitRow({
    super.key,
    required this.displayName,
    required this.amountMinor,
    required this.totalMinor,
    required this.onAmount,
    required this.onPercentTenths,
    required this.onChanged,
  });

  final String displayName;
  final int amountMinor;
  final int totalMinor;
  final ValueChanged<int> onAmount;
  final ValueChanged<int> onPercentTenths;
  final VoidCallback onChanged;

  @override
  State<_SplitRow> createState() => _SplitRowState();
}

class _SplitRowState extends State<_SplitRow> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _pctCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: (widget.amountMinor / 100).toStringAsFixed(2),
    );
    // Percent text needs [Localizations]; do not read [context] in [initState].
    _pctCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPercentControllerText();
  }

  @override
  void didUpdateWidget(covariant _SplitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAmountControllerText();
    if (oldWidget.amountMinor != widget.amountMinor && !_pctFocused) {
      _applyPercentText(_percentTextFor(widget.amountMinor));
    } else {
      _syncPercentControllerText();
    }
  }

  void _syncAmountControllerText() {
    if (_amountFocused) return;
    final t = (widget.amountMinor / 100).toStringAsFixed(2);
    if (_amountCtrl.text != t) _amountCtrl.text = t;
  }

  void _syncPercentControllerText() {
    if (_pctFocused) return;
    _applyPercentText(_percentTextFor(widget.amountMinor));
  }

  void _applyPercentText(String t) {
    if (_pctCtrl.text != t) _pctCtrl.text = t;
  }

  void _applyAmountText(int amountMinor) {
    final t = (amountMinor / 100).toStringAsFixed(2);
    if (_amountCtrl.text != t) _amountCtrl.text = t;
  }

  void _releaseAmountFocus() {
    applyFixedDecimalInputOnBlur(_amountCtrl, fractionDigits: 2);
    FocusScope.of(context).unfocus();
    setState(() {
      _amountFocused = false;
      _syncAmountControllerText();
      _syncPercentControllerText();
    });
  }

  void _releasePercentFocus() {
    applyFixedDecimalInputOnBlur(_pctCtrl, fractionDigits: 1);
    FocusScope.of(context).unfocus();
    setState(() {
      _pctFocused = false;
      _syncAmountControllerText();
      _syncPercentControllerText();
    });
  }

  bool _amountFocused = false;
  bool _pctFocused = false;

  String _percentTextFor(int shareMinor) {
    if (widget.totalMinor <= 0) return '';
    return formatShareOfTotalPercentNoSuffix(
      context,
      shareNumeratorMinor: shareMinor,
      totalDenominatorMinor: widget.totalMinor,
    ).replaceAll('%', '').trim();
  }

  int _amountMinorFromPercentTenths(int percentTenths) {
    final scale = ExpenseRatioTemplateRepository.weightScale;
    final w = (percentTenths * scale ~/ 1000)
        .clamp(0, scale);
    return widget.totalMinor * w ~/ scale;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppTextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: const InputDecoration(isDense: true),
              onTap: () => setState(() => _amountFocused = true),
              onEditingComplete: _releaseAmountFocus,
              onSubmitted: (_) => _releaseAmountFocus(),
              onTapOutside: (_) => _releaseAmountFocus(),
              onChanged: (v) {
                final minor = parseAmountMinorFromText(v);
                if (minor == null) return;
                widget.onAmount(minor);
                widget.onChanged();
                if (!_pctFocused) {
                  _applyPercentText(_percentTextFor(minor));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                widget.displayName,
                textAlign: TextAlign.center,
                style: nameStyle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: AppTextField(
              controller: _pctCtrl,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                isDense: true,
                suffixText: '%',
              ),
              onTap: () => setState(() => _pctFocused = true),
              onEditingComplete: _releasePercentFocus,
              onSubmitted: (_) => _releasePercentFocus(),
              onTapOutside: (_) => _releasePercentFocus(),
              onChanged: (v) {
                final t = v.trim().replaceAll('%', '').replaceAll(',', '.');
                if (t.isEmpty) return;
                final d = double.tryParse(t);
                if (d == null) return;
                final tenths = (d * 10).round();
                widget.onPercentTenths(tenths);
                widget.onChanged();
                if (!_amountFocused) {
                  _applyAmountText(_amountMinorFromPercentTenths(tenths));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionRow extends StatelessWidget {
  const _CorrectionRow({
    required this.deltaMinor,
    required this.sumAmountMinor,
    required this.totalMinor,
    required this.currencyCode,
    required this.label,
  });

  final int deltaMinor;
  final int sumAmountMinor;
  final int totalMinor;
  final String currencyCode;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Amount column: adjustment (sum − total). Percent column: share already assigned.
    final pct = totalMinor > 0 && deltaMinor != 0
        ? '${formatShareOfTotalPercentNoSuffix(
            context,
            shareNumeratorMinor: sumAmountMinor,
            totalDenominatorMinor: totalMinor,
          )}%'
        : '—';
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '${deltaMinor < 0 ? '-' : '+'}${formatMinorAsMoney(context, deltaMinor.abs(), currencyCode)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            pct,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
