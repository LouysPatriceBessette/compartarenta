import 'dart:convert';

import 'package:drift/drift.dart' as drift;

import '../../db/app_database.dart';
import 'plan_agreement_proposal_service.dart';

class ReceivedHousingProposalImport {
  const ReceivedHousingProposalImport({
    required this.planId,
    required this.revisionId,
  });

  final String planId;
  final String revisionId;
}

class HousingProposalTransportService {
  HousingProposalTransportService(this._db);

  final AppDatabase _db;

  Future<String> exportProposalForParticipant({
    required String planId,
    required String revisionId,
    required String targetParticipantId,
  }) async {
    final payload = await PlanAgreementProposalService(
      _db,
    ).loadRevisionPayload(revisionId);
    final participants = await _participantsForPlan(planId);
    final enriched = Map<String, Object?>.from(payload)
      ..['targetParticipantId'] = targetParticipantId
      ..['participantSnapshots'] = [
        for (final p in participants)
          {
            'id': p.id,
            'displayName': p.displayName,
            'avatarId': p.avatarId,
            if (p.contactId != null) 'contactId': p.contactId,
          },
      ];
    return jsonEncode(enriched);
  }

  Future<ReceivedHousingProposalImport> importReceivedProposal({
    required String proposalJson,
    required String targetParticipantId,
    required String senderContactId,
    required String senderDisplayName,
    required String senderAvatarId,
  }) async {
    final payload = jsonDecode(proposalJson) as Map<String, dynamic>;
    final sourcePackageId = _string(
      payload['packageId'],
      fallback: 'pkg:unknown',
    );
    final sourceRevisionId = _string(
      payload['revisionId'],
      fallback: 'rev:${DateTime.now().toUtc().microsecondsSinceEpoch}',
    );
    final receivedPlanId = 'received:${_token(sourcePackageId)}';
    final receivedPackageId = 'pkg:$receivedPlanId';
    final receivedRevisionId =
        'rev:$receivedPlanId:${_token(sourceRevisionId)}';
    final createdAt = _date(payload['createdAt']) ?? DateTime.now().toUtc();

    final sourceToLocalParticipant = _participantIdMap(
      payload: payload,
      targetParticipantId: targetParticipantId,
    );
    final importedPayload = _remapPayload(
      payload,
      receivedPlanId: receivedPlanId,
      sourceToLocalParticipant: sourceToLocalParticipant,
      receivedPackageId: receivedPackageId,
      receivedRevisionId: receivedRevisionId,
    );

    await _deleteReceivedPlanData(receivedPlanId);
    await _upsertPlan(receivedPlanId, payload, createdAt);
    await _upsertParticipants(
      receivedPlanId: receivedPlanId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      senderContactId: senderContactId,
      senderDisplayName: senderDisplayName,
      senderAvatarId: senderAvatarId,
      createdAt: createdAt,
    );
    await _upsertGroups(receivedPlanId, payload, createdAt);
    await _upsertLines(receivedPlanId, payload, createdAt);
    await _upsertRatios(
      receivedPlanId: receivedPlanId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      createdAt: createdAt,
    );
    await _upsertAgreement(receivedPlanId, payload, createdAt);
    await _db
        .into(_db.proposalPackages)
        .insertOnConflictUpdate(
          ProposalPackagesCompanion.insert(
            id: receivedPackageId,
            planId: receivedPlanId,
            pendingRevisionId: drift.Value(receivedRevisionId),
            createdAt: createdAt,
          ),
        );
    await _db
        .into(_db.proposalRevisions)
        .insertOnConflictUpdate(
          ProposalRevisionsCompanion.insert(
            id: receivedRevisionId,
            packageId: receivedPackageId,
            contentHash: _string(
              payload['contentHash'],
              fallback: 'received:$receivedRevisionId',
            ),
            proposerParticipantId:
                '$receivedPlanId:${sourceToLocalParticipant[_string(payload['proposerParticipantId'])] ?? 'p0'}',
            payloadJson: jsonEncode(importedPayload),
            createdAt: createdAt,
          ),
        );
    await _upsertResponses(
      receivedPlanId: receivedPlanId,
      revisionId: receivedRevisionId,
      payload: payload,
      sourceToLocalParticipant: sourceToLocalParticipant,
      createdAt: createdAt,
    );

    return ReceivedHousingProposalImport(
      planId: receivedPlanId,
      revisionId: receivedRevisionId,
    );
  }

  Future<List<Participant>> _participantsForPlan(String planId) async {
    final rows = await _db.listParticipants();
    return rows
        .where((p) => p.id == '$planId:self' || p.id.startsWith('$planId:p'))
        .toList(growable: false);
  }

  Future<void> _deleteReceivedPlanData(String planId) async {
    final pkgs = await (_db.select(
      _db.proposalPackages,
    )..where((t) => t.planId.equals(planId))).get();
    for (final pkg in pkgs) {
      final revs = await (_db.select(
        _db.proposalRevisions,
      )..where((t) => t.packageId.equals(pkg.id))).get();
      for (final rev in revs) {
        await (_db.delete(
          _db.proposalResponses,
        )..where((t) => t.revisionId.equals(rev.id))).go();
      }
      await (_db.delete(
        _db.proposalRevisions,
      )..where((t) => t.packageId.equals(pkg.id))).go();
      await (_db.delete(
        _db.proposalPackages,
      )..where((t) => t.id.equals(pkg.id))).go();
    }
    await (_db.delete(
      _db.planRatios,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.planLines,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.agreements,
    )..where((t) => t.planId.equals(planId))).go();
    await (_db.delete(
      _db.planGroups,
    )..where((t) => t.planId.equals(planId))).go();
    final participants = await _db.listParticipants();
    for (final p in participants) {
      if (p.id == '$planId:self' || p.id.startsWith('$planId:p')) {
        await (_db.delete(
          _db.participants,
        )..where((t) => t.id.equals(p.id))).go();
      }
    }
  }

  Map<String, String> _participantIdMap({
    required Map<String, dynamic> payload,
    required String targetParticipantId,
  }) {
    final sourceIds = <String>[];
    void add(String value) {
      if (value.isNotEmpty && !sourceIds.contains(value)) sourceIds.add(value);
    }

    add(targetParticipantId);
    add(_string(payload['proposerParticipantId']));
    final snapshots = payload['participantSnapshots'];
    if (snapshots is List) {
      for (final item in snapshots) {
        if (item is Map) add(_string(item['id']));
      }
    }
    final plan = payload['plan'];
    if (plan is Map) {
      final ratios = plan['ratios'];
      if (ratios is List) {
        for (final item in ratios) {
          if (item is Map) add(_string(item['participantId']));
        }
      }
    }

    final out = <String, String>{};
    if (targetParticipantId.isNotEmpty) out[targetParticipantId] = 'self';
    var n = 0;
    for (final id in sourceIds) {
      out.putIfAbsent(id, () => 'p${n++}');
    }
    return out;
  }

  Map<String, Object?> _remapPayload(
    Map<String, dynamic> payload, {
    required String receivedPlanId,
    required Map<String, String> sourceToLocalParticipant,
    required String receivedPackageId,
    required String receivedRevisionId,
  }) {
    final copy = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    copy['packageId'] = receivedPackageId;
    copy['revisionId'] = receivedRevisionId;
    final proposer = _string(copy['proposerParticipantId']);
    if (sourceToLocalParticipant.containsKey(proposer)) {
      copy['proposerParticipantId'] =
          '$receivedPlanId:${sourceToLocalParticipant[proposer]}';
    }
    final plan = copy['plan'];
    if (plan is Map) {
      final ratios = plan['ratios'];
      if (ratios is List) {
        for (final item in ratios) {
          if (item is Map) {
            final id = _string(item['participantId']);
            final localTail = sourceToLocalParticipant[id];
            item['participantId'] = localTail == null
                ? id
                : '$receivedPlanId:$localTail';
          }
        }
      }
    }
    return copy;
  }

  Future<void> _upsertPlan(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final plan = _map(payload['plan']);
    await _db.upsertPlan(
      PlansCompanion.insert(
        id: receivedPlanId,
        type: _string(plan['type'], fallback: 'housing'),
        title: drift.Value(_string(plan['title'], fallback: receivedPlanId)),
        currency: drift.Value(_string(plan['defaultCurrency'])),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> _upsertParticipants({
    required String receivedPlanId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required String senderContactId,
    required String senderDisplayName,
    required String senderAvatarId,
    required DateTime createdAt,
  }) async {
    final snapshots = <String, Map>{};
    final raw = payload['participantSnapshots'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) snapshots[_string(item['id'])] = item;
      }
    }
    for (final entry in sourceToLocalParticipant.entries) {
      final sourceId = entry.key;
      final localTail = entry.value;
      final snap = snapshots[sourceId];
      final isProposer = sourceId == _string(payload['proposerParticipantId']);
      await _db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: '$receivedPlanId:$localTail',
          displayName: isProposer
              ? senderDisplayName
              : _string(snap?['displayName'], fallback: sourceId),
          avatarId: isProposer
              ? senderAvatarId
              : _string(snap?['avatarId'], fallback: 'a01'),
          contactId: isProposer
              ? drift.Value(senderContactId)
              : const drift.Value.absent(),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertGroups(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final groups = _list(_map(payload['plan'])['groups']);
    for (final group in groups.whereType<Map>()) {
      final sourceId = _string(group['id']);
      await _db.upsertPlanGroup(
        PlanGroupsCompanion.insert(
          id: '$receivedPlanId:grp:$sourceId',
          planId: receivedPlanId,
          title: _string(group['title'], fallback: sourceId),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertLines(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final lines = _list(_map(payload['plan'])['lines']);
    for (final line in lines.whereType<Map>()) {
      final sourceId = _string(line['id']);
      final sourceGroupId = _string(line['groupId']);
      await _db.upsertPlanLine(
        PlanLinesCompanion.insert(
          id: '$receivedPlanId:line:$sourceId',
          planId: receivedPlanId,
          isRecurring: _bool(line['isRecurring']),
          title: _string(line['title'], fallback: sourceId),
          currency: _string(line['currency']),
          amountUsesRange: drift.Value(_bool(line['amountUsesRange'])),
          amountMinor: _intValue(line['amountMinor']),
          minAmountMinor: _intValue(line['minAmountMinor']),
          maxAmountMinor: _intValue(line['maxAmountMinor']),
          description: drift.Value(_string(line['description'])),
          cadence: drift.Value(_string(line['cadence'], fallback: 'monthly')),
          recurrenceDayOfMonth: _intValue(line['recurrenceDayOfMonth']),
          sortOrder: drift.Value(_int(line['sortOrder'])),
          groupId: sourceGroupId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:grp:$sourceGroupId'),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertRatios({
    required String receivedPlanId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required DateTime createdAt,
  }) async {
    final ratios = _list(_map(payload['plan'])['ratios']);
    for (final ratio in ratios.whereType<Map>()) {
      final participant =
          sourceToLocalParticipant[_string(ratio['participantId'])];
      if (participant == null) continue;
      final sourceLineId = _string(ratio['lineId']);
      final sourceGroupId = _string(ratio['groupId']);
      await _db.upsertPlanRatio(
        PlanRatiosCompanion.insert(
          id: 'ratio:$receivedPlanId:${sourceLineId.isEmpty ? 'grp:$sourceGroupId' : sourceLineId}:$participant',
          planId: receivedPlanId,
          participantId: '$receivedPlanId:$participant',
          lineId: sourceLineId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:line:$sourceLineId'),
          groupId: sourceGroupId.isEmpty
              ? const drift.Value.absent()
              : drift.Value('$receivedPlanId:grp:$sourceGroupId'),
          weight: _int(ratio['weight']),
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> _upsertAgreement(
    String receivedPlanId,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) async {
    final agreement = _map(payload['agreement']);
    await _db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$receivedPlanId',
        planId: receivedPlanId,
        periodStart: _date(agreement['periodStart']) ?? createdAt,
        periodEnd:
            _date(agreement['periodEnd']) ??
            createdAt.add(const Duration(days: 30)),
        minNoticeDays: drift.Value(_int(agreement['minNoticeDays'])),
        penaltyMinor: drift.Value(
          _int(_map(agreement['penalty'])['amountMinor']),
        ),
        clauses: drift.Value(_string(agreement['clauses'])),
        withdrawalSameForAll: drift.Value(
          _string(agreement['withdrawalSameForAll'], fallback: 'true'),
        ),
        withdrawalPerParticipantJson: drift.Value(
          _string(agreement['withdrawalPerParticipantJson'], fallback: '{}'),
        ),
        createdAt: createdAt,
        version: drift.Value(_int(agreement['version'], fallback: 1)),
      ),
    );
  }

  Future<void> _upsertResponses({
    required String receivedPlanId,
    required String revisionId,
    required Map<String, dynamic> payload,
    required Map<String, String> sourceToLocalParticipant,
    required DateTime createdAt,
  }) async {
    final proposer =
        sourceToLocalParticipant[_string(payload['proposerParticipantId'])];
    for (final localTail in sourceToLocalParticipant.values) {
      final fullParticipantId = '$receivedPlanId:$localTail';
      final accepted = localTail == proposer;
      await _db
          .into(_db.proposalResponses)
          .insertOnConflictUpdate(
            ProposalResponsesCompanion.insert(
              id: 'resp:$revisionId:$fullParticipantId',
              revisionId: revisionId,
              participantId: fullParticipantId,
              status: accepted
                  ? ProposalResponseStatus.accepted.name
                  : ProposalResponseStatus.pending.name,
              respondedAt: accepted
                  ? drift.Value(createdAt)
                  : const drift.Value.absent(),
            ),
          );
    }
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  List<Object?> _list(Object? value) =>
      value is List ? value.cast<Object?>() : const <Object?>[];

  String _string(Object? value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  drift.Value<int?> _intValue(Object? value) {
    if (value == null) return const drift.Value.absent();
    return drift.Value(_int(value));
  }

  bool _bool(Object? value) => value == true || value.toString() == 'true';

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _token(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
