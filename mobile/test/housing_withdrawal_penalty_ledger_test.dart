import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/agreement_rules_json.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_kind.dart';
import 'package:compartarenta/housing/participation/housing_participation_change_service.dart';
import 'package:compartarenta/housing/participation/housing_participation_membership_service.dart';
import 'package:compartarenta/housing/participation/housing_withdrawal_penalty_ledger.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_balance.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applyPenaltyIfDue publishes negative split transfers owed by leaver', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const planId = 'housing:penalty';
    const pkgId = 'pkg:penalty';
    const changeId = 'pc:penalty';
    const leaverId = '$planId:p0';
    const remain1 = '$planId:p1';
    const remain2 = '$planId:self';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    for (final id in [leaverId, remain1, remain2]) {
      await db.upsertParticipant(
        ParticipantsCompanion.insert(
          id: id,
          displayName: id,
          avatarId: 'a',
          createdAt: DateTime.utc(2026),
        ),
      );
    }

    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: pkgId,
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: DateTime.utc(2026),
      ),
    );

    final rules = AgreementRulesDraft(earlyWithdrawalEnabled: true);
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$planId',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        clauses: const drift.Value(''),
        agreementRulesJson: drift.Value(rules.encode()),
        minNoticeDays: const drift.Value(30),
        penaltyMinor: const drift.Value(100000),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        createdAt: DateTime.utc(2026),
      ),
    );

    await db.upsertPlanLine(
      PlanLinesCompanion.insert(
        id: 'line:1',
        planId: planId,
        isRecurring: true,
        title: 'Rent',
        currency: 'CAD',
        amountMinor: const drift.Value(100000),
        recurrenceDayOfMonth: const drift.Value(1),
        sortOrder: const drift.Value(0),
        createdAt: DateTime.utc(2026),
      ),
    );

    final departure = DateTime.now().add(const Duration(days: 5));
    final ledger = HousingWithdrawalPenaltyLedger(db);
    await ledger.applyPenaltyIfDue(
      planId: planId,
      changeId: changeId,
      leaverParticipantId: leaverId,
      departureDate: departure,
      remainingParticipantIds: [remain1, remain2],
    );
    await ledger.applyPenaltyIfDue(
      planId: planId,
      changeId: changeId,
      leaverParticipantId: leaverId,
      departureDate: departure,
      remainingParticipantIds: [remain1, remain2],
    );

    final published = await (db.select(db.realizedExpenses)
          ..where((t) => t.planId.equals(planId))
          ..where((t) => t.status.equals(RealizedExpenseStatus.published)))
        .get();

    expect(published, hasLength(2));
    expect(
      published.every((e) => e.kind == RealizedExpenseKind.transfer),
      isTrue,
    );
    expect(
      published.every((e) => e.payerParticipantId == leaverId),
      isTrue,
    );
    expect(
      published.every((e) => e.amountMinor < 0),
      isTrue,
    );
    expect(
      published.map((e) => e.beneficiaryParticipantId).toSet(),
      {remain1, remain2},
    );
    expect(
      published.fold<int>(0, (sum, e) => sum + e.amountMinor.abs()),
      100000,
    );

    final balance = computeHousingBalanceData(
      publishedExpenses: published,
      planRatios: const [],
      participants: [
        HousingBalanceParticipant(
          participantId: leaverId,
          displayName: 'Leaver',
          letter: 'A',
          orderIndex: 0,
        ),
        HousingBalanceParticipant(
          participantId: remain1,
          displayName: 'R1',
          letter: 'B',
          orderIndex: 1,
        ),
        HousingBalanceParticipant(
          participantId: remain2,
          displayName: 'R2',
          letter: 'C',
          orderIndex: 2,
        ),
      ],
    );
    expect(
      balance.optimizedMode.edges.map(
        (e) => '${e.fromParticipantId}->${e.toParticipantId}:${e.amountMinor}',
      ),
      containsAll(['$leaverId->$remain1:50000', '$leaverId->$remain2:50000']),
    );
  });

  test('applyPenaltyIfDue skips when notice period satisfied', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const planId = 'housing:penalty:skip';
    const pkgId = 'pkg:penalty:skip';

    await db.upsertPlan(
      PlansCompanion.insert(id: planId, type: 'housing', createdAt: DateTime.utc(2026)),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: pkgId,
        planId: planId,
        activeRevisionId: const drift.Value('rev:1'),
        createdAt: DateTime.utc(2026),
      ),
    );

    final rules = AgreementRulesDraft(earlyWithdrawalEnabled: true);
    await db.upsertAgreement(
      AgreementsCompanion.insert(
        id: 'agreement:$planId',
        planId: planId,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        clauses: const drift.Value(''),
        agreementRulesJson: drift.Value(rules.encode()),
        minNoticeDays: const drift.Value(0),
        penaltyMinor: const drift.Value(5000),
        withdrawalSameForAll: const drift.Value('true'),
        withdrawalPerParticipantJson: const drift.Value('{}'),
        createdAt: DateTime.utc(2026),
      ),
    );

    final ledger = HousingWithdrawalPenaltyLedger(db);
    await ledger.applyPenaltyIfDue(
      planId: planId,
      changeId: 'pc:skip',
      leaverParticipantId: '$planId:p0',
      departureDate: DateTime.now().toUtc().add(const Duration(days: 60)),
      remainingParticipantIds: ['$planId:self'],
    );

    final count = await db.select(db.realizedExpenses).get();
    expect(count, isEmpty);
  });

  test(
    'voluntary withdrawal departure uses initiator even when target is remapped wrong',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const planId = 'housing:withdraw-leaver';
      const louysId = '$planId:louys';
      const monicaId = '$planId:self';
      const changeId = 'pc:withdraw-leaver';

      await db.upsertPlan(
        PlansCompanion.insert(
          id: planId,
          type: 'housing',
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );
      for (final entry in [
        (monicaId, 'Monica'),
        (louysId, 'Louys'),
        ('$planId:roberr', 'Roberr'),
      ]) {
        await db.upsertParticipant(
          ParticipantsCompanion.insert(
            id: entry.$1,
            displayName: entry.$2,
            avatarId: 'a',
            createdAt: DateTime.utc(2026, 6, 13),
          ),
        );
      }
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: 'pkg:$planId',
          planId: planId,
          activeRevisionId: const drift.Value('rev:1'),
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );

      await db.into(db.housingParticipationChanges).insert(
        HousingParticipationChangesCompanion.insert(
          id: changeId,
          planId: planId,
          packageId: 'pkg:$planId',
          kind: HousingParticipationChangeKind.voluntaryWithdrawal.wireValue,
          initiatorParticipantId: louysId,
          targetParticipantId: drift.Value(monicaId),
          departureDate: drift.Value(DateTime.utc(2026, 6, 13)),
          status: HousingParticipationChangeStatus.effective.wireValue,
          createdAt: DateTime.utc(2026, 6, 13),
        ),
      );

      final svc = HousingParticipationChangeService(db);
      await svc.applyEffectiveFromPeerNotify(changeId);

      expect(
        participationChangeDepartureParticipantId(
          kind: HousingParticipationChangeKind.voluntaryWithdrawal,
          initiatorParticipantId: louysId,
          targetParticipantId: monicaId,
        ),
        louysId,
      );
      expect(
        await HousingParticipationMembershipService(db).isActiveMember(
          planId,
          monicaId,
        ),
        isTrue,
      );
      expect(
        await HousingParticipationMembershipService(db).isActiveMember(
          planId,
          louysId,
        ),
        isFalse,
      );
    },
  );
}
