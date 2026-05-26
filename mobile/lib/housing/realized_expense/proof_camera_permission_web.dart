// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:permission_handler/permission_handler.dart';

enum ProofCameraOptionState { enabled, unavailable }

Future<ProofCameraOptionState> proofCameraOptionState() async {
  try {
    final status = await Permission.camera.status;
    if (!status.isGranted && !status.isLimited) {
      return ProofCameraOptionState.enabled;
    }
  } catch (_) {
    return ProofCameraOptionState.enabled;
  }

  final mediaDevices = html.window.navigator.mediaDevices;
  if (mediaDevices == null) return ProofCameraOptionState.enabled;
  try {
    final devices = await mediaDevices.enumerateDevices();
    final hasCamera = devices.any((device) => device.kind == 'videoinput');
    return hasCamera
        ? ProofCameraOptionState.enabled
        : ProofCameraOptionState.unavailable;
  } catch (_) {
    return ProofCameraOptionState.enabled;
  }
}

Future<bool> ensureProofCameraPermission() async {
  try {
    final status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    final requested = await Permission.camera.request();
    if (requested.isGranted || requested.isLimited) {
      return true;
    }
  } catch (_) {
    // Fall through to direct browser prompt.
  }

  final mediaDevices = html.window.navigator.mediaDevices;
  if (mediaDevices == null) return false;
  try {
    final stream = await mediaDevices.getUserMedia(<String, dynamic>{
      'video': true,
    });
    for (final track in stream.getTracks()) {
      track.stop();
    }
    return true;
  } catch (_) {
    return false;
  }
}
