import 'package:flutter/material.dart';

/// Content padding inside a [SafeArea] (top: false) amendment body.
const EdgeInsets housingAmendmentSafeAreaContentPadding =
    EdgeInsets.fromLTRB(16, 16, 16, 16);

/// Bottom inset for amendment flows (Android navigation bar).
EdgeInsets housingAmendmentScreenPadding(BuildContext context) {
  final bottom = MediaQuery.viewPaddingOf(context).bottom;
  return EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom);
}

/// Extra [ListView] bottom inset when a full-width footer sits below the scroll
/// view (rules amendment editor).
double housingAmendmentStickyFooterScrollInset(BuildContext context) {
  return 80 + MediaQuery.viewPaddingOf(context).bottom;
}
