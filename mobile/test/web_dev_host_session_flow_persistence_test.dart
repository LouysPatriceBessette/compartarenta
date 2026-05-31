import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/debug/web_dev_db_snapshot.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_type.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'housing_plan_navigation_e2e_harness.dart';

/// In-memory export/import after each housing flow (excludes lineEdit and
/// ruleChange — not QA-ready).
void main() {
  group('web dev persistence after housing flows', () {
    late HousingPlanNavigationE2EContext ctx;

    setUp(() async {
      ctx = await setUpHousingPlanNavigationE2E();
    });

    tearDown(() async {
      await tearDownHousingPlanNavigationE2E(ctx);
    });

    Future<void> expectRoundTripPreservesCounts(AppDatabase db) async {
      final before = await countDevHostDriftTables(db);
      final exported = await exportDriftTablesSnapshot(db);
      final restored = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await importDriftTablesSnapshot(restored, exported);
      final after = await countDevHostDriftTables(restored);
      expect(after, equals(before));
    }

    test('initial plan proposal pending state', () async {
      await ensurePendingProposalSubmitted(ctx);
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('active plan after unanimous acceptance', () async {
      await ensurePendingProposalSubmitted(ctx);
      await simulateProposalAccepted(ctx);
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('rejected plan archive', () async {
      await ensurePendingProposalSubmitted(ctx);
      await simulateProposalRejected(ctx);
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('line remove amendment revision payload', () async {
      await ensurePendingProposalSubmitted(ctx);
      await simulateProposalAccepted(ctx);
      final planId = ctx.planId;
      const lineId = 'line:e2e:rent';
      final now = DateTime.utc(2026, 5, 30);
      final pkg = (await ctx.db.select(ctx.db.proposalPackages).get()).first;

      await ctx.db.into(ctx.db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: 'rev:line-remove',
              packageId: pkg.id,
              contentHash: 'hash:remove',
              proposerParticipantId: '$planId:self',
              payloadJson: jsonEncode({
                'amendmentType': HousingAmendmentType.lineRemove.wireValue,
                'amendmentTargetLineId': lineId,
                'plan': {'lines': [], 'ratios': []},
              }),
              createdAt: now,
            ),
          );

      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('line add amendment revision payload', () async {
      await _ensureAccepted(ctx);
      final planId = ctx.planId;
      final now = DateTime.utc(2026, 5, 30);
      final pkg = (await ctx.db.select(ctx.db.proposalPackages).get()).first;

      await ctx.db.into(ctx.db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: 'rev:line-add',
              packageId: pkg.id,
              contentHash: 'hash:add',
              proposerParticipantId: '$planId:self',
              payloadJson: jsonEncode({
                'amendmentType': HousingAmendmentType.lineAdd.wireValue,
                'plan': {
                  'lines': [
                    {
                      'id': 'line:new:util',
                      'title': 'Utilities',
                      'currency': 'CAD',
                      'isRecurring': true,
                      'amountMinor': 5000,
                    },
                  ],
                  'ratios': [],
                },
              }),
              createdAt: now,
            ),
          );
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('line amount amendment revision payload', () async {
      await _ensureAccepted(ctx);
      final planId = ctx.planId;
      final now = DateTime.utc(2026, 5, 30);
      final pkg = (await ctx.db.select(ctx.db.proposalPackages).get()).first;

      await ctx.db.into(ctx.db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: 'rev:line-amount',
              packageId: pkg.id,
              contentHash: 'hash:amount',
              proposerParticipantId: '$planId:self',
              payloadJson: jsonEncode({
                'amendmentType': HousingAmendmentType.lineAmount.wireValue,
                'amendmentTargetLineId': 'line:e2e:rent',
                'plan': {
                  'lines': [
                    {
                      'id': 'line:e2e:rent',
                      'title': 'Rent',
                      'currency': 'CAD',
                      'isRecurring': true,
                      'amountMinor': 120000,
                    },
                  ],
                  'ratios': [],
                },
              }),
              createdAt: now,
            ),
          );
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('agreement end amendment revision payload', () async {
      await _ensureAccepted(ctx);
      final planId = ctx.planId;
      final now = DateTime.utc(2026, 5, 30);
      final pkg = (await ctx.db.select(ctx.db.proposalPackages).get()).first;

      await ctx.db.into(ctx.db.proposalRevisions).insert(
            ProposalRevisionsCompanion.insert(
              id: 'rev:agreement-end',
              packageId: pkg.id,
              contentHash: 'hash:end',
              proposerParticipantId: '$planId:self',
              payloadJson: jsonEncode({
                'amendmentType': HousingAmendmentType.agreementEnd.wireValue,
                'agreement': {
                  'periodEnd': now
                      .add(const Duration(days: 90))
                      .toIso8601String(),
                },
              }),
              createdAt: now,
            ),
          );
      await expectRoundTripPreservesCounts(ctx.db);
    });

    test('published realized expense with snapshots', () async {
      await _ensureAccepted(ctx);
      final planId = ctx.planId;
      const lineId = 'line:e2e:rent';
      final now = DateTime.utc(2026, 5, 30);
      await ctx.db.into(ctx.db.realizedExpenses).insert(
            RealizedExpensesCompanion.insert(
              id: 'realized:persist:1',
              packageId: 'pkg:1',
              planId: planId,
              planLineId: lineId,
              status: RealizedExpenseStatus.published,
              amountMinor: 2500,
              currency: 'CAD',
              paymentDate: now,
              payerParticipantId: '$planId:self',
              kind: RealizedExpenseKind.normal,
              planLineTitleSnapshot: const drift.Value('Rent'),
              splitRatiosJson: drift.Value(
                '[{"participantId":"$planId:self","weight":5000},'
                '{"participantId":"$planId:p0","weight":5000}]',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await expectRoundTripPreservesCounts(ctx.db);
    });
  });
}

Future<void> _ensureAccepted(HousingPlanNavigationE2EContext ctx) async {
  await ensurePendingProposalSubmitted(ctx);
  await simulateProposalAccepted(ctx);
}
