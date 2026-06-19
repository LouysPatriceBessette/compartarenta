import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Web housing notifications are browser-only after relay import — not FCM.
void main() {
  test('ClosedAppPushRegistrationService.sync returns immediately on web', () {
    final src = File(
      'lib/notifications/closed_app_push_registration_service.dart',
    ).readAsStringSync();
    expect(
      src,
      contains('if (kIsWeb) return;'),
      reason: 'Web must not register FCM tokens with the relay',
    );
  });

  test('housing proposal notification on web uses browser API after import', () {
    final orchestratorSrc = File(
      'lib/relay/handshake_orchestrator.dart',
    ).readAsStringSync();
    expect(
      orchestratorSrc,
      contains('showLocalHousingProposalNotification'),
      reason: 'Import handler is the sole housing-proposal notification trigger',
    );
    final webBrowserSrc = File(
      'lib/notifications/housing_browser_notification_web.dart',
    ).readAsStringSync();
    expect(webBrowserSrc, contains('html.Notification'));
    expect(kIsWeb, isFalse, reason: 'VM test host; guards are compile-time on web');
  });
}
