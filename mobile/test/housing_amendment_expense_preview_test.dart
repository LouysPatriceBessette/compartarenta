import 'dart:convert';

import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_expense_preview.dart';
import 'package:compartarenta/housing/amendment/housing_line_add_amendment_pending.dart';
import 'package:compartarenta/housing/amendment/housing_line_edit_amendment_pending.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_summary.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_type.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
  test('resolveAmendmentExpenseLinePreview loads line_add from revision only',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-payload-line';
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

    const newLineId = 'line:new-expense';
    final amendRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: activeRev,
    );
    await (db.update(db.proposalRevisions)..where((t) => t.id.equals(amendRev)))
        .write(
      ProposalRevisionsCompanion(
        payloadJson: drift.Value(
          jsonEncode({
            ...(jsonDecode(
                  (await (db.select(db.proposalRevisions)
                            ..where((t) => t.id.equals(amendRev)))
                        .getSingle())
                      .payloadJson,
                )
                as Map<String, dynamic>),
            'amendmentType': 'line_add',
            'amendmentTargetLineId': newLineId,
            'plan': {
              'type': 'housing',
              'title': 'Home',
              'defaultCurrency': 'CAD',
              'lines': [
                {
                  'id': newLineId,
                  'title': 'Groceries',
                  'description': 'Weekly shop',
                  'currency': 'CAD',
                  'isRecurring': false,
                  'amountUsesRange': false,
                  'amountIsBudgetCap': false,
                  'amountMinor': 4200,
                  'cadence': '',
                },
              ],
              'ratios': [
                {
                  'lineId': newLineId,
                  'participantId': '$planId:self',
                  'weight': 5000,
                },
                {
                  'lineId': newLineId,
                  'participantId': '$planId:p0',
                  'weight': 5000,
                },
              ],
            },
          }),
        ),
      ),
    );

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = HousingAmendmentSummary(
      revisionId: amendRev,
      type: HousingAmendmentType.lineAdd,
      proposerParticipantId: '$planId:self',
      proposerDisplayName: 'Self',
      targetLineId: newLineId,
      targetLineTitle: 'Groceries',
      currentText: 'None',
      proposedText: 'ignored',
    );

    final view = await resolveAmendmentExpenseLinePreview(
      db: db,
      planId: planId,
      summary: summary,
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
      defaultCurrency: 'CAD',
    );

    expect(view, isNotNull);
    expect(view!.title, 'Groceries');
    expect(view.description, 'Weekly shop');
    expect(view.amountText, '42.00');
    expect(view.split, isNotNull);
    expect(view.split!.rows.length, 2);

    await db.close();
  });

  test(
      'resolveAmendmentExpenseLinePreview maps payment responsible from source ids',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-peer';
    await _seedPlan(db, planId);

    const newLineId = 'line:ute';
    const amendRev = 'rev:amend-pay';
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId',
            planId: planId,
            createdAt: DateTime.utc(2026, 5, 29),
          ),
        );
    await db.into(db.proposalRevisions).insert(
          ProposalRevisionsCompanion.insert(
            id: amendRev,
            packageId: 'pkg:$planId',
            contentHash: 'hash',
            proposerParticipantId: 'remote:self',
            payloadJson: jsonEncode({
              'lifecycleState': 'open',
              'amendmentType': 'line_add',
              'amendmentTargetLineId': newLineId,
              'participantSourceIds': {
                '$planId:p0': 'remote:p0',
                '$planId:self': 'remote:self',
              },
              'plan': {
                'lines': [
                  {
                    'id': newLineId,
                    'title': 'UTE',
                    'description': '',
                    'currency': 'CAD',
                    'isRecurring': true,
                    'amountMinor': 20000,
                    'paymentResponsibleParticipantId': 'remote:p0',
                  },
                ],
                'ratios': [
                  {
                    'lineId': newLineId,
                    'participantId': '$planId:p0',
                    'weight': 10000,
                  },
                ],
              },
            }),
            createdAt: DateTime.utc(2026, 5, 29),
          ),
        );

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = HousingAmendmentSummary(
      revisionId: amendRev,
      type: HousingAmendmentType.lineAdd,
      proposerParticipantId: '$planId:self',
      proposerDisplayName: 'Self',
      targetLineId: newLineId,
      targetLineTitle: 'UTE',
      currentText: 'None',
      proposedText: 'UTE · 200.00',
    );

    final view = await resolveAmendmentExpenseLinePreview(
      db: db,
      planId: planId,
      summary: summary,
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
      defaultCurrency: 'CAD',
    );

    expect(view, isNotNull);
    expect(view!.paymentResponsibleLabel, 'Peer');
    await db.close();
  });

  test('resolveAmendmentExpenseLinePreview loads line_add draft before submit',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-preview-draft';
    await _seedPlan(db, planId);

    const newLineId = 'line:draft-expense';
    HousingLineAddAmendmentPendingStore.set(
      planId,
      HousingLineEditAmendmentPending(
        lineId: newLineId,
        lineMap: {
          'id': newLineId,
          'title': 'Insurance',
          'description': 'Monthly',
          'currency': 'CAD',
          'isRecurring': true,
          'amountMinor': 12000,
          'amountUsesRange': false,
          'amountIsBudgetCap': false,
          'cadence': 'monthly',
          'recurrenceSpecJson': '{"kind":"monthlyDay","day":1}',
        },
        ratioMaps: [
          {
            'lineId': newLineId,
            'participantId': '$planId:self',
            'weight': 5000,
          },
          {
            'lineId': newLineId,
            'participantId': '$planId:p0',
            'weight': 5000,
          },
        ],
      ),
    );

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final view = await resolveAmendmentExpenseLinePreview(
      db: db,
      planId: planId,
      summary: HousingAmendmentSummary(
        revisionId: 'preview',
        type: HousingAmendmentType.lineAdd,
        proposerParticipantId: '$planId:self',
        proposerDisplayName: 'Self',
        targetLineId: newLineId,
        targetLineTitle: 'Insurance',
        currentText: 'None',
        proposedText: 'Insurance · 120.00',
      ),
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
      defaultCurrency: 'CAD',
    );

    HousingLineAddAmendmentPendingStore.clear(planId);
    expect(view, isNotNull);
    expect(view!.title, 'Insurance');
    expect(view.amountText, '120.00');
    await db.close();
  });

  test('journalListSubject uses expense title and amount for line add', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = HousingAmendmentSummary(
      revisionId: 'rev:1',
      type: HousingAmendmentType.lineAdd,
      proposerParticipantId: 'p:self',
      proposerDisplayName: 'Self',
      targetLineId: 'line:1',
      targetLineTitle: 'UTE',
      currentText: 'None',
      proposedText: 'UTE · 200.00 CAD',
    );
    expect(
      summary.journalListSubject(l10n),
      "Ajout d'une dépense - UTE - 200,00 \$",
    );
    expect(
      summary.journalListSubject(l10n),
      isNot(contains('nouvelle ligne')),
    );
  });
}
