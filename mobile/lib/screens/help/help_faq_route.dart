import 'package:go_router/go_router.dart';

import 'help_faq_screen.dart';

/// Parses `/help/faq` and optional `#anchor` from [GoRouterState].
String? helpFaqAnchorFromState(GoRouterState state) {
  final fragment = state.uri.fragment.trim();
  if (fragment.isNotEmpty) return fragment;
  final extra = state.extra;
  if (extra is String && extra.trim().isNotEmpty) return extra.trim();
  return null;
}

GoRoute helpFaqRoute() {
  return GoRoute(
    path: '/help/faq',
    builder: (context, state) => HelpFaqScreen(
      initialAnchor: helpFaqAnchorFromState(state),
    ),
  );
}
