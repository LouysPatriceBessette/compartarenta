import 'device_binding_platform.dart';

DeviceBindingPlatform createDeviceBindingPlatform() =>
    StubDeviceBindingPlatform();

class StubDeviceBindingPlatform implements DeviceBindingPlatform {
  @override
  Future<Map<String, String>> collectNativeSignals() async => const {};
}
