// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import '../housing/housing_navigation_intent.dart';
import '../navigation/app_navigation.dart';
import '../relay/handshake_orchestrator.dart';
import 'push_notification_service.dart';

const _planPeerEstablishmentPrefix = 'plan_peer_establishment:';

Future<void> showContactNotification({
  required String title,
  required String body,
  required bool playSound,
  String? payload,
}) async {
  if (!html.Notification.supported ||
      html.Notification.permission != 'granted') {
    return;
  }
  final notification = html.Notification(title, body: body);
  notification.onClick.listen((_) async {
    if (payload != null && payload.startsWith(_planPeerEstablishmentPrefix)) {
      final planId = payload.substring(_planPeerEstablishmentPrefix.length);
      if (planId.isNotEmpty) {
        HousingNavigationIntent.requestOpenMissingContacts(planId);
      }
      final orchestrator = HandshakeOrchestrator.maybeInstance;
      if (orchestrator != null) {
        await orchestrator.pollSteadyStateInboxes().catchError((
          Object e,
          StackTrace st,
        ) {
          // ignore: avoid_print
          print('contact browser notification click poll: $e\n$st');
        });
      }
      pushFromNotificationTapWhenReady(
        '/housing',
        skipPushWhenAlreadyAt: (location) => location.startsWith('/housing'),
        beforeNavigate: (_) async {
          HousingNavigationIntent.requestEntryReload();
        },
      );
      notification.close();
      return;
    }
    PushNotificationService.openContactsFromNotificationTap();
    notification.close();
  });
}
