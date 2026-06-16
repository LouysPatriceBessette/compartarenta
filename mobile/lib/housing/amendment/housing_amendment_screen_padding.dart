import 'package:flutter/material.dart';

import '../../widgets/screen_body_padding.dart';

/// Content padding inside a [SafeArea] (top: false) amendment body.
///
/// Prefer [housingAmendmentScreenPadding] on scroll views instead.
const EdgeInsets housingAmendmentSafeAreaContentPadding =
    EdgeInsets.fromLTRB(16, 16, 16, 16);

/// Scroll body padding for amendment flows (includes OS bottom inset).
EdgeInsets housingAmendmentScreenPadding(BuildContext context) {
  return screenBodyScrollPadding(context);
}

/// Extra [ListView] bottom inset when a full-width footer sits below the scroll
/// view (rules amendment editor).
double housingAmendmentStickyFooterScrollInset(BuildContext context) {
  return 80 + screenBottomSafeInset(context);
}
