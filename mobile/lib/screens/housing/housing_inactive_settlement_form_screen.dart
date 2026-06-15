import 'package:flutter/material.dart';
import '../../widgets/app_text_field.dart';

import '../../db/app_database.dart';
import '../../housing/expense_form/expense_amount_parse.dart';
import '../../housing/participation/housing_inactive_participant_service.dart';
import '../../housing/participation/housing_inactive_settlement_transfer.dart';
import '../../housing/participation/housing_participation_change_service.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../housing/realized_expense/realized_expense_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
import '../../util/format_money.dart';

/// Records a closure transfer toward an inactive (departed) participant.
class HousingInactiveSettlementFormScreen extends StatefulWidget {
  const HousingInactiveSettlementFormScreen({
    super.key,
    required this.planId,
    required this.inactiveParticipantId,
    this.prefs,
  });

  final String planId;
  final String inactiveParticipantId;
  final AppPreferences? prefs;

  @override
  State<HousingInactiveSettlementFormScreen> createState() =>
      _HousingInactiveSettlementFormScreenState();
}

class _HousingInactiveSettlementFormScreenState
    extends State<HousingInactiveSettlementFormScreen> {
  final _amountController = TextEditingController();
  final _repo = RealizedExpenseRepository(AppDatabase.processScope);
  DateTime? _paymentDate;
  bool _submitting = false;
  HousingInactiveParticipant? _inactive;
  AppPreferences? _prefs;
  String? _packageId;
  String _currency = '';
  int _netBalanceMinor = 0;

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
    final inactiveSvc = HousingInactiveParticipantService(db);
    final inactive = await inactiveSvc.getById(widget.inactiveParticipantId);
    if (inactive == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final packageId =
        await HousingParticipationChangeService(db).packageIdForPlan(
      widget.planId,
    );
    final lines = await db.listPlanLines(widget.planId);
    final prefs = _prefs ?? await AppPreferences.load();
    final net = await RealizedExpenseLedgerService(db).netBalanceMinorForInactive(
      planId: widget.planId,
      inactiveParticipantId: widget.inactiveParticipantId,
    );
    if (!mounted) return;
    setState(() {
      _inactive = inactive;
      _packageId = packageId;
      _currency = lines.isEmpty ? prefs.currency : lines.first.currency;
      _netBalanceMinor = net;
      _paymentDate ??= DateTime.now();
    });
  }

  String? _validationMessage(AppLocalizations l10n, int amountMinor) {
    final code = HousingInactiveSettlementTransfer.validateAmount(
      amountMinor: amountMinor,
      inactiveNetBalanceMinor: _netBalanceMinor,
    );
    return switch (code) {
      'zero_amount' => l10n.housingInactiveSettlementErrorZero,
      'cannot_create_credit_for_inactive' =>
        l10n.housingInactiveSettlementErrorCannotCreateCredit,
      'exceeds_inactive_debt' => l10n.housingInactiveSettlementErrorExceedsDebt,
      'cannot_increase_inactive_debt' =>
        l10n.housingInactiveSettlementErrorCannotIncreaseDebt,
      'exceeds_inactive_credit' =>
        l10n.housingInactiveSettlementErrorExceedsCredit,
      _ => null,
    };
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final packageId = _packageId;
    final inactive = _inactive;
    if (packageId == null || inactive == null || _paymentDate == null) return;

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
      final payerId = signedMinor > 0 ? selfId : inactive.id;
      final beneficiaryId = signedMinor > 0 ? inactive.id : selfId;

      await _repo.publishSystemTransfer(
        packageId: packageId,
        planId: widget.planId,
        amountMinor: absMinor,
        currency: _currency,
        paymentDate: _paymentDate!,
        payerParticipantId: payerId,
        beneficiaryParticipantId: beneficiaryId,
        description: l10n.housingInactiveSettlementTransferDescription,
      );

      final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);
      final remaining = await ledger.netBalanceMinorForInactive(
        planId: widget.planId,
        inactiveParticipantId: inactive.id,
      );
      if (remaining == 0) {
        await HousingInactiveParticipantService(
          AppDatabase.processScope,
        ).markCleared(inactive.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.housingInactiveSettlementSuccess)),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inactive = _inactive;
    final prefs = _prefs;
    if (inactive == null || prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dateFmt = effectiveDateFormat(prefs);
    final paymentLabel = _paymentDate == null
        ? l10n.housingRealizedExpensePaymentDatePick
        : formatPreferenceDate(_paymentDate!, dateFmt);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingInactiveSettlementTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.housingInactiveSettlementParticipantLabel(
              inactive.displayNameSnapshot,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.housingInactiveSettlementCurrentBalance(
              formatMinorAsMoney(context, _netBalanceMinor, _currency),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
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
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _paymentDate = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(l10n.housingInactiveSettlementSubmit),
          ),
        ],
      ),
    );
  }
}

/// Parses a signed amount in minor units from user text (supports leading `-`).
int? parseSignedAmountMinorFromText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final negative = trimmed.startsWith('-');
  final unsigned = negative ? trimmed.substring(1).trim() : trimmed;
  final minor = parseAmountMinorFromText(unsigned);
  if (minor == null) return null;
  return negative ? -minor : minor;
}
