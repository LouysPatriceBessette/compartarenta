import 'package:compartarenta/relay/testing/fake_relay_client.dart';

/// Process-wide FakeRelay used when [sandboxMode] is active.
abstract final class SandboxRelay {
  static FakeRelayClient? _instance;

  static FakeRelayClient get instance {
    return _instance ??= FakeRelayClient();
  }

  static FakeRelayClient ensureFresh() {
    _instance = FakeRelayClient();
    return _instance!;
  }

  static void clear() {
    _instance = null;
  }
}
