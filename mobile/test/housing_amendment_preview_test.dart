import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_summary.dart';
import 'package:compartarenta/housing/amendment/housing_amendment_type.dart';
import 'package:compartarenta/housing/proposals/housing_proposal_transport_service.dart';
import 'package:compartarenta/housing/proposals/plan_agreement_proposal_service.dart';
import 'package:compartarenta/l10n/app_localizations.dart';
import 'package:compartarenta/util/display_date.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _seedTwoParticipantPlan(AppDatabase db, String planId) async {
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
  test('buildAmendmentPreviewSummary agreement end uses active revision', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-active';
    await _seedTwoParticipantPlan(db, planId);

    final svc = PlanAgreementProposalService(db);
    final rev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: rev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = await buildAmendmentPreviewSummary(
      db: db,
      planId: planId,
      type: HousingAmendmentType.agreementEnd,
      proposedPeriodEnd: DateTime.utc(2027, 6, 30),
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
    );

    expect(summary, isNotNull);
    expect(summary!.type, HousingAmendmentType.agreementEnd);
    expect(
      summary.currentText,
      formatPreferenceDate(DateTime.utc(2026, 12, 31), 'YYYY-MM-DD'),
    );
    expect(
      summary.proposedText,
      formatPreferenceDate(DateTime.utc(2027, 6, 30), 'YYYY-MM-DD'),
    );

    await db.close();
  });

  test('buildAmendmentPreviewSummary agreement end falls back to live agreement',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-live-only';
    await _seedTwoParticipantPlan(db, planId);

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = await buildAmendmentPreviewSummary(
      db: db,
      planId: planId,
      type: HousingAmendmentType.agreementEnd,
      proposedPeriodEnd: DateTime.utc(2027, 3, 15),
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
    );

    expect(summary, isNotNull);
    expect(
      summary!.currentText,
      formatPreferenceDate(DateTime.utc(2026, 12, 31), 'YYYY-MM-DD'),
    );
    expect(
      summary.proposedText,
      formatPreferenceDate(DateTime.utc(2027, 3, 15), 'YYYY-MM-DD'),
    );

    await db.close();
  });

  test(
      'loadHousingAmendmentSummary agreement end ignores live table before acceptance',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-pending-end';
    await _seedTwoParticipantPlan(db, planId);

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

    final pendingRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: activeRev,
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: pendingRev,
      mutate: (payload) {
        payload['amendmentType'] = 'agreement_end';
        final agr = payload['agreement'];
        if (agr is Map) {
          agr['periodEnd'] = DateTime.utc(2027, 3, 31).toIso8601String();
        }
      },
    );

    // Simulate a device where live agreement was wrongly advanced early.
    await (db.update(db.agreements)..where((t) => t.planId.equals(planId)))
        .write(
      AgreementsCompanion(
        periodEnd: drift.Value(DateTime.utc(2027, 3, 31)),
      ),
    );

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = await loadHousingAmendmentSummary(
      db: db,
      planId: planId,
      revisionId: pendingRev,
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
    );

    expect(summary, isNotNull);
    expect(
      summary!.currentText,
      formatPreferenceDate(DateTime.utc(2026, 12, 31), 'YYYY-MM-DD'),
    );
    expect(
      summary.proposedText,
      formatPreferenceDate(DateTime.utc(2027, 3, 31), 'YYYY-MM-DD'),
    );

    await db.close();
  });

  test('accepting amendment updates live agreement periodEnd', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-accept-updates-agreement';
    await _seedTwoParticipantPlan(db, planId);

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
        payload['amendmentType'] = 'agreement_end';
        final agr = payload['agreement'];
        if (agr is Map) {
          agr['periodEnd'] = DateTime.utc(2027, 3, 31).toIso8601String();
        }
      },
    );
    await svc.recordResponse(
      revisionId: amendRev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: amendRev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final agr = await db.getAgreementForPlan(planId);
    expect(agr, isNotNull);
    expect(
      formatPreferenceDate(agr!.periodEnd, 'YYYY-MM-DD'),
      formatPreferenceDate(DateTime.utc(2027, 3, 31), 'YYYY-MM-DD'),
    );
    await db.close();
  });

  test('hasPendingAmendmentForUi when active and pending are on different packages',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-split-pkg';
    await _seedTwoParticipantPlan(db, planId);

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

    final pendingRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: activeRev,
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: pendingRev,
      mutate: (payload) {
        payload['amendmentType'] = 'agreement_end';
      },
    );

    // Legacy duplicate row: pending here, active on canonical pkg only.
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId:imported',
            planId: planId,
            pendingRevisionId: drift.Value(pendingRev),
            createdAt: DateTime.utc(2026, 5, 27, 22),
          ),
        );
    await (db.update(db.proposalPackages)..where((t) => t.id.equals('pkg:$planId')))
        .write(
      const ProposalPackagesCompanion(pendingRevisionId: drift.Value(null)),
    );

    final transport = HousingProposalTransportService(db);
    expect(await transport.hasPendingAmendmentForUi(planId), isTrue);
    expect(await transport.resolveActiveRevisionIdForPlan(planId), activeRev);
    expect(await transport.resolvePendingRevisionIdForPlan(planId), pendingRev);

    await db.close();
  });

  test(
      'resolveActiveRevisionIdForPlan prefers live agreement when packages disagree',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-stale-active-pkg';
    await _seedTwoParticipantPlan(db, planId);

    final svc = PlanAgreementProposalService(db);
    final initialRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: initialRev,
      mutate: (payload) {
        final agr = payload['agreement'];
        if (agr is Map) {
          agr['periodEnd'] = DateTime.utc(2027, 3, 24).toIso8601String();
        }
      },
    );
    await svc.recordResponse(
      revisionId: initialRev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: initialRev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    final amendRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: initialRev,
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: amendRev,
      mutate: (payload) {
        payload['amendmentType'] = 'agreement_end';
        final agr = payload['agreement'];
        if (agr is Map) {
          agr['periodEnd'] = DateTime.utc(2027, 3, 31).toIso8601String();
        }
      },
    );
    await svc.recordResponse(
      revisionId: amendRev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: amendRev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    // Import shadow row still pointing at the superseded activation revision.
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId:imported',
            planId: planId,
            activeRevisionId: drift.Value(initialRev),
            createdAt: DateTime.utc(2026, 5, 27, 22),
          ),
        );

    final transport = HousingProposalTransportService(db);
    expect(await transport.resolveActiveRevisionIdForPlan(planId), amendRev);

    final l10n = lookupAppLocalizations(const Locale('fr'));
    final summary = await buildAmendmentPreviewSummary(
      db: db,
      planId: planId,
      type: HousingAmendmentType.agreementEnd,
      proposedPeriodEnd: DateTime.utc(2027, 4, 15),
      l10n: l10n,
      dateFormat: 'YYYY-MM-DD',
    );
    expect(summary, isNotNull);
    expect(
      summary!.currentText,
      formatPreferenceDate(DateTime.utc(2027, 3, 31), 'YYYY-MM-DD'),
    );
    expect(
      summary.proposedText,
      formatPreferenceDate(DateTime.utc(2027, 4, 15), 'YYYY-MM-DD'),
    );

    await db.close();
  });

  test('resolveActiveRevisionIdForPlan finds active across duplicate packages',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-dup-pkg';
    await _seedTwoParticipantPlan(db, planId);

    final svc = PlanAgreementProposalService(db);
    final rev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
    );
    await svc.recordResponse(
      revisionId: rev,
      participantId: '$planId:p0',
      status: ProposalResponseStatus.accepted,
    );
    await svc.tryActivateIfUnanimous(
      planId: planId,
      revisionId: rev,
      participantIds: ['$planId:self', '$planId:p0'],
    );

    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId:shadow',
            planId: planId,
            createdAt: DateTime.utc(2026, 2, 1),
          ),
        );

    final transport = HousingProposalTransportService(db);
    expect(await transport.resolveActiveRevisionIdForPlan(planId), rev);

    await db.close();
  });

  test(
      'resolveActiveRevisionIdForPlan ignores open revision mistakenly marked active',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    const planId = 'p-active-open-shadow';
    await _seedTwoParticipantPlan(db, planId);

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

    final pendingRev = await svc.createRevisionFromCurrentDraft(
      planId: planId,
      proposerParticipantId: '$planId:self',
      forkedFromPackageId: 'pkg:$planId',
      forkedFromRevisionId: activeRev,
    );
    await HousingProposalTransportService(db).updateRevisionPayload(
      revisionId: pendingRev,
      mutate: (payload) {
        payload['amendmentType'] = 'agreement_end';
      },
    );

    // Shadow package incorrectly marking the open pending revision as active.
    await db.into(db.proposalPackages).insert(
          ProposalPackagesCompanion.insert(
            id: 'pkg:$planId:shadow',
            planId: planId,
            activeRevisionId: drift.Value(pendingRev),
            createdAt: DateTime.utc(2026, 5, 27, 22, 30),
          ),
        );

    final transport = HousingProposalTransportService(db);
    expect(await transport.resolveActiveRevisionIdForPlan(planId), activeRev);

    await db.close();
  });
}
