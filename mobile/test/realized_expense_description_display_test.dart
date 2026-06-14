import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_description_display.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('realized expense penalty descriptions are localized for display', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    final expense = RealizedExpense(
      id: 'exp:1',
      packageId: 'pkg:1',
      planId: 'plan:1',
      planLineId: '',
      status: RealizedExpenseStatus.published,
      amountMinor: -50000,
      currency: 'CAD',
      paymentDate: DateTime.utc(2026, 6, 14),
      payerParticipantId: 'plan:louys',
      kind: RealizedExpenseKind.transfer,
      beneficiaryParticipantId: 'plan:monica',
      priorExpenseId: null,
      planLineTitleSnapshot: null,
      splitRatiosJson: null,
      description: kEarlyWithdrawalPenaltyDescriptionKey,
      createdAt: DateTime.utc(2026, 6, 14),
      updatedAt: DateTime.utc(2026, 6, 14),
    );

    expect(
      realizedExpenseDescriptionForList(l10n, expense),
      'Pénalité de départ anticipé',
    );
    expect(
      realizedExpenseDescriptionForDetail(
        l10n,
        expense,
        beneficiaryDisplayName: 'Monica',
      ),
      'Pénalité de départ anticipé\nCe montant est dû à Monica.',
    );
  });
}
