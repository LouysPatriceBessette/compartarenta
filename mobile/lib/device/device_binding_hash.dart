import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart';

const String kDeviceBindingDomainSeparator =
    'compartarenta/device-binding/v1';

/// Builds a stable, opaque device binding id from Tier A + Tier B signal maps.
///
/// Keys are sorted lexicographically; values are UTF-8 encoded. Only the hash
/// leaves this device — never the raw signal map.
Future<String> computeDeviceBindingId(Map<String, String> signals) async {
  if (signals.isEmpty) {
    throw ArgumentError.value(signals, 'signals', 'must not be empty');
  }
  final canonical = _canonicalSignalPayload(signals);
  final input = utf8.encode('$kDeviceBindingDomainSeparator|$canonical');
  final digest = await Sha256().hash(input);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}

/// Exposed for unit tests and diagnostics (never send over the wire).
String canonicalDeviceBindingPayload(Map<String, String> signals) {
  return _canonicalSignalPayload(signals);
}

String _canonicalSignalPayload(Map<String, String> signals) {
  final keys = signals.keys.toList()..sort();
  return keys.map((key) => '$key=${signals[key]}').join('|');
}
