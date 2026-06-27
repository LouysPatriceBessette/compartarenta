import 'package:compartarenta/housing/realized_expense/proof_attachment_storage.dart';
import 'package:compartarenta/housing/realized_expense/proof_expense_file_name.dart';
import 'package:compartarenta/portability/public_documents_file_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persist temporary and finalize at submission', () async {
    final scope = HousingProofStorageScope(
      agreementPeriodStart: DateTime(2024, 1, 1),
      agreementPeriodEnd: DateTime(2024, 12, 31),
    );
    final bytes = List<int>.generate(32, (i) => i % 256);
    final temp = await ProofAttachmentStorage.persistFromBytes(
      bytes: bytes,
      scope: scope,
      sourceExtension: '.jpg',
    );
    expect(isTemporaryProofFileName(temp.displayFileName), isTrue);
    expect(await publicDocumentExists(temp.filePath), isTrue);

    final submittedAt = DateTime(2026, 6, 27, 18, 45);
    final finalized = await ProofAttachmentStorage.finalizeProofsForSubmission(
      proofs: [temp],
      scope: scope,
      paymentDate: DateTime(2026, 6, 15),
      submittedAt: submittedAt,
      lineTitleLabel: 'Loyer',
      amountMinor: 50000,
    );
    expect(finalized, hasLength(1));
    expect(finalized.single.displayFileName, '2026-06-15_18-45_Loyer_500.00.jpg');
    expect(await publicDocumentExists(finalized.single.filePath), isTrue);
    expect(await publicDocumentExists(temp.filePath), isFalse);

    final readBack = await ProofAttachmentStorage.readProofBytes(
      finalized.single.filePath,
    );
    expect(readBack, bytes);

    await deletePublicDocument(finalized.single.filePath);
  });

  test('sha256Hex is stable length', () async {
    final hash = await ProofAttachmentStorage.sha256Hex([1, 2, 3]);
    expect(hash, hasLength(64));
  });
}
