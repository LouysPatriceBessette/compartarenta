import 'package:compartarenta/vehicle/portability/vehicle_sale_export_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vehicleSaleExportZipFileName uses localized segment and label', () {
    final name = vehicleSaleExportZipFileName(
      date: DateTime(2026, 7, 14),
      dataOfSegment: 'Données-de',
      displayLabel: 'Camry',
    );
    expect(name, '2026-07-14-Données-de-Camry.zip');
  });

  test('sanitize replaces path-illegal characters only', () {
    expect(
      sanitizeVehicleSaleDisplayLabelForFileName('Foo/Bar:Baz'),
      'Foo-Bar-Baz',
    );
  });

  test('empty displayLabel is rejected', () {
    expect(
      () => sanitizeVehicleSaleDisplayLabelForFileName('  '),
      throwsArgumentError,
    );
  });
}
