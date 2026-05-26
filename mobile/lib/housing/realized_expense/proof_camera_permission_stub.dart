import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum ProofCameraOptionState { enabled, unavailable }

Future<ProofCameraOptionState> proofCameraOptionState() async {
  return ProofCameraOptionState.enabled;
}

Future<bool> ensureProofCameraPermission() async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    return true;
  }
  final status = await Permission.camera.status;
  if (status.isGranted || status.isLimited) {
    return true;
  }
  final requested = await Permission.camera.request();
  return requested.isGranted || requested.isLimited;
}
