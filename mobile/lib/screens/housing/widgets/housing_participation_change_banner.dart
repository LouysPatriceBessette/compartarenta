import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Error-colored banner for pending participation changes.
class HousingParticipationChangeBanner extends StatelessWidget {
  const HousingParticipationChangeBanner({
    super.key,
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      color: scheme.error,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: scheme.onError),
        title: Text(
          text,
          style: TextStyle(color: scheme.onError),
        ),
        trailing:
            onTap != null
                ? Icon(Icons.chevron_right, color: scheme.onError)
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
