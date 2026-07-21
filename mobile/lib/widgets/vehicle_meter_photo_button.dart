import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Odometer / horometer photo picker control: green and disabled once attached.
class VehicleMeterPhotoButton extends StatelessWidget {
  const VehicleMeterPhotoButton({
    super.key,
    required this.attached,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final bool attached;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !attached && onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final attachedBackground = Color.alphaBlend(
      AppBrandColors.moneyGreen.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.24 : 0.12,
      ),
      scheme.surface,
    );
    return Center(
      child: OutlinedButton.icon(
        onPressed: canPress ? onPressed : null,
        style: attached
            ? OutlinedButton.styleFrom(
                backgroundColor: attachedBackground,
                foregroundColor: AppBrandColors.moneyGreen,
                disabledBackgroundColor: attachedBackground,
                disabledForegroundColor: AppBrandColors.moneyGreen,
                side: const BorderSide(color: AppBrandColors.moneyGreen),
              )
            : null,
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(label),
      ),
    );
  }
}
