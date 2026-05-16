import 'package:compartarenta/notifications/notification_permission_gate.dart';
import 'package:compartarenta/prefs/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('does not request when permission is already granted', () async {
    final client = _FakePermissionClient(
      status: NotificationSystemPermissionStatus.granted,
      requestResult: NotificationSystemPermissionStatus.denied,
    );
    final gate = NotificationPermissionGate(client: client);

    final result = await gate.ensureForUserAction();

    expect(result, NotificationSystemPermissionStatus.granted);
    expect(client.requestCount, 0);
  });

  test('requests when permission is unknown', () async {
    final client = _FakePermissionClient(
      status: NotificationSystemPermissionStatus.unknown,
      requestResult: NotificationSystemPermissionStatus.granted,
    );
    final gate = NotificationPermissionGate(client: client);

    final result = await gate.ensureForUserAction();

    expect(result, NotificationSystemPermissionStatus.granted);
    expect(client.requestCount, 1);
  });

  test('does not request when app notifications are disabled', () async {
    SharedPreferences.setMockInitialValues({'notifications.enabled': false});
    final prefs = await AppPreferences.load();
    final client = _FakePermissionClient(
      status: NotificationSystemPermissionStatus.unknown,
      requestResult: NotificationSystemPermissionStatus.granted,
    );
    final gate = NotificationPermissionGate(client: client);

    final result = await gate.ensureForUserAction(prefs: prefs);

    expect(result, NotificationSystemPermissionStatus.unknown);
    expect(client.requestCount, 0);
  });

  test('new installations default app notifications to disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();

    expect(prefs.notificationsEnabled, isFalse);
    expect(prefs.notificationContactAddRequests, isTrue);
  });

  test('settings system request ignores disabled app notifications', () async {
    SharedPreferences.setMockInitialValues({'notifications.enabled': false});
    final client = _FakePermissionClient(
      status: NotificationSystemPermissionStatus.unknown,
      requestResult: NotificationSystemPermissionStatus.granted,
    );
    final gate = NotificationPermissionGate(client: client);

    final result = await gate.requestSystemPermission();

    expect(result, NotificationSystemPermissionStatus.granted);
    expect(client.requestCount, 1);
  });
}

final class _FakePermissionClient implements NotificationPermissionClient {
  _FakePermissionClient({required this.status, required this.requestResult});

  final NotificationSystemPermissionStatus status;
  final NotificationSystemPermissionStatus requestResult;
  int requestCount = 0;

  @override
  Future<NotificationSystemPermissionStatus> getStatus() async => status;

  @override
  Future<NotificationSystemPermissionStatus> request() async {
    requestCount++;
    return requestResult;
  }
}
