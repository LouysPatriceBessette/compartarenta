import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'expense_amount_parse.dart';
import 'expense_line_persistence.dart';
import 'expense_recurrence_flow.dart';
import 'expense_recurrence_spec.dart';
import 'expense_ratio_template_repository.dart';
import 'expense_split_grid.dart';
import 'expense_split_grid_logic.dart';
import 'like_ratio_selector.dart';

/// Full-screen add/edit expense form (proposal draft and future in-force scope).
class ExpensePlanLineFormScreen extends StatefulWidget {
  const ExpensePlanLineFormScreen({
    super.key,
    required this.planId,
    required this.participantIds,
    required this.participantNames,
    required this.periodStart,
    required this.periodEnd,
    required this.defaultCurrency,
    this.existingLineId,
    this.initialSortOrder = 0,
  });

  final String planId;
  final List<String> participantIds;
  final List<String> participantNames;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String defaultCurrency;
  final String? existingLineId;
  final int initialSortOrder;

  @override
  State<ExpensePlanLineFormScreen> createState() =>
      _ExpensePlanLineFormScreenState();
}

class _ExpensePlanLineFormScreenState extends State<ExpensePlanLineFormScreen> {
  AppDatabase get _db => AppDatabase.processScope;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _isRecurring = true;
  bool _amountIsBudgetCap = false;
  ExpenseRecurrenceSpec? _recurrence;
  String? _paymentResponsibleId;
  String? _selectedTemplateId;
  bool _likeClearedByEdit = false;

  ExpenseSplitGridState? _split;
  List<PlanRatioTemplate> _templates = const [];
  late int _sortOrder = widget.initialSortOrder;
  DateTime? _createdAt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _templates = await ExpenseRatioTemplateRepository(
      _db,
    ).listForPlan(widget.planId);
    if (widget.existingLineId != null) {
      final lines = await _db.listPlanLines(widget.planId);
      PlanLine? line;
      for (final l in lines) {
        if (l.id == widget.existingLineId) {
          line = l;
          break;
        }
      }
      final loaded = line;
      if (loaded != null) {
        _titleCtrl.text = loaded.title;
        _descCtrl.text = loaded.description;
        _amountCtrl.text = minorToAmountText(loaded.amountMinor);
        _isRecurring = loaded.isRecurring;
        _amountIsBudgetCap = loaded.amountIsBudgetCap;
        _paymentResponsibleId = loaded.paymentResponsibleParticipantId;
        _selectedTemplateId = loaded.ratioTemplateId;
        _sortOrder = loaded.sortOrder;
        _createdAt = loaded.createdAt;
        _recurrence =
            ExpenseRecurrenceSpec.parseStored(loaded.recurrenceSpecJson) ??
            ExpenseRecurrenceSpec.fromLegacyDayOfMonth(
              loaded.recurrenceDayOfMonth,
            );
        final ratios = await _db.listPlanRatios(widget.planId);
        final weights = {
          for (final r in ratios.where((r) => r.lineId == loaded.id))
            r.participantId: r.weight,
        };
        final total = loaded.amountMinor ?? 0;
        if (total > 0 && weights.length == widget.participantIds.length) {
          _split = ExpenseSplitGridState(
            participantIds: widget.participantIds,
            displayNames: widget.participantNames,
            rows: [
              for (var i = 0; i < widget.participantIds.length; i++)
                ExpenseSplitRow(
                  participantId: widget.participantIds[i],
                  displayName: widget.participantNames[i],
                  amountMinor: 0,
                  weightBps: weights[widget.participantIds[i]] ?? 0,
                ),
            ],
            totalMinor: total,
          )..applyWeights(weights);
        }
      }
    }
    _syncSplitFromAmount();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _syncSplitFromAmount() {
    final minor = parseAmountMinorFromText(_amountCtrl.text);
    if (minor == null || minor <= 0) {
      _split = null;
      return;
    }
    if (_split == null) {
      _split = ExpenseSplitGridState.equalParts(
        participantIds: widget.participantIds,
        displayNames: widget.participantNames,
        totalMinor: minor,
      );
    } else {
      _split!.setTotalMinor(minor);
    }
  }

  bool get _canSave {
    if (_titleCtrl.text.trim().isEmpty) return false;
    final minor = parseAmountMinorFromText(_amountCtrl.text);
    if (minor == null || minor <= 0) return false;
    if (_isRecurring && _recurrence == null) return false;
    if (_split == null || _split!.hasAmountMismatch) return false;
    return true;
  }

  Future<void> _save() async {
    final now = DateTime.now().toUtc();
    final minor = parseAmountMinorFromText(_amountCtrl.text)!;
    await ExpenseLinePersistence(_db).save(
      planId: widget.planId,
      existingLineId: widget.existingLineId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      currency: widget.defaultCurrency,
      isRecurring: _isRecurring,
      recurrenceSpec: _isRecurring ? _recurrence : null,
      amountMinor: minor,
      amountIsBudgetCap: _amountIsBudgetCap,
      paymentResponsibleParticipantId: _paymentResponsibleId,
      split: _split,
      sortOrder: _sortOrder,
      createdAt: _createdAt ?? now,
      templates: ExpenseRatioTemplateRepository(_db),
    );
    if (mounted) Navigator.pop(context, true);
  }

  void _onLikeSelected(String? templateId) {
    if (templateId == null || _split == null) return;
    final t = _templates.firstWhere((e) => e.id == templateId);
    final weights = ExpenseRatioTemplateRepository.decodeWeights(t.weightsJson);
    setState(() {
      _selectedTemplateId = templateId;
      _likeClearedByEdit = false;
      _split!.applyWeights(weights);
    });
  }

  void _onGridEdited() {
    setState(() {
      if (_selectedTemplateId != null && !_likeClearedByEdit) {
        _selectedTemplateId = null;
        _likeClearedByEdit = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLineId == null
              ? l10n.housingPlanAddExpenseTitle
              : l10n.housingPlanEditExpenseTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: l10n.housingExpenseNameLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: l10n.housingPlanExpenseDescriptionLabel,
            ),
            maxLines: 4,
            minLines: 2,
          ),
          SwitchListTile(
            title: Text(l10n.housingPlanRecurringSwitch),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
          if (_isRecurring)
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(l10n.housingExpenseRecurrenceTapToSet),
              subtitle: _recurrence == null
                  ? null
                  : Text(l10n.housingExpenseRecurrenceSet),
              onTap: () async {
                final spec = await showExpenseRecurrenceFlow(
                  context: context,
                  periodStart: widget.periodStart,
                  periodEnd: widget.periodEnd,
                  initial: _recurrence,
                );
                if (spec != null) setState(() => _recurrence = spec);
              },
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.housingPlanAmountLabel,
            ),
            onChanged: (_) => setState(_syncSplitFromAmount),
          ),
          const SizedBox(height: 8),
          Text(l10n.housingExpenseAmountTypeLabel, style: Theme.of(context).textTheme.titleSmall),
          RadioGroup<bool>(
            groupValue: _amountIsBudgetCap,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _amountIsBudgetCap = v);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RadioListTile<bool>(
                  title: Text(l10n.housingExpenseAmountDetermined),
                  value: false,
                ),
                RadioListTile<bool>(
                  title: Text(l10n.housingExpenseAmountBudgetMax),
                  value: true,
                ),
              ],
            ),
          ),
          DropdownButtonFormField<String?>(
            initialValue: _paymentResponsibleId,
            decoration: InputDecoration(
              labelText: l10n.housingExpensePaymentResponsibleLabel,
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.housingExpensePaymentResponsibleAll),
              ),
              for (var i = 0; i < widget.participantIds.length; i++)
                DropdownMenuItem(
                  value: widget.participantIds[i],
                  child: Text(widget.participantNames[i]),
                ),
            ],
            onChanged: (v) => setState(() => _paymentResponsibleId = v),
          ),
          const Divider(height: 32),
          Text(
            l10n.housingExpenseSplitSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _split == null
                  ? null
                  : () => setState(_split!.resetEqualParts),
              child: Text(l10n.housingExpenseEqualParts),
            ),
          ),
          if (_templates.isNotEmpty) ...[
            LikeRatioSelector(
              templates: _templates,
              participantIds: widget.participantIds,
              selectedTemplateId: _selectedTemplateId,
              onSelected: _onLikeSelected,
            ),
            const SizedBox(height: 8),
          ],
          if (_split != null)
            ExpenseSplitGrid(
              state: _split!,
              currencyCode: widget.defaultCurrency,
              onChanged: _onGridEdited,
              onRowAmountChanged: (i, minor) {
                setState(() {
                  _split!.onAmountEdited(i, minor);
                  _onGridEdited();
                });
              },
              onRowPercentChanged: (i, tenths) {
                setState(() {
                  _split!.onPercentTenthsEdited(i, tenths);
                  _onGridEdited();
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(l10n.housingPlanSave),
          ),
        ),
      ),
    );
  }
}
