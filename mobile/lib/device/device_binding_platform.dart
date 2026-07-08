import 'device_binding_platform_io.dart'
    if (dart.library.html) 'device_binding_platform_stub.dart';

export 'device_binding_platform_io.dart'
    if (dart.library.html) 'device_binding_platform_stub.dart';

abstract class DeviceBindingPlatform {
  Future<Map<String, String>> collectNativeSignals();

  static DeviceBindingPlatform get instance => createDeviceBindingPlatform();
}
