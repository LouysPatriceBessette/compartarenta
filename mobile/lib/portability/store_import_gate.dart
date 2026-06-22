import 'package:flutter/foundation.dart';

/// Whether the user may import a device backup (active paid housing subscription).
abstract class StoreImportGate {
  Future<bool> hasActiveHousingSubscription();
}

/// Debug / pre-billing: import enabled when [kDebugMode] unless overridden.
class DevFakeStoreImportGate implements StoreImportGate {
  DevFakeStoreImportGate({this.forceEnabled = true});

  final bool forceEnabled;

  static const enabledDefine = bool.fromEnvironment(
    'DEVICE_IMPORT_GATE_FAKE',
    defaultValue: true,
  );

  @override
  Future<bool> hasActiveHousingSubscription() async {
    if (!kDebugMode) return false;
    return enabledDefine && forceEnabled;
  }
}

/// Release builds until Play / StoreKit integration ships.
class ReleaseStoreImportGate implements StoreImportGate {
  @override
  Future<bool> hasActiveHousingSubscription() async => false;
}

StoreImportGate defaultStoreImportGate() {
  if (kDebugMode) return DevFakeStoreImportGate();
  return ReleaseStoreImportGate();
}
