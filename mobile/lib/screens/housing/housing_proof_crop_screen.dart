import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Full-screen crop step before persisting a proof image.
class HousingProofCropScreen extends StatefulWidget {
  const HousingProofCropScreen({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<HousingProofCropScreen> createState() => _HousingProofCropScreenState();
}

class _HousingProofCropScreenState extends State<HousingProofCropScreen> {
  final _cropController = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.housingRealizedExpenseCropTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _cropController,
              aspectRatio: null,
              interactive: true,
              onCropped: (result) {
                if (!mounted) return;
                setState(() => _cropping = false);
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    Navigator.of(context).pop<Uint8List>(croppedImage);
                  case CropFailure():
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.housingRealizedExpenseCropFailed)),
                    );
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _cropping
                    ? null
                    : () {
                        setState(() => _cropping = true);
                        _cropController.crop();
                      },
                child: _cropping
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.housingRealizedExpenseCropConfirm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
