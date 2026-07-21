import 'package:compartarenta/db/app_database.dart';
import 'package:compartarenta/housing/amendment/housing_agreement_start_date_policy.dart';
import 'package:compartarenta/housing/portability/housing_export_file_name.dart';
import 'package:compartarenta/housing/portability/housing_agreement_export_service.dart';
import 'package:compartarenta/housing/realized_expense/realized_expense_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _DbForTesting extends AppDatabase {
  _DbForTesting(super.e) : super.forTesting();
}

void main() {
  group('housing_agreement_start_date_policy', () {
    test('blocks start date change when published expense exists', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const planId = 'plan:a';
      await db.upsertAgreement(
        AgreementsCompanion.insert(
          id: 'agr:$planId',
          planId: planId,
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 12, 31),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await db.into(db.realizedExpenses).insert(
        RealizedExpensesCompanion.insert(
          id: 'exp:1',
          packageId: 'pkg:a',
          planId: planId,
          planLineId: '$planId:line:1',
          amountMinor: 1000,
          currency: 'CAD',
          paymentDate: DateTime.utc(2026, 2, 1),
          payerParticipantId: '$planId:self',
          kind: 'normal',
          status: RealizedExpenseStatus.published,
          createdAt: DateTime.utc(2026, 2, 1),
          updatedAt: DateTime.utc(2026, 2, 1),
        ),
      );

      final blocked = await blocksAgreementStartDateChange(
        db: db,
        planId: planId,
        existingStart: DateTime.utc(2026, 1, 1),
        proposedStart: DateTime.utc(2026, 2, 1),
      );
      expect(blocked, isTrue);
      expect(
        agreementStartDateWouldChange(
          existingStart: DateTime.utc(2026, 1, 1),
          proposedStart: DateTime.utc(2026, 1, 1),
        ),
        isFalse,
      );
    });

    test(
      'planHasPublishedRealizedExpense true with multiple published rows',
      () async {
        final db = _DbForTesting(NativeDatabase.memory());
        addTearDown(db.close);
        const planId = 'plan:multi';
        for (var i = 1; i <= 2; i++) {
          await db.into(db.realizedExpenses).insert(
            RealizedExpensesCompanion.insert(
              id: 'exp:$i',
              packageId: 'pkg:a',
              planId: planId,
              planLineId: '$planId:line:$i',
              amountMinor: 1000 * i,
              currency: 'CAD',
              paymentDate: DateTime.utc(2026, 2, i),
              payerParticipantId: '$planId:self',
              kind: 'normal',
              status: RealizedExpenseStatus.published,
              createdAt: DateTime.utc(2026, 2, i),
              updatedAt: DateTime.utc(2026, 2, i),
            ),
          );
        }
        expect(await planHasPublishedRealizedExpense(db, planId), isTrue);
      },
    );
  });

  group('housing_export_file_name', () {
    test('uses locale-specific module slug', () {
      final when = DateTime(2026, 6, 22, 10, 31, 13);
      expect(
        housingExportFileName(languageCode: 'fr', now: when),
        '2026-06-22_10:31_Bojairũ-logement.json',
      );
      expect(
        housingExportFileName(languageCode: 'en', now: when),
        '2026-06-22_10:31_Bojairũ-housing.json',
      );
      expect(
        housingExportFileName(languageCode: 'es', now: when),
        '2026-06-22_10:31_Bojairũ-renta.json',
      );
    });
  });

  group('housing_agreement_export_service', () {
    test('checksum verifies intact bundle', () async {
      final db = _DbForTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const planId = 'plan:a';
      const packageId = 'pkg:a';
      await db.into(db.proposalPackages).insert(
        ProposalPackagesCompanion.insert(
          id: packageId,
          planId: planId,
          createdAt: DateTime.utc(2026, 1, 1),
          activeRevisionId: const drift.Value('rev:1'),
        ),
      );
      await db.into(db.proposalRevisions).insert(
        ProposalRevisionsCompanion.insert(
          id: 'rev:1',
          packageId: packageId,
          contentHash: 'hash',
          proposerParticipantId: '$planId:self',
          payloadJson: '{"lifecycleState":"active"}',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final bundle = await HousingAgreementExportService(db).buildExportBundle(
        packageId: packageId,
        planId: planId,
      );
      expect(bundle['formatVersion'], HousingAgreementExportService.formatVersion);
      expect(await HousingAgreementExportService.verifyChecksum(bundle), isTrue);
      final tampered = Map<String, Object?>.from(bundle);
      tampered['planId'] = 'plan:other';
      expect(await HousingAgreementExportService.verifyChecksum(tampered), isFalse);
    });
  });
}
