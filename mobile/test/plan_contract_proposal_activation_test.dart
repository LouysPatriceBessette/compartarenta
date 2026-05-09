import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/proposals/plan_contract_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('partial acceptance does not activate a pending revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanContractProposalService(db);

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
    await db.upsertContract(
      AgreementContractsCompanion.insert(
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
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );

    final rev = await svc.createRevisionFromCurrentDraft(
      planId: 'p1',
      proposerParticipantId: 'u1',
    );

    // Only u1 accepted (u2 is missing => not unanimous).
    final activated = await svc.tryActivateIfUnanimous(
      planId: 'p1',
      revisionId: rev,
      participantIds: const ['u1', 'u2'],
    );
    expect(activated, isFalse);

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals('p1')))
        .getSingle();
    expect(pkg.activeRevisionId, isNull);
    expect(pkg.pendingRevisionId, rev);

    await db.close();
  });

  test('unanimous acceptance activates the revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final svc = PlanContractProposalService(db);

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
    await db.upsertContract(
      AgreementContractsCompanion.insert(
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

    final activated = await svc.tryActivateIfUnanimous(
      planId: 'p1',
      revisionId: rev,
      participantIds: const ['u1', 'u2'],
    );
    expect(activated, isTrue);

    final pkg = await (db.select(db.proposalPackages)
          ..where((t) => t.planId.equals('p1')))
        .getSingle();
    expect(pkg.activeRevisionId, rev);

    await db.close();
  });
}

