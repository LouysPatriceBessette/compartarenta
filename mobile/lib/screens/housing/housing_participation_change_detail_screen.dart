import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../housing/participation/housing_participation_change_kind.dart';
import '../../housing/participation/housing_participation_change_service.dart';
import '../../housing/realized_expense/realized_expense_participants.dart';
import '../../l10n/app_localizations.dart';
import '../../relay/handshake_orchestrator.dart';
import '../../util/display_date.dart';
import '../../prefs/app_preferences.dart';

/// Accept/refuse (voting flows) or read-only detail for a participation change.
class HousingParticipationChangeDetailScreen extends StatefulWidget {
  const HousingParticipationChangeDetailScreen({
    super.key,
    required this.changeId,
    required this.planId,
    required this.packageId,
    this.prefs,
  });

  final String changeId;
  final String planId;
  final String packageId;
  final AppPreferences? prefs;

  @override
  State<HousingParticipationChangeDetailScreen> createState() =>
      _HousingParticipationChangeDetailScreenState();
}

class _HousingParticipationChangeDetailScreenState
    extends State<HousingParticipationChangeDetailScreen> {
  bool _working = false;
  HousingParticipationChange? _change;
  List<HousingParticipationDecision> _decisions = const [];
  List<Participant> _roster = const [];
  String _selfId = '';
  AppPreferences? _prefs;

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

  Future<void> _load() async {
    final db = AppDatabase.processScope;
    final change =
        await HousingParticipationChangeService(db).getById(widget.changeId);
    if (!mounted) return;
    if (change == null) {
      Navigator.of(context).pop();
      return;
    }
    final decisions =
        await HousingParticipationChangeService(db).decisionsFor(change.id);
    final roster = await participantsForPlan(db, widget.planId);
    setState(() {
      _change = change;
      _decisions = decisions;
      _roster = roster;
      _selfId = selfParticipantIdForPlan(widget.planId);
    });
  }

  bool get _isReadOnly {
    final change = _change;
    if (change == null) return true;
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    return kind == HousingParticipationChangeKind.voluntaryWithdrawal;
  }

  bool get _selfAlreadyDecided {
    return _decisions.any((d) => d.participantId == _selfId);
  }

  Future<void> _respond(bool accepted) async {
    if (_working || _change == null) return;
    setState(() => _working = true);
    try {
      final orch = HandshakeOrchestrator.maybeInstance;
      if (orch != null) {
        await orch.sendParticipationChangeDecision(
          changeId: _change!.id,
          participantId: _selfId,
          accepted: accepted,
        );
      } else {
        await HousingParticipationChangeService(
          AppDatabase.processScope,
        ).recordDecision(
          changeId: _change!.id,
          participantId: _selfId,
          accepted: accepted,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final change = _change;
    if (change == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final kind = HousingParticipationChangeKind.fromWire(change.kind);
    final initiatorName = displayNameForParticipant(
      change.initiatorParticipantId,
      _roster,
    );
    final targetName =
        change.targetParticipantId == null
            ? null
            : displayNameForParticipant(change.targetParticipantId!, _roster);

    final bodyText = switch (kind) {
      HousingParticipationChangeKind.immediateTermination =>
        l10n.housingParticipationChangeDetailTerminationBody(initiatorName),
      HousingParticipationChangeKind.voluntaryWithdrawal =>
        l10n.housingParticipationChangeDetailWithdrawalBody(
          initiatorName,
          change.departureDate != null && _prefs != null
              ? formatPreferenceDate(
                  change.departureDate!.toLocal(),
                  effectiveDateFormat(_prefs!),
                )
              : '—',
        ),
      HousingParticipationChangeKind.ejection =>
        l10n.housingParticipationChangeDetailEjectionBody(
          initiatorName,
          targetName ?? '—',
        ),
      null => '',
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingParticipationChangeDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(bodyText),
          if (kind == HousingParticipationChangeKind.voluntaryWithdrawal) ...[
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: HousingParticipationChangeService(
                AppDatabase.processScope,
              ).shouldApplyEarlyWithdrawalPenalty(
                planId: widget.planId,
                participantId: change.initiatorParticipantId,
                departureDate: change.departureDate ?? DateTime.now(),
              ),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                final applies = snap.data == true;
                return Text(
                  applies
                      ? l10n.housingParticipationChangePenaltyApplies
                      : l10n.housingParticipationChangePenaltyDoesNotApply,
                );
              },
            ),
          ],
          if (!_isReadOnly && !_selfAlreadyDecided) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _working ? null : () => _respond(true),
              child: Text(l10n.housingParticipationChangeAccept),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _working ? null : () => _respond(false),
              child: Text(l10n.housingParticipationChangeReject),
            ),
          ],
        ],
      ),
    );
  }
}
