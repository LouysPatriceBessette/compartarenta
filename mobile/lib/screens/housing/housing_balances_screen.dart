import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_balance.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../l10n/app_localizations.dart';
import '../../util/format_money.dart';

class HousingBalancesScreen extends StatelessWidget {
  const HousingBalancesScreen({
    super.key,
    required this.planId,
    required this.currency,
  });

  final String planId;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingBalancesTitle)),
      body: FutureBuilder<List<PairwiseBalanceEntry>>(
        future: ledger.pairwiseBalancesForPlan(planId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final balances = snap.data ?? const [];
          if (balances.isEmpty) {
            return Center(child: Text(l10n.housingBalancesEmpty));
          }
          return FutureBuilder<List<Participant>>(
            future: participantsForPlan(AppDatabase.processScope, planId),
            builder: (context, rosterSnap) {
              final roster = rosterSnap.data ?? const [];
              String name(String id) =>
                  displayNameForParticipant(id, roster);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: balances.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = balances[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        l10n.housingBalancesOwes(
                          name(entry.fromParticipantId),
                          name(entry.toParticipantId),
                          formatMinorAsMoney(
                            context,
                            entry.amountMinor,
                            currency,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
