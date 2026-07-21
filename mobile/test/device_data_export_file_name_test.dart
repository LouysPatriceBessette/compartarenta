import 'package:compartarenta/portability/device_data_export_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device backup filename uses the visible Bojairũ brand', () {
    expect(
      deviceDataExportFileName(now: DateTime(2026, 7, 21, 18, 6)),
      '2026-07-21_18:06_Bojairũ-backup.json',
    );
  });
}
