import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../../db/app_database.dart';
import '../realized_expense/realized_expense_participants.dart';
import 'housing_participation_change_kind.dart';
import 'housing_participation_change_service.dart';
import 'housing_participation_membership_service.dart';

/// Steady-state JSON sync for participation change (client-only relay kinds).
class HousingParticipationChangeSyncService {
  HousingParticipationChangeSyncService(this._db);

  final AppDatabase _db;

  Future<String> buildProposeJson(HousingParticipationChange change) async {
    final roster = await participantsForPlan(_db, change.planId);
    return jsonEncode({
      'change_id': change.id,
      'package_id': change.packageId,
      'plan_id': change.planId,
      'kind': change.kind,
      'initiator_participant_id': change.initiatorParticipantId,
      if (change.targetParticipantId != null)
        'target_participant_id': change.targetParticipantId,
      if (change.departureDate != null)
        'departure_date': change.departureDate!.toUtc().toIso8601String(),
      'status': change.status,
      'created_at': change.createdAt.toUtc().toIso8601String(),
      'participant_snapshots': [
        for (final p in roster)
          {
            'id': p.id,
            'displayName': p.displayName,
            if (p.contactId != null) 'contactId': p.contactId,
          },
      ],
    });
  }

  Future<String> buildDecisionJson({
    required String changeId,
    required String participantId,
    required String status,
  }) async {
    return jsonEncode({
      'change_id': changeId,
      'participant_id': participantId,
      'status': status,
      'decided_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String> buildNotifyJson(HousingParticipationChange change) async {
    return buildProposeJson(change);
  }

  Future<bool> importProposeFromPeer({
    required String changeJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(changeJson) as Map<String, dynamic>;
    final changeId = payload['change_id'] as String? ?? '';
    if (changeId.isEmpty) return false;

    final existing = await (_db.select(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingleOrNull();
    if (existing != null) return false;

    final planId = payload['plan_id'] as String? ?? '';
    if (planId.isEmpty) return false;

    await HousingParticipationMembershipService(_db).ensureMembershipsForPlan(
      planId,
    );

    await _db.into(_db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: changeId,
        planId: planId,
        packageId: payload['package_id'] as String? ?? '',
        kind: payload['kind'] as String? ?? '',
        initiatorParticipantId:
            payload['initiator_participant_id'] as String? ?? '',
        targetParticipantId: drift.Value(
          payload['target_participant_id'] as String?,
        ),
        departureDate: drift.Value(_parseDate(payload['departure_date'])),
        status:
            payload['status'] as String? ??
            HousingParticipationChangeStatus.pending.wireValue,
        createdAt:
            _parseDate(payload['created_at']) ?? DateTime.now().toUtc(),
      ),
    );

    final kind = HousingParticipationChangeKind.fromWire(
      payload['kind'] as String?,
    );
    if (kind?.requiresUnanimousVote == true) {
      final initiator = payload['initiator_participant_id'] as String? ?? '';
      if (initiator.isNotEmpty) {
        await _db.into(_db.housingParticipationDecisions).insertOnConflictUpdate(
          HousingParticipationDecisionsCompanion.insert(
            changeId: changeId,
            participantId: initiator,
            status: HousingParticipationDecisionStatus.accepted.wireValue,
            decidedAt: drift.Value(DateTime.now().toUtc()),
          ),
        );
      }
    }

    _log('imported propose $changeId from $senderContactId');
    return true;
  }

  Future<bool> importDecisionFromPeer({
    required String decisionJson,
    required String senderContactId,
  }) async {
    final payload = jsonDecode(decisionJson) as Map<String, dynamic>;
    final changeId = payload['change_id'] as String? ?? '';
    final participantId = payload['participant_id'] as String? ?? '';
    final status = payload['status'] as String? ?? '';
    if (changeId.isEmpty || participantId.isEmpty || status.isEmpty) {
      return false;
    }

    final change = await (_db.select(_db.housingParticipationChanges)
          ..where((t) => t.id.equals(changeId)))
        .getSingleOrNull();
    if (change == null) return false;
    if (change.status != HousingParticipationChangeStatus.pending.wireValue) {
      return false;
    }

    await _db.into(_db.housingParticipationDecisions).insertOnConflictUpdate(
      HousingParticipationDecisionsCompanion.insert(
        changeId: changeId,
        participantId: participantId,
        status: status,
        decidedAt: drift.Value(
          _parseDate(payload['decided_at']) ?? DateTime.now().toUtc(),
        ),
      ),
    );

    await HousingParticipationChangeService(_db).recordDecision(
      changeId: changeId,
      participantId: participantId,
      accepted: status == HousingParticipationDecisionStatus.accepted.wireValue,
    );

    _log('imported decision on $changeId from $senderContactId');
    return true;
  }

  Future<bool> importNotifyFromPeer({
    required String notifyJson,
    required String senderContactId,
  }) async {
    return importProposeFromPeer(
      changeJson: notifyJson,
      senderContactId: senderContactId,
    );
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  void _log(String message) {
    debugPrint('housing_participation_change $message');
  }
}
