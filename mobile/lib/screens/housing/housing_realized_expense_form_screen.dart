import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/expense_form/expense_amount_parse.dart';
import '../../housing/realized_expense/proof_attachment_export.dart';
import '../../housing/realized_expense/proof_attachment_storage.dart';
import '../../housing/realized_expense/proof_pick_flow.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_repository.dart';
import '../../housing/realized_expense/realized_expense_status.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../util/week_start_calendar.dart';

/// Full-screen realized expense entry (pass 2 — local draft + propose).
class HousingRealizedExpenseFormScreen extends StatefulWidget {
  const HousingRealizedExpenseFormScreen({
    super.key,
    required this.planId,
    required this.packageId,
    this.prefs,
    this.existingExpenseId,
  });

  final String planId;
  final String packageId;
  final AppPreferences? prefs;
  final String? existingExpenseId;

  @override
  State<HousingRealizedExpenseFormScreen> createState() =>
      _HousingRealizedExpenseFormScreenState();
}

class _FormContext {
  const _FormContext({
    required this.planLines,
    required this.participants,
    required this.currency,
    required this.periodStart,
    required this.periodEnd,
    required this.prefs,
  });

  final List<PlanLine> planLines;
  final List<Participant> participants;
  final String currency;
  final DateTime periodStart;
  final DateTime periodEnd;
  final AppPreferences prefs;
}

class _AttachmentUi {
  _AttachmentUi({this.id, required this.stored});

  final String? id;
  final StoredProof stored;
}

class _HousingRealizedExpenseFormScreenState
    extends State<HousingRealizedExpenseFormScreen> {
  static const bool _showDraftAction = false;

  final _repo = RealizedExpenseRepository(AppDatabase.processScope);
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Future<_FormContext?>? _loadFuture;

  String? _planLineId;
  String _kind = RealizedExpenseKind.normal;
  String? _beneficiaryId;
  DateTime? _paymentDate;
  final List<_AttachmentUi> _attachments = [];
  bool _submitting = false;
  String? _draftExpenseId;

  @override
  void initState() {
    super.initState();
    _draftExpenseId = widget.existingExpenseId;
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<_FormContext?> _load() async {
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (agreement == null) return null;

    final lines = await db.listPlanLines(widget.planId);
    final participants = await participantsForPlan(db, widget.planId);
    final prefs = widget.prefs ?? await AppPreferences.load();
    final currency = displayCurrencyCodeForPlan(prefs, lines);

    if (_draftExpenseId != null) {
      final expense = await _repo.getById(_draftExpenseId!);
      if (expense != null && expense.status == RealizedExpenseStatus.draft) {
        _planLineId = expense.planLineId;
        _kind = RealizedExpenseKind.normalizeForForm(expense.kind);
        _beneficiaryId = expense.beneficiaryParticipantId;
        _descriptionController.text = (expense.description ?? '').trim();
        _paymentDate = expense.paymentDate;
        _amountController.text = minorToAmountText(expense.amountMinor);
        final atts = await _repo.attachmentsFor(expense.id);
        _attachments
          ..clear()
          ..addAll(
            atts.map(
              (a) => _AttachmentUi(
                id: a.id,
                stored: StoredProof(
                  filePath: a.filePath,
                  displayFileName: a.displayFileName,
                  contentHash: a.contentHash,
                ),
              ),
            ),
          );
      }
    } else {
      _paymentDate ??= DateTime.now();
      if (lines.isNotEmpty) {
        _planLineId ??= lines.first.id;
      }
    }

    return _FormContext(
      planLines: lines,
      participants: participants,
      currency: currency.isNotEmpty ? currency : 'CAD',
      periodStart: agreement.periodStart,
      periodEnd: agreement.periodEnd,
      prefs: prefs,
    );
  }

  Future<void> _pickPaymentDate(_FormContext ctx) async {
    final firstAllowed = DateTime(
      ctx.periodStart.year,
      ctx.periodStart.month,
      ctx.periodStart.day,
    );
    final periodEnd = DateTime(
      ctx.periodEnd.year,
      ctx.periodEnd.month,
      ctx.periodEnd.day,
    );
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastAllowed = periodEnd.isBefore(todayDate) ? periodEnd : todayDate;
    final initial = (_paymentDate ?? todayDate).isAfter(lastAllowed)
        ? lastAllowed
        : _paymentDate ?? todayDate;
    final picked = await showAppDatePicker(
      context: context,
      prefs: ctx.prefs,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _addProof() async {
    final stored = await pickAndStoreProof(context);
    if (stored == null || !mounted) return;
    setState(() => _attachments.add(_AttachmentUi(stored: stored)));
  }

  Future<void> _exportAttachment(StoredProof stored) async {
    final ok = await exportStoredProofCopy(
      displayFileName: stored.displayFileName,
      filePath: stored.filePath,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          ).housingRealizedExpenseProofSaveCopyFailed,
        ),
      ),
    );
  }

  List<RealizedExpenseAttachmentDraft> _attachmentDrafts() {
    return _attachments
        .map(
          (a) => RealizedExpenseAttachmentDraft(
            id: a.id,
            filePath: a.stored.filePath,
            displayFileName: a.stored.displayFileName,
            contentHash: a.stored.contentHash,
          ),
        )
        .toList(growable: false);
  }

  String? _validate(AppLocalizations l10n, _FormContext ctx) {
    if (RealizedExpenseKind.usesPlanLine(_kind) &&
        (_planLineId == null || _planLineId!.isEmpty)) {
      return l10n.housingRealizedExpenseValidationLine;
    }
    final minor = parseAmountMinorFromText(_amountController.text);
    if (minor == null || minor <= 0) {
      return l10n.housingRealizedExpenseValidationAmount;
    }
    if (_paymentDate == null) {
      return l10n.housingRealizedExpenseValidationDate;
    }
    if (_kind == RealizedExpenseKind.transfer &&
        (_beneficiaryId == null || _beneficiaryId!.isEmpty)) {
      return l10n.housingRealizedExpenseValidationBeneficiary;
    }
    if (RealizedExpenseKind.usesPlanLine(_kind) && ctx.planLines.isEmpty) {
      return l10n.housingRealizedExpenseNoPlanLines;
    }
    return null;
  }

  Future<void> _saveDraft(_FormContext ctx) async {
    final l10n = AppLocalizations.of(context);
    final error = _validate(l10n, ctx);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final minor = parseAmountMinorFromText(_amountController.text)!;
    final selfId = selfParticipantIdForPlan(widget.planId);
    final saved = await _repo.saveDraft(
      packageId: widget.packageId,
      planId: widget.planId,
      planLineId: RealizedExpenseKind.usesPlanLine(_kind) ? _planLineId! : '',
      amountMinor: minor,
      currency: ctx.currency,
      paymentDate: _paymentDate!,
      payerParticipantId: selfId,
      kind: _kind,
      beneficiaryParticipantId: _kind == RealizedExpenseKind.transfer
          ? _beneficiaryId
          : null,
      description:
          _kind == RealizedExpenseKind.transfer ||
              _kind == RealizedExpenseKind.normal
          ? _descriptionController.text
          : null,
      existingExpenseId: _draftExpenseId,
      attachments: _attachmentDrafts(),
    );
    setState(() => _draftExpenseId = saved.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.housingRealizedExpenseDraftSaved)),
    );
  }

  Future<bool> _confirmBudgetCapIfNeeded(
    AppLocalizations l10n,
    _FormContext ctx,
    int newAmountMinor,
  ) async {
    if (!RealizedExpenseKind.usesPlanLine(_kind)) {
      return true;
    }
    PlanLine? line;
    for (final l in ctx.planLines) {
      if (l.id == _planLineId) {
        line = l;
        break;
      }
    }
    if (line == null || !line.amountIsBudgetCap || line.amountMinor == null) {
      return true;
    }
    final cap = line.amountMinor!;
    final payment = _paymentDate ?? DateTime.now();
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);
    final sum = await ledger.sumPublishedMinorForLineMonth(
      packageId: widget.packageId,
      planId: widget.planId,
      planLineId: line.id,
      year: payment.year,
      month: payment.month,
    );
    if (sum + newAmountMinor <= cap) return true;

    if (!mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.housingRealizedExpenseBudgetCapTitle),
        content: Text(
          l10n.housingRealizedExpenseBudgetCapBody(
            formatMinorAsMoney(context, cap, ctx.currency),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.housingRealizedExpenseBudgetCapConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit(_FormContext ctx) async {
    final l10n = AppLocalizations.of(context);
    final error = _validate(l10n, ctx);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final minor = parseAmountMinorFromText(_amountController.text)!;
    if (!await _confirmBudgetCapIfNeeded(l10n, ctx, minor)) return;

    setState(() => _submitting = true);
    try {
      final selfId = selfParticipantIdForPlan(widget.planId);
      final saved = await _repo.saveDraft(
        packageId: widget.packageId,
        planId: widget.planId,
        planLineId: RealizedExpenseKind.usesPlanLine(_kind) ? _planLineId! : '',
        amountMinor: minor,
        currency: ctx.currency,
        paymentDate: _paymentDate!,
        payerParticipantId: selfId,
        kind: _kind,
        beneficiaryParticipantId: _kind == RealizedExpenseKind.transfer
            ? _beneficiaryId
            : null,
        description:
            _kind == RealizedExpenseKind.transfer ||
                _kind == RealizedExpenseKind.normal
            ? _descriptionController.text
            : null,
        existingExpenseId: _draftExpenseId,
        attachments: _attachmentDrafts(),
      );
      await _repo.proposeLocally(saved.id);
      await RealizedExpenseLedgerService(
        AppDatabase.processScope,
      ).markPlanActiveUseIfNeeded(widget.planId);
      final orchestrator = HandshakeOrchestrator.maybeInstance;
      if (orchestrator != null) {
        await orchestrator.sendRealizedExpensePropose(expenseId: saved.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingRealizedExpenseProposedSnackbar)),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingRealizedExpenseTitle)),
      body: SafeArea(
        child: FutureBuilder<_FormContext?>(
          future: _loadFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final ctx = snap.data;
            if (ctx == null) {
              return Center(child: Text(l10n.housingRealizedExpenseLoadFailed));
            }

            final dateFmt = effectiveDateFormat(ctx.prefs);
            final paymentLabel = _paymentDate == null
                ? l10n.housingRealizedExpensePaymentDatePick
                : formatPreferenceDate(_paymentDate!, dateFmt);
            final dateFieldLabel = _kind == RealizedExpenseKind.transfer
                ? l10n.housingRealizedExpenseTransferDate
                : l10n.housingRealizedExpensePaymentDate;

            final selfId = selfParticipantIdForPlan(widget.planId);
            final otherParticipants = ctx.participants
                .where((p) => p.id != selfId)
                .toList(growable: false);
            final showPlanLineField = RealizedExpenseKind.usesPlanLine(_kind);
            final showTransferFields = _kind == RealizedExpenseKind.transfer;
            final showDescriptionField =
                _kind == RealizedExpenseKind.transfer ||
                _kind == RealizedExpenseKind.normal;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  l10n.housingRealizedExpenseKind,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: RealizedExpenseKind.normal,
                      label: Text(l10n.housingRealizedExpenseKindNormal),
                    ),
                    ButtonSegment(
                      value: RealizedExpenseKind.transfer,
                      label: Text(l10n.housingRealizedExpenseKindTransfer),
                    ),
                  ],
                  selected: {_kind},
                  emptySelectionAllowed: false,
                  onSelectionChanged: (selected) {
                    if (selected.isEmpty) return;
                    setState(() {
                      _kind = selected.first;
                      if (RealizedExpenseKind.usesPlanLine(_kind)) {
                        _planLineId ??= ctx.planLines.isEmpty
                            ? null
                            : ctx.planLines.first.id;
                      } else {
                        _planLineId = null;
                      }
                      if (_kind != RealizedExpenseKind.transfer) {
                        _beneficiaryId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (showPlanLineField) ...[
                  if (ctx.planLines.isEmpty)
                    Text(
                      l10n.housingRealizedExpenseNoPlanLines,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _planLineId,
                      decoration: InputDecoration(
                        labelText: l10n.housingRealizedExpensePlanLine,
                      ),
                      isExpanded: true,
                      items: [
                        for (final line in ctx.planLines)
                          DropdownMenuItem(
                            value: line.id,
                            child: Text(
                              line.title.trim().isEmpty
                                  ? line.id
                                  : line.title.trim(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _planLineId = v),
                    ),
                  const SizedBox(height: 16),
                ],
                if (showTransferFields) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _beneficiaryId,
                    decoration: InputDecoration(
                      labelText: l10n.housingRealizedExpenseTransferRecipient,
                    ),
                    isExpanded: true,
                    items: [
                      for (final p in otherParticipants)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            displayNameForParticipant(p.id, ctx.participants),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _beneficiaryId = v),
                  ),
                ],
                if (showDescriptionField) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.housingRealizedExpenseTransferDescription,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: l10n.housingRealizedExpenseAmount,
                          suffixText: ctx.currency,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => _pickPaymentDate(ctx),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: dateFieldLabel,
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          child: Text(paymentLabel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.housingRealizedExpenseProofSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.housingRealizedExpenseProofEncourage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _addProof,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.housingRealizedExpenseAddProof),
                ),
                const SizedBox(height: 64),
                for (final att in _attachments) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(att.stored.displayFileName),
                      subtitle: Text(
                        l10n.housingRealizedExpenseProofTapToSaveCopy,
                      ),
                      onTap: _submitting
                          ? null
                          : () => _exportAttachment(att.stored),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _attachments.remove(att)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (_showDraftAction) ...[
                  OutlinedButton(
                    onPressed: _submitting ? null : () => _saveDraft(ctx),
                    child: Text(l10n.housingRealizedExpenseSaveDraft),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: _submitting ? null : () => _submit(ctx),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.housingRealizedExpenseSubmit),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
