import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedTwoParticipantPlan(AppDatabase db, String planId) async {
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
}

void main() {
  test('listArchivesForPlan omits the in-force active revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:test';

    await _seedTwoParticipantPlan(db, planId);
    final svc = PlanAgreementProposalService(db);
    final revisionId = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await svc.recordResponse(
      revisionId: revisionId,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: revisionId,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final archives =
        await HousingProposalTransportService(db).listArchivesForPlan(planId);

    expect(archives, isEmpty);
  });

  test('hasActiveRevision is false after a rejected proposal', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:test';

    await _seedTwoParticipantPlan(db, planId);
    final svc = PlanAgreementProposalService(db);
    final revisionId = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await HousingProposalTransportService(db).archiveInvalidatedProposal(
      planId: planId,
      revisionId: revisionId,
      status: ProposalResponseStatus.rejected,
      responderParticipantId: '$planId:p0',
    );

    expect(
      await HousingProposalTransportService(db).hasActiveRevision(planId),
      isFalse,
    );
  });

  test('listArchivesForPlan keeps a rejected archived revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:test';

    await _seedTwoParticipantPlan(db, planId);
    final svc = PlanAgreementProposalService(db);
    final revisionId = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await HousingProposalTransportService(db).archiveInvalidatedProposal(
      planId: planId,
      revisionId: revisionId,
      status: ProposalResponseStatus.rejected,
      responderParticipantId: '$planId:p0',
    );

    final archives =
        await HousingProposalTransportService(db).listArchivesForPlan(planId);

    expect(archives, hasLength(1));
    expect(archives.single.status, ProposalResponseStatus.rejected);
  });
}
