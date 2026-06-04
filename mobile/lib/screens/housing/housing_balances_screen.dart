import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/participation/housing_inactive_participant_service.dart';
import '../../housing/realized_expense/realized_expense_ledger_service.dart';
import '../../housing/realized_expense/realized_expense_balance.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';
import 'housing_inactive_settlement_form_screen.dart';
import 'widgets/housing_balances_graph.dart';
import 'widgets/housing_balances_legend.dart';

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
  HousingBalanceMode _mode = HousingBalanceMode.real;

  @override
  void initState() {
    super.initState();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
    _pollInboxOnce();
  }

  @override
  void dispose() {
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

  void _pollInboxOnce() {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    unawaited(
      orch.pollSteadyStateInboxes().catchError((Object e, StackTrace st) {
        debugPrint('housing balances poll: $e\n$st');
      }),
    );
  }

  Future<void> _openInactiveSettlement(HousingInactiveParticipant inactive) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HousingInactiveSettlementFormScreen(
          planId: widget.planId,
          inactiveParticipantId: inactive.id,
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = RealizedExpenseLedgerService(AppDatabase.processScope);
    final inactiveSvc = HousingInactiveParticipantService(AppDatabase.processScope);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingBalancesTitle)),
      body: FutureBuilder<({HousingBalanceData data, List<HousingInactiveParticipant> inactive})>(
        future: () async {
          final data = await ledger.balanceDataForPlan(widget.planId);
          final inactive = await inactiveSvc.listUncleared(widget.planId);
          return (data: data, inactive: inactive);
        }(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = snap.data;
          if (bundle == null) {
            return Center(child: Text(l10n.housingBalancesEmpty));
          }
          final data = bundle.data;
          final inactiveRows = bundle.inactive;
          final modeData = data.modeData(_mode);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (inactiveRows.isNotEmpty) ...[
                for (final inactive in inactiveRows)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.person_off_outlined),
                      title: Text(
                        l10n.housingInactiveSettlementParticipantLabel(
                          inactive.displayNameSnapshot,
                        ),
                      ),
                      subtitle: Text(l10n.housingInactiveSettlementTileSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openInactiveSettlement(inactive),
                    ),
                  ),
              ],
              SegmentedButton<HousingBalanceMode>(
                segments: [
                  ButtonSegment(
                    value: HousingBalanceMode.real,
                    label: Text(l10n.housingBalancesModeReal),
                  ),
                  ButtonSegment(
                    value: HousingBalanceMode.optimized,
                    label: Text(l10n.housingBalancesModeOptimized),
                  ),
                ],
                selected: {_mode},
                emptySelectionAllowed: false,
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) {
                    return;
                  }
                  setState(() => _mode = selection.first);
                },
              ),
              const SizedBox(height: 16),
              if (modeData.edges.isEmpty) ...[
                Text(
                  l10n.housingBalancesEmpty,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: HousingBalancesGraph(
                    participants: data.participants,
                    modeData: modeData,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HousingBalancesLegend(
                participants: data.participants,
                modeData: modeData,
                currency: widget.currency,
              ),
            ],
          );
        },
      ),
    );
  }
}
