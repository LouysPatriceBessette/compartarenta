import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/realized_expense/realized_expense_balance.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/format_money.dart';

class HousingBalancesScreen extends StatefulWidget {
  const HousingBalancesScreen({
    super.key,
    required this.planId,
    required this.currency,
  });

  final String planId;
  final String currency;

  @override
  State<HousingBalancesScreen> createState() => _HousingBalancesScreenState();
}

class _HousingBalancesScreenState extends State<HousingBalancesScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    _startRefreshPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.removeListener(
      _onSteadyInboxTick,
    );
    super.dispose();
  }

  void _onSteadyInboxTick() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _startRefreshPolling() {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    unawaited(
      orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing balances poll: $e\n$st');
      }),
    );
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      final pollOrch = HandshakeOrchestrator.maybeInstance;
      if (pollOrch == null) return;
      unawaited(
        pollOrch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
          debugPrint('housing balances poll: $e\n$st');
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingBalancesTitle)),
      body: FutureBuilder<List<PairwiseBalanceEntry>>(
        future: ledger.pairwiseBalancesForPlan(widget.planId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final balances = snap.data ?? const [];
          if (balances.isEmpty) {
            return Center(child: Text(l10n.housingBalancesEmpty));
          }
          return FutureBuilder<List<Participant>>(
            future: participantsForPlan(
              AppDatabase.processScope,
              widget.planId,
            ),
            builder: (context, rosterSnap) {
              final roster = rosterSnap.data ?? const [];
              String name(String id) => displayNameForParticipant(id, roster);
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
                            widget.currency,
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
