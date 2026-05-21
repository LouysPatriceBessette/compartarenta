import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../util/display_numbers.dart';
import '../../util/format_money.dart';
import 'expense_amount_parse.dart';
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
  });

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
          _SplitRow(
            key: ValueKey(state.rows[i].participantId),
            row: state.rows[i],
            totalMinor: state.totalMinor,
            currencyCode: currencyCode,
            onAmount: (minor) => onRowAmountChanged(i, minor),
            onPercentTenths: (t) => onRowPercentChanged(i, t),
            onChanged: onChanged,
          ),
        if (state.hasAmountMismatch) ...[
          const Divider(),
          _CorrectionRow(
            deltaMinor: state.amountDeltaMinor,
            sumWeightBps: state.rows.fold<int>(0, (a, r) => a + r.weightBps),
            totalMinor: state.totalMinor,
            currencyCode: currencyCode,
            label: l10n.housingExpenseSplitCorrectRow,
          ),
        ],
      ],
    );
  }
}

class _SplitRow extends StatefulWidget {
  const _SplitRow({
    super.key,
    required this.row,
    required this.totalMinor,
    required this.currencyCode,
    required this.onAmount,
    required this.onPercentTenths,
    required this.onChanged,
  });

  final ExpenseSplitRow row;
  final int totalMinor;
  final String currencyCode;
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
      text: (widget.row.amountMinor / 100).toStringAsFixed(2),
    );
    _pctCtrl = TextEditingController(text: _percentText());
  }

  @override
  void didUpdateWidget(covariant _SplitRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_amountFocused) {
      final t = (widget.row.amountMinor / 100).toStringAsFixed(2);
      if (_amountCtrl.text != t) _amountCtrl.text = t;
    }
    if (!_pctFocused) {
      final t = _percentText();
      if (_pctCtrl.text != t) _pctCtrl.text = t;
    }
  }

  bool _amountFocused = false;
  bool _pctFocused = false;

  String _percentText() {
    if (widget.totalMinor <= 0) return '';
    return formatShareOfTotalPercentNoSuffix(
      context,
      shareNumeratorMinor: widget.row.amountMinor,
      totalDenominatorMinor: widget.totalMinor,
    ).replaceAll('%', '').trim();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: const InputDecoration(isDense: true),
              onTap: () => setState(() => _amountFocused = true),
              onEditingComplete: () => setState(() => _amountFocused = false),
              onTapOutside: (_) => setState(() => _amountFocused = false),
              onChanged: (v) {
                final minor = parseAmountMinorFromText(v);
                if (minor != null) widget.onAmount(minor);
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(widget.row.displayName),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _pctCtrl,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: '%',
              ),
              onTap: () => setState(() => _pctFocused = true),
              onEditingComplete: () => setState(() => _pctFocused = false),
              onTapOutside: (_) => setState(() => _pctFocused = false),
              onChanged: (v) {
                final t = v.trim().replaceAll('%', '').replaceAll(',', '.');
                final d = double.tryParse(t);
                if (d == null) return;
                widget.onPercentTenths((d * 10).round());
                widget.onChanged();
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
    required this.sumWeightBps,
    required this.totalMinor,
    required this.currencyCode,
    required this.label,
  });

  final int deltaMinor;
  final int sumWeightBps;
  final int totalMinor;
  final String currencyCode;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = totalMinor > 0
        ? formatShareOfTotalPercentNoSuffix(
            context,
            shareNumeratorMinor: (sumWeightBps * totalMinor ~/ 10000).clamp(
              0,
              totalMinor,
            ),
            totalDenominatorMinor: totalMinor,
          )
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
