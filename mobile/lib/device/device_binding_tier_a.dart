import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Permissionless signals available from Dart / Flutter without native code.
Map<String, String> collectTierADeviceSignals() {
  final signals = <String, String>{
    'target_platform': defaultTargetPlatform.name,
  };

  if (!kIsWeb) {
    signals['os'] = Platform.operatingSystem;
    signals['os_version'] = Platform.operatingSystemVersion;
    signals['locale_name'] = Platform.localeName;
    signals['processor_count'] = '${Platform.numberOfProcessors}';
  }

  final dispatcher = SchedulerBinding.instance.platformDispatcher;
  signals['ui_locale'] = dispatcher.locale.toString();
  if (dispatcher.locales.isNotEmpty) {
    signals['ui_locales'] = dispatcher.locales
        .map((locale) => locale.toString())
        .join(',');
  }
  signals['platform_brightness'] = dispatcher.platformBrightness.name;

  if (dispatcher.views.isNotEmpty) {
    final view = dispatcher.views.first;
    signals['physical_width'] = '${view.physicalSize.width}';
    signals['physical_height'] = '${view.physicalSize.height}';
    signals['device_pixel_ratio'] = '${view.devicePixelRatio}';
  }

  final now = DateTime.now();
  signals['timezone_offset_min'] = '${now.timeZoneOffset.inMinutes}';
  signals['timezone_abbr'] = now.timeZoneName;

  return signals;
}
