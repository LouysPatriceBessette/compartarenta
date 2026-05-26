// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<Uint8List?> captureProofPhotoWeb(BuildContext context) async {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => const _HousingProofWebCameraScreen(),
    ),
  );
}

class _HousingProofWebCameraScreen extends StatefulWidget {
  const _HousingProofWebCameraScreen();

  @override
  State<_HousingProofWebCameraScreen> createState() =>
      _HousingProofWebCameraScreenState();
}

class _HousingProofWebCameraScreenState
    extends State<_HousingProofWebCameraScreen> {
  late final String _viewType;
  late final html.VideoElement _videoElement;
  html.MediaStream? _stream;
  bool _starting = true;
  bool _capturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _viewType =
        'housing-proof-camera-${DateTime.now().microsecondsSinceEpoch}';
    _videoElement =
        html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.backgroundColor = '#000';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _videoElement,
    );
    unawaited(_startCamera());
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw StateError('mediaDevices unavailable');
      }
      final stream = await mediaDevices.getUserMedia(<String, dynamic>{
        'video': true,
      });
      _stream = stream;
      _videoElement.srcObject = stream;
      await _videoElement.play();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _errorMessage = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _errorMessage = AppLocalizations.of(
          context,
        ).housingRealizedExpenseCameraStartFailed;
      });
    }
  }

  void _stopCamera() {
    final stream = _stream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _stream = null;
    _videoElement.srcObject = null;
  }

  Future<void> _capture() async {
    if (_capturing) return;
    final width = _videoElement.videoWidth;
    final height = _videoElement.videoHeight;
    if (width <= 0 || height <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).housingRealizedExpenseCameraStartFailed,
          ),
        ),
      );
      return;
    }
    setState(() => _capturing = true);
    try {
      final canvas =
          html.CanvasElement()
            ..width = width
            ..height = height;
      canvas.context2D.drawImageScaled(_videoElement, 0, 0, width, height);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex < 0) return;
      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
      if (!mounted) return;
      Navigator.of(context).pop(Uint8List.fromList(bytes));
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.housingRealizedExpensePickCamera)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _starting
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : HtmlElementView(viewType: _viewType),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _capturing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _starting || _errorMessage != null || _capturing
                          ? null
                          : _capture,
                      icon: const Icon(Icons.photo_camera),
                      label: Text(l10n.housingRealizedExpenseCapturePhoto),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
