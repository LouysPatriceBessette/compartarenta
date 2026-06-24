import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_hub_gates.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hub gates keep amendment enabled during voluntary withdrawal pending', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'housing:withdraw';
    const selfId = 'housing:withdraw:self';
    const pkgId = 'pkg:2';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Self',
        avatarId: 'a',
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: pkgId,
        planId: planId,
        activeRevisionId: const drift.Value('rev:2'),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agr:withdraw',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        minNoticeDays: const drift.Value(0),
        penaltyMinor: const drift.Value(0),
        clauses: const drift.Value(''),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        agreementRulesJson: const drift.Value('{}'),
        version: const drift.Value(1),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: 'pc:2',
        planId: planId,
        packageId: pkgId,
        kind: HousingParticipationChangeKind.voluntaryWithdrawal.wireValue,
        initiatorParticipantId: selfId,
        targetParticipantId: const drift.Value(selfId),
        departureDate: drift.Value(DateTime.utc(2026, 12, 1)),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026),
      ),
    );
    await HousingParticipationMembershipService(db).ensureMembershipsForPlan(planId);

    final result = await HousingParticipationHubGates.compute(
      db: db,
      planId: planId,
      selfParticipantId: selfId,
      ejectionCandidateSubtitle: 'ejection pending',
      bannerTextBuilder:
          ({
            required String initiatorName,
            required String? targetName,
            required DateTime? departureDate,
          }) => 'banner',
    );

    expect(result.gates.requestAmendmentEnabled, isTrue);
    expect(result.gates.majorChangeEnabled, isFalse);
  });

  test('hub gates show ejection banner for the named candidate', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'housing:eject-candidate';
    const selfId = 'housing:eject-candidate:self';
    const pkgId = 'pkg:3';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: selfId,
        displayName: 'Roberr',
        avatarId: 'a',
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.upsertParticipant(
      ParticipantsCompanion.insert(
        id: 'housing:eject-candidate:p1',
        displayName: 'Louys',
        avatarId: 'b',
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: pkgId,
        planId: planId,
        activeRevisionId: const drift.Value('rev:3'),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agr:eject',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        minNoticeDays: const drift.Value(0),
        penaltyMinor: const drift.Value(0),
        clauses: const drift.Value(''),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        agreementRulesJson: const drift.Value('{}'),
        version: const drift.Value(1),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.housingParticipationChanges).insert(
      HousingParticipationChangesCompanion.insert(
        id: 'pc:3',
        planId: planId,
        packageId: pkgId,
        kind: HousingParticipationChangeKind.ejection.wireValue,
        initiatorParticipantId: 'housing:eject-candidate:p1',
        targetParticipantId: const drift.Value(selfId),
        status: HousingParticipationChangeStatus.pending.wireValue,
        createdAt: DateTime.utc(2026),
      ),
    );
    await HousingParticipationMembershipService(db).ensureMembershipsForPlan(planId);

    final result = await HousingParticipationHubGates.compute(
      db: db,
      planId: planId,
      selfParticipantId: selfId,
      ejectionCandidateSubtitle: 'ejection pending',
      bannerTextBuilder:
          ({
            required String initiatorName,
            required String? targetName,
            required DateTime? departureDate,
          }) => '$initiatorName ejects $targetName',
    );
    final gates = result.gates;

    expect(gates.isEjectionCandidate, isTrue);
    expect(gates.showParticipationBanner, isTrue);
    expect(gates.participationBannerText, 'Louys ejects Roberr');
    expect(gates.enterExpenseEnabled, isFalse);
    expect(gates.requestAmendmentEnabled, isFalse);
    expect(gates.majorChangeEnabled, isFalse);
    expect(gates.majorChangeSubtitle, 'ejection pending');
  });
}
