import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/amendment/housing_amendment_type.dart';
import '../../housing/amendment/housing_line_add_amendment_pending.dart';
import '../../housing/amendment/housing_line_edit_amendment_pending.dart';
import '../../housing/housing_plan_draft_backup.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../screens/housing/housing_amendment_submit_preview_screen.dart';
import '../../widgets/screen_body_padding.dart';
import 'expense_amount_parse.dart';
import 'expense_line_persistence.dart';
import 'expense_plan_line_form_body.dart';
import 'expense_recurrence_flow.dart';
import 'expense_recurrence_labels.dart';
import 'expense_recurrence_spec.dart';
import 'expense_ratio_template_repository.dart';
import 'expense_plan_line_form_snapshot.dart';
import 'expense_split_grid_logic.dart';
import 'plan_participant_dropdown_value.dart';
import 'package:compartarenta/navigation/app_navigation.dart';

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

  bool _isRecurring = false;
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
  ExpensePlanLineFormSnapshot? _loadedBaseline;
  String? _draftLineId;

  final ValueNotifier<int> _splitRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_refreshAmountDependentUi);
    _titleCtrl.addListener(_notifyFormChanged);
    _boot();
  }

  Future<void> _boot() async {
    _templates = await ExpenseRatioTemplateRepository(
      _db,
    ).listSelectableForPlan(widget.planId);
    if (_amendmentLineAddFlow) {
      HousingLineAddAmendmentPendingStore.clear(widget.planId);
      await purgeNonInForcePlanLines(_db, widget.planId);
      final now = DateTime.now().toUtc();
      _createdAt = now;
      _draftLineId = HousingPlanDraftBackup.newLineId(now);
    }
    if (_amendmentEditRequiresChange && widget.existingLineId != null) {
      HousingLineEditAmendmentPendingStore.clear(widget.planId);
      await restoreInForcePlanLineFromActiveRevision(
        _db,
        widget.planId,
        widget.existingLineId!,
      );
    }
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
    if (widget.existingLineId != null) {
      _loadedBaseline = _snapshotFromCurrentForm();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _notifyFormChanged() {
    if (mounted) setState(() {});
  }

  ExpensePlanLineFormSnapshot _snapshotFromCurrentForm() {
    return ExpensePlanLineFormSnapshot.fromFormState(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      amountMinor: parseAmountMinorFromText(_amountCtrl.text),
      isRecurring: _isRecurring,
      amountIsBudgetCap: _amountIsBudgetCap,
      paymentResponsibleId: _paymentResponsibleId,
      recurrence: _recurrence,
      split: _split,
      selectedTemplateId: _selectedTemplateId,
    );
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_refreshAmountDependentUi);
    _titleCtrl.removeListener(_notifyFormChanged);
    _splitRevision.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _refreshAmountDependentUi() {
    _syncSplitFromAmount();
    _splitRevision.value++;
    _notifyFormChanged();
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

  bool get _amendmentLineAddFlow =>
      widget.amendmentSubmitToGroup && widget.existingLineId == null;

  bool get _amendmentEditRequiresChange =>
      widget.amendmentSubmitToGroup && widget.existingLineId != null;

  bool get _hasChangeFromLoadedLine {
    final baseline = _loadedBaseline;
    if (baseline == null) return false;
    return _snapshotFromCurrentForm() != baseline;
  }

  bool get _canContinue =>
      _canSave && (!_amendmentEditRequiresChange || _hasChangeFromLoadedLine);

  Future<void> _discardAmendmentLineEditDraft() async {
    if (!_amendmentEditRequiresChange || widget.existingLineId == null) return;
    HousingLineEditAmendmentPendingStore.clear(widget.planId);
    try {
      await restoreInForcePlanLineFromActiveRevision(
        _db,
        widget.planId,
        widget.existingLineId!,
      );
    } catch (e, st) {
      assert(() {
        debugPrint('ExpensePlanLineFormScreen discard draft failed: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> _discardAmendmentLineAddDraft() async {
    if (!_amendmentLineAddFlow) return;
    HousingLineAddAmendmentPendingStore.clear(widget.planId);
    try {
      await purgeNonInForcePlanLines(_db, widget.planId);
    } catch (e, st) {
      assert(() {
        debugPrint('ExpensePlanLineFormScreen discard add draft failed: $e\n$st');
        return true;
      }());
    }
    _draftLineId = null;
  }

  Future<void> _discardAmendmentDrafts() async {
    await _discardAmendmentLineEditDraft();
    await _discardAmendmentLineAddDraft();
  }

  Future<void> _continueLineAddAmendment() async {
    final split = _split;
    final lineId = _draftLineId;
    if (split == null || lineId == null) return;

    final minor = parseAmountMinorFromText(_amountCtrl.text)!;
    HousingLineAddAmendmentPendingStore.set(
      widget.planId,
      HousingLineEditAmendmentPendingStore.buildFromForm(
        planId: widget.planId,
        lineId: lineId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        currency: widget.defaultCurrency,
        isRecurring: _isRecurring,
        recurrenceSpec: _isRecurring ? _recurrence : null,
        amountMinor: minor,
        amountIsBudgetCap: _amountIsBudgetCap,
        paymentResponsibleParticipantId: _paymentResponsibleId,
        sortOrder: _sortOrder,
        ratioTemplateId: _selectedTemplateId,
        split: split,
      ),
    );

    if (!mounted) return;
    await navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentSubmitPreviewScreen(
          planId: widget.planId,
          prefs: widget.prefs,
          type: HousingAmendmentType.lineAdd,
          targetLineId: lineId,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _continueLineEditAmendment() async {
    final lineId = widget.existingLineId;
    final split = _split;
    if (lineId == null || split == null) return;

    final minor = parseAmountMinorFromText(_amountCtrl.text)!;
    HousingLineEditAmendmentPendingStore.set(
      widget.planId,
      HousingLineEditAmendmentPendingStore.buildFromForm(
        planId: widget.planId,
        lineId: lineId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        currency: widget.defaultCurrency,
        isRecurring: _isRecurring,
        recurrenceSpec: _isRecurring ? _recurrence : null,
        amountMinor: minor,
        amountIsBudgetCap: _amountIsBudgetCap,
        paymentResponsibleParticipantId: _paymentResponsibleId,
        sortOrder: _sortOrder,
        ratioTemplateId: _selectedTemplateId,
        split: split,
      ),
    );

    await navigateToRoute<void>(context, 
      MaterialPageRoute<void>(
        builder: (_) => HousingAmendmentSubmitPreviewScreen(
          planId: widget.planId,
          prefs: widget.prefs,
          type: HousingAmendmentType.lineEdit,
          targetLineId: lineId,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_saving || !_canContinue) return;
    if (_amendmentLineAddFlow) {
      _saving = true;
      if (mounted) setState(() {});
      try {
        await _continueLineAddAmendment();
      } finally {
        _saving = false;
        if (mounted) setState(() {});
      }
      return;
    }
    if (_amendmentEditRequiresChange) {
      _saving = true;
      if (mounted) setState(() {});
      try {
        await _continueLineEditAmendment();
      } finally {
        _saving = false;
        if (mounted) setState(() {});
      }
      return;
    }

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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(_discardAmendmentDrafts());
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLineId == null
              ? l10n.housingPlanAddExpenseTitle
              : l10n.housingPlanEditExpenseTitle,
        ),
      ),
      body: Semantics(
        identifier: kDebugMode ? 'qa-housing-expense-form' : null,
        container: true,
        child: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          ExpensePlanLineFormBody.edit(
            lockRecurrenceAndSplit: widget.lockRecurrenceAndSplit,
            titleController: _titleCtrl,
            descriptionController: _descCtrl,
            amountController: _amountCtrl,
            isRecurring: _isRecurring,
            onRecurringChanged: (v) => setState(() {
              _isRecurring = v;
              if (!v) _recurrence = null;
            }),
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
                periodEnd: widget.periodEnd,
                initial: _recurrence,
                dateFormat: widget.dateFormat,
              );
              if (spec != null) {
                setState(() => _recurrence = spec);
                _notifyFormChanged();
              }
            },
            onTitleChanged: _notifyFormChanged,
            onAmountChanged: _refreshAmountDependentUi,
            amountIsBudgetCap: _amountIsBudgetCap,
            onAmountTypeChanged: (v) {
              _amountIsBudgetCap = v;
              _notifyFormChanged();
            },
            paymentResponsibleId: _paymentResponsibleId,
            participantIds: widget.participantIds,
            participantNames: widget.participantNames,
            onPaymentResponsibleChanged: (v) {
              _paymentResponsibleId = v;
              _notifyFormChanged();
            },
            currentSplitState: () => _split,
            currencyCode: widget.defaultCurrency,
            onEqualParts: () {
              _split!.resetEqualParts();
              _splitRevision.value++;
              _notifyFormChanged();
            },
            templates: _templates,
            selectedTemplateId: _selectedTemplateId,
            onLikeSelected: (id) {
              _onLikeSelected(id);
              _notifyFormChanged();
            },
            onSplitChanged: () {
              _onGridEdited();
              _notifyFormChanged();
            },
            onRowAmountChanged: (i, minor) {
              _split!.onAmountEdited(i, minor);
              _onGridEdited();
              _notifyFormChanged();
            },
            onRowPercentChanged: (i, tenths) {
              _split!.onPercentTenthsEdited(i, tenths);
              _onGridEdited();
              _notifyFormChanged();
            },
            splitRevision: _splitRevision,
          ),
        ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          _splitRevision,
          _titleCtrl,
          _descCtrl,
          _amountCtrl,
        ]),
        builder: (context, _) {
          _syncSplitFromAmount();
          final canContinue = _canContinue;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                identifier: kDebugMode ? 'qa-housing-expense-form-save' : null,
                button: true,
                label: l10n.housingPlanSave,
                enabled: canContinue && !_saving,
                excludeSemantics: true,
                child: FilledButton(
                  onPressed: canContinue && !_saving ? _save : null,
                  child: Text(
                    widget.amendmentSubmitToGroup
                        ? l10n.commonContinue
                        : l10n.housingPlanSave,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}
