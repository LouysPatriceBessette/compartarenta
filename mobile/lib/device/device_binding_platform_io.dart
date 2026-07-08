import 'package:flutter/services.dart';

import 'device_binding_platform.dart';

DeviceBindingPlatform createDeviceBindingPlatform() =>
    MethodChannelDeviceBindingPlatform();

class MethodChannelDeviceBindingPlatform implements DeviceBindingPlatform {
  static const MethodChannel _channel = MethodChannel(
    'com.compartarenta/device_binding',
  );

  @override
  Future<Map<String, String>> collectNativeSignals() async {
    try {
      final raw = await _channel.invokeMethod<Object>('collectSignals');
      if (raw is! Map) return const {};
      return raw.map(
        (key, value) => MapEntry('$key', value == null ? '' : '$value'),
      );
    } on MissingPluginException {
      return const {};
    } on PlatformException {
      return const {};
    }
  }
}
