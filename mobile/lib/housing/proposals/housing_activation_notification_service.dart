import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../activity/relay_activity_log_service.dart';
import '../../db/app_database.dart';
import '../../notifications/push_notification_service.dart';

/// Task 1.23 — unanimous activation local notification (deduped per [revisionId]).
class HousingActivationNotificationService {
  HousingActivationNotificationService(this._db);

  static const _prefsKey = 'housing.activationNotifiedRevisionIds';

  final AppDatabase _db;

  bool get _canPersistDedupe {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> alreadyNotified(String revisionId) async {
    if (!_canPersistDedupe) return false;
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_prefsKey)?.contains(revisionId) ?? false;
  }

  Future<void> markNotified(String revisionId) async {
    if (!_canPersistDedupe) return;
    final sp = await SharedPreferences.getInstance();
    final list = List<String>.from(sp.getStringList(_prefsKey) ?? const []);
    if (list.contains(revisionId)) return;
    list.add(revisionId);
    await sp.setStringList(_prefsKey, list);
  }

  /// Shows activation notification once per [revisionId] on this device.
  Future<void> maybeNotifyAgreementActivated({
    required String planId,
    required String revisionId,
    String? packageId,
  }) async {
    if (!_canPersistDedupe) return;
    if (await alreadyNotified(revisionId)) return;
    await markNotified(revisionId);
    try {
      await PushNotificationService.showLocalHousingAgreementActivatedNotification(
        planId: planId,
      );
      await RelayActivityLogService(_db).append(
        kind: RelayActivityLogKinds.housingAgreementActivated,
        initiatorKind: RelayActivityLogService.initiatorSelf,
        planId: planId,
        packageId: packageId,
        revisionId: revisionId,
      );
    } catch (e, st) {
      debugPrint('housing: activation notification failed: $e\n$st');
    }
  }
}
