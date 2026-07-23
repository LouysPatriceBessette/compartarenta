import 'package:compartarenta/housing/expense_form/expense_amount_parse.dart';
import 'package:compartarenta/housing/realized_expense/proof_expense_file_name.dart';
import 'package:compartarenta/portability/bojairu_documents_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BojairuDocumentsLayout', () {
    test('housing expense proofs subdir uses plan period', () {
      final start = DateTime(2024, 3, 1);
      final end = DateTime(2025, 12, 31);
      expect(
        BojairuDocumentsLayout.housingExpenseProofsRelativeSubDir(
          agreementPeriodStart: start,
          agreementPeriodEnd: end,
        ),
        'Bojairũ/Housing/2024-03-01_2025-12-31/ExpenseProofs',
      );
    });

    test('backups subdir', () {
      expect(
        BojairuDocumentsLayout.backupsRelativeSubDir(),
        'Bojairũ/Backups',
      );
    });
  });

  group('proof file names', () {
    test('temporary name prefix', () {
      final name = temporaryProofFileName(extension: '.jpg');
      expect(isTemporaryProofFileName(name), isTrue);
      expect(name.endsWith('.jpg'), isTrue);
    });

    test('final name format', () {
      final name = finalProofFileName(
        paymentDate: DateTime(2026, 6, 27),
        submittedAt: DateTime(2026, 6, 27, 14, 30),
        lineTitleLabel: 'Loyer',
        amountMinor: 123456,
        extension: '.jpg',
      );
      expect(name, '2026-06-27_14-30_Loyer_1234.56.jpg');
      expect(isTemporaryProofFileName(name), isFalse);
    });

    test('slugify strips accents and unsafe chars', () {
      expect(slugifyProofLineLabel('Électricité'), 'Electricite');
      expect(slugifyProofLineLabel('A/B test'), 'A_B_test');
    });

    test('collision suffix', () {
      final name = finalProofFileName(
        paymentDate: DateTime(2026, 1, 1),
        submittedAt: DateTime(2026, 1, 1, 9, 0),
        lineTitleLabel: 'Loyer',
        amountMinor: 10000,
        extension: '.pdf',
        collisionSuffix: 3,
      );
      expect(name, '2026-01-01_09-00_Loyer_100.00-3.pdf');
    });

    test('amount uses decimal point from minor units', () {
      expect(minorToAmountText(8950), '89.50');
    });
  });
}
