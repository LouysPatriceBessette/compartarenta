import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/app_database.dart';
import '../../housing/housing_plan_peer_contacts.dart';
import '../../l10n/app_localizations.dart';
import '../../prefs/app_preferences.dart';
import '../../util/display_date.dart';
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
  AppPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _rowsFuture = _loadRows();
    AppPreferences.load().then((prefs) {
      if (!mounted) return;
      setState(() => _prefs = prefs);
    });
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
    setState(() {
      _rowsFuture = _loadRows();
    });
  }

  Future<List<PlanPeerContactRow>> _loadRows() {
    return listPlanPeerContactRows(db: widget.db, planId: widget.planId);
  }

  void _reloadRows() {
    setState(() {
      _rowsFuture = _loadRows();
    });
  }

  Future<void> _establishContact(PlanPeerContactRow row) async {
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    try {
      await orch.sendPlanPeerEstablishmentRequest(
        planId: widget.planId,
        participantId: row.participant.id,
      );
      if (!mounted) return;
      _reloadRows();
    } on HandshakeOrchestratorError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code)),
      );
    }
  }

  Future<void> _respondInbound({
    required PlanPeerContactRow row,
    required bool accepted,
  }) async {
    final establishmentId = row.establishmentId;
    if (establishmentId == null) return;
    final orch = HandshakeOrchestrator.maybeInstance;
    if (orch == null) return;
    await orch.respondPlanPeerEstablishmentRequest(
      establishmentId: establishmentId,
      accepted: accepted,
    );
    if (!mounted) return;
    _reloadRows();
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
                  row: row,
                  l10n: l10n,
                  refusedLabel: row.refusedAt == null
                      ? null
                      : l10n.housingPlanMissingContactsRefusedAt(
                          _formatRefusedAt(row.refusedAt!),
                        ),
                  onEstablishContact: () => _establishContact(row),
                  onAcceptInbound: () =>
                      _respondInbound(row: row, accepted: true),
                  onRefuseInbound: () =>
                      _respondInbound(row: row, accepted: false),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatRefusedAt(DateTime refusedAt) {
    final prefs = _prefs;
    if (prefs == null) {
      return DateFormat.yMMMd().add_Hm().format(refusedAt.toLocal());
    }
    return DateFormat(
      '${effectiveDateFormat(prefs)} HH:mm',
    ).format(refusedAt.toLocal());
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({
    required this.row,
    required this.l10n,
    required this.refusedLabel,
    required this.onEstablishContact,
    required this.onAcceptInbound,
    required this.onRefuseInbound,
  });

  final PlanPeerContactRow row;
  final AppLocalizations l10n;
  final String? refusedLabel;
  final VoidCallback onEstablishContact;
  final VoidCallback onAcceptInbound;
  final VoidCallback onRefuseInbound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = row.participant.displayName;
    final isConnected = row.isConnected;
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
        if (!isConnected && row.outboundPending) ...[
          const SizedBox(height: 4),
          Text(
            l10n.housingPlanMissingContactsPendingOutbound,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
        if (!isConnected && refusedLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            refusedLabel!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (!isConnected && row.inboundPending) ...[
          const SizedBox(height: 8),
          Text(
            l10n.housingPlanMissingContactsInboundPrompt(
              row.inboundRequesterDisplayName ?? displayName,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onAcceptInbound,
                child: Text(l10n.housingPlanMissingContactsAccept),
              ),
              OutlinedButton(
                onPressed: onRefuseInbound,
                child: Text(l10n.housingPlanMissingContactsRefuse),
              ),
            ],
          ),
        ] else if (!isConnected &&
            !row.outboundPending &&
            row.establishmentId != null) ...[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onEstablishContact,
            child: Text(l10n.housingPlanMissingContactsEstablishContact),
          ),
        ],
      ],
    );
  }
}
