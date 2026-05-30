import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import 'expense_amount_parse.dart';
import 'expense_line_persistence.dart';
import 'expense_plan_line_form_body.dart';
import 'expense_recurrence_flow.dart';
import 'expense_recurrence_labels.dart';
import 'expense_recurrence_spec.dart';
import 'expense_ratio_template_repository.dart';
import 'expense_split_grid_logic.dart';
import 'plan_participant_dropdown_value.dart';

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
    required this.dateFormat,
    required this.prefs,
    this.prefsForBackup,
    this.existingLineId,
    this.initialSortOrder = 0,
    this.amendmentSubmitToGroup = false,
    this.lockRecurrenceAndSplit = false,
  });

  final String planId;
  final List<String> participantIds;
  final List<String> participantNames;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String defaultCurrency;
  final String dateFormat;
  final AppPreferences prefs;
  final AppPreferences? prefsForBackup;
  final String? existingLineId;
  final int initialSortOrder;
  final bool amendmentSubmitToGroup;
  final bool lockRecurrenceAndSplit;

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
  bool _saving = false;

  final ValueNotifier<int> _splitRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _templates = await ExpenseRatioTemplateRepository(
      _db,
    ).listSelectableForPlan(widget.planId);
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
        _paymentResponsibleId = resolvePlanParticipantDropdownValue(
          loaded.paymentResponsibleParticipantId,
          widget.participantIds,
        );
        final templateId = loaded.ratioTemplateId;
        _selectedTemplateId = templateId != null &&
                _templates.any((t) => t.id == templateId)
            ? templateId
            : null;
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
    _splitRevision.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _refreshAmountDependentUi() {
    _syncSplitFromAmount();
    _splitRevision.value++;
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
    if (_saving || !_canSave) return;
    _saving = true;
    if (mounted) setState(() {});
    final now = DateTime.now().toUtc();
    final minor = parseAmountMinorFromText(_amountCtrl.text)!;
    try {
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
        prefsForBackup: widget.prefsForBackup,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e, st) {
      assert(() {
        debugPrint('ExpensePlanLineFormScreen save failed: $e\n$st');
        return true;
      }());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).housingPlanLoadError('$e'))),
        );
      }
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  void _onLikeSelected(String? templateId) {
    if (templateId == null || _split == null) return;
    final t = _templates.firstWhere((e) => e.id == templateId);
    final weights = ExpenseRatioTemplateRepository.decodeWeights(t.weightsJson);
    _selectedTemplateId = templateId;
    _likeClearedByEdit = false;
    _split!.applyWeights(weights);
    _splitRevision.value++;
  }

  void _onGridEdited() {
    if (_selectedTemplateId != null && !_likeClearedByEdit) {
      _selectedTemplateId = null;
      _likeClearedByEdit = true;
    }
    _splitRevision.value++;
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
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          ExpensePlanLineFormBody.edit(
            lockRecurrenceAndSplit: widget.lockRecurrenceAndSplit,
            titleController: _titleCtrl,
            descriptionController: _descCtrl,
            amountController: _amountCtrl,
            isRecurring: _isRecurring,
            onRecurringChanged: (v) => setState(() => _isRecurring = v),
            recurrenceSummary: _recurrence == null
                ? null
                : formatRecurrenceSpecSummary(
                    l10n,
                    widget.dateFormat,
                    _recurrence!,
                  ),
            onRecurrenceTap: () async {
              final spec = await showExpenseRecurrenceFlow(
                context: context,
                prefs: widget.prefs,
                periodStart: widget.periodStart,
                periodEnd: widget.periodEnd,
                initial: _recurrence,
                dateFormat: widget.dateFormat,
              );
              if (spec != null) setState(() => _recurrence = spec);
            },
            onTitleChanged: () => setState(() {}),
            onAmountChanged: _refreshAmountDependentUi,
            amountIsBudgetCap: _amountIsBudgetCap,
            onAmountTypeChanged: (v) => setState(() => _amountIsBudgetCap = v),
            paymentResponsibleId: _paymentResponsibleId,
            participantIds: widget.participantIds,
            participantNames: widget.participantNames,
            onPaymentResponsibleChanged: (v) =>
                setState(() => _paymentResponsibleId = v),
            currentSplitState: () => _split,
            currencyCode: widget.defaultCurrency,
            onEqualParts: () {
              _split!.resetEqualParts();
              _splitRevision.value++;
            },
            templates: _templates,
            selectedTemplateId: _selectedTemplateId,
            onLikeSelected: _onLikeSelected,
            onSplitChanged: _onGridEdited,
            onRowAmountChanged: (i, minor) {
              _split!.onAmountEdited(i, minor);
              _onGridEdited();
            },
            onRowPercentChanged: (i, tenths) {
              _split!.onPercentTenthsEdited(i, tenths);
              _onGridEdited();
            },
            splitRevision: _splitRevision,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _splitRevision,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                child: Text(
                  widget.amendmentSubmitToGroup
                      ? l10n.commonContinue
                      : l10n.housingPlanSave,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
