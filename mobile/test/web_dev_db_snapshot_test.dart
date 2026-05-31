import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/web_dev_db_snapshot.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_ledger_service.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_line_snapshot.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'housing_plan_navigation_e2e_harness.dart';

void main() {
  group('web dev host drift snapshot', () {
    test('exports every AppDatabase table key', () {
      expect(kWebDevHostDriftTableKeys.length, 18);
    });

    test('isAcceptedDevHostSessionVersion accepts v2 and v3', () {
      expect(isAcceptedDevHostSessionVersion(2), isTrue);
      expect(isAcceptedDevHostSessionVersion(3), isTrue);
      expect(isAcceptedDevHostSessionVersion(1), isFalse);
      expect(isAcceptedDevHostSessionVersion('3'), isFalse);
    });

    test('round-trips a fully populated housing ledger', () async {
      final ctx = await setUpHousingPlanNavigationE2E();
      addTearDown(() => tearDownHousingPlanNavigationE2E(ctx));
      final db = ctx.db;
      final planId = ctx.planId;
      const lineId = 'line:e2e:rent';
      final now = DateTime.utc(2026, 5, 30);

      await ensurePendingProposalSubmitted(ctx);
      await simulateProposalAccepted(ctx);

      final pkg = (await db.select(db.proposalPackages).get()).first;

      await db.into(db.realizedExpenses).insert(
            RealizedExpensesCompanion.insert(
              id: 'realized:e2e:1',
              packageId: pkg.id,
              planId: planId,
              planLineId: lineId,
              status: RealizedExpenseStatus.published,
              amountMinor: 1800,
              currency: 'CAD',
              paymentDate: now,
              payerParticipantId: '$planId:p0',
              kind: RealizedExpenseKind.normal,
              planLineTitleSnapshot: const drift.Value('Rent'),
              splitRatiosJson: drift.Value(
                encodeSplitRatiosJson([
                  PlanRatio(
                    id: 'r1',
                    planId: planId,
                    participantId: '$planId:self',
                    lineId: lineId,
                    weight: 5000,
                    createdAt: now,
                  ),
                  PlanRatio(
                    id: 'r2',
                    planId: planId,
                    participantId: '$planId:p0',
                    lineId: lineId,
                    weight: 5000,
                    createdAt: now,
                  ),
                ]),
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await archivePlanLineBeforeRemoval(
        db,
        planId: planId,
        line: (await db.listPlanLines(planId)).first,
      );
      await (db.delete(db.planLines)..where((t) => t.id.equals(lineId))).go();
      await (db.delete(db.planRatios)..where((t) => t.lineId.equals(lineId)))
          .go();

      final revisionId = 'rev:amendment:line-remove';
      await db.into(db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: revisionId,
              packageId: pkg.id,
              contentHash: 'hash:line-remove',
              proposerParticipantId: '$planId:self',
              payloadJson: jsonEncode({
                'amendmentType': 'line_remove',
                'plan': {'lines': [], 'ratios': []},
              }),
              createdAt: now,
            ),
          );

      await db.into(db.relayActivityLogEntries).insert(
            RelayActivityLogEntriesCompanion.insert(
              id: 'log:e2e:1',
              occurredAt: now,
              kind: 'housing_realized_expense',
              initiatorKind: 'local',
              planId: drift.Value(planId),
              detailsJson: const drift.Value('{"expenseId":"realized:e2e:1"}'),
            ),
          );

      final beforeCounts = await countDevHostDriftTables(db);
      expect(beforeCounts['realizedExpenses'], 1);
      expect(beforeCounts['proposalRevisions'], greaterThanOrEqualTo(1));
      expect(beforeCounts['archivedPlanLineSnapshots'], greaterThanOrEqualTo(1));
      expect(beforeCounts['relayActivityLogEntries'], 1);

      final exported = await exportDriftTablesSnapshot(db);
      for (final key in kWebDevHostDriftTableKeys) {
        expect(exported, contains(key));
      }

      final fresh = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(fresh.close);
      await importDriftTablesSnapshot(fresh, exported);

      final afterCounts = await countDevHostDriftTables(fresh);
      expect(afterCounts, equals(beforeCounts));

      final ledger = RealizedExpenseLedgerService(fresh);
      final balances = await ledger.balanceDataForPlan(planId);
      expect(balances.realMode.edges, hasLength(1));
      expect(balances.realMode.edges.single.amountMinor, 900);
    });
  });
}
