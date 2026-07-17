import 'package:compartarenta/util/display_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPreferenceDateTimeWithSeconds includes seconds', () {
    final utc = DateTime.utc(2026, 7, 16, 22, 47, 5);
    expect(
      formatPreferenceDateTimeWithSeconds(utc, 'YYYY-MM-DD'),
      '2026-07-16 18:47:05',
    );
  });
}
