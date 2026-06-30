import 'package:flutter/material.dart';

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

  static const Color _attachedBackground = Color(0xFFE8F5E9);
  static const Color _attachedForeground = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !attached && onPressed != null;
    return Center(
      child: OutlinedButton.icon(
        onPressed: canPress ? onPressed : null,
        style: attached
            ? OutlinedButton.styleFrom(
                backgroundColor: _attachedBackground,
                foregroundColor: _attachedForeground,
                disabledBackgroundColor: _attachedBackground,
                disabledForegroundColor: _attachedForeground,
                side: const BorderSide(color: _attachedForeground),
              )
            : null,
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(label),
      ),
    );
  }
}
