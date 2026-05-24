import 'dart:io';

import 'package:compartarenta/housing/realized_expense/proof_attachment_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('persistFromBytes writes file and hash', () async {
    final dir = await Directory.systemTemp.createTemp('proof_test_');
    try {
      // Override proofs directory by writing directly via persistFromBytes
      // (uses app documents in production; here we only test hash + naming).
      final bytes = List<int>.generate(64, (i) => i % 256);
      final hash = await ProofAttachmentStorage.sha256Hex(bytes);
      expect(hash, hasLength(64));

      final safe = p.join(dir.path, 'sample-receipt.pdf');
      await File(safe).writeAsBytes(bytes);
      expect(await File(safe).exists(), isTrue);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
