import 'package:flutter/foundation.dart';

import 'device_binding_hash.dart';
import 'device_binding_platform.dart';
import 'device_binding_tier_a.dart';

/// Computes and caches the local [deviceBindingId] from Tier A + Tier B signals.
class DeviceBindingService {
  DeviceBindingService({
    DeviceBindingPlatform? platform,
    @visibleForTesting this.fixedIdForTesting,
  }) : _platform = platform ?? DeviceBindingPlatform.instance;

  static var _testingSeq = 0;

  /// Distinct binding id per call — use in unit/integration tests.
  factory DeviceBindingService.forTesting([String suffix = '']) {
    _testingSeq++;
    final token = suffix.isEmpty ? '$_testingSeq' : suffix;
    return DeviceBindingService(fixedIdForTesting: 'test-binding-$token');
  }

  final DeviceBindingPlatform _platform;

  /// When set (tests), skips signal collection entirely.
  @visibleForTesting
  final String? fixedIdForTesting;

  String? _cached;

  Future<String> loadOrComputeId() async {
    final hit = _cached;
    if (hit != null) return hit;
    final fixed = fixedIdForTesting;
    if (fixed != null) {
      _cached = fixed;
      return fixed;
    }
    final tierA = collectTierADeviceSignals();
    final tierB = await _platform.collectNativeSignals();
    final merged = <String, String>{...tierA, ...tierB};
    final id = await computeDeviceBindingId(merged);
    _cached = id;
    return id;
  }

  @visibleForTesting
  void clearCacheForTesting() {
    _cached = null;
  }
}
