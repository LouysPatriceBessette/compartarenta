import 'package:flutter/material.dart';
import '../../widgets/app_decimal_text_field.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_status.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/realized_expense/realized_expense_repository.dart';
import '../../housing/settlement/housing_settlement_due_transfer.dart';
import '../../housing/settlement/housing_settlement_window.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';
import '../../util/week_start_calendar.dart';
import '../../widgets/screen_body_padding.dart';
import 'housing_inactive_settlement_form_screen.dart';

/// Records a settlement transfer toward another active participant.
class HousingSettlementDueFormScreen extends StatefulWidget {
  const HousingSettlementDueFormScreen({
    super.key,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  @override
  State<HousingSettlementDueFormScreen> createState() =>
      _HousingSettlementDueFormScreenState();
}

class _SettlementCounterparty {
  const _SettlementCounterparty({
    required this.participantId,
    required this.displayName,
    required this.pairwiseNetMinor,
  });

  final String participantId;
  final String displayName;
  final int pairwiseNetMinor;
}

class _HousingSettlementDueFormScreenState
    extends State<HousingSettlementDueFormScreen> {
  final _amountController = TextEditingController();
  final _repo = RealizedExpenseRepository(AppDatabase.processScope);
  DateTime? _paymentDate;
  bool _submitting = false;
  AppPreferences? _prefs;
  String _currency = '';
  DateTime? _periodStart;
  DateTime? _settlementWindowEnd;
  List<_SettlementCounterparty> _counterparties = const [];
  String? _selectedParticipantId;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs;
    if (_prefs == null) {
      AppPreferences.load().then((p) {
        if (mounted) setState(() => _prefs = p);
      });
    }
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppDatabase.processScope;
    final agreement = await db.getAgreementForPlan(widget.planId);
    if (agreement == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final ledger = RealizedExpenseLedgerService(db);
    final hasNonZero = await ledger.hasNonZeroOptimizedBalances(widget.planId);
    if (!isSettlementOpen(
      agreement: agreement,
      hasNonZeroOptimizedBalances: hasNonZero,
    )) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final roster = await participantsForPlan(db, widget.planId);
    final selfId = selfParticipantIdForPlan(widget.planId);
    final edges = (await ledger.balanceDataForPlan(widget.planId))
        .optimizedMode
        .edges;
    final lines = await db.listPlanLines(widget.planId);
    final prefs = _prefs ?? await AppPreferences.load();
    final counterparties = <_SettlementCounterparty>[];
    for (final participant in roster) {
      if (participant.id == selfId) continue;
      final net = HousingSettlementDueTransfer.pairwiseNetFromSelf(
        edges: edges,
        selfId: selfId,
        otherId: participant.id,
      );
      if (net == 0) continue;
      counterparties.add(
        _SettlementCounterparty(
          participantId: participant.id,
          displayName: displayNameForParticipant(participant.id, roster),
          pairwiseNetMinor: net,
        ),
      );
    }
    counterparties.sort(
      (a, b) => compareParticipantDisplayNames(a.displayName, b.displayName),
    );
    if (!mounted) return;
    setState(() {
      _periodStart = agreement.periodStart;
      _settlementWindowEnd = settlementWindowLastDayInclusive(
        agreement.periodEnd,
      );
      _currency = lines.isEmpty ? prefs.currency : lines.first.currency;
      _counterparties = counterparties;
      _selectedParticipantId ??=
          counterparties.isEmpty ? null : counterparties.first.participantId;
      _paymentDate ??= DateTime.now();
    });
  }

  _SettlementCounterparty? get _selectedCounterparty {
    final id = _selectedParticipantId;
    if (id == null) return null;
    for (final c in _counterparties) {
      if (c.participantId == id) return c;
    }
    return null;
  }

  String? _validationMessage(AppLocalizations l10n, int amountMinor) {
    final counterparty = _selectedCounterparty;
    if (counterparty == null) {
      return l10n.housingRealizedExpenseValidationBeneficiary;
    }
    final code = HousingSettlementDueTransfer.validateAmount(
      amountMinor: amountMinor,
      pairwiseNetFromSelfMinor: counterparty.pairwiseNetMinor,
    );
    return switch (code) {
      'zero_amount' => l10n.housingInactiveSettlementErrorZero,
      'cannot_create_credit' =>
        l10n.housingInactiveSettlementErrorCannotCreateCredit,
      'exceeds_debt' => l10n.housingInactiveSettlementErrorExceedsDebt,
      'cannot_increase_debt' =>
        l10n.housingInactiveSettlementErrorCannotIncreaseDebt,
      'exceeds_credit' => l10n.housingInactiveSettlementErrorExceedsCredit,
      _ => null,
    };
  }

  Future<void> _pickPaymentDate() async {
    final prefs = _prefs;
    final periodStart = _periodStart;
    final windowEnd = _settlementWindowEnd;
    if (prefs == null || periodStart == null || windowEnd == null) return;
    final firstAllowed = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastAllowed = windowEnd.isBefore(todayDate) ? windowEnd : todayDate;
    final initial = (_paymentDate ?? todayDate).isAfter(lastAllowed)
        ? lastAllowed
        : _paymentDate ?? todayDate;
    final picked = await showAppDatePicker(
      context: context,
      prefs: prefs,
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final counterparty = _selectedCounterparty;
    if (counterparty == null || _paymentDate == null) return;

    final signedMinor = parseSignedAmountMinorFromText(_amountController.text);
    if (signedMinor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingRealizedExpenseValidationAmount)),
      );
      return;
    }
    final error = _validationMessage(l10n, signedMinor);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final selfId = selfParticipantIdForPlan(widget.planId);
      final absMinor = signedMinor.abs();
      final payerId = signedMinor > 0 ? selfId : counterparty.participantId;
      final beneficiaryId = signedMinor > 0 ? counterparty.participantId : selfId;

      final saved = await _repo.saveDraft(
        packageId: widget.packageId,
        planId: widget.planId,
        planLineId: '',
        amountMinor: absMinor,
        currency: _currency,
        paymentDate: _paymentDate!,
        payerParticipantId: payerId,
        kind: RealizedExpenseKind.transfer,
        beneficiaryParticipantId: beneficiaryId,
        description: l10n.housingSettlementDueTransferDescription,
        existingExpenseId: null,
        attachments: const [],
      );
      await _repo.proposeLocally(saved.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingSettlementDueSuccess)),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = _prefs;
    if (prefs == null || _counterparties.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.housingSettlementDueTitle)),
        body: Center(
          child: _counterparties.isEmpty && prefs != null
              ? Text(l10n.housingSettlementDueNoCounterparties)
              : const CircularProgressIndicator(),
        ),
      );
    }

    final counterparty = _selectedCounterparty;
    final dateFmt = effectiveDateFormat(prefs);
    final paymentLabel = _paymentDate == null
        ? l10n.housingRealizedExpensePaymentDatePick
        : formatPreferenceDate(_paymentDate!, dateFmt);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingSettlementDueTitle)),
      body: ListView(
        padding: screenBodyScrollPadding(context),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedParticipantId,
            decoration: InputDecoration(
              labelText: l10n.housingRealizedExpenseTransferRecipient,
            ),
            isExpanded: true,
            items: [
              for (final c in _counterparties)
                DropdownMenuItem(
                  value: c.participantId,
                  child: Text(c.displayName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _selectedParticipantId = v;
              _amountController.clear();
            }),
          ),
          if (counterparty != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.housingInactiveSettlementCurrentBalance(
                formatMinorAsMoney(
                  context,
                  counterparty.pairwiseNetMinor,
                  _currency,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppDecimalTextField(
            controller: _amountController,
            fractionDigits: 2,
            signed: true,
            decoration: InputDecoration(
              labelText: l10n.housingInactiveSettlementAmountLabel,
              helperText: l10n.housingInactiveSettlementAmountHint,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.housingRealizedExpenseTransferDate),
            subtitle: Text(paymentLabel),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickPaymentDate,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(l10n.housingSettlementDueSubmit),
          ),
        ],
      ),
    );
  }
}
