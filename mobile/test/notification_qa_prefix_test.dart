import 'package:compartarenta/notifications/notification_qa_prefix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notificationQaPrefix prepends list number when enabled', () {
    expect(notificationQaPrefix(4, 'Expense to review'), '#4 Expense to review');
  });
}
