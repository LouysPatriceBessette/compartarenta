import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../db/app_database.dart';
import '../../housing/housing_plan_peer_contacts.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';

/// Lists every co-participant on a housing proposal and whether this device
/// has a relay-reachable contact for them.
class HousingPlanMissingContactsScreen extends StatefulWidget {
  const HousingPlanMissingContactsScreen({
    super.key,
    required this.db,
    required this.planId,
  });

  final AppDatabase db;
  final String planId;

  @override
  State<HousingPlanMissingContactsScreen> createState() =>
      _HousingPlanMissingContactsScreenState();
}

class _HousingPlanMissingContactsScreenState
    extends State<HousingPlanMissingContactsScreen> {
  late Future<List<PlanPeerContactRow>> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _rowsFuture = _loadRows();
    HandshakeOrchestrator.maybeInstance?.steadyStateInboxTick.addListener(
      _onSteadyInboxTick,
    );
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
    setState(() => _rowsFuture = _loadRows());
  }

  Future<List<PlanPeerContactRow>> _loadRows() {
    return listPlanPeerContactRows(db: widget.db, planId: widget.planId);
  }

  void _reloadAfterContactsFlow() {
    setState(() => _rowsFuture = _loadRows());
  }

  void _openGenerateInvitation() {
    context.push<void>('/contacts/invite/new').then((_) {
      if (!mounted) return;
      _reloadAfterContactsFlow();
    });
  }

  void _openRedeemInvitation(String displayName) {
    context
        .push<void>(
          '/contacts/redeem',
          extra: HousingMissingContactRedeemArgs(displayName: displayName),
        )
        .then((_) {
          if (!mounted) return;
          _reloadAfterContactsFlow();
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingPlanMissingContactsTitle)),
      body: FutureBuilder<List<PlanPeerContactRow>>(
        future: _rowsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.housingPlanMissingContactsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final allConnected = rows.every((r) => r.isConnected);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.housingPlanMissingContactsIntro,
                style: theme.textTheme.bodyMedium,
              ),
              if (allConnected) ...[
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.housingPlanMissingContactsAllReady,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final row in rows) ...[
                _PeerRow(
                  displayName: row.participant.displayName,
                  isConnected: row.isConnected,
                  onCreateInvitation: _openGenerateInvitation,
                  onEnterCode: () =>
                      _openRedeemInvitation(row.participant.displayName),
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({
    required this.displayName,
    required this.isConnected,
    required this.onCreateInvitation,
    required this.onEnterCode,
    required this.l10n,
  });

  final String displayName;
  final bool isConnected;
  final VoidCallback onCreateInvitation;
  final VoidCallback onEnterCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isConnected
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${isConnected ? '✓' : '✗'} $displayName',
          style: theme.textTheme.titleMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!isConnected) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onCreateInvitation,
                child: Text(l10n.housingPlanMissingContactsCreateInvitation),
              ),
              OutlinedButton(
                onPressed: onEnterCode,
                child: Text(l10n.housingPlanMissingContactsEnterCode),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
