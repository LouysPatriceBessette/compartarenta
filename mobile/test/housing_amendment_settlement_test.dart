import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_settlement.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('archivedAmendmentWasAccepted treats activation archive as accepted', () {
    expect(
      archivedAmendmentWasAccepted({
        'lifecycleState': 'archived',
      }),
      isTrue,
    );
  });

  test('archivedAmendmentWasAccepted treats rejection as refused', () {
    expect(
      archivedAmendmentWasAccepted({
        'lifecycleState': 'archived',
        'invalidatedByStatus': 'rejected',
      }),
      isFalse,
    );
  });

  test('amendmentBaselineRevisionId prefers fork lineage', () {
    expect(
      amendmentBaselineRevisionId(
        revisionPayload: {'forkedFromRevisionId': 'rev:baseline'},
        revisionId: 'rev:new',
        packageActiveRevisionId: 'rev:new',
        isArchived: true,
      ),
      'rev:baseline',
    );
  });

  test('settledAmendmentActorParticipantId uses non-proposer on unanimous accept',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-actor-accept';
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Self',
        avatarId: 'a1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Peer',
        avatarId: 'a2',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('Home'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$planId',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final svc = PlanAgreementProposalService(db);
    final rev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: rev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final stored = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(rev)))
        .getSingle();
    final payload = jsonDecode(stored.payloadJson) as Map<String, dynamic>;

    final actorId = await settledAmendmentActorParticipantId(
      db: db,
      revisionId: rev,
      proposerParticipantId: '$planId:self',
      archivedPayload: payload,
    );
    expect(actorId, '$planId:p0');
    await db.close();
  });

  test('settledAmendmentActorParticipantId uses invalidated peer on reject',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-actor-reject';
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Self',
        avatarId: 'a1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:p0',
        displayName: 'Peer',
        avatarId: 'a2',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('Home'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$planId',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final svc = PlanAgreementProposalService(db);
    final rev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await HousingProposalTransportService(db).archiveInvalidatedProposal(
      planId: planId,
      revisionId: rev,
      status: ProposalResponseStatus.rejected,
      responderParticipantId: '$planId:p0',
    );

    final stored = await (db.select(db.proposalRevisions)
          ..where((t) => t.id.equals(rev)))
        .getSingle();
    final payload = jsonDecode(stored.payloadJson) as Map<String, dynamic>;

    final actorId = await settledAmendmentActorParticipantId(
      db: db,
      revisionId: rev,
      proposerParticipantId: '$planId:self',
      archivedPayload: payload,
    );
    expect(actorId, '$planId:p0');
    await db.close();
  });
}
