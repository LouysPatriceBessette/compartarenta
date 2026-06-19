import 'package:compartarenta/housing/quiet_hours_week_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quietHoursCalendarWeekdayForUiColumn', () {
    test('Sunday week start maps UI columns to calendar weekdays', () {
      // D L M M J V S → Sun … Sat
      expect(quietHoursCalendarWeekdayForUiColumn(0, 0), 0);
      expect(quietHoursCalendarWeekdayForUiColumn(0, 1), 1);
      expect(quietHoursCalendarWeekdayForUiColumn(0, 5), 5); // Friday
      expect(quietHoursCalendarWeekdayForUiColumn(0, 6), 6); // Saturday
    });

    test('Monday week start maps UI columns to calendar weekdays', () {
      // L M M J V S D → Mon … Sun
      expect(quietHoursCalendarWeekdayForUiColumn(1, 0), 1);
      expect(quietHoursCalendarWeekdayForUiColumn(1, 4), 5); // Friday
      expect(quietHoursCalendarWeekdayForUiColumn(1, 5), 6); // Saturday
      expect(quietHoursCalendarWeekdayForUiColumn(1, 6), 0); // Sunday
    });
  });
}
