import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Dark red banner for pending participation changes (distinct from amendment/expense).
class HousingParticipationChangeBanner extends StatelessWidget {
  const HousingParticipationChangeBanner({
    super.key,
    required this.text,
    this.onTap,
  });

  static const Color bannerColor = Color(0xFF8B0000);

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: bannerColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        title: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
        trailing:
            onTap != null
                ? const Icon(Icons.chevron_right, color: Colors.white)
                : null,
        onTap: onTap,
      ),
    );
    if (!kDebugMode) return card;
    return Semantics(
      identifier: 'qa-housing-participation-banner',
      label: text,
      child: card,
    );
  }
}
