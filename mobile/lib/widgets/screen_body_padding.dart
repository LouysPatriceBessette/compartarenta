import 'package:flutter/material.dart';

/// Default screen content padding before adding system insets.
const EdgeInsets kScreenBodyPadding = EdgeInsets.all(16);

/// Android/iOS system bottom inset (navigation bar, home indicator).
double screenBottomSafeInset(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom;
}

/// Scrollable body padding that clears the OS navigation bar / home indicator.
EdgeInsets screenBodyScrollPadding(
  BuildContext context, {
  EdgeInsets content = kScreenBodyPadding,
}) {
  final bottom = screenBottomSafeInset(context);
  return content.copyWith(bottom: content.bottom + bottom);
}
