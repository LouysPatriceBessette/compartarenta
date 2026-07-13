import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app_root_navigator.dart';

/// Leaves the housing module and returns to the app home (`/`).
void exitHousingModule(BuildContext context) {
  // PopScope / system back invoke this while the navigator is locked; defer
  // GoRouter work to the next frame (see NavigatorState.dispose !_debugLocked).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final rootCtx = appRootNavigatorKey.currentContext ?? context;
    if (!rootCtx.mounted) return;
    final router = GoRouter.of(rootCtx);
    if (router.state.matchedLocation == '/housing') {
      router.go('/');
      return;
    }
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go('/');
  });
}
