import 'package:compartarenta/util/percent_rational_expansion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandPercentRationalFromShareTotal', () {
    test('non-terminating uses four exact fractional digits (thirds)', () {
      final e = expandPercentRationalFromShareTotal(
        shareMinor: 1,
        totalMinor: 3,
      );
      expect(e, isA<PercentExpansionTruncatedEllipsis>());
      final t = e as PercentExpansionTruncatedEllipsis;
      expect(t.intPart, 33);
      expect(t.fracDigitsFour, '3333');
    });

    test('non-terminating long period still truncates to four digits', () {
      final e = expandPercentRationalFromShareTotal(
        shareMinor: 70458,
        totalMinor: 139500,
      );
      expect(e, isA<PercentExpansionTruncatedEllipsis>());
      final t = e as PercentExpansionTruncatedEllipsis;
      expect(t.intPart, 50);
      expect(t.fracDigitsFour, '5075');
    });
  });
}
