import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/proposals/housing_agreement_overlap_withdrawal_exception.dart';
import 'package:compartarenta/housing/proposals/housing_agreement_period_conflict.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _dbWithActiveAndIncomingPlans() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  const activePlanId = 'plan:active';
  const incomingPlanId = 'plan:incoming';

  for (final planId in [activePlanId, incomingPlanId]) {
    await db.upsertPlan(
      PlansCompanion.insert(
        id: planId,
        type: 'housing',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$planId:self',
        displayName: 'Self',
        avatarId: 'a01',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }
  for (final suffix in ['p1', 'p2']) {
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: '$activePlanId:$suffix',
        displayName: suffix,
        avatarId: 'a01',
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  }

    await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agr:$activePlanId',
      planId: activePlanId,
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: DateTime.utc(2027, 12, 31),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.upsertAgreement(
    AgreementsCompanion.insert(
      id: 'agr:$incomingPlanId',
      planId: incomingPlanId,
      periodStart: DateTime.utc(2027, 6, 1),
      periodEnd: DateTime.utc(2028, 5, 31),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );

  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$activePlanId',
      planId: activePlanId,
      activeRevisionId: const drift.Value('rev:active:1'),
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalRevisions).insert(
    ProposalRevisionsCompanion.insert(
      id: 'rev:active:1',
      packageId: 'pkg:$activePlanId',
      contentHash: 'hash:active',
      proposerParticipantId: '$activePlanId:self',
      payloadJson: '{"lifecycleState":"archived"}',
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
  await db.into(db.proposalPackages).insert(
    ProposalPackagesCompanion.insert(
      id: 'pkg:$incomingPlanId',
      planId: incomingPlanId,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );

  return db;
}

void main() {
  test('overlap cleared when voluntary withdrawal departs on or before new start',
      () async {
    final db = await _dbWithActiveAndIncomingPlans();
    addTearDown(db.close);

    const activePlanId = 'plan:active';
    const incomingPlanId = 'plan:incoming';

    await HousingParticipationChangeService(db).proposeVoluntaryWithdrawal(
      planId: activePlanId,
      initiatorParticipantId: '$activePlanId:self',
      departureDate: DateTime.utc(2027, 6, 1),
    );

    final conflict = await findFirstAgreementPeriodConflict(
      db: db,
      excludePlanId: incomingPlanId,
      candidateStart: DateTime.utc(2027, 6, 1),
      candidateEnd: DateTime.utc(2028, 5, 31),
    );
    expect(conflict, isNull);

    expect(
      await qualifyingVoluntaryWithdrawalClearsOverlap(
        db: db,
        conflictingPlanId: activePlanId,
        candidatePeriodStart: DateTime.utc(2027, 6, 1),
      ),
      isTrue,
    );
    expect(
      HousingParticipationChangeKind.voluntaryWithdrawal,
      HousingParticipationChangeKind.fromWire(
        (await HousingParticipationChangeService(db)
                .pendingForPlan(activePlanId))!
            .kind,
      ),
    );
  });
}
