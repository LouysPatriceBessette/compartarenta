import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createForkDraftFromActiveRevision copies active revision into draft plan',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const listPlanId = 'housing:source';
    const draftPlanId = 'housing:draft';
    const packageId = 'pkg:1';
    const revisionId = 'rev:active';

    await db.upsertPlan(
      PlansCompanion.insert(
        id: listPlanId,
        type: 'housing',
        title: const drift.Value('Source plan'),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.proposalPackages).insert(
      ProposalPackagesCompanion.insert(
        id: packageId,
        planId: listPlanId,
        activeRevisionId: const drift.Value(revisionId),
        createdAt: DateTime.utc(2026),
      ),
    );
    await db.into(db.proposalRevisions).insert(
      ProposalRevisionsCompanion.insert(
        id: revisionId,
        packageId: packageId,
        contentHash: 'hash',
        proposerParticipantId: '$listPlanId:self',
        payloadJson: jsonEncode({
          'kind': PlanAgreementProposalService.kind,
          'lifecycleState': 'archived',
          'plan': {
            'title': 'Source plan',
            'lines': [
              {
                'id': 'line1',
                'title': 'Rent',
                'currency': 'CAD',
                'isRecurring': true,
                'amountMinor': 100000,
              },
            ],
            'ratios': [],
          },
          'agreement': {
            'periodStart': '2025-01-01T00:00:00.000Z',
            'periodEnd': '2025-12-31T00:00:00.000Z',
            'minNoticeDays': 0,
            'penaltyMinor': 0,
            'clauses': '',
            'withdrawalSameForAll': 'true',
            'withdrawalPerParticipantJson': '{}',
            'agreementRulesJson': '{}',
          },
          'participantSnapshots': [
            {'id': '$listPlanId:self', 'displayName': 'Self'},
          ],
        }),
        createdAt: DateTime.utc(2026),
      ),
    );

    await HousingProposalTransportService(db).createForkDraftFromActiveRevision(
      listPlanId: listPlanId,
      draftPlanId: draftPlanId,
    );

    final draftPlan = await (db.select(db.plans)
          ..where((t) => t.id.equals(draftPlanId)))
        .getSingleOrNull();
    expect(draftPlan, isNotNull);
    expect(draftPlan!.title, 'Source plan');

    final lines = await db.listPlanLines(draftPlanId);
    expect(lines, hasLength(1));
    expect(lines.single.title, 'Rent');
  });
}
