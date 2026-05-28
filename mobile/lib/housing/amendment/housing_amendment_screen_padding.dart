import 'package:flutter/material.dart';

/// Bottom inset for amendment flows (Android navigation bar).
EdgeInsets housingAmendmentScreenPadding(BuildContext context) {
  final bottom = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom);
}
