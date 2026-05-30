import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedPlan(AppDatabase db, String planId) async {
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
  test('applyActiveRevisionPayloadToPlan syncs ratio templates from payload',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-templates';
    await _seedPlan(db, planId);

    const templateId = 'ratioTpl:custom';
    const lineId = 'line:ute';
    final payload = {
      'plan': {
        'type': 'housing',
        'title': 'Home',
        'defaultCurrency': 'CAD',
        'ratioTemplates': [
          {
            'id': templateId,
            'displayTitle': 'UTE split',
            'weightsJson': jsonEncode({
              '$planId:self': 7000,
              '$planId:p0': 3000,
            }),
          },
        ],
        'lines': [
          {
            'id': lineId,
            'title': 'UTE',
            'currency': 'CAD',
            'isRecurring': false,
            'amountMinor': 20000,
            'ratioTemplateId': templateId,
          },
        ],
        'ratios': [
          {'lineId': lineId, 'participantId': '$planId:self', 'weight': 7000},
          {'lineId': lineId, 'participantId': '$planId:p0', 'weight': 3000},
        ],
      },
      'agreement': {
        'periodStart': DateTime.utc(2026, 1, 1).toIso8601String(),
        'periodEnd': DateTime.utc(2026, 12, 31).toIso8601String(),
      },
    };

    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId',
            planId: planId,
            createdAt: DateTime.utc(2026, 5, 29),
          ),
        );
    const revId = 'rev:active';
    await db.into(db.proposalRevisions).insert(
          ProposalRevisionsCompanion.insert(
            id: revId,
            packageId: 'pkg:$planId',
            contentHash: 'hash',
            proposerParticipantId: '$planId:self',
            payloadJson: jsonEncode(payload),
            createdAt: DateTime.utc(2026, 5, 29),
          ),
        );

    await HousingProposalTransportService(db).applyActiveRevisionPayloadToPlan(
      planId: planId,
      revisionId: revId,
    );

    final templates = await db.listPlanRatioTemplates(planId);
    expect(templates.length, 1);
    expect(templates.single.id, templateId);
    expect(templates.single.displayTitle, 'UTE split');

    final lines = await db.listPlanLines(planId);
    expect(lines.length, 1);
    expect(lines.single.title, 'UTE');
    expect(lines.single.ratioTemplateId, templateId);

    await db.close();
  });

  test('repairPendingAmendmentActivationIfUnanimous activates when all accepted',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-repair-activate';
    await _seedPlan(db, planId);

    final svc = PlanAgreementProposalService(db);
    final activeRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await svc.recordResponse(
      revisionId: activeRev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: activeRev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final amendRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: activeRev,
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: amendRev,
      mutate: (payload) {
        payload['amendmentType'] = 'line_add';
      },
    );
    await svc.recordResponse(
      revisionId: amendRev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );

    final transport = HousingProposalTransportService(db);
    expect(
      await transport.pendingRevisionIdForPlan(planId),
      amendRev,
    );

    await transport.repairPendingAmendmentActivationIfUnanimous(planId);
    await transport.reconcileStalePackagePending(planId);

    expect(await transport.pendingRevisionIdForPlan(planId), isNull);
    expect(
      await transport.hasPendingAmendmentForUi(
        planId,
        reconcileFirst: false,
      ),
      isFalse,
    );
    expect(await transport.resolveActiveRevisionIdForPlan(planId), amendRev);

    await db.close();
  });
}
