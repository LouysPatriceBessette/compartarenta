import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('partial acceptance does not activate a pending revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanAgreementProposalService(db);

    // Seed participants (2).
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'u1',
        displayName: 'U1',
        avatarId: 'a1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'u2',
        displayName: 'U2',
        avatarId: 'a2',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    // Seed plan + contract + one line.
    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'p1',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: drift.Value('Plan'),
        currency: drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'c1',
        planId: 'p1',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 2, 1),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'l1',
        planId: 'p1',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: drift.Value(1000),
        recurrenceDayOfMonth: const drift.Value(1),
        sortOrder: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final rev = await svc.createRevisionFromCurrentDraft(
      planId: 'p1',
      proposerParticipantId: 'u1',
    );

    // Only u1 accepted (u2 is missing => not unanimous).
    final outcome = await svc.tryActivateIfUnanimous(
      planId: 'p1',
      revisionId: rev,
      participantIds: const ['u1', 'u2'],
    );
    expect(outcome, ProposalActivationOutcome.notUnanimous);

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals('p1')))
        .getSingle();
    expect(pkg.activeRevisionId, isNull);
    expect(pkg.pendingRevisionId, rev);

    await db.close();
  });

  test('unanimous acceptance activates the revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanAgreementProposalService(db);

    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'u1',
        displayName: 'U1',
        avatarId: 'a1',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'u2',
        displayName: 'U2',
        avatarId: 'a2',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'p1',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: drift.Value('Plan'),
        currency: drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'c1',
        planId: 'p1',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 2, 1),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'l1',
        planId: 'p1',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: drift.Value(1000),
        recurrenceDayOfMonth: const drift.Value(1),
        sortOrder: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final rev = await svc.createRevisionFromCurrentDraft(
      planId: 'p1',
      proposerParticipantId: 'u1',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: 'u2',
      status: ProposalResponseStatus.accepted,
    );

    final outcome = await svc.tryActivateIfUnanimous(
      planId: 'p1',
      revisionId: rev,
      participantIds: const ['u1', 'u2'],
    );
    expect(outcome, ProposalActivationOutcome.activated);

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals('p1')))
        .getSingle();
    expect(pkg.activeRevisionId, rev);

    await db.close();
  });

  test('unanimous activation blocked when agreement overlaps another housing plan by day rule',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanAgreementProposalService(db);

    Future<void> seedParticipant(String id) async {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: id,
          displayName: id,
          avatarId: 'a1',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }

    await seedParticipant('ov-a:self');
    await seedParticipant('ov-a:p0');

    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'ov-a',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('A'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:ov-a',
        planId: 'ov-a',
        periodStart: DateTime.utc(2026, 6, 1),
        periodEnd: DateTime.utc(2026, 6, 30),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'ov-a:l1',
        planId: 'ov-a',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: drift.Value(1000),
        recurrenceDayOfMonth: const drift.Value(1),
        sortOrder: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await seedParticipant('ov-b:self');
    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'ov-b',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('B'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:ov-b',
        planId: 'ov-b',
        periodStart: DateTime.utc(2026, 6, 10),
        periodEnd: DateTime.utc(2026, 6, 20),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:ov-b',
            planId: 'ov-b',
            createdAt: DateTime.utc(2026, 1, 1),
            activeRevisionId: const drift.Value('rev:ov-b'),
            pendingRevisionId: const drift.Value.absent(),
          ),
        );

    final rev = await svc.createRevisionFromCurrentDraft(
      planId: 'ov-a',
      proposerParticipantId: 'ov-a:self',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: 'ov-a:p0',
      status: ProposalResponseStatus.accepted,
    );

    final outcome = await svc.tryActivateIfUnanimous(
      planId: 'ov-a',
      revisionId: rev,
      participantIds: const ['ov-a:self', 'ov-a:p0'],
    );
    expect(outcome, ProposalActivationOutcome.blockedByOverlappingAgreementPeriod);

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals('ov-a')))
        .getSingle();
    expect(pkg.activeRevisionId, isNull);
    expect(pkg.pendingRevisionId, rev);

    await db.close();
  });

  test('unanimous activation allowed when only one calendar day is shared with other plan',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanAgreementProposalService(db);

    Future<void> seedParticipant(String id) async {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: id,
          displayName: id,
          avatarId: 'a1',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }

    await seedParticipant('edge-a:self');
    await seedParticipant('edge-a:p0');

    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'edge-a',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('A'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:edge-a',
        planId: 'edge-a',
        periodStart: DateTime.utc(2026, 6, 1),
        periodEnd: DateTime.utc(2026, 6, 30),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'edge-a:l1',
        planId: 'edge-a',
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: drift.Value(1000),
        recurrenceDayOfMonth: const drift.Value(1),
        sortOrder: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await seedParticipant('edge-b:self');
    await db.upsertPlan(
      PlansCompanion.insert(
        id: 'edge-b',
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
        title: const drift.Value('B'),
        currency: const drift.Value('CAD'),
        notes: const drift.Value.absent(),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:edge-b',
        planId: 'edge-b',
        periodStart: DateTime.utc(2026, 6, 30),
        periodEnd: DateTime.utc(2026, 7, 31),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(0),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:edge-b',
            planId: 'edge-b',
            createdAt: DateTime.utc(2026, 1, 1),
            activeRevisionId: const drift.Value('rev:edge-b'),
            pendingRevisionId: const drift.Value.absent(),
          ),
        );

    final rev = await svc.createRevisionFromCurrentDraft(
      planId: 'edge-a',
      proposerParticipantId: 'edge-a:self',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: 'edge-a:p0',
      status: ProposalResponseStatus.accepted,
    );

    final outcome = await svc.tryActivateIfUnanimous(
      planId: 'edge-a',
      revisionId: rev,
      participantIds: const ['edge-a:self', 'edge-a:p0'],
    );
    expect(outcome, ProposalActivationOutcome.activated);

    await db.close();
  });
}

