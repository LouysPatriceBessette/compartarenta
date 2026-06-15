import 'package:compartarenta/widgets/dialog_tap_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DialogTapGuard ignores overlapping invocations for the same key', () async {
    var started = 0;
    var completed = 0;

    Future<void> slowAction() async {
      started++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      completed++;
    }

    final first = DialogTapGuard.run('test-key', slowAction);
    final second = DialogTapGuard.run('test-key', slowAction);

    expect(await second, isNull);
    await first;
    expect(started, 1);
    expect(completed, 1);
  });

  test('DialogTapGuard allows different keys concurrently', () async {
    var count = 0;

    Future<void> bump() async {
      count++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    await Future.wait([
      DialogTapGuard.run('a', bump),
      DialogTapGuard.run('b', bump),
    ]);

    expect(count, 2);
  });
}
