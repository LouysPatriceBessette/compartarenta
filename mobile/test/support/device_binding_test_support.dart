import 'package:compartarenta/device/device_binding_service.dart';

/// Shared [DeviceBindingService] for tests — each call gets a unique fixed id
/// unless [suffix] pins a stable value (e.g. dedup scenarios).
DeviceBindingService deviceBindingForTest([String suffix = '']) =>
    DeviceBindingService.forTesting(suffix);
